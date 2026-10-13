---
date: 2026-10-08
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Crunch leg curl and calf raise animations

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Crunch: the plate floated inside the body. Leg curl: the body and roller were wrong. Calf raise: the lifter stood inside the step with hands behind the head.
- **Cause:** The poses did not match the real equipment.
- **Fix:** Plate lies on the chest under crossed arms, legs hook the rollers; leg curl hips flat with the roller on the ankles; calf raise stands on the step under the pads.
- **Commit:** 424bc4f

![[GYM ARC/Screenshots/anim_crunch_fixed_top.png]]
![[GYM ARC/Screenshots/anim_legcurl_fixed.png]]
![[GYM ARC/Screenshots/anim_calfraise_fixed.png]]
