# 23 Nov: live cleanup (half-finished builders, place size, road fixes)

The owner published about 03:00 on 21 Nov while three builder agents were stopped mid-work. This run makes the place look finished. Saved as **v1820, v1823, v1824**, store `CityLegends_v1`. **Not published.**

## The half-finished pieces
| Piece | What was there | Done |
|---|---|---|
| City Hall (`Landmarks.city_hall.Rebuild21Nov`, 973 parts + night lines `IrlNight21Nov.CityHall`) | Finished by its script (walls, towers, tiers, spires). One grounded piece, nothing floating, no parts on the road. 22 coplanar trim/wall and horn/eave faces (flicker) | Kept. The 22 trim/horn parts grown 0.06 so they no longer share a face |
| Sule shops + Sule stupa floods (`IrlNight21Nov.SuleShops`, `.SuleRoundabout`) | Complete; the floods' boxes touch the road box but sit inside the Sule base (checked by screenshot) | Kept |
| Maha Bandula Park fence (`IrlNight21Nov.ParkFence`, 508 parts) | Complete; 468 night-neon parts are hidden by day on purpose | Kept |
| Hanthawaddy roundabout monument (`IrlNight21Nov.Roundabout`) | Sits on the island collision at 75.63 | Kept |
| Other 21 Nov builds (`IrlBuild21Nov`: Chinese temple, Junction City canopy) | 5 coplanar faces | Smaller part of each pair grown 0.06 |
| **Yangon-Dala Bridge** (`Landmarks.DalaBridge`, 2,384 parts) | Not finished: the old flat deck still runs under it, collision gaps on the bends, the Dala end in the air with no ground, no lanes | **Pulled out** to `ServerStorage.DalaBridge_WIP_21Nov` (attribute `PulledFromLive`). The old road network is back as it was. Picture before: `2026-11-23 Live cleanup - Dala Bridge WIP before pull-out.jpg` |
| Stray stages | `Workspace._FixStage` (lamp audit car), `_UvTest`, `KitPilot` (test platform at y 600), `ReplicatedStorage.ZZTestKit` (Play test helper) | Deleted (after this run's Play test) |

Checks used (Edit, Luau): floating = parts grouped by touching boxes, each group must touch terrain or a support; flicker = two opaque boxes with the same face plane, same side, different colour or material; on-road = visible part over an R/D collision box. Results above.

## Place size
- Measured with `SerializationService:SerializeInstancesAsync` per top-level folder (sum of parts; it overstates the real file because shared data repeats per piece). Terrain alone 50.5 MB (57 s to measure: don't repeat that during a session).
- **Before ~192.7 MB, after ~176 MB (16.7 MB removed).** Saves pass (v1820, v1823, v1824).
- Removed (all are still in place versions up to v1760-1819):
  - `ServerStorage.RB_OldP8` (Temps + TreesOnRoad), `RB_PBoxOnDeck` (52 boxes)
  - `TerrainBackup_21Nov` (cell 23x29)
  - `LampBackup_21Nov` (24 cars, 8.3 MB) and `LampBackup_21Nov_beforeRealShapes` (5 cars, 2.0 MB): all 24 cars checked first, each has its 12 `LampFx_*` shells
  - `Backups.2026-11-08 SVJ before doors`, `Backups.2026-11-08 Aventadors before doors`, `Backups.2026-11-08 doors v3 (before the full covers)`
  - `TrafficModels_preBadges` (3.9 MB)
  - `Workspace._FixStage`, `_UvTest`, `KitPilot`, `ReplicatedStorage.ZZTestKit`
- Kept: `OldCarModels` (19.8 MB: RimSwap2 undo reads it), `OldModelCars` (25.7 MB: the Pending old-model cars), `Backups.ViewPointRemoved`, `Backups.OptimaTallShells`, the DealerBody backups (22 Nov), `KitTiles_P6/P8`, `P8Tools`. Those two car folders are the next 45 MB if the place gets tight again.

## Road fixes
- **Sule Pagoda Road hole (36092, 43529):** the real gap was a slit 16 x 3.6 studs at z 43537-43540 where the car fell to terrain 10 studs down. Filled: `Roads.CollideFix_SulePagodaRd`. Play: car drove over at a steady y 35.3.
- **P3 road bed poking through:** all R/P boxes in P3 sampled every 3 studs: 2,332 points had terrain above the road top, now 16 (max +0.74). Before / after: `2026-11-23 Live cleanup - Sule west arm road bed before.jpg` / `after.jpg`.
- **Road #25 valley joint:** collision only (`Roads.CollideFix_Road25Valley`): the pavement kerb across the Road Flyover's foot is cut back, and two ramp slabs join the ground road to both decks. Ray profiles: max step 0.38. The road MESH is unchanged (needs the 19x29-21x29 re-bake). Not driven in Play: the test teleport kept lifting the car onto the old Dala deck above.
- **P8 U Chit Maung x Banyar Dala deck dip:** the deck north of the junction has collision and NPC lanes (198-205, at 60.6) but **no road mesh at all**, so this is more than a dip. Done for now: the south deck ends at yellow / black barriers with a collision wall (`Roads.DeckEnd_UChitMaung`). Play: the car stops at the barrier. NPC cars on those lanes still pass through it until the re-bake.
- No road swap, so no LaneHeights / lane writer run was needed.

## Minimap
`minimap_1to1.py` FULL already lists P6 and P8. In Play, the minimap shows P8 in colour with buildings. Not checked: whether tile `d_0_0` (78495515679494, "in review" on 21 Nov) is approved. Open Cloud's asset read timed out.

## Test
- Saved before every Play. Play on `CityLegends_test`: Sule Pagoda Road hole, U Chit Maung barrier, City Hall from the Sule ring. No script errors from this work. Studio memory was 14.5 GB (low-end auto mode); Stop Play did not crash.
- The place's PlayerData was already set to `CityLegends_test` when this run started (left from an earlier test). Now `CityLegends_v1`, read back on the Server in Play.
- Pictures: `2026-11-23 Live cleanup - City Hall from Sule (Edit).jpg`, `- City Hall from Sule (Play).jpg`, `- U Chit Maung deck end barrier.jpg`, `- U Chit Maung deck end (Play).jpg`.

## Left
- Re-bake 26x21 plus the north U Chit Maung deck. The P8 pages exist only on the laptop. Then run LaneHeights and the lane writer, and remove `Roads.DeckEnd_UChitMaung`.
- Re-bake 19x29-21x29 for the Road #25 valley (a data fix first, see `rebuild_progress.json` road25.open_valley).
- Finish the Dala Bridge from `ServerStorage.DalaBridge_WIP_21Nov` (steps in `rebuild_progress.json` dala_bridge).
- Check that minimap tile `d_0_0` is approved.

## Lessons
- Smooth terrain: `FillBlock(Air)` on a small box does not lower the drawn surface (the neighbours' voxels hold it up). Write the 4-stud columns with `WriteVoxels` and aim about 2 studs under where the surface must end up.
- Edit screenshots straight after a camera jump show the coarse terrain sheet. Move `workspace.CurrentCamera` (CFrame and Focus), wait 4 s, then capture without the camera arguments.
- `TestTeleport` under a deck lifts the car onto the deck: test ground roads under flyovers some other way.
- Never run one MCP call that serializes the whole place (it dropped the connection).
