# roads05 J35 studio check (18 Nov 2026, BUILDER agent)

Main Studio "City Legends". Test asset 133014134133489 rev 205 = the J35 data (roads.json md5 c34a1111, paint b6c2ba15) + the split builder (`ClaudeTools.YangonRoads` 169,545 chars, checksum 348673078 + new `ClaudeTools.YangonRoadsChecks` 27,721 chars, 1180005105). All 17 spots built with the no-terrain copy, `T.qa`, alphabetical order. Terrain never written. Scratch removed, saved as version 1358, lock released.

## Totals (T.qa: box_hole / kerb_gap / road_step / pave_step / buried / pave_gap)
| | totals |
|---|---|
| J34 (rev 204) | 18 / 177 / 37 / 77 / 11 / 97 |
| **J35 (rev 205)** | **16 / 177 / 36 / 77 / 9 / 95** |

## Per spot (only changed spots)
| spot | J34 | J35 |
|---|---|---|
| double_junction | 3 / 24 / 1 / 0 / 5 / 18 | **1** / 24 / **0** / 0 / **3** / **16** |

Unchanged: bahan_ring 1/26/0/6/0/10, deck_run 1/10/2/11/0/9, downtown_straight 0, hanthawaddy 3/6/0/0/0/1, hledan_flyover 3/4/0/1/0/1, kunchan_gyophyu 0/25/3/16/1/12, lane_taper 0, long_median 0/0/0/0/0/3, pazundaung_y 1/3/0/0/0/3, pyay_univ 1/13/9/13/2/7, roundabout4 0/25/1/8/0/14, slip_triangle 0/10/3/11/3/4, sule_north 0/0/0/0/0/2, sule_shangrila 1/2/2/0/0/6, univ_kabaraye 4/29/16/9/0/4, ycentral 0/0/0/2/0/3.

Shot: `2026-11-18 roads05 J35 - double_junction - Bridge starts off Road 18.jpg`.

## What changed
1. **Code split.** The checks part of `YangonRoads.luau` (checkBumps .. stepCell, ~700 lines) moved to `YangonRoadsChecks.luau`. YangonRoads requires it at load. The test runner installs it and the packers ship it. Same 3 spots before and after (roundabout4, univ_kabaraye, deck_run): identical counts and parts hashes. 30k characters are now free under Studio's 200k limit.
2. **Bridge / Road #18 (roads05_fix `deck_foot_ends`).** An OSM bridge whose end sits at ground under ANOTHER deck is cut back to that deck's footprint edge. East Horse Race Course Road (Bridge) lost its first 5 samples (under the Banyar Dala Road deck, on Road #18). Its own flyover indices moved with it (`_shift_idx`, a fix to the old cut-only shift). Road #18 stays the ground road. The repair step now gives Road #18's start a "square end under the deck" instead of a 32-stud run-on into the Bridge. mouthsim 0 failed.
3. **Lane #544 (roads05_chain).** A node is not chained through a turn sharper than 100° when another road's end lies within 15 studs (5 joins skipped). Dhobi Street 3 #2's U-turn is now split: Lane #2914 is the short link and Lane #544 starts on its end. **QA mouth_short real 2 -> 0.**

QA (`J35a_qa.log`): mouth_short real 0 (was 2), dead_end 4452 -> 4451, signals 242 -> 243, every other rule = J34. Paint QA (`J35a_paint_qa.log`): arrow_missing 9 -> 10, edge_missing 179 -> 178, the rest = J34.

## Tried and dropped
- **Pazundaung Y, Bogyoke × Upper Pazundaung round corner.** Found where it is lost: `findCorners`, "edge never meets the other kerb" (noCorner, line ~1388; the J34 note was wrong). Bogyoke Aung San Road #2 ~2 ends on Upper Pazundaung Road #3 at sample 1, so the kerb window stops at Upper #3's start, and the kerb it should meet runs on along the continuation (Lower Pazundaung Road). Letting the window run on along the continuation built both corners (r 30), but pazundaung_y kerb_gap went 3 -> 29 (13 at the Y nose, 14 at Lake Kan × U Shwe Gwun). With the plain corner size it was still 25. Reverted.

## Not reached
NE island strip at Kan Yeiktha, Y east nose, kerb_gap list (U Wisara #5, Gyophyu Flyover kunchan, Lane #1256 notch, Sule Pagoda Road curve cracks, Maha Bandula #2 / Lane #3357 island), the rest of buried (double_junction 3: Lane #3308's road 0.8 over its own and Banyar Dala #3's kerb at 39984, 32911; Bridge flyover foot vs East Horse Race Course Road #3 kerb at 39996, 32701), the pave_gap fill rule, pyay_univ road steps.
