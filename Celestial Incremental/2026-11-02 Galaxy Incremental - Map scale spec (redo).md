---
date: 2026-11-02
tags: [galaxy, map, scale, spec]
status: decided
---
# Galaxy Incremental - map SCALE SPEC + redo (2 Nov)

Owner: "i think u need to redo the entire map and the scaling too, the scaling is so wrong for every single thing and the boards need to be carefully check and fix and if its not 1:1 accurate to the one then fix and try to get 1:1 accurate. and also in the boards, they are using the ui version that i decline (like the realistic planets and orbit speed)."

## Why the scale is wrong (measured in Studio, 2 Nov)
The concept was scaled uniformly (Blender units x2.5) with no character in the concept, so nothing was sized against a PLAYER:
- Lamp posts 4 studs tall (shorter than a player, 5.2).
- Bridges 3.5 studs wide (one-person plank).
- Personal islands 23 studs across (4 steps across; no room to grow).
- The Core is 41 x 26 studs on a 94-stud plaza (44% of the floor) while the Black Hole ring is 30 across and the anvil only 6 x 4: three different scales side by side.
- Boards show the OLD UI images (realistic striped planet), ids 101241710618078 / 119028925930340.

## The rule: size everything against the R15 character (~5.2 studs tall, ~2 wide; walk 16 studs/s)
| Thing | Size (studs) | Why |
|---|---|---|
| Personal island | 60 across (radius 30), 4 thick, rock underside ~30 deep | ~4 s to cross; room for every tier piece + terminal + garden |
| Centre plaza | 140 across (radius 70) | Core in the middle, zones around it with walkways |
| Core | star 10 across, gyro rings 18-22 across, altar 3 steps x 0.8 = 2.4 high + pedestal, top of star ~20 high; footprint ~26 across | a landmark, not the whole plaza |
| Bridges | 8 wide, 20-25 long, rails 1.2 high | two players side by side, ~1.5 s walk |
| Sector 2 bridge | 10 wide; gate arch 14 high x 12 wide | reads as THE big path |
| Lamp posts | 9 high, lamp orb 1.6 | above head height |
| Upgrades / Tree terminal (on each island) | screen 15 x 10.3 (image ratio 745:512), bottom edge 3 above floor, frame 0.6 deep | readable from ~25 studs |
| Leaderboard wall (centre) | 24 x 12, bottom 3 above floor | |
| Black Hole gate | ring 22 across (walk-through, ~4x a player), dais 30 across, 2 steps | |
| Star Forge | anvil 8 long x 3.5 high (chest height), padlock 2.5 on its front, platform 26 across, 2 steps | |
| Signs | text cap height >= 1 stud per 10 studs of viewing distance (2.5-3 stud letters for plaza signs) | readable |
| Crystal clusters | 3-8 high | accents |
| Island pieces | rim 1.5 high; lamp pillars 8; banner pole 10 with a 3 x 5 cloth; telescope 7; brass dais 12 across | |
| Star system above an island | ~22 above the floor; star 4 -> 8 across by tier; orbits radius 6-14; planets 1.5-3 | big enough to see from the plaza |
| Name plate | letters 2.5 high, ~10 above the system | readable at ~60 studs |

## Boards = 1:1 the approved UI (v12 with the low-poly planet)
New images: `Map\images\board_upgrades_v12.png`, `board_tree_v12.png` (1490 x 1024, rendered from the approved files: UI\galaxy_ui_v12_animated.html and UI\windows\galaxy_windows.html with the re-rendered low-poly planet). Also in `Downloads\galaxy_boards\` for the owner to upload to P&L Studios XP.
- Upgrades board = the approved Upgrades window (v12 buttons/rows, low-poly planet, no realistic striped planet, no "orbit speed" row from the declined version).
- Tree board = the approved Tree window (constellation diamonds, green theme).
- Screen part ratio MUST equal the image (745:512 = 1.455). SurfaceGui SizingMode PixelsPerStud or a Decal on a part sized 15 x 10.3; no stretching, no crop.
- Boards are TERMINALS on each personal island (tier 1 piece), front facing the island centre/spawn, one-sided, clickable (ClickDetector + ProximityPrompt, both open the window). Centre plaza keeps only the leaderboard wall + STAR SURGE bar.

## Also fix in the redo (from the 2 Nov Studio check)
- Padlock sits ON the anvil front (was floating 5.6 above).
- Black Hole swirl: stronger, animated (rotating beams/particles), void opaque, no see-through.
- All sign text readable (rule above); MapConfig radii = the built sizes (Config was 27.5 while the floor was 94).
- Free island slots look like a dim empty rock + bridge, not missing.
- Plaza details: walkways, lamp posts at the new size, crystal clusters.

## Owner to do
Upload `Downloads\galaxy_boards\board_upgrades_v12.png` + `board_tree_v12.png` to P&L Studios XP (Creator Hub > group > Decals/Images) and send the two ids.

Prompt for Claude Code: [[2026-11-02 Galaxy Incremental - Prompt - Map redo to scale]]
