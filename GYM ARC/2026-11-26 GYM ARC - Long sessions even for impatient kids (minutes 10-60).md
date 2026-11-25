---
tags: [gym-arc, retention, session-length, sims]
date: 2026-11-26
build: v1914
---
# GYM ARC: long sessions, even for very impatient kids (minutes 10-60)

Owner (26 Nov, 05:14): "we need very long average session even with the very impatient kids".
Follows [[2026-11-26 GYM ARC - The 10-minute plan (minutes 3-10)]]. Goes into [[2026-11-25 GYM ARC - CHRISTMAS UPDATE build brief (5 Dec)]] as **Phase 2f**.

## What the live game has after minute 10 (read from Studio config, 26 Nov)
- Growth Spurts aim at ~5 min each with normal play (Config/GrowthSpurts `Targets {2,5,5,5,5,5}`), 6 of them, then Body Alters.
- Bosses: Coral at Growth Spurt 3 (opens the Pro Gym), Dante at Growth Spurt 5 (opens the Powerlifting Gym).
- THE RUNWAY posing show every 300 s (Config/PosingComp `Interval`), open from Growth Spurt 1. It invites with a side card that many players miss (the join rate in the model is a guess, ~35%).
- Playtime gifts at 3, 6, 10, 15, 20, 25, 30, 40, 60 min (Config/Playtime), trainer rolls at 20 and 60.
- Trainer roll = 150 coins (Config/Trainers `RollCost`). A new player had 4,662 coins at 6 min and 6,659 at 10 min in the 26 Nov run, so rolls are affordable. The kid just has to walk to the Agency and know about it.
- In between: the same reps, titles, coach levels, "weight unlocked". These wear off (habituation).

## Research (vault)
[[Playbook notes - Loading, auras, trainers, retention (29 Oct 2026)]] and [[Playbook notes - Core loop design]]:
- limited events / server-wide moments (Sol's RNG biomes);
- collection with empty slots;
- a goals ladder;
- AFK- and idle-friendly play (suits phones and kids who multitask);
- an open loop at session end;
- in-session server events every 15-20 min ("Protein Drop");
- don't pad playtime with walking or grind;
- Roblox counts at most 60 min of playtime per user per day as a signal, so padding past 60 is useless.

## The plan (Phase 2f)
1. **Every Growth Spurt pays 3 visible steps** (25 / 50 / 75%): the body visibly steps up (MuscleRig look) + a coin pop. A long bar becomes four short goals.
2. **THE RUNWAY for new players:** a big JOIN card in the centre queue (after the current card) 30 s before a show, one tap = dash to the stage. Their first 2 shows have an easy podium (NPC fill models pose weaker).
3. **Trainer rolls from anywhere:** when coins ≥ RollCost a "ROLL READY" chip appears (top-left, not under the joystick); tap = the roll card right there, no walk to the Agency. First session only: the chip pulses once per new 150 coins, max every 4 min.
4. **Playtime gifts every 5 min to 60 min** (15, 20, 25, ..., 60), trainer rolls at 20 / 40 / 60; the countdown chip from Phase 2e stays.
5. **A server event every 15 min:** "PROTEIN DROP: x2 gains for 3 min" for the whole server, with a countdown on the chip. The same system as the Christmas GIFT RUSH, so it doubles up.
6. **The AFK gift chair** (already in Phase 2c): a bored kid may park there instead of leaving. AFK minutes count as session time; the chair pays coins + Candy Canes, no reps (protects the AUTO REP pass).
- Tested and dropped (no gain in the model):
  - shows every 150 s (no better than every 300 s);
  - 3 first-day quests finishing at 12 / 18 / 25 min (slightly worse: more small rewards wear the big ones down).

## Session sim (`GYM ARC\Calc\session_gymarc.py`)
- The same kid model, run to 60 min (Roblox's daily cap).
- Calibrated so live players who pass 3 min play ~19 min on average (target ~18, from D1 playtime 11.8 min). Calibration: `calib_session.py`.
- Mean session for ALL new players at three patience levels (5 s = very impatient):

| Version (cumulative) | Mean @5 s | Mean @7 s | Mean @11 s | Still playing @5 s: 20 min | 30 min |
|---|---|---|---|---|---|
| A minutes 3-60 as live (first 3 min fixed) | 6.8 min | 10.4 | 18.1 | 0% | 0% |
| B + the 10-minute plan (Phase 2e) | 18.1 | 25.8 | 37.1 | 29% | 20% |
| C + 3 visible steps per Growth Spurt | 22.7 | 31.4 | 43.7 | 42% | 32% |
| D + RUNWAY join card, 90% join | 25.5 | 34.8 | 46.6 | 55% | 39% |
| F + trainer rolls from anywhere (~every 4 min) | 34.0 | 44.7 | 54.2 | 75% | 56% |
| H + gifts every 5 min to 60, rolls at 20/40/60 | 35.5 | 47.4 | 56.4 | 72% | 59% |
| I + a server event every 15 min | 36.1 | 48.4 | 56.3 | 79% | 60% |
| **PLAN (B C D F H I)** | **36.7** | **46.2** | **55.9** | **78%** | **60%** |
| PLAN + AFK chair | 38.9 | 49.6 | 57.5 | 82% | 65% |

What it says, honestly:
- **The biggest levers after minute 10:**
  - trainer rolls the kid can reach (F: a new face, a variable reward, already affordable);
  - Growth Spurt steps (C);
  - getting new players into THE RUNWAY (D).
- The 10-minute plan (B) is still the base everything stands on.
- The means near 60 min for patient kids are the model's CEILING (it caps at 60 and has no lag, bugs, homework, parents, battery). Real top Roblox games average ~19-25 min (GameAnalytics). **Read the table as "which changes lengthen sessions and by how much, relative", not as a forecast.**
- What should hold in the real game: a very impatient kid on live leaves before minute 7; with the plan, most of them should get past 20 minutes.
- The real check:
  - Creator Hub session length and D1 playtime;
  - funnel steps "10 min", "20 min", "first roll", "first show";
  - Daily Engagement Rewards (10-min users).
