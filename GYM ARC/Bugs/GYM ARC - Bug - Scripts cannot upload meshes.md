---
date: 2026-10-08
tags: [gymarc, bug]
status: wont-fix (engine limit)
---
# GYM ARC - Bug - Scripts cannot upload meshes

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Stage meshes for other players have to be imported by hand in Studio.
- **Cause:** Roblox's CreateAssetAsync is "not available yet", so a script can't upload meshes.
- **Fix:** Engine limit. The owner imports the OBJ files and a setup script installs them.
- **Commit:** unknown
