---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Machines

Back to [[00 GYM ARC Home|GYM ARC Home]].

One reusable machine system: every machine is a config entry with the muscles it trains and 12 weight tiers. Walk up, press Occupy, and lift.

## How it works
- **Muscles per machine:** one main muscle (100%) plus secondaries (about 30-60%). Players only see muscle names, never the numbers.
- **Starter gym (2 of each):** Flat Bench, Incline Bench, Squat Rack, Deadlift, Overhead Press, Pull-Up Bar, Barbell Row, Crunch Bench, Leg Press, Hack Squat, plus treadmills.
- **Pro gym (Growth Spurt 2):** Dips, Lateral Raise, Reverse Fly (pec deck), Shrugs, Leg Curl, Hip Thrust, Calf Raise, Bicep Curl, Tricep Pushdown, Hanging Leg Raise, Cable Woodchop, plus 1 of each starter machine.
- **Beach gym (Growth Spurt 1):** copies of the real machines (same name, tiers and progress), no beach-only machines.
- **Seasonal:** a winter-only Sled Pull.
- **12 weight tiers:** each tier needs the main muscle at a level AND a one-time coin purchase. Heavier tiers give more gains and more coins per rep. After a Growth Spurt you need the level again.
- **MAX button (9 Oct):** sits right on top of the + button. Buys every next plate in order while your level and coins allow, then selects the heaviest plate you can lift. Checked on the server.
- **Plates:** real bumper colors per weight (55 red, 45 blue, 35 yellow, 25 green, 10 white, 5 steel), thin like calibrated plates, "M WEIGHTS" printed on both faces, end collars on the bars. Idle bars show a mix.
- **Lifting:** reps run on their own at a slow pace; tapping makes them faster and fills the PUMP meter. The bar follows the hands; pro machines use arm IK on real handles and cables.
- **Leg Press / Hack Squat:** the sled or carriage slides on its rail with each rep.
- **7'0" fit (13 Oct):** big bodies slide on the flat bench to clear the J-hooks; pull-up and leg raise uprights are wider; dip handles further apart; sauna doorway widened.
- **Spot types:** "hands" on benches, squat rack and overhead press; "hype" on everything else (see [[GYM ARC - Spotting]]).

## Where it lives
- `Config/Machines` (list, tiers, plates, gym unlocks), `Config/Poses`
- `Server/MachineService`, `MachineClient`
- Builders: `tools/builders/Gyms`, `GymKit`, `GymAssets` (plates), `SpotPoints`
- Numbers: [[GYM ARC - Config values]]

## Known issues
- `MachineClient` is at Luau's 200 local variable limit, so new code there has to go into tables.
- Small leftovers at 7'0": incline seat under the thighs, dip calves touching the posts, leg press rails under the body.

## Planned change
- New features prompt: arm wrestling tables should use this machine system's Occupy flow (see [[GYM ARC - Arm Wrestling]]).
- Monetization prompt: an "Auto Rep" pass (hold the rep button) replacing the old Auto Lift idea.

## Related
[[GYM ARC - Machine HUD]], [[GYM ARC - Machine Signs]], [[GYM ARC - Gains and EXP]], [[GYM ARC - Stamina and Treadmills]], [[GYM ARC - Town and Gyms]]

## Screenshots
![[GYM ARC/Screenshots/max_button_above_plus.jpg]]
![[GYM ARC/Screenshots/rebuild_machine_plates.jpg]]
![[GYM ARC/Screenshots/leg_press.png]]
![[GYM ARC/Screenshots/plate_mmbc_closeup.png]]

## Machines are free (14 Oct)
- Every machine and every weight is free. Your main muscle's level is the only thing a heavier weight needs (as before, again after each Growth Spurt).
- No prices anywhere: the floating sign always says OCCUPY, the machine panel never shows an UNLOCK / coin button, the goal line says "135 lb is ready: press + on the panel".
- BEST WEIGHT (the MAX button) jumps straight to the heaviest weight your level allows.
- Coins already spent on weights are not refunded (owner's call).
- Tested: a brand-new save went from 45 lb to 135 lb with 38 coins and no coins were taken.
- Because heavier weights now come sooner, the Growth Spurt goals were re-tuned so each spurt still takes about the same play time (see [[GYM ARC - Config values]]).
![[GYM ARC/Screenshots/ui_compare_v2_free_weights_new_save.jpg]]

## Pro machines back in the pro gym only (21 Oct, prompt 32)
- The starter gym's 11 pro copies are gone (in `ServerStorage.StarterGymBackup.ProCopies`); `machine.openAt = 0` is removed, so these exercises open at Growth Spurt 2 again (the beach copies at 1). Dumbbell exercises stay open from the start. The starter gym has its old machines again (3 Flat Benches, 3 Squat Racks, 2 of the rest).

## Starter gym copies and dumbbells (21 Oct, prompt 16; the copies are undone by prompt 32)
- The starter gym has one copy of every pro machine (model attribute Gym = "Starter", `tools/builders/StarterProMachines`); `machine.openAt = 0` opens those exercises from the start, the pro gym's copies still need Growth Spurt 2 (`Machines.GymOpenAt`). New helper `Machines.OpenAt(machine)` for "is this exercise open anywhere".
- Dumbbells: Train spots at every rack (`tools/builders/DumbbellSpots`: small machine models, tag "Machine", attribute Dumbbell = true, MachineId = the exercise picked). The prompt opens the picker (`Shared/UI/DumbbellPicker`, action "Dumbbell" on MachineAction: the server checks the spot is free and within 14 studs, or switches the exercise on your own spot).
- 11 exercises in `Machines.Dumbbells` (ids DB*, gym "Dumbbell", tier set "Dumbbell" 10-100 lb, `gainScale` 0.85, `grip` = the hand axis the handle lies along, `hands` = 1 for one-dumbbell moves). Poses `DB_*` (Config/Poses), moves in MachineClient (`bars.dbArm` / `bars.dbBoth`).
- MachineService welds the dumbbells to the hands (folder "HeldDumbbells" on the character), resized when the weight changes and removed on leave. NPC regulars never use the spots. The sign over a spot says DUMBBELLS / TRAIN with no NEW mark.
- Machine HUD: EXERCISE button above STOP for dumbbells. Settings: `dumbbellLast` (the picker's first card).

## Starter gym re-layout (21 Oct, prompt 26; UNDONE by prompt 32)
- The starter gym now has 2 Flat Benches and 2 Squat Racks, 1 of every other machine (the extra Overhead Press, Incline Bench, Deadlift, Barbell Row, Leg Press, Hack Squat, Crunch Bench and Pull-Up Bar copies, and the third Flat Bench / Squat Rack, are in `ServerStorage.StarterGymBackup.Removed`). Zones and rows: [[GYM ARC - Town and Gyms]].
