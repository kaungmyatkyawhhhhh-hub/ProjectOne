---
tags: [city-legends, roads, roads05, collision]
created: 2026-11-24
---
# Road steps fix: crests, deck feet and collision seams (24 Nov 2026)

Follows [[2026-11-24 Road fix - Arzani Street deck and crests]] ("Crests and steps" table). Everything is fixed where it starts, in the shared builder, bake and generator code, so P11 / P12 and every later rebuild get it too. Ten cells were rebuilt whole with the batch 0.5 builder (Roads.luau + YangonRoads.luau) and swapped. Final save **v1956**: in Edit, store `CityLegends_v1` (read on the Server), lock released, ready for the owner to publish. Not published.

## The causes and the fixes

| # | Fault | Cause | Fix (shared code) |
|---|---|---|---|
| 1 | Ahlone Road #3 deck foot: the road dropped 4.7 studs at the foot, and the 24 Nov try made it start 3 over | `Roads.luau` relax step: the samples under a deck (cut, never built) were still treated as neighbours of the built road. Their heights were walked down at the 5% edge grade, which lifted (or dropped) the built road's start. | `relax` skips cut samples: they neither move nor hold anything. Repro in Studio: road start 64.9 before, 61.82 (= the deck foot) after. Data: `roads05_ahlone_fix` (samples under the deck take the deck's heights) is applied again. |
| 2 | Collision: 1.25 hop at Lane #1957's slanted mouth on Arzani, 1.6-deep cracks between boxes | `roads05_bake.collision`: each road box was a flat strip from the road data over up to 96 studs, so it didn't follow a slanted mouth (a side road's box ran into Arzani). Straight boxes also left a wedge gap open on the outside of each bend. | `fit_boxes`: every carriageway box's top is the best-fit plane of the BUILT surface under it (along and across), split in two until it is within 0.12 everywhere. Each box end grows by tan(turn/2) x its outer edge, which closes the wedges. Pavement boxes: `roads05_pbox_clip` drops pavement-box parts that stand over asphalt or a deck top. That was the 0.7 invisible kerb on the May Ni Gone deck end. |
| 3 | Every other point too high or too low (zigzag) on Ziwaka, Shwe Gone Dine, Old Yay Ta Shay #2, Merchant, May Ni Gone, Maha Bandula #2 | `roads05.py` heights: the profile points are ~15 studs apart and the inverse-distance weights go flat at each point. Each 8-stud sample alternated between a flat and a steep step (up to 8% grade change). | `roads05.smooth_chain`: heights smoothed along each road over ±16 studs. |
| 3b | Maha Bandula Road #2 by Sule: built 3.3 over its data, then a 4.2 drop | `roads05_fix.ring_level` lowered the road 3.8 studs where 31st Street crosses it, 150 studs from Roundabout 4, but left 31st Street at the old height. The builder then pinned Maha Bandula's edges up to 31st Street. | `roads05_fix.repin_crossers`, run by ring_level: a road crossing a lowered stretch takes its height there and eases back at 4%. |
| 4 | A re-run of `roads05.py` would make the fake Arzani deck again | The old P7 profile's "raised" run | `roads05.py`: a raised profile point is a deck only within 40 studs of an OSM bridge way (`BRIDGE_NEAR`). Arzani has none. |

- Data: `tools/yangon/city/roads05_steps_fix.py` (`test` = self-check) applies 1, 3 and 3b to the network, the lanes data `roads05_LP1to10` and new subsets RB6s / RB3s / RB7s / RB8s. Backups: `roads_before_stepsfix.json`.
  - The smoothing works only inside the rebuilt cells and fades out over 60 studs at their edges, so the seams with older cells stay level.
- Offline check: `tools/yangon/city/roads05_collide_check.py <tag> x0 z0 x1 z1`. It compares the bake's boxes with the built road surface (off, steps, cracks) without Studio.

