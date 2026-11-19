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

RESULTS_BRIDGE

## 2. Lag spikes

RESULTS_LAG

## Traps (also in the Playbook)
- Compact building data (P4-P12) is laid out on the client; one big compound building's roof grid took 190 ms in ONE frame (P7 tile 135_159). A per-frame time budget only works if the heavy step itself can stop: `KD.expand` / `roofSlabs` now pause at the frame's deadline (coroutine), and the roof grid keeps each corner test (same output as `kit_layout.py`: all 1,632 P4 / P7 tiles byte-identical).
- A dict keyed by a name silently keeps the last of several records: check every `{x['name']: x}` over data that can repeat.
