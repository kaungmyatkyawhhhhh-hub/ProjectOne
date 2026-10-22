---
tags: [gymarc, feature]
status: built
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Pro Gym expansion

Built 22 Oct ([[2026-10-21 GYM ARC Prompt - 36 Pro Gym expansion heavier machines|prompt 36]]).

## Lights, windows, city view (23 Oct, prompt 58; [[2026-10-23 GYM ARC Pro Gym lights and Powerlifting Gym]])
- Opens at **Growth Spurt 3** now (was 2); players who had trained there at Spurt 2 keep it.
- White light everywhere (gold only as metal trim), no reception desk (bench + plants), white linear ceiling fixtures, LED under the mirror, spots on ELITE / stretch, a slight cool colour inside.
- East wall and front wall floor-to-ceiling glass; below the east side a valley city (client-side backdrop, lit at night). Canopy + white-lit PRO GYM sign outside.
- Builders `ProGymLights`, `ProGymValley`, `ProGymCity`; backup `ServerStorage.ProGymBackup_23Oct_b`.

## Rearrange and makeover (23 Oct, prompt 50; [[2026-10-23 GYM ARC Pro Gym rearrange and makeover]])
- Every machine in the Pro Gym is a real Pro machine now (the starter-config copies with the Pro skin got their Pro id: Pro tiers, +10%); every machine carries `Gym = "Pro"`.
- Zones: ENTRANCE (PRO GYM sign wall, desk), CARDIO row (4 Pro Treadmills, bike, rower) facing the windows, a MACHINES row (LEGS / BACK / ABS), FREE WEIGHTS at the mirror wall (2 Pro dumbbell racks, 8 spots), ELITE (the 11 sub-muscle machines) under a GYM ARC mural, STRETCH by the east mirrors. Black rubber mats with gold lines, hanging lamps, gold LEDs. Recipe `tools/builders/ProGymMakeover`; backup `ServerStorage.ProGymBackup_23Oct`.

## Prompt 47 (22 Oct)
- ONE hall: the wall between the two rooms is gone (pieces in `ServerStorage.ProGymExpansionBackup`); the GYM ARC PRO sign, mirror, TVs, speakers, lockers moved to the new east wall.
- Every Pro Gym machine has the PRO look (black satin, gold accents, chrome bars, gold-stitched pads, PRO badge, gold underglow; the underglow is soft white since prompt 58), gold plates, "PRO" in gold on its sign.

## Check first (what the starter machines really go to)
- **Starter Gym machines:** Flat Bench, Incline Bench, Overhead Press, Barbell Row (Barbell set: 45 to **315** lb); Squat Rack, Deadlift (Heavy set: 45 to **455**); Leg Press, Hack Squat (Sled set: 45 to **455**); Pull-Up Bar, Crunch Bench (bodyweight to **+100**); Treadmill (2 to 13 mph); dumbbell rack (10 to **100** lb). 12 tiers each.
- So the top is 315 on the benches, press and row, but **455** on squat, deadlift and the sleds (not ~300 everywhere).
- **Steps** between tiers are uneven: 20 to 40 lb (mostly 20 or 30) on the bars, 5 on bodyweight, 5 to 15 on dumbbells.

## The new hall
- The Pro Gym is 40 studs longer to the east (a new hall `ProGym.ShellEast`, same look: black concrete, rubber floor, LED seams and light bars, glass front, mirrors on the east wall, spotlights over each machine). Nothing in the old hall moved.
- **Way in:** an opening in the old east wall right under the GYM ARC PRO neon sign, between the mirror and the hanging leg raise.
- Outside it's one building (parapet and roof seams carried over). The trees and bushes that stood there are in `ServerStorage.ProGymExpansionBackup` (with the old wall piece, panels and parapet), the hill inside was cut down to the floor.
- **Layout** (zone signs over each group, a wide cross aisle through the entrance): ARMS = the Pro dumbbell rack on the back wall; CHEST (Pro Flat Bench, Pro Incline Bench) + SHOULDERS (Pro Overhead Press); BACK (Pro Pull-Up Bar, Pro Barbell Row, Pro Deadlift); LEGS (Pro Squat Rack, Pro Hack Squat, Pro Leg Press); ABS (Pro Crunch Bench); CARDIO (Pro Treadmill).

## Pro machines (`Config/Machines`)
- A copy of every starter machine (`ProFlatBench` ...; `base` = the starter id, so quests, gear perks, rivals and spotting count it as that machine) and a Pro dumbbell rack (spots with `DumbbellSet = "Pro"`, picker titled PRO DUMBBELLS). Same exercise and animation, chrome + black + gold look, copies of the starter models (no new meshes; about 650 parts, streaming loads them only nearby).
- **Tiers** start at the starter top and go 8 tiers up (`Machines.ProProgression`: EXP x8.2 to x21.7, +15% a tier like the starter's top; levels 95 to 178):
  - bars 315 to 455 (steps of 20; 435 = 55+55+55+25+5 a side), squat / deadlift / sleds 455 to 665 (steps of 30), bodyweight +100 to +205, dumbbells 100 to 150, treadmill 13 to 20 mph.
- **Locked below its first weight:** a Pro copy needs the starter top's level (95) on its main muscle; until then it says "Pro Flat Bench starts at 315 lb. Needs Chest level 95: train on the starter machines first."
- **+10% gains in the Pro Gym** (`Machines.GymGains`, new: the plan's "+10% per gym") on every Pro Gym machine (the sub-muscle machines too).
- Starter machines unchanged.

## Pacing (needs your OK if you disagree)
The heavier Pro tiers made Growth Spurts 5 and 6 about 15% faster (39 and 37 min instead of 45). Like on 14 Oct (free weights), their goals were retuned with tests/pacing so they take ~45 min again: **Spurt 5 goal 164 -> 191, Spurt 6 goal 178 -> 216** (`Config/GrowthSpurts`). Spurts 1-4 unchanged. If you'd rather keep the faster late spurts, put 164 / 178 back.

## Tested
Spurt 3 test save: Pro Flat Bench 355 lb, after a few sets "NEW 375 lb" and it moved up; Pro Squat Rack 515 lb, then "NEW 545 lb" (tier 4 / 8, plates loaded). Pacing test: see the batch note.