## Rebuilt (whole cells, batch 0.5 builder, 0 mouths failed)
- **17x25** (Ahlone) and **18x22** (May Ni Gone): RB6s
- **22x29 + 23x29** (Merchant, Maha Bandula #2): RB3s
- **21x25 + 22x25** (Ziwaka) and **22x24** (Old Yay Ta Shay #2): RB7s
- **23x21** (Shwe Gone Dine): RB8s
- **20x23 + 21x23** (Arzani): re-baked from the 24 Nov pages, new collision only.
- All 953 old road meshes elsewhere were set to CollisionFidelity Box. None of them collide; this freed ~20 MB of place size.
- The old cells were deleted after the swap (place size). The deleted items are listed in `build/city_1to1/mapbugs/deleted_24nov_steps_fix.txt`.
- Lanes:
  - The old lane-height rows in the 10 cells were dropped, LaneHeights was re-run and `roads05_lanes.py LP1to10 --install` re-run.
  - Result: 1,322 lanes, 3,080 links, 0 dead ends. 13 modules synced; require 26/26.
  - LaneHeights in the 10 cells went from 387 points off the road to 8. The 8 are ground points under the May Ni Gone deck, on the road.
- DeckFeetCheck (Ahlone, May Ni Gone): 2 ok, 0 bad.

## Step at each spot (collision, the most change in height between two points 2 studs apart, every lane)
A road at 5% climbs 0.1 in 2 studs, so about 0.1-0.2 is just the slope.

| Spot | Before | After |
|---|---|---|
| Ahlone Road #3 deck foot (27503, 39765) | 4.71 | 0.10 (deck box 61.92, road box 61.82) |
| Maha Bandula Road #2 at 31st Street (35667, 45116) | 1.08 (the 4.2 drop over ~8 studs) | 0.20 |
| Ziwaka Road (33738, 39455) | 0.81 | 0.13 |
| Merchant Road (33955, 45889) | 0.49 | 0.23 |
| Shwe Gone Dine Road (36439, 33326) | 0.52 | 0.19 |
| Old Yay Ta Shay Street #2 (34505, 37748) | 0.29 | 0.13 |
| May Ni Gone Overpass deck end (29048, 35056) | 0.69 (pavement box over the deck) | 0.15 |
| Arzani, Lane #1957 mouth (32836, 36243) | 1.29 (box 1.39 over the road) | 0.12 (offline check) |
| Arzani box cracks (32969, 36326) / (33603, 36458) | cracks inside the carriageway | none (offline); 0.17 on the lanes in Studio |
| Hledan Road #3 deck (25082, 28895) | 0.15-0.24 | not rebuilt: the 1.6 measured before was the probe's ray starting under the deck |
| May Ni Gone deck end, 3 studs off the centre (after the 18x22 redo) | 2.53 (pavement box over the deck) | 0.14 |

## Play drive (test store `CityLegends_test`, then back to `CityLegends_v1`)
The starter car was driven along each road's centre line with the test hooks (throttle, plus steering toward the next road point). "Jolt" is the biggest change in the car's up/down speed, in studs/s².

| Spot | Result |
|---|---|
| Ahlone Road #3 deck foot | rolls down the deck onto the foot at a steady -1.2 studs/s up/down speed, no bump |
| Maha Bandula Road #2 at 31st Street | no drop any more. A small crest is left where 31st Street crosses (jolt 18 at 34 mph; the 31st Street junction is flat across) |
| Ziwaka Road | jolt 4 |
| Merchant Road | smooth over the listed spot. Jolt 26 further on at (33903, 45889), where Merchant runs into Strand Road (the two road surfaces meet unevenly there) |
| Shwe Gone Dine Road | jolt 4 |
| Old Yay Ta Shay Street #2 | jolt 3.7 |
| Arzani Street over Lane #1957's mouth and the old cracks | jolt 3.5 |
| May Ni Gone Overpass deck end | jolt 8.6: the real dip at the foot (the deck comes down, the ground road climbs away) |

Shots:
- ![[2026-11-24 road steps fix - Ahlone Road 3 deck foot (Play) - after.jpg]]
- ![[2026-11-24 road steps fix - Maha Bandula Road 2 at 31st Street (Play) - after.jpg]]
- ![[2026-11-24 road steps fix - Ziwaka Road (Play) - after.jpg]]
- ![[2026-11-24 road steps fix - Merchant Road (Play) - after.jpg]]
- ![[2026-11-24 road steps fix - Shwe Gone Dine Road (Play) - after.jpg]]
- ![[2026-11-24 road steps fix - Old Yay Ta Shay Street 2 (Play) - after.jpg]]
- ![[2026-11-24 road steps fix - Arzani Street at Lane 1957 mouth (Play) - after.jpg]]
- ![[2026-11-24 road steps fix - May Ni Gone Overpass deck end (Play) - after.jpg]]
- Found in the drive and fixed: ![[2026-11-24 road steps fix - May Ni Gone deck end, deck surface missing (Play) - before redo.jpg]]
  - The May Ni Gone deck's middle is in 19x23, so the cell-only build of 18x22 had no deck: the swap lost that deck's surface in the cell.
  - 18x22 was rebuilt with `DECK_TOUCH` (every deck with a sample in the box is built). `RebuildCell.RBXJob` now always sets it.
  - The same pass fixed two collision faults: a pavement box 2.5 over that deck's carriageway (`roads05_pbox_clip`: never over a deck carriageway), and a hole between two Ahlone deck boxes on a bend at (27140, 39890) (deck boxes now grow at bends like the road boxes).

## Saves
- v1943 (cells swapped).
- From 13:14 UTC every save timed out ("server publish request timed out", status.roblox.com all green; this PC's network was dropping connections). The old file-too-large errors (12:25-12:42) came from the temporary data modules and backups, all deleted.
- Studio was relaunched; then v1949, v1952, v1954, and **v1956** (final).
- Deleted to keep the place small: `build/city_1to1/mapbugs/deleted_24nov_steps_fix.txt`.

## Left
- **25 Nov:** the Maha Bandula #2 crest, Merchant into Strand and the 6 P8 kerb cells are done: [[2026-11-24 Road joins fix]].
- The Maha Bandula #2 crest at 31st Street: 31st Street ranks above Maha Bandula #2 in the data (2097 vs 2378), so the main road is held level across the street. A rank fix would remove it.
- Merchant Road where it runs into Strand Road (33903, 45889): the two surfaces meet unevenly (lumps of 0.2-0.3).
- 347 lane points elsewhere on the map are still off the built road (LaneHeights, outside these cells). They were there before.
- The new collision fit is only in these 10 cells. Other cells keep their old boxes until they are next baked.
