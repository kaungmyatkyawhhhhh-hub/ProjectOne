---
date: 2026-10-28
tags: [speedarc, progress]
---
# SPEED ARC Progress - Hub map redesign

Back to [[00 SPEED ARC Home|SPEED ARC Home]] · Feature note: [[SPEED ARC - Hub World]]

## What the owner asked
"The entire map should be redesigned. The portals are blocked and people don't know where they are. The arrangement sucks." Then: "the flowers don't look like flowers", and "a separate place for training and a separate place for shops only".
Owner picked the **central plaza** layout.

## The new layout
| Where | What |
|---|---|
| Middle | **Central Plaza**: you spawn here, facing the track. A signpost with 4 arrows, floor labels at each exit, 4 round flower planters with small trees, 8 benches |
| North | The race track (unchanged, so races work as before). Benches by the track to watch races |
| West | **Shop Street** (only shops): Shoe Shop + Trail Booth on the north side, Coach Corner + new **Locker Room** on the south side, a fountain at the end. Gold lamps, banners and kerb line |
| East | **Portals** avenue to a raised round stage: the 5 gates in a shallow arc facing the plaza, nothing in front of them. A light beam over each gate (Neon, no real light) so you can see them from anywhere. Blue lamps and kerb line |
| South | **Training Yard** (only training): Sprint Lane, Treadmills and Stair Run each in its own bay (blue mat, white lines, sign at the front). Fence round 3 sides, flower planters between bays. The school with the race clock is behind it |
| Plaza south edge | The 4 leaderboards on two walls either side of the yard path |

Each district has an arch with its name at the plaza (SHOP STREET / PORTALS / TRAINING YARD), its own paving colour and a neon kerb line in its colour.

## Other fixes found on the way
- **Shoe Shop and Trail Booth faced the wrong way.** Their imported Blender shells were turned round (open side at the back), also in the old layout. Turned back in the builder.
- **Flowers** are now real flowers: daisies, tulips and lupins (stem, 2 leaves, petals), in 8 colour mixes, planted in drifts with leafy mounds in raised planters. Each flower is one part (built once, then copied).
- New **Locker Room** on Shop Street: walk up, press OPEN, and the Locker opens on KITS.
- Locked gates also dim their sky beam.
- The menu fly-over now circles the whole new map.

## Numbers
| | Before | Now |
|---|---|---|
| Hub parts | 882 | 1,726 (316 flowers) |
| Real lights | 0 | 0 |
| Glass | 0 | 0 |
| Studio FPS | Studio-limited | 15 render / 60 physics, Studio-limited again (two Studios open, same as Progress 1) |
| Instances (client, play) | 58,577 | 58,953 |
No console errors in a FreshPlayer play test. The tutorial put the new player into the Sprint Lane in its new bay. All 4 gate triggers are found.

## Screenshots
![[2026-10-28 map v2 spawn view.jpg]]
![[2026-10-28 map v2 overview.jpg]]
![[2026-10-28 map v2 shop street.jpg]]
![[2026-10-28 map v2 portals.jpg]]
![[2026-10-28 map v2 training yard.jpg]]
![[2026-10-28 map v2 flowers.jpg]]
![[2026-10-28 map v2 menu.jpg]]

## Code changed
- `tools/build_hub.luau`: new ground, avenues, plaza, Shop Street (shops are built facing +X and then placed), Locker Room, Training Yard, portal stage, leaderboard walls, flowers, arches, signpost, floor labels, fountain, lamps.
- `Config/Areas.lua`: hub spawn (0, 3, 118) in the plaza.
- `TutorialService`: "go to shop" now stands you in front of the shop whichever way it faces.
- `MenuController`: Locker Room prompt; locked gates dim their beam.
- `LoadingScreen`: fly-over centred on the new map.

## Owner to do
1. Play it in Studio and walk around. Tell me anything that feels wrong.
2. File > Save to Roblox, and a dated backup (File > Save to File).
3. Check FPS on your phone (Studio can't show the real number with two Studios open).
