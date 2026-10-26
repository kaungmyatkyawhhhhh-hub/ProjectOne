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

## Street front (23 Oct, prompt 62, [[2026-10-23 GYM ARC Powerlifting front and Pro Gym view]])
- No more alley: the 6 Main Street buildings in front of it went to `ServerStorage.PowerliftingFrontRemoved_23Oct`; its front faces Main Street, lined up with the starter gym (gym row: Powerlifting, Starter, Pro), with a paved forecourt.
- Facade (`Workspace.PowerliftingGym.Facade`, `tools/builders/PowerliftingFront`): brick base, 8 industrial windows, steel columns, lit POWERLIFTING / GYM ARC sign, wall lamps, side door, sawtooth roof with skylights, vents and AC units, chalk barbell mural on the east wall.
- Loading door: locked = steel shutter with a black + white "UNLOCKS AT GROWTH SPURT 5" plate and padlock; tapping it (ClickDetector on the `Blocker`) or walking up shows the locked toast with progress. Unlocked = rolled up.

## Door fix (27 Oct, owner: "I can't go in the powerlifting gym and I have over Growth Spurt 5")
Streaming unloaded the loading door's parts when you walked away and brought them back with the server's closed state (the invisible Blocker solid again), while PowerliftingClient still thought the door was open, so it never re-opened. It now re-applies whenever the blocker's collision doesn't match (same for the Strongman Yard gate). Tested: away and back twice, then walked in.

## Record board: IN THIS SERVER (27 Oct)
Owner: "the server record shows even the old top 1, 2, 3 that already left the server". The 1 / 2 / 3 were the saved ALL-TIME list (all servers, kept forever), easy to read as this server's ranking. Now (PowerliftingService) each lift's column shows:
- top line **ALL-TIME RECORD**: the saved list's #1 (all servers);
- **IN THIS SERVER** 1 / 2 / 3: only players in this server now, by their best: their saved PR on the lift's machines (PLSquat / PLMonolift, PLBench, PLDeadlift) as they join, raised by this session's lifts. A player who leaves comes off the list at once.
- The all-time top 3 is still saved and merged across servers as before (just not listed on the board). NEW SERVER RECORD (board flash, judge lights) now fires when someone beats the best lifter in the server right now.
- Tested: joining put LuigiRED's PRs (875 / 595 / 875 LB) on IN THIS SERVER with the all-time line above. Not tested with 2 players (needs a team test).

## Doors: slats / signs left showing (27 Oct)
Owner: "the slats still appear after unlocking the Powerlifting gym", "the ALTER 2 sign of the Strongman Yard doesn't disappear after unlocking". The shutters' pieces (slats, the lock sign) streamed in one by one after the door had been opened, so the late ones stayed visible. Fix: the three door models (LoadingDoor, YardGate, YardDoor) stream in whole (ModelStreamingMode Atomic), and PowerliftingClient re-checks every shutter piece each tick (and a new Shutter instance). Tested: all three fully open (0 visible parts, 0 signs) after walking away and back twice.
