---
date: 2026-10-04
tags: [gymarc, feature]
status: done
---
# GYM ARC - Economy and Daily Rewards

Back to [[00 GYM ARC Home|GYM ARC Home]].

One currency: coins. Earned by lifting and playing, spent on weights, shakes, cosmetics and DNA Tokens.

## How it works
- **Earning coins:**
  - Every rep (2-9 coins by weight tier)
  - Quests, legends, spotting, arm wrestling
  - Re-racking loose plates: up to 3 plates lie around the gym, 5 coins each, a new one every 90 s
  - Rush hour: every 30 minutes (same clock on every server) 3 minutes of 2x coins per rep
  - Seasonal events: x1.25 coins
- **Daily streak:** claimed automatically on the first join of each UTC day: 20 coins + 5 per streak day (up to 30 days counted). Missing a day only drops the streak 3 days per missed day (not to zero). A DNA Token on every 7th streak day.
- **Offline coins:** 0.5 coins per minute away, from 10 minutes up to 8 hours.
- **Spending:** weight tiers (5-600 coins), [[GYM ARC - Energy Shakes|Energy Shakes]] (25), cosmetics (60-900), DNA Tokens (400 at the front desk).
- **Top bar:** a coins pill on the left and a Daily Reward pill on the right.
- Everything is paid out on the server.

## Where it lives
- `Config/Economy`
- `Server/RetentionService`, `RetentionClient`
- Numbers: [[GYM ARC - Config values]]

## Planned change
- **Login streak redo** (new features prompt, task 2): a 7-day calendar with rising coin rewards, day 7 = big reward + the title "Dedicated". Missing a day resets to day 1 (today it only drops 3 days). A popup with a Claim button on join. Comes with the daily quests (see [[GYM ARC - Quests and Muscle of the Day]]).
- Monetization prompt: "2x Coins" pass and coin packs (see [[GYM ARC - Monetization]]).

## Related
[[GYM ARC - Quests and Muscle of the Day]], [[GYM ARC - Energy Shakes]], [[GYM ARC - Machines]], [[GYM ARC - Wardrobe and Gear and Fits Store]]

## Screenshots
![[GYM ARC/Screenshots/ui_v7_hud_pc.png]]
