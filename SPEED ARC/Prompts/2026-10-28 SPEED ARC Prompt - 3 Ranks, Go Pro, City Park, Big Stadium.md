---
date: 2026-10-28
tags: [speedarc, prompt]
status: todo
---
# 3 Ranks, Go Pro, City Park, Big Stadium (M3)

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

```text
SPEED ARC milestone M3: leagues. Follow CLAUDE.md (Quick Rules). Never touch GYM ARC.
READ (only these): GDD sections 4, 7.2 (leagues 1-3), 8.4, 9 and 19; "SPEED ARC - World, Map and Buildings.md" sections Rules, 2, 3, 7 and 8; "SPEED ARC - Lighting.md" rows City Park and Big Stadium; "SPEED ARC - Audio (SFX and Music).md" Music table + World ambience; "SPEED ARC - Lessons from GYM ARC.md" section 10.

1) RANKS (GDD 9.1)
- League 1-3 ranks: Bronze, Silver, Gold, Platinum, Champion (SPEED thresholds in Config).
- Rank badge in the top bar and next to your name. Rank up = popup + big rising sound + gold ring on the ground + small coin reward (minutes of coins).
- The HUD always shows the NEXT goal: next rank, next station, or the Go Pro goal.

2) GO PRO (GDD 9.2)
- When the goal is met (Champion + the race wins needed): a big gold GO PRO button + Coach Benji line.
- Confirm screen in 3 clear blocks: YOU KEEP / YOU RESET / YOU GET. Big text, fits a phone.
- Go Pro moment: short cutscene (~4 s, SKIP after the first time), then teleport to the new league with an intro (players' tunnel reveal for the Stadium).
- League multiplier x8 per league (Config), a free coach roll, the league's title. SPEED resets to 0, everything else kept.

3) PORTAL PLAZA (hub, back side)
- 5 league gates on a round platform, each in its league's look. Unlocked = walk in to teleport. Locked = dark with the requirement on a sign.
- Leagues 4 and 5: "COMING SOON" gates with a NOTIFY ME button (Roblox experience notifications opt-in) for launch.
- Every league area has a BACK TO HUB gate. Visiting a lower league is allowed (races there give reduced rewards).

4) CITY PARK RUN (League 2) and BIG STADIUM (League 3)
- Build both from the World note: landmark, race route, 4 training stations each with GDD numbers, props from the shared Blender kit, edges that show why they end, < 3,000 parts each, only that area's lights on.
- Each area: its own race every 3 min (offset from the hub's), its own music + ambience, its own lighting preset (Lighting note), its own leaderboard board.
- Stadium: players' tunnel entrance (dark tunnel -> bright stadium reveal).
- Separate areas linked by teleports, streaming on, nothing loads all areas at once.

5) HURDLES RACE (League 3+)
- Hurdles appear on the stadium track for hurdle races. A JUMP button with a timing ring when a hurdle comes; a miss = small slowdown, never a stop. Rotates with Sprint and Lap Race in League 3.
- Sounds: jump whoosh, clean landing tap, hurdle knock on a miss.

6) PACING
- Make a simple pacing sim (bot that trains, races every 3 min, buys shoes, rolls coaches) and tune Config so: League 1 ~15 min, League 2 ~35 min, League 3 ~60 min for a normal player. Show me the table.

TEST
- Test save: reach Champion in League 1 (admin command OK), win a race, Go Pro, arrive in City Park, train, race there; Go Pro again into the Stadium, run a hurdles race.
- Rejoin keeps league, medals, shoes, coaches.
- Phone screenshots: rank up popup, Go Pro confirm, Portal Plaza, City Park, Stadium tunnel + inside, hurdles race.
- Per area: parts, lights, draw calls. Progress note + feature notes (Leagues and Go Pro, City Park, Big Stadium). List .fbx files to import.
```
