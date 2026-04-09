from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..auth import get_current_user, require_family_id, require_member_id
from ..database import get_db, utcnow
from ..models.family_member import FamilyMember
from ..models.todo import Todo
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
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
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
        members=members,
    )
    db.add(todo)
    await db.flush()
    await db.refresh(todo)
    return todo


@router.put("/{todo_id}", response_model=TodoResponse)
async def update_todo(
    todo_id: int,
    data: TodoUpdate,
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
    return todo


@router.patch("/{todo_id}/complete", response_model=TodoResponse)
async def complete_todo(
    todo_id: int,
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
        raise HTTPException(status_code=403, detail="Nur der Ersteller kann dieses Todo löschen")
    await db.delete(todo)
