from __future__ import annotations

import json
import re
import uuid
from pathlib import Path
from urllib.parse import urlparse, urlunparse

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from fastapi.responses import FileResponse
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..auth import get_current_user, require_family_id, require_member_id
from ..config import settings
from ..database import get_db, utcnow
from ..models.note import Note
from ..models.note_attachment import NoteAttachment
from ..models.note_comment import NoteComment
from ..models.note_tag import NoteTag
from ..models.todo import Todo
from ..schemas.family_member import FamilyMemberResponse
from ..schemas.note import (
    ChecklistItem,
    ConvertNoteToTodoRequest,
    DuplicateLinkResponse,
    NoteAttachmentResponse,
    NoteColorRequest,
    NoteCommentCreate,
    NoteCommentResponse,
    NoteCreate,
    NoteReorderRequest,
    NoteResponse,
    NoteType,
    NoteUpdate,
    PreviewLinkRequest,
    PreviewLinkResponse,
)
from ..schemas.note_category import NoteCategoryResponse
from ..schemas.note_tag import NoteTagResponse
from ..schemas.todo import TodoResponse
from ..utils import resolve_members
from ..link_preview import fetch_link_preview

router = APIRouter(
    prefix="/api/notes",
    tags=["notes"],
    dependencies=[Depends(get_current_user)],
)

_note_load = [
    selectinload(Note.category),
    selectinload(Note.created_by),
    selectinload(Note.tags),
    selectinload(Note.comments).selectinload(NoteComment.member),
    selectinload(Note.attachments),
]

_todo_load_for_convert = [
    selectinload(Todo.category),
    selectinload(Todo.created_by),
    selectinload(Todo.members),
    selectinload(Todo.subtodos),
]


def _normalize_url(u: str) -> str:
    raw = u.strip()
    p = urlparse(raw)
    if not p.scheme or not p.netloc:
        return raw.lower()
    scheme = p.scheme.lower()
    netloc = p.netloc.lower()
    path = (p.path or "").rstrip("/")
    return urlunparse((scheme, netloc, path, "", p.query, "")).lower()


def _can_read_note(note: Note, current_member_id: int) -> bool:
    if note.is_personal:
        return note.created_by_member_id == current_member_id
    return True


def _can_edit_note(note: Note, current_member_id: int) -> bool:
    if note.is_personal:
        return note.created_by_member_id == current_member_id
    return True


def _note_to_response(note: Note) -> NoteResponse:
    checklist: list[ChecklistItem] | None = None
    if note.checklist_json:
        try:
            raw = json.loads(note.checklist_json)
            checklist = [ChecklistItem.model_validate(x) for x in raw]
        except Exception:
            checklist = []
    comments = [
        NoteCommentResponse(
            id=c.id,
            member=FamilyMemberResponse.model_validate(c.member) if c.member else None,
            content=c.content,
            created_at=c.created_at,
        )
        for c in note.comments
    ]
    attachments = [
        NoteAttachmentResponse(
            id=a.id,
            filename=a.filename,
            content_type=a.content_type,
            file_size=a.file_size,
            created_at=a.created_at,
            download_url=f"/api/notes/{note.id}/attachments/{a.id}/download",
        )
        for a in note.attachments
    ]
    return NoteResponse(
        id=note.id,
        is_personal=note.is_personal,
        created_by_member_id=note.created_by_member_id,
        created_by=FamilyMemberResponse.model_validate(note.created_by)
        if note.created_by
        else None,
        type=note.type,
        title=note.title,
        content=note.content,
        url=note.url,
        link_title=note.link_title,
        link_description=note.link_description,
        link_thumbnail_url=note.link_thumbnail_url,
        link_domain=note.link_domain,
        checklist_items=checklist,
        is_pinned=note.is_pinned,
        is_archived=note.is_archived,
        color=note.color,
        category=NoteCategoryResponse.model_validate(note.category) if note.category else None,
        tags=[NoteTagResponse.model_validate(t) for t in note.tags],
        comments=comments,
        attachments=attachments,
        reminder_at=note.reminder_at,
        position=note.position,
        created_at=note.created_at,
        updated_at=note.updated_at,
    )


