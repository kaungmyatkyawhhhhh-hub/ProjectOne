---
date: 2026-10-07
tags: [gymarc, bug]
status: wont-fix (engine limit)
---
# GYM ARC - Bug - Only 8 live muscle meshes per player

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Only your own character has live, growing muscle meshes; other players, NPCs and the statue use fixed body stage meshes. The torso also has to be split in two.
- **Cause:** A Roblox player's game can hold at most 8 EditableMeshes and your body uses 7. A mesh shows nothing once its EditableMesh is gone, so they can't be baked. Each mesh is limited to 20,000 triangles (the torso has 39,600).
- **Fix:** Engine limit. Workaround: static body stage meshes for everyone else (8 Oct); torso split into front and back.
- **Commit:** unknown

![[GYM ARC/Screenshots/task1a_merged_torso_7meshes.png]]
