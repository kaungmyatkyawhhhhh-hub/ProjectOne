---
date: 2026-10-13
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Smoothie boost charged when already full

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** A 4th Protein Shake took 60 coins but only added 2 seconds (the boost was already at its 15-minute cap).
- **Cause:** Buying again only capped the time; it never checked whether the drink still fit.
- **Fix:** A drink can be bought again only when its whole time fits under the cap; otherwise the button says FULL and nothing is charged. Found while testing the smoothie bar (task 5), before release.
- **Commit:** 0815b75
