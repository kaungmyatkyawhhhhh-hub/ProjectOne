---
date: 2026-10-07
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Two title tags on one head

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Sometimes two title tags were stacked above a player's head after joining.
- **Cause:** Two parts of the code raced to create the tag on join.
- **Fix:** Only one tag is made; your own title is hidden on the menu.
- **Commit:** 29eb5a6
