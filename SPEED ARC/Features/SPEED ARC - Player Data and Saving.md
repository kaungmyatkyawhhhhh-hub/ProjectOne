---
date: 2026-10-28
tags: [speedarc, feature]
status: done
---
# SPEED ARC - Player Data and Saving

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

One save per player in Roblox's DataStore, built from GYM ARC's approach (the GYM ARC note, not its place).

## How it works
- **What is saved:** SPEED, coins, league, medals (gold / silver / bronze), taps, races, wins, play time, best time per race type, the day of your last race (first-race-of-the-day bonus), first and last join.
- **Session lock:** a server marks the save as in use. A lock older than 180 s is treated as dead. A new server waits up to 60 s, then kicks with "Your data is still saving from another server". Studio locks never block a live server.
- **Saving:** every 60 s, when you leave, and when the server shuts down.
- **Old saves:** new fields are filled in automatically; numbered migrations run in order (version 1 now).
- **Studio:** uses its own store `SpeedArcData_Studio`, never the live `SpeedArcData_v1`. `FreshPlayer` = true plays on temporary data that is never saved.
- **HUD link:** Speed, Coins, League, medals, races and wins are copied to player attributes, plus `leaderstats` (MPH, Coins) for the player list.

## Where it lives
`Server/Services/PlayerData`, `Server/Services/DataTemplate`, numbers in `Config/GameConfig` (Data).

## Tested (28 Oct)
Left at 131 MPH / 1,036 coins; rejoined and got exactly the same.

## Related
[[SPEED ARC - Code and Sync]]
