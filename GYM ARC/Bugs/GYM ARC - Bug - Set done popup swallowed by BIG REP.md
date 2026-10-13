---
date: 2026-10-07
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Set done popup swallowed by BIG REP

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** When the 10th rep was also a BIG REP, the "Set done" popup never showed.
- **Cause:** The BIG REP popup replaced it.
- **Fix:** Set done is no longer swallowed. Big numbers are also formatted properly now.
- **Commit:** ba327e0
