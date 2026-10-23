---
date: 2026-10-06
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Flickering overlapping parts on the map

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** All over the town surfaces flickered (z-fighting): the park's fountain ring was 28 overlapping slabs, paths overlapped, umbrellas looked like spokes from below.
- **Cause:** Many parts shared exactly the same face, so the renderer could not decide which to draw.
- **Fix:** Fountain ring and paths merged into one part, all 13 umbrellas rebuilt, and a whole-map scan nudged ~10,500 parts 0.04 studs apart (invisible, stops the flicker).
- **Commit:** bd6fece

![[GYM ARC/Screenshots/fix3_park-paths_before.png]]
![[GYM ARC/Screenshots/fix3_park-paths_after.png]]
![[GYM ARC/Screenshots/fix3_umbrella_before.png]]
![[GYM ARC/Screenshots/fix3_umbrella_after.png]]
