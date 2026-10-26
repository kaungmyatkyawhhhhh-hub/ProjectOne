---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Town and Gyms

Back to [[00 GYM ARC Home|GYM ARC Home]].

A sunny beach-side fitness town with three gyms: the warm old-school starter gym, the premium pro gym, and the beach gym.

## How it works
- **Town hub:** main street, plaza with a fountain, park, parking lot, beach, skate park, posing stage, smoothie bar, clothing store.
- **Starter gym (88 x 85 studs, ceiling 16):** brick walls, black rubber floor, exposed pipes. Zones: entrance (front desk, shake machine, water fountain, Muscle of the Day chalkboard, the gym cat), rack area on the left, bench row facing the mirror wall with a red neon "GYM ARC" sign, pull-up / dip corner, dumbbell rack and stretching area on the right, cardio corner. Lifting platforms under the squat rack, deadlift and row.
- **Pro gym (68 x 85, ceiling 18, opens at Growth Spurt 2):** behind a glass wall with a sliding door. Darker premium look: charcoal floor with a tile grid, chrome racks on wood platforms, mirror wall, LED lights and strips, spotlight pools, a smoothie bar corner, hanging zone signs.
- **Beach gym (Growth Spurt 1):** copies of the real machines in beachy surroundings, plus the sauna recovery station.
- **Locked areas:** signs say "Opens at Growth Spurt N" only while locked for you.
- **Built in Studio:** world geometry comes from builder scripts run once (`tools/builders`), never by game scripts. Services only find pieces by name and wire them.
- **Performance:** StreamingEnabled on, only a few shadow-casting lights, small props without shadows. Town ~16,100 parts, gyms ~3,500.
- **13 Oct:** sauna doorway widened and pull-up / dip clearances changed so a 7'0" mass monster fits.

