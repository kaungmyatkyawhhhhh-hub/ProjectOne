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
- The starter gym has a copy of every pro machine (two columns in the middle of the room) and every gym's dumbbell rack has Train spots (starter 6, beach 6, pro 4). See [[GYM ARC - Machines]].

## Starter gym re-layout (21 Oct, prompt 26; [[2026-10-21 GYM ARC Starter gym layout]])
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
