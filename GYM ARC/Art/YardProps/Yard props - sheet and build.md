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
| Fence section (2 posts, caps, snow points, 2 rails, sagging wire, 3 C9 bulbs) | 504 | Wood, WoodDark, Snow, Wire, Red, Yellow, Green | **0.914** |
| Street lamp (stepped base, pole, 6-sided lantern with glass + frame, roof, finial, bow + pine sprig) | 416 | Iron, Glass (Neon), Red, Pine | 0.867 |
| Light string (sagging wire, 7 C9 bulbs hanging square to the wire) | 852 | Wire, Red, Yellow, Green, Blue | 0.810 |

- Refinement pass done (28 Nov): fence passes. Lamp and light string stay under 0.90: the sheet draws a dark outline stroke round every shape, which costs thin objects most; the diff maps are within 2-3 px everywhere. Bulbs hang tilted 0.35 x the wire slope (the sheet's angle). Gate note: snow is white like the label boxes, so the fence gate keeps white pixels (`keepwhite`).

## Swap notes (after "go")
- Lamps: NightLamps finds the lamps by name; keep the model names and put the PointLight / anything NightLamps toggles onto the Glass MeshPart. Grep NightLamps before swapping.
- Fence: StrongmanYard etc. reference `Fence`; keep the folder names. One mesh per post pair; fit each to the old post spacing.
- Light strings: one mesh per span between hooks; the bulb count per span follows the old run length.

## Low-poly pass + swap (28 Nov)
Bulbs 5-sided (3 rings), wires 6-8 segments. Fence 250 tris -> **136174487561012** (79 sections, span ~5.5, round the expanded yard). Lamp 416 tris -> **138440086597146** (12 lamps). Light string now 4 bulbs per span, 220 tris -> **76886121186183** (90 spans of ~8 studs along the 8 old ceiling chains; Glow lights kept).
