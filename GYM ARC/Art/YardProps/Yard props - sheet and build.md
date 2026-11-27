---
tags: [gym-arc, christmas-update, art, 3d-model]
date: 2026-11-28
---
# Christmas yard props: fence, street lamp, light string (roblox-3d-model-from-sheet)

Replaces Fence posts + rails + bulbs (50 posts, 155 parts), Lamp posts (4, 8 parts, used by NightLamps), Ceiling light strings (6 runs, 288 bulbs, 593 parts). PREP ONLY: not uploaded or swapped yet (Studio on hold).

## Sheet (ChatGPT chat "Create Christmas Props Sheet")
`sheet.png`: one row per prop, FRONT, SIDE, EXPLODED (fence: post, cap, rail, snow, bulbs, wire; lamp: base, pole, lantern, glass, bow; string: wire, socket, bulb). A yard screenshot was attached.

## Build
`build_yardprops.py` (headless) writes `Fence.glb`, `Lamp.glb`, `LightString.glb`.
| model | tris | MeshParts | FRONT IoU |
|---|---|---|---|
| Fence section (2 posts, caps, snow points, 2 rails, sagging wire, 3 C9 bulbs) | 528 | Wood, WoodDark, Snow, Wire, Red, Yellow, Green | 0.882 |
| Street lamp (stepped base, pole, 6-sided lantern with glass + frame, roof, finial, bow + pine sprig) | 416 | Iron, Glass (Neon), Red, Pine | 0.826 (side 0.805) |
| Light string (sagging wire, 7 C9 bulbs hanging square to the wire) | 908 | Wire, Red, Yellow, Green, Blue | 0.626 |

- All under the 0.90 gate: the fence and lamp only on detail (the sheet's fluted base and bigger bow); the light string because thin wire + small bulbs mis-register by a few px. Refine before the swap.

## Swap notes (after "go")
- Lamps: NightLamps finds the lamps by name; keep the model names and put the PointLight / anything NightLamps toggles onto the Glass MeshPart. Grep NightLamps before swapping.
- Fence: StrongmanYard etc. reference `Fence`; keep the folder names. One mesh per post pair; fit each to the old post spacing.
- Light strings: one mesh per span between hooks; the bulb count per span follows the old run length.
