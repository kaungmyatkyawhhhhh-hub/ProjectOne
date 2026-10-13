---
date: 2026-10-08
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Stage mesh downloads sometimes failed

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** In some play sessions one of the other-player body meshes failed to download, leaving a hole.
- **Cause:** A Roblox mesh download hiccup (a different mesh each time); the engine remembers the failure for the session.
- **Fix:** Meshes preload behind the loading screen, the nearest loaded stage shows instead, and the failed one is fetched again (4 tries).
- **Commit:** 7bd6c6c
