# roads05 J23 studio check (18 Nov 2026, GEOMETRY agent)

Built-surface check (`YangonRoads.qaBuilt`, 0.5-stud ray grid, 20 studs at the box edge skipped) on all 16 Studio test spots, main Studio "City Legends", J23 data (pipeline `J23_*.log`) + J23 builder. Terrain never written; scratch removed; place saved (version 1229); asset 133014134133489 = the J23 pack.

**QA changes this pass (they count in the table):**
- A cell where the rays only hit side faces is an edge, not a fault. J22's miss-retry took the 4.7-stud side face at a pavement's outer edge as "pavement 4.7 lower".
- An asphalt cell next to nothing at an OSM dead end is not a kerb_gap.

## Per spot, J22 -> J23 (box_hole / kerb_gap / road_step / pave_step / buried)

| spot | J22 | J23 |
|---|---|---|
| bahan_ring | 8 / 111 / 12 / 28 / 0 | 5 / 63 / 8 / 7 / 0 |
| deck_run | 0 / 14 / 0 / 0 / 0 | 1 / 11 / 2 / 23 / 0 |
| double_junction | 11 / 126 / 3 / 32 / 2 | 12 / 93 / 1 / 30 / 2 |
| downtown_straight | 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 |
| hanthawaddy | 5 / 11 / 0 / 5 / 2 | 5 / 11 / 0 / 0 / 0 |
| hledan_flyover | 5 / 23 / 12 / 34 / 1 | 4 / 5 / 7 / 1 / 0 |
| kunchan_gyophyu | 6 / 80 / 14 / 25 / 1 | 6 / 69 / 1 / 15 / 0 |
| lane_taper | 0 / 0 / 0 / 1 / 0 | 0 / 0 / 0 / 0 / 0 |
| long_median | 2 / 13 / 2 / 2 / 0 | 2 / 2 / 0 / 0 / 0 |
| pazundaung_y | 3 / 26 / 1 / 10 / 0 | 2 / 16 / 0 / 0 / 0 |
| pyay_univ | 8 / 35 / 37 / 45 / 2 | 8 / 30 / 37 / 23 / 2 |
| roundabout4 | 7 / 57 / 2 / 32 / 1 | 6 / 51 / 1 / 19 / 0 |
| slip_triangle | 4 / 41 / 32 / 45 / 2 | 3 / 40 / 32 / 19 / 1 |
| sule_shangrila | 5 / 13 / 4 / 6 / 0 | 5 / 8 / 4 / 1 / 0 |
| univ_kabaraye | 12 / 77 / 28 / 35 / 3 | 7 / 47 / 14 / 3 / 0 |
| ycentral | 1 / 12 / 1 / 13 / 2 | 0 / 0 / 0 / 2 / 0 |
| **total** | 77 / 639 / 148 / 308 / 14 | **66 / 446 / 107 / 143 / 5** |

Python QA (`J23_qa.log`):
- seam_step 3 -> 0, pave_step 3 -> 0.
- Unchanged: kerb_cross 0, mouthsim 0 failed of 11,569, deck_grade 7, mouth_short / mouth_over real 3 / 1.

## Causes found and fixed
- **Deck-spot pave_step (item 1):** this was the QA, not the builder. The J22 miss-retry accepted side-face hits; a cell that only finds side faces now counts as an edge.
  - univ_kabaraye pave_step 35 -> 3, hledan 34 -> 1, slip 45 -> 19, pyay 45 -> 23.
  - There are no real low pavement pieces.
- **Side lanes under a flyover lost their inner kerb:** the distance-to-road helper (`polyDist`) still counted a deck's cut ground samples as road. A cut sample is now no road, and neither is a lone uncut sample between two cuts.
  - Kabar Aye Pagoda Road #5 / #6 (univ_kabaraye).
  - Bo Min Gaung Street's lone 45-wide uncut sample took East Horse Race Course Road (Bridge)'s kerb in a 45-stud circle (double_junction).
- **Round caps:** `polyDist` gave every road end a round cap of its half, but roads are built square. Ends are now square, in the builder and in kerbsim. Kan Yeiktha Road's start had eaten the Kan Yeiktha island kerb (bahan).
- **T far kerb:** a T ending 0.1 past a road's centre took that road's far kerb and walk (Lane #4245 on Kabar Aye Pagoda Road #5). The clip line now sits 1 stud on the road's own side.
- **Island kerbs (item 5, bahan):** an island outline side with no band kerb next to it (a split's gore along a road's end line) now gets its own kerb, and the fill moves in off it.
  - The check is a ray just inside the outline, not a bounding box.
  - Islands are now computed after the last plan change.
- **Flyover side lanes onto Hledan Road #3 (item 2):** `mouth_level` changes.
  - It stays on one host per run.
  - Two runs on one record meet by a linear blend.
  - Runs that meet leave the climb 3 samples.
  - It skips continuation joints (seam_step / pave_step 3 -> 0).
  - Lane #1256 now climbs 5% instead of creasing.
  - univ_kabaraye road_step 28 -> 14.
- **End kerbs:** a road end that is not a mouth, not a continuation and not a dead end gets a kerb wherever nothing is built just past it (100 parts at the double junction).

## Not fixed / seen this pass
- **double_junction:** the water patch south of the box is still open (box_hole 12). East Horse Race Course Road (Bridge)'s ground start ends under the Bo Min Gaung bridge, with no slab between Upper Pazundaung Road #3's corner and Lane #3308. This needs data work (that road end under the deck).
- **Dropped corners (item 3):** no rounded noses yet. Six corners are still dropped, and the Kun Chan cluster stays at kerb_gap 69.
- **Kun Chan (item 6):** Gyophyu Road kerb_gap 30 at (36150, 42666) is a 3-stud asphalt strip beside the Gyophyu Road Flyover ramp foot, with no kerb (cut ground + mouth slab). The gore seam is a small dark mark on the zebra gap in the driver shot.
- **New: deck_run pave_step 0 -> 23.** These are 0.27-0.38 steps between two roads' wide downtown pavements at their corners: Lane #4610 x Yawmingyi (York) Street, and Lane #4611. The data heights did not change, so a builder change caused it. Not traced.
- **Deck-foot road_step:** pyay_univ 37 and slip_triangle 32 are unchanged.
- **Bahan, Kan Yeiktha split:**
  - Two island pieces have a hole strip between them, and Kan Yeiktha Road meets the island with no kerb at its START line (12).
  - Lane #3790 meets Bahan Road's pavement with no kerb (12).
- **Lane wider than its host:** Lane #1256 (21 wide) ends on Kabar Aye Pagoda Road #6 (12 wide), and its asphalt runs past the host's far edge.
- **slip_triangle:** in the driver shot, Lane #17's pavement sticks out past the small corner island's kerb.

## Shots (all 32, `2026-11-18 roads05 J23 test - <spot> - <overview|driver>.jpg`)
- The overview is straight down from the box centre.
- Driver cameras now stand inside the spot (`roads05_studiotest.py`: at most 0.55 of the half box from the centre, never in a roundabout island).
- At roundabout4, slip_triangle and bahan_ring the driver is a point on the road 75-220 studs from the centre, looking at it, because the stored point was not on the road surface.
