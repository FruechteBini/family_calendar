import hashlib
import logging
from datetime import date, datetime, timedelta, timezone

from google.auth.transport.requests import Request as GoogleRequest
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .database import utcnow
from .models.event import Event
from .models.google_sync import GoogleCalendarSync, GoogleTasksSync
from .models.todo import Todo
from .models.user import User

logger = logging.getLogger("kalender")


def _dt_from_rfc3339(value: str) -> datetime:
    # Handles "Z" and timezone offsets.
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def _ensure_utc(dt: datetime) -> datetime:
    """DB/API may mix naive and aware timestamps; normalize before comparing."""
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _hash_dict(d: dict) -> str:
    raw = repr(sorted(d.items())).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()


def _event_to_google_body(event: Event) -> dict:
    body: dict = {
        "summary": event.title,
        "description": event.description or "",
    }
    if event.all_day:
        start_date = event.start.date()
        # Google all-day end is exclusive
        end_date = (event.end.date() if event.end else start_date) + timedelta(days=1)
        body["start"] = {"date": start_date.isoformat()}
        body["end"] = {"date": end_date.isoformat()}
    else:
        body["start"] = {"dateTime": event.start.isoformat()}
        body["end"] = {"dateTime": event.end.isoformat()}
    return body


def _google_event_to_local_fields(ge: dict) -> dict:
    summary = ge.get("summary") or "(Ohne Titel)"
    description = ge.get("description")
    start = ge.get("start") or {}
    end = ge.get("end") or {}
    all_day = False
    if "date" in start:
        all_day = True
        s = date.fromisoformat(start["date"])
        e = date.fromisoformat((end.get("date") or start["date"]))
        # end is exclusive; store end as next midnight
        start_dt = datetime(s.year, s.month, s.day, tzinfo=timezone.utc)
        end_dt = datetime(e.year, e.month, e.day, tzinfo=timezone.utc)
    else:
        start_dt = _dt_from_rfc3339(start["dateTime"]).astimezone(timezone.utc)
        end_dt = _dt_from_rfc3339(end["dateTime"]).astimezone(timezone.utc)
    return {
        "title": summary,
        "description": description,
        "start": start_dt,
        "end": end_dt,
        "all_day": all_day,
    }


def _todo_to_google_body(todo: Todo) -> dict:
    body: dict = {
        "title": todo.title,
        "notes": todo.description or "",
        "status": "completed" if todo.completed else "needsAction",
    }
    if todo.due_date:
        # Tasks API expects RFC3339 dateTime for due (midnight UTC works well)
        due_dt = datetime(todo.due_date.year, todo.due_date.month, todo.due_date.day, tzinfo=timezone.utc)
        body["due"] = due_dt.isoformat().replace("+00:00", "Z")
    return body


def _google_task_to_local_fields(gt: dict) -> dict:
    title = gt.get("title") or "(Ohne Titel)"
    notes = gt.get("notes")
    status = gt.get("status") or "needsAction"
    completed = status == "completed"
    due_date = None
    if gt.get("due"):
        due_date = _dt_from_rfc3339(gt["due"]).date()
    return {
        "title": title,
        "description": notes,
        "completed": completed,
        "due_date": due_date,
    }


