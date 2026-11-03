---
date: 2026-11-03
tags: [gymarc, pacing, hall-of-fame, trainers]
status: DECIDED 3 Nov - no pace changes
---
# Pace by star with realistic trainers (3 Nov)

Full table, assumptions and raw numbers: [[2026-11-03 Pace by star - realistic trainers]] (folder `GYM ARC\Calc`, with the CSV and `pace_sim.luau`). Design targets: [[2026-10-29 GYM ARC Hall of Fame - good or bad]].

Owner asked for realistic trainers per star (not 2 Voltas forever), no pass. Everyone has Pro belt + Pro wraps from Alter 1 (owner, 3 Nov; +10% EXP, moves the runs only 1-2%):
- ★0-2: 2 Voltas.
- ★3-5: 2 Hall of Fame Mythics.
- ★6-9: the same Mythics (the agency's best non-Secret).
- ★10: 2 Hall of Fame Secrets.
- Plus the owner's own maxed setup.

## Trainer values (Config/Trainers, BASE LV 20 = x1.10)
| Trainer | Base perk | 2 of them |
|---|---|---|
| Volta (Legendary) | +35% EXP, +9% progress | +77% EXP, +19.8% progress |
| The Bronze Titan (HoF Mythic) | +140% EXP, +25% progress | +308% EXP, +55% progress |
| Heracles (HoF Secret) | +220% EXP, +40% progress | +484% EXP, +88% progress |
| Owner: 4 x Atlas LIMITLESS LV 20 | +150% EXP, +30% progress each (x2.2) | **+800% EXP (the cap)**, +264% progress, + Void aura, all-S genetics (x1.5), Pro gear, 2x pass |

## Run time (Growth Spurts + Alters 1-15 + the Hall of Fame goal)
| Setup | Lifting min | Real, est. (x2.35) | Design target | Flag |
|---|---|---|---|---|
| ★0, 2 Voltas | 228 | ~8.9 h | ~8 h | - |
| ★1, 2 Voltas | 107 | ~4.2 h | ~3 h | - |
| ★3, 2 Titans | 50 | ~1.9 h | ~2 h | - |
| ★5, 2 Titans | 42 | ~1.7 h | ~1.5 h | **too fast** (lifting < 45) |
| ★10, 2 Heracles | 23 | ~0.9 h | ~1 h | **too fast** (lifting < 45) |
| **Owner maxed (★4)** | **12** | **~27 min** | - | **too fast** (lifting and real) |
Per alter (lifting minutes), ★0: about 10-13 for Alters 1-13, 20 / 28 for 14 / 15, 27-31 for 16-20. ★3: about 2-3, then 4-6. Owner: under 1 min every alter.

## What it means
- With the Hall of Fame agency's trainers, runs ★3-10 land close to the design's real-time targets (2 h → 1 h).
- In pure lifting, though, ★5 and ★10 are under 45 min.
- The owner's account is the outlier: +800% trainers (the cap) x the stars' EXP x S genetics x the 2x pass gives a whole run in ~12 lifting minutes. That's what "skip all 15 after 15 min" was.
- **The two biggest levers:**
  - The trainer EXP cap (+800%).
  - The star EXP: it multiplies on top of the trainers' total, outside the cap.
- The Gem Mine opening at star 1 doesn't speed runs up (tested).
- Nothing was changed. Owner's call.

## What the run measures + Alter 20 + skipping (owner, 3 Nov; report only)
- **The run table above = a whole run from the start:** muscles 0, the star's starting Growth Spurt -> every Growth Spurt -> Alters 1-15 one by one -> the Hall of Fame goal. It is NOT "Alter 1 -> Alter 15" (it includes the Growth Spurts before Alter 1 and the Hall of Fame goal after 15).
- New columns: start -> Alter 15 and start -> Alter 20 (Gem alters 16-20), no Hall of Fame goal. Pro gear from Alter 1. Lifting minutes.
- Skip needs ★1 now, so ★0 has no skip column. Two skip ways were simulated:
  - "Skip to 15": train without altering until you can jump straight to Alter 15 (2.5x its goal), then 16-20 one by one.
  - "Skip to 20": jump straight to Alter 20.

| Row | One by one: to 15 | One by one: to 20 | Skip to 15: to 15 | Skip to 15: to 20 | Skip to 20 |
|---|---|---|---|---|---|
| ★0, 2 Voltas | 201 | 343 | - | - | - |
| ★1, 2 Voltas | 94 | 166 | 90 | 161 | 126 |
| ★3, 2 Titans | 44 | 72 | 36 | 64 | 49 |
| ★5, 2 Titans | 38 | 62 | 29 | 53 | 41 |
| ★10, 2 Heracles | 21 | 31 | 13 | 23 | 18 |

- **Skipping is FASTER, not slower.** The 1 Nov estimate said skip-all costs ~2.4x the effort, but that only counted EXP. Skipping keeps your muscles big, so you keep using the heaviest weights. Altering one by one drops you to 25% and back to lighter weights each time. Biggest gain: going straight to Alter 20 (★3: 72 -> 49 min).

## Owner's decision (3 Nov)
- **No pace changes.** Skipping straight to 20 being fastest is fine (it's a ★1+ reward). Don't nerf skipping or anything players own.
- ★1 to Alter 15 with skip (~90 lifting min) is close enough: no ★1 boost.
- **Rebirth still unlocks at Alter 15 (checked in Studio, nothing changed):**
  - `HallOfFame.RequiredAlter = 15`.
  - `CanEnter` = Alter 15 or past it + the Hall of Fame goal (the training goal after Alter 15 that has always been there).
  - The server checks the same rule (PlayerData:EnterHallOfFame, HallOfFameService).
  - Nothing requires Alter 20. Alter 20 (`BonusAlter`) only raises the reward: 2 stars instead of 1, and 1 extra Legacy card.
