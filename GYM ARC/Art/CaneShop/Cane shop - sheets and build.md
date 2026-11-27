---
tags: [gym-arc, christmas-update, art, 3d-model]
date: 2026-11-28
---
# Christmas cane shop booth (roblox-3d-model-from-sheet)

Replaces the Part-built `Xmas.Yard` cane shop booth (~117 parts incl. 2 GiantCanes and a Finish folder).

## Sheets (ChatGPT)
- `turnaround_sheet.png`: FRONT / SIDE / TOP of a chunky stylised booth: red-white striped awning with scallops, wood counter with red front and gold trim, back shelf with 3 santa hats, candy-cane corner posts, bulb string, sign board.
- `exploded_sheet.png`: every part apart and labelled (awning, scallops, roof, counter, shelf, hats, posts, sign, bulbs).
- Captured with the overlay + `zoom save_to_disk` route (see the Xmas tree note).

## Build
`build_shop.py` (headless Blender, default scene). S = 0.0215 studs/px, front = -Y. Boxes for floor, walls (side window), shelf + brackets, counter (red front, wood body, gold trim and feet), helical cane posts, 9-stripe awning with scallops and side valances, roof, fascia, bulbs, sign.
- One MeshPart per colour: 3,496 tris total.
- Gates (`../gate_views.py`): FRONT IoU 0.967, SIDE IoU 0.918. Pass.

## Roblox
- `CaneShop.glb` -> Open Cloud Model **70952306560105** (group 33151111). Source in `ServerStorage.RemodelMeshes`.
- Colours: Red d3202a, White f4f1ea, Gold f0be3c (Reflectance 0.15), Wood 70401c, WoodDark 4a2810, Bulbs ffe7a0 Neon, Sign fbf4e4. Red/White/Wood collide.
- Kept `PromptSpot` (pivot-local 0,2.4,-4.8) and `Header` (invisible part with the TextLabel + PointLight) so the shop prompt and sign text still work. Nothing else in scripts names the booth.
- Parts ~117 -> 9.
- Trap: I first added a 180 deg flip for glTF; it came in facing the right way already, so the flip had to be undone. No extra flip needed.
