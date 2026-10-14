---
date: 2026-10-13
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
- **Login streak (13 Oct, replaces the old automatic streak):** a 7-day calendar. Join each UTC day and press CLAIM: 25 / 35 / 50 / 70 / 90 / 120 / 300 coins. Day 7 also gives a DNA token and (the first time) the title "Dedicated", then the calendar starts over. Missing a day starts again at day 1. The calendar card pops up after Play when today's reward is waiting; the Daily pill opens it too (a dot when unclaimed).
- **Offline coins:** 0.5 coins per minute away, from 10 minutes up to 8 hours.
- **Spending:** weight tiers (5-600 coins), [[GYM ARC - Energy Shakes|Energy Shakes]] (25), cosmetics (60-900), DNA Tokens (400 at the front desk).
- **Top bar:** a coins pill on the left and the Daily pill (login calendar) on the right.
- Everything is paid out on the server.

## Where it lives
- `Config/Economy`
- `Server/RetentionService`, `RetentionClient` (offline coins, loose plates, rush hour); the login calendar: `Server/DailyService`, `DailyClient`
- Numbers: [[GYM ARC - Config values]]

## Planned change
- Monetization prompt: "2x Coins" pass and coin packs (see [[GYM ARC - Monetization]]).

## History
- Before 13 Oct the daily streak was paid automatically on join (20 coins + 5 per streak day, up to 30 days), missing a day only took 3 days off the streak, and a DNA token came every 7th streak day.

## Related
[[GYM ARC - Quests and Muscle of the Day]], [[GYM ARC - Energy Shakes]], [[GYM ARC - Machines]], [[GYM ARC - Wardrobe and Gear and Fits Store]]

## Screenshots
![[GYM ARC/Screenshots/ui_v7_hud_pc.png]]
![[GYM ARC/Screenshots/streak_popup_day1.jpg]]
![[GYM ARC/Screenshots/streak_popup_day7.jpg]]

## DNA tokens (14 Oct)
Day 7 of the login calendar no longer gives a DNA token (only coins and, the first time, the "Dedicated" title). The front desk no longer sells tokens; they cost 25,000 coins in the Shop or on the Genetics screen. See [[GYM ARC - Genetics]].
