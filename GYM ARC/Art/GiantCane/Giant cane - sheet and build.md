---
tags: [gym-arc, christmas-update, art, 3d-model]
date: 2026-11-28
---
# Giant candy cane (roblox-3d-model-from-sheet)

Replaces the 2 Part-built GiantCane models on `Xmas.Yard.LiftRig` (18 parts each; the shop's 2 went with the shop remodel).

## Sheet
`turnaround_sheet.png`: side, front and exploded view in one (shaft, hook, gold band, red end cap).

## Build
`build_cane.py`: S = 8/887 studs/px, tube radius 57.5 px, 16 sides, rings twisted along the path (pitch 150 px) so the stripes spiral instead of stair-stepping; hook centre (298,198) R 105.5; gold band and bevelled red end cap. Origin = shaft bottom centre, 8 studs tall.
- 1,880 tris (Red 956, White 864, Gold 60). Silhouette IoU 0.902. Pass.
- Trap: the ortho camera scale follows the longer image side; set ortho_scale = 1024*S for a 768x1024 render.

## Roblox
- `GiantCane.glb` -> Open Cloud Model **135667754162134**. Source `ServerStorage.RemodelMeshes.GiantCaneMesh` (PackageLink removed).
- In Roblox the hook came in pointing -X. Scaled x1.28 to the old 10.26 studs, bottoms on the old ground line, hooks toward the rig centre (x -22). Model name `GiantCane` kept. Backups `ServerStorage.RemodelBackup.LiftRigCane1/2`.
- Parts 36 -> 6 (3 per cane). Red/White collide, Gold no.

## Low-poly v2 (28 Nov, owner: "do low poly style", then "the reference saves more triangles")
`build_cane_lowpoly.py`: 8 sides, one ring per stripe on the straight shaft (long flat quads), 30° tilted bands, extra rings only round the hook, rounded faceted hook tip, gold band + red end cap. **312 tris** (was 1,880). `GiantCane_lp2.glb` -> Model **73612155677866**, template `RemodelMeshes.GiantCaneLP2`. Swapped on both lift canes (scale 1.28, anchored on the gold band). v1 rope style kept in `build_cane.py`.
