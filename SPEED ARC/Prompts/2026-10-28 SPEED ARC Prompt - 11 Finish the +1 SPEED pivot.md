---
date: 2026-10-28
tags: [speedarc, prompt]
status: todo
---
# 11 Finish the +1 SPEED pivot (before launch)

Back to [[00 SPEED ARC Home|SPEED ARC Home]] · Why: [[2026-10-28 SPEED ARC Progress - Pivot to +1 SPEED every step]]

```text
SPEED ARC: finish the "+1 SPEED every step" pivot so the whole game uses the new loop before the soft launch. Follow CLAUDE.md. Never touch GYM ARC.
READ (only these): "SPEED ARC - Wall Course and Steps.md", "2026-10-28 SPEED ARC Progress - Pivot to +1 SPEED every step.md", GDD sections 9 and 19 (leagues + economy, still valid). Nothing else.

1) SMASHING MUST FEEL AMAZING (it's the core moment now, like the top "+1" games)
- Each wall: its stage colour (candy), a big chunky number, a cracked look when you're close to the need, glowing edges when you already have enough.
- Smash: the wall bursts into chunky pooled pieces, a short camera kick + FOV punch, a layered sound (crack + boom + crowd "ooh" + coin shower), "+X COINS" flying to the counter, and a bigger version for the first time ever (x3).
- Too slow: a soft bounce, never a hard fling. Show how close you are on the wall: "214 / 420" with a bar, plus "about 40 more steps".
- A progress strip at the top of the screen while on the course: wall 1 ... wall 10 with your best wall marked.

2) CITY PARK + BIG STADIUM GET THEIR WALL COURSES
- Same system as the hub, themed: Park = a course along the park path (hedges, bridge over the lake, wall colours in fresh greens/blues/yellows); Stadium = a long straight out of the players' tunnel along the stands (crowd cheers on each smash).
- Go Pro = smash the last wall in EVERY league. Remove the old rule (Champion + race wins) everywhere.
- Rebuild both areas in the bright candy palette like the hub v3 (no dark walls, big open spaces, giant floating zone names, fewer small props). Their stations = AFK step machines.

3) PACING (new sim for steps, the old tools/pacing_sim.py is for taps)
- Simulate a normal player running the course + some AFK time + races. Tune wall needs, step gains and coins so:
  first step < 15 s, wall 1 ~30-40 s, wall 2 ~2 min, wall 5 ~6-8 min, League 1 Go Pro ~15 min, League 2 ~35 min, League 3 ~60 min.
- Running must always beat AFK (about 3x), and Auto Run must not beat running.
- Shoes / coaches must be felt on the next wall (buying shoes should make the next wall reachable soon). Show me the table.

4) REMOVE EVERY TAP LEFTOVER
- Tutorial lines, quest texts ("Train 300 taps" -> steps / walls), daily/playtime text, the Auto Train offer ("after 10 min of tapping" -> after 10 min on a treadmill), store texts, the TRAIN button, combo meter, Sprint Lane / Stair Run leftovers, analytics step names (first tap -> first step, add first wall / wall 5 / last wall).
- Update the feature notes that still describe tapping (Training, First 15 Minutes, Daily/Quests, Store, Analytics, UI Kit).

5) SCREEN FIXES (from the v3 screenshots)
- The "A RACE IS STARTING!" card sits in the middle-bottom over the course. Make it a small card under the NEXT RACE pill (top right) with the RACE! button, gone when the join window ends. Never in the middle of the screen.
- "Need 420 SPEED. Keep running!" stacks under the speed panel. Put the need on the wall itself (point 1) and use the one toast lane only for real news.
- The leaderboard boards in the hub showed as empty dark squares. Make sure they fill, and show "LOADING..." / "BE THE FIRST!" instead of blank.
- The course road runs past the hub's fence in the top view: give the course a proper end (finish stage + edge).

6) DOCS
- Rewrite GDD sections 5, 6, 7 and 21 short for steps + walls (keep the rest), and the Launch Checklist's game page description, e.g. "+1 SPEED every step! Run, smash walls, GO PRO to new worlds. Race every 3 minutes, collect shoes and coaches."

TEST
- FreshPlayer on phone size: times for first step, wall 1, first race, first shoes, wall 5, Go Pro 1 (hub -> Park). Then Park course to Go Pro 2 (admin help allowed), Stadium course.
- Screenshots: a smash moment, the "214 / 420" wall, the progress strip, Park course, Stadium course, race card in its new spot, leaderboards filled.
- Parts per area, draw calls, particles during a smash. Progress note + updated feature notes.
```
