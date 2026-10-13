---
date: 2026-10-09
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Still saving from another server kick

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** The owner was kicked on join with "Your data is still saving from another server".
- **Cause:** A dead server's save lock blocked rejoining for 5 minutes.
- **Fix:** Dead locks expire after 180 s, the loader waits ~60 s before kicking, Studio test locks never block live servers, FreshPlayer tests never touch the real save.
- **Commit:** f6d7fa3
