---
date: 2026-10-23
tags: [gymarc, progress, progym]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Pro Gym rearrange and makeover (prompt 50)

Prompt: [[2026-10-23 GYM ARC Prompt - 50 Pro Gym rearrange and makeover]]

Built in Studio. Recipe: `tools/builders/ProGymMakeover` (game commit 1c6fc9f). No game scripts changed.
- **Backup before anything changed:** `ServerStorage.ProGymBackup_23Oct` (the whole Pro Gym).
- **What was taken out:** `ServerStorage.ProGymRemoved_23Oct`.

## Audit (before)

| Machine | Config | Tiers | Problem | Where |
|---|---|---|---|---|
| FlatBench | **Starter** | 45-315 | Pro skin only | west, (55,-77), facing a wall |
| SquatRack x2 | **Starter** | 45-455 | Pro skin only; a duplicate | west wall, (52,-28) and (52,-63) |
| Deadlift | **Starter** | 45-455 | Pro skin only | west wall, (54,-46) |
| HackSquat | **Starter** | 45-455 | Pro skin only | middle, (95,-35) |
| LegPress | **Starter** | 45-455 | Pro skin only | middle, (104,-43) |
| Treadmill x4 | **Starter** | 2-13 mph | Pro skin only; apart from the ProTreadmill | front, (68-84,-11) |
| DumbbellSpot1-4 (+ rack) | **Starter** (DBCurl) | 10-100 | a 2nd, non-Pro dumbbell rack | back wall, (86-96,-82) |
| ProTreadmill | Pro | 13-20 mph | **stood alone** | east corner, (143,-17) |
| ProFlatBench, ProInclineBench, ProOverheadPress | Pro | 315-455 | | east back, (120-147,-72) |
| ProSquatRack, ProHackSquat, ProLegPress | Pro | 455-665 | apart from their starter twins | east, (120-147,-31) |
| ProPullUpBar, ProBarbellRow, ProDeadlift | Pro | | apart from their starter twins | east middle, (120-147,-59) |
| ProCrunchBench | Pro | +100-205 | alone in the corner | (124,-17) |
| ProDumbbellSpot1-4 (+ rack) | Pro | 100-150 | | east back wall, (128-139,-82) |
| 11 sub-muscle machines (Shrugs, ReverseFly, LateralRaise, BicepCurl, TricepPushdown, Dips, LegCurl, CalfRaise, HipThrust, CableWoodchop, HangingLegRaise) | Pro (`gym = Pro`) | own | mixed in two rows with the starter copies | middle, (70-109, -52 / -75) |

