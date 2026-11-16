---
tags: [mega-bite, 3d, exploded-diagram, mosasaurus]
created: 2026-11-16
---
# Mosasaurus Tier 6 - exploded sheet v1 (ChatGPT)

Method: [[Brain/Skills/roblox-3d-model-from-sheet/SKILL|3D model from sheet]] step 1a. Ref: the owner's "Mosasaurus - Tier 6" card (green low-poly, cyan crystal dorsal spikes, yellow eye), attached to the prompt.
Chat: https://chatgpt.com/c/6afa9256-2cc0-83ec-9825-d714f6e1b01a

Saved via overlay + 2 zoom captures stitched (1536x1024), so it is slightly resampled.

Parts (label = Blender object / MeshPart name): UPPER SKULL, LOWER JAW, UPPER TEETH ROW, LOWER TEETH ROW, MOUTH INTERIOR, EYE, NECK, TORSO, TAIL BASE, TAIL TIP, FRONT/BACK FLIPPER LEFT/RIGHT, 15 DORSAL CRYSTAL SPIKES (largest at mid-back).

Known gaps vs the card: body is straight (card is curved, pose it with the rig); no tail fluke drawn; flippers are shown side-on only, so take their plan shape from a turnaround sheet.

## Prompt
Create an image: a technical EXPLODED-VIEW diagram of the creature in the attached image, copied exactly from the attached image (same Roblox low-poly faceted style, flat shading, same colours: dark mossy green scales with darker green facets, lighter yellow-green belly, glowing cyan ice-crystal dorsal spikes, glowing yellow eye, dark red mouth interior, cream-white teeth). Orthographic SIDE view, nose pointing RIGHT, body straightened out horizontally (not curved). Every part pulled apart along the body's long axis with thin dashed alignment lines, each part labelled with a short name: UPPER SKULL, LOWER JAW, UPPER TEETH ROW, LOWER TEETH ROW, MOUTH INTERIOR, EYE, NECK, TORSO, TAIL BASE, TAIL TIP, FRONT FLIPPER LEFT, FRONT FLIPPER RIGHT, BACK FLIPPER LEFT, BACK FLIPPER RIGHT, DORSAL CRYSTAL SPIKES (shown as a row of separate crystals, largest at mid-back, smaller toward head and tail). Add a small ASSEMBLED side view at the bottom. Flat MAGENTA #FF00FF background, no shadows, no perspective, no glow halo bleeding onto the background, 1536x1024 landscape.

![[mosasaurus_exploded_v1.png]]

---
# Turnaround sheet v1 (same chat, 2026-11-16)
`mosasaurus_turnaround_v1.png`: side (top row), top (bottom left), front (bottom right). Replaces the old teal/orange `sheet.png` (evolution 9 look) for the Tier 6 model.

Checks:
- Top view is NOT the side view's length: side spans x 51-1478 (1427 px), top spans x 35-1043 (1008 px). Scale the top view by 1.416 before lofting. ChatGPT ignores the "same length" instruction, so fix it in analysis.
- Side view shows the 2 near flippers only; the top view shows all 4 spread out.
- Front view: the crystals stack into a tall crest and the open mouth is wider than the side suggests. Run step 1b (guide lines) before modelling the head.

## Prompt
Create a new image: a full orthographic TURNAROUND model sheet of the same creature, matching the first attached image and the exploded diagram you just made exactly (same Roblox low-poly faceted style, flat shading, same colours: dark mossy green with darker green facets and raised hexagonal scale plates on the back, yellow-green belly, 15 glowing cyan ice-crystal dorsal spikes largest at mid-back, glowing yellow slit eye, dark red mouth interior, cream-white teeth, pointed tail tip, 4 paddle flippers). Body straight, mouth slightly open as in the exploded sheet. Layout on a 1536x1024 landscape canvas: TOP ROW the full SIDE view, nose pointing RIGHT, spanning nearly the full width. BOTTOM LEFT the TOP view (looking straight down), nose pointing RIGHT, exactly the same length as the side view and directly under it, showing the flippers spread out and the crystal row down the spine. BOTTOM RIGHT the FRONT view (looking straight at the nose), showing the head, both eyes, the flippers spread, and the crystals sticking up. No labels, no text. Flat MAGENTA #FF00FF background, no shadows, no perspective, no glow halo bleeding onto the background.

![[mosasaurus_turnaround_v1.png]]

---
# Build v1 (2026-11-16)
Built in Blender 5.2 by `mosa6_build.py` from `mosa6_data.json` (measured from the turnaround by `analyse.py` + `data.py`). Rebuild from the script, never hand-edit.
- Run headless: `blender -b --factory-startup -P mosa6_build.py -- mosa6_data.json <out_dir> render <out>.blend`
- In the owner's Blender: scene **Mosasaurus T6**, collection `Mosasaurus_T6` (exec the script with `ARGS=[data, out_dir]`).
- **29 parts, 5,568 triangles**, length 6.4 m. Part names follow the exploded sheet: TailTip, TailBase, Torso, Neck, UpperSkull, LowerJaw, MouthInterior, Upper/LowerTeethRow, Eye, Front/BackFlipper Left/Right, DorsalCrystal_01-14, ScalePlates. Materials: `M6_Body` (vertex colour `Col`), `M6_Glow` (crystals and eye, emission).
- 14 crystals, not 15: both turnaround views show 14.

Checks (`compare.py`, `gates.py`, pictures in `checks/`):
- Silhouette IoU: **side 0.922** (passes 0.90), top 0.864, front 0.707.
- Top and front miss because the sheet's views disagree on the flippers: the side puts the tips further back, the top further forward, and the front draws them broad and low. The build puts the tips halfway and twists each paddle 35 deg. Owner to say which view wins.
- Gates PASS: zero open edges, every part faces outward (signed-volume fix for the thin flippers), every flipper and crystal rooted in the body.

Not done yet: rig (8 spine bones + Jaw) and Swim clip, baking colours into one texture, FBX export, Studio import, and which game it goes in.
