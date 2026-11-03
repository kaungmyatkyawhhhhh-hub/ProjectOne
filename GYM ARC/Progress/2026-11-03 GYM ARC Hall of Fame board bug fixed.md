---
date: 2026-11-03
tags: [gymarc, progress, hall-of-fame, bug, live]
status: fixed + tested in Studio (test board), goes out with the next publish
---
# GYM ARC - Hall of Fame "TOP 10 ALL TIME" board bug (3 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Related: [[2026-11-03 GYM ARC Star Track built]], [[2026-11-03 GYM ARC GEM update - verify and build]]

Owner's report: a ★7 player shows ★7 under "Legends in this server" but isn't in the TOP 10 board, while ★2 players are.

## 1. What his save and the board said (read-only, 3 Nov)
- **His save** (`GymArcDataStoreV1`, the player's key):
  - fame.stars = **7**.
  - ★1 on 1 Nov 16:42 UTC; ★7 on 2 Nov 22:18 UTC.
  - First join 1 Nov 13:01.
  - 8.0 h total play, 18 sessions.
  - 13,757 lifetime reps.
  - No Robux purchases.
- **His board entry** (`LB2_HallOfFame`): **none**.
- **Real board top 10:** ★7, 6, 5, 4, 4, 3, 3, 3, 3, 2. All of them pass the cheat check.

## 2. What was wrong
1. **The cheat check deleted him.** Each time he entered the Hall, `HallOfFame.Plausible` asked for **3,000 lifetime reps per star** (he needed 21,000 for ★7). It failed with "only 13757 reps for 7 stars", and `writeStars` called **RemoveAsync** on his entry.
   - The rule ignored that later runs are much shorter (x2 → x4.5 EXP, a later start).
   - **Is he a cheater?** Not proven. He is fast: ★7 with ~1/3 the reps and ~1/2 the play time of the other ★7 player. But the save looks like real play: all 6 story bosses beaten, 10 arm wins, 2 posing trophies, 6.5 km of cardio, 1,903 reps with others, 18 sessions. Owner chose: loosen the rule.
2. **The board was only written on gaining a star**, with a single `SetAsync` in a pcall and **no retry**. A failed write left the player off until their next star. There was no write on join or leave.
3. **Stars from before the 28 Oct `LB2_` reset:** not a cause. The Hall of Fame opened 31 Oct 15:00 (after the reset); the first board entry is 31 Oct 15:07.
4. **The published top 10 read exactly 10 rows**, so a refused save near the top made the list shorter.

## 3. Fix (Studio, not published)
- **Cheat rule, loosened** (`Config/HallOfFame`):
  - **Reps:** `MinRepsFirstRun` 2000 + `MinRepsLaterRun` 800 for each later run, scaled by that run's star EXP (x 2 / (1 + exp)).
  - **Play time:** `MinPlayFirstRun` 1 h + `MinPlayLaterRun` 10 min a run, when the save has `playtime.total`.
  - Runs = `fame.runs`, so an Alter 20 entry (2 stars in 1 run) isn't double-counted. The 30-min-a-run wall-time check stays.
  - He now needs 5,758 reps (has 13,757) → passes. The real top 25 all still pass.
- **Board writes** (`HallOfFameService.syncBoard`):
  - **When:** on **join** (2-8 s after load, spread out), on every new **star**, and on **leave**. The leave write uses the save as it was last seen, because the profile may already be gone.
  - **Safe writes:** `UpdateAsync` with `KeepBest`, which **never writes a lower value**. Fewer stars, or the same stars reached later, keep the old entry. Same stars = earlier achiever first, stable.
  - **Retries:** 4 tries with 2/4/8 s back-off and a request-budget wait. A final failure is logged as a warning.
  - **Admin console:** still writes exactly what was set (SetAsync), so the owner can lower a player.
  - **Refused saves:** removed (with retry) and listed in `fame suspicious`. Once a save passes again, it's written back.
  - Skips the write when the board already holds that value.
  - Analytics: `HallOfFame_BoardWrite_join` / `_star` / `_admin`.
- **Published board:** reads 20 rows and keeps the first 10 that pass. The statue cheat check uses the published place.
- **Studio safety:** Studio never writes the real board. Writes go to `TEST_HallOfFame_Studio`; ServerStorage attribute `HallOfFameTestBoard` = true makes Studio read the test board too.

## 4. Backfill
- **Everyone fixes themselves on their next join** after the publish. He'll appear at **#1**: ★7 reached 2 Nov 22:18, before the other ★7 (3 Nov 00:24).
- Nothing was written to the real board from Studio (owner rule: test keys only).

## 5. Tested in Studio (test board = a copy of the real top 10)
- **Join:** a ★7 save like his, written → **rank #1**. The published HallOfFameData showed it #1, then ★7, 6, 5, 4, 3, 3, 3, 3, 2.
- **Lower save joining** (★4 over ★7): board kept ★7.
- **Leave:** ★8 written.
- **Refused save** (500 reps): removed + flagged. Once the reps were fixed, written back.
- **KeepBest checks:**
  - lower → keep
  - same stars later → keep
  - same stars earlier → replace
  - more stars → replace
  - old plain number → re-encoded
- **The real join path by itself** (TestHallOfFame + TestStars 3): checked at join and refused (no peak), with no manual call.
- No script errors. Test attributes and scripts removed afterwards.

## Owner to do
- **Include in the next publish (live bug).**
- After the publish, check that he's on the board after his next join.