- **Two of everything:** the old hall had starter copies with only the Pro skin; the new hall had the real Pro copies. No machine was floating or clipping.
- **Only 4 models said `Gym = "Pro"`:** the 4 starter dumbbell spots.
- **Hand-placed by you?** Nothing looked hand-placed (all matched the builders' spots), so nothing was kept aside for that.

## What changed
- **Every machine is a real Pro machine.** The starter-config copies got their Pro id (FlatBench -> ProFlatBench ...).
  - The models were identical to the Pro copies; only the id differed.
  - So now: the Pro tiers (from the starter top up), the +10% Pro Gym gains, "PRO ..." in gold on the sign.
  - The 4 starter dumbbell spots became Pro spots: 8 Pro dumbbell spots on 2 racks.
  - Every machine and spot in the hall now carries `Gym = "Pro"`. The guide's GO TO "Gym:Pro" read the old dumbbell spots, so it keeps working.
  - Starter Gym machines are untouched.
- **Sets now:**
  - 4 Pro Treadmills in one row (the 5th treadmill was taken out), plus the bike and the rower;
  - 2 Pro Flat Benches + 1 Incline, 3 Pro Squat Racks + the Overhead Press;
  - 2 Hack Squats, 2 Leg Presses, 2 Deadlifts, the Pull-Up Bar and the Barbell Row, the Crunch Bench;
  - 11 sub-muscle machines.
- **Zones** (one hall; the main aisle across the gym is ~14 studs; the other aisles ~8-10):
  - **ENTRANCE** (by the door from the Starter Gym): a black + gold PRO GYM sign wall (flexing-arm icon), the reception desk "WELCOME TO THE PRO GYM", bench, water fountain, plants. The PRO RECORDS board stays above the front windows. The door is clear.
  - **CARDIO:** the row along the front, facing the street windows; the TVs above.
  - **MACHINES** (one row facing the aisle): LEGS, BACK, ABS, each with its sign.
  - **FREE WEIGHTS** (west back): benches and racks facing the long mirror wall, both dumbbell racks on the back wall, plate trees, two chalk bowls.
  - **ELITE** (east back): the 11 sub-muscle machines in rows by body part (shoulders / arms / legs / core), under a big GYM ARC mural (black, gold, red, our own icons).
  - **STRETCH** along the east mirrors: the stretching mat (gold yoga mats), the arm wrestle table, the towel rack.
- **Look:**
  - **Floor:** black rubber mats with thin gold lines round every zone; the aisles a dark polished floor.
  - **Walls:** the wall LED strips are warm gold now, with a gold trim line on the back and east walls.
  - **Lights:** 35 hanging lamps with gold rims over the zones (only 4 cast shadows); the old spotlights over the old spots were removed.
  - **Signs:** 7 black + gold zone signs (CARDIO, LEGS, BACK, ABS, FREE WEIGHTS, ELITE, STRETCH); the spare ones went.
- **Gym-goers:** their pose / chat / rest / water spots moved with the layout.
- **Parts:** 3,079 before, 3,101 after. All new parts are Anchored, no collisions (except the desk and the sign wall) and no shadows.

## Tested (Studio, phone layout 844x390)
- Walked in from the Starter Gym door to the desk: clear path. Shot 09.
- **Pro Treadmill:** "PRO TREADMILL 13 mph, tier 1/8", facing the windows, reps counted.
- **Pro Flat Bench** (the old starter copy): "PRO FLAT BENCH 455 lb, tier 8/8", gold plates.
- **Shrugs** (ELITE): 315 lb, tier 12/12.
- All three use `gym = Pro` (x1.1 gains).
- An overlap check of every machine and prop: no overlaps, nothing in a wall, nothing in the door path.
- No script errors.

## Needs the owner
- **Big gameplay change:**
  - The starter copies in the Pro Gym are now Pro machines, so they start at the starter top weight. They also need the main muscle at level 95 (the prompt 36 rule).
  - Before, a player at Growth Spurt 2-4 could use them right away. Now, until level 95, only the 11 sub-muscle machines and the bike / rower work there.
  - This is what the brief asked for. If it makes the Pro Gym feel locked for mid players, I can lower the Pro tiers' first level.
- **The mural** uses our flexing-arm and dumbbell icons with GYM ARC text. If you want a painted mural, it needs an image (and your OK to upload).

## Not tested
- A second player and the gym-goer NPCs walking the new aisles.
- Streaming on a real phone (part count barely changed).
- 667x375 and tablet.

![[GYM ARC/Screenshots/prompt50/01_top_before.jpg]]
![[GYM ARC/Screenshots/prompt50/02_top_after.jpg]]
![[GYM ARC/Screenshots/prompt50/03_corner_before.jpg]]
![[GYM ARC/Screenshots/prompt50/04_corner_after.jpg]]
![[GYM ARC/Screenshots/prompt50/05_entrance.jpg]]
![[GYM ARC/Screenshots/prompt50/06_free_weights.jpg]]
![[GYM ARC/Screenshots/prompt50/07_elite_mural.jpg]]
![[GYM ARC/Screenshots/prompt50/08_machines_row.jpg]]
![[GYM ARC/Screenshots/prompt50/09_phone_walk_in.jpg]]
![[GYM ARC/Screenshots/prompt50/10_phone_pro_treadmill.jpg]]
![[GYM ARC/Screenshots/prompt50/11_phone_pro_flat_bench.jpg]]
![[GYM ARC/Screenshots/prompt50/12_phone_shrugs_elite.jpg]]
![[GYM ARC/Screenshots/prompt50/13_stretch_before_fix.jpg]]
