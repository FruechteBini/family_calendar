import re
import uuid
from pathlib import Path

from fastapi import APIRouter, BackgroundTasks, Depends, File, HTTPException, Query, UploadFile, status
from fastapi.responses import FileResponse
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..auth import get_current_user, require_family_id, require_member_id
from ..config import settings
from ..database import get_db, utcnow
from ..database import async_session
from ..google_sync_service import GoogleSyncService
from ..models.event import Event
from ..models.family_member import FamilyMember
from ..models.todo import Todo
from ..models.todo_attachment import TodoAttachment
from ..models.user import User
from ..notification_service import notification_service
from ..todo_event_binding import apply_event_binding_to_todo, reschedule_todo_reminders
from ..schemas.todo import (
    LinkEventRequest,
    ReorderSubtodosRequest,
    TodoAttachmentResponse,
    TodoCreate,
    TodoResponse,
    TodoUpdate,
)
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
    selectinload(Todo.attachments),
    selectinload(Todo.subtodos).selectinload(Todo.attachments),
    selectinload(Todo.subtodos).selectinload(Todo.members),
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
    sort_order_val = 0
    if data.parent_id:
        parent = await db.get(Todo, data.parent_id)
        if not parent or parent.family_id != family_id:
            raise HTTPException(status_code=404, detail="Eltern-Todo nicht gefunden")
        if parent.parent_id is not None:
            raise HTTPException(
                status_code=400,
                detail="Sub-Todos können keine eigenen Sub-Todos haben",
            )
        max_order = await db.execute(
            select(func.coalesce(func.max(Todo.sort_order), -1)).where(
                Todo.parent_id == data.parent_id,
                Todo.family_id == family_id,
            )
        )
        sort_order_val = int(max_order.scalar_one()) + 1
    members = []
    if not data.is_personal:
        members = await resolve_members(db, data.member_ids, family_id)
    due_date = data.due_date
    notification_level_id = data.notification_level_id
    if data.event_id is not None:
        event = await db.get(Event, data.event_id)
        if not event or event.family_id != family_id:
            raise HTTPException(status_code=404, detail="Termin nicht gefunden")
        due_date = event.start.date()
        notification_level_id = event.notification_level_id
    todo = Todo(
        family_id=family_id,
        created_by_member_id=current_member_id,
        is_personal=data.is_personal,
        title=data.title,
        description=data.description,
        priority=data.priority.value,
        due_date=due_date,
        category_id=data.category_id,
        event_id=data.event_id,
        parent_id=data.parent_id,
        sort_order=sort_order_val,
        requires_multiple=data.requires_multiple,
        notification_level_id=notification_level_id,
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

    await reschedule_todo_reminders(db, family_id, todo, user.id)
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

    if todo.event_id is not None:
        event = await db.get(Event, todo.event_id)
        if event and event.family_id == family_id:
            apply_event_binding_to_todo(todo, event)

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

    await reschedule_todo_reminders(db, family_id, todo, user.id)
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

    will_complete = not todo.completed

    if will_complete and todo.parent_id is None and user.require_subtodos_complete:
        incomplete = [s for s in todo.subtodos if not s.completed]
        if incomplete:
            raise HTTPException(
                status_code=400,
                detail=f"{len(incomplete)} Sub-Todo(s) noch nicht erledigt",
            )

    parent_auto_completed = False
    todo.completed = will_complete
    todo.completed_at = utcnow() if will_complete else None

    await db.flush()
    await db.refresh(todo)

    if (
        will_complete
        and todo.parent_id is not None
        and user.auto_complete_parent
    ):
        parent_res = await db.execute(
            select(Todo)
            .options(
                selectinload(Todo.subtodos),
                selectinload(Todo.members),
            )
            .where(Todo.id == todo.parent_id, Todo.family_id == family_id)
        )
        parent_todo = parent_res.scalar_one_or_none()
        if (
            parent_todo
            and parent_todo.subtodos
            and all(s.completed for s in parent_todo.subtodos)
            and not parent_todo.completed
        ):
            parent_todo.completed = True
            parent_todo.completed_at = utcnow()
            parent_auto_completed = True
            await db.flush()
            await db.refresh(parent_todo)
            if (
                background_tasks is not None
                and user.sync_todos_enabled
                and user.google_refresh_token
                and settings.GOOGLE_CLIENT_ID
                and settings.GOOGLE_CLIENT_SECRET
            ):
                background_tasks.add_task(_google_push_todo, user.id, parent_todo.id)
            if not parent_todo.is_personal:
                member_ids = [m.id for m in parent_todo.members]
                res_users = await db.execute(
                    select(User.id).where(
                        User.family_id == family_id,
                        (User.member_id.in_(member_ids))
                        | (User.member_id == parent_todo.created_by_member_id),
                    )
                )
                target_user_ids = [r[0] for r in res_users.all() if r[0] != user.id]
                await notification_service.send_immediate(
                    db=db,
                    user_ids=target_user_ids,
                    notification_type="todo_completed",
                    title="Todo erledigt",
                    body=f'"{parent_todo.title}" wurde erledigt',
                    data={"route": "/todos", "todo_id": str(parent_todo.id)},
                )

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

    payload = TodoResponse.model_validate(todo)
    return payload.model_copy(update={"parent_auto_completed": parent_auto_completed})


@router.patch("/{todo_id}/link-event", response_model=TodoResponse)
async def link_event(
    todo_id: int,
    data: LinkEventRequest,
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

    if data.event_id is not None:
        event = await db.get(Event, data.event_id)
        if not event or event.family_id != family_id:
            raise HTTPException(status_code=404, detail="Termin nicht gefunden")
        todo.event_id = data.event_id
        apply_event_binding_to_todo(todo, event)
    else:
        todo.event_id = None

    await db.flush()
    await db.refresh(todo)
    await reschedule_todo_reminders(db, family_id, todo, user.id)
    return todo


@router.patch("/{todo_id}/reorder-subtodos", response_model=TodoResponse)
async def reorder_subtodos(
    todo_id: int,
    data: ReorderSubtodosRequest,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
    _user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Todo).options(*_todo_options).where(
            Todo.id == todo_id,
            Todo.family_id == family_id,
            Todo.parent_id.is_(None),
        )
    )
    root = result.scalar_one_or_none()
    if not root:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")
    if root.is_personal:
        if root.created_by_member_id != current_member_id:
            raise HTTPException(status_code=403, detail="Nur der Ersteller kann dieses Todo bearbeiten")
    else:
        if not any(m.id == current_member_id for m in root.members):
            raise HTTPException(status_code=403, detail="Nur zugewiesene Mitglieder können dieses Todo bearbeiten")

    r2 = await db.execute(
        select(Todo).where(Todo.parent_id == todo_id, Todo.family_id == family_id)
    )
    subs = {t.id: t for t in r2.scalars().all()}
    if set(data.subtodo_ids) != set(subs.keys()):
        raise HTTPException(
            status_code=400,
            detail="Sub-Todo-Liste muss exakt alle Untertodos enthalten",
        )
    for i, sid in enumerate(data.subtodo_ids):
        subs[sid].sort_order = i
    await db.flush()
    result3 = await db.execute(
        select(Todo).options(*_todo_options).where(Todo.id == todo_id, Todo.family_id == family_id)
    )
    return result3.scalar_one()


@router.post(
    "/{todo_id}/attachments",
    response_model=TodoAttachmentResponse,
    status_code=status.HTTP_201_CREATED,
)
async def upload_todo_attachment(
    todo_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
    file: UploadFile = File(...),
):
    result = await db.execute(
        select(Todo).where(Todo.id == todo_id, Todo.family_id == family_id)
    )
    todo = result.scalar_one_or_none()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")
    if todo.is_personal and todo.created_by_member_id != current_member_id:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")

    upload_root = Path(settings.UPLOAD_DIR)
    upload_root.mkdir(parents=True, exist_ok=True)

    body = await file.read()
    if len(body) > settings.MAX_NOTE_ATTACHMENT_BYTES:
        raise HTTPException(status_code=413, detail="Datei zu groß (max. 10 MB)")

    safe_name = re.sub(r"[^A-Za-z0-9._-]", "_", file.filename or "upload")
    stored_name = f"todo_{todo.id}_{uuid.uuid4().hex}_{safe_name}"
    stored_path = upload_root / stored_name
    stored_path.write_bytes(body)

    att = TodoAttachment(
        todo_id=todo.id,
        filename=file.filename or "upload",
        stored_path=str(stored_path),
        content_type=file.content_type or "application/octet-stream",
        file_size=len(body),
    )
    db.add(att)
    await db.flush()
    await db.refresh(att)
    return TodoAttachmentResponse.model_validate(att)


@router.delete("/{todo_id}/attachments/{attachment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_todo_attachment(
    todo_id: int,
    attachment_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
):
    result = await db.execute(
        select(Todo).where(Todo.id == todo_id, Todo.family_id == family_id)
    )
    todo = result.scalar_one_or_none()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")
    if todo.is_personal and todo.created_by_member_id != current_member_id:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")

    r2 = await db.execute(
        select(TodoAttachment).where(
            TodoAttachment.id == attachment_id,
            TodoAttachment.todo_id == todo.id,
        )
    )
    att = r2.scalar_one_or_none()
    if not att:
        raise HTTPException(status_code=404, detail="Anhang nicht gefunden")
    p = Path(att.stored_path)
    if p.is_file():
        try:
            p.unlink()
        except OSError:
            pass
    await db.delete(att)


@router.get("/{todo_id}/attachments/{attachment_id}/download")
async def download_todo_attachment(
    todo_id: int,
    attachment_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
):
    result = await db.execute(
        select(Todo).where(Todo.id == todo_id, Todo.family_id == family_id)
    )
    todo = result.scalar_one_or_none()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")
    if todo.is_personal and todo.created_by_member_id != current_member_id:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")

    r2 = await db.execute(
        select(TodoAttachment).where(
            TodoAttachment.id == attachment_id,
            TodoAttachment.todo_id == todo.id,
        )
    )
    att = r2.scalar_one_or_none()
    if not att:
        raise HTTPException(status_code=404, detail="Anhang nicht gefunden")
    path = Path(att.stored_path)
    if not path.is_file():
        raise HTTPException(status_code=404, detail="Datei nicht gefunden")
    return FileResponse(
        path=str(path),
        filename=att.filename,
        media_type=att.content_type or "application/octet-stream",
    )


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
        select(Todo)
        .options(selectinload(Todo.attachments))
        .where(Todo.id == todo_id, Todo.family_id == family_id)
    )
    todo = result.scalar_one_or_none()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")
    if todo.is_personal and todo.created_by_member_id != current_member_id:
        raise HTTPException(status_code=403, detail="Nur der Ersteller kann dieses Todo löschen")
    for att in list(todo.attachments):
        p = Path(att.stored_path)
        if p.is_file():
            try:
                p.unlink()
            except OSError:
                pass
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
