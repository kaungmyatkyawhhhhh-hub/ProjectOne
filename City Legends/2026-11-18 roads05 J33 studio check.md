# roads05 J33 studio check (18 Nov 2026, BUILDER agent)

Main Studio "City Legends" (version 1327 at start, no scratch left). Runner = asset 133014134133489 rev 202 with the repo builder put in before install. Baseline re-checked first on bahan_ring / deck_run / double_junction: exactly J32. Builder changed by find / replace: `ClaudeTools.YangonRoads` = repo (checksum 419443297, 195,605 characters, under the 200k limit), `ClaudeTools.Roads` unchanged. The two data changes (islands, butt_match) were put into the test by replacing those records after `Y.load()` (8 island records, Lower Pazundaung s1-s5, Upper Pazundaung #3 s1932-1936). All 17 spots built with the no-terrain copy, `T.qa`, fixed order. Terrain never written; scratch removed, saved, lock released.

## What I saw (close-up first)
- **bahan_ring, Kan Yeiktha island:** ray map by road name. The island record was ONE outline covering two islands joined by a neck right under Kan Yeiktha Road's start. Cause: the island data (roads05_fix `islands`) is the hole in the union of every road's quads, and `quads()` drops a quad that folds into a bow-tie on a sharp bend (Kan Yeiktha Road s1-s2). `Roads.build` lays that bend anyway (its inner edge point waits), so the "hole" ran under asphalt: the builder scrubbed the island triangles on the road, leaving the 2-4 stud spike and an unkerbed side.
- **pazundaung_y gore:** Bogyoke Aung San Road #2 ~2 ends on Upper Pazundaung Road #3 right at the Y where Lower Pazundaung starts. The mouth's "bigger road edge" stopped at Upper Pazundaung's end, so the mouth's other edge snapped across and left a 4-8 stud wedge with nothing built. Satellite / OSM: one asphalt junction, so asphalt is the right fill.
- Also at the Y: Lower Pazundaung (half 22.5) starts on Upper Pazundaung's 31.5-half end, a 9-stud step each side with no kerb. `butt_match` was written for exactly this joint but skipped it: "a median in the first 8 samples" = 65 studs, and Lower's median starts 57 studs on.

## What changed
1. **roads05_fix.py `built_quads`**: islands now come from the carriageway as the builder lays it (inner edge waits on a tight bend), and a hole pinched to a neck under 1 stud is split into its own islands. bahan_ring's island is now two islands (722 + 1,332 studs^2).
2. **YangonRoads.buildMouth**: the bigger road's edge runs on along a continuation's edge on the same side (`contsOf`: roads flagged startsOnEnd / endsOnEnd within 3 studs of its end; their edges are kept for it). The Pazundaung gore is asphalt now.
3. **roads05_fix.py `butt_match`**: the median check looks only within the morph + 8 studs. Lower Pazundaung now starts on Upper's full end and tapers back over 40 studs.

## Totals (T.qa: box_hole / kerb_gap / road_step / pave_step / buried / pave_gap)
| | totals |
|---|---|
| J32 (= J33 start) | 19 / 214 / 37 / 77 / 11 / 105 |
| **J33** | **17 / 193 / 37 / 77 / 11 / 107** |

## Per spot (J33 start -> J33)
| spot | before | after |
|---|---|---|
| bahan_ring | 1 / 37 / 0 / 6 / 0 / 9 | 1 / **26** / 0 / 6 / 0 / **10** |
| deck_run | 1 / 9 / 2 / 11 / 0 / 9 | same |
| double_junction | 3 / 24 / 1 / 0 / 5 / 18 | same |
| downtown_straight | 0 / 0 / 0 / 0 / 0 / 0 | same |
| hanthawaddy | 3 / 6 / 0 / 0 / 0 / 1 | same |
| hledan_flyover | 3 / 4 / 0 / 1 / 0 / 1 | same |
| kunchan_gyophyu | 0 / 25 / 3 / 16 / 1 / 12 | same |
| lane_taper | 0 / 0 / 0 / 0 / 0 / 0 | same |
| long_median | 0 / 0 / 0 / 0 / 0 / 3 | same |
| pazundaung_y | 2 / 15 / 0 / 0 / 0 / 5 | **0 / 5** / 0 / 0 / 0 / **6** |
| pyay_univ | 1 / 13 / 9 / 13 / 2 / 7 | same |
| roundabout4 | 0 / 38 / 1 / 8 / 0 / 21 | same |
| slip_triangle | 0 / 10 / 3 / 11 / 3 / 4 | same |
| sule_north | 0 / 0 / 0 / 0 / 0 / 2 | same |
| sule_shangrila | 1 / 2 / 2 / 0 / 0 / 6 | same |
| univ_kabaraye | 4 / 31 / 16 / 9 / 0 / 4 | same |
| ycentral | 0 / 0 / 0 / 2 / 0 / 3 | same |
| **total** | **19 / 214 / 37 / 77 / 11 / 105** | **17 / 193 / 37 / 77 / 11 / 107** |

Shots: `2026-11-18 roads05 J33 - bahan_ring - Kan Yeiktha islands split and kerbed.jpg`, `2026-11-18 roads05 J33 - pazundaung_y - Y gore filled.jpg`.

## Seen but not fixed
- **bahan_ring, NE Kan Yeiktha island:** a 2-7 stud open strip between Kan Yeiktha Road's east edge (s1 cap line, (35427, 38115) to (35421, 38140)) and the island's kerb; it is the +1 pave_gap. The island fill stops short of the road there.
- **pazundaung_y, west corner** (40973-40982, 43395-43398): no round corner between Bogyoke's north kerb and Upper Pazundaung's west kerb. **East nose** (41038-41042, 43411-43416): the two roads' kerb ends do not meet.

## Not done (next pass, in order)
1. The three leftovers above.
2. kerb_gap clusters by close-up: roundabout4 (Lane #3357, Lane #115), univ_kabaraye Lane #1256, deck_run U Wisara #5, kunchan Gyophyu Flyover.
3. Buried 11; the Bridge start join to Road #18 (Road #18 lies inside the Bridge's widened start: the Bridge flares from half 24.5 to 31.7 over its first 6 samples and the two cross at z ~32850, so it is road on road, not a gap); pave_gap fill rule; pyay_univ road steps; univ / kunchan regressions.
