"""Fetch Open Graph / basic HTML metadata for a URL (async)."""

from __future__ import annotations

import logging
import re
from urllib.parse import urlparse

import httpx
from bs4 import BeautifulSoup

logger = logging.getLogger("kalender.notes")

# Browser-like UA: many sites (Reddit, etc.) omit og:title for generic/bot clients.
_DEFAULT_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7",
}
_TIMEOUT = httpx.Timeout(12.0, connect=5.0)

_URL_IN_CLIPBOARD = re.compile(r"https?://[^\s<>\[\]()]+", re.I)
_TRAIL_URL_PUNCT = ".,;:!?)]}'\"»«"


def looks_like_http_url(s: str) -> bool:
    t = s.strip()
    if not t:
        return False
    try:
        p = urlparse(t)
        return bool(p.scheme in ("http", "https") and p.netloc)
    except Exception:
        return False


def _trim_url_trailing_punct(url: str) -> str:
    s = url
    while len(s) > 1 and s[-1] in _TRAIL_URL_PUNCT:
        s = s[:-1]
    return s


def primary_url_from_paste_text(raw: str, *, max_chars_outside: int = 120) -> str | None:
    """
    If paste is a URL or a short blurb plus URL (quick paste / share), return that URL.
    Long text with an embedded link → None (keep as plain text note).
    Mirrors Flutter note_quick_capture.urlForLinkNote.
    """
    t = raw.strip()
    if not t:
        return None
    first_line = t.split("\n")[0].strip()
    if looks_like_http_url(t):
        return t
    if looks_like_http_url(first_line):
        return first_line
    m = _URL_IN_CLIPBOARD.search(t)
    if not m:
        return None
    u = _trim_url_trailing_punct(m.group(0))
    if not looks_like_http_url(u):
        return None
    rest = (t[: m.start()] + t[m.end() :]).strip()
    rest = re.sub(r"\s+", " ", rest)
    if len(rest) > max_chars_outside:
        return None
    return u


def _domain_from_url(url: str) -> str | None:
    try:
        p = urlparse(url.strip())
        if p.netloc:
            return p.netloc
    except Exception:
        pass
    return None


def _meta_content(soup: BeautifulSoup, prop: str) -> str | None:
    tag = soup.find("meta", property=prop) or soup.find("meta", attrs={"name": prop})
    if tag and tag.get("content"):
        return str(tag["content"]).strip() or None
    return None


def _title_tag(soup: BeautifulSoup) -> str | None:
    t = soup.find("title")
    if not t:
        return None
    text = t.get_text(strip=True)
    return text or None


async def fetch_link_preview(url: str) -> dict:
    """
    Returns keys: url, link_title, link_description, link_thumbnail_url, link_domain.
    On failure, still returns url and link_domain if parseable.
    """
    raw = url.strip()
    domain = _domain_from_url(raw)
    out: dict = {
        "url": raw,
        "link_title": None,
        "link_description": None,
        "link_thumbnail_url": None,
        "link_domain": domain,
    }
    if not raw.startswith(("http://", "https://")):
        return out

    try:
        async with httpx.AsyncClient(
            follow_redirects=True,
            timeout=_TIMEOUT,
            headers=_DEFAULT_HEADERS,
        ) as client:
            resp = await client.get(raw)
            resp.raise_for_status()
            ct = (resp.headers.get("content-type") or "").lower()
            if "html" not in ct and "text/plain" not in ct:
                return out
            html = resp.text[:2_000_000]  # cap size
    except Exception as e:
        logger.debug("link preview fetch failed for %s: %s", raw, e)
        return out

    try:
        soup = BeautifulSoup(html, "lxml")
    except Exception:
        soup = BeautifulSoup(html, "html.parser")

    title = (
        _meta_content(soup, "og:title")
        or _meta_content(soup, "twitter:title")
        or _title_tag(soup)
    )
    desc = _meta_content(soup, "og:description") or _meta_content(soup, "description")
    image = _meta_content(soup, "og:image")

    out["link_title"] = title
    out["link_description"] = desc
    out["link_thumbnail_url"] = image
    return out
