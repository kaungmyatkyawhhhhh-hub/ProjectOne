---
date: 2026-10-04
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Finished tutorial would restart on old saves

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Players who had already finished the tutorial would have been dropped back onto its last step.
- **Cause:** When a save loaded, the tidy-up step stamped it with the new tutorial version before the game checked which version it really was.
- **Fix:** The saved version is read first. Later, "finished" became a fixed value (100) so adding tutorial steps never sends finished players back.
- **Commit:** de4f30e
