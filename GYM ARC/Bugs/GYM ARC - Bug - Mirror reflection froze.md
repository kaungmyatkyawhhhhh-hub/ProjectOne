---
date: 2026-10-07
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Mirror reflection froze

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** The live mirror reflection could stay frozen while you moved or posed.
- **Cause:** Copy parts were paired with your real parts by list order (which can differ), and the copy still had its own Humanoid and joints (an earlier fix had never applied).
- **Fix:** Parts paired by name path and the copy has no Humanoid. Tested by tracking limb heights during an emote.
- **Commit:** 75ca3dc
