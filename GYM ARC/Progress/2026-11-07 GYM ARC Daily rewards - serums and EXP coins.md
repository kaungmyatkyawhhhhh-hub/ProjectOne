---
date: 2026-11-07
tags: [gymarc, progress, economy, retention]
status: done (Studio, not published)
---
# Daily rewards: serums + coins by total EXP (7 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]]. Feature: [[GYM ARC - Economy and Daily Rewards]].

Owner: "make daily rewards better by putting TITAN SERUM as day 7 reward and MONSTER MIX as day 4 reward and BEAST FORMULA as day 2 reward and make the coins higher depending on the players total xp, maxxing out daily reward coins at 25000".

## What changed
- **Serums (into the Boosts inventory, `Config/Boosts.LoginItems`):** day 2 BEAST FORMULA (replaces the Coconut Water), day 4 MONSTER MIX, day 7 TITAN SERUM. Days 4 and 7 keep their DNA token; day 5 keeps its Creatine.
- **Coins by total EXP (`Config/Economy.LoginScale`, `LoginMultiplier`, `LoginReward`):**
  - Total EXP = lifetime EXP (`Muscles.LifetimeExp`). It never drops, so an alter or the Hall of Fame never lowers the daily coins.
  - Up to 50K EXP (about Growth Spurt 1) each day pays its old base. Above that, every day grows by the same factor on a log scale until 2B EXP (about Alter 15 / the Hall of Fame goal), where day 7 pays 25,000.
  - Nothing ever pays more than 25,000. Days 1-6 keep their share of day 7 (the ladder stays). Rounded to 10.

| Total EXP | Day 1 | Day 2 | Day 3 | Day 4 | Day 5 | Day 6 | Day 7 |
|---|---|---|---|---|---|---|---|
| 0-50K | 100 | 150 | 200 | 300 | 400 | 500 | 1,500 |
| 500K | 440 | 660 | 880 | 1,320 | 1,760 | 2,200 | 6,610 |
| 5M | 780 | 1,170 | 1,560 | 2,340 | 3,120 | 3,900 | 11,710 |
| 50M | 1,120 | 1,680 | 2,240 | 3,360 | 4,490 | 5,610 | 16,820 |
| 500M | 1,460 | 2,190 | 2,920 | 4,390 | 5,850 | 7,310 | 21,930 |
| 2B and up | 1,670 | 2,500 | 3,330 | 5,000 | 6,670 | 8,330 | **25,000** |

- **Calendar window (`DailyClient`):** days 4 and 7 show the DNA token and the serum picture side by side, each with "+1". Day 2 shows BEAST FORMULA. The line under the tiles: "Serums on days 2, 4 and 7, DNA tokens on 4 and 7. Coins grow with your EXP. Miss two days and it starts over." After claiming: "TOMORROW: +X COINS + DNA + TITAN SERUM".
- The server pays from the same formula (`DailyService` passes the save), so the tile and the payout always match.

## Tests (Studio, FreshPlayer = temporary data, nothing saved)
- 5M EXP, day 7: +11,710 coins, +1 TITAN SERUM, +1 DNA (as the tile said).
- 10B EXP: day 4 +5,000 + MONSTER MIX + DNA; day 2 +2,500 + BEAST FORMULA; day 7 +25,000 (the cap) + TITAN SERUM + DNA.
- PC + phone (667x375) screenshots, no console errors.

## Screenshots
![[GYM ARC/Screenshots/2026-11-07_daily_rewards/01_pc_calendar_5M_exp.jpg]]
![[GYM ARC/Screenshots/2026-11-07_daily_rewards/02_pc_day7_claimed_5M.jpg]]
![[GYM ARC/Screenshots/2026-11-07_daily_rewards/03_pc_calendar_10B_exp_capped.jpg]]
![[GYM ARC/Screenshots/2026-11-07_daily_rewards/04_phone_calendar_10B.jpg]]

## Owner to do
- File > Save to Roblox, then publish.
