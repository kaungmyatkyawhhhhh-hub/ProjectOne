---
date: 2026-11-03
tags: [gymarc, calc, pacing, hall-of-fame, trainers]
status: report only - no numbers changed
---
# Pace by star with realistic trainers (3 Nov)

Owner: "Redo the pace table with REALISTIC trainers per star (not 2 Voltas forever) ... Show minutes per alter 1-20 and total run time for ★0, 1, 3, 5, 10, plus the owner's maxed setup. Use the real boost values from the trainer config (say them). Flag any run under 45 min as too fast. Don't change any numbers - report only."
Summary note: [[2026-11-03 GYM ARC Pace by star - realistic trainers]]. Raw numbers: `2026-11-03 Pace by star - realistic trainers.csv`. The sim: `pace_sim.luau` (run in Studio, Edit).

## The trainers (real values, Config/Trainers, 3 Nov)
A trainer's boost = its base perk x its stage (BASE x1 ... LIMITLESS x2) x its level (LV 1 +0% ... LV 20 +10%). EXP boost cap +800% (`Trainers.BoostCap` 8). Rolled trainers are BASE; they reach LV 20 in ~20-30 min of following you, so **BASE LV 20 (x1.10)** is used.
| Stars | Trainers (2 slots, no pass) | Base perk each | At BASE LV 20, the pair |
|---|---|---|---|
| ★0-2 | 2 x **Volta** (Legendary, Trainer Agency) | +35% EXP, +9% progress | **+77% EXP, +19.8% progress** |
| ★3-5 | 2 x **The Bronze Titan** (Mythic, Hall of Fame agency) | +140% EXP, +25% progress | **+308% EXP, +55% progress** |
| ★6-9 | 2 x The Bronze Titan (the agency's best non-Secret is Mythic) | same | same as ★3-5 |
| ★10 | 2 x **Heracles** (Secret, Hall of Fame agency) | +220% EXP, +40% progress | **+484% EXP, +88% progress** |
| Owner (★4, his real save) | 4 x **Atlas** (AeonCoach) LIMITLESS LV 20 (x2.2) + Void aura + all-S genetics + Pro belt/wraps + 2x pass | +150% EXP, +30% progress each | +1,320% EXP -> **capped +800%** (+10% Void, +10% gear), **+264% progress** (+10% Void), genetics S = x1.5 EXP, pass x2 |
Stars add their own EXP (★1 x2, ★3 x2.5, ★4 x2.75, ★5 x3, ★10 x4.5) and start at Growth Spurt 3 (★1-3), 4 (★4-9), 5 (★10). Normal players: genetics B (the starter's). **Pro belt + Pro wraps from Alter 1 on** (owner, 3 Nov: "everyone starting from alter 1 has pro gear"): +10% added to the EXP boost, next to the trainers (MachineService: boost + gear - 1); starred runs keep their gear, so the whole run. (It moves the runs 1-2%: +10% next to +77% to +484%.)

## How it was measured
Rep-by-rep sim on the LIVE config (the same rules as the 1 Nov calibration, [[2026-11-01 GYM ARC Alter pacing - normal player has 2 Voltas]]): one rep every 1.05 s, the heaviest weight the level allows, the best open machine for the weakest muscle of the group furthest from the goal, Balanced +10%, each gym's bonus (Pro x1.1, Powerlifting x1.2, Golden Era x1.2 more from Alter 8, Gem Mine x1.3), alters one by one (no skip), each alter keeps 25%, the Hall of Fame goal after Alter 15. A starred run starts from 0 muscles at the star's Growth Spurt with every kept gym open (like the real Hall of Fame).
**Not counted:** Muscle of the Day, PUMPED, BIG REP, Run Cards / Legacy cards, boosts bought, walking and menus. So the minutes are **pure lifting**. "Real, est." = lifting x 2.35 (the 1 Nov calibration: approved 75 real min for Alter 15 = 31.9 lifting min) - a rough guide only.
**Run** = Growth Spurts + Alters 1-15 + the Hall of Fame goal (Alters 16-20 shown for keeping going; they're not in the run).

## Minutes per alter (lifting minutes)
| Setup | Spurts | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | HoF goal | **Run (lifting)** | Run (real, est.) | Flag |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ★0 · 2 Voltas | 13.4 | 6.7 | 13.2 | 11.3 | 11.5 | 10.5 | 10.6 | 12.0 | 12.0 | 9.9 | 10.2 | 10.2 | 11.1 | 11.5 | 19.5 | 27.2 | 26.7 | 27.6 | 28.6 | 29.3 | 30.2 | 26.7 | **227.5** | 535 (8.9 h) | - |
| ★1 · 2 Voltas | 4.1 | 2.5 | 5.2 | 5.2 | 5.2 | 4.8 | 4.9 | 5.2 | 5.5 | 5.2 | 5.5 | 5.2 | 5.7 | 5.9 | 9.8 | 14.1 | 13.4 | 14.0 | 14.3 | 14.8 | 15.4 | 13.4 | **107.4** | 252 (4.2 h) | - |
| ★3 · 2 Bronze Titans | 2.1 | 1.4 | 2.7 | 2.4 | 2.5 | 2.7 | 2.5 | 2.7 | 2.8 | 2.7 | 2.5 | 2.5 | 2.7 | 2.7 | 4.1 | 5.5 | 5.3 | 5.5 | 5.6 | 5.7 | 6.0 | 5.3 | **49.8** | 117 (2.0 h) | - |
| ★5 · 2 Bronze Titans | 1.5 | 1.4 | 2.5 | 2.2 | 2.4 | 2.4 | 2.0 | 2.1 | 2.2 | 2.0 | 2.5 | 2.0 | 2.2 | 2.4 | 3.5 | 4.6 | 4.2 | 4.8 | 4.9 | 4.9 | 5.0 | 4.2 | **42.1** | 99 (1.6 h) | **TOO FAST** (lifting < 45) |
| ★10 · 2 Heracles | 1.0 | 0.6 | 1.5 | 1.4 | 1.3 | 1.1 | 1.3 | 1.4 | 1.3 | 1.5 | 1.0 | 1.3 | 1.3 | 1.3 | 1.7 | 2.0 | 2.0 | 2.0 | 2.1 | 2.2 | 2.2 | 2.0 | **23.0** | 54 (0.9 h) | **TOO FAST** (lifting < 45) |
| Owner maxed (★4) | 0.6 | 0.4 | 0.7 | 0.8 | 0.6 | 0.8 | 0.6 | 0.7 | 0.7 | 0.7 | 0.6 | 0.6 | 0.6 | 0.6 | 1.0 | 0.8 | 0.8 | 0.7 | 0.8 | 0.6 | 1.0 | 0.8 | **11.6** | 27 (0.5 h) | **TOO FAST** (lifting < 45) / **TOO FAST** (real < 45) |

## What it says
- **Run 2 (★1) is ~2x faster than run 1** (228 -> 107 lifting min): the x2 star EXP + starting at Growth Spurt 3. Real ~4.3 h vs the design's ~3 h.
- **★3 and ★5 with 2 Hall of Fame Mythics: ~50 and ~42 lifting min** (real ~2 h / ~1.7 h): about the design's 2 h / 1.5 h. ★5 is just under 45 lifting min.
- **★10 with 2 Secrets: ~23 lifting min** (real ~53 min): the design's 1 h floor, but under 45 lifting min.
- **The owner's maxed setup: ~12 lifting min for a whole run** (real ~27 min), every alter under 1 min. This is why "after 3 stars I could skip all 15 after 15 min": the trainers alone are +800% (the cap), on top of x2.75 stars, S genetics and the 2x pass.
- What drives it: the trainer EXP (+77% -> +308% -> +484% -> the +800% cap) multiplied by the star EXP (both stack: the star EXP sits outside the trainer total). The Gem Mine opening from star 1 changes nothing here (tested: same times with it closed until Alter 15; at low levels its weights give no more than the Powerlifting ones).
- Flagged (< 45 min): ★5 (lifting), ★10 (lifting), the owner's setup (lifting and real).
