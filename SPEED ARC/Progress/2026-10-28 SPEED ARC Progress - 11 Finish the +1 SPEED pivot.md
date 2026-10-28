---
date: 2026-10-28
tags: [speedarc, progress]
---
# SPEED ARC Progress - 11 Finish the +1 SPEED pivot

Back to [[00 SPEED ARC Home|SPEED ARC Home]] · Prompt: [[2026-10-28 SPEED ARC Prompt - 11 Finish the +1 SPEED pivot]] · Feature: [[SPEED ARC - Wall Course and Steps]]

## 1) Smashing feels good
- **Wall face:** the stage's candy colour, WALL k, a big number. For your next wall it shows "560 / 1,600 - about 416 more steps" with a bar, cracks from 70%, and glowing edges + SMASH IT! once you have enough.
- **Smash:** 24 chunky pooled pieces, a camera kick + FOV punch, crack + boom + crowd "ooh", the crowd cheers, "+X COINS" and coins fly to the counter. The first time ever is bigger: "FIRST SMASH!", the coin shower, more pieces, a bigger kick.
- **Too slow:** a soft bounce (no fling, no toast).
- **Strip** under the SPEED panel while you're on the course: walls 1-10, passed ones filled, the best one gold, the next one outlined.

![[2026-10-28 p11 wall progress 560 of 1600.jpg]]
![[2026-10-28 p11 smash moment.jpg]]

## 2) City Park and Big Stadium have wall courses
- One course builder for all 3 worlds (`builder_lib` L.course, themes hub / hedge / stands), each with a gold finish, a FINISH arch and a closed end.
- **Park:** south of the spawn (you spawn facing it), hedges and trees, stage 4 a bridge over water, fresh greens / blues / yellows.
- **Stadium:** straight out of the players' tunnel, low stands with a crowd that cheers on every smash, purples / pinks / blues.
- Both rebuilt in the candy look (no dark walls, the small props removed, giant floating names). Their stations are AFK machines.
- **Go Pro = the last wall in every league.** The old rule (Champion + race wins) is gone from code and config.
- Parts: hub 964, City Park 719, Big Stadium 885 (296 fans).

![[2026-10-28 p11 park course bridge and strip.jpg]]
![[2026-10-28 p11 stadium course.jpg]]

## 3) Pacing (`tools/step_pacing_sim.py`, new, for steps)
A normal player: 78% running, 12% AFK, races every 3 min, buys the next shoes, rolls coaches with spare coins. `--solve` sets each wall's need to the SPEED at its target time. One step = 3 studs, AFK 1.6 steps/s, Auto Run x2.4. Shoe prices were lowered so each league's shoes are bought inside it: 900 / 3,000 / 15,000 / 150,000. Ranks now sit on walls 4 / 6 / 8 / 10.

| League | First step | Wall 1 | Wall 2 | Wall 5 | Go Pro |
|---|---|---|---|---|---|
| 1 | 6 s | 0.6 min | 2.0 min | 7.0 min | **14.9 min** |
| 2 | - | 1.6 min | 4.2 min | 14.2 min | **35.1 min** |
| 3 | - | 1.9 min | 6.0 min | 21.2 min | **59.3 min** |

Shoes are felt on the next wall: Canvas Runners at 2.0 min, then wall 3 at 2.9. Track Trainers at 6.0, then wall 5 at 7.0. Light Racers 2.0 min into League 2, Park Pacers at 8.7, then wall 4 at 10.1.

Running vs AFK (league start): running 5.0 steps/s, AFK 1.6, Auto Run 3.8. Running = **3.2x AFK**, and Auto Run = 0.76x running, so it never beats running.

## 4) Tap leftovers removed
- Code: the combo (config, formula, the HUD meter), the TrainTap remote, "MPH" texts (HUD, leaderboards, profile), "training" texts (Locker, Go Pro screen, gifts, invites, the Auto Run AFK card "STILL THERE?"), the station prompt (AFK STEPS), the loading tips.
- Quests: Take 500 / 1,500 steps, Smash 5 / 12 walls (new stat `Smashes`).
- Funnel: first_step, first_wall, wall_5, last_wall. The tutorial step ids are `FirstStep` / `FirstWall`.
- Test switch `TestWalls` (walls already smashed) replaces `TestLeagueWins`.
- Feature notes updated: Training, First 15 Minutes, Daily/Quests, Store, Analytics, UI Kit, Leagues and Go Pro, City Park, Big Stadium, Wall Course.

## 5) Screen fixes
- The tutorial race card is a small card top right, under the DAILY row, never in the middle.
- "Need ... SPEED" toast removed (the wall shows it). The toast lane moved below the wall strip.
- Leaderboards: "LOADING..." until filled, "BE THE FIRST!" when empty, visible from further away. Tested: all 4 hub boards filled.
- The hub course has hedges along its strip and a closed end; all courses have a FINISH arch and an end wall.

![[2026-10-28 p11 race card top right.jpg]]
![[2026-10-28 p11 leaderboards filled.jpg]]

## 6) Docs
GDD sections 5, 6, 7 and 21 were rewritten short for steps + walls, plus the league 1 Go Pro goal in section 9. The Launch Checklist has the game page text: "+1 SPEED every step! Run, smash walls, GO PRO to new worlds. Race every 3 minutes, collect shoes and coaches."

## Tests (Studio, FreshPlayer)
| Step | Time after PLAY |
|---|---|
| First step | 4.7 s |
| Wall 1 | 34.4 s |
| Tutorial race card | ~40 s |
| Wall 2 (with test SPEED) | opens on contact, pays on passing |
- City Park as League 2 (TestLeague 2, TestWalls 9): walls 1-10 in order, wall 10 at 55M, GO PRO ready, Go Pro to League 3 (SPEED 0).
- Big Stadium as League 3: walls 1-3 with first-smash moments, the crowd stands along the course.
- No console errors. Client during play: 1,021 parts streamed in, 5 particle emitters, 62K instances. Studio FPS is Studio-limited (two Studios open), so it's not a real number; phone check needed. Draw calls can't be read from Studio scripts.

## Not tested / for the owner
1. A full real-time League 1 run (15 min) and the Go Pro cutscene from Hub to Park (tested with admin switches and the GoPro call).
2. A phone test (FPS, the strip and the race card at phone size).
3. File > Save to Roblox + a dated backup.
