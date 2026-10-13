---
date: 2026-10-13
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Trainer stood inside the next bench

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** On the flat bench a trainer stood pressed against the incline bench next to it.
- **Cause:** He took the machine's last cheer spot without checking for room.
- **Fix:** Every spot is checked for room first (nothing solid where he would stand); he tries the other cheer spots, then points around you. Found while testing task 7, before release.
- **Commit:** 63d7cd0
