---
date: 2026-11-05
tags: [gymarc, growthspurts, pacing, progress]
---
# GYM ARC - Early Growth Spurts: built (5 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Report: [[2026-11-05 GYM ARC Early Growth Spurts report]] · Feature: [[GYM ARC - Growth Spurts]]

In Studio only. **Not published.**

Owner (5 Nov, final): "GS1-6 should be quick, Alters are the real progression": GS1 ~2 min, GS2-6 ~5 min each with normal play, 6'0" in ~27 min; GS6 may go lower; Alters / plate gates unchanged; start at 0; New Player Boost = 2x coins only; existing players never lose anything.

## Final table
Studio simulation with the live formulas and NORMAL play: the lowest group first, 8 s walk per machine, half the sets tapped (PUMPED x2 with faster reps), half on auto reps, BIG REP 1 in 12 (x3), the heaviest weight unlocked, Muscle of the Day on a random group each spurt, stamina + 10 s refills; median of 25 players, lifting minutes (no menu / tutorial / story fights).
| GS | Height | Goal before | **Goal now** | Strength now | Gap | Total |
|---|---|---|---|---|---|---|
| 1 | 4'4" | L6 (fast start) | **L9** | 445K | 2.0 min | 2.0 |
| 2 | 4'8" | L33 | **L32** | 2.9M | 4.8 | 6.8 |
| 3 | 5'0" | L58 | **L35** | 3.3M | 5.4 | 12.2 |
| 4 | 5'4" | L73 | **L37** | 3.7M | 4.8 | 17.0 |
| 5 | 5'8" | L99 | **L41** | 4.3M | 5.1 | 22.1 |
| 6 | 6'0" | L124 | **L47** | 5.5M | 4.8 | **26.9** |
- Same goals today with the same play: 1.4 / 5.6 / 11.7 / 13.4 / 22.8 / 36.9 min (91.8 in all).
- The bonuses (x1.36 ... x4.3), heights, Alters, plate gates and everything after 6'0" are unchanged.

## GS6 -> Alter 1 (NOT changed, owner's call)
- Alter 1 needs L218 in every group (6 spurts' bonus, muscles from 0 after GS6): **~129 min** for a new player with normal play and no trainers (trainers' progress boost and auras shorten it). That's >10x the last spurt gap (the owner's line: ~12 min). It is the same today (the GS6 reset was there before).
- Bridge options (owner to choose): (a) Alter 1 at ~L90 (~12 min) with the later alters re-spaced so Alter 2 isn't a wall; (b) keep the Alter goals, but GS6 doesn't reset the muscles (they carry into the Alter 1 goal); (c) more steps between 6'0" and Alter 1 (e.g. an "Alter 0" or a 6'0" mastery step). Times for Alter 1 at L80 / 100 / 120 / 140 / 160: 9 / 16 / 22 / 33 / 53 min.

## Built
- `Config/GrowthSpurts`: goals 9 / 32 / 35 / 37 / 41 / 47; Targets 2 / 5 / 5 / 5 / 5 / 5; the FastStart first-goal override off (FastFirstLevel = nil).
- `Config/Onboarding.WelcomeLevel` 1 -> 0: new players start at 0 strength (was 35,294 before any rep). Saves that already got the welcome levels keep them.
- `Config/Playtime.NewPlayer`: gains 2 -> 1 (2x coins kept). Tutorial lines: "Every rep fills your Growth Spurt bar, and here's 2x coins for your first 25 minutes!" / "NEW PLAYER BOOST: 2x coins ...".
- Existing players (`PlayerData` load): while the save meets the next (lower) goal, +1 Growth Spurt and the free DNA token, muscles KEPT (no reset), up to 6'0"; one note ~10 s after joining: "YOU EARNED N GROWTH SPURTS" (ProgressClient, PlayerEvent SpurtsGranted). No cutscenes.
- Level 0: every spurt already reset the muscles to 0, so 0 is a normal state; the only division in the UI is by the goal (BodyMapClient), never by a level.

## Tested (Studio)
- Fresh save: strength 0 at the start, EXP boost x1.1 (another source, not the new player 2x), coins boost kept; the tutorial opens with "0 EXP · 4'0"", GROWTH SPURT 1 0% and the new coach line. ![[GYM ARC/Screenshots/2026-11-05_growth_spurts/01_new_player_starts_at_0.jpg]]
- 15 min with a test bot (real machines, real Growth Spurt action, taps on EVERY rep so mostly PUMPED = a fast player; tutorial skipped; Starter Gym only, because the next gyms open by beating the story's bullies at arm wrestling, which the bot can't do): GS1 at 1.1 min; GS2 -> 3 -> 4 -> 5 every ~2.1-2.3 min (GS5 at 14.7 min). The bot lost ~4 min stuck on the story-locked Beach Gym (fixed in the bot). Slower normal players: the simulation above. No errors.
- Existing saves (the batch rule on test saves): GS0 at L12 -> +1; GS1 at L40 -> +3 (to GS4); GS2 at L36 -> +1; GS2 at L45 -> +3; GS3 at L60 -> +3 (6'0"); GS5 at L50 -> +1; GS6 -> 0; strength unchanged every time.
- Not done: the full tutorial to the end with the new numbers (its steps don't use the goal numbers; the first lines are checked), a real phone, Mind-Muscle-style playtests with real kids.
