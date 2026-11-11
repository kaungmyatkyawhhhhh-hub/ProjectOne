---
date: 2026-11-11
tags: [stomp-evolution, titan, 3d, blender, stone-set, model, first-pass]
status: FIRST PASS, NOT approved, NOT high quality yet. Loaded in the owner's Blender for a look. No rig, no Roblox export.
---
# Stomp Evolution: STONE set, model v1 (first pass in Blender), 11 Nov 2026, 15:30 to 16:10

Owner (15:27): "ok sure good and lets blender them". One model at a time; the Stone set first because its sheet is the approved reference.
Sheet: `Art\Concepts\stomp_sheet_stage3_stone_v9_head_fixed.png`. Design rules: [[2026-11-11 Reference study - Titan Simulator evolutions (30 armours) + line-up v4]]. Size rule: design doc v1.6.
Files in `TITAN ARC\Art\Stone\`: `stone_v1.py` (the model, rebuild from it), `stone_v9_tex.png` (the sheet with its background filled in = the texture), `stone_v9_emit.png` (the glow), `analyse.py`, `render.py`, `compare.py`, `stone_v1_compare_sheet_vs_model.png`, `stone_v1_three_quarter.png`.

## How v1 is made
- 37 parts (2,148 faces) built by code from pixels measured on the sheet (head, collar, chest, belt, hips, thighs, knee plates, shin bands, boots, arms, bracers, fists, chest plate, core, buckle, skirt plates, back slab, boulder shoulder, slab shoulder, 4 crystals, 2 floating shards).
- **The sheet is the texture.** Each face takes its picture from the sheet's FRONT, SIDE or BACK view, chosen by the way the face points. One 1536x1024 image, one material; the glow is a second image made from the lime pixels.
- Built and rendered in Claude's workspace first (Blender as a Python module, about 25 s per check), then loaded into the owner's Blender (collection `StoneSet_v1`).

## Checks (v1)
| View | Outline match with the sheet (IoU) | Gate |
|---|---|---|
| Front | 0.90 | 0.90 |
| Side | 0.89 | 0.90 |
| Back | 0.88 | 0.90 |
**Not passed yet.** From the front, side and back it reads as the approved character. From a three-quarter angle it does not hold:
1. Picture seams: where a front face meets a side face the two views do not join (a rune and the glowing knuckles show twice, straps break).
2. Top faces and the boot toes are smeared (no view of the sheet shows them from above).
3. The parts are rounded boxes: arms, legs and chest are blockier than the sculpted armour on the sheet; the two shoulders are rough hulls with the wrong outline.
4. A pink edge shows on a few faces (sheet background sampled at the rim).
5. No backface check, no rig, no part split for Roblox, not looked at in Studio or at phone size.

## Next (v2)
1. Shape: bend the boxes to the sheet outline per part (shoulders and arms first), add the overlapping plate layers as real geometry.
2. Texture: bake the three projections into one texture per part with blended seams, paint the top faces from the nearest stone, widen the fill at the rim.
3. Then the gates from the 3D method: outline 0.90 or more in all three views, a three-quarter look, backface check, then the R15 part split and rig, then Studio.
4. A top view and a three-quarter view of the Stone set from ChatGPT would remove most of the guessing for the top faces.

## Lesson
Projecting the approved sheet onto simple shapes gives the right look fast from the sheet's own angles, and shows at once where real modelling is needed. It is a starting block-out, not a finished model.
