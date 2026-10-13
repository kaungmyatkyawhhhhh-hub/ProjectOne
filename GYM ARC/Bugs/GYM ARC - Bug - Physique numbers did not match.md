---
date: 2026-10-14
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Physique numbers did not match

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** In the Physique window every muscle group showed 100%, but the grades next to them were B, A, S, C, and the big total said 12%.
- **Cause:** Three different numbers: the bars showed progress to the Growth Spurt goal (a player at max height is past every goal, so all 100%), the letters were the genetics grades, and the total was the average muscle look.
- **Fix:** One number drives everything: each group's % is how close its muscles are to the full look, the grade comes from that % (S 90+, A 75+, B 55+, C 35+, D below), and the total is the average of the six groups. The bar color follows the grade.
