from datetime import datetime
from typing import Literal

from pydantic import BaseModel

from .family_member import FamilyMemberResponse


class ProposalCreate(BaseModel):
    proposed_date: datetime
    message: str | None = None


class ProposalRespondRequest(BaseModel):
    response: Literal["accepted", "rejected"]
    message: str | None = None
    counter_date: datetime | None = None


class ProposalResponseDetail(BaseModel):
    id: int
    member: FamilyMemberResponse
    response: str
    counter_proposal_id: int | None
    message: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class ProposalDetail(BaseModel):
    id: int
    todo_id: int
    proposer: FamilyMemberResponse
    proposed_date: datetime
    message: str | None
    status: str
    responses: list[ProposalResponseDetail]
    created_at: datetime

    model_config = {"from_attributes": True}


class PendingProposalDetail(BaseModel):
    id: int
    todo_id: int
    todo_title: str
    proposer: FamilyMemberResponse
    proposed_date: datetime
    message: str | None
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}
