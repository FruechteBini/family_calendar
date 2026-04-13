"""Expand stored recurrence rules into concrete occurrence start datetimes."""

from __future__ import annotations

import calendar
import hashlib
import json
from datetime import date, datetime, timedelta, timezone
from typing import Any, Literal

Frequency = Literal["daily", "weekly", "monthly", "yearly"]


def _as_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _add_months(d: date, months: int) -> date:
    m = d.month - 1 + months
    y = d.year + m // 12
    m = m % 12 + 1
    last = calendar.monthrange(y, m)[1]
    return date(y, m, min(d.day, last))


def _add_years(d: date, years: int) -> date:
    return _add_months(d, years * 12)


def _parse_rules_json(raw: str | None) -> list[dict[str, Any]]:
    if not raw or not raw.strip():
        return []
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return []
    if not isinstance(data, list):
        return []
    return [x for x in data if isinstance(x, dict)]


def _rule_dates(
    rule: dict[str, Any],
    series_start: date,
    horizon_start: date,
    horizon_end: date,
) -> list[date]:
    freq = rule.get("frequency")
    if freq not in ("daily", "weekly", "monthly", "yearly"):
        return []

    interval = int(rule.get("interval") or 1)
    if interval < 1:
        interval = 1

    until_d: date | None = None
    until_raw = rule.get("until")
    if until_raw:
        try:
            until_dt = datetime.fromisoformat(str(until_raw).replace("Z", "+00:00"))
            until_d = until_dt.date()
        except ValueError:
            pass

    max_n: int | None = None
    if rule.get("count") is not None:
        try:
            max_n = int(rule["count"])
        except (TypeError, ValueError):
            max_n = None
        if max_n is not None and max_n < 1:
            max_n = None

    end_cap = min(horizon_end, until_d) if until_d else horizon_end
    if series_start > end_cap:
        return []

    hs = max(horizon_start, series_start)
    out: list[date] = []
    seen: set[date] = set()

    def take(d: date) -> None:
        if d < hs or d > end_cap:
            return
        if d in seen:
            return
        seen.add(d)
        out.append(d)

    if freq == "daily":
        delta_days = (hs - series_start).days
        if delta_days <= 0:
            n0 = 0
        else:
            n0 = (delta_days + interval - 1) // interval
        d0 = series_start + timedelta(days=n0 * interval)
        while d0 <= end_cap:
            if max_n is not None and len(out) >= max_n:
                break
            take(d0)
            d0 += timedelta(days=interval)

    elif freq == "weekly":
        by_weekday = rule.get("by_weekday")
        weekdays: set[int]
        if isinstance(by_weekday, list) and by_weekday:
            weekdays = set()
            for w in by_weekday:
                try:
                    wi = int(w)
                except (TypeError, ValueError):
                    continue
                if 1 <= wi <= 7:
                    weekdays.add(wi)
        else:
            weekdays = {series_start.isoweekday()}

        week0_monday = series_start - timedelta(days=series_start.isoweekday() - 1)
        current_monday = week0_monday
        while current_monday <= end_cap + timedelta(days=6):
            weeks_passed = (current_monday - week0_monday).days // 7
            if weeks_passed % interval == 0:
                for wd in sorted(weekdays):
                    if max_n is not None and len(out) >= max_n:
                        break
                    d = current_monday + timedelta(days=wd - 1)
                    take(d)
            if max_n is not None and len(out) >= max_n:
                break
            current_monday += timedelta(weeks=1)

    elif freq == "monthly":
        k = 0
        while True:
            if max_n is not None and len(out) >= max_n:
                break
            cand = _add_months(series_start, k * interval)
            k += 1
            if cand > end_cap:
                break
            take(cand)

    elif freq == "yearly":
        k = 0
        while True:
            if max_n is not None and len(out) >= max_n:
                break
            cand = _add_years(series_start, k * interval)
            k += 1
            if cand > end_cap:
                break
            take(cand)

    out.sort()
    if max_n is not None:
        out = out[:max_n]
    return out


def occurrence_starts_for_event(
    event_start: datetime,
    event_end: datetime,
    recurrence_rules_json: str | None,
    range_start: datetime,
    range_end: datetime,
) -> list[tuple[datetime, datetime]]:
    rules = _parse_rules_json(recurrence_rules_json)
    if not rules:
        return []

    es = _as_utc(event_start)
    ee = _as_utc(event_end)
    if ee < es:
        ee = es

    rs = _as_utc(range_start)
    re = _as_utc(range_end)

    duration = ee - es
    series_start_d = es.date()
    horizon_start_d = rs.date()
    horizon_end_d = re.date()

    uniq: dict[datetime, None] = {}

    for rule in rules:
        for d in _rule_dates(rule, series_start_d, horizon_start_d, horizon_end_d):
            occ_start = datetime(
                d.year,
                d.month,
                d.day,
                es.hour,
                es.minute,
                es.second,
                es.microsecond,
                tzinfo=timezone.utc,
            )
            occ_end = occ_start + duration
            if occ_end < rs or occ_start > re:
                continue
            uniq.setdefault(occ_start, None)

    return sorted((s, s + duration) for s in uniq.keys())


def recurrence_occurrence_entity_id(event_id: int, occurrence_start: datetime) -> int:
    key = f"{event_id}:{_as_utc(occurrence_start).isoformat()}".encode()
    h = hashlib.sha256(key).digest()[:8]
    return int.from_bytes(h, "big") & 0x7FFFFFFFFFFFFFFF
