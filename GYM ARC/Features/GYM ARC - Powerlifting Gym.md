---
date: 2026-10-23
tags: [gymarc, feature]
status: built
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Powerlifting Gym

Built 23 Oct ([[2026-10-23 GYM ARC Prompt - 58 Pro Gym lights, gym pacing, Powerlifting Gym|prompt 58]], [[2026-10-23 GYM ARC Pro Gym lights and Powerlifting Gym|progress note]]). Opens at **Growth Spurt 5**.

## Place
- An old warehouse at the north-west edge of town, behind the Main Street row and west of the starter gym. Brick below, dark steel cladding above, high ceiling (30) on steel beams, high windows, "POWERLIFTING" painted on the front.
- The way in: a new alley from Main Street to a roll-up loading door. One small town building was moved out for the alley (`ServerStorage.PowerliftingSiteBackup`, with the trees and rocks that stood on the site and the terrain before).
- Inside 108 x 92 studs, aisles 11+ studs wide.

## Training (all `Gym = "Powerlifting"`, `Config/Machines.PowerliftingCopies`)
| Zone | Machines |
|---|---|
| West wall | 3 Comp Squat racks, Strict Press (black rubber mats) |
| East wall (wooden platforms) | 2 Comp Deadlifts, Block Pull (wooden blocks), Pendlay Row |
| Middle | 2 Comp Benches, Weighted Pull-Up, Weighted Crunch |
| Front | Heavy dumbbell rack (4 spots, 150 to 220 lb, "HEAVY DUMBBELLS" picker) |
| Back: competition platform | Monolift Squat, Comp Bench, Comp Deadlift (`Platform = true`) |

- All 6 groups covered. Weight tiers start at the Pro top and keep the same steps: bars 455 to 595 (20), squat / deadlift 665 to **875** (30), bodyweight +205 to +310 (15), dumbbells 150 to 220 (10). Levels 178 to 262, +15% EXP a tier (`Machines.PowerliftingProgression`).
- Locked below the first weight's level, like the Pro copies ("train on the lighter machines first").
- Gym bonus **+20%** (`Machines.GymGains.Powerlifting = 1.2`; Pro stays +10%).
- New **100 lb bumper** plate (`GymAssets.Plates.Plate100`); every plate here is red with a black rim.

## Look
- Dark rubber floor, black steel, RED accents (the Pro machines' gold parts turn red, no PRO badge, no floor glow), bright white high-bay lamps (30, 3 cast shadows), faint chalk dust, 4 chalk stands, plate trees, loudspeakers.
- Banners: LIFT HEAVY, CHALK UP, NO EGO, JUST WEIGHT, ONE MORE REP, LOCK IN, NO DAYS OFF.
- While you're inside the colours are a little rawer (`GymMoodClient`).

## Record board + PR bell (unique feature)
- **Record board** (back wall): for squat, bench and deadlift the server record (name + weight) and the all-time top 3 (one per player, saved in DataStore `PowerliftingRecords_v1`, merged with other servers).
- **PR bell**: a new personal record on any machine here rings the bell for everyone inside, with a gold flash and the toast "NAME hit a 875 LB DEADLIFT PR!" (only inside).
- **New server record** (beating someone): the board flashes, judge lights white with GOOD LIFT, crowd cheer, toast "NEW SERVER RECORD".
- **MEET** every 10 min for 60 s (15 s warning): reps on the competition platform give +20% EXP and the judge lights answer each rep; the countdown shows on the panel under the judge lights.
- All numbers in `Config/Powerlifting`.

## Hookups
- Locked door: shutter down with LOCKED, sign "Unlocks at Growth Spurt 5", walking up shows the locked toast with progress; the server puts anyone locked back in the alley.
- Unlock guide (Coach Dex + GO TO teleport + path), the growth spurt card "Next: Powerlifting Gym" at Growth Spurt 4, the Growth Spurt 5 popup line.
- 3 NPC lifters (Hank, Vera, Tank), music area `Powerlifting` (owner's heavier tracks for now), sounds PRBell / RecordCheer / GoodLift / PlateDrop (reused licensed ids, [[GYM ARC - Music and Sounds]]).
- No world map exists yet, so there's no map entry.

## Where it lives
- `Server/PowerliftingService`, `Client/PowerliftingClient`, `Config/Powerlifting`, `Config/Machines`, MachineService (red plates, meet bonus, lift hook), GymGoerService.
- Builder `tools/builders/PowerliftingGym` (Workspace.PowerliftingGym, ~1,850 parts).

## Studio test hooks
- `TestSpurts` + `FreshPlayer` as usual; `TestMeet = true` starts a meet now; `TestMachine = "Powerlifting/PLDeadlift"`.

## Screenshots
![[GYM ARC/Screenshots/p58/pl_inside.jpg]]
![[GYM ARC/Screenshots/p58/pl_pr_bell_board.jpg]]
![[GYM ARC/Screenshots/p58/pl_platform_good_lift.jpg]]
![[GYM ARC/Screenshots/p58/spurt4_pl_locked.jpg]]
