# roads05 J24 studio check (18 Nov 2026, GEOMETRY agent)

Built-surface check (`YangonRoads.qaBuilt`, 0.5-stud ray grid, 20 studs at the box edge skipped) on all 16 Studio test spots, main Studio "City Legends".
- Data: J23 (`e1410681`). Builder: J23. No change in this pass was kept (all tries made it worse and were reverted, see below).
- Terrain never written. Scratch removed. Place saved (version 1237). Asset 133014134133489 = the J23 pack again.

## Per spot, J23 -> J24 (box_hole / kerb_gap / road_step / pave_step / buried)

| spot | J23 | J24 |
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
| sule_shangrila | 5 / 8 / 4 / 1 / 0 | 5 / 8 / 4 / 1 / 0 |
| univ_kabaraye | 7 / 47 / 14 / 3 / 0 | 7 / 47 / 14 / 3 / 0 |
| ycentral | 0 / 0 / 0 / 2 / 0 | 0 / 0 / 0 / 2 / 0 |
| **total** | **66 / 446 / 107 / 143 / 5** | **66 / 446 / 107 / 143 / 5** |

The same code gives the same counts: the check repeats exactly.

## Item 1, deck_run pave_step 23: traced, not fixed

**Not a J23 builder regression.** Each J23 builder change was turned off in a Studio test copy (source patched, module re-required) and the spot rebuilt:
- square road ends off: 23
- T clip 1 stud off: 23
- data heights near the step: the same in J22 and J23

The step was always built. J23's QA change (a cell that only hits side faces is an edge) made it countable.

**What it is:**
- Lane #4610 (walk 30 on its right) meets Yawmingyi (York) Street (walk 18) in a corner with r 15.9.
- The radius is under the walk, so `buildCorners` lays a back-corner "chip". Here it reaches about 30 studs along Yawmingyi Street.
- The chip's heights run from yA to yB, the corner's two END heights.
- Yawmingyi Street climbs about 1% there, so the chip is 0.24-0.27 under Yawmingyi's straight pavement along Yawmingyi's back line, at z 42636, x 34542-34556.
- The chip also lies under Yawmingyi's pavement, lower, so it does not flicker.
- Found by wrapping `Roads.triangle` in the test copy and logging the traceback of triangles in the fault box: `buildCorners` chip loop.
- The other deck_run cells are separate cases, not traced: U Wisara Road #2 / U Wisara Ein Yar Street #2 at (34132, 42470-42479), Lane #3421 at (34244, 42458), Lane #4610 x Lane #4611 at (34603-34612, 42617-42624).

**Tried and reverted** (pave_step for deck_run each time):
- Raycast snap of cut pavement-piece vertices onto another road's built pavement (Roads.luau `opts.paveSnap`): 23. The chip is not made there.
- The same snap on corner arc, taper and chip vertices, reach 2: 32.
- Chip vertices taking the nearer road's built edge height: 26.
- Only the vertices nearer the bigger road taking its height: 23. The step moved inside the corner, between the chip and the arc pavement.

**Next:** one height rule for every pavement piece of a corner (straight bands near T, arc pavement, chip, taper), for example the height of the nearer road's straight pavement at that point, all set together in `buildCorners`.

## Not done this pass
- Items 2-7 of the J24 list: rounded kerb noses at the 6 dropped corners, deck-foot road_step, the double junction hole, the Kun Chan seam and ramp-foot strip, the Bahan hole strip, other kerb_gap patterns.
- Double junction box_hole 12: the holes are single cells scattered round the box, (39906-39940, 32838-32898) and (39972-39988, 32914-32944), not one patch. Probes 3 studs away hit Upper Pazundaung Road #3 / Lane #3308 slabs.

## Shots (all 32, `2026-11-18 roads05 J24 test - <spot> - <overview|driver>.jpg`)
- Overview: straight down from the box centre. With the place's city under it, the downtown spots show buildings round the roads.
- The driver cameras at bahan_ring, hanthawaddy and roundabout4 sit inside the roundabout's grass mound. The camera point is lower than the mound top, so those shots show grass. They need a camera on the ring road.
