# roads05 J37 studio check (18 Nov 2026, BUILDER agent)

Main Studio "City Legends". Test pack 133014134133489 as installed = repo (runner 542610530, YangonRoads 661359068 before this pass), J35 data (roads.json c34a1111, paint b6c2ba15, unchanged). New builder: `ClaudeTools.YangonRoads` 179,431 chars, checksum 1843759058; `YangonRoadsChecks` 27,754 chars, 1841289662 (both = repo). All 17 spots built with the no-terrain copy, alphabetical. Terrain never written. Scratch removed, saved as version 1384 (was 1377), lock released.

## Totals (T.qa: box_hole / kerb_gap / road_step / pave_step / buried / pave_gap)
| | totals |
|---|---|
| J36 | 16 / 161 / 36 / 77 / 0 / 95 |
| J37 first try (seal v1) | 16 / 87 / 36 / 77 / **3** / 94 |
| **J37 (seal v2, kept)** | **14 / 84 / 36 / 77 / 0 / 94** |

## Per spot
| spot | J36 | J37 |
|---|---|---|
| bahan_ring | 1 / 20 / 0 / 6 / 0 / 10 | 1 / 11 / 0 / 6 / 0 / 10 |
| deck_run | 1 / 10 / 2 / 11 / 0 / 9 | 1 / 6 / 2 / 11 / 0 / 9 |
| double_junction | 1 / 23 / 0 / 0 / 0 / 16 | 1 / 11 / 0 / 0 / 0 / 16 |
| downtown_straight | 0 | 0 |
| hanthawaddy | 3 / 6 / 0 / 0 / 0 / 1 | 2 / 5 / 0 / 0 / 0 / 1 |
| hledan_flyover | 3 / 4 / 0 / 1 / 0 / 1 | 3 / 2 / 0 / 1 / 0 / 1 |
| kunchan_gyophyu | 0 / 24 / 3 / 16 / 0 / 12 | 0 / 12 / 3 / 16 / 0 / 11 |
| lane_taper | 0 | 0 |
| long_median | 0 / 0 / 0 / 0 / 0 / 3 | same |
| pazundaung_y | 1 / 3 / 0 / 0 / 0 / 3 | 1 / 2 / 0 / 0 / 0 / 3 |
| pyay_univ | 1 / 12 / 9 / 13 / 0 / 7 | 1 / 6 / 9 / 13 / 0 / 7 |
| roundabout4 | 0 / 20 / 1 / 8 / 0 / 14 | 0 / 5 / 1 / 8 / 0 / 14 |
| slip_triangle | 0 / 10 / 3 / 11 / 0 / 4 | 0 / 4 / 3 / 11 / 0 / 4 |
| sule_north | 0 / 0 / 0 / 0 / 0 / 2 | same |
| sule_shangrila | 1 / 2 / 2 / 0 / 0 / 6 | 1 / 1 / 2 / 0 / 0 / 6 |
| univ_kabaraye | 4 / 27 / 16 / 9 / 0 / 4 | 3 / 19 / 16 / 9 / 0 / 4 |
| ycentral | 0 / 0 / 0 / 2 / 0 / 3 | same |

Nothing went up at any spot against J36.

## What changed: `YangonRoads.kerbSeal()` (new, last step of `stepCell` and `step5`, after `scrub`)
One closing pass over the built parts instead of one fix per builder (corners, noses, mouths, island outlines all leave the same visible fault):
1. **Kerb stops short / pavement reaches the asphalt** (audit pattern 1): the top triangle of every Pavement part (wedge or flat block) is read back; each edge is walked every 0.4 studs; where the top 0.2 outside is lower asphalt (Road or Paint, 0.15+ under the pavement), a kerb is laid along that run: out over the asphalt 0.9 (less where anything else starts first), red / white by world position.
2. **Pavement on the road side of its own kerb** (pattern 2): when an own kerb lies within 1.5 inside the run, the new kerb reaches back over the pavement to it, so the overhanging sliver is covered.
3. **Open slot** (pattern 3): nothing 0.2 outside an edge, then lower asphalt within 2: past a kerb, the kerb runs on to the asphalt; past a pavement, the pavement runs on and gets a kerb on its new edge.
4. **Height floor:** a new kerb's top is 0.1 over the pavement and never under CURB_UP + 0.1 over the asphalt it stands on (v1 without it made 3 buried cells at pyay_univ Lane #588 and univ_kabaraye).
5. Runs are collected first, then each is probed again just before it is laid, so new pieces never lie on each other (no coplanar tops).

Shot: `2026-11-18 roads05 J37 - double_junction - Lane 3308 strip kerbed by the seal, nose still messy.jpg`. The Lane #3308 strip (a 1-stud pavement strip between Lane #3308 and Banyar Dala Road #3 under the deck) is kerbed along both sides now, but its south nose is a jumble of small kerb pieces standing at different heights: the strip itself is the fault (two roads 1 stud apart), not a kerb rule.

## Left (by pattern)
- **kerb_gap 84:** road next to NOTHING (open road edge, e.g. Bahan Road (35388, 38010-38024): the asphalt ends with no kerb or pavement for 7+ studs); deck foot vs pavement (East Horse Race Course Road #3 x the Bridge Flyover, 0.13 apart: under the 0.15 seal threshold); deck wall base slots; Hanthawaddy ring cracks; tiny island road strips (Bahan Road (35386, 37828): kerb, 0.5 asphalt, pavement, kerb).
- **pave_step 77, road_step 36, pave_gap 94, box_hole 14, arrow_missing 10:** not reached this pass (order and ideas in the handover).
