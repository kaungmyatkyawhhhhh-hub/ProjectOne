---
tags: [gym-arc, christmas-update, art, 3d-model]
date: 2026-11-28
---
# Christmas present (roblox-3d-model-from-sheet)

One mesh for all 28 Christmas presents (Extra.Presents piles 7x3, LiftRig.Present, FreeGift, 5 under the LandmarkTree). Each was 5-10 Parts (box, 2-4 ribbons, 2 bow wedges, lid, knot).

## Sheet (ChatGPT chat "Create Present Design Sheet")
`sheet.png`: FRONT / SIDE / TOP on the top row, EXPLODED VIEW below (box, ribbon band box, lid, ribbon band lid, bow loops, bow knot, bow tails). The LiftRig screenshot was attached for style.

## Build
`build_present.py` (headless Blender). Unit = body width (330 px). Body 1 x 0.706 x 1, lid overhang 1.106 wide to 0.967 high, ribbon bands 0.2 wide standing 0.018 proud, knot, two ring bow loops (traced outline + hole, resampled to 16 points each), two V-notched tails over the lid's front edge. Bevelled box and lid.
- 3 MeshParts: Box 44, Lid 44, Ribbon 356 = **444 tris**.
- Gates: FRONT IoU 0.939, SIDE IoU 0.906. Pass. `gate/compare.png` = sheet above, renders below.

## Roblox
- `Present.glb` -> Open Cloud Model **110979000029899**. Source `ServerStorage.RemodelMeshes.PresentMesh`.
- Swap per present: scale = (old box X, red height / 0.967, old box Z) where red height = box bottom to lid top (or box top if no lid); yaw from the old box; Box colour = old box, Lid = old lid colour (else box darkened 14%), Ribbon = old ribbon colour. Old parts' children (FreeGift ProximityPrompt, lights) and attributes moved onto the new Box.
- Names kept for scripts: MegaLift uses `Present.Box` and `Present.Lid` (cable bottom = Lid.Y + 1.4, now ends inside the knot); AdventService finds the FreeGift ProximityPrompt by FindFirstChildWhichIsA (still there). LiftRig Plate untouched.
- Parts: ~190 -> 84 (28 x 3). Backups: `ServerStorage.RemodelBackup.ExtraPresents1-7`, `LiftRigPresent`, `FreeGift` (tree presents are in the `LandmarkTree` backup).
