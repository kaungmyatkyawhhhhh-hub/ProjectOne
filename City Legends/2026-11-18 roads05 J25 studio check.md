# roads05 J25 studio check (18 Nov 2026, GEOMETRY agent)

Owner refs: `Owner ref - median road dead end, missing lanes (owner paint 1).png` and `(owner paint 2).png`.

## The owner's spot: Sule Pagoda Road north arm at Bogyoke Aung San Road
- The picture is a crop of the J24 `sule_shangrila` test shot. The "dead end" was the edge of the Studio TEST box: the arm's full-width flyover ramp starts 13 studs inside the box edge, so the test built nothing past it.
- In the data (and OSM) the road goes on: both carriageways climb the Sule Pagoda Road flyover (93 studs wide), which curves north-west onto Alan Pya Pagoda Road. That curve is the owner's red line.
- New test spot `sule_north` (half box 300) covers the arm, the ramp and the curve: it is built with no dead end and with lane lines. All its built checks are 0.
- QA rules added: `dual_dead_end` (geometry) = **0**. `lanes_unmarked` (paint) went from 30 to **3**: streets with 2+ lanes in a direction now get lane lines. The 3 left are short route stretches (Strand Road 56 studs, Min Nandar Road #2 31, Shwe Gone Dine Road #2 32), not traced yet.
- Driver cameras at bahan_ring, hanthawaddy and roundabout4 are now on the road, not in the island mound.

## Per spot, J24 -> J25 (box_hole / kerb_gap / road_step / pave_step / buried)
Builder unchanged (YangonRoads checksum 1649648240), data J23. Version saved: 1241. Terrain never written. Scratch removed.

| spot | J24 | J25 |
|---|---|---|
| bahan_ring | 5 / 63 / 8 / 7 / 0 | 5 / 63 / 8 / 7 / 0 |
| deck_run | 1 / 11 / 2 / 23 / 0 | 1 / 11 / 2 / 23 / 0 |
| double_junction | 12 / 93 / 1 / 30 / 2 | 12 / 93 / 1 / 30 / 2 |
| downtown_straight | 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 |
| hanthawaddy | 5 / 11 / 0 / 0 / 0 | 5 / 11 / 0 / 0 / 0 |
| hledan_flyover | 4 / 5 / 7 / 1 / 0 | 4 / 5 / 7 / 1 / 0 |
| kunchan_gyophyu | 6 / 69 / 1 / 15 / 0 | 6 / 69 / 1 / 15 / 0 |
| lane_taper | 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 |
| long_median | 2 / 2 / 0 / 0 / 0 | 2 / 2 / 0 / 0 / 0 |
| pazundaung_y | 2 / 16 / 0 / 0 / 0 | 2 / 16 / 0 / 0 / 0 |
| pyay_univ | 8 / 30 / 37 / 23 / 2 | 8 / 30 / 37 / 23 / 2 |
| roundabout4 | 6 / 51 / 1 / 19 / 0 | 6 / 51 / 1 / 19 / 0 |
| slip_triangle | 3 / 40 / 32 / 19 / 1 | 3 / 40 / 32 / 19 / 1 |
| sule_north (new) | - | 0 / 0 / 0 / 0 / 0 |
| sule_shangrila | 5 / 8 / 4 / 1 / 0 | 5 / 8 / 4 / 1 / 0 |
| univ_kabaraye | 7 / 47 / 14 / 3 / 0 | 7 / 47 / 14 / 3 / 0 |
| ycentral | 0 / 0 / 0 / 2 / 0 | 0 / 0 / 0 / 2 / 0 |
| **total** | **66 / 446 / 107 / 143 / 5** | **66 / 446 / 107 / 143 / 5** |

## Shots
Shots taken this pass (the other spots' builds did not change; their J24 shots still show them):
- `2026-11-18 roads05 J25 test - sule_north - overview.jpg`
- `2026-11-18 roads05 J25 test - sule_north - driver.jpg`
- `2026-11-18 roads05 J25 test - bahan_ring - driver.jpg`
- `2026-11-18 roads05 J25 test - hanthawaddy - driver.jpg`
- `2026-11-18 roads05 J25 test - roundabout4 - driver.jpg`

## Not done (context ran low)
These J24 items are still open:
- corner pavement height rule (deck_run pave_step 23)
- rounded kerb noses at the 6 dropped corners
- deck-foot road_step (pyay_univ 37, slip_triangle 32)
- double-junction box holes
- Kun Chan seam and the strip at (36150, 42666)
- Bahan hole strip
- overview / driver shots of the 12 unchanged spots