async def _get_note_or_404(
    db: AsyncSession, note_id: int, family_id: int, member_id: int,
) -> Note:
    result = await db.execute(
        select(Note)
        .options(*_note_load)
        .where(Note.id == note_id, Note.family_id == family_id)
    )
    note = result.scalar_one_or_none()
    if not note or not _can_read_note(note, member_id):
        raise HTTPException(status_code=404, detail="Notiz nicht gefunden")
    return note


async def _resolve_tags(db: AsyncSession, tag_ids: list[int], family_id: int) -> list[NoteTag]:
    if not tag_ids:
        return []
    result = await db.execute(
        select(NoteTag).where(
            NoteTag.id.in_(tag_ids),
            NoteTag.family_id == family_id,
        )
    )
    tags = result.scalars().all()
    if len(tags) != len(tag_ids):
        raise HTTPException(status_code=400, detail="Ein oder mehrere Tags nicht gefunden")
    return list(tags)


async def _reload_note(db: AsyncSession, note_id: int) -> Note:
    result = await db.execute(
        select(Note).options(*_note_load).where(Note.id == note_id)
    )
    return result.scalar_one()


@router.get("/", response_model=list[NoteResponse])
async def list_notes(
    scope: str = Query("all", pattern="^(all|personal|family)$"),
    category_id: int | None = Query(None),
    note_type: str | None = Query(None, pattern="^(text|link|checklist)$", alias="type"),
    tag_id: int | None = Query(None),
    search: str | None = Query(None),
    is_archived: bool = Query(False),
    is_pinned: bool | None = Query(None),
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
):
    stmt = select(Note).options(*_note_load).where(Note.family_id == family_id)

    if scope == "personal":
        stmt = stmt.where(
            Note.is_personal.is_(True),
            Note.created_by_member_id == current_member_id,
        )
    elif scope == "family":
        stmt = stmt.where(Note.is_personal.is_(False))
    else:
        stmt = stmt.where(
            (Note.is_personal.is_(True) & (Note.created_by_member_id == current_member_id))
            | (Note.is_personal.is_(False))
        )

    stmt = stmt.where(Note.is_archived == is_archived)

    if category_id is not None:
        stmt = stmt.where(Note.category_id == category_id)
    if note_type:
        stmt = stmt.where(Note.type == note_type)
    if tag_id is not None:
        stmt = stmt.where(Note.tags.any(NoteTag.id == tag_id))
    if search and search.strip():
        q = f"%{search.strip()}%"
        stmt = stmt.where(
            or_(
                Note.title.ilike(q),
                Note.content.ilike(q),
                Note.url.ilike(q),
            )
        )
    if is_pinned is not None:
        stmt = stmt.where(Note.is_pinned == is_pinned)

    stmt = stmt.order_by(
        Note.is_pinned.desc(),
        Note.position.asc(),
        Note.created_at.desc(),
    )
    result = await db.execute(stmt)
    notes = result.scalars().unique().all()
    return [_note_to_response(n) for n in notes]


@router.post("/preview-link", response_model=PreviewLinkResponse)
async def preview_link(data: PreviewLinkRequest):
    meta = await fetch_link_preview(data.url)
    return PreviewLinkResponse(**meta)


@router.get("/check-duplicate-link", response_model=DuplicateLinkResponse)
async def check_duplicate_link(
    url: str = Query(..., min_length=1),
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
):
    want = _normalize_url(url)
    result = await db.execute(
        select(Note).where(
            Note.family_id == family_id,
            Note.type == "link",
            Note.url.isnot(None),
        )
    )
    for note in result.scalars().all():
        if note.url and _normalize_url(note.url) == want:
            return DuplicateLinkResponse(exists=True, note_id=note.id, title=note.title)
    return DuplicateLinkResponse(exists=False)


@router.put("/reorder", status_code=status.HTTP_204_NO_CONTENT)
async def reorder_notes(
    data: NoteReorderRequest,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
):
    if not data.ids:
        return
    result = await db.execute(
        select(Note).where(
            Note.family_id == family_id,
            Note.id.in_(data.ids),
        )
    )
    by_id = {n.id: n for n in result.scalars().all()}
    missing = [i for i in data.ids if i not in by_id]
    if missing:
        raise HTTPException(status_code=400, detail="Ungültige Notiz-IDs")
    for n in by_id.values():
        if not _can_edit_note(n, current_member_id):
            raise HTTPException(status_code=403, detail="Keine Berechtigung zum Sortieren")
    for idx, nid in enumerate(data.ids):
        by_id[nid].position = idx
    await db.flush()


