---
date: 2026-10-08
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Torso poked through at the chest midline

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** The torso skin poked through between the chest and the abs and on the torso sides.
- **Cause:** Muscles riding the waist shape updated one frame behind the torso.
- **Fix:** Torso and those muscles update in the same frame; flat muscles sink deeper; seams snap to the torso.
- **Commit:** 605e31a

![[GYM ARC/Screenshots/midline2_waistmax_chestabsmax.png]]
