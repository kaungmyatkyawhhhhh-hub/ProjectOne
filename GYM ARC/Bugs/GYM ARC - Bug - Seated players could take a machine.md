---
date: 2026-10-07
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Seated players could take a machine

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** A player sitting on a seat could still grab a machine, and a seasonal machine did not release its lifter when the season ended.
- **Cause:** The server did not check those cases.
- **Fix:** Seated players can't take a machine; seasonal machines release their lifter. Posing and skating also release each other.
- **Commit:** ba327e0
