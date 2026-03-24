from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..auth import get_current_user, require_family_id
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
    selectinload(Todo.event),
    selectinload(Todo.members),
    selectinload(Todo.subtodos),
]


@router.get("/", response_model=list[TodoResponse])
async def list_todos(
    completed: bool | None = Query(None),
    priority: str | None = Query(None),
    member_id: int | None = Query(None),
    category_id: int | None = Query(None),
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    stmt = (
        select(Todo)
        .options(*_todo_options)
        .where(Todo.parent_id.is_(None), Todo.family_id == family_id)
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
):
    result = await db.execute(
        select(Todo)
        .options(*_todo_options)
        .where(Todo.id == todo_id, Todo.family_id == family_id)
    )
    todo = result.scalar_one_or_none()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")
    return todo


@router.post("/", response_model=TodoResponse, status_code=status.HTTP_201_CREATED)
async def create_todo(
    data: TodoCreate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    if data.parent_id:
        parent = await db.get(Todo, data.parent_id)
        if not parent or parent.family_id != family_id:
            raise HTTPException(status_code=404, detail="Eltern-Todo nicht gefunden")
    members = await resolve_members(db, data.member_ids, family_id)
    todo = Todo(
        family_id=family_id,
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
):
    result = await db.execute(
        select(Todo).options(*_todo_options).where(Todo.id == todo_id, Todo.family_id == family_id)
    )
    todo = result.scalar_one_or_none()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")

    update_data = data.model_dump(exclude_unset=True)
    member_ids = update_data.pop("member_ids", None)
    if "priority" in update_data and update_data["priority"] is not None:
        update_data["priority"] = update_data["priority"].value

    for key, value in update_data.items():
        setattr(todo, key, value)

    if member_ids is not None:
        todo.members = await resolve_members(db, member_ids, family_id)

    await db.flush()
    await db.refresh(todo)
    return todo


@router.patch("/{todo_id}/complete", response_model=TodoResponse)
async def complete_todo(
    todo_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(Todo).options(*_todo_options).where(Todo.id == todo_id, Todo.family_id == family_id)
    )
    todo = result.scalar_one_or_none()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")

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
):
    result = await db.execute(
        select(Todo).options(*_todo_options).where(Todo.id == todo_id, Todo.family_id == family_id)
    )
    todo = result.scalar_one_or_none()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")

    todo.event_id = data.event_id
    await db.flush()
    await db.refresh(todo)
    return todo


@router.delete("/{todo_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_todo(
    todo_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    result = await db.execute(
        select(Todo).where(Todo.id == todo_id, Todo.family_id == family_id)
    )
    todo = result.scalar_one_or_none()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")
    await db.delete(todo)
