---
date: 2026-10-28
tags: [speedarc, feature]
status: live in the hub (league 1); Park + Stadium courses still to build
---
# SPEED ARC - Wall Course and Steps

Back to [[00 SPEED ARC Home|SPEED ARC Home]] · Why: [[2026-10-28 SPEED ARC Progress - Pivot to +1 SPEED every step]]

## The loop (owner's choice, 28 Oct)
**Every step = +1 SPEED** (times shoes, coaches, passes, boosts and the wall bonus) -> run down the **wall course** -> each wall needs some SPEED -> **SMASH** it for coins -> every smashed wall makes later steps worth more -> smash the **last wall** = GO PRO to the next world. Races stay as an event every 3 min. Coaches stay as they are.

## Steps
- The server measures how far you run on the ground: every **3.5 studs = 1 step** (`Config/Course.StudsPerStep`).
- Not counted: teleports, flings, races, anchored, more than 12 steps a second.
- SPEED per step = league base gain (1 / 40 / 900 / ...) x the x8 per league x shoes, coaches, passes x session boosts (New Runner, gift, friends) x **1.25 for every wall you've smashed in your league**.
- Coins: a small share per step (same share the old taps had).
- On screen: a "+N" popup and a soft tick, at most a few a second.

## The course (hub)
- Starts just south of the spawn plaza, straight south, 44 studs wide, 10 stages of 90 studs, each stage its own candy colour. A gold finish stage at the end sends you back to the start.
- Wall k needs a share of the league's Champion SPEED (`WallShares`). League 1: 110, 420, 1.2K, 3K, 6K, 12K, 22K, 35K, 50K, 70K.
- Fast enough: your own client opens the wall when you run into it (pieces fly, layered sound). The server checks where you are and pays: wall k after wall k-1 in this run.
- Too slow: you bounce back, and see "Need 420 SPEED. Keep running!".
- Going back behind the start line, or respawning, starts a new run: every wall stands again.
- Coins for wall k: 0.3 ... 2.5 minutes of coins at your league; **the first time ever x3**. In a lower league's area, a quarter.
- The TO START button (bottom centre after the tutorial) takes you to the start.

## AFK treadmills
Six treadmills next to the course start step for you: 2 steps a second. The **Auto Run** pass (was Auto Train, same pass id) makes it 6 a second, with the "still there?" check every 15 min. Running the course is faster (about 5-6 steps a second).

## Go Pro
Smash your league's last wall. Leagues whose area has no course yet (Park, Stadium) keep the old rule (Champion rank + race wins) until their course is built.

## Tutorial (first minutes)
Welcome -> **take your first step** (+10 SPEED, +100 coins) -> **smash wall 1** -> the tutorial race -> podium -> buy shoes -> Silver rank -> free coach roll.
Test: wall 1 fell 35 s after PLAY.

## Numbers are a first pass
The wall needs and step gains are first guesses, scaled from the old rank thresholds. They need a pacing pass (the old `tools/pacing_sim.py` is for taps).

## Where it lives
`Config/Course`, `Config/Stations` (AFK machines), `Util/Formulas` (stepBase, wallNeed, hasCourse), `Server/Services/StepService`, `WallService`, `TrainingService`, `LeagueService` (Go Pro rule), `Client/Controllers/StepController`, `WallController`, `TrainingController`, `HudController` (goal line), `TutorialController`. The course is built by `tools/build_hub.luau` (Model `Hub.Course`, walls `Wall1..10` with Index / League attributes).

## Screenshots
![[2026-10-28 v3 course wall 2.jpg]]
![[2026-10-28 v3 need more speed.jpg]]
