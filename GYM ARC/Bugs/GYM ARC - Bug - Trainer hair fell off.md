---
date: 2026-10-13
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Trainer hair fell off

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** The trainers' hair lay on the floor next to them while they followed.
- **Cause:** The trainer models are copied on each player's screen and the hair had no weld holding it to the head.
- **Fix:** The trainer models now weld every accessory to its attachment on the head before they are copied. Found while testing task 7, before release.
- **Commit:** 63d7cd0