@router.post("/", response_model=NoteResponse, status_code=status.HTTP_201_CREATED)
async def create_note(
    data: NoteCreate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
):
    if data.category_id is not None:
        from ..models.note_category import NoteCategory

        r = await db.execute(
            select(NoteCategory).where(
                NoteCategory.id == data.category_id,
                NoteCategory.family_id == family_id,
            )
        )
        if not r.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Notiz-Kategorie nicht gefunden")

    title_norm = (data.title or "").strip()[:200]
    if data.type == NoteType.text:
        if not title_norm and not (data.content or "").strip():
            raise HTTPException(
                status_code=400, detail="Titel oder Inhalt der Notiz erforderlich"
            )
    elif data.type == NoteType.link:
        if not (data.url or "").strip():
            raise HTTPException(status_code=400, detail="URL erforderlich")
    elif data.type == NoteType.checklist:
        items = data.checklist_items or []
        if not any(i.text.strip() for i in items):
            raise HTTPException(
                status_code=400, detail="Mindestens ein Listenpunkt erforderlich"
            )

    checklist_json = None
    if data.type == NoteType.checklist and data.checklist_items is not None:
        checklist_json = json.dumps([i.model_dump() for i in data.checklist_items])
    elif data.type == NoteType.checklist:
        checklist_json = "[]"

    link_title = link_description = link_thumbnail_url = link_domain = None
    url = data.url
    if data.type == NoteType.link and url:
        meta = await fetch_link_preview(url)
        link_title = meta.get("link_title")
        link_description = meta.get("link_description")
        link_thumbnail_url = meta.get("link_thumbnail_url")
        link_domain = meta.get("link_domain")

    max_pos = await db.scalar(
        select(func.coalesce(func.max(Note.position), 0)).where(Note.family_id == family_id)
    )
    tags = await _resolve_tags(db, data.tag_ids, family_id)

    note = Note(
        family_id=family_id,
        created_by_member_id=current_member_id,
        is_personal=data.is_personal,
        type=data.type.value,
        title=title_norm,
        content=data.content,
        url=url if data.type == NoteType.link else None,
        link_title=link_title,
        link_description=link_description,
        link_thumbnail_url=link_thumbnail_url,
        link_domain=link_domain,
        checklist_json=checklist_json,
        color=data.color,
        category_id=data.category_id,
        reminder_at=data.reminder_at,
        position=int(max_pos or 0) + 1,
        tags=tags,
    )
    db.add(note)
    await db.flush()
    note = await _reload_note(db, note.id)
    return _note_to_response(note)


@router.get("/{note_id}", response_model=NoteResponse)
async def get_note(
    note_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
):
    note = await _get_note_or_404(db, note_id, family_id, current_member_id)
    return _note_to_response(note)


@router.put("/{note_id}", response_model=NoteResponse)
async def update_note(
    note_id: int,
    data: NoteUpdate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
):
    note = await _get_note_or_404(db, note_id, family_id, current_member_id)
    if not _can_edit_note(note, current_member_id):
        raise HTTPException(status_code=403, detail="Keine Berechtigung")

    update_data = data.model_dump(exclude_unset=True)
    tag_ids = update_data.pop("tag_ids", None)
    checklist_items = update_data.pop("checklist_items", None)
    new_type = update_data.pop("type", None)

    if new_type is not None:
        note.type = new_type.value

    for key in ("title", "content", "url", "is_personal", "category_id", "color", "reminder_at"):
        if key in update_data:
            setattr(note, key, update_data[key])

    for key in ("link_title", "link_description", "link_thumbnail_url", "link_domain"):
        if key in update_data:
            setattr(note, key, update_data[key])

    if "category_id" in update_data and update_data["category_id"] is not None:
        from ..models.note_category import NoteCategory

        r = await db.execute(
            select(NoteCategory).where(
                NoteCategory.id == update_data["category_id"],
                NoteCategory.family_id == family_id,
            )
        )
        if not r.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Notiz-Kategorie nicht gefunden")

    if checklist_items is not None:
        note.checklist_json = json.dumps([i.model_dump() for i in checklist_items])

    if tag_ids is not None:
        note.tags = await _resolve_tags(db, tag_ids, family_id)

    url_changed = "url" in update_data
    if note.type == "link" and note.url and (url_changed or new_type == NoteType.link):
        meta = await fetch_link_preview(note.url)
        note.link_title = meta.get("link_title") or note.link_title
        note.link_description = meta.get("link_description") or note.link_description
        note.link_thumbnail_url = meta.get("link_thumbnail_url") or note.link_thumbnail_url
        note.link_domain = meta.get("link_domain") or note.link_domain

    note.updated_at = utcnow()
    await db.flush()
    note = await _reload_note(db, note.id)
    return _note_to_response(note)


