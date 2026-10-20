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
