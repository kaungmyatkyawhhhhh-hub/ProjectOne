# roads05 J29 studio check (18 Nov 2026, BUILDER agent)

Main Studio "City Legends". The test was re-packed first (J29 roads.json + paint.json + current builder), asset 133014134133489 revision 201. All 17 spots were built with the no-terrain copy of YangonRoads and checked with the QA agent's final check `T.qa` (deterministic, false positives removed; see `2026-11-18 roads05 fault census.md`). In Studio: `ClaudeTools.YangonRoads` = repo (checksum 2108652449), `ClaudeTools.Roads` = repo (1407280218, unchanged).

## What changed
1. **Decks in the test spots** (`YangonRoads.buildDecks`, new flag `M.DECK_TOUCH`, on in the test only).
   - A test spot built a flyover only when the deck's middle lay inside the spot. East Horse Race Course Road (Bridge) Flyover is 1,750 studs long, so at double_junction it was never built and the ground road at its foot met nothing: 45 "deck foot" kerb gaps that were the test's, not the builder's.
   - With the flag, every deck with a sample in the spot is built. The bake keeps one owner cell per deck (flag off).
2. **Side lanes at a flyover's foot** (`roads05.py`).
   - The side lanes were placed with their edge exactly on the deck's edge. Their own deck-side walk and kerb (1 stud) then lay under the deck slab (buried kerbs, pavement inside the deck).
   - Now the gore leaves room for that walk, as the middle of the deck already did.
3. **No road ends on a deck's foot** (`roads05_fix.py`, new step `deck_foot_ends`).
   - Lane #3309 (a link OSM draws merging 12 studs past the deck's start) ended on the deck's foot, its kerb under the deck slab.
   - A road end at grade inside a deck's footprint is now cut back along itself to the footprint's edge: 6 roads (Lane #3309, #5381, #4086, #6984, #7680, #452). mouthsim: 0 failed of 11,570.
4. **Island kerbs on every open stretch** (`YangonRoads.buildIslands`).
   - One ray at the middle of each 4-stud island side decided whether it had a kerb. A band kerb that covered only the middle left the nose bare (the census's "gore nose with no kerb").
   - Now every 0.5 along a side is tested and only the open runs get a kerb (no kerb laid on a kerb).

Tried and dropped (not in the build):
- Leaving out a smaller road's strips that lie under a bigger road (item 2, Hledan Road #3 under Insein / Pyay). The data reach test ran past the bigger road's end line and made holes: pyay_univ kerb_gap 21 -> 42.
- Not raising inner pins next to an unpinned edge (slip_triangle buried). Lane #15's edge there IS pinned; the buried cells are its kerb and pavement standing only 0.1 over the pinned edge. Still open.

## Totals, same check (T.qa final)
| | box_hole | kerb_gap | road_step | pave_step | buried | pave_gap |
|---|---|---|---|---|---|---|
| J28 (QA census run) | 26 | 308 | 36 | 99 | 7 | 233 |
| **J29** | **20** | **256** | **36** | **76** | **10** | **231** |

## Per spot, J29 (box_hole / kerb_gap / road_step / pave_step / buried, then pave_gap)
The J28 column is the J28 note's old `qaBuilt` (it counted more false positives, so it is only a guide per spot).

| spot | J28 (qaBuilt) | J29 (T.qa) |
|---|---|---|
| bahan_ring | 6 / 53 / 0 / 6 / 0 | 1 / 40 / 0 / 6 / 0 / 18 |
| deck_run | 1 / 10 / 2 / 12 / 0 | 1 / 10 / 2 / 12 / 0 / 28 |
| double_junction | 12 / 86 / 1 / 23 / 2 | 3 / 35 / 1 / 0 / 5 / 32 |
| downtown_straight | 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 / 0 |
| hanthawaddy | 5 / 11 / 0 / 0 / 0 | 3 / 6 / 0 / 0 / 0 / 7 |
| hledan_flyover | 4 / 5 / 7 / 1 / 0 | 3 / 4 / 0 / 1 / 0 / 8 |
| kunchan_gyophyu | 1 / 28 / 2 / 15 / 0 | 0 / 25 / 2 / 16 / 0 / 22 |
| lane_taper | 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 / 0 |
| long_median | 2 / 2 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 / 15 |
| pazundaung_y | 2 / 15 / 0 / 0 / 0 | 2 / 15 / 0 / 0 / 0 / 11 |
| pyay_univ | 5 / 25 / 8 / 15 / 2 | 2 / 18 / 9 / 13 / 2 / 9 |
| roundabout4 | 5 / 47 / 1 / 11 / 0 | 0 / 40 / 1 / 8 / 0 / 49 |
| slip_triangle | 3 / 33 / 3 / 9 / 3 | 0 / 25 / 3 / 11 / 3 / 7 |
| sule_north | 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 / 4 |
| sule_shangrila | 3 / 5 / 2 / 1 / 0 | 1 / 2 / 2 / 0 / 0 / 8 |
| univ_kabaraye | 8 / 44 / 14 / 6 / 0 | 4 / 36 / 16 / 7 / 0 / 8 |
| ycentral | 0 / 0 / 0 / 2 / 0 | 0 / 0 / 0 / 2 / 0 / 5 |
| **total** | **57 / 364 / 40 / 101 / 7** | **20 / 256 / 36 / 76 / 10 / 231** |

double_junction pave_step 23 -> 0: the Road #20 / Road #18 back-to-back pavements lie under the now-built Banyar Dala / East Horse Race Course decks (the step is still there under the decks; the top-down check cannot see it).

The owner's target is 0 on every count at all 17 spots. Not there yet.

## Shots
- `2026-11-18 roads05 J29 test - double_junction - deck foot.jpg`: East Horse Race Course Road (Bridge) Flyover now built at its foot, the side lanes beside it.

## Open (next pass, biggest first; patterns from the census)
- **buried 10:** double_junction Banyar Dala Road #3 x Lane #3308 (39984, 32907) 5; slip_triangle Lane #15 3 (its kerb and pavement stand 0.1 over its own pinned edge at (43464, 29305)); pyay_univ Lane #588 2 (kerb 0.2-0.26 over its own road at (27036, 27670)). The 3 new ones (7 -> 10) are all at double_junction (39995-39997, 32698-32702): East Horse Race Course Road #3's deck-side kerb (30.55) under the now-built Bridge Flyover's foot surface (30.47-30.56). The deck foot still laps that side lane's kerb, so the gore change (item 2) is not enough there.
- **New in the data QA:** mouth_short 3 -> 4: East Horse Race Course Road (Bridge)'s start at (39963, 32873) is 5.3 short of the road it joins (the wider gore of item 2 reaches its start). mouth_over 1 -> 0.
- **Junction corners, mouth ends, roundabout gores** (census 1-3): e.g. the Pazundaung Y wedge (40983-40990, 43398-43414): an open triangle between Bogyoke Aung San Road #2 ~2's end and Upper Pazundaung Road #3's start, no corner built there.
- **Hledan Road #3 under Insein / Pyay** (item 2): needs a "covered" test against the bigger road's built faces or its end lines.
- **Builder state leak** (QA): a spot's build depends on the spot built before it (bahan_ring Lane #3789 kerbs 0.004-0.007). `T.runAll` keeps the same order, so the table repeats.
- Not done this pass: Yawmingyi corner wedge, Kun Chan #3 kerb pairs, flicker probe at other junctions, Bahan pave_gap strip, univ_kabaraye three-pavement island.
