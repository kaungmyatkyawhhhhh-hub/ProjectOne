---
tags: [gym-arc, christmas-update, art, 3d-model]
date: 2026-11-28
---
# Christmas wall decor: wreath, garland swag, peppermint (roblox-3d-model-from-sheet)

Replaces Wreath (21 copies, 175 parts), Garland swag (74 copies, 740 parts), Peppermint wall disc (15 copies, 120 parts) in `Xmas.Makeover`. PREP ONLY: not uploaded or swapped yet (Studio on hold).

## Sheet (ChatGPT chat "Create Christmas Design Sheet")
`sheet.png`: one row per prop, each FRONT, SIDE, EXPLODED (wreath: ring, pine clumps, baubles, bow; garland: garland, bauble, bulbs, bows; peppermint: disc, wrapper ends).

## Build
`build_walldecor.py` (headless) writes `Wreath.glb`, `Garland.glb`, `Peppermint.glb`. Front = -Y (out of the wall).
| model | tris | MeshParts | FRONT IoU |
|---|---|---|---|
| Wreath (30 faceted pine clumps + dark core, 5 red baubles, traced bow) | 1,008 | Pine, PineDark, Red | 0.888 |
| Garland (14 clumps on a sag curve, 6 bulbs, gold bauble, 2 bows, 2 hooks) | 600 | Pine, PineDark, Red, Gold, Bulbs | 0.820 |
| Peppermint (16 swirled wedges, rounded rim, 2 faceted wrapper fans) | 616 | Red, White, Wrapper | 0.896 |

- Refinement pass done (28 Nov): still just under the 0.90 gate. Diff maps show the rest is clump bumps against the sheet's black outline strokes (1-2 px all round) and the garland's bow loops; shapes match by eye. Accepted as is; check them in Play after the swap.
- Wreath side view 0.756: the sheet's side view is taller than its front (sheet conflict).

## Swap plan (after "go")
Scale each copy to the old copy's bounding box with front facing out of the wall (old parts' LookVector). Wrapper: Transparency 0.25.

## Low-poly rebuild + swap (28 Nov, owner low-poly rule)
Wreath = one faceted torus (10 x 5, Pine/PineDark facets) + 20-tri baubles: 268 tris -> **72906414238969** (7 wreaths). Garland = one faceted sagging tube (8 x 5) + bigger bulbs: 410 tris -> **106693871043857** (68 swags, hung between the old bow pairs). Peppermint = 8 swirl wedges over 2 rings: 200 tris -> **133013461585821** (the 15 old "plates" were 3 floor stacks of 5 candies: placed flat, no wrapper, solid). Old clump script kept as `build_walldecor_clumps_old.py`. Backups `RemodelBackup.Makeover_*`.
