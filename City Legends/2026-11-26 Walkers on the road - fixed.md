---
tags: [city-legends, yangon, walkers, map]
created: 2026-11-26
---
# Walkers on the road (Myanmar Plaza) - fixed

Owner (26 Nov): "people are walking on the road near myanmar plaza".

## Cause
- The pavement walkers (`src/shared/YangonStreetLife*.lua`, made by `tools/yangon/city/streetlife_1to1.py`) were made once, on 17 Nov at 01:05, from the P1-P3 road data of that night.
- After that the roads were rebuilt and moved many times (J18-J37 passes, then the P1-P12 district rebuilds and the road bug sweeps). The walker paths were never made again, so they still followed the old road edges. Where a road moved, the paths lay on today's carriageway. At the south end of Kabar Aye by Myanmar Plaza one path even zig-zagged across the road.
- Also: only P1-P3 had walkers. P4-P12 had almost none.
- The walker code itself was fine (it walks the line and turns back at the end). Nothing spawns or drifts off the path.

## Fix
- `streetlife_1to1.py` now runs on the whole P1-P12 road network. Every path is then cut to what is really in the place:
  - every point must be on a pavement collision box (`RoadBox` P), and it takes that box's top as its height;
  - the walker's band (0.3-2.4 studs out from the line) must not touch a road, deck or median box (R / D / M).
- Where a path would go onto a road (a junction mouth, a side road), it stops and the walkers turn back. Nobody crosses a road.
- The boxes are dumped from Studio into `Games/CityLegends/build/city_1to1/walkers_26nov/` (`roadboxes_place.txt`, `paveboxes_place.txt`, 15 characters a box).
- The check is `tools/yangon/city/walkers_check.py`. It counts every path segment and point on a carriageway, and every point off a pavement, for each district.

## Counts (from the place's own boxes)
| | Before (17 Nov paths) | After |
|---|---|---|
| Paths | 1,026 (P1-P3 only) | 4,583 (all 12 districts) |
| Path segments on a carriageway | 1,780 of 19,292 | **0** of 53,441 |
| Path points on a carriageway | 2,674 | **0** |
| Path points off any pavement | 3,084 | **0** |
| Bad segments within 600 studs of Myanmar Plaza | 37 | **0** |

Before, for each district (bad segments): P1 340, P2 212, P3 1,170, P4 17, P7 10, P8 2, P9 13, outside 16. After: 0 in every district.

![[2026-11-26 Walkers - Myanmar Plaza paths before and after (top-down).png]]

## Re-run after any road swap
1. Dump the R / D / M and P collision boxes from Studio again (the Luau is in the progress entry `walkers_26nov`).
2. `YANGON_SCALE=1to1 python streetlife_1to1.py P1_P2_P3_P4_P5_P6_P7_P8_P9_P10_P11_P12`
3. `python walkers_check.py`: it must print 0.
4. Sync the 4 modules into `ReplicatedStorage.Shared` (`pack_sync.py` -> asset 133014134133489 -> LoadAsset).

## Not done
- Walkers only use main-road pavements, not side-street pavements.
- No crossings: walkers never cross a road, even at zebras.
- No parked cars or standing spots yet (the old shortcut).

Lesson filed in [[Map placement rules (every game)]] (26 Nov).
