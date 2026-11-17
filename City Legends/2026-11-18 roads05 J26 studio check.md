# roads05 J26 studio check (18 Nov 2026, GEOMETRY agent)

Builder fixes only (data = J23, paint = J25, both unchanged). Main Studio "City Legends", test copy of YangonRoads with terrain writes switched off, every spot built and checked with `qaBuilt`. `ServerStorage.ClaudeTools.YangonRoads` / `Roads` now hold the J26 repo files (checksums 1585396069 / 1519410308). Scratch removed, saved as version 1249.

## What changed in the builder
1. **Corner pavement height rule** (`YangonRoads.buildCorners` + new `Roads` option `paveY`): every corner pavement point away from the kerb (the arc pavement's inner edge and the corner "chip") now takes the height of the two roads' straight pavements where it lies. Before, it used the height at the corner's two ends, so a chip about 30 studs long sat 0.25 to 0.3 below Yawmingyi Street's pavement. A smaller road's pavement piece, where another road's zone cuts it, takes the bigger road's pavement height along that cut. **pave_step 143 -> 110** (deck_run 23 -> 13, double_junction 30 -> 23, pyay_univ 23 -> 15, roundabout4 19 -> 11).
2. **Gore kerb past a corner** (`sideZone`): past a round corner, the corner's road "owns" the strip and wiped the smaller road's kerb, even where the smaller road runs beside that road's pavement (Lane #3414 next to Kun Chan Road #3). Now the smaller road keeps its kerb wherever the owner's carriageway and kerb are not, and the bigger road's pavement stops at that kerb, so nothing overlaps.
3. **Gyophyu ramp-foot strip** (`crossMouths`): Gyophyu Road's crossing arm ran on through its 32 cut deck samples. Its mouth laid a 100-stud asphalt sliver along the flyover's ramp wall, with no kerb. The arm now stops at the first cut sample, which is the deck's foot.
- Together, 2 and 3 took **kerb_gap from 446 to 394** (kunchan_gyophyu 69 -> 46, bahan_ring 63 -> 54, double_junction 93 -> 86, roundabout4 51 -> 47, slip_triangle 40 -> 37).

## Per spot, J25 -> J26 (box_hole / kerb_gap / road_step / pave_step / buried)

| spot | J25 | J26 |
|---|---|---|
| bahan_ring | 5 / 63 / 8 / 7 / 0 | 6 / 54 / 9 / 7 / 0 |
| deck_run | 1 / 11 / 2 / 23 / 0 | 1 / 10 / 2 / 13 / 0 |
| double_junction | 12 / 93 / 1 / 30 / 2 | 12 / 86 / 1 / 23 / 2 |
| downtown_straight | 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 |
| hanthawaddy | 5 / 11 / 0 / 0 / 0 | 5 / 11 / 0 / 0 / 0 |
| hledan_flyover | 4 / 5 / 7 / 1 / 0 | 4 / 5 / 7 / 1 / 0 |
| kunchan_gyophyu | 6 / 69 / 1 / 15 / 0 | 6 / 46 / 1 / 15 / 0 |
| lane_taper | 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 |
| long_median | 2 / 2 / 0 / 0 / 0 | 2 / 2 / 0 / 0 / 0 |
| pazundaung_y | 2 / 16 / 0 / 0 / 0 | 2 / 15 / 0 / 0 / 0 |
| pyay_univ | 8 / 30 / 37 / 23 / 2 | 8 / 28 / 37 / 15 / 2 |
| roundabout4 | 6 / 51 / 1 / 19 / 0 | 6 / 47 / 1 / 11 / 0 |
| slip_triangle | 3 / 40 / 32 / 19 / 1 | 3 / 37 / 31 / 19 / 1 |
| sule_north | 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 |
| sule_shangrila | 5 / 8 / 4 / 1 / 0 | 5 / 8 / 4 / 1 / 0 |
| univ_kabaraye | 7 / 47 / 14 / 3 / 0 | 7 / 45 / 14 / 3 / 0 |
| ycentral | 0 / 0 / 0 / 2 / 0 | 0 / 0 / 0 / 2 / 0 |
| **total** | **66 / 446 / 107 / 143 / 5** | **67 / 394 / 107 / 110 / 5** |

bahan_ring got 1 more box_hole and 1 more road_step, both not traced yet.

## Shots (only spots whose build changed and that show the fix)
- `2026-11-18 roads05 J26 test - kunchan_gyophyu - overview.jpg`: no kerbless sliver along the Gyophyu ramp.
- `2026-11-18 roads05 J26 test - kunchan_gyophyu - driver.jpg`
- `2026-11-18 roads05 J26 test - deck_run - corner.jpg`: Lane #4610 / Yawmingyi Street corner; the test is lifted 400 studs, so it floats.

## Not fixed (findings)
- **Deck-foot road_step** (pyay_univ 37, slip_triangle 31): the pyay_univ cluster is Lane #118's mouth on Hledan Road #3.
  - The mouth outline's points on Hledan's edge jump 51.83 -> 52.55 within 3 studs. They take Hledan's kept edge heights, so the cause is Hledan Road #3's edge heights at the deck foot, not the mouth fill.
- **Rounded kerb noses:** not built. The worst corner-drop cluster (the Lane #3414 / Kun Chan Road #3 gore) is now kerbed by fix 2. The other dropped corners still leave kerb_gap: double_junction 86 and Kun Chan (36192, 42592) / (36178, 42612).
  - Those last two are the Gyophyu ramp foot: the ground mouth ends 1.5 studs short of the ramp wall, and the west kerb is missing along the noSlab samples.
- **Double junction box holes** (12 single cells), **Bahan Kan Yeiktha hole strip**: not worked on this pass.
- **lanes_unmarked 3** (paint): the three stretches are traced, not changed.
  - Strand Road (56 studs) sits inside a zebra's no-paint zone.
  - Min Nandar Road #2 (31) and Shwe Gone Dine Road #2 (32) are mouth breaks: Lane #2708 and Old Yay Ta Shay Street #2 join at a shallow angle across the carriageway.
  - Each is only just over the rule's 30 studs.
