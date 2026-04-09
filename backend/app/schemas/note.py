from __future__ import annotations

from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field

from .family_member import FamilyMemberResponse
from .note_category import NoteCategoryResponse
from .note_tag import NoteTagResponse


class NoteType(str, Enum):
    text = "text"
    link = "link"
    checklist = "checklist"


class ChecklistItem(BaseModel):
    text: str
    checked: bool = False


class NoteCreate(BaseModel):
    title: str = ""
    type: NoteType = NoteType.text
    content: str | None = None
    url: str | None = None
    checklist_items: list[ChecklistItem] | None = None
    is_personal: bool = False
    category_id: int | None = None
    color: str | None = None
    tag_ids: list[int] = Field(default_factory=list)
    reminder_at: datetime | None = None


class NoteUpdate(BaseModel):
    title: str | None = None
    type: NoteType | None = None
    content: str | None = None
    url: str | None = None
    checklist_items: list[ChecklistItem] | None = None
    is_personal: bool | None = None
    category_id: int | None = None
    color: str | None = None
    tag_ids: list[int] | None = None
    reminder_at: datetime | None = None
    link_title: str | None = None
    link_description: str | None = None
    link_thumbnail_url: str | None = None
    link_domain: str | None = None


class NoteReorderRequest(BaseModel):
    ids: list[int]


class NoteCommentCreate(BaseModel):
    content: str


class NoteCommentResponse(BaseModel):
    id: int
    member: FamilyMemberResponse | None
    content: str
    created_at: datetime

    model_config = {"from_attributes": True}


class NoteAttachmentResponse(BaseModel):
    id: int
    filename: str
    content_type: str
    file_size: int
    created_at: datetime
    download_url: str | None = None

    model_config = {"from_attributes": True}


class NoteResponse(BaseModel):
    id: int
    is_personal: bool
    created_by_member_id: int | None
    created_by: FamilyMemberResponse | None
    type: str
    title: str
    content: str | None
    url: str | None
    link_title: str | None
    link_description: str | None
    link_thumbnail_url: str | None
    link_domain: str | None
    checklist_items: list[ChecklistItem] | None = None
    is_pinned: bool
    is_archived: bool
    color: str | None
    category: NoteCategoryResponse | None
    tags: list[NoteTagResponse]
    comments: list[NoteCommentResponse]
    attachments: list[NoteAttachmentResponse]
    reminder_at: datetime | None
    position: int
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class NoteColorRequest(BaseModel):
    color: str | None


class PreviewLinkRequest(BaseModel):
    url: str


class PreviewLinkResponse(BaseModel):
    url: str
    link_title: str | None = None
    link_description: str | None = None
    link_thumbnail_url: str | None = None
    link_domain: str | None = None


class ConvertNoteToTodoRequest(BaseModel):
    archive_note: bool = True


class DuplicateLinkResponse(BaseModel):
    exists: bool
    note_id: int | None = None
    title: str | None = None
