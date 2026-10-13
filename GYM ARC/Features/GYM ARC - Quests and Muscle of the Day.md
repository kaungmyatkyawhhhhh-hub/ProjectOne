---
date: 2026-10-07
tags: [gymarc, feature]
status: done
---
# GYM ARC - Quests and Muscle of the Day

Back to [[00 GYM ARC Home|GYM ARC Home]].

Coach Dex hands out quests at the front desk, and one muscle group trains at double gains each day.

## How it works
- **Coach Dex:** stands behind the front desk. Talk to him to get a quest; finish it and talk again for the reward and the next one.
- **Quest chain (played once, in order):** 12 quests from "Do 10 reps on any machine" through leg day, going heavier, back day, pull-ups, chest EXP, shoulders, crunches, every muscle to a level, earn 3 titles, 200 reps, and "Do your first Growth Spurt".
- **Repeatables (after the chain, in a loop):** 100 reps, squat/deadlift reps, bench reps, pull reps, 15 leg presses, 15 hack squats.
- **Rewards:** coins, sometimes shakes or a DNA Token.
- **Quest tracker:** a small panel at the top right, hidden while training. A Quests pill in the top bar.
- **Muscle of the Day:** one group gets 2x gains for the whole UTC day, the same on every server. Shown on the chalkboard next to the front desk and as a chip on the menu.

## Where it lives
- `Config/Quests`, `Config/MuscleOfTheDay`
- `Server/QuestService`, `Server/MuscleOfTheDayService`, `QuestClient`
- Builder: `tools/builders/NPCs` (Coach Dex)

## Planned change
- New features prompt adds 3 **daily quests** per player with a Quests panel and Claim buttons (see [[GYM ARC - Daily Quests]]).

## Related
[[GYM ARC - Tutorial]], [[GYM ARC - Legend NPCs]], [[GYM ARC - Economy and Daily Rewards]], [[GYM ARC - Gains and EXP]]

## Screenshots
![[GYM ARC/Screenshots/coach-talk_fixed.png]]
![[GYM ARC/Screenshots/s2_reception_after.png]]
