---
date: 2026-10-05
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Stats labels hidden behind walls

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Stats labels could be hidden by walls and racks, or faded out when a prompt showed nearby.
- **Cause:** The labels were drawn in the world, so things in front of them covered them.
- **Fix:** Labels are always drawn on top and are nudged off a shown prompt instead of fading.
- **Commit:** 9e5aeae

![[GYM ARC/Screenshots/fix3_stats-behind-wall_after.png]]
