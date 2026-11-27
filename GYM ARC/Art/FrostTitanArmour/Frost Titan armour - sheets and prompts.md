---
tags: [gym-arc, christmas-update, art, 3d-model]
date: 2026-11-27
---
# Frost Titan ice armour: design sheets (roblox-3d-model-from-sheet, step 1 + 1a)

Owner, 27 Nov: "those spikes are so ugly too, i told u to use the /roblox-3d-model-from-sheet for every build & details". The code-built crystals, back spikes, arm shards and crown (32 parts) are removed from the statue; this armour set replaces them, modelled in Blender from these sheets.

Body first (same day, owner: "it must look like a mass monster ... widths and depths"): the statue now has the gym giants' exact mass-monster shape (Coach Dex: shoulders 1.918, hips 1.568, arms/legs 1.438, depth 1.394, times 0.8 for its uniform 2.1 scale; torso w/h 1.56, thigh w/h 0.45 = his), MuscleG at the full MonsterG for every muscle.

## Files
- `statue_ref.png`: the statue as it is now (Play screenshot), attached to the first prompt.
- `turnaround_sheet.png`: side / top / front, armour worn (ChatGPT option 2 of 2, chosen for the required layout). Captured from the page at 0.79 scale (1215x810), not downloaded.
- `exploded_sheet.png`: every piece apart and labelled, attach points marked.

## Pieces (Blender objects / MeshPart names)
PauldronPlate1, PauldronPlate2, PauldronPlate3 (x2, mirrored; attach: shoulder top), IceCrown (5 thick points; attach: head top), Bracer (x2; attach: forearm centre).

## Prompts (ChatGPT, chat "Generate armour design sheet")
1. Turnaround: "Full turnaround design sheet of an ICE ARMOUR SET for the giant muscular 'Frost Titan' ice statue in the attached Roblox screenshot ... two big layered glacier-ice SHOULDER PAULDRONS (3 overlapping curved plates each, thick chunky faceted ice, frosty white edges, a faint cyan glow line along each plate edge), a low jagged ICE CROWN circlet (5 short thick points, not thin spikes), and two forearm ICE BRACERS ... 3-4 colours only: pale ice blue, deep glacier blue, frost white, cyan glow. NO thin needle spikes, NO clusters of shards. 1536x1024, orthographic, flat MAGENTA #FF00FF: TOP ROW SIDE, BOTTOM LEFT TOP, BOTTOM RIGHT FRONT."
2. Exploded: "Technical EXPLODED-VIEW diagram of ONLY the ice armour pieces ... LEFT PAULDRON with its 3 plates pulled apart vertically ... RIGHT PAULDRON (assembled), ICE CROWN (front and top), LEFT/RIGHT BRACER (front and side) ... dashed alignment lines ... ATTACH dots ... flat MAGENTA."

## Owner rule (27 Nov)
"not just armor, i mean for LITERALLY ANYTHING ... if the model is built in blender greatly with low triangles, it lags less than builds with parts and look better". Written into the skill (vault copy, re-upload needed) and memory.

## Build (Blender 5.2, scene "GYM ARC Armour")
Scripts here, rebuild from them: `analyse_sheet.py` (sheet -> `profiles.json`, masks: all non-magenta outside the label boxes, leader lines and attach dots kept then opened away), `build_armour.py`, `gate_render.py`, `gate_iou.py`, `export_armour.py`.
- Plates: curved roof-tile shells from each plate's front outline (droop = height - thickness), nested like stacked bowls, glow rim strip under each.
- Crown: the front outline wrapped on a ring (x = R sin a), faceted ridge, glow strip.
- Bracers: lofted from the front width and the side width + lean per row, 2 glow bands where the sheet is most cyan.
- 18 objects, 7,560 tris for the whole set (both sides). Every mesh watertight: 0 open edges, 0 non-manifold, positive volume.

| view | IoU | |
|---|---|---|
| plate1 | 0.952 | pass |
| plate2 | 0.964 | pass |
| plate3 | 0.947 | pass |
| crown front | 0.910 | pass |
| crown top | 0.337 | sheet conflict (step 1b): the top view is drawn ~0.7x the front, a ring thick enough for it fails the front; front wins |
| bracer front | 0.959 | pass |
| bracer side | 0.928 | pass |

Export: `FrostTitanArmour.fbx`, 10 objects (PauldronL/R, BracerL/R, IceCrown + a Glow piece each, for Neon).

## Blocked (27 Nov)
- Studio's `AssetService:CreateAssetAsync` is "not available yet".
- The Open Cloud upload (open_cloud_invoke, group 33151111) needs this folder approved in Studio: Assistant Settings -> MCP Permissions -> approved upload directories.

Then: insert the model, size each piece on the statue (UpperArm / Head / LowerArm), materials Ice + Neon glow, weld, Play screenshots, retake the shop cards.
