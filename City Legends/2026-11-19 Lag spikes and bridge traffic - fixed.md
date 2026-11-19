# 2026-11-19 Lag spikes and bridge traffic: fixed

Owner, from Play (19 Nov):
- "in some places, it lag spikes so much" (later clue: mostly on the **small roads**, side streets and lanes)
- "i saw npc traffic cars falling inside a bridge"

## 1. Traffic inside the bridges

### Where
Every 1:1 lane point (85,282) was checked against the BUILT road collision (`Yangon1to1.Roads.Collide`, R carriageway and D deck boxes: the visual road meshes are `CanQuery = false`, so rays only see the boxes). 2,552 points are on decks or bridges.

| Road (lanes) | Where | What the cars did |
|---|---|---|
| Hledan Road #3 (Hledan Road Flyover, P4) | (24930..25600, 25..49, 28300..29060) | drove at ground height (25.7) INSIDE both ramps while the deck rose to 40.9, then jumped up 15 studs onto the deck |
| Kabar Aye Pagoda Road (its south flyover, P7) | (34650..35030, 77..95, 33530..34100) | ran down from 95 to 77 through the flat deck slab (95.4) |
| Road #25 (the river bridge approach, P3) | (31120..31410, 32..49, 45300..45480) | flat at 31.9 inside a ramp rising to 48.7 |
| Pyay Road #6, Lanmadaw Road | (27150..27430, 49..58, 27130..29240), (32490..32510, 44.5, 42980) | same fault, shorter |
| Arzani Street (after its flyover, P7) | (32745..33330, 129.6, 36190..36345) | floated in the air at the deck's height for ~550 studs over the road built 20-36 studs lower |

### Why
1. **The lane writer kept only one deck per road.** `roads05_lanes.py` put the decks in a dict keyed by road name (`{d['of']: d}`), so a road with 2-3 decks got deck heights on its LAST deck only; the lanes over its other decks stayed at ground height and the cars drove inside the ramps and slabs. Five roads have more than one deck: Hledan Road #3 (3), Kabar Aye Pagoda Road, Road #25, Pyay Road #6, Lanmadaw Road (2 each). 1,340 lane points were wrong, 1,234 of them by more than 2 studs. It was never the cars' own physics: traffic cars are anchored and placed exactly on the lane points (`Traffic.lua` BulkMoveTo, no ground ray).
2. **The builder re-grades some stretches** (Arzani Street past its deck is built well under its data height), and the lanes only knew the data.

### Fix
- `roads05_lanes.py`: every deck of a road is applied.
- New: the lanes follow the BUILT surface. `tools/yangon/LaneHeights.luau` (Studio, Edit) lists every lane point that is not on an R / D top; `roads05_lanes.py` reads `roads05_<tag>/lane_heights.txt` and lifts a point onto a top that is 6 or less over it (a car there would be inside the slab), drops a ground point that floats over a top, and keeps a deck point over nothing (a hole in the deck collision: counted as `deck_gaps`). **Re-run LaneHeights after any road swap, then the lanes.**

