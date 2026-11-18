# roads05 J32 studio check (18 Nov 2026, BUILDER agent)

Main Studio "City Legends". Runner = asset 133014134133489 rev 202 (J29 data + paint, QA's T.qa with the J30 open-ground rule), with the repo builder put in before install. Baseline re-measured first: exactly J31 (19 / 253 / 37 / 77 / 11, pave_gap 105). Builder changed by text patch: `ClaudeTools.YangonRoads` = repo (checksum 1688280175, 194,095 characters, under the 200k limit), `ClaudeTools.Roads` unchanged (1407280218). All 17 spots built with the no-terrain copy (fresh copy + `Y.load()`), checked with `T.qa`, fixed order. Terrain never written; scratch removed, saved as version 1327, lock released.

## What I saw (close-up first, J31's lesson)
A ray map of the built double_junction gore (Lane #7108 and Lane #5482 merging onto Banyar Dala Road #2) plus the corners of the piece under each fault cell. The pavement on the other lane's asphalt was **not** the straight pavement (its zone there already said "drop"). It came from the two round corners where each lane meets Banyar Dala #2:
- **Corner taper:** a short corner arc keeps the wider walk (Banyar Dala's 7.5) and tapers the lane's own 3-4 stud walk back over 20 studs. That taper was laid with no zone, so in the narrow gore it ran over the other lane's kerb and asphalt.
- **Corner chip:** sharp corners (theta 32-33 degrees, radius 0.5-3) got the J17 "tip" pavement, which in a gore spills outward.

## What changed (YangonRoads.luau, buildCorners)
1. The taper is now cut wherever it lies on another road's carriageway or kerb (`onOther`, the same exact clip `Roads.build` uses).
2. No chip on a corner sharper than 60 degrees (a gore nose: the two pavements already overlap inside it, so there is no notch to fill).

Each was measured on its own and kept only because the totals dropped: the chip rule alone took slip_triangle kerb_gap 25 -> 15; the taper clip then took double_junction 35 -> 24 and slip_triangle 15 -> 10.

## Totals (T.qa: box_hole / kerb_gap / road_step / pave_step / buried / pave_gap)
| | totals |
|---|---|
| J31 (= J32 start) | 19 / 253 / 37 / 77 / 11 / 105 |
| **J32** | **19 / 214 / 37 / 77 / 11 / 105** |

## Per spot (J32 start -> J32)
| spot | before | after |
|---|---|---|
| bahan_ring | 1 / 37 / 0 / 6 / 0 / 9 | same |
| deck_run | 1 / 10 / 2 / 11 / 0 / 9 | 1 / **9** / 2 / 11 / 0 / 9 |
| double_junction | 3 / 35 / 1 / 0 / 5 / 18 | 3 / **24** / 1 / 0 / 5 / 18 |
| downtown_straight | 0 / 0 / 0 / 0 / 0 / 0 | same |
| hanthawaddy | 3 / 6 / 0 / 0 / 0 / 1 | same |
| hledan_flyover | 3 / 4 / 0 / 1 / 0 / 1 | same |
| kunchan_gyophyu | 0 / 25 / 3 / 16 / 1 / 12 | same |
| lane_taper | 0 / 0 / 0 / 0 / 0 / 0 | same |
| long_median | 0 / 0 / 0 / 0 / 0 / 3 | same |
| pazundaung_y | 2 / 15 / 0 / 0 / 0 / 5 | same |
| pyay_univ | 1 / 17 / 9 / 13 / 2 / 7 | 1 / **13** / 9 / 13 / 2 / 7 |
| roundabout4 | 0 / 40 / 1 / 8 / 0 / 21 | 0 / **38** / 1 / 8 / 0 / 21 |
| slip_triangle | 0 / 25 / 3 / 11 / 3 / 4 | 0 / **10** / 3 / 11 / 3 / 4 |
| sule_north | 0 / 0 / 0 / 0 / 0 / 2 | same |
| sule_shangrila | 1 / 2 / 2 / 0 / 0 / 6 | same |
| univ_kabaraye | 4 / 37 / 16 / 9 / 0 / 4 | 4 / **31** / 16 / 9 / 0 / 4 |
| ycentral | 0 / 0 / 0 / 2 / 0 / 3 | same |
| **total** | **19 / 253 / 37 / 77 / 11 / 105** | **19 / 214 / 37 / 77 / 11 / 105** |

Nothing went up anywhere. The owner's target is 0 on every count at all 17 spots: not there yet.

Shots: `2026-11-18 roads05 J32 - double_junction - gore nose kerbed (Lane 7108 x 5482).jpg` (the gore now ends in one kerbed nose), `2026-11-18 roads05 J32 - slip_triangle - Lane 17 gore after chip rule.jpg`.

## Seen but not fixed (close-ups this pass)
- **bahan_ring, Kan Yeiktha island (35407-35420, 38138-38153), 11 cells:** the island fill has a 2-4 stud spike running south into Kan Yeiktha Road's asphalt, and its road-side edges have no kerb. Island outline (data `islands`) or `buildIslands`' kerb test, not traced.
- **pazundaung_y (40981-40990, 43397-43412), 11 cells:** a gore between Bogyoke Aung San Road #2 ~2, Upper Pazundaung Road #3 and Lower Pazundaung Road with nothing built in it (road next to empty ground: no kerb, no pavement, no island).

## Not done (next pass, in order)
1. The two clusters above, then the other kerb_gap clusters by close-up (roundabout4 Lane #3357 / Maha Bandula #2, Lane #115; univ_kabaraye Lane #1256; deck_run U Wisara #5; kunchan Gyophyu Flyover / Kun Chan #4).
2. Buried 11, the Bridge start join to Road #18 (roads05_fix.py + the builder's road-end join), pave_gap 105 fill, pyay_univ road_step, the univ_kabaraye / kunchan regressions: not reached this pass.

No data change, so the pipeline was not re-run (roads.json / paint.json = J29) and there is no new version line.
