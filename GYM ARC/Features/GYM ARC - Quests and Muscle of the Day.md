---
date: 2026-10-07
tags: [gymarc, feature]
status: done
aliases: ["GYM ARC - Daily Quests"]
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
- New features prompt adds 3 **daily quests** per player with a Quests panel and Claim buttons, plus a 7-day login calendar (see "Daily Quests (planned)" below).

## Daily Quests (planned)

Planned (new features prompt, task 2): three fresh quests per player every day, plus a 7-day login calendar. Not built yet.

### How it works (as the prompt asks)
- **3 daily quests** per player from a pool in Config, reset at 00:00 UTC. Examples:
  - 50 reps on any chest machine / 50 leg reps / 100 reps total
  - Spot another player 2 times
  - Run 1 km on the treadmill
  - Enter a posing competition
  - Win an arm wrestle
  - Train 3 different muscle groups
- **Tracking:** automatic, from the existing rep / EXP events.
- **Quests panel:** a small panel in the existing menu style, one button on the HUD side bar, progress bars and a Claim button. Coins as the reward; completing all 3 gives an extra reward.
- **Empty server:** quests that need another player (spotting) get another way to finish, for example a swap button once per day.
- **Login streak:** 7-day calendar with rising coin rewards, day 7 = big reward + the title "Dedicated". Missing a day resets to day 1. Popup on join with a Claim button. Saved per player.
- Monetization prompt: the VIP pass gives +1 daily quest reroll.

### Where it lives
- Not built. Would extend `Server/QuestService` / `Server/RetentionService` and `Config` (one table per feature).


## Related
[[GYM ARC - Tutorial]], [[GYM ARC - Legend NPCs]], [[GYM ARC - Economy and Daily Rewards]], [[GYM ARC - Gains and EXP]]

## Screenshots
![[GYM ARC/Screenshots/coach-talk_fixed.png]]
![[GYM ARC/Screenshots/s2_reception_after.png]]
