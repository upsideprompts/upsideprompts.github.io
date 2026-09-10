# Check / Add AV Innovate Articles (OpenClaw Prompt)

Use this when searching for new AV hardware/innovation articles for `/innovateav`. **Never write candidates straight into `articles2.json`.**

## Goal

Find recent, real article pages about autonomous-vehicle hardware / compute / sensors / robotaxi platforms, stage them, validate them, and merge **only** URLs that still work.

## Hard rule

Add a candidate to the live list **only if**:

1. Final HTTP status is **200** (after redirects), and  
2. Page content looks like a real article (enough body text; not soft-404, parking, or empty shell), and  
3. The URL is **not already** in `articles2.json`.

If validation fails, leave `articles2.json` unchanged and record why.

## OpenClaw workflow

### 1) Search

Use OpenClaw web search for recent AV hardware / LiDAR / SoC / robotaxi compute coverage. Prefer primary publisher URLs (press rooms, trade press), not aggregators or guessed paths.

Example prompt:

```text
Search for recent news about autonomous vehicle hardware, LiDAR chips, AV SoCs, and robotaxi compute platforms. Return article title, publisher date, and canonical URL for each result.
```

### 2) Stage only (do not touch live JSON yet)

Write candidates into `innovateav/candidates.json` in this shape:

```json
{
  "articles": [
    {
      "category": "AV",
      "date": "YYYY-MM-DD",
      "link": "https://…",
      "title": "…"
    }
  ]
}
```

Optional OpenClaw commands while drafting:

```bash
openclaw run "Search for recent AV hardware / LiDAR / SoC / robotaxi compute articles and list title, date, and URL."
```

Use `web_fetch` on promising URLs to confirm title/date before staging:

```bash
openclaw run --skill web-scraper "Fetch this URL and extract the article title and publish date: <URL>"
```

### 3) Validate + merge (required gate)

From the repo:

```bash
cd innovateav
python3 validate_and_merge_articles.py --dry-run
python3 validate_and_merge_articles.py
```

Or:

```bash
./validate_and_merge_articles.sh
./validate_and_merge_articles.sh --dry-run
```

- Exit **0** with merges → verified articles were prepended to `articles2.json` (backup in `articlesavbak.json`).  
- Exit **non-zero** / no passes → **do not** invent replacements; leave the live list alone.  
- `candidates.json` is rewritten with `passed` / `failed` reasons.

### 4) Optional live health check

```bash
python3 validate_and_merge_articles.py --check-live
python3 validate_and_merge_articles.py --check-live --prune-broken --dry-run
python3 validate_and_merge_articles.py --check-live --prune-broken
```

### 5) Related OpenClaw search/verify cron (does not write live list)

`update_articles.sh` can search/verify URLs via OpenClaw + curl. It logs results only. After it finds good URLs, still stage them in `candidates.json` and run `validate_and_merge_articles.py`.

```bash
./update_articles.sh
```

## Files

| File | Role |
|------|------|
| `candidates.json` | Staging queue + last validation report |
| `articles2.json` | Live list served by `/innovateav` |
| `articlesavbak.json` | Backup before merge/prune |
| `validate_and_merge_articles.py` | HTTP + content gate, dedupe, merge |
| `new_articles_test.json` | Example of failed validation (404s not added) |

## Done checklist

- [ ] Candidates staged in `candidates.json` only  
- [ ] `validate_and_merge_articles.py` run (dry-run then real)  
- [ ] Live list updated **only** with passes  
- [ ] Failures left out with reasons recorded  
- [ ] Commit/push only after the gate succeeds  
