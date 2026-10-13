---
date: 2026-10-07
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Camera zoomed into your arm on first lift

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** On the first lift the camera suddenly zoomed into your arm.
- **Cause:** An NPC stood behind the bench and the camera treated him as a wall.
- **Fix:** NPCs are not solid on each player's screen, so the camera ignores them.
- **Commit:** 29eb5a6
