---
date: 2026-10-13
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Paused smoothie boosts wiped before the restore

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** In the leave/rejoin test the paused boosts never came back.
- **Cause:** The every-5-seconds save ran while the player was away and saved "nothing left" over the paused times.
- **Fix:** The save waits until a player's boosts have been restored. Found while testing the smoothie bar (task 5), before release.
- **Commit:** 0815b75
