# Prompt: roundabout roads invisible + falling through the road at Sule

_For Claude Code on the PC with Studio (MCP). Owner: caveman mode, no questions. No errors. Read the "Hanthawaddy roundabout invisible road" and "CORRECTION: the ground-deepening fix did NOT work" sections in `City Legends/2026-11-21 Night run - P8, code sync, minimap, lamps.md` first._

## What the owner says (2026-11-22)
"I don't think u have fixed the roundabout roads being invisible yet, and also in Sule, in some parts u can go through the road and get stuck in the ground."

## What we know
- **Hanthawaddy Roundabout** was fixed on 21 Nov (terrain cleared over the road meshes, 509 `RCol` strips in `Roads.CollideFix_HanthawaddyRoundabout`, 12 asphalt tops in `Roads.VisibleFix_HanthawaddyRoundabout`, no kerbs / lines on those). A whole-map scan (`_G.RbScan` / `Roads.VisibleFix_Auto`) was started in Edit; it lives only in Studio memory, so check if it finished (attribute `Filled` on boxes) before trusting it.
- **Sule:** a known hole in the collision boxes along Sule Pagoda Road, and the ground under every road was carved 10 studs deeper on 21 Nov, so a car falls 10 studs into it and gets stuck. Sule Pagoda Road runs (36102, 42836) -> (36005, 44992) -> Roundabout 4 (Sule roundabout) -> (35958, 46458); side pieces #4 (36026, 43808)-(35934, 44304), #5 (35953, 43490)-(36019, 43571). The truss bridge over the railway is at z 42870-43020.

## Roundabouts in the built districts (from the road data; check every one)
| Roundabout | centre (x, y, z) | outer radius | district | arms |
|---|---|---|---|---|
| Roundabout 1 | (35288, 49, 38108) | r_out 113 | P7 | Bahan Road, Bahan Road #2, Kan Yeiktha #2, Kan Yeiktha Road |
| Roundabout 2 | (32186, 85, 38314) | r_out 103 | P7 | Ahlone Road, Ahlone Road #2, U Htaung Bo Road, U Htaung Bo Road #2 |
| Hanthawaddy Roundabout | (28250, 75, 32193) | r_out 116 | P1 | Hanthawaddy Road, Hanthawaddy Road #2, Pyay Road, Pyay Road #4 |
| Roundabout 4 | (35996, 19, 45117) | r_out 178 | P3 | Lane #115, Lane #3186, Lane #3352, Lane #3357 |
| Roundabout 11 | (27513, 66, 18429) | r_out 32 | P4 | Lane #616, Lane #620, Lane #623, Lane #624 |
| Roundabout 12 | (30524, 68, 18726) | r_out 26 | P2 | Lane #4852, Lane #611, Lane #617, Lane #6717 |
| Roundabout 15 | (33241, 53, 17517) | r_out 46 | P2 | Lane #4697, Lane #6795 |
| Roundabout 25 | (33540, 53, 41711) | r_out 35 | P3 | Lane #4562, Lane #4563 |
| Roundabout 26 | (33078, 101, 35539) | r_out 36 | P7 | Lane #1429, Lane #5684 |

## Do
0. **Sync `src/client/Driving.lua` first** (cloud, 22 Nov): a car stuck in the ground under a road (no road box under it, a road box top 4+ studs over it within 12 studs, under 8 studs/s for 2 s) is put back on the nearest road with "Back on the road". A safety net only: still fill the holes. Test: drive into a known Sule hole, wait 2 s. Also check it never fires on grass beside a raised road or under a flyover.
1. **Every roundabout above:** look from above and from a car in Play. Where the ring has collision with no road mesh, or terrain over it, do the Hanthawaddy fix (clear terrain over the road surfaces, `RCol` strips under any mesh floor with none, asphalt tops over bare boxes) and ALSO kerbs and lane lines like the rest of the ring (the Hanthawaddy tops have none: add them there too). Better if it works: re-bake those road cells properly instead of patches.
2. **Sule:** walk every lane and pavement of Sule Pagoda Road (all pieces above), the Sule roundabout and the streets meeting them a stud at a time (LaneCheck-style ray down from 6 studs up, middle and 3 studs each side): every spot with no `RCol` / road collision within 2 studs under the surface is a hole. Fill each with collision (and a visible top if the mesh is missing). Then drive it in Play at speed in every lane, and walk the pavements.
3. **Then the whole map:** the same hole scan on all road cells (it costs time: run it cell by cell in `task.spawn`, save progress in an attribute, report per cell). Fix every hole found.
4. No overlapping / flickering parts (the flicker rule). Save is the owner's (Ctrl+S). Note results with before / after pictures in the vault.

## Tell the owner (short)
Which roundabouts were broken and are fixed (pictures), how many Sule holes were filled, the whole-map hole count.
