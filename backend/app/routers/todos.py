from datetime import datetime, time, timezone

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..auth import get_current_user, require_family_id, require_member_id
from ..config import settings
from ..database import get_db, utcnow
from ..database import async_session
from ..google_sync_service import GoogleSyncService
from ..models.family_member import FamilyMember
from ..models.todo import Todo
from ..models.user import User
from ..notification_service import notification_service
from ..schemas.todo import LinkEventRequest, TodoCreate, TodoResponse, TodoUpdate
from ..utils import resolve_members

router = APIRouter(
    prefix="/api/todos",
    tags=["todos"],
    dependencies=[Depends(get_current_user)],
)

_todo_options = [
    selectinload(Todo.category),
    selectinload(Todo.created_by),
    selectinload(Todo.event),
    selectinload(Todo.members),
    selectinload(Todo.subtodos),
]

_google_sync = GoogleSyncService()


async def _google_push_todo(user_id: int, todo_id: int) -> None:
    if not settings.GOOGLE_CLIENT_ID or not settings.GOOGLE_CLIENT_SECRET:
        return
    async with async_session() as db:
        user = await db.get(User, user_id)
        todo = await db.get(Todo, todo_id)
        if not user or not todo:
            return
        try:
            await _google_sync.push_todo_to_google(
                user=user,
                todo=todo,
                db=db,
                client_id=settings.GOOGLE_CLIENT_ID,
                client_secret=settings.GOOGLE_CLIENT_SECRET,
            )
            await db.commit()
        except Exception:
            await db.rollback()


async def _google_delete_todo(user_id: int, todo_id: int) -> None:
    if not settings.GOOGLE_CLIENT_ID or not settings.GOOGLE_CLIENT_SECRET:
        return
    async with async_session() as db:
        user = await db.get(User, user_id)
        if not user:
            return
        try:
            await _google_sync.delete_todo_from_google(
                user=user,
                todo_id=todo_id,
                db=db,
                client_id=settings.GOOGLE_CLIENT_ID,
                client_secret=settings.GOOGLE_CLIENT_SECRET,
            )
            await db.commit()
        except Exception:
            await db.rollback()


@router.get("/", response_model=list[TodoResponse])
async def list_todos(
    scope: str = Query("all", pattern="^(all|personal|family)$"),
    completed: bool | None = Query(None),
    priority: str | None = Query(None),
    member_id: int | None = Query(None),
    view_member_id: int | None = Query(None),
    category_id: int | None = Query(None),
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
):
    stmt = select(Todo).options(*_todo_options).where(
        Todo.parent_id.is_(None),
        Todo.family_id == family_id,
    )

    if scope == "personal":
        stmt = stmt.where(
            Todo.is_personal.is_(True),
            Todo.created_by_member_id == current_member_id,
        )
    elif scope == "family":
        stmt = stmt.where(Todo.is_personal.is_(False))
        if view_member_id is not None:
            stmt = stmt.where(Todo.members.any(FamilyMember.id == view_member_id))
    else:
        # all: own personal + family todos assigned to current member
        stmt = stmt.where(
            (Todo.is_personal.is_(True) & (Todo.created_by_member_id == current_member_id))
            | (Todo.is_personal.is_(False) & Todo.members.any(FamilyMember.id == current_member_id))
        )
    if completed is not None:
        stmt = stmt.where(Todo.completed == completed)
    if priority:
        stmt = stmt.where(Todo.priority == priority)
    if category_id:
        stmt = stmt.where(Todo.category_id == category_id)
    if member_id:
        stmt = stmt.where(Todo.members.any(FamilyMember.id == member_id))
    stmt = stmt.order_by(Todo.due_date.asc().nulls_last(), Todo.created_at.desc())
    result = await db.execute(stmt)
    return result.scalars().unique().all()


@router.get("/{todo_id}", response_model=TodoResponse)
async def get_todo(
    todo_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
):
    result = await db.execute(
        select(Todo)
        .options(*_todo_options)
        .where(Todo.id == todo_id, Todo.family_id == family_id)
    )
    todo = result.scalar_one_or_none()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")
    if todo.is_personal and todo.created_by_member_id != current_member_id:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")
    return todo


