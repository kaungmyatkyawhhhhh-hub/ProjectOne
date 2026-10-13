---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Growth Spurts

Back to [[00 GYM ARC Home|GYM ARC Home]].

The rebirth system (never called "sacrifice"): when all 6 muscle groups hit the goal, muscles reset, you get taller and earn a permanent gains bonus. Height stops at exactly 7'0".

## How it works
- **Start:** Growth Spurt 0, 4'0" tall (release setting since 9 Oct).
- **Goal:** every group must reach the required level. The first one is 50,000 EXP per group and takes about 8 minutes.
- **Stages:**
  - 1: 4'6", gains x1.25
  - 2: 5'0", x1.5 (opens the pro gym)
  - 3: 5'6", x1.75
  - 4: 6'0", x2
  - 5: 6'6", x2.5
  - 6: 7'0", x3 (the last one)
- **Pacing targets:** 8, 15, 25, 35, 45 minutes per spurt (checked by a simulation test).
- **What you get:** taller body, permanent bonus, +1 DNA Token. Muscles reset to 0. A "you grew" moment plays.
- **7'0" cap (13 Oct):** no spurt ever goes past 7'0". At the cap the button reads "MAX GROWTH SPURT REACHED" (greyed, not pressable, nothing charged), heights show "7'0" (MAX)", and muscles keep growing. Old saves past spurt 6 are shown at 7'0".
- **Unlocks by spurt:** beach gym at 1, pro gym at 2.
- **Progress bar:** an always-visible Growth Spurt bar at the top with a "next goal" line.

## Where it lives
- `Config/GrowthSpurts` (`MaxHeightInches = 84`, `Stages`, `Targets`)
- `Server/PlayerData` (GrowthSpurt), `Server/BodyService` (height), `ProgressClient`, `StatsClient`
- Tests: `tests/pacing`
- Numbers: [[GYM ARC - Config values]]

## Known issues
- After about 11 spurts each spurt takes longer (the 5x multiplier cap). With the 7'0" cap there are now only 6 spurts, so this mostly no longer applies.

## Planned change
- Monetization prompt: a "Skip Growth Spurt cooldown" product, only if there is a cooldown (there is none today) and never past 7'0".

## Related
[[GYM ARC - Muscles and Bodies]], [[GYM ARC - Stats and Muscles Panel]], [[GYM ARC - Town and Gyms]], [[GYM ARC - Titles]]

## Screenshots
![[GYM ARC/Screenshots/full_spurt_ready.png]]
![[GYM ARC/Screenshots/full_spurt_done.png]]
![[GYM ARC/Screenshots/s1_you-grew_after.png]]
![[GYM ARC/Screenshots/body_7ft_max_front.png]]
