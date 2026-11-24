---
tags: [city-legends, roads, roads05, bake]
created: 2026-11-24
---
# Road joins fix: Maha Bandula rank, Merchant into Strand, P8 kerbs (24 Nov 2026)

Follows [[2026-11-24 Road steps fix]] ("Left"). All three fixed at the cause in shared code and data; 7 cells rebuilt whole with the batch 0.5 builder (Roads.luau + YangonRoads.luau) and swapped. Final save **v1983**: Edit, store `CityLegends_v1` (read on the Server), lock released. Not published.

## Causes found and fixed (shared code, so every later bake keeps them)

| # | Fault | Cause | Fix |
|---|---|---|---|
| 1 | Maha Bandula Road #2 crest at 31st Street | A fresh `roads05.py` run ranks Maha Bandula Road #2 at 24. `roads05_chain.rerank` (run by `roads05_fix`) pushed it to 2378: its end lies inside a stub of the same road ("Maha Bandula Road", a continuation 10 studs off) and the rule only skipped ends within 2 studs. Behind ~25 residential streets, the main road was pinned level at each crossing. | `rerank`: an end within the other road's own half of that road's end is a continuation, not "ends inside"; a bigger-class road ending inside a smaller one never makes it the smaller one. Data: `roads05_rank_fix.py` (`test`) moves Maha Bandula Road #2 to rank 118.5 (net, LP1to10, new subset RB3r): every street it crosses in 22x29 + 23x29 now meets its surface (31st, 32nd, Bo Soon Pat, 27th-30th, Kon Zay Tan, Shwe Bon Thar, Shwedagon Pagoda Road). |
| 2 | Merchant Road into Strand Road: jolt 26 at (33903, 45889) | Two causes. (a) Merchant's data ran 0.6-1.7 over Strand's surface where its carriageway already lies on Strand's; the builder pulled it down onto Strand, so the built road dipped and stepped 0.8. Fixed by `roads05_merge_fix.py` (`test`): Merchant's samples within Strand's side + 6 take Strand's height, the 120 studs behind blend back, crossing streets re-pinned. (b) Not the data and not the builder: a Studio build of the two roads has Strand flat across (edges = centre). The bake's v2 page format stored each part's rotation as a quaternion's x, y, z (x 4000) and rebuilt w. Road wedges are turns near 180 degrees (w near 0), so w came back wrong and every wide road triangle was tilted up to 0.03 rad. On Strand's 65-stud triangles that is 0.4-0.8 studs: a sawtooth across the road every few samples. The visual meshes and the collision fit both came from these tilted triangles. | `RoadBake05.collect` writes v3 pages (body starts `~T~`): smallest-three quaternion, the largest component dropped, the other three in 3 characters (x 515,000). `roads05_bake.decode_q` reads both. Round trip in Studio: worst axis error 3.6e-6 (was ~1e-2). `RebuildCell` now requires a Clone of RoadBake05 (a cached copy would keep v2). |
| 3 | 5 P8 cells with the old kerbs (23x26-27x26) | Their pages were only on the laptop. (23x21, the 6th, was rebuilt in the steps fix with RB8s.) | The RB8s data (asset 95224778874033) is here: rebuilt whole with stepCell, v3 pages, kerb fix + collision fit in the bake. |

**Map-wide note:** every road cell baked before 24 Nov carries the v2 tilt (worst on the widest roads). Only cells rebuilt from now on are free of it.

## Rebuilt (whole cells, batch 0.5 builder, v3 pages, 0 MOUTH FAILED)
- **22x29 + 23x29** (Maha Bandula #2, Merchant / Strand): subset RB3r (= RB3s + rank fix + merge fix + fresh paint), 102,167 parts, 24 meshes, 1,740 boxes.
- **23x26-27x26** (P8 row, the old kerbs): subset RB8s, 3 boxes (39,842 / 99,979 / 98,331 parts), kerb fix in the bake (49 kerb pairs: 41 dropped, 1 raised; 67 leaning pieces dropped), 56 meshes, 3,617 boxes. The 790 HoleFill boxes of the old cells were all flush with the new collision: removed.
- Old cells and boxes deleted after the swap (place size); new meshes CollisionFidelity Box, no shadow, CanCollide off.
- Lanes: lane-height rows in the 7 cells dropped (185), LaneHeights re-run after the swap (145 rows: mostly the old Shwedagon Pagoda Road stretch at 34178, 45730-45880 that the builder lays 1-1.5 under its data, snapped by the lanes), `roads05_lanes.py LP1to10 --install`: 1,326 lanes, 3,080 links, 0 dead ends; 26 modules synced, require 26/26.
- DeckFeetCheck (Set Yone Street Flyover, Thaketa Bridge Flyover in the P8 row): 4 ok, 0 bad.

## Numbers (before -> after)
| Spot | Before | After |
|---|---|---|
| Maha Bandula #2 at 31st Street (35667, 45116), Play | jolt 18 at 34 mph, crest across the street | no crest: the car runs straight through on the road's own grade (0.6 studs a 0.25 s sample, steady). Worst jolt on the run 9.0 at (35519, 45137): the grade change where the ring easing starts, not a step. Collision check: off 0.12, steps 0.09 |
| Merchant into Strand (33903, 45889), Play | jolt 26 | smooth through the merge (0.1-0.3 a sample). Worst jolt on the run 7.2 at (34109, 45896): the data's own flat-then-6% break 100 studs before the merge |
| Strand Road surface beside the merge | sawtooth 0.4-0.5 every ~3 samples (cross tilt +-0.4) | flat (0.01-0.05 between samples) |
| P8 row 26, Bo Min Gaung Street, Play | old kerbs (no kerb fix) | kerb fix in; jolt 9.8 (road grade only) |

Shots:
- ![[2026-11-24 road joins fix - Maha Bandula Road 2 at 31st Street (Play) - after.jpg]]
- ![[2026-11-24 road joins fix - Merchant Road into Strand Road (Play) - after.jpg]]
- ![[2026-11-24 road joins fix - Bo Min Gaung Street P8 kerbs (Play) - after.jpg]]

## Traps
- A rank change must also turn round every `data.crossings` record of the pair (the first road is the small one). The first build with the old records hung Studio for an hour (no yield, MCP unreachable); Studio was killed and relaunched (Team Create kept the edits, including the half-built cell: deleted).
- Studio relaunch after a kill: "Connecting to server" for ~20 minutes before the place opened.

## Saves
- v1981 (cells swapped, lanes, store v1), v1983 (after the Play test, store back to v1, read on the Server).

## Left
- **Every road cell baked before 24 Nov carries the v2 tilt** (0.1-0.8 studs on wide roads). Only these 7 cells and the ones rebuilt later are clean. A map-wide rebuild (cell by cell, same chain) would remove it.
- Merchant Road 1013-1023 (33990-34070): the box surface is smooth, but the visual surface still sits up to 0.4 under the boxes where Merchant's edge runs onto Strand (a builder pin, not a step).
- Maha Bandula #2 west of 22x29 (cells 20x29 / 21x29) is still held level at 9th-16th Street (the rank fix kept those cells' relations; they are the Road #25 valley build: rebuild them from a subset holding the valley fix).
- Shwedagon Pagoda Road's last 150 studs before Strand are built 1-1.5 under its data (lanes snapped; from before).