@router.delete("/{note_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_note(
    note_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
):
    note = await _get_note_or_404(db, note_id, family_id, current_member_id)
    if not _can_edit_note(note, current_member_id):
        raise HTTPException(status_code=403, detail="Keine Berechtigung")
    for att in list(note.attachments):
        p = Path(att.stored_path)
        if p.is_file():
            try:
                p.unlink()
            except OSError:
                pass
    await db.delete(note)


@router.patch("/{note_id}/pin", response_model=NoteResponse)
async def toggle_pin(
    note_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
):
    note = await _get_note_or_404(db, note_id, family_id, current_member_id)
    if not _can_edit_note(note, current_member_id):
        raise HTTPException(status_code=403, detail="Keine Berechtigung")
    note.is_pinned = not note.is_pinned
    note.updated_at = utcnow()
    await db.flush()
    note = await _reload_note(db, note.id)
    return _note_to_response(note)


@router.patch("/{note_id}/archive", response_model=NoteResponse)
async def toggle_archive(
    note_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
):
    note = await _get_note_or_404(db, note_id, family_id, current_member_id)
    if not _can_edit_note(note, current_member_id):
        raise HTTPException(status_code=403, detail="Keine Berechtigung")
    note.is_archived = not note.is_archived
    note.updated_at = utcnow()
    await db.flush()
    note = await _reload_note(db, note.id)
    return _note_to_response(note)


@router.patch("/{note_id}/color", response_model=NoteResponse)
async def set_color(
    note_id: int,
    data: NoteColorRequest,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
):
    note = await _get_note_or_404(db, note_id, family_id, current_member_id)
    if not _can_edit_note(note, current_member_id):
        raise HTTPException(status_code=403, detail="Keine Berechtigung")
    if data.color is not None and not re.match(r"^#[0-9A-Fa-f]{6}$", data.color):
        raise HTTPException(status_code=400, detail="Ungültige Farbe (erwartet #RRGGBB)")
    note.color = data.color
    note.updated_at = utcnow()
    await db.flush()
    note = await _reload_note(db, note.id)
    return _note_to_response(note)


@router.post("/{note_id}/convert-to-todo", response_model=TodoResponse)
async def convert_note_to_todo(
    note_id: int,
    data: ConvertNoteToTodoRequest,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
):
    note = await _get_note_or_404(db, note_id, family_id, current_member_id)
    if not _can_edit_note(note, current_member_id):
        raise HTTPException(status_code=403, detail="Keine Berechtigung")

    desc_parts = []
    if note.content:
        desc_parts.append(note.content)
    if note.type == "link" and note.url:
        desc_parts.append(note.url)
    description = "\n\n".join(desc_parts) if desc_parts else None

    title_raw = (note.title or "").strip()[:200]
    if not title_raw:
        if note.type == "link":
            title_raw = (
                (note.link_title or "").strip()
                or (note.link_domain or "").strip()
                or (note.url or "").strip()
            )[:200]
        if not title_raw and note.content:
            title_raw = (note.content.strip().split("\n")[0].strip())[:200]
        if not title_raw:
            title_raw = "Aus Notiz"

    members = []
    if not note.is_personal:
        members = await resolve_members(db, [current_member_id], family_id)

    todo = Todo(
        family_id=family_id,
        created_by_member_id=current_member_id,
        is_personal=note.is_personal,
        title=title_raw,
        description=description,
        priority="medium",
        members=members,
    )
    db.add(todo)
    await db.flush()
    if data.archive_note:
        note.is_archived = True
        note.updated_at = utcnow()
    await db.flush()

    result = await db.execute(
        select(Todo).options(*_todo_load_for_convert).where(Todo.id == todo.id)
    )
    created = result.scalar_one()
    return TodoResponse.model_validate(created)


