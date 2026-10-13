---
date: 2026-10-09
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - NPC body shapes lost on players screens

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** On players' screens the giant Dante looked narrow and other NPCs lost the golden ratio body.
- **Cause:** Roblox rescales an NPC with a height scale on each player's game and drops the server's widths and proportions.
- **Fix:** MuscleClient re-applies the widths and proportions when they differ (later replaced by the 13 Oct fix).
- **Commit:** 01efcd2

![[GYM ARC/Screenshots/giant_vs_maxed_player.jpg]]
