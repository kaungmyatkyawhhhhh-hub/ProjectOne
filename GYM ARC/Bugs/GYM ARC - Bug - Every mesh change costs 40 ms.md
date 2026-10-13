---
date: 2026-10-08
tags: [gymarc, bug]
status: wont-fix (engine limit)
---
# GYM ARC - Bug - Every mesh change costs 40 ms

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Changing a muscle mesh in any way costs the engine about 40-60 ms of a frame.
- **Cause:** Roblox EditableMesh cost, whatever the size of the change.
- **Fix:** Engine limit. Workaround: muscle meshes change rarely (small steps, one region per frame, tints by transparency).
- **Commit:** unknown
