---
date: 2026-10-13
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Photo mode missed the mirror wall

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** The PHOTO button didn't show at the starter gym's mirror wall.
- **Cause:** The gym has two mirror panels with the same name; the game looked at the small one on the side wall.
- **Fix:** Every mirror with that name is checked, and the spots point at the glass itself. Found while testing task 7, before release.
- **Commit:** 63d7cd0
