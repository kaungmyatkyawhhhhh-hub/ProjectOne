# roads05 J21 studio check (18 Nov 2026, GEOMETRY agent)

Built-surface check (`YangonRoads.qaBuilt`, 0.5-stud ray grid) on all 16 Studio test spots of the J16 list, main Studio "City Legends", test pack = asset 133014134133489 rev 175 (J21 data + J21 builder). Terrain never written; scratch removed; place saved (version 1208).

## What the numbers mean
- **box_hole** no surface with asphalt on 3+ sides; **kerb_gap** asphalt next to pavement / nothing with no kerb; **road_step** / **pave_step** neighbours more than 0.2 apart; **buried** kerb top under 0.3 over the asphalt.
- **J21 QA fixes (counting only what a player can meet):** (1) a ray hitting a WedgePart's vertical slanted face (normal not up) is cast again a hair off: the J20 "thin pavement wedges 0.29-0.41 lower" were such grazes, every wedge checked had a flat top at the right height; (2) the 20 studs at the test box edge are skipped (the cell is clipped there: roads end square); (3) a deck's open end next to nothing is skipped (the subset cuts decks in the air).

## Per spot (J21, box edge 20 skipped)

| spot | box_hole | kerb_gap | road_step | pave_step | buried |
|---|---|---|---|---|---|
| bahan_ring | 43 | 160 | 8 | 13 | 0 |
| deck_run | 12 | 55 | 1 | 28 | 0 |
| double_junction | 13 | 130 | 2 | 30 | 2 |
| downtown_straight | 0 | 0 | 0 | 0 | 0 |
| hanthawaddy | 25 | 35 | 3 | 3 | 2 |
| hledan_flyover | 10 | 30 | 7 | 17 | 1 |
| kunchan_gyophyu | 8 | 82 | 13 | 17 | 1 |
| lane_taper | 0 | 0 | 0 | 0 | 0 |
| long_median | 3 | 16 | 0 | 0 | 0 |
| pazundaung_y | 13 | 39 | 0 | 2 | 0 |
| pyay_univ | 9 | 36 | 35 | 33 | 2 |
| roundabout4 | 48 | 166 | 2 | 33 | 1 |
| slip_triangle | 7 | 46 | 35 | 22 | 1 |
| sule_shangrila | 22 | 35 | 11 | 4 | 0 |
| univ_kabaraye | 17 | 91 | 50 | 5 | 3 |
| ycentral | 4 | 16 | 1 | 4 | 2 |

Kun Chan x Gyophyu, same +-220 box, before the QA fixes -> after: road_step 50 -> 13, pave_step 64 -> 17 (grazes), kerb_gap 123 -> 82 (box edge). J20 (+-170 box): 8 / 54 / 28 / 48 / 4.

## Seen in the shots
- Kun Chan x Gyophyu: the floating arc and the island tip are gone, the box is one surface; a thin dark seam line still crosses the box (driver shot): a slab joint ("gore crack"), not fixed.
- Double junction: open holes in the box between the two triangle islands and at the north fork (blue water shows through): the box_hole count is real there.
- Yangon Central: clean; the deck's open end is the test subset's cut.
- Not driven toward 0 this pass: box_hole and kerb_gap at the roundabouts (bahan_ring, roundabout4) and the double junction; road_step at the deck feet (univ_kabaraye, pyay_univ, slip_triangle).

## Shots
Overview + driver taken for 5 spots (bahan_ring, deck_run, double_junction, kunchan_gyophyu, ycentral): `2026-11-18 roads05 J21 test - <spot> - <view>.jpg`. The other 11 spots: QA only (context).
