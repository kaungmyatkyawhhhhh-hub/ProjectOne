# roads05 J31 studio check (18 Nov 2026, BUILDER agent)

Main Studio "City Legends". The runner was re-packed first (asset 133014134133489 revision 202: J29 data + paint, J30 builder, QA's runner with the J30 open-ground pave_gap rule). The builder change went in by text patch: `ClaudeTools.YangonRoads` = repo (checksum 1234869083, 193,294 characters), `ClaudeTools.Roads` unchanged (1407280218). All 17 spots built with the no-terrain copy (fresh copy + `Y.load()`), checked with QA's `T.qa`, fixed order. Terrain never written; scratch removed after, saved as version 1319, lock released.

## What changed (YangonRoads.luau, `sideZone`)
- Where a smaller road's kerb lies in a bigger road's kerb band, it used to be dropped always. Now it stays where the bigger road's own kerb is not built there (because the smaller road's carriageway cut it). Aim: two links that merge (Lane #7108 into Lane #5482 at double_junction).
- Result: pyay_univ 1 box hole and 1 kerb gap fewer; univ_kabaraye 1 kerb gap and 1 pavement step more at its known three-pavement island (34396, 28831). No change at double_junction.
- Tried and reverted: the same rule for a corner owner's kerb band (no change where it was aimed).

## Totals (T.qa: box_hole / kerb_gap / road_step / pave_step / buried / pave_gap)
| | totals |
|---|---|
| J30 builder on the old runner | 20 / 253 / 37 / 76 / 11 / 188 |
| J31 start (re-packed runner, before changes) | 20 / 253 / 37 / 76 / 11 / 105 |
| **J31** | **19 / 253 / 37 / 77 / 11 / 105** |

## Per spot (J31 start -> J31)
| spot | before | after |
|---|---|---|
| bahan_ring | 1 / 37 / 0 / 6 / 0 / 9 | same |
| deck_run | 1 / 10 / 2 / 11 / 0 / 9 | same |
| double_junction | 3 / 35 / 1 / 0 / 5 / 18 | same |
| downtown_straight | 0 / 0 / 0 / 0 / 0 / 0 | same |
| hanthawaddy | 3 / 6 / 0 / 0 / 0 / 1 | same |
| hledan_flyover | 3 / 4 / 0 / 1 / 0 / 1 | same |
| kunchan_gyophyu | 0 / 25 / 3 / 16 / 1 / 12 | same |
| lane_taper | 0 / 0 / 0 / 0 / 0 / 0 | same |
| long_median | 0 / 0 / 0 / 0 / 0 / 3 | same |
| pazundaung_y | 2 / 15 / 0 / 0 / 0 / 5 | same |
| pyay_univ | 2 / 18 / 9 / 13 / 2 / 7 | **1 / 17** / 9 / 13 / 2 / 7 |
| roundabout4 | 0 / 40 / 1 / 8 / 0 / 21 | same |
| slip_triangle | 0 / 25 / 3 / 11 / 3 / 4 | same |
| sule_north | 0 / 0 / 0 / 0 / 0 / 2 | same |
| sule_shangrila | 1 / 2 / 2 / 0 / 0 / 6 | same |
| univ_kabaraye | 4 / 36 / 16 / 8 / 0 / 4 | 4 / **37** / 16 / **9** / 0 / 4 |
| ycentral | 0 / 0 / 0 / 2 / 0 / 3 | same |
| **total** | **20 / 253 / 37 / 76 / 11 / 105** | **19 / 253 / 37 / 77 / 11 / 105** |

The owner's target is 0 on every count at all 17 spots. Not there: this pass moved almost nothing.

## Finding (close-up at double_junction, the biggest "junction corner" group, 12 cells)
Lane #7108 and Lane #5482 merge into one end point. Past the kerb nose of the gore between them, pavement wedges of both roads run on a few studs over the other road's asphalt with no kerb. So these cells are a gore-nose problem (a pavement must end where its own kerb ends), not a missing corner kerb. Neither rule tried this pass reaches it.

## Not done (next pass, in order)
1. Gore-nose pavements past the kerb nose (double_junction above; look at slip_triangle's Lane #15 / #16 / #17 corners, radius about 2, in a close-up first).
2. Buried 11: the Bridge Flyover foot over East Horse Race Course Road #3's kerb, Lane #3308 x Banyar Dala #3, slip_triangle Lane #15, pyay_univ Lane #588 (a kerb under its own road), the Kun Chan Lane #3414 nose.
3. The Bridge start in `roads05_fix.py`: it sits between Banyar Dala Road #2 and #3 under the deck; the fix looks for one bigger road within 12 studs and finds none. Both the fix and the builder's mouth need one host, so the join (one side lane or Road #18) has to be chosen before coding.
4. pave_gap 105 (merge pavements under 2 studs apart): the data has one walk width per road side, so this has to be a builder fill.
5. Hledan #3 under Insein / Pyay: Roads.luau already lowers the inner points 0.06 in a junction; the pyay_univ road steps left are Hledan #3 / Pyay #9's joint (0.2) and Lane #588.
6. The kunchan and univ_kabaraye regressions: not traced.

No data change, so the pipeline was not re-run (roads.json 95dfb789 / paint.json 84b94130 = J29) and no new version line. No shots: no spot changed visibly.
