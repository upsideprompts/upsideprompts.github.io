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

### NY Stroll Stuff

- Website: nystrollstuff/index.html (relative to workspace root)
- Repository: github.com/upsideprompts/upsideprompts.github.io (gh-pages branch)
- Content: Baseball schedule (Yankees, Mets, Cyclones, FerryHawks) + NYC hiking events
- Last updated: June 20, 2026 - Updated with June 20 baseball and hiking events
- Note: Scrape Meetup.com for hiking events and update baseball schedule daily

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.