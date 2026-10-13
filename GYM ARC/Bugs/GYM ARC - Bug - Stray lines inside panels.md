---
date: 2026-10-04
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Stray lines inside panels

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Thin stray lines showed inside some panels.
- **Cause:** The soft drop-shadow pieces under a panel were squeezed by the panel's inner padding.
- **Fix:** The shadow pieces now step around the padding.
- **Commit:** 43c29d0
