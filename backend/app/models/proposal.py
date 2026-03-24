from datetime import datetime

from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base, utcnow


class TodoProposal(Base):
    __tablename__ = "todo_proposals"

    id: Mapped[int] = mapped_column(primary_key=True)
    todo_id: Mapped[int] = mapped_column(ForeignKey("todos.id", ondelete="CASCADE"))
    proposed_by: Mapped[int] = mapped_column(ForeignKey("family_members.id", ondelete="CASCADE"))
    proposed_date: Mapped[datetime] = mapped_column()
    message: Mapped[str | None] = mapped_column(Text, default=None)
    status: Mapped[str] = mapped_column(String(20), default="pending")
    created_at: Mapped[datetime] = mapped_column(default=utcnow)

    todo = relationship("Todo", lazy="selectin")
    proposer = relationship("FamilyMember", lazy="selectin")
    responses = relationship(
        "ProposalResponse",
        back_populates="proposal",
        lazy="selectin",
        cascade="all, delete-orphan",
        foreign_keys="[ProposalResponse.proposal_id]",
    )


class ProposalResponse(Base):
    __tablename__ = "proposal_responses"

    id: Mapped[int] = mapped_column(primary_key=True)
    proposal_id: Mapped[int] = mapped_column(ForeignKey("todo_proposals.id", ondelete="CASCADE"))
    member_id: Mapped[int] = mapped_column(ForeignKey("family_members.id", ondelete="CASCADE"))
    response: Mapped[str] = mapped_column(String(20))
    counter_proposal_id: Mapped[int | None] = mapped_column(
        ForeignKey("todo_proposals.id", ondelete="SET NULL"), default=None
    )
    message: Mapped[str | None] = mapped_column(Text, default=None)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)

    proposal = relationship("TodoProposal", foreign_keys=[proposal_id], back_populates="responses")
    member = relationship("FamilyMember", lazy="selectin")
