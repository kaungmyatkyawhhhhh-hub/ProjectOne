---
date: 2026-10-13
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Trainer desks built in the air

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Rebuilding the trainer desks put two of them 3 studs above the floor.
- **Cause:** The builder measured the floor before removing the old desk, so it measured the old desk's top.
- **Fix:** The builder removes the old desk first. Found while testing task 7, before release.
- **Commit:** 63d7cd0
