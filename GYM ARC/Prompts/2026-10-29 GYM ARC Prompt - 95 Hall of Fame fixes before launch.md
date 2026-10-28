---
date: 2026-10-29
tags: [gymarc, prompt, hall-of-fame]
status: todo (run with 90, BEFORE Saturday 31 Oct)
---
# 95 Hall of Fame fixes before launch

Back to [[00 GYM ARC Home|GYM ARC Home]] · Why: [[2026-10-29 GYM ARC Hall of Fame - good or bad]], [[Playbook notes - Costly mistakes of big games]], plan: [[2026-10-29 GYM ARC Master plan - one ladder]]

```text
GYM ARC: make the Hall of Fame feel like a REWARD, not a punishment, before Saturday's launch. Follow CLAUDE.md and the Playbook rules. Only the GYM ARC Studio. Read "GYM ARC - Hall of Fame" first. Keep what exists (opt-in, ARE YOU SURE, ceremony, statues, cutscenes stay unskippable). Never undo my manual Studio changes. Put every number in Config/HallOfFame AND a Roblox Experience Config override so I can change it live.

1) RUN 2 IS FAST: star 1 = x2 EXP and start at Growth Spurt 3; each next star faster again (targets: run 2 ~3 h total, run 3 ~2.5 h, run 4 ~2 h, ~1.5 h by star 6, ~1 h floor by star 10; never slower than the run before). Check with tests/pacing and write the run-2 times in the progress note.
2) HEIGHT KEPT AS STATUS: overhead tag and profile show "PEAK 7'0" ★1" (the player's real peak height from data.fame.peak). Statue = peak body (already). Small extra: in the Hall and on the posing stage, star players can toggle "Legend Form" (their peak height, look only, no stats).
2b) STAR TRACK PREVIEW: the Hall of Fame screen shows the next star's reward (just the list for now; the full star track comes in prompt 101).
3) CLEAR ENTER SCREEN: one big line "Run 2 is 3x faster" (use the real number), then YOU KEEP / START OVER as now, plus "Your peak height stays on your name and statue".
4) NO CHEATERS AS STATUES: before the top-10 board / statue / LB2_HallOfFame accept a player, the server checks the save is possible (stars vs alters reached vs time played, no impossible EXP jumps). Suspicious = left off the board and logged for me in the Admin console.
5) ANALYTICS: HallOfFame_Entered (stars), HallOfFame_Declined (pressed Not yet), SecondRun_Done (minutes), and a custom event each day a star player plays (so I can compare 7-day playtime of players who entered vs. Alter-15 players who didn't).
6) FAIRNESS CHECKS (from [[2026-10-29 GYM ARC Every decision - the whole game]]): (a) any player who had a free 3rd trainer slot before the 28 Oct slot change keeps it (check the saves/logic, fix if not, tell me how many were affected); (b) the Starter Pack price is the same everywhere (Creator Hub, Config fallback, Store, offers, notes): tell me what it is.
7) TEST with TestLaunchIn / TestHallOfFame: enter at Alter 15, run 2 speed, tag text, Legend Form, a fake impossible save gets refused. Phone-size screenshots. Progress note + update the Hall of Fame feature note.
```
