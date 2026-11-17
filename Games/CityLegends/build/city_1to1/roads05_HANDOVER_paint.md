# roads05 paint handover (J17, 17 Nov 2026, PAINT agent)

These are the paint rules and their QA. The geometry handover is `roads05_HANDOVER.md`. Only the paint files were changed: `tools/yangon/city/roads05_paint.py`, `roads05_paint_qa.py` (and, J17, one line in `roads05_pipeline.sh`).

## How to run
- `YANGON_SCALE=1to1 python roads05_paint.py <tag>` (about 6 minutes on P1-P12) writes `paint.json`. Then `roads05_paint_qa.py <tag>` (about 2 minutes) writes `qa_paint_J15.json` and prints the counts.
- J17: the pipeline (`roads05_pipeline.sh`) now runs the paint QA too (`<label>_paint_qa.log`).
- J17 runs used a private copy of the network: `build/city_1to1/roads05_J17P/roads.json` = the P1-P12 `roads.json` of 17 Nov 13:38 (the J16 network; there is no `roads05_NETWORK_VERSION.txt`). QA files per run: `qa_base.json` (J16 paint on it), `qa_r1.json` .. `qa_r6.json` (r6 = final).

## J17 counts (same network, J16 paint -> J17 paint)
| rule | J16 | J17 | what changed |
|---|---|---|---|
| arrow_missing | 52 | 6 | arrows only at signalled approaches (photo check); arrows sit between the PAINTED lines (a lane still tapering out counts); QA: lanes = the painted dashes of that road, an arrow anywhere in its lane counts, arrow spots under a deck skipped |
| stopline_missing | 29 | 1 | stop lines only at signalled junctions (`roads.json` `junctions`, a box within `SIG_BOX` 30); QA counts signalled arms only and an outgoing zebra half before a median starts |
| stopline_wrong_side | 14 | 3 | one stop line piece per approach (no stub past a median nose); the 3 left are `short`: cut back at a deck edge (Kabar Aye Pagoda Road #4, Pyay Road #14, Pyay Road #12 ~2) |
| dash_jog | 76 | 20 | QA took dash ends from the minimum rectangle (a sagitta off on curved dashes): now from each flat cap. Most left: Baho Road #3, Than Thu Mar Road, Bo Min Gaung Street lane-count changes |
| dash_side_by_side | 4 | 1 | the Kabar Aye ones were a centre-line fold (below). Left: Road Flyover #2 deck lanes |
| paint_snake | 91 | 22 | kerb / median lines from a smoothed kerb (`steady`: 9-sample mean, rate-limited, kept 0.5-1.6 in from the real kerb); no paint at fold-backs |
| edge_missing | 291 | 193 | stacked roads (> 6 studs apart in height: `STACK`) are no mouth and no box; a smaller road wipes kerb lines only round the overlap itself (+4), not along its whole carriageway; kerb lines run on from the box to the zebra. Left (r6): 107 next to another road's carriageway (mouths, flares), 30 under a deck, 17 within 15 of a zebra / stop line, 39 other |
| zebra_torn | 2 | 0 | a zebra is whole or none: an arm left with under 3 bars or under half its bars gets none (Studio test "stray bars"); lines stop 0.6 short of a zebra / stop line |
| paint_in_median, double_box, box_paint, zebra_colour | 0 | 0 | |

Also new: a line that crosses itself loses its loops before buffering (a loop buffered to a ring and the paint list painted the hole solid yellow), and any "line" polygon fatter than 1.6x its width is dropped.

## Photo check (Playbook `2026-11-13 Research - Yangon road look.md`, J17 section)
- Two solid white lines along a painted median: KEEP (Hledan 2021 double solid centre; Bogyoke Road 2021 painted strip with a line each side).
- Stop lines + arrows on every main approach: CHANGED to signalled junctions only. Photos 2018-2021 show them at signals (Sule Pagoda Road); unsignalled corners have only the yellow zebra. 140 of 302 boxes are signalled; approaches with stop line + arrows 912 -> 494.

## Singapore Kyaung Street at the Pazundaung Y (OSM API 0.6, 17 Nov)
Way 547765387 (`highway=service`) has no crossing tag on any of its nodes. The only crossing nearby is node 2212217914 (`crossing=traffic_signals`, 13 m west), the Bogyoke Aung San Road / Upper and Lower Pazundaung Road junction, which already gets its zebras. So the street stays unmarked (residential streets get no zebra).

## Geometry faults found by paint (for the GEOMETRY agent)
Centre lines that step back on themselves: 71 samples on 52 roads (`roads05_paint.folds`), e.g. Kabar Aye Pagoda Road 1201-1204 and 1326-1327, Hanthawaddy Road 39-42, Hledan Road #3 231-232 / 319-320, Min Nandar Road #2 125-126 / 160-161, Pyay Road #2 1101-1102, Pyay Road #6 366-367, Strand Road 1360-1363, Parami Road 3065-3067, Old Yay Ta Shay Street #2 24-25, Bo Min Gaung Street 360-363. Paint leaves the road's width + 6 round each one empty, so those stretches are bare until the data is fixed.

## Previews (vault `City Legends/2026-11-18 roads05 J17 paint - *.png`)
Pazundaung Y; Crossroads Waizayandar (signalled: stop lines + arrows); Pyay Road x Ma Kyee Kyee Street (no signals: zebras only); Kabar Aye Pagoda Road fold (Bahan: no paint at the data fault).

## Left
- edge_missing 193 (above), dash_jog 20, paint_snake 22: lane-count changes and kerb notches in the data; the fold-backs.
- arrow_missing 6: lanes that end at the stop line (a taper: the QA sees one dash fewer than the arrows). stopline_missing 1: Pyay Road #13 (29131, 35461), an arm squeezed between a deck and the box, no room behind its zebra.
- Not done: a Studio look at the J17 paint; the geometry network moves on (a J16 fix was running at 14:01), so rerun paint + QA on the newest `roads.json`.