@router.post("/", response_model=TodoResponse, status_code=status.HTTP_201_CREATED)
async def create_todo(
    data: TodoCreate,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
    user: User = Depends(get_current_user),
):
    if data.parent_id:
        parent = await db.get(Todo, data.parent_id)
        if not parent or parent.family_id != family_id:
            raise HTTPException(status_code=404, detail="Eltern-Todo nicht gefunden")
    members = []
    if not data.is_personal:
        members = await resolve_members(db, data.member_ids, family_id)
    todo = Todo(
        family_id=family_id,
        created_by_member_id=current_member_id,
        is_personal=data.is_personal,
        title=data.title,
        description=data.description,
        priority=data.priority.value,
        due_date=data.due_date,
        category_id=data.category_id,
        event_id=data.event_id,
        parent_id=data.parent_id,
        requires_multiple=data.requires_multiple,
        notification_level_id=data.notification_level_id,
        members=members,
    )
    db.add(todo)
    await db.flush()
    await db.refresh(todo)
    if (
        background_tasks is not None
        and user.sync_todos_enabled
        and user.google_refresh_token
        and settings.GOOGLE_CLIENT_ID
        and settings.GOOGLE_CLIENT_SECRET
    ):
        background_tasks.add_task(_google_push_todo, user.id, todo.id)

    # Immediate push: assigned members (family todos)
    if not todo.is_personal and members:
        res_users = await db.execute(
            select(User.id).where(
                User.family_id == family_id,
                User.member_id.in_([m.id for m in members]),
            )
        )
        target_user_ids = [r[0] for r in res_users.all() if r[0] != user.id]
        await notification_service.send_immediate(
            db=db,
            user_ids=target_user_ids,
            notification_type="todo_assigned",
            title="Neues Todo",
            body=f'"{todo.title}" wurde dir zugewiesen',
            data={"route": "/todos", "todo_id": str(todo.id)},
        )

        # Schedule reminders for due_date (09:00 UTC anchor)
        if todo.due_date and todo.notification_level_id is not None:
            anchor = datetime.combine(
                todo.due_date, time(hour=9, minute=0), tzinfo=timezone.utc
            )
            await notification_service.cancel_schedules(
                db=db,
                family_id=family_id,
                entity_type="todo",
                entity_id=todo.id,
                notification_type="todo_reminder",
            )
            await notification_service.schedule_from_level(
                db=db,
                family_id=family_id,
                entity_type="todo",
                entity_id=todo.id,
                notification_type="todo_reminder",
                anchor_time=anchor,
                level_id=todo.notification_level_id,
                target_user_ids=target_user_ids if target_user_ids else [user.id],
                title="Todo-Erinnerung",
                body=f'"{todo.title}" ist fällig',
                data={"route": "/todos", "todo_id": str(todo.id)},
            )
    return todo


@router.put("/{todo_id}", response_model=TodoResponse)
async def update_todo(
    todo_id: int,
    data: TodoUpdate,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
    user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Todo).options(*_todo_options).where(Todo.id == todo_id, Todo.family_id == family_id)
    )
    todo = result.scalar_one_or_none()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")
    if todo.is_personal and todo.created_by_member_id != current_member_id:
        raise HTTPException(status_code=403, detail="Nur der Ersteller kann dieses Todo bearbeiten")

    update_data = data.model_dump(exclude_unset=True)
    member_ids = update_data.pop("member_ids", None)
    if "priority" in update_data and update_data["priority"] is not None:
        update_data["priority"] = update_data["priority"].value

    for key, value in update_data.items():
        setattr(todo, key, value)

    if member_ids is not None:
        if todo.is_personal:
            raise HTTPException(status_code=400, detail="Persönliche Todos können nicht zugewiesen werden")
        todo.members = await resolve_members(db, member_ids, family_id)

    await db.flush()
    await db.refresh(todo)
    if (
        background_tasks is not None
        and user.sync_todos_enabled
        and user.google_refresh_token
        and settings.GOOGLE_CLIENT_ID
        and settings.GOOGLE_CLIENT_SECRET
    ):
        background_tasks.add_task(_google_push_todo, user.id, todo.id)

    if not todo.is_personal and todo.members:
        res_users = await db.execute(
            select(User.id).where(
                User.family_id == family_id,
                User.member_id.in_([m.id for m in todo.members]),
            )
        )
        target_user_ids = [r[0] for r in res_users.all() if r[0] != user.id]
        # reschedule if due_date/level changed
        if todo.due_date and todo.notification_level_id is not None:
            anchor = datetime.combine(
                todo.due_date, time(hour=9, minute=0), tzinfo=timezone.utc
            )
            await notification_service.cancel_schedules(
                db=db,
                family_id=family_id,
                entity_type="todo",
                entity_id=todo.id,
                notification_type="todo_reminder",
            )
            await notification_service.schedule_from_level(
                db=db,
                family_id=family_id,
                entity_type="todo",
                entity_id=todo.id,
                notification_type="todo_reminder",
                anchor_time=anchor,
                level_id=todo.notification_level_id,
                target_user_ids=target_user_ids if target_user_ids else [user.id],
                title="Todo-Erinnerung",
                body=f'"{todo.title}" ist fällig',
                data={"route": "/todos", "todo_id": str(todo.id)},
            )
        else:
            await notification_service.cancel_schedules(
                db=db,
                family_id=family_id,
                entity_type="todo",
                entity_id=todo.id,
                notification_type="todo_reminder",
            )
    return todo


