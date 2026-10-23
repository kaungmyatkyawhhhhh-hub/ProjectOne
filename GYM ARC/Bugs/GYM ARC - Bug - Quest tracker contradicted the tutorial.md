---
date: 2026-10-05
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Quest tracker contradicted the tutorial

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** From the first second, the quest tracker said "Talk to Coach Dex" while the coach line said "Walk to the Flat Bench". Legend arrival notes also popped up on the menu and in the tutorial.
- **Cause:** The tracker and legend notes did not wait for the tutorial.
- **Fix:** New players see the tracker only from the tutorial's Coach step; no legend notes on the menu or in the tutorial.
- **Commit:** fb99f0b
