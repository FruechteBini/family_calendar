"""Fetch Open Graph / basic HTML metadata for a URL (async)."""

from __future__ import annotations

import logging
from urllib.parse import urlparse

import httpx
from bs4 import BeautifulSoup

logger = logging.getLogger("kalender.notes")

_DEFAULT_UA = (
    "Mozilla/5.0 (compatible; FamilienkalenderBot/1.0; +https://example.com) "
    "AppleWebKit/537.36 (KHTML, like Gecko)"
)
_TIMEOUT = httpx.Timeout(12.0, connect=5.0)


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
    if t and t.string:
        return t.string.strip() or None
    return None


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
            headers={"User-Agent": _DEFAULT_UA},
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

    title = _meta_content(soup, "og:title") or _title_tag(soup)
    desc = _meta_content(soup, "og:description") or _meta_content(soup, "description")
    image = _meta_content(soup, "og:image")

    out["link_title"] = title
    out["link_description"] = desc
    out["link_thumbnail_url"] = image
    return out
