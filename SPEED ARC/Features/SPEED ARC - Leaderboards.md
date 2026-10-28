---
date: 2026-10-28
tags: [speedarc, feature]
status: done (M4)
---
# SPEED ARC - Leaderboards

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

GDD 17, built in M4.

- **Boards** (global, OrderedDataStores): Top SPEED (all leagues: league first, then speed), Most Wins, Top SPEED per league, Fastest Sprint per area, Wins This Week, Fastest Hometown Sprint This Week.
- **Where:** two leaderboard walls on the plaza's south edge, either side of the Training Yard path (4 boards), each league area's "FASTEST HERE" board, and the TOP panel (top 25, your row in blue).
- **Weekly:** resets Monday 00:00 UTC. The first server to see the new week pays last week's top 3 for wins once: WEEKLY CHAMPION + 30 min of coins, RUNNER-UP + 20, THIRD + 10. Delivered the next time they play.
- **Reset everything:** change `Retention.Leaderboards.Version` (store names are `SpeedArcLB_v1_...`). Studio uses `SpeedArcLBStudio_...`, so tests never touch the live boards.
- **Budgets:** each player writes only changed values once a minute; boards are read one at a time, spread over the minute.

## Studio test switches
`TestWeekOffset` = weeks to add. `TestOpenWindow` = "Top".

## Where it lives
`Server/Services/LeaderboardService`, `Client/Controllers/LeaderboardController`, the wall in `tools/build_hub.luau`.
