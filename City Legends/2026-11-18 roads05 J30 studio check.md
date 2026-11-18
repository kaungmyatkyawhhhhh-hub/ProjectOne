# roads05 J30 studio check (18 Nov 2026, BUILDER agent)

Main Studio "City Legends". Pack = asset 133014134133489 revision 201 (J29 data + paint, unchanged); the builder went in by text patch, so `ClaudeTools.YangonRoads` = repo (checksum 2122460250), `ClaudeTools.Roads` = repo (1407280218, unchanged). All 17 spots built with the no-terrain copy of YangonRoads (fresh copy + `Y.load()` before the run) and checked with the QA agent's `T.qa`, in this fixed order: bahan_ring, deck_run, double_junction, downtown_straight, hanthawaddy, hledan_flyover, kunchan_gyophyu, lane_taper, long_median, pazundaung_y, pyay_univ, roundabout4, slip_triangle, sule_north, sule_shangrila, univ_kabaraye, ycentral. Scratch removed, saved as version 1304, terrain never written.

## What changed (YangonRoads.luau only; no data change)
1. **Pavement slots between two roads (pave_gap).**
   - Where a smaller road's pavement must stop at a bigger road (or at the road that owns a corner), the stop line was drawn from the other road's centre line plus a nominal width and its WIDER side's walk. The other road's real pavement edge is its built pieces, so a 0.3 to 0.5 stud slot ran between the two pavements (e.g. Lane #3186 beside Sule Pagoda Road at Roundabout 4, 30 studs long).
   - Now the stop line is the other road's BUILT surface: the same edge points and walk Roads.build lays (`onBuilt`). Near the other road's ends and its cut stretches (flyover corridors, ring) the old test stays: there the built edge is someone else's.
2. **Corner zone inner edge.** A round corner claimed everything out to 0.3 inside its own pavement's inner edge, so another road's pavement stopped 0.3 short of the corner's pavement. The zone now ends exactly on the corner pavement's inner edge (the same chords the corner is built from).
3. **Builder state leak (QA finding).** bahan_ring built after long_median and after ycentral differed in 199 parts (Lane #3789). Reloading one thing at a time showed the state lives in the road module copy (Roads.luau) the tool holds: a fresh copy alone made both orders equal. Each test cell / bake cell now takes a fresh copy, and no ring state is carried in. Proof: roundabout4 built inside the full run and again on its own after ycentral gave the same part hash (290473333).
4. **Ring mouths** now always use their own ring's outline (they used whichever ring the code had looked at last).
5. **Studio limit:** a script's Source cannot be set over 200,000 characters and YangonRoads was at 199,8xx. The old built-surface check `qaBuilt` (replaced by the runner's `T.qa`) was removed: 192,796 now.

## Totals, same check (T.qa)
| | box_hole | kerb_gap | road_step | pave_step | buried | pave_gap |
|---|---|---|---|---|---|---|
| J29 | 20 | 256 | 36 | 76 | 10 | 231 |
| **J30** | **20** | **253** | **37** | **76** | **11** | **188** |

## Per spot (box_hole / kerb_gap / road_step / pave_step / buried / pave_gap)
| spot | J29 | J30 |
|---|---|---|
| bahan_ring | 1 / 40 / 0 / 6 / 0 / 18 | 1 / 37 / 0 / 6 / 0 / 18 |
| deck_run | 1 / 10 / 2 / 12 / 0 / 28 | 1 / 10 / 2 / 11 / 0 / 22 |
| double_junction | 3 / 35 / 1 / 0 / 5 / 32 | 3 / 35 / 1 / 0 / 5 / 21 |
| downtown_straight | 0 / 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 / 0 |
| hanthawaddy | 3 / 6 / 0 / 0 / 0 / 7 | 3 / 6 / 0 / 0 / 0 / 7 |
| hledan_flyover | 3 / 4 / 0 / 1 / 0 / 8 | 3 / 4 / 0 / 1 / 0 / 8 |
| kunchan_gyophyu | 0 / 25 / 2 / 16 / 0 / 22 | 0 / 25 / 3 / 16 / 1 / 20 |
| lane_taper | 0 / 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 / 0 |
| long_median | 0 / 0 / 0 / 0 / 0 / 15 | 0 / 0 / 0 / 0 / 0 / 15 |
| pazundaung_y | 2 / 15 / 0 / 0 / 0 / 11 | 2 / 15 / 0 / 0 / 0 / 12 |
| pyay_univ | 2 / 18 / 9 / 13 / 2 / 9 | 2 / 18 / 9 / 13 / 2 / 9 |
| roundabout4 | 0 / 40 / 1 / 8 / 0 / 49 | 0 / 40 / 1 / 8 / 0 / 27 |
| slip_triangle | 0 / 25 / 3 / 11 / 3 / 7 | 0 / 25 / 3 / 11 / 3 / 6 |
| sule_north | 0 / 0 / 0 / 0 / 0 / 4 | 0 / 0 / 0 / 0 / 0 / 4 |
| sule_shangrila | 1 / 2 / 2 / 0 / 0 / 8 | 1 / 2 / 2 / 0 / 0 / 6 |
| univ_kabaraye | 4 / 36 / 16 / 7 / 0 / 8 | 4 / 36 / 16 / 8 / 0 / 8 |
| ycentral | 0 / 0 / 0 / 2 / 0 / 5 | 0 / 0 / 0 / 2 / 0 / 5 |
| **total** | **20 / 256 / 36 / 76 / 10 / 231** | **20 / 253 / 37 / 76 / 11 / 188** |

The J29 column was measured in a different order, before the state leak was fixed, so a spot can move by a few cells for that reason alone. Worse at one spot: kunchan_gyophyu road_step 2 -> 3 and buried 0 -> 1, both at the Lane #3414 / Kun Chan Road #3 nose (36355, 42408), a spot that was already faulty in J28 (pave_step + kerb_gap there). univ_kabaraye pave_step 7 -> 8: not traced.

The owner's target is 0 on every count at all 17 spots. Not there yet.

## Shot
- `2026-11-18 roads05 J30 test - roundabout4 - Lane 3186 x Sule pavement slot closed.jpg`: the corner where Lane #3186's and Sule Pagoda Road's pavements meet, now one surface (it had a 0.5 slot over 30 studs).

## Open (next pass)
- **pave_gap 188:** most of what is left is not a slot between two roads: it is the narrow end of a piece of open ground between two pavements (e.g. the city block inside Lane #3357 / 32nd Street / Roundabout 4, where the walks converge), plus island outlines. Closing those needs a rule for "ground narrower than X between two pavements gets paved", which is a design decision for the QA rule and the builder together.
- **kerb_gap 253:** not reached this pass. One clear case seen: Lane #3357's south kerb at Roundabout 4 (35812-35830, 45048-45063) is missing beside its corner onto the ring (road next to open ground).
- **Buried 11 and the Bridge start (items 3-4):** not reached. Found: East Horse Race Course Road (Bridge) starts under the Banyar Dala (bridge) Flyover, where Bo Min Gaung Street's ground samples 601-699 are cut; its old host is gone, so the fix's mouth run-on never sees it. It has to be joined to the ground lanes under the deck (Banyar Dala Road #2 / #3) or to Road #18, in `roads05_fix.py`.
- **Hledan Road #3 under Insein / Pyay (item 5):** not reached.
