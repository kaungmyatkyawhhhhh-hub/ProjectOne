---
date: 2026-10-07
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Mirror took your muscles away

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Walking up to the progress mirror made your own muscles vanish.
- **Cause:** The mirror's "Now" body built a new muscle rig, which used up the player's limited muscle meshes (only 8 allowed), so your character lost its own.
- **Fix:** The Now body shows copies of your live muscle meshes instead of building new ones.
- **Commit:** 14dd2d0
