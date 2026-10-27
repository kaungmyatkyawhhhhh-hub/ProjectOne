---
date: 2026-10-28
tags: [speedarc, progress]
---
# Progress - Hub props v2 (modelling like a human artist)

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

The 13 hub props from prompt 1, remade to the new "Modelling like a human artist" rule in [[SPEED ARC/CLAUDE|CLAUDE.md]].

## What changed
- **Rounded edges everywhere:** bevels on every part (weighted normals keep flat faces flat), no sharp cube edges.
- **Cut-outs and insets (real geometry):** open truss towers on the arch (you can see through them) with gusset plates that have a round hole; recessed belt, recessed screen and buttons on the treadmill; slatted bench with gaps; hollow cone top and a recessed base seat; serrated starting-block rail with grooved pads; lamp head with a recessed glow panel; bleacher risers set back under a bull-nose cap.
- **Natural look:** sculpted tree crowns made of lumpy clumps (no plain balls), bent trunks with a flared base, pine tiers with drooping long/short tips; bench slats each a slightly different wood tone and a hair out of line; fans with hair, collars and arms in 3 poses (cheer, wave, flag). The builder gives cones and fans a small random turn.
- **3-tone vertex shading:** base colour, a lighter highlight on convex bevels, darker corners and gaps (curvature + baked ambient occlusion), plus a soft wear tone.
- **Same sizes and pivots as v1:** every bounding box matches within 0.005 studs, so they drop into the same places.

## Triangles (budget: props ~200-2,000, buildings 3-8K)
| Prop | v1 | v2 | in the hub |
|---|---|---|---|
| Crowd fans A/B/C | 188-308 | 492-544 | x129 |
| Bleacher section | 1,692 | 2,176 | x5 |
| Start arch | 1,284 | 4,200 (one landmark) | x1 |
| Treadmill | 792 | 2,020 | x4 |
| Bench | 432 | 1,392 | x4 |
| Lamp post | 668 | 1,300 | x4 |
| Starting block | 324 | 1,308 | x3 |
| Cone | 292 | 692 | x3 |
| Tree round A / B | 144 | 366 | x~19 |
| Tree pine | 684 | 268 | x~5 |

Hub total for these meshes: about 55K triangles before, about 115K after. Most of the increase is the 129 fans (~66K). If the phone F9 test is slow, the first fix is fewer fans (or a simpler far-away fan).

## Before / after (same 3/4 camera, left = v1, right = v2)
| Before | After |
|---|---|
| ![[Start_Arch before.jpg]] | ![[Start_Arch after.jpg]] |
| ![[Bleacher_Section before.jpg]] | ![[Bleacher_Section after.jpg]] |
| ![[Treadmill before.jpg]] | ![[Treadmill after.jpg]] |
| ![[Bench before.jpg]] | ![[Bench after.jpg]] |
| ![[Crowd_Fan_A before.jpg]] | ![[Crowd_Fan_A after.jpg]] |
| ![[Crowd_Fan_B before.jpg]] | ![[Crowd_Fan_B after.jpg]] |
| ![[Crowd_Fan_C before.jpg]] | ![[Crowd_Fan_C after.jpg]] |
| ![[Tree_Round_A before.jpg]] | ![[Tree_Round_A after.jpg]] |
| ![[Tree_Round_B before.jpg]] | ![[Tree_Round_B after.jpg]] |
| ![[Tree_Pine before.jpg]] | ![[Tree_Pine after.jpg]] |
| ![[Lamp_Post before.jpg]] | ![[Lamp_Post after.jpg]] |
| ![[Cone before.jpg]] | ![[Cone after.jpg]] |
| ![[Starting_Block before.jpg]] | ![[Starting_Block after.jpg]] |

## Files
- New .fbx (+ .blend) to import: `Downloads\speed_arc_models\hub\v2\` (13 files, same names as v1, plus `hub_kit_v2.py`).
- Scripts in the vault: `Games/SpeedArc/blender/hub_kit_v2.py` (the kit), `preview_compare.py` (before/after renders), `bbox_dump.py` (size check).

## What I need from you
1. Import the 13 .fbx files from `Downloads\speed_arc_models\hub\v2\` the same way as before (3D Importer, "Scale unit: Stud", import as model).
2. Tell me, and I'll swap them into `ServerStorage/Meshes`, rebuild the hub and check it in play and at phone size.
