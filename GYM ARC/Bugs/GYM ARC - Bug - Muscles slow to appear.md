---
date: 2026-10-07
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Muscles slow to appear

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** After spawning it took 4-5 seconds before your muscles showed.
- **Cause:** Each muscle mesh takes 0.3-1 s to create and they were made one after another.
- **Fix:** Up to 3 are built at once on a time budget; NPCs wait until yours are done. Now ~1-1.5 s.
- **Commit:** 14dd2d0
