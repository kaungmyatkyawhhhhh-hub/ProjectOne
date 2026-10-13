---
date: 2026-10-07
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Arm wrestling and crew race bugs

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Arm wrestling matches and the practice rookie could clash when two things happened at once; creating a crew could fail without a refund; a failed crew leave was not handled.
- **Cause:** Timing races and missing error handling on the server.
- **Fix:** Races fixed, crew creation refunds on failure, failed leaves handled.
- **Commit:** ba327e0