class GoogleSyncService:
    def build_credentials(self, user: User) -> Credentials:
        if not user.google_access_token or not user.google_refresh_token:
            raise ValueError("Missing Google tokens")
        creds = Credentials(
            token=user.google_access_token,
            refresh_token=user.google_refresh_token,
            token_uri="https://oauth2.googleapis.com/token",
            client_id=None,
            client_secret=None,
            expiry=user.google_token_expiry,
            scopes=None,
        )
        # google-auth needs client_id/client_secret for refresh; attach via private fields
        # These will be injected by caller via creds._client_id/_client_secret
        return creds

    async def _get_calendar_service(self, user: User, creds: Credentials):
        return build("calendar", "v3", credentials=creds, cache_discovery=False)

    async def _get_tasks_service(self, user: User, creds: Credentials):
        return build("tasks", "v1", credentials=creds, cache_discovery=False)

    async def _refresh_if_needed(self, user: User, creds: Credentials, client_id: str, client_secret: str, db: AsyncSession) -> Credentials:
        creds._client_id = client_id  # type: ignore[attr-defined]
        creds._client_secret = client_secret  # type: ignore[attr-defined]
        if creds.expired and creds.refresh_token:
            creds.refresh(GoogleRequest())
            user.google_access_token = creds.token
            user.google_token_expiry = creds.expiry
            await db.flush()
        return creds

    async def sync_calendar(self, *, user: User, db: AsyncSession, client_id: str, client_secret: str) -> None:
        if not user.sync_calendar_enabled:
            return
        if not user.google_refresh_token:
            raise ValueError("Google refresh token missing")

        creds = self.build_credentials(user)
        creds = await self._refresh_if_needed(user, creds, client_id, client_secret, db)
        service = await self._get_calendar_service(user, creds)
        calendar_id = user.google_calendar_id or "primary"

        # Limit sync window for performance
        time_min = (utcnow() - timedelta(days=365)).isoformat().replace("+00:00", "Z")
        time_max = (utcnow() + timedelta(days=365)).isoformat().replace("+00:00", "Z")
        google_items: dict[str, dict] = {}
        page_token = None
        while True:
            resp = (
                service.events()
                .list(
                    calendarId=calendar_id,
                    timeMin=time_min,
                    timeMax=time_max,
                    singleEvents=True,
                    showDeleted=True,
                    maxResults=2500,
                    pageToken=page_token,
                )
                .execute()
            )
            for it in resp.get("items", []) or []:
                gid = it.get("id")
                if gid:
                    google_items[gid] = it
            page_token = resp.get("nextPageToken")
            if not page_token:
                break

        # Local events (family-wide)
        res_local = await db.execute(select(Event).where(Event.family_id == user.family_id))
        local_events = {e.id: e for e in res_local.scalars().all()}

        res_map = await db.execute(
            select(GoogleCalendarSync).where(
                GoogleCalendarSync.family_id == user.family_id,
                GoogleCalendarSync.user_id == user.id,
                GoogleCalendarSync.google_calendar_id == calendar_id,
            )
        )
        mappings = res_map.scalars().all()
        map_by_event = {m.event_id: m for m in mappings}
        map_by_google = {m.google_event_id: m for m in mappings}

        # Deletions based on mappings
        for m in list(mappings):
            if m.event_id not in local_events:
                # local deleted => delete google
                try:
                    service.events().delete(calendarId=calendar_id, eventId=m.google_event_id).execute()
                except Exception:
                    pass
                await db.delete(m)
                continue
            ge = google_items.get(m.google_event_id)
            if not ge or ge.get("status") == "cancelled":
                # google deleted => delete local
                await db.delete(local_events[m.event_id])
                await db.delete(m)

        await db.flush()

        # Push local without mapping
        for event_id, event in local_events.items():
            if event_id in map_by_event:
                continue
            body = _event_to_google_body(event)
            created = service.events().insert(calendarId=calendar_id, body=body).execute()
            gid = created.get("id")
            if not gid:
                continue
            m = GoogleCalendarSync(
                family_id=user.family_id,
                user_id=user.id,
                event_id=event.id,
                google_calendar_id=calendar_id,
                google_event_id=gid,
                last_synced_at=utcnow(),
                last_local_hash=_hash_dict(body),
                last_google_hash=_hash_dict(created),
            )
            db.add(m)

        await db.flush()

        # Pull google without mapping
        for gid, ge in google_items.items():
            if ge.get("status") == "cancelled":
                continue
            if gid in map_by_google:
                continue
            fields = _google_event_to_local_fields(ge)
            ev = Event(
                family_id=user.family_id,
                title=fields["title"],
                description=fields["description"],
                start=fields["start"],
                end=fields["end"],
                all_day=fields["all_day"],
                category_id=None,
                notification_level_id=None,
                members=[],
            )
            db.add(ev)
            await db.flush()
            m = GoogleCalendarSync(
                family_id=user.family_id,
                user_id=user.id,
                event_id=ev.id,
                google_calendar_id=calendar_id,
                google_event_id=gid,
                last_synced_at=utcnow(),
            )
            db.add(m)

        await db.flush()

        # Resolve conflicts (last-write-wins)
        res_map2 = await db.execute(
            select(GoogleCalendarSync).where(
                GoogleCalendarSync.family_id == user.family_id,
                GoogleCalendarSync.user_id == user.id,
                GoogleCalendarSync.google_calendar_id == calendar_id,
            )
        )
        mappings2 = res_map2.scalars().all()
        for m in mappings2:
            ev = await db.get(Event, m.event_id)
            ge = google_items.get(m.google_event_id)
            if not ev or not ge or ge.get("status") == "cancelled":
                continue
            google_updated = (
                _ensure_utc(_dt_from_rfc3339(ge.get("updated"))) if ge.get("updated") else None
            )
            local_updated = _ensure_utc(ev.updated_at or ev.created_at)

            if google_updated and google_updated > local_updated:
                fields = _google_event_to_local_fields(ge)
                ev.title = fields["title"]
                ev.description = fields["description"]
                ev.start = fields["start"]
                ev.end = fields["end"]
                ev.all_day = fields["all_day"]
                m.last_synced_at = utcnow()
            elif google_updated and local_updated >= google_updated:
                body = _event_to_google_body(ev)
                updated = (
                    service.events()
                    .patch(calendarId=calendar_id, eventId=m.google_event_id, body=body)
                    .execute()
                )
                m.last_synced_at = utcnow()
                m.last_local_hash = _hash_dict(body)
                m.last_google_hash = _hash_dict(updated)

        await db.flush()

    async def sync_tasks(self, *, user: User, db: AsyncSession, client_id: str, client_secret: str) -> None:
        if not user.sync_todos_enabled:
            return
        if not user.google_refresh_token:
            raise ValueError("Google refresh token missing")

        creds = self.build_credentials(user)
        creds = await self._refresh_if_needed(user, creds, client_id, client_secret, db)
        service = await self._get_tasks_service(user, creds)

        tasklist_id = user.google_tasklist_id
        if not tasklist_id or tasklist_id == "@@default@@":
            # Resolve default tasklist
            tl_resp = service.tasklists().list(maxResults=50).execute()
            items = tl_resp.get("items") or []
            if items:
                tasklist_id = items[0].get("id") or "@default"
            else:
                tasklist_id = "@default"
            user.google_tasklist_id = tasklist_id
            await db.flush()

        google_tasks: dict[str, dict] = {}
        page_token = None
        while True:
            resp = (
                service.tasks()
                .list(
                    tasklist=tasklist_id,
                    showCompleted=True,
                    showHidden=True,
                    showDeleted=True,
                    maxResults=100,
                    pageToken=page_token,
                )
                .execute()
            )
            for it in resp.get("items", []) or []:
                gid = it.get("id")
                if gid:
                    google_tasks[gid] = it
            page_token = resp.get("nextPageToken")
            if not page_token:
                break

        res_local = await db.execute(select(Todo).where(Todo.family_id == user.family_id, Todo.parent_id.is_(None)))
        local_todos = {t.id: t for t in res_local.scalars().all()}

        res_map = await db.execute(
            select(GoogleTasksSync).where(
                GoogleTasksSync.family_id == user.family_id,
                GoogleTasksSync.user_id == user.id,
                GoogleTasksSync.google_tasklist_id == tasklist_id,
            )
        )
        mappings = res_map.scalars().all()
        map_by_todo = {m.todo_id: m for m in mappings}
        map_by_google = {m.google_task_id: m for m in mappings}

        for m in list(mappings):
            if m.todo_id not in local_todos:
                try:
                    service.tasks().delete(tasklist=tasklist_id, task=m.google_task_id).execute()
                except Exception:
                    pass
                await db.delete(m)
                continue
            gt = google_tasks.get(m.google_task_id)
            if not gt or gt.get("deleted") is True:
                await db.delete(local_todos[m.todo_id])
                await db.delete(m)

        await db.flush()

        for todo_id, todo in local_todos.items():
            if todo_id in map_by_todo:
                continue
            body = _todo_to_google_body(todo)
            created = service.tasks().insert(tasklist=tasklist_id, body=body).execute()
            gid = created.get("id")
            if not gid:
                continue
            db.add(
                GoogleTasksSync(
                    family_id=user.family_id,
                    user_id=user.id,
                    todo_id=todo.id,
                    google_tasklist_id=tasklist_id,
                    google_task_id=gid,
                    last_synced_at=utcnow(),
                    last_local_hash=_hash_dict(body),
                    last_google_hash=_hash_dict(created),
                )
            )

        await db.flush()

        for gid, gt in google_tasks.items():
            if gt.get("deleted") is True:
                continue
            if gid in map_by_google:
                continue
            fields = _google_task_to_local_fields(gt)
            todo = Todo(
                family_id=user.family_id,
                created_by_member_id=user.member_id,
                is_personal=False,
                title=fields["title"],
                description=fields["description"],
                priority="medium",
                due_date=fields["due_date"],
                completed=fields["completed"],
                completed_at=utcnow() if fields["completed"] else None,
                category_id=None,
                event_id=None,
                parent_id=None,
                requires_multiple=False,
                notification_level_id=None,
                members=[],
            )
            db.add(todo)
            await db.flush()
            db.add(
                GoogleTasksSync(
                    family_id=user.family_id,
                    user_id=user.id,
                    todo_id=todo.id,
                    google_tasklist_id=tasklist_id,
                    google_task_id=gid,
                    last_synced_at=utcnow(),
                )
            )

        await db.flush()

        res_map2 = await db.execute(
            select(GoogleTasksSync).where(
                GoogleTasksSync.family_id == user.family_id,
                GoogleTasksSync.user_id == user.id,
                GoogleTasksSync.google_tasklist_id == tasklist_id,
            )
        )
        mappings2 = res_map2.scalars().all()
        for m in mappings2:
            todo = await db.get(Todo, m.todo_id)
            gt = google_tasks.get(m.google_task_id)
            if not todo or not gt or gt.get("deleted") is True:
                continue
            google_updated = (
                _ensure_utc(_dt_from_rfc3339(gt.get("updated"))) if gt.get("updated") else None
            )
            local_updated = _ensure_utc(todo.updated_at or todo.created_at)

            if google_updated and google_updated > local_updated:
                fields = _google_task_to_local_fields(gt)
                todo.title = fields["title"]
                todo.description = fields["description"]
                todo.due_date = fields["due_date"]
                todo.completed = fields["completed"]
                todo.completed_at = utcnow() if fields["completed"] else None
                m.last_synced_at = utcnow()
            elif google_updated and local_updated >= google_updated:
                body = _todo_to_google_body(todo)
                updated = (
                    service.tasks()
                    .patch(tasklist=tasklist_id, task=m.google_task_id, body=body)
                    .execute()
                )
                m.last_synced_at = utcnow()
                m.last_local_hash = _hash_dict(body)
                m.last_google_hash = _hash_dict(updated)

        await db.flush()

    async def push_event_to_google(self, *, user: User, event: Event, db: AsyncSession, client_id: str, client_secret: str) -> None:
        if not user.sync_calendar_enabled:
            return
        creds = await self._refresh_if_needed(user, self.build_credentials(user), client_id, client_secret, db)
        service = await self._get_calendar_service(user, creds)
        calendar_id = user.google_calendar_id or "primary"

        res_map = await db.execute(
            select(GoogleCalendarSync).where(
                GoogleCalendarSync.family_id == user.family_id,
                GoogleCalendarSync.user_id == user.id,
                GoogleCalendarSync.event_id == event.id,
                GoogleCalendarSync.google_calendar_id == calendar_id,
            )
        )
        m = res_map.scalar_one_or_none()
        body = _event_to_google_body(event)
        if not m:
            created = service.events().insert(calendarId=calendar_id, body=body).execute()
            gid = created.get("id")
            if not gid:
                return
            db.add(
                GoogleCalendarSync(
                    family_id=user.family_id,
                    user_id=user.id,
                    event_id=event.id,
                    google_calendar_id=calendar_id,
                    google_event_id=gid,
                    last_synced_at=utcnow(),
                )
            )
        else:
            service.events().patch(calendarId=calendar_id, eventId=m.google_event_id, body=body).execute()
            m.last_synced_at = utcnow()
        await db.flush()

    async def delete_event_from_google(self, *, user: User, event_id: int, db: AsyncSession, client_id: str, client_secret: str) -> None:
        if not user.sync_calendar_enabled:
            return
        creds = await self._refresh_if_needed(user, self.build_credentials(user), client_id, client_secret, db)
        service = await self._get_calendar_service(user, creds)
        calendar_id = user.google_calendar_id or "primary"
        res_map = await db.execute(
            select(GoogleCalendarSync).where(
                GoogleCalendarSync.family_id == user.family_id,
                GoogleCalendarSync.user_id == user.id,
                GoogleCalendarSync.event_id == event_id,
                GoogleCalendarSync.google_calendar_id == calendar_id,
            )
        )
        m = res_map.scalar_one_or_none()
        if not m:
            return
        try:
            service.events().delete(calendarId=calendar_id, eventId=m.google_event_id).execute()
        finally:
            await db.delete(m)
            await db.flush()

    async def push_todo_to_google(self, *, user: User, todo: Todo, db: AsyncSession, client_id: str, client_secret: str) -> None:
        if not user.sync_todos_enabled:
            return
        creds = await self._refresh_if_needed(user, self.build_credentials(user), client_id, client_secret, db)
        service = await self._get_tasks_service(user, creds)
        tasklist_id = user.google_tasklist_id if user.google_tasklist_id != "@@default@@" else "@default"

        res_map = await db.execute(
            select(GoogleTasksSync).where(
                GoogleTasksSync.family_id == user.family_id,
                GoogleTasksSync.user_id == user.id,
                GoogleTasksSync.todo_id == todo.id,
                GoogleTasksSync.google_tasklist_id == tasklist_id,
            )
        )
        m = res_map.scalar_one_or_none()
        body = _todo_to_google_body(todo)
        if not m:
            created = service.tasks().insert(tasklist=tasklist_id, body=body).execute()
            gid = created.get("id")
            if not gid:
                return
            db.add(
                GoogleTasksSync(
                    family_id=user.family_id,
                    user_id=user.id,
                    todo_id=todo.id,
                    google_tasklist_id=tasklist_id,
                    google_task_id=gid,
                    last_synced_at=utcnow(),
                )
            )
        else:
            service.tasks().patch(tasklist=tasklist_id, task=m.google_task_id, body=body).execute()
            m.last_synced_at = utcnow()
        await db.flush()

    async def delete_todo_from_google(self, *, user: User, todo_id: int, db: AsyncSession, client_id: str, client_secret: str) -> None:
        if not user.sync_todos_enabled:
            return
        creds = await self._refresh_if_needed(user, self.build_credentials(user), client_id, client_secret, db)
        service = await self._get_tasks_service(user, creds)
        tasklist_id = user.google_tasklist_id if user.google_tasklist_id != "@@default@@" else "@default"
        res_map = await db.execute(
            select(GoogleTasksSync).where(
                GoogleTasksSync.family_id == user.family_id,
                GoogleTasksSync.user_id == user.id,
                GoogleTasksSync.todo_id == todo_id,
                GoogleTasksSync.google_tasklist_id == tasklist_id,
            )
        )
        m = res_map.scalar_one_or_none()
        if not m:
            return
        try:
            service.tasks().delete(tasklist=tasklist_id, task=m.google_task_id).execute()
        finally:
            await db.delete(m)
            await db.flush()

