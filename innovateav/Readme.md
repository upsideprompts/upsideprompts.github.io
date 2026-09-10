# AV Innovate (`/innovateav`) — article list gate

The live page loads **`articles2.json`**. Candidates must never be written there directly.

## Hard rule

Add a candidate to `articles2.json` **only if**:

1. Final HTTP status is **200** (after redirects), and  
2. Fetched content looks like a real article (enough body text; not soft-404, parking, captcha wall, etc.), and  
3. The URL is **not already** in the live list.

## Workflow

1. **Stage** candidates in `candidates.json`:

```json
{
  "articles": [
    {
      "category": "AV",
      "date": "2026-09-10",
      "link": "https://example.com/real-article/",
      "title": "Example AV Hardware Story"
    }
  ]
}
```

2. **Validate + merge** (only passes are prepended to `articles2.json`):

```bash
cd innovateav
python3 validate_and_merge_articles.py          # merge verified
python3 validate_and_merge_articles.py --dry-run  # check only
```

Or: `./validate_and_merge_articles.sh`

3. On success:
   - Verified articles are merged into `articles2.json`
   - Previous live list is copied to `articlesavbak.json`
   - `candidates.json` is rewritten with a validation report (`passed` / `failed` / reasons)

4. On failure: live file is **unchanged** (same behavior as the old `new_articles_test.json` 404 case).

## Re-check the live list

```bash
python3 validate_and_merge_articles.py --check-live
python3 validate_and_merge_articles.py --check-live --prune-broken   # drop dead links
python3 validate_and_merge_articles.py --check-live --prune-broken --dry-run
```

## Files

| File | Role |
|------|------|
| `articles2.json` | Live list served by `index.html` |
| `candidates.json` | Staging queue + last validation report |
| `articlesavbak.json` | Backup before merge/prune |
| `validate_and_merge_articles.py` | HTTP + content gate, dedupe, merge |
| `new_articles_test.json` | Historical failed-validation example |
| `update_articles.sh` | Optional OpenClaw search/verify cron (does **not** write the live list) |

## Automation (OpenClaw / cron)

Any agent that finds articles must:

1. Append them only to `candidates.json`
2. Run `validate_and_merge_articles.py`
3. Commit/`push` **only if** the script exits 0 and `articles2.json` changed

Do not invent URLs or skip the gate.
