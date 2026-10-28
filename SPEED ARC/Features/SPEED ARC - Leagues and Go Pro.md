---
date: 2026-10-28
tags: [speedarc, feature]
status: done (M3)
---
# SPEED ARC - Leagues and Go Pro

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

## Leagues
| League | Area | Opens |
|---|---|---|
| 1 | Hometown Track (hub) | from the start |
| 2 | [[SPEED ARC - City Park]] | Go Pro from League 1 |
| 3 | [[SPEED ARC - Big Stadium]] | Go Pro from League 2 |
| 4-5 | Mountain Trail, World Games | COMING SOON gates (updates 1 and 2) |

## Ranks
- Bronze, Silver, Gold, Platinum, Champion in every league. SPEED thresholds are in `Config/Ranks`:
  - L1: 0 / 3.8K / 20K / 36K / 70K MPH
  - L2: 0 / 4M / 16M / 40M / 80M
  - L3: 0 / 1.8B / 7.5B / 18B / 36B
  - (re-tuned in prompt 4 with the New Runner boost, gifts, daily and quests; Silver at ~5 min)
- Badge under the coins (rank letter + LEAGUE X) and a tag over your head.
- Rank up: popup, rising sound, gold ring on the ground, coins = 1 / 2 / 3 / 5 minutes of coins (Silver / Gold / Platinum / Champion), only the first time you reach a rank in a league.

## Go Pro
- **Needs:** Champion + race wins in your league: 1 (L1), 2 (L2), 3 (L3).
- **Then:** big gold GO PRO button and a Coach Benji line. The HUD goal line says "GO PRO is ready!".
- **Confirm screen:** YOU KEEP (coins, shoes, trails, coaches, medals, titles, purchases) / YOU RESET (SPEED to 0, rank to Bronze) / YOU GET (the new area, x8 training forever, a free coach roll, a title).
- **Moment:** ~4 s gold cutscene (SKIP after the first time), teleport, arrival banner.
- **Titles:** PARK RUNNER (L2), STADIUM STAR (L3), TRAIL LEGEND (L4), WORLD CHAMPION (L5).
- Training multiplier = 8 ^ (league - 1), on top of shoes, coaches and trails.

## Portal Plaza
- Behind the hub stands. 5 gates on a round platform, each in its league's colour.
- Open gate = "LEAGUE X - WALK IN", walk through to teleport. Locked = dark grey with "GO PRO FROM LEAGUE X".
- Leagues 4-5: COMING SOON + NOTIFY ME prompt (Roblox experience notifications).
- Every area has a BACK TO HUB gate. You can visit a lower league; races there pay 25%.

## Pacing
Tuned with `Games/SpeedArc/tools/pacing_sim.py` so a normal player takes ~15 / 35 / 60 min in leagues 1 / 2 / 3. Table in [[2026-10-28 SPEED ARC Progress - 3 Ranks, Go Pro, City Park, Big Stadium|Progress 3]].

## Studio test switches
`TestLeague` (2 or 3), `TestLeagueWins`, `TestSpeed`, `TestOpenWindow` = "GoPro".

## Where it lives
`Server/Services/LeagueService` (ranks, Go Pro), `Server/Services/AreaService` (teleports, gates, leaderboards), `Client/Controllers/MomentController` (popups, Go Pro screens, arrival, notify), `Config/Ranks`, `Config/Areas`.
