---
date: 2026-10-13
tags: [gymarc, feature]
status: planned
---
# GYM ARC - Daily Quests

Back to [[00 GYM ARC Home|GYM ARC Home]].

Planned (new features prompt, task 2): three fresh quests per player every day, plus a 7-day login calendar. Not built yet.

## How it works (as the prompt asks)
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

## Where it lives
- Not built. Would extend `Server/QuestService` / `Server/RetentionService` and `Config` (one table per feature).

## Related
[[GYM ARC - Quests and Muscle of the Day]], [[GYM ARC - Economy and Daily Rewards]], [[GYM ARC - Titles]]
