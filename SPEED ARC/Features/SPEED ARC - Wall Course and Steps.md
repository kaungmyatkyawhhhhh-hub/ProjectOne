---
date: 2026-10-28
tags: [speedarc, feature]
status: live in all 3 worlds (prompt 11)
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
- Wall k needs `Config/Course Walls[league][k]` (see Pacing below).
- Fast enough: your own client opens the wall when you run into it (pieces fly, layered sound). The server checks where you are and pays: wall k after wall k-1 in this run.
- Too slow: a soft bounce; the wall itself shows how close you are.
- Going back behind the start line, or respawning, starts a new run: every wall stands again.
- Coins for wall k: 0.3 ... 2.5 minutes of coins at your league; **the first time ever x3**. In a lower league's area, a quarter.
- The TO START button (bottom centre after the tutorial) takes you to the start.

## AFK treadmills
Six treadmills next to the course start step for you: 1.6 steps a second. The **Auto Run** pass (was Auto Train, same pass id) makes it x2.4, with the "still there?" check every 15 min. Running the course is faster (about 5 steps a second at the start, more as you get faster).

## Go Pro
Smash your league's last wall, in every league (prompt 11).

## Tutorial (first minutes)
Welcome -> **take your first step** (+10 SPEED, +100 coins) -> **smash wall 1** -> the tutorial race -> podium -> buy shoes -> Silver rank -> free coach roll.
Test: wall 1 fell 35 s after PLAY.

## Pacing (prompt 11, `tools/step_pacing_sim.py`)
Wall needs per league are in `Config/Course Walls` (solved so a normal player smashes them at target times). League 1: 310, 1.6K, 3.2K, 4.7K, 8.6K, 15K, 18K, 28K, 34K, 53K. One step = 3 studs. AFK 1.6 steps/s, Auto Run x2.4. The table is in [[2026-10-28 SPEED ARC Progress - 11 Finish the +1 SPEED pivot]].

## Prompt 11 changes
- **One builder** for every world: `builder_lib` L.course (themes: hub, hedge (Park, with a bridge), stands (Stadium, with a crowd)). Each course ends in a gold finish, a FINISH arch and a closed end. The hub course has hedges along its strip.
- **The wall's face** shows the live "214 / 420 - about 40 more steps" + a bar for your next wall, cracks from 70%, glowing edges + SMASH IT! when you have enough (the server sends `StepGain`, what one step is worth).
- **Smash:** 24 chunky pooled pieces, camera kick + FOV punch, crack + boom + crowd "ooh", the crowd cheers, coins fly to the counter (bigger the first time). **Too slow:** a soft bounce (20 studs/s), no toast.
- **The strip** under the SPEED panel (walls 1-10, passed filled, best gold) while you're on the course.
- Go Pro = the last wall in every league. Quests use steps and walls; the funnel has first_step / first_wall / wall_5 / last_wall.

## Where it lives
`Config/Course`, `Config/Stations` (AFK machines), `Util/Formulas` (stepBase, wallNeed, hasCourse), `Server/Services/StepService`, `WallService`, `TrainingService`, `LeagueService` (Go Pro rule), `Client/Controllers/StepController`, `WallController`, `TrainingController`, `HudController` (goal line), `TutorialController`. Every course is built by `tools/builder_lib.luau` L.course, called from the hub / Park / Stadium builders (Model `<Area>.Course`, walls `Wall1..10` with Index / League attributes). Pacing: `tools/step_pacing_sim.py`.

## Screenshots
![[2026-10-28 v3 course wall 2.jpg]]
![[2026-10-28 v3 need more speed.jpg]]

![[2026-10-28 p11 smash moment.jpg]]
![[2026-10-28 p11 wall progress 560 of 1600.jpg]]
