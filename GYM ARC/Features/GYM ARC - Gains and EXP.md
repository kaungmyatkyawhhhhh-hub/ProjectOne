---
date: 2026-10-07
tags: [gymarc, feature]
status: done
---
# GYM ARC - Gains and EXP

Back to [[00 GYM ARC Home|GYM ARC Home]].

How much a muscle grows per rep. The server always does the math; the client only shows it.

## How it works
- **Formula:** gains per rep = weight tier x genetics grade x frame/body bonus x Growth Spurt bonus x boosts x Muscle of the Day x diminishing factor.
- **Cap:** all stacked multipliers together are capped at 5x.
- **Diminishing:** the higher a muscle's level, the slower it grows (at level 50 it grows at half speed), so weak muscles catch up fastest.
- **Balanced bonus:** +10% when all 6 groups are within 10 levels of each other (from level 5).
- **No cap on stats:** muscles keep growing past the Growth Spurt goal; only the diminishing factor slows them.
- **PUMPED:** tapping fills the pump meter (16 taps); when full you get 8 s of double gains and faster reps.
- **BIG REP:** about 1 in 12 reps counts triple (gold number). PUMPED and BIG REP sit outside the 5x cap.
- **EXP shown:** every number on screen is EXP. The first Growth Spurt needs exactly 50,000 EXP per group.
- **Anti-cheat:** the server allows at most about 1.35 reps per second (with a small burst for lag).
- **Workout together:** +10% gains when lifting within 30 studs of another lifter.

## Where it lives
- `Config/Gains`, `Config/Muscles` (EXP curve), `Config/MuscleOfTheDay`, `Config/Genetics`
- `Server/MachineService`, `Server/BoostService`
- Tests: `tests/exp`, `tests/pacing`
- Numbers: [[GYM ARC - Config values]]

## Known issues
- Rep and set popups show big numbers (3,000+ EXP at the start); easy to scale down in `Muscles.ExpPerXp` if too loud.
- After about 11 Growth Spurts each spurt takes a few minutes longer (the permanent bonus hits the 5x cap).

## Planned change
- Monetization prompt: a "2x EXP" game pass (see [[GYM ARC - Monetization]]).
- New features prompt: smoothie bar items like Protein Shake (+20% EXP for 5 min) and Chicken and Rice (see [[GYM ARC - Energy Shakes]]).

## Related
[[GYM ARC - Machines]], [[GYM ARC - Genetics]], [[GYM ARC - Growth Spurts]], [[GYM ARC - Game Feel]]

## Screenshots
![[GYM ARC/Screenshots/exp_popups_flatbench.png]]
![[GYM ARC/Screenshots/look_2x_stats_sum.png]]
