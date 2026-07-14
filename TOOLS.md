# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

### Bay Area Hikes

- Website: bayhikes.md (relative to workspace root)
- Last updated: July 12, 2026 - Updated with latest upcoming hikes from Meetup.com's San Francisco hiking page
- Source: Meetup.com San Francisco hiking groups
- Content: Upcoming hike events with dates, distances, difficulty, and organizer info

### NY Stroll Stuff

- Website: nystrollstuff/index.html (relative to workspace root)
- Repository: github.com/upsideprompts/upsideprompts.github.io (gh-pages branch)
- Content: Baseball schedule (Yankees, Mets, Cyclones, FerryHawks) + NYC hiking events
- Last updated: July 14, 2026 - Updated with Tuesday July 14 baseball and hiking events
- Automation: Daily cron job (ee46fe6c) runs at 9:30 AM UTC
- Channel access: Successfully sent update to initflux channel (C0AS1FCPQHG) - channel access working

### E-Bike Hub

- Website: ebikehub/index.html (relative to workspace root)
- Repository: github.com/upsideprompts/upsideprompts.github.io (gh-pages branch)
- Content: Top 10 Electric Bikes 2025-2026 with filtering by range and speed
- Last updated: June 21, 2026 - Moved newsletter text to top of popup card
- Features: Range/speed filters, bike cards with specs, review video links, popup with FREE badge, email signup, and "No, thanks" link

### AV Innovate

- Website: innovateav/index.html (relative to workspace root)
- Articles JSON: innovateav/articles2.json
- Last updated: July 14, 2026 - Added 3 new verified articles (71 unique)
- Automation: Daily cron jobs (8:30am PT lookup, 8:50am PT add) for AV/train/aircraft news
- Current total: 71 unique verified articles
- Verification rule: All articles must be confirmed to exist via 3 different loading methods before adding

### AMD LLM Processor YouTube Summaries
- Task: Find top 3 YouTube videos about AMD processors for LLM models
- Format: 3-sentence summary per video
- Last run: July 3, 2026 - 3:30 PM UTC
- Status: Completed via cron task (4b8aa269-7f47-4c2e-bdee-ded21fca878b)

### AI Hardware Stock Dashboard (hwdeck)
- Website: hwdeck/index.html
- Last updated: July 6, 2026 - Added Current Price column
- Columns: Ticker, Company, Current Price, Monthly Return, 3-Month Change
- Issues resolved:
  - Monthly Return column now sorts correctly (descending/ascending)
  - 3-Month Change column now sorts correctly
  - Button active state now highlights properly
  - Removed broken `event.target` reference, now uses passed button element
  - Added toggle functionality: click Monthly Return header to switch between ▼ (descending) and ▲ (ascending) visual indicators
  - Added Current Price column with all stock prices populated

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.