3. **Lanes were joined in 2D.** The writer cut a lane wherever it crossed a bigger road on the map, even when one of them was a deck far above: **123 links ran from flyovers and bridges down to the roads under them** (Yangon-Dala Bridge, Hledan Road #3 to Baho Road #3, Pyay Road #6 / #9, Yarza Thingyan Road ...). A car on one drove diagonally through the deck. Before the height fix those lanes were at ground height inside the ramps, so it was hidden there.
   Fix: two roads meet only within 6 studs of height (junction cuts and every end link: lane starts ahead, lanes passing ahead, the last-resort rescue). 123 -> 1 (6.5 studs, a steep junction ramp, fine). Lanes 923 -> 901 (fewer false cuts), links 2,100 -> 2,019, 0 dead ends.

### Result (Studio, `YangonLanes1to1_*` re-installed from `roads05_L12347`, all 15 modules require-tested)
- Lane points against the built collision: 1,115 moved onto the built surface (+ the deck heights of the 5 multi-deck roads); points sunk into a deck > 1.5 studs: **4** (2.6 each, at deck feet) where the Hledan ramps alone had ~25 points 2-15 studs inside before; air / gap points 167 -> 95 (most are ground stretches between collision boxes).
- Play, traffic watched 12 s at each flyover (cars within 500 studs, car bottom vs the collision under it): **Kabar Aye flyover 26 cars, worst 0.52; Arzani flyover 23 cars, worst 0.90** (tyres / camber). Hledan 27 cars: one car 5.2 into the surface at (25387, 44.5, 28564) = on a link from the deck down to Baho Road #3: that is the 2D-join fault above, found here and fixed after this check (the final Play check is below).
- **Still open (builder / data, not lanes): 32 deck lane points where the data's deck is longer than the deck that was built** (no deck collision within 20 studs): end of Pyay Road #6's deck (27290..27344, 58, 28860..28916) ~6 over the road; (27054, 73, 27890) 24 up; Lanmadaw Road (32494, 56, 42619) (the P3 deck being rebuilt by the district agent); the south end of the Kabar Aye flyover (34640..34663, 95, 34110..34161) ~60 studs past the last deck box; the Road #25 ramp (31456..31503, 15..24, 45506..45616). Cars there run a short way in the air. Fix the deck extents in the builder / data, then re-run LaneHeights + lanes.

## 2. Lag spikes

### How it was measured
- Studio main place, Play on the test save (`CityLegends_test`, switched back after), the player's own car driven along a fixed route by a kit (car moved every frame along lane / street polylines, so the camera, the traffic focus and the server's streaming focus all follow it like a real drive). 8 stretches: main roads at 80 studs/s (Kabar Aye flyover, Hledan flyover, Sule, Shwedagon Pagoda Road), small roads at 53 studs/s (Bahan: Lane #4890, Pantra Kyaung Street; west of Inya Lake: Thanlwin Road, Lane #36 + Lane #957); a hop (teleport, like fast travel) before each, 6 s parked.
- Every frame logged with position, instance-count change, kit-tile change and Lua heap change. **Studio's own frame is ~68 ms on this PC before** (client + server + editor in one process), so a "spike" here = a frame of 120 ms or more.

### Before -> after (frames >= 120 ms while driving; worst frame)
| Stretch | Before | After |
|---|---|---|
| Inya lanes, Thanlwin Road (small) | 91 (84 over 200 ms), worst 589 ms | **0**, worst 86 ms |
| Inya lanes, Lane #36 / #957 (small) | 40 (38 over 200), worst 668 | 1, worst 162 |
| Bahan, Lane #4890 (small) | 44 (35 over 200), worst 553 | **0**, worst 78 |
| Bahan, Pantra Kyaung St (small) | 2, worst 237 | 0, worst 54 |
| Kabar Aye flyover (main) | 9, worst 145 | 0, worst 107 |
| Hledan flyover (main) | 10, worst 177 | 0, worst 93 |
| Sule (main) | 15, worst 186 | 0, worst 66 |
| Shwedagon Pagoda Road (main) | 21, worst 306 | 1, worst 134 |
| Average frame (whole drive) | ~68 ms (15 FPS) | ~18 ms (55-60 FPS) |

(Part of the baseline change may be other load on the PC between the runs; the per-spot test below is the like-for-like one.)

### The causes
1. **Traffic, on every small road (the biggest one).** NPC traffic only has lanes on the main roads (923 lanes = **92,253 segments**). Every 0.5 s the recycler looks for a new spot for each car that is far from you (`findSpot` -> `lanesNear`), and `lanesNear` tested EVERY segment's box: **~20 ms a call on a fast PC**. On a main road 3 cars find a spot and it stops (~60 ms every half second); on a small street no lane is near, so every car's search fails, it never stops, and ~28 full scans ran in ONE frame: ~500 ms, twice a second. Spot test on Thanlwin Road: frames averaged 146 ms (worst 616) against 69 ms on Kabar Aye at the same moment; client Heartbeat 21 ms vs 4 ms; render 13-20 ms either way; hiding the kit / trees / buildings / roads / traffic cars changed nothing (the cost was the script, not the scene). On a phone that is 3-4x worse.
   Fix (`client/Traffic.lua`): the segments are kept in a 512-stud grid; `lanesNear` runs the same box test only on the cells round the point.
2. **Compact building data in P4 / P7 (small streets with dense buildings).** The building detail of P4-P12 is stored compactly and laid out on the client (`KD.expand`) when a tile loads; the streamer's 3 ms budget was only checked BETWEEN steps, and the first step laid out the whole tile: 205 tiles over 10 ms, 19 over 30 ms, the worst **164-190 ms in one frame** (P7 tile 135_159, Bahan / Shwedagon side: one big compound building's roof grid).
   Fix (`shared/YangonKitData.lua`, `client/YangonKitStream.client.lua`): the layout runs in a coroutine that stops at the frame's deadline and goes on next frame; the roof grid keeps each corner test (neighbouring cells share corners: 34% less work overall). Checked on all 1,632 P4 / P7 compact tiles: **byte-identical** output to the old decoder, worst single step 9.5 ms (was 164).
3. **Tiles taken down all at once after a hop / fast travel.** Found in the after-run: one frame destroyed ~30 tiles (~5,000-6,800 parts): 90-230 ms. Fix (`YangonKitStream`): a tile that goes is taken down 100 parts at a time inside the same frame budget.

Checked and NOT the cause: physics (2.3 ms a step, 2 contacts at the worst spot), rendering (13-20 ms), GC (no big heap drops at the spikes), streaming bursts while driving (dInst 0 on the spike frames).

FINAL_PLAY

## Traps (also in the Playbook)
- Compact building data (P4-P12) is laid out on the client; one big compound building's roof grid took 190 ms in ONE frame (P7 tile 135_159). A per-frame time budget only works if the heavy step itself can stop: `KD.expand` / `roofSlabs` now pause at the frame's deadline (coroutine), and the roof grid keeps each corner test (same output as `kit_layout.py`: all 1,632 P4 / P7 tiles byte-identical).
- A dict keyed by a name silently keeps the last of several records: check every `{x['name']: x}` over data that can repeat.
