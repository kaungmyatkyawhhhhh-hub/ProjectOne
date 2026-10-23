---
date: 2026-10-05
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Roblox spawn pad in the menu shot

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** The default gray spawn pad with the black Roblox logo showed on the entrance floor behind the menu.
- **Cause:** Studio's default spawn location was left visible.
- **Fix:** Made invisible, non-colliding and flush with the floor (still the spawn). Studio-only change, needed a place save.
- **Commit:** fb99f0b
