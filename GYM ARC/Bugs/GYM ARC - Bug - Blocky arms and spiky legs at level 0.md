---
date: 2026-10-08
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Blocky arms and spiky legs at level 0

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** At level 0 the plain blocky Roblox arms and legs showed, and thin legs had spikes.
- **Cause:** Arm and leg muscle meshes were only built once a muscle grew; the leg shells sank under the skin and poked out the other side.
- **Fix:** Arms and legs are built from level 0, leg shells no longer sink, plain parts are hidden.
- **Commit:** 574ccec

![[GYM ARC/Screenshots/before_fix_level0_spiky_legs.png]]
![[GYM ARC/Screenshots/unified_front_level0.png]]
