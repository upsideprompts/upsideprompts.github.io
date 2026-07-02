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

### NY Stroll Stuff

- Website: nystrollstuff/index.html (relative to workspace root)
- Repository: github.com/upsideprompts/upsideprompts.github.io (gh-pages branch)
- Content: Baseball schedule (Yankees, Mets, Cyclones, FerryHawks) + NYC hiking events
- Last updated: July 2, 2026 - Updated with July 2 baseball and hiking events
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
- Last updated: July 1, 2026 - Added 3 new verified articles (41 total)
- Automation: Daily cron jobs (8:30am PT lookup, 8:50am PT add) for AV/train/aircraft news
- Current total: 41 verified articles
- Verification rule: All articles must be confirmed to exist via 3 different loading methods before adding

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.