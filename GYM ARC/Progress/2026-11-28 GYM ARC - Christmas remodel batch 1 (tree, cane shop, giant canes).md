---
tags: [gym-arc, christmas-update, progress, 3d-model]
date: 2026-11-28
---
# Christmas remodel batch 1: tree, cane shop, giant canes

Owner: the Christmas and Gem Cave objects "look like trash"; remodel every one with the roblox-3d-model-from-sheet skill (ChatGPT turnaround + exploded sheets, traced in Blender, low-tri mesh). Autopilot. Order: Christmas props first (ships 5 Dec), Gem Cave next, the shared gym machines last. Full inventory: side-session notes `remodel-inventory.md`.

| model | Open Cloud asset | tris | parts before -> after | gate |
|---|---|---|---|---|
| LandmarkTree | 73495178738460 | 8,130 | 171 -> 31 (20 = presents, next batch) | IoU 0.911 |
| Cane shop booth | 70952306560105 | 3,496 | ~117 -> 9 | front 0.967, side 0.918 |
| GiantCane x2 (LiftRig) | 135667754162134 | 1,880 each | 36 -> 6 | IoU 0.902 |

- Kept every name and pivot scripts use: LandmarkTree pivot (LaunchCutscenes), shop PromptSpot + Header, LiftRig.GiantCane names. The LiftRig Present/Box/Cable names (MegaLift scripts) are untouched.
- Backups of every old model: `ServerStorage.RemodelBackup`. Mesh sources: `ServerStorage.RemodelMeshes`.
- Studio screenshots (Edit) look clean: tree reads as the sheet, shop matches the sheet, canes spiral with gold bands and hooks toward the rig.
- Notes per model: `GYM ARC/Art/XmasTree`, `Art/CaneShop`, `Art/GiantCane`.

## Not checked yet
- A Play run for console errors and phone FPS: the Christmas build session was editing scripts, so I did not start Play. To do after the next batch.

## Next
Present box mesh (~15 copies; keep Present/Box/Lid names for MegaLift and FreeGift), TitanPedestal, LiftRig frame, wreaths, garland, peppermints, light strings, arch, fence, lamps; then the Gem Cave.
