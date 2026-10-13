---
date: 2026-10-08
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Muscle z-fighting and zigzags

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** At level 0 and mid levels the abs and muscle edges flickered and showed zigzag edges.
- **Cause:** Muscle shells and the torso skin sat in the same place.
- **Fix:** The torso sits just under the shells, barely grown shells sink under it, and each muscle's edge snaps onto the skin.
- **Commit:** bab52a1

![[GYM ARC/Screenshots/zfight_level0_abs_front.png]]
