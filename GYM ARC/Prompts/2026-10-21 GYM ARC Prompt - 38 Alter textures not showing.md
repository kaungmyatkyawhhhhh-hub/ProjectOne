---
date: 2026-10-21
tags: [gymarc, prompt, bug]
status: done
---
# 38 Alter textures don't show (only the skin color changes)

Back to [[00 GYM ARC Home|GYM ARC Home]] - done: [[2026-10-21 GYM ARC Alter textures fix]], [[GYM ARC - Bug - Alter textures only change color]]

```text
Bug: body alters only change the skin COLOR. The alter textures (striations, veins, gloss) don't show in game.
Check and report:
1. Which SurfaceAppearance (ColorMap / NormalMap / RoughnessMap IDs) is actually on the body parts after wearing Shredded and Vascular. Print the IDs.
2. Are the 5 Tier 1 alter textures uploaded and are those IDs in the alter config? (files: Downloads\gym_arc_alters\tier1_human\)
3. Does the body rebuild (EditableMesh / stage swap / growth update) overwrite the alter SurfaceAppearance with the normal stage textures?
4. Is the UV tiling OK (detail not stretched huge or shrunk tiny)?
Fix it so the worn alter's maps stay on all body parts after every body update. Then take 1 close screenshot of the same character in Natural, Shredded, Tanned and Vascular side by side.
```
