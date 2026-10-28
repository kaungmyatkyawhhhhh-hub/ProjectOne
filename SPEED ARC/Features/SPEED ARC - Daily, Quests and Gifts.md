---
date: 2026-10-28
tags: [speedarc, feature]
status: done (M4)
---
# SPEED ARC - Daily, Quests and Gifts

> **Prompt 11 (28 Oct):** quests "Take 500 steps", "Take 1,500 steps", "Smash 5 walls", "Smash 12 walls" replace the tap quests (the stats are `Steps` and `Smashes`). Gift and invite boosts say "2x SPEED" / "+10% SPEED".

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

GDD 15, built in M4. Days are UTC days. All numbers in `Config/Retention`.

## Daily streak
- 7 days: 2 / 3 / 4 / 4 + coach roll / 5 / 6 / 8 minutes of coins; day 7 also gives the **Sunrise** trail the first time (later day 7s give 2 rolls).
- **One missed day is OK** (the UTC day changes in the US afternoon); two missed days restart the streak.
- The window shows what tomorrow gives, and opens by itself once a session when you're free (never in the tutorial). The DAILY button has a red dot when it's ready.
- After the first claim: Roblox's notifications opt-in prompt.

## Daily quests
- 3 a day from 9 (win 1, race 3 / 5, train 300 / 800 taps, a new PB, top 3 twice, BOOST 15 times, roll a coach), never two of the same kind.
- Each pays 3 min of coins; all 3 = 10 min + a coach roll.
- Finished but not claimed when the day ends = paid automatically ("QUESTS PAID").

## Playtime gifts
- At 3 / 8 / 15 / 25 / 40 / 60 min of play today: 1 min coins / 2 min / 2x training for 5 min / 4 min / 6 min / a coach roll.
- Paid at once; the popup ("GIFT 1 OF 6") waits until you're free and names the next one.

## Popups
One queue for everything (gifts, notices, the daily window): one at a time, only off a station, not racing, no window open, no tutorial hint.

## Studio test switches
`TestDayOffset` = days to add to the clock. `TestOpenWindow` = "Daily" / "Quests".

## Where it lives
`Server/Services/RetentionService`, `Server/Services/SessionBoosts` (2x boosts), `Client/Controllers/RetentionController`.
