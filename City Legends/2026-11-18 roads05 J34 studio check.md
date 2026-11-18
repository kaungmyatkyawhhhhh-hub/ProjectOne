# roads05 J34 studio check (18 Nov 2026, BUILDER agent)

Main Studio "City Legends". Test asset 133014134133489 re-packed twice: rev 203 = the J33 data (roads.json md5 991fe6e6, paint 0e0fcb1c) + the J33 builder, for the real baseline; rev 204 = the J34 data (roads ca2aa236, paint 1d4e6c10) + the J34 builder (`ClaudeTools.YangonRoads` checksum 1649579739, 196,364 characters, under the 200k limit). All 17 spots built with the no-terrain copy, `T.qa`, fixed (alphabetical) order. Terrain never written; scratch removed, saved as version 1347, lock released.

## Totals (T.qa: box_hole / kerb_gap / road_step / pave_step / buried / pave_gap)
| | totals |
|---|---|
| J33 as reported (data injected after load) | 17 / 193 / 37 / 77 / 11 / 107 |
| **J33 baseline, real data (rev 203)** | **18 / 191 / 37 / 77 / 11 / 104** |
| **J34 (rev 204)** | **18 / 177 / 37 / 77 / 11 / 97** |

## Per spot (baseline -> J34; only changed spots)
| spot | baseline | J34 |
|---|---|---|
| roundabout4 | 0 / 38 / 1 / 8 / 0 / 21 | 0 / **25** / 1 / 8 / 0 / **14** |
| univ_kabaraye | 4 / 31 / 16 / 9 / 0 / 4 | 4 / **29** / 16 / 9 / 0 / 4 |
| deck_run | 1 / 9 / 2 / 11 / 0 / 9 | 1 / **10** / 2 / 11 / 0 / 9 (one U Wisara #2 / #3 cell moved by half a stud) |
| pazundaung_y | J33 report 0 / 5 / 0 / 0 / 0 / 6 | 1 / 3 / 0 / 0 / 0 / 3 on the real data, both passes (J33's Upper Pazundaung #3 change was never in the data) |

Unchanged: bahan_ring 1/26/0/6/0/10, double_junction 3/24/1/0/5/18, downtown_straight 0, hanthawaddy 3/6/0/0/0/1, hledan_flyover 3/4/0/1/0/1, kunchan_gyophyu 0/25/3/16/1/12, lane_taper 0, long_median 0/0/0/0/0/3, pyay_univ 1/13/9/13/2/7, slip_triangle 0/10/3/11/3/4, sule_north 0/0/0/0/0/2, sule_shangrila 1/2/2/0/0/6, ycentral 0/0/0/2/0/3.

Shot: `2026-11-18 roads05 J34 - roundabout4 - Lane 3357 ring corner kerb closed.jpg`.

## What changed
1. **YangonRoads.inCorner (`armNear`)**: a ring corner's zone stops at its arm's centre line. Before, the north corner of Lane #3357 at Roundabout 4 (r 5.7, zone 21.7 studs from its centre) reached across the 10.5-wide lane and took the SOUTH kerb and pavement (13 studs, open ground). Found by testing the zone along the missing kerb, then taking one corner at a time out of the grid. Fixed Lane #3357 and Lane #115 (roundabout4 kerb_gap 38 -> 25, pave_gap 21 -> 14). Nothing else moved.
2. **YangonRoads.scrub**: a road's data past its own mouth is not built, so it no longer scrubs its host's kerb / pavement (Kabar Aye Pagoda Road #6's east kerb by Lane #1256's mouth, univ_kabaraye kerb_gap 31 -> 29). Ring mouths keep the old rule: the first try also skipped them and roundabout4 went 25 -> 30.
3. **roads05_fix** (data, pipeline J34a): `edge_ends` (road ends within 3 studs of the district outline are map-edge ends: Insein Road, Pyay Road #7 and 3 more); the mouth run-on also tests the end's centre (Lane #5161 ran on 2 studs); `osm_joins` runs again after `fork_trim` (cut back 2 overshooting ends: Lane #35, Tha Yat Taw 4 Street). mouthsim 0 failed of 11,571. QA (`J34a_qa.log`): mouth_short real 4 -> 2 (Insein Road and Lane #5161 gone; the Bridge start and Lane #544 left), every other rule and the paint QA = J33. None of these roads is in a test spot.

## Tried and dropped
- **Pazundaung Y west corner:** a continuation of the bigger road (Lower Pazundaung on Upper Pazundaung #3) no longer counted as "a third road" under the corner point. No change: the corner is lost at another step (it is not in the overlap list and not in the "edge never meets" list). Reverted.

## Seen, not fixed (close-ups)
- **univ_kabaraye, Lane #1256 merge nose** (34433-34436, 28990): a 4-stud notch between Lane #1256's left kerb end and Kabar Aye #6's kerb, one row deep.
- **roundabout4, Sule Pagoda Road west kerb:** single cells where the kerb has a crack and the pavement shows through (44927, 44912, 44895-44899): kerb piece joins on the curve.
- **Bridge / Road #18 (OSM checked):** OSM says East Horse Race Course Road (Bridge) is a one-way bridge (layer 1) starting on the Banyar Dala bridge, i.e. our Bo Min Gaung Street deck at height 60.6; Road #18 is the real ground road (OSM 478882258 / 617123000, one-way south). At the crossing (z ~32850) the real ground carriageway is Road #18. In our data the Bridge's first 20 samples are at ground (30.0) under the deck, between the two side lanes, and flare to half 35: road on road. A ramp from 60.6 down to 29.8 in 20 samples would be 19%, so it cannot leave the deck there. Not coded this pass.
- **Lane #544** (mouth_short 8.5): the chain joins Dhobi Street 3 #2 through a ~140 degree U-turn node, so OSM's short link to Lane #544 never exists.
