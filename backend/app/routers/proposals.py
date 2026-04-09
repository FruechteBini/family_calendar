from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..auth import get_current_user, require_family_id
from ..database import get_db
from ..models.family_member import FamilyMember
from ..models.proposal import ProposalResponse as ProposalResponseModel
from ..models.proposal import TodoProposal
from ..models.todo import Todo, todo_members
from ..models.user import User
from ..schemas.proposal import (
    PendingProposalDetail,
    ProposalCreate,
    ProposalDetail,
    ProposalRespondRequest,
)

router = APIRouter(prefix="/api", tags=["proposals"], dependencies=[Depends(get_current_user)])


def _get_member_or_fail(user: User) -> FamilyMember:
    if not user.member_id or not user.member:
        raise HTTPException(
            status_code=400,
            detail="Dein Account ist noch nicht mit einem Familienmitglied verknüpft.",
        )
    return user.member


@router.post(
    "/todos/{todo_id}/proposals",
    response_model=ProposalDetail,
    status_code=status.HTTP_201_CREATED,
)
async def create_proposal(
    todo_id: int,
    data: ProposalCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    member = _get_member_or_fail(user)
    result = await db.execute(
        select(Todo).where(Todo.id == todo_id, Todo.family_id == family_id)
    )
    todo = result.scalar_one_or_none()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")
    if not todo.requires_multiple:
        raise HTTPException(status_code=400, detail="Terminvorschläge nur für Mehrpersonen-Todos")

    proposal = TodoProposal(
        todo_id=todo_id,
        proposed_by=member.id,
        proposed_date=data.proposed_date,
        message=data.message,
        status="pending",
    )
    db.add(proposal)
    await db.flush()
    await db.refresh(proposal)
    return proposal


@router.get("/todos/{todo_id}/proposals", response_model=list[ProposalDetail])
async def list_proposals(
    todo_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    todo_check = await db.execute(
        select(Todo).where(Todo.id == todo_id, Todo.family_id == family_id)
    )
    if not todo_check.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Todo nicht gefunden")

    stmt = (
        select(TodoProposal)
        .options(
            selectinload(TodoProposal.proposer),
            selectinload(TodoProposal.responses).selectinload(ProposalResponseModel.member),
        )
        .where(TodoProposal.todo_id == todo_id)
        .order_by(TodoProposal.created_at.desc())
    )
    result = await db.execute(stmt)
    return result.scalars().unique().all()


@router.post("/proposals/{proposal_id}/respond", response_model=ProposalDetail)
async def respond_to_proposal(
    proposal_id: int,
    data: ProposalRespondRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    member = _get_member_or_fail(user)

    proposal = await db.get(TodoProposal, proposal_id, options=[
        selectinload(TodoProposal.proposer),
        selectinload(TodoProposal.responses).selectinload(ProposalResponseModel.member),
    ])
    if not proposal:
        raise HTTPException(status_code=404, detail="Vorschlag nicht gefunden")

    todo_check = await db.execute(
        select(Todo).where(Todo.id == proposal.todo_id, Todo.family_id == family_id)
    )
    if not todo_check.scalar_one_or_none():
        raise HTTPException(status_code=403, detail="Kein Zugriff auf diesen Vorschlag")

    if proposal.status != "pending":
        raise HTTPException(status_code=400, detail="Vorschlag ist nicht mehr offen")

    existing = [r for r in proposal.responses if r.member_id == member.id]
    if existing:
        raise HTTPException(status_code=409, detail="Du hast bereits geantwortet")

    counter_proposal_id = None
    if data.response == "rejected" and data.counter_date:
        counter = TodoProposal(
            todo_id=proposal.todo_id,
            proposed_by=member.id,
            proposed_date=data.counter_date,
            message=data.message,
            status="pending",
        )
        db.add(counter)
        await db.flush()
        counter_proposal_id = counter.id
        proposal.status = "superseded"
    else:
        resp = ProposalResponseModel(
            proposal_id=proposal_id,
            member_id=member.id,
            response=data.response,
            counter_proposal_id=counter_proposal_id,
            message=data.message,
        )
        db.add(resp)
        await db.flush()

        if data.response == "rejected":
            proposal.status = "rejected"
        else:
            todo = await db.get(Todo, proposal.todo_id, options=[selectinload(Todo.members)])
            if todo:
                needed_ids = {m.id for m in todo.members if m.id != proposal.proposed_by}
                accepted_ids = {
                    r.member_id for r in proposal.responses if r.response == "accepted"
                }
                accepted_ids.add(member.id)
                if needed_ids <= accepted_ids:
                    proposal.status = "accepted"

    await db.flush()
    await db.refresh(proposal)
    return proposal


@router.get("/proposals/pending", response_model=list[PendingProposalDetail])
async def pending_proposals(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    member = _get_member_or_fail(user)

    stmt = (
        select(TodoProposal)
        .join(Todo, TodoProposal.todo_id == Todo.id)
        .join(todo_members, todo_members.c.todo_id == Todo.id)
        .options(selectinload(TodoProposal.proposer), selectinload(TodoProposal.todo))
        .where(
            Todo.family_id == family_id,
            TodoProposal.status == "pending",
            todo_members.c.member_id == member.id,
            TodoProposal.proposed_by != member.id,
        )
        .order_by(TodoProposal.created_at.desc())
    )
    result = await db.execute(stmt)
    proposals = result.scalars().unique().all()

    return [
        PendingProposalDetail(
            id=p.id,
            todo_id=p.todo_id,
            todo_title=p.todo.title if p.todo else "?",
            proposer=p.proposer,
            proposed_date=p.proposed_date,
            message=p.message,
            status=p.status,
            created_at=p.created_at,
        )
        for p in proposals
    ]
