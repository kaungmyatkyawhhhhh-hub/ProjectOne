---
tags: [gym-arc, christmas-update, progress, 3d-model]
date: 2026-11-28
---
# Christmas remodel batch 3: yard props, wall decor, LOW-POLY rule, bigger Winter Yard

Saved to Roblox as **v2059** (pre-save steps done; not published). Place 80031260599632.

## Owner notes this batch (all done)
1. **"do low poly style models ... non low poly style is making the model look ugly"** (example: faceted paper-craft candy cane). New rule written into the roblox-3d-model-from-sheet skill (vault copy, plugin copy needs re-upload) + memory. Reference look: 6-8 sided tubes, long flat quads, one ring per colour band, rings only where a shape bends, flat shading.
2. **"still wrong ... the reference saves more triangles"**: giant cane rebuilt again as v2: 8 sides, ONE ring per stripe on the straight shaft, 30° tilted bands, extra rings only round the hook. **1,880 -> 312 tris**. `GiantCane/build_cane_lowpoly.py` -> Model **73612155677866**.
3. **"the gold ring is missing"**: the cane's gold band is back (visible on both lift canes).
4. **"the christmas event is so small and tight"**: Winter Yard expanded ~3x: x -44..112, z -96..-208 (was x -38..38, z -92..-150).
   - Terrain cut flat at y 0 (Snow; top cell half-filled so the surface sits at 0, not 2), sloped terraces up to the hills north/east/west. Backup: `ServerStorage.RemodelBackup.Terrain_XmasYard_preExpand` (TerrainRegion).
   - Invisible walls moved: `Xmas.Opening.Boundary` north z -210.5, east x 114.5, new `BoundaryW` x -45.5 (z -163..-210). SnowFloor resized.
   - New layout round a plaza at (18,-118): tree + free gift centre (34,-152), Mega Gift Lift (-14,-172), Frost Titan pedestal (80,-162), cane shop (-24,-126), all facing the plaza (yaw-only turn from their original pivots). 20 pines on the edges (6 new clones). Town Cypress/RoundTree moved out onto the east slope.
   - Backups: `RemodelBackup.Yard_preExpand`, `LandmarkTree_preExpand`, `FreeGift_preExpand`, `Opening_preExpand`.
5. **"no popular game does this text"** (FREE GIFT! billboard): removed (`RemodelBackup.FreeGiftLabel_old`); the gift now has a soft gold sparkle + warm glow; the ProximityPrompt is unchanged.

## Swapped in (all low-tri Blender meshes, roblox-3d-model-from-sheet)
| object | old | new | asset |
|---|---|---|---|
| Titan pedestal | 11 parts | 5 MeshParts (872 tris), old Base/Top/Step kept invisible as colliders, FX moved to TP_Frost | 121613224912725 |
| Lift rig frame | ~136 parts | 7 MeshParts (2,724 tris); Pad, Posts kept invisible (collision, MegaLift uses Pad), SignBoard invisible with its SurfaceGui in front of the mesh sign | 79991385849553 |
| Giant canes (2) | rope-style 1,880 tris | low-poly v2 312 tris | 73612155677866 |
| Wreaths (7) | 175 parts | low-poly faceted torus, 268 tris each | 72906414238969 |
| Garland swags (68) | 740 parts | faceted sagging tube, 410 tris each | 106693871043857 |
| Peppermint stacks (3 x 5) | 120 parts | 8-wedge swirl disc, 200 tris, solid | 133013461585821 |
| Yard fence | 155 parts, 76x58 | 79 sections round the new yard, 250 tris each | 136174487561012 |
| Street lamps | 4 (8 parts) | 12 low-poly lamps along the path/plaza, PointLight on the glass | 138440086597146 |
| Ceiling light strings | 587 parts (299 wires + 288 bulbs) | 90 spans (4 C9 bulbs, 220 tris) laid along the 8 old wire chains | 76886121186183 |

Low-poly passes this batch: wreath 1,008 -> 268, peppermint 616 -> 200, fence 504 -> 250, light string 852 -> 220 tris.

## Checks
- Play: no new errors (only the usual ConfigService "not found" lines). Client FPS in Studio 14.9 with the decor vs 14.3 with the whole Xmas folder removed = the decor costs nothing measurable (Studio caps this machine at ~15).
- Xmas folder in Play: 1,587 MeshParts + 481 Parts.

## Next
- CaneShop mesh still has the older non-low-poly look; rebuild low-poly. Same for Xmas tree / presents if the owner wants them faceted.
- Entrance arch, Extra (PlateTree x2, Street, Banner), Pines, then Gem Cave (#16-25), machines last.
- Garland/wreath gate IoU not re-run after the low-poly rebuild (silhouette kept, style changed on purpose).
