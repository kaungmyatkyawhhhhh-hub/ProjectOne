# roads05 J27 studio check (18 Nov 2026, GEOMETRY agent)

Builder fix in `tools/riviera/Roads.luau` (Yangon-only path; Monaco unchanged), plus a paint QA exception. Main Studio "City Legends", test re-packed with the J26 builder first (asset 133014134133489 = this pack now), test copy of YangonRoads with terrain writes switched off, every spot built and checked with `qaBuilt`. `ServerStorage.ClaudeTools.Roads` = the J27 repo file (checksum 915171076), YangonRoads unchanged (1585396069). Scratch removed, saved as version 1263.

## What changed
1. **Edge pins reach the whole width of the bigger road** (`Roads.luau` `otherNear` / `bigSurface`, only when `edgeSurface` is on, which only Yangon uses):
   - A smaller road's edge takes the bigger road's surface height where it lies on that road. The test used the bigger road's `half`, but many Yangon roads are much wider on one side at a junction (Hledan Road #3 is 44 studs on one side where Lane #118 joins, its half is 21). The lane's edge on Hledan's carriageway was never pinned, so the mouth sat 0.3 to 0.5 below Hledan.
   - Now the pin reaches 8 studs past that sample's own edge on the point's side.
   - When several bigger roads qualify, the pin takes the one the point lies deepest in, not the nearest centre line.
   - The search for the bigger road's sample now covers its full width. Before, Bahan Road (78 wide on one side at Roundabout 1) was outside the search, so the pin read sample 1's height and Lane #3790 sat 1.1 studs low.
2. **Paint QA `lanes_unmarked`:** no lane dash is needed where a zebra or another road's carriageway lies within reach. That covers the 3 stretches traced in J26 (the Strand Road zebra zone, and the shallow mouths on Min Nandar Road #2 and Shwe Gone Dine Road #2). The count went from 3 to 0; every other paint rule is unchanged.

## Per spot, J26 -> J27 (box_hole / kerb_gap / road_step / pave_step / buried)

| spot | J26 | J27 |
|---|---|---|
| bahan_ring | 6 / 54 / 9 / 7 / 0 | 6 / 54 / 0 / 7 / 0 |
| deck_run | 1 / 10 / 2 / 13 / 0 | 1 / 11 / 2 / 12 / 0 |
| double_junction | 12 / 86 / 1 / 23 / 2 | 12 / 86 / 1 / 23 / 2 |
| downtown_straight | 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 |
| hanthawaddy | 5 / 11 / 0 / 0 / 0 | 5 / 11 / 0 / 0 / 0 |
| hledan_flyover | 4 / 5 / 7 / 1 / 0 | 4 / 5 / 7 / 1 / 0 |
| kunchan_gyophyu | 6 / 46 / 1 / 15 / 0 | 7 / 47 / 1 / 15 / 0 |
| lane_taper | 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 |
| long_median | 2 / 2 / 0 / 0 / 0 | 2 / 2 / 0 / 0 / 0 |
| pazundaung_y | 2 / 15 / 0 / 0 / 0 | 2 / 15 / 0 / 0 / 0 |
| pyay_univ | 8 / 28 / 37 / 15 / 2 | 5 / 25 / 27 / 15 / 2 |
| roundabout4 | 6 / 47 / 1 / 11 / 0 | 5 / 47 / 1 / 11 / 0 |
| slip_triangle | 3 / 37 / 31 / 19 / 1 | 3 / 33 / 3 / 9 / 3 |
| sule_north | 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 |
| sule_shangrila | 5 / 8 / 4 / 1 / 0 | 3 / 5 / 2 / 1 / 0 |
| univ_kabaraye | 7 / 45 / 14 / 3 / 0 | 8 / 44 / 14 / 6 / 0 |
| ycentral | 0 / 0 / 0 / 2 / 0 | 0 / 0 / 0 / 2 / 0 |
| **total** | **67 / 394 / 107 / 110 / 5** | **63 / 385 / 58 / 102 / 7** |

The same build can differ by 1 to 3 on a spot from run to run (pyay_univ road_step was 35 or 37 with the J26 code). The +1 values at deck_run and kunchan_gyophyu are within that noise.
- slip_triangle buried went from 1 to 3. Lane #15's kerb at (43464, 29305) now sits at its raised asphalt height.
- univ_kabaraye pave_step went from 3 to 6. This is not traced yet.

## Shots (changed spots + flicker close-ups)
- `2026-11-18 roads05 J27 test - pyay_univ - lane118 mouth.jpg`: Lane #118 now meets Hledan Road #3 flush.
- `2026-11-18 roads05 J27 test - slip_triangle - lay daungkan crossing.jpg`: Lay Daungkan Road #2 across Waizayandar Road, with no step. Bottom left there is a slot in the pavement next to the kerb (not traced).
- `2026-11-18 roads05 J27 test - bahan_ring - lane3790 edge.jpg`: Lane #3790 beside Bahan Road is now level. On the left you can see the Bahan hole strip (an open slot between two pavement blocks), which is still to fix.
- `2026-11-18 roads05 J27 test - kunchan_gyophyu - gore kerb grazing.jpg`: the J26 gore kerb at a grazing angle shows no flicker.
- `2026-11-18 roads05 J27 test - deck_run - corner pavement grazing.jpg`: the J26 corner chip at a grazing angle.

## Flicker check (item 7)
A grid of rays (0.5 studs) found up-facing faces less than 0.05 studs apart on the same spot:
- **Kun Chan gore**, 30 x 30 studs round (36363, 42421): 3 cells of 3,523, two Kun Chan Road #3 kerb pieces (36351, 42414) and (36360, 42419), and one pavement pair (36378, 42421).
- **deck_run corner**, round (34549, 42636): 4 cells of 2,647, two Yawmingyi Street pavement pieces overlapping at (34535, 42645) and (34552, 42645).

Both are small overlaps between neighbouring pieces of one road. Neither shows flicker in the stills, but by the rule they must butt together. **Not fixed yet.**

## Not done this pass (findings for the next one)
- **pyay_univ road_step 27, cause found:** Insein Road starts on three bigger roads: Hledan Road #3 (48.2), Pyay (Prome) Road (48.4) and the Pyay Road #9 deck-foot ramp (48.6 to 49.2).
  - Its first cross-section is one straight line from 48.37 to 49.25, so it sits 0.25 above the middle road (16 cells along z 27852-27859).
  - Fix: build the end strip with points pinned to each road underneath, or make Insein Road's start a mouth.
- **Gyophyu ramp foot, west side:** traced, not changed.
  - On the ground, Gyophyu Road ends 2 to 4 studs short of the Gyophyu Road Flyover deck foot. There is a hole at (36180, 42610) and a 32.2 dip at (36174, 42620).
  - Between them the deck has a 37-38 stud high "Road" side face.
  - The pavement west of it meets asphalt with no kerb (around x 36172, z 42610-42620).
- Rounded kerb noses (double_junction kerb_gap 86), the double junction's 12 hole cells and the Bahan hole strip: not worked on.
- The Bahan J26 regression (+1 box_hole, +1 road_step) is gone: road_step is now 0. box_hole is still 6.
