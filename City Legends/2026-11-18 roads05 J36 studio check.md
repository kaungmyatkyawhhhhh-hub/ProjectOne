# roads05 J36 studio check (18 Nov 2026, BUILDER agent)

Main Studio "City Legends". Test asset 133014134133489 rev 206 = J35 data (roads.json c34a1111, paint b6c2ba15, no data change) + QA's new `T.qa` (kerbBetween probes, commit 11683873). Builder `ClaudeTools.YangonRoads` 173,337 chars, checksum 661359068 (= repo). All 17 spots built with the no-terrain copy, alphabetical. Terrain never written. Scratch removed, saved as version 1377 (was 1367), lock released.

## Totals (T.qa: box_hole / kerb_gap / road_step / pave_step / buried / pave_gap)
| | totals |
|---|---|
| J35 (old check) | 16 / 177 / 36 / 77 / 9 / 95 |
| J35 (QA's new check, same parts) | 16 / 161 / 36 / 77 / 9 / 95 |
| **J36** | **16 / 161 / 36 / 77 / 0 / 95** |

## Per spot (only changed spots, new check)
| spot | J35 | J36 |
|---|---|---|
| double_junction | 1 / 23 / 0 / 0 / 3 / 16 | 1 / 23 / 0 / 0 / **0** / 16 |
| slip_triangle | 0 / 10 / 3 / 11 / 3 / 4 | 0 / 10 / 3 / 11 / **0** / 4 |
| pyay_univ | 1 / 12 / 9 / 13 / 2 / 7 | 1 / 12 / 9 / 13 / **0** / 7 |
| kunchan_gyophyu | 0 / 24 / 3 / 16 / 1 / 12 | 0 / 24 / 3 / 16 / **0** / 12 |

Unchanged: bahan_ring 1/20/0/6/0/10, deck_run 1/10/2/11/0/9, downtown_straight 0, hanthawaddy 3/6/0/0/0/1, hledan_flyover 3/4/0/1/0/1, lane_taper 0, long_median 0/0/0/0/0/3, pazundaung_y 1/3/0/0/0/3, roundabout4 0/20/1/8/0/14, sule_north 0/0/0/0/0/2, sule_shangrila 1/2/2/0/0/6, univ_kabaraye 4/27/16/9/0/4, ycentral 0/0/0/2/0/3.

Shot: `2026-11-18 roads05 J36 - double_junction - Bridge flyover foot, side-lane kerb stands over the ramp.jpg`.

## What changed (all in `YangonRoads.scrub`)
1. **Kerb under a deck foot.** A kerb block that a deck's road lies over, less than 0.35 under the kerb's top, is raised to stand 0.35 over that deck road. East Horse Race Course Road #3's deck-side kerb under the Bridge Flyover's foot (39996, 32700). double_junction buried 3 -> 0.
2. **Kerb flush with its own road.** A kerb whose own road's asphalt beside it (probes 0.5-1.2 out, 8 directions) lies within 0.33 under its top is raised to stand 0.33 over it. This also runs from each stray's asphalt patch, because at a nose the kerb slivers hide the patch from the kerb's probes. Fixed: Lane #15 (slip_triangle, pinned edge), Lane #588 (pyay_univ, 1.4 drop in one sample) and Lane #3414's nose (kunchan).
3. **Stray patch never rises.** The asphalt patch laid for a stray kerb took the middle height round it and could go UP onto patches laid before it (a 1.7-stud spike at Lane #3414's nose, (36354.5, 42408)). Now it only goes down.

QA's audit (same day): Lane #3308 is no longer buried; it is a kerb_gap pattern ("kerb stops short", "pavement on the road side of its kerb").

## Tried and dropped
- Stray patch at the LOWEST asphalt round it (not the middle): univ_kabaraye road_step 16 -> 17 and kunchan unchanged. Reverted to the middle height (no rise).
- Paint QA arrow_missing 10 (new one: Banyar Dala Road #3 at (39994, 32900), the stop line moved 15 south with the J35 Bridge cut). Paint lays 2 arrows for 2 lanes. QA splits one dash line into 2 because the line drifts 3 studs across the stop line's normal over 25 studs (curving approach). Tried projecting the dashes along the road's heading at the dash, and along each dash's own axis: arrow_missing went to 16 and 17. Reverted. Next: cluster the dashes by lane line (one dash line = a chain of dashes, not one t per dash).

## Not reached
pave_step 77, road_step 36 (pyay_univ Hledan #3 / Pyay #9 joint, Lane #588; univ_kabaraye Lane #1256 / #1257), box_hole 16, kerb_gap 161 (QA's top patterns: kerb stops short 22%, pavement on the road side of its kerb 17%, open slot 15%), pave_gap fill rule, Road #18's square end, arrow_missing.
