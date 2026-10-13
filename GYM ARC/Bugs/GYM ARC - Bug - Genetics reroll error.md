---
date: 2026-10-07
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Genetics reroll error

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Rerolling genetics gave an error during the reveal.
- **Cause:** Labels kept updating for plates that were already sliding off the bar.
- **Fix:** Labels of sliding-off plates stop updating.
- **Commit:** 54ee1e2

![[GYM ARC/Screenshots/genetics_reroll.png]]
