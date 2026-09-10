#!/usr/bin/env python3
"""
Gatekeeper for /innovateav article list.

Never write candidates straight into articles2.json.
Stage in candidates.json, validate HTTP + content, dedupe, then merge only passes.

Usage:
  python3 validate_and_merge_articles.py              # merge verified candidates
  python3 validate_and_merge_articles.py --dry-run    # validate only, no write
  python3 validate_and_merge_articles.py --check-live # re-check articles2.json links
  python3 validate_and_merge_articles.py --prune-broken  # with --check-live, drop fails
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import ssl
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from datetime import date
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

DIR = Path(__file__).resolve().parent
LIVE_PATH = DIR / "articles2.json"
CANDIDATES_PATH = DIR / "candidates.json"
BACKUP_PATH = DIR / "articlesavbak.json"

USER_AGENT = (
    "Mozilla/5.0 (compatible; UpsidePromptsArticleGate/1.0; +https://upsideprompts.github.io)"
)
TIMEOUT_SEC = 12
MAX_BYTES = 400_000
MIN_BODY_CHARS = 400

SOFT_404_PATTERNS = [
    re.compile(p, re.I)
    for p in [
        r"<title[^>]*>\s*(404|page not found|not found)\s*<",
        r"page not found",
        r"\b404\b.{0,40}not found",
        r"not found.{0,40}\b404\b",
        r"the page you(?:'|’)re looking for (?:can'?t|cannot|could not) be found",
        r"this page (?:does not|doesn'?t) exist",
        r"sorry,? (?:this|the) page.*(not found|doesn'?t exist|no longer)",
        r"domain (?:is )?for sale",
        r"buy this domain",
        r"parked (?:domain|page)",
        r"website coming soon",
        r"account suspended",
    ]
]

REQUIRED_FIELDS = ("title", "link", "date", "category")


def load_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as f:
        data = json.load(f)
    if isinstance(data, list):
        return {"articles": data}
    if not isinstance(data, dict):
        raise ValueError(f"Unexpected JSON root in {path}")
    data.setdefault("articles", [])
    return data


def save_json(path: Path, data: dict[str, Any]) -> None:
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def normalize_url(url: str) -> str:
    url = (url or "").strip()
    parsed = urlparse(url)
    if parsed.scheme not in ("http", "https") or not parsed.netloc:
        raise ValueError(f"Invalid URL: {url!r}")
    # Strip fragment; keep query (some CMS pages need it)
    return parsed._replace(fragment="").geturl()


def existing_links(articles: list[dict[str, Any]]) -> set[str]:
    links: set[str] = set()
    for a in articles:
        link = a.get("link")
        if not link:
            continue
        try:
            links.add(normalize_url(link))
        except ValueError:
            links.add(link.strip())
    return links


def fetch_url_urllib(url: str) -> tuple[int, str, str]:
    """Return (final_http_status, content_type, body_text) via urllib."""
    ctx = ssl.create_default_context()
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": USER_AGENT,
            "Accept": "text/html,application/xhtml+xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.8",
        },
        method="GET",
    )
    with urllib.request.urlopen(req, timeout=TIMEOUT_SEC, context=ctx) as resp:
        status = getattr(resp, "status", None) or resp.getcode()
        ctype = (resp.headers.get("Content-Type") or "").split(";")[0].strip().lower()
        raw = resp.read(MAX_BYTES)
        charset = "utf-8"
        hdr_ctype = resp.headers.get("Content-Type") or ""
        if "charset=" in hdr_ctype.lower():
            charset = hdr_ctype.split("charset=")[-1].split(";")[0].strip()
        try:
            body = raw.decode(charset, errors="replace")
        except LookupError:
            body = raw.decode("utf-8", errors="replace")
        return int(status), ctype, body


def fetch_url_curl(url: str) -> tuple[int, str, str]:
    """Fallback fetch via curl (better TLS / redirect behavior on some hosts)."""
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        body_path = tmp.name
    try:
        result = subprocess.run(
            [
                "curl",
                "-sS",
                "-L",
                "--max-redirs",
                "5",
                "--max-time",
                str(TIMEOUT_SEC),
                "-A",
                USER_AGENT,
                "-H",
                "Accept: text/html,application/xhtml+xml;q=0.9,*/*;q=0.8",
                "-o",
                body_path,
                "-w",
                "%{http_code}\n%{content_type}",
                url,
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode not in (0, 56, 28) and not result.stdout.strip():
            raise RuntimeError(result.stderr.strip() or f"curl exit {result.returncode}")
        lines = (result.stdout or "").strip().splitlines()
        if not lines:
            raise RuntimeError(result.stderr.strip() or "curl produced no status")
        status = int(lines[0].strip())
        ctype = lines[1].split(";")[0].strip().lower() if len(lines) > 1 else ""
        raw = Path(body_path).read_bytes()[:MAX_BYTES]
        body = raw.decode("utf-8", errors="replace")
        return status, ctype, body
    finally:
        Path(body_path).unlink(missing_ok=True)


def fetch_url(url: str) -> tuple[int, str, str]:
    """Return (final_http_status, content_type, body_text)."""
    try:
        return fetch_url_urllib(url)
    except urllib.error.HTTPError as e:
        raw = e.read(MAX_BYTES) if e.fp else b""
        ctype = (e.headers.get("Content-Type") if e.headers else "") or ""
        ctype = ctype.split(";")[0].strip().lower()
        body = raw.decode("utf-8", errors="replace")
        return int(e.code), ctype, body
    except Exception:
        try:
            return fetch_url_curl(url)
        except Exception as e:  # noqa: BLE001
            raise RuntimeError(f"network error: {e}") from e


def looks_like_soft_404(body: str) -> str | None:
    sample = body[:80_000]
    for pat in SOFT_404_PATTERNS:
        if pat.search(sample):
            return f"soft-404/block pattern: {pat.pattern}"
    # Thin / empty-ish pages
    text = re.sub(r"<script[\s\S]*?</script>", " ", sample, flags=re.I)
    text = re.sub(r"<style[\s\S]*?</style>", " ", text, flags=re.I)
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    if len(text) < MIN_BODY_CHARS:
        return f"insufficient article text ({len(text)} chars)"
    return None


def validate_article(article: dict[str, Any]) -> tuple[bool, str]:
    for field in REQUIRED_FIELDS:
        if not str(article.get(field, "")).strip():
            return False, f"missing required field: {field}"

    try:
        url = normalize_url(str(article["link"]))
    except ValueError as e:
        return False, str(e)

    try:
        status, ctype, body = fetch_url(url)
    except RuntimeError as e:
        return False, str(e)

    if status != 200:
        return False, f"HTTP {status} (need final 200)"

    if ctype and "html" not in ctype and "text/" not in ctype and "json" not in ctype:
        # Allow empty ctype; reject obvious binaries
        if ctype.startswith(("image/", "audio/", "video/", "application/pdf")):
            return False, f"non-article content-type: {ctype}"

    soft = looks_like_soft_404(body)
    if soft:
        return False, soft

    return True, "ok"


def clean_article(article: dict[str, Any]) -> dict[str, Any]:
    return {
        "category": str(article["category"]).strip(),
        "date": str(article["date"]).strip(),
        "link": normalize_url(str(article["link"])),
        "title": str(article["title"]).strip(),
    }


def merge_candidates(*, dry_run: bool) -> int:
    if not CANDIDATES_PATH.exists():
        print(f"No staging file at {CANDIDATES_PATH.name}; nothing to do.")
        return 0

    candidates_doc = load_json(CANDIDATES_PATH)
    candidates = candidates_doc.get("articles") or []
    if not candidates:
        print("candidates.json has no articles.")
        return 0

    live = load_json(LIVE_PATH)
    live_articles = list(live.get("articles") or [])
    seen = existing_links(live_articles)

    passed: list[dict[str, Any]] = []
    failed: list[dict[str, Any]] = []
    skipped_dupes = 0

    print(f"Validating {len(candidates)} candidate(s)…")
    for raw in candidates:
        link = str(raw.get("link", "")).strip()
        try:
            norm = normalize_url(link) if link else ""
        except ValueError:
            norm = link

        if norm and norm in seen:
            skipped_dupes += 1
            failed.append({**raw, "validationResult": "skip", "reason": "duplicate of live list"})
            print(f"  [SKIP] duplicate -> {link}")
            continue

        ok, reason = validate_article(raw)
        if ok:
            cleaned = clean_article(raw)
            passed.append(cleaned)
            seen.add(cleaned["link"])
            print(f"  [PASS] {cleaned['link']}")
        else:
            failed.append({**raw, "validationResult": "fail", "reason": reason})
            print(f"  [FAIL] {reason} -> {link}")

    today = date.today().isoformat()
    validation_id = hashlib.sha1(f"{today}:{len(passed)}:{len(failed)}".encode()).hexdigest()[:12]

    report = {
        "articles": candidates,
        "lastUpdated": today,
        "validationId": validation_id,
        "validationStatus": "completed" if passed else "failed",
        "passedCount": len(passed),
        "failedCount": len(failed),
        "skippedDuplicates": skipped_dupes,
        "passed": passed,
        "failed": [
            {
                "link": f.get("link"),
                "title": f.get("title"),
                "reason": f.get("reason"),
            }
            for f in failed
        ],
    }
    if not passed:
        report["validationFailure"] = (
            "No candidates passed HTTP 200 + content checks — articles not added"
        )

    if dry_run:
        print(f"\nDry run: would add {len(passed)} article(s); live file unchanged.")
        print(json.dumps(report, indent=2)[:2000])
        return 0 if passed or not candidates else 1

    # Persist staging report (keeps audit; clears queue of unverified adds)
    save_json(CANDIDATES_PATH, report)

    if not passed:
        print("\nNo verified articles to merge. articles2.json unchanged.")
        return 1

    # Backup then merge
    save_json(BACKUP_PATH, live)
    live_articles = passed + live_articles
    live["articles"] = live_articles
    live["lastUpdated"] = today
    live["lastCleanup"] = today
    live["validationId"] = validation_id
    live["validationStatus"] = "completed"
    live.pop("validationFailure", None)
    save_json(LIVE_PATH, live)

    print(f"\nMerged {len(passed)} article(s) into {LIVE_PATH.name} (backup: {BACKUP_PATH.name}).")
    return 0


def check_live(*, dry_run: bool, prune: bool) -> int:
    live = load_json(LIVE_PATH)
    articles = list(live.get("articles") or [])
    kept: list[dict[str, Any]] = []
    removed: list[dict[str, Any]] = []

    print(f"Checking {len(articles)} live article(s)…")
    for raw in articles:
        ok, reason = validate_article(raw)
        link = raw.get("link")
        if ok:
            kept.append(clean_article(raw))
            print(f"  [PASS] {link}")
        else:
            removed.append({**raw, "reason": reason})
            print(f"  [FAIL] {reason} -> {link}")

    today = date.today().isoformat()
    print(f"\n{len(kept)}/{len(articles)} still valid; {len(removed)} failed.")

    if not prune:
        return 0 if not removed else 1

    if dry_run:
        print(f"Dry run: would prune {len(removed)} broken link(s).")
        return 0 if not removed else 1

    save_json(BACKUP_PATH, live)
    live["articles"] = kept
    live["lastUpdated"] = today
    live["lastCleanup"] = today
    live["validationStatus"] = "completed"
    live["validationId"] = hashlib.sha1(f"prune:{today}:{len(removed)}".encode()).hexdigest()[:12]
    save_json(LIVE_PATH, live)
    print(f"Pruned {len(removed)} broken link(s); backup at {BACKUP_PATH.name}.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate and merge innovateav article candidates.")
    parser.add_argument("--dry-run", action="store_true", help="Validate without writing articles2.json")
    parser.add_argument(
        "--check-live",
        action="store_true",
        help="Re-validate links already in articles2.json",
    )
    parser.add_argument(
        "--prune-broken",
        action="store_true",
        help="With --check-live, remove URLs that fail validation",
    )
    args = parser.parse_args()

    if args.prune_broken and not args.check_live:
        parser.error("--prune-broken requires --check-live")

    if args.check_live:
        return check_live(dry_run=args.dry_run, prune=args.prune_broken)
    return merge_candidates(dry_run=args.dry_run)


if __name__ == "__main__":
    sys.exit(main())
