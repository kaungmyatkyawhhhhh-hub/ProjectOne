---
date: 2026-10-09
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Upper traps never grew

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Training Traps never raised the slope from the neck to the shoulders.
- **Cause:** The package's Traps only pushed the upper back out; the top of the torso was a flat cap.
- **Fix:** The generator gives the cap a ring and adds upper traps that rise from the neck to the shoulders (each torso half stays under 20,000 triangles).
- **Commit:** 3de329b

![[GYM ARC/Screenshots/upper_traps_back.jpg]]
![[GYM ARC/Screenshots/upper_traps_front.jpg]]