## Gym ladder (23 Oct, prompt 58)
- Starter, Beach (Spurt 1), Pro (Spurt 3, was 2), Powerlifting (Spurt 5, the warehouse west of the starter gym with an alley from Main Street). See [[GYM ARC - Powerlifting Gym]].
- East of the Pro Gym the land outside the boundary is a valley with a city below (seen through the Pro Gym's glass).

## Where it lives
- `tools/builders` (Gyms, GymKit, Town, Decor, Sauna, ...), `tools/bake.md`
- `Server/ProGymService`, `ProGymClient`, `AreaSignsClient`, `Config/Town`

## Known issues
- If phones struggle: turn windows and trees into MeshPart templates.

## Planned change
- New features prompt: a posing competition stage in the plaza, smoothie bar counter + starter gym cart, leaderboards in every gym, arm wrestling tables in both gyms, rivals per gym, a day / night cycle (20 min day). Monetization prompt: a small VIP lounge in the pro gym.

## Related
[[GYM ARC - Gym Lighting]], [[GYM ARC - Machines]], [[GYM ARC - Skateboard and Skate Park]], [[GYM ARC - NPC Regulars and Gym Cat]]

## Screenshots
![[GYM ARC/Screenshots/s3_town-above_after.png]]
![[GYM ARC/Screenshots/starter_gym_bigger_wide.jpg]]
![[GYM ARC/Screenshots/pro_gym_bigger_wide.jpg]]
![[GYM ARC/Screenshots/beach_real_machines_row.jpg]]

## 21 Oct (prompt 16)
- (Copies removed again by prompt 32.) The starter gym had a copy of every pro machine (two columns in the middle of the room) and every gym's dumbbell rack has Train spots (starter 6, beach 6, pro 4). See [[GYM ARC - Machines]].

## Old starter gym restored (21 Oct, prompt 32; [[2026-10-21 GYM ARC Old starter gym restored]])
- The owner went back to the old starter gym: the re-layout below and prompt 16's pro machine copies are undone. The room is 88 x 85 again (ceiling 16), original zones and machines, plus the dumbbell Train spots and the Trainer Agency.
- Backups in `ServerStorage.StarterGymBackup`: `Before` (the old gym, what is live now), `LayoutV2` (the re-layout), `ProCopies` (the 11 pro copies), `Removed`. All untagged.
- The grass west of the gym is filled back in; the trees there were spread out again (their exact old spots were lost).

## Starter gym re-layout (21 Oct, prompt 26; UNDONE by prompt 32)
The starter gym felt packed after prompt 16 (every machine, dumbbells, the Agency). Re-laid out like a real, organised gym:
- **Bigger room:** 30 studs wider to the west (now 118 x 85, +34%); the ceiling 16 -> 18 (the same as the pro gym). The front wall, door, the glass wall to the pro gym and the back (mirror) wall stayed where they were; the new wing has its own street windows, west wall windows, a duct line and an AC unit on the roof. Trees on that ground moved west; the terrain under the new floor was cleared.
- **Zones, straight rows, hanging black + gold zone signs:** FREE WEIGHTS (west: squat racks + overhead press against the wall, benches, deadlift / row platforms, all facing into the room), CABLES + ARMS (pushdown, curl, woodchop), MACHINES (two rows on the east, same spacing, all facing the aisle), CARDIO (one row by the glass wall), DUMBBELLS (rack + 6 train spots on the mirror wall), STRETCH (back-left corner). FRONT: desk + Coach Dex, the Trainer Agency, the lounge corner (arm wrestling, smoothie cart, a bench).
- **Walkways:** a main aisle from the door (12+ studs, open to the dumbbells), 8+ studs between all rows; the path to the pro gym's glass door stays clear.
- **Fewer duplicates:** 2 Flat Benches and 2 Squat Racks (the tutorial ones), 1 of everything else (10 machines removed). Gym bags, the floor mat, a sitting bench and the free-standing whiteboard removed.
- **The big dark board** (the hanging COACH DEX sign, seen from behind) is gone; the name is a nameplate on the desk.
- **Lights:** one grid of 20 pendants at one height (2 cast shadows, as before), 12 fill lights; the 3 extra pendants removed.
- Every machine kept its MachineId, prompts and Hype / Spot points (moved as whole models); the tutorial's glowing path finds the new spots by itself.
- Everything changed is backed up in `ServerStorage.StarterGymBackup` (Before: the whole old gym; Removed: what was taken out; tags removed, kept as a WasTags attribute). Builder: `tools/builders/StarterLayout`.

![[GYM ARC/Screenshots/starter_layout/angle1_from_desk.jpg]]
![[GYM ARC/Screenshots/starter_layout/top_after.jpg]]

## Beach gym upgrade, city in Studio (26 Oct; [[2026-10-26 GYM ARC Fast spurts, menu, beach and skate park]])
- Beach gym: mat edging + gold lines, tiki torches, festoon lights, BEACH GYM board, surfboard racks, umbrellas + loungers (`BeachGym.Upgrade`, backup ServerStorage.BeachGymBackup_26Oct).
- The Pro Gym city is in `Workspace.Backdrops` in Studio; Main moves it into ReplicatedStorage.Backdrops at game start.

## Beach gym expanded (27 Oct, owner: "keep the old beach and skatepark and expand them")
- The old look kept; the compound grows 18 studs north to the water (`Town.BeachGym.NorthDeck`): the north rope fence, its lamps and the corner flags moved out to z 257, the side fences lengthened, the boardwalk continued to the north opening.
- New shoreline deck: two speckled rubber mats like the weights mats, two copies of the calisthenics sail shade, and **5 new exercises** the beach didn't have: Deadlift, Overhead Press, Incline Bench, Barbell Row, Crunch Bench (the starter gym's machines, `Gym = Beach`, so they open with the beach gym at Spurt 1; facing south like the other beach stations). Tested: all 5 put the player on and lift.
- Backup: `ServerStorage.BeachGymBackup_27Oct`.

## Skate park expanded (27 Oct)
- Old look kept; the concrete slab grows 18 studs north (`Town.SkatePark.NorthExtension`): the north fence, both floodlights, the art wall and the north lamp moved to the water, the side fences lengthened.
- New: a **half pipe** (two copies of the park's own quarter pipe facing each other across 24 studs of flat), a flat grind rail (tagged GrindRail, grinds like the others) and a kicker.
- Beach decor that stood in the new strip (2 palms, driftwood, a shell, an umbrella / chair / towel set) moved just outside the fence.
- Backup: `ServerStorage.SkateParkBackup_27Oct`. Not tested: riding the half pipe on a board (needs a real player).
- Shots: `beach_expand_top.jpg`, `beach_expand_lift.jpg`, `skate_expand_top.jpg`, `skate_expand_halfpipe.jpg` in `Screenshots/test_2026-10-27`.
