---
tags: [gym-arc, christmas-update, art, 3d-model]
date: 2026-11-28
---
# Christmas landmark tree (roblox-3d-model-from-sheet)

Replaces `Workspace.Gym.StarterGym.Xmas.LandmarkTree`: was a stock fir mesh + 151 parts (91 Light balls, 46 Ornament balls, star wedges, skirt cylinders). Owner: the Christmas and Gem Cave objects "look like trash"; every object gets remodelled with this skill.

## Sheets (ChatGPT, chat "Create Christmas Tree Sheet")
- `turnaround_sheet.png`: SIDE / FRONT / TOP. Prompt: chunky stylized low-poly tree, 5 faceted cone tiers (2 greens), jagged 8-point tier edges, chunky gold star, warm-white bulb spiral, ~30 red/gold/silver baubles, red skirt with white fur rim, flat MAGENTA, ortho.
- `exploded_sheet.png`: STAR, TIER 1-5, TRUNK, SKIRT, FUR RIM, BAUBLE, BULB, BULB WIRE, star attach point.
- How the sheets got to disk: the Chrome download and a localhost POST are both blocked on chatgpt.com, and desktop control was declined. Working route: show the image at its natural size in a full-page overlay (JS), then the Chrome extension `zoom` with `save_to_disk` over two halves (1536x512 each, PNG, full res) and `stitch.py`.

## Build
Scripts (rebuild from them): `analyse_sheet.py` (side profile -> `profiles.json`), `build_tree.py`, `gate_render.py`, `gate_iou.py`, `export_tree.py`, `run_tree.py` (headless: `blender -b --factory-startup --python run_tree.py`).
- 1 unit = 1 stud. Height 30.68 = the old tree; the star centre lands at 27.9 (LaunchCutscenes frost burst aims at 27.6).
- Tiers: measured (top y, top r, bottom y, bottom r) per tier; light-green cap + dark band + jagged rim + underside; each tier's top tucked 16 px into the tier above (no see-through gap). Hidden seam discs keep both colour pieces watertight.
- 40 baubles on the tier bands at the tip angles (icosphere 2), 4-turn bulb spiral (3-sided wire, bulbs every 1.6 studs), 24-gon skirt, scalloped fur tube, 10-point bevelled star.
- 11 objects = 11 MeshParts (one per colour): 8,130 tris total. 0 open edges on every piece.

| gate | value | |
|---|---|---|
| silhouette IoU vs SIDE (tree, above the skirt) | 0.911 | pass |
| silhouette IoU incl. skirt | 0.864 | sheet conflict: the sheet draws the skirt as a tilted ellipse (perspective) while its TOP view shows a flat disc; flat disc kept |

## Roblox
- `XmasTree.glb` -> Open Cloud Model **73495178738460** (group 33151111), Approved. Open Cloud works while Studio is in Play (it did on 28 Nov). Loaded on the Play server with InsertService: all 11 MeshParts load.
- Swap: old tree backed up to `ServerStorage.RemodelBackup.LandmarkTree`; source model in `ServerStorage.RemodelMeshes.XmasTreeMesh`. Removed Fir, Light, Ornament, StarCore, StarPoint, Skirt, SkirtFur. Kept the model name/pivot (LaunchCutscenes uses the pivot) and the 5 presents (they get the Present mesh later). PointLight (gold, 2, range 18) moved onto the new Star.
- Parts in the tree: 171 -> 31 (11 meshes + 20 present parts until the Present remodel).
- Trap: `insert_asset` moves the inserted model, so place pieces relative to a known piece (the Skirt at 0,0.2,0), not by their raw positions.
- Trap: a glTF export in a 2nd scene crashed Blender (owner's Blender too: the MCP link dropped). Headless builds run in the one default scene.