@router.patch("/{todo_id}/complete", response_model=TodoResponse)
async def complete_todo(
    todo_id: int,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
    user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Todo).options(*_todo_options).where(Todo.id == todo_id, Todo.family_id == family_id)
    )
    todo = result.scalar_one_or_none()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")

    if todo.is_personal:
        if todo.created_by_member_id != current_member_id:
            raise HTTPException(status_code=403, detail="Nur der Ersteller kann dieses Todo abhaken")
    else:
        if not any(m.id == current_member_id for m in todo.members):
            raise HTTPException(status_code=403, detail="Nur zugewiesene Mitglieder können dieses Todo abhaken")

    todo.completed = not todo.completed
    todo.completed_at = utcnow() if todo.completed else None

    await db.flush()
    await db.refresh(todo)
    if (
        background_tasks is not None
        and user.sync_todos_enabled
        and user.google_refresh_token
        and settings.GOOGLE_CLIENT_ID
        and settings.GOOGLE_CLIENT_SECRET
    ):
        background_tasks.add_task(_google_push_todo, user.id, todo.id)

    if todo.completed and not todo.is_personal:
        # inform creator and assigned members (excluding actor)
        member_ids = [m.id for m in todo.members]
        res_users = await db.execute(
            select(User.id).where(
                User.family_id == family_id,
                (User.member_id.in_(member_ids))
                | (User.member_id == todo.created_by_member_id),
            )
        )
        target_user_ids = [r[0] for r in res_users.all() if r[0] != user.id]
        await notification_service.send_immediate(
            db=db,
            user_ids=target_user_ids,
            notification_type="todo_completed",
            title="Todo erledigt",
            body=f'"{todo.title}" wurde erledigt',
            data={"route": "/todos", "todo_id": str(todo.id)},
        )
    return todo


@router.patch("/{todo_id}/link-event", response_model=TodoResponse)
async def link_event(
    todo_id: int,
    data: LinkEventRequest,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
):
    result = await db.execute(
        select(Todo).options(*_todo_options).where(Todo.id == todo_id, Todo.family_id == family_id)
    )
    todo = result.scalar_one_or_none()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")
    if todo.is_personal and todo.created_by_member_id != current_member_id:
        raise HTTPException(status_code=403, detail="Nur der Ersteller kann dieses Todo bearbeiten")

    todo.event_id = data.event_id
    await db.flush()
    await db.refresh(todo)
    return todo


@router.delete("/{todo_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_todo(
    todo_id: int,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
    user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Todo).where(Todo.id == todo_id, Todo.family_id == family_id)
    )
    todo = result.scalar_one_or_none()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")
    if todo.is_personal and todo.created_by_member_id != current_member_id:
        raise HTTPException(status_code=403, detail="Nur der Ersteller kann dieses Todo löschen")
    await notification_service.cancel_schedules(
        db=db,
        family_id=family_id,
        entity_type="todo",
        entity_id=todo.id,
    )
    if (
        background_tasks is not None
        and user.sync_todos_enabled
        and user.google_refresh_token
        and settings.GOOGLE_CLIENT_ID
        and settings.GOOGLE_CLIENT_SECRET
    ):
        background_tasks.add_task(_google_delete_todo, user.id, todo.id)
    await db.delete(todo)
