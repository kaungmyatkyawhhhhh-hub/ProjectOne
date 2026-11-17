# roads05 paint handover (J15 / J16, 18 Nov 2026, PAINT agent)

These are the paint rules and their QA. The geometry handover is `roads05_HANDOVER.md`. Only the paint files were changed: `tools/yangon/city/roads05_paint.py`, `roads05_paint_qa.py` and one line in `roads05_view.py` (it can now draw `LZ` zebras).

## How to run
- `YANGON_SCALE=1to1 python roads05_paint.py <tag>` (about 4 minutes on P1-P12) writes `paint.json`. Then run `roads05_paint_qa.py <tag>` (about 2 minutes), which writes `qa_paint_J15.json` and prints the counts.
- The pipeline (`roads05_pipeline.sh`) runs the paint script but not the paint QA. Run the QA by hand after it.
- These runs used a private copy of the network, `build/city_1to1/roads05_J15P/` (`roads.json` from 13:43). That kept them separate from the geometry agent's runs.

## Rules (QA name: J14 paint -> final)
| rule | before | after | how |
|---|---|---|---|
| arrow_missing | 1100 | 52 | arrows at every approach for the turns the box allows (a T takes them from the through road); OSM turn:lanes used where the lane count fits; an arrow moves back 6 or 12 studs if a zebra is in the way |
| stopline_missing | 637 | 29 | a stop line on every approach (it used to be signals only) |
| stopline_wrong_side | 65 | 14 | crosses only the incoming lanes, measured at the stop line's own sample; moves back up to 6 studs if another arm's zebra is there; never inside a box; cut back at a deck edge |
| dash_jog | 1283 | 76 | lane count is the median over 9 samples; offsets averaged over 9 samples, rate-limited to 0.08 per stud and clamped to the asphalt; Chaikin smoothing; the QA counts a step of 1.5 studs or more |
| dash_side_by_side | 32 | 4 | a line closer than 4 studs to the line inside it is dropped |
| paint_in_median | 1245 | 0 | nose caps (1.5 back and 1.0 past each median end) and islands are no-paint areas in `tidy` |
| double_box | 225 | 0 | two parallel roads under 40 studs apart crossing one road form ONE box, and so do any two junctions under 60 apart on one road. The stretch of each road from the box out to its zebra is box too. |
| box_paint | 149 | 0 | the same, plus ring lanes are clipped by boxes |
| paint_snake | 439 | 91 | Chaikin smoothing on every line; the rows that are left are mostly edge or median lines following wavy kerbs (geometry `width_wobble`) |
| edge_missing (yellow kerb line) | 5323 | 291 | yellow lines along every outer and median kerb of main roads, 0.9 in from the kerb; a smaller road lying inside a road is no mouth; no lines of one road on a bigger road |
| zebra_colour | 0 | 0 | LZ (230, 190, 110) kept |
| zebra_torn | 347 | 2 | whole bars only: a bar the kerb would cut, or one that lies in a box, on a median nose, under a deck or on another arm's zebra, is dropped. `tidy` closes the seams between roads before clipping, and deck paint is no longer cut by ground paint |

## J16 Studio test fixes (commit 5a3877d0)
- Pazundaung Y: a main road that ends at a box (a continuation whose centre line never enters the box) now gets its arm, with zebra, stop line and arrows. Singapore Kyaung Street, the east approach, is a `street`. Streets get no zebras or stop lines (rule: residential streets are unmarked). Whether that street should be marked is a data or owner question.
- Pyay x University: no zebra bar under a deck's footprint (+1 stud), because the ground under it can be an open gap. Stop lines are cut back to the deck edge, or dropped if under half of the line is left.

## Previews (vault `City Legends/2026-11-18 roads05 J15 paint - *.png`)
Crossroads Waizayandar, Pazundaung Y, Pyay Road x University Avenue, Double junction Maha Bandula x Lan Thit. In the newest network the last one is a T plus a through road, not a double junction. For the double-junction rule, see the QA rows (double_box 0) and the Strand Road / Pyay Road #14 areas.

## Left
- edge_missing 291: mostly kerbs next to another road's carriageway with a gap under 4 studs (paint breaks for the mouth buffer), or roads under decks.
- paint_snake 91: kerb wobble in the geometry.
- arrow_missing 52 / stopline_missing 29: messy flyover junctions (Pyay Road #14, Hledan), where arms are short and zebras crowd.
- The `stopline_wrong_side` rows marked "short" are stop lines cut back at deck edges.
- Not done: a Studio look at the newest paint (the geometry agent's job); paint on flush medians is two solid white lines (new J15, not checked against photos).
