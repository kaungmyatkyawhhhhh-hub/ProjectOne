---
date: 2026-10-07
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Saves could be cut off at shutdown

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** When a server closed, a save that was still running could be cut off. Test sessions could also write to the real leaderboards and crews.
- **Cause:** Shutdown did not wait for saves already in progress, and test sessions were not kept away from the shared boards.
- **Fix:** Shutdown waits for in-flight saves; test sessions never write leaderboards or crews.
- **Commit:** ba327e0
