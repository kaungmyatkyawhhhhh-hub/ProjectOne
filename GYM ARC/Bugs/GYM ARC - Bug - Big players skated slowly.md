---
date: 2026-10-14
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Big players skated slowly

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Big / tall players were slow on the skateboard. A 7'0" mass monster topped out at 13.8 studs/s when the board should go 32.
- **Cause:** The board is pushed by a force with a fixed limit (60000). While skating the character stands still in Roblox's eyes, and Roblox holds a bigger character to the ground harder, so the fixed push lost.
- **Fix:** The push has no limit any more (walls still stop the board). Taller riders also go a bit faster, push and turn faster, and get a bigger board, so it feels the same at every size. See [[GYM ARC - Skateboard and Skate Park]].
- **Commit:** cd0a94e
- **Status:** fixed
