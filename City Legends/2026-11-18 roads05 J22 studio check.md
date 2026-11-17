# roads05 J22 studio check (18 Nov 2026, GEOMETRY agent)

Built-surface check (`YangonRoads.qaBuilt`, 0.5-stud ray grid, 20 studs at the box edge skipped) on all 16 Studio test spots, main Studio "City Legends", test pack = asset 133014134133489 rebuilt from the J22 data (pipeline `J22_*.log`) + J22 builder. Terrain never written; scratch removed; place saved. qaBuilt now also casts a miss again 0.003 / 0.006 off (a ray exactly down two touching wedges' shared edge missed both: most of Roundabout 4's "box holes").

## Per spot, J21 -> J22 (box_hole / kerb_gap / road_step / pave_step / buried)

| spot | J21 | J22 |
|---|---|---|
| bahan_ring | 43 / 160 / 8 / 13 / 0 | 8 / 111 / 12 / 28 / 0 |
| deck_run | 12 / 55 / 1 / 28 / 0 | 0 / 14 / 0 / 0 / 0 |
| double_junction | 13 / 130 / 2 / 30 / 2 | 11 / 126 / 3 / 32 / 2 |
| downtown_straight | 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 |
| hanthawaddy | 25 / 35 / 3 / 3 / 2 | 5 / 11 / 0 / 5 / 2 |
| hledan_flyover | 10 / 30 / 7 / 17 / 1 | 5 / 23 / 12 / 34 / 1 |
| kunchan_gyophyu | 8 / 82 / 13 / 17 / 1 | 6 / 80 / 14 / 25 / 1 |
| lane_taper | 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 1 / 0 |
| long_median | 3 / 16 / 0 / 0 / 0 | 2 / 13 / 2 / 2 / 0 |
| pazundaung_y | 13 / 39 / 0 / 2 / 0 | 3 / 26 / 1 / 10 / 0 |
| pyay_univ | 9 / 36 / 35 / 33 / 2 | 8 / 35 / 37 / 45 / 2 |
| roundabout4 | 48 / 166 / 2 / 33 / 1 | 7 / 57 / 2 / 32 / 1 |
| slip_triangle | 7 / 46 / 35 / 22 / 1 | 4 / 41 / 32 / 45 / 2 |
| sule_shangrila | 22 / 35 / 11 / 4 / 0 | 5 / 13 / 4 / 6 / 0 |
| univ_kabaraye | 17 / 91 / 50 / 5 / 3 | 12 / 77 / 28 / 35 / 3 |
| ycentral | 4 / 16 / 1 / 4 / 2 | 1 / 12 / 1 / 13 / 2 |
| **total** | 234 / 937 / 168 / 211 / 15 | 77 / 639 / 148 / 308 / 14 |

## What changed (causes found)
- **Roundabout 4 kerb_gap:** Sule Pagoda Road is 64 / 33 (absorbed slip) and the band tests used the wider half on both sides: it "owned" Lane #3352's kerb band 30 studs off its narrow side (40 studs of kerb and pavement missing). New `YangonRoads.sideHalf` (the half on the spot's side) in ownedBy, findCorners, crossMouths, mouth tests, deck piers.
- **Island fills over kerbs:** fills triangulated from far corners stood up to 1 stud over the kerbs (Lane #7793 at Roundabout 4). Outlines now cut into 4-stud sides on the built edge height.
- **Lane #7793 walk 24.6 across 32nd Street** (downtown_walks to the building line straight over another road): another carriageway (and its walk) now limits a side.
- **mouth_level (data):** a road whose end lies on a bigger road takes its height (step faded 3%, 20-120 studs, skipped if over 2.5 off): 1,043 ends.

## Not fixed (seen this pass)
- pave_step went UP at the deck spots (univ_kabaraye 5 -> 35, hledan 17 -> 34, slip 22 -> 45, pyay 33 -> 45): probed ones on Hledan Road #3's pavement are mostly grazes on sloped wedges plus a few pieces 4.7 lower (deck-side pavement): not checked to the root. Python QA seam_step 0 -> 3 and pave_step 0 -> 3 (new: likely mouth_level).
- Deck-foot road_step: univ_kabaraye 50 -> 28; Lane #1256 / #1257 / #1248 mouths on Hledan Road #3 (flyover side lanes) still crease.
- bahan_ring: the island between Kan Yeiktha Road, Lane #8112 and Kan Yeiktha has no kerb on Kan Yeiktha Road's side, and "Islands on Kan Yeiktha Road 17" pieces are scrubbed (the data island overlaps the built carriageway).
- double_junction: water between the two N-S roads south of the box = the two corners still dropped (Lane #3308 on Upper Pazundaung Road #3 / Banyar Dala Road #3); Kun Chan's dropped corners: same cause (no rounded noses yet).

## Shots
Only 3 this pass (context): `2026-11-18 roads05 J22 test - roundabout4 - overview.jpg`, `... roundabout4 - driver.jpg` (the stored driver camera stands at the box edge), `... bahan_ring - overview.jpg`. The other 29 not taken.
