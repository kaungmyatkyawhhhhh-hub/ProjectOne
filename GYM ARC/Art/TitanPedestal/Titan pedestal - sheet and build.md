---
tags: [gym-arc, christmas-update, art, 3d-model]
date: 2026-11-28
---
# Frost Titan pedestal (roblox-3d-model-from-sheet)

Replaces `Xmas.Yard.TitanPedestal` (18 parts). PREP ONLY: built and exported, NOT uploaded or swapped yet (the owner put Studio on hold until the Christmas build session finishes).

## Sheet (ChatGPT chat "Create Technical Turnaround Sheet")
`sheet.png`: FRONT, SIDE, TOP, EXPLODED (base tier, middle tier, top tier, glow ring, ice cluster, plaque). A yard screenshot was attached for style.

## Build
`build_pedestal.py` (headless). Unit = base radius (338 px). 20-sided tiers: chamfered navy base with a cyan glow band, sloped navy middle tier, frosted top disc with a chamfered edge, cyan glow ring, 4 ice clusters (tall 6-sided crystal + 2 leaning), bevelled plaque on the front slope.
- 5 MeshParts: Navy 272, Frost 156, Glow 152 (Neon), Crystal 264, Plaque 28 = **872 tris**.
- Gates: FRONT IoU 0.894, SIDE 0.884. The rest of the loss is the sheet's perspective (the tier tops are drawn as ellipses); flat tops kept, as with the tree skirt. Sheet conflict: the FRONT shows no front crystal cluster but TOP and SIDE do; 4 clusters kept.

## Swap plan (after "go")
Upload `TitanPedestal.glb`, scale to the old pedestal's footprint (radius) and height, keep the model name `TitanPedestal` and anything AdventService uses (it moves the Frost Titan statue; check the statue's stand height after the swap). Keep TitanSign.
