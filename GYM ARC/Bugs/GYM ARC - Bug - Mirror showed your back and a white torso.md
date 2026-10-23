---
date: 2026-10-08
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Mirror showed your back and a white torso

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** The mirror reflection showed your back instead of your front, and the torso was a white see-through box.
- **Cause:** Wrong flip math (it kept your facing), and the mirror's viewport used the tint layer's see-through values.
- **Fix:** Reflection faces you, flipped left/right like a real mirror; a mirror mode makes the meshes solid while it shows; sharper copy.
- **Commit:** 9cf1167

![[GYM ARC/Screenshots/mirror_reflection_before.png]]
![[GYM ARC/Screenshots/mirror_front.png]]