@router.post("/{note_id}/comments", response_model=NoteCommentResponse, status_code=status.HTTP_201_CREATED)
async def add_comment(
    note_id: int,
    data: NoteCommentCreate,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
):
    note = await _get_note_or_404(db, note_id, family_id, current_member_id)
    comment = NoteComment(note_id=note.id, member_id=current_member_id, content=data.content.strip())
    db.add(comment)
    await db.flush()
    await db.refresh(comment)
    from ..models.family_member import FamilyMember

    m_result = await db.execute(select(FamilyMember).where(FamilyMember.id == current_member_id))
    member = m_result.scalar_one_or_none()
    return NoteCommentResponse(
        id=comment.id,
        member=FamilyMemberResponse.model_validate(member) if member else None,
        content=comment.content,
        created_at=comment.created_at,
    )


@router.delete("/{note_id}/comments/{comment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_comment(
    note_id: int,
    comment_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
):
    note = await _get_note_or_404(db, note_id, family_id, current_member_id)
    result = await db.execute(
        select(NoteComment).where(
            NoteComment.id == comment_id,
            NoteComment.note_id == note.id,
        )
    )
    comment = result.scalar_one_or_none()
    if not comment:
        raise HTTPException(status_code=404, detail="Kommentar nicht gefunden")
    if comment.member_id != current_member_id and note.created_by_member_id != current_member_id:
        raise HTTPException(status_code=403, detail="Keine Berechtigung")
    await db.delete(comment)


@router.post("/{note_id}/attachments", response_model=NoteAttachmentResponse, status_code=status.HTTP_201_CREATED)
async def upload_attachment(
    note_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
    file: UploadFile = File(...),
):
    note = await _get_note_or_404(db, note_id, family_id, current_member_id)
    if not _can_edit_note(note, current_member_id):
        raise HTTPException(status_code=403, detail="Keine Berechtigung")

    upload_root = Path(settings.UPLOAD_DIR)
    upload_root.mkdir(parents=True, exist_ok=True)

    body = await file.read()
    if len(body) > settings.MAX_NOTE_ATTACHMENT_BYTES:
        raise HTTPException(status_code=413, detail="Datei zu groß (max. 10 MB)")

    safe_name = re.sub(r"[^A-Za-z0-9._-]", "_", file.filename or "upload")
    stored_name = f"{note.id}_{uuid.uuid4().hex}_{safe_name}"
    stored_path = upload_root / stored_name
    stored_path.write_bytes(body)

    att = NoteAttachment(
        note_id=note.id,
        filename=file.filename or "upload",
        stored_path=str(stored_path),
        content_type=file.content_type or "application/octet-stream",
        file_size=len(body),
    )
    db.add(att)
    await db.flush()
    await db.refresh(att)
    return NoteAttachmentResponse(
        id=att.id,
        filename=att.filename,
        content_type=att.content_type,
        file_size=att.file_size,
        created_at=att.created_at,
        download_url=f"/api/notes/{note.id}/attachments/{att.id}/download",
    )


@router.delete("/{note_id}/attachments/{attachment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_attachment(
    note_id: int,
    attachment_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
):
    note = await _get_note_or_404(db, note_id, family_id, current_member_id)
    if not _can_edit_note(note, current_member_id):
        raise HTTPException(status_code=403, detail="Keine Berechtigung")
    result = await db.execute(
        select(NoteAttachment).where(
            NoteAttachment.id == attachment_id,
            NoteAttachment.note_id == note.id,
        )
    )
    att = result.scalar_one_or_none()
    if not att:
        raise HTTPException(status_code=404, detail="Anhang nicht gefunden")
    p = Path(att.stored_path)
    if p.is_file():
        try:
            p.unlink()
        except OSError:
            pass
    await db.delete(att)


@router.get("/{note_id}/attachments/{attachment_id}/download")
async def download_attachment(
    note_id: int,
    attachment_id: int,
    db: AsyncSession = Depends(get_db),
    family_id: int = Depends(require_family_id),
    current_member_id: int = Depends(require_member_id),
):
    note = await _get_note_or_404(db, note_id, family_id, current_member_id)
    result = await db.execute(
        select(NoteAttachment).where(
            NoteAttachment.id == attachment_id,
            NoteAttachment.note_id == note.id,
        )
    )
    att = result.scalar_one_or_none()
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
