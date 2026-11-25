---
tags: [gym-arc, retention, session-length, sims, onboarding]
date: 2026-11-26
build: v1914
---
# GYM ARC: the 10-minute plan (minutes 3-10 of a new player)

Owner (26 Nov, 04:48): "now we need them to play for 10 minutes, which is super hard from 3 mins so we need a good plan".
The first 3 minutes are already fixed on paper (Phase 2b + 2d in [[2026-11-25 GYM ARC - CHRISTMAS UPDATE build brief (5 Dec)]]). This note covers minutes 3-10 and goes into the brief as **Phase 2e**.

## Why 10 minutes
- Roblox pays Daily Engagement Rewards (5 Robux) for each user who spends at least 10 minutes in an experience in a day.
- Vault [[Playbook notes - Core loop design]] (GameAnalytics 2025): D1 climbs with session length: 0-3 min 4.3%, 7-12 min 7.9%, 13-18 min 10.2%, 19-24 min 11.5%.
- Vault [[Playbook notes - Loading, auras, trainers, retention (29 Oct 2026)]]:
  - clear short- and long-term goals; an open loop at session end;
  - no padding with walking or grind; no feature bloat in the first 8 minutes;
  - no fake urgency or "buy" prompts at kids.

## What minutes 3-10 really look like (live v1914, measured 26 Nov 05:00, UI logged every second)
| Time | What happens | Problem |
|---|---|---|
| 2:50-5:20 | BEACH GRIND: chest 15, core 15, legs 20, back 20 reps, then "fill every group" = 70+ reps | 2.5 min of repeats, only titles / coach levels; OUT OF STAMINA at 4:25 |
| 5:20-5:30 | GS2 READY → GROW (6 s) | ok |
| 5:30 | free trainer roll (2 rolls) | good, a new thing |
| ~5:40-6:30 | forced QUESTS TOUR: 3 "tap to continue" pages (Daily / Streak / Goals) | ~50 s; the big gold CLAIM DAY 1 button does nothing while the tour runs (looks broken) |
| ~6:30 | "Heavier weight open! Tap + on the machine" dialog while you're NOT on a machine; STARTER PACK R$29 sticky; the tour's SKIP button stays on screen after the tour | noise + a paid offer before Growth Spurt 3 |
| 6:30-10:00 | GS3 0%, needs CHEST + SHOULDERS; the kid sits on the machine he's on (Bicep Curl): 16%, then the bar stops (biceps full), only "weight unlocked" pops | wasted reps; GO TRAIN CHEST shows but nothing forces it |
| ~8:45 | OUT OF STAMINA + a refill OFFER (R$5 / R$49) | a paid popup at minute 9 |
| 5:33 / 5:54 / 9:53 | PLAYTIME GIFT 1/9, 2/9, 3/9 | they only start after the tutorial; the next one is 4-5 min away |
| ~9:00 | the sky turns to dusk on a server that started at 9:00 (day = 14 of every 20 min) | about a third of new players hit dusk/night in their first 15 min; owner rule: never dark |

## The plan (each a config value or small change; the sim says which ones matter)
1. **Beach grind 70 → 40 reps** (10 per group). GS2 comes ~1.5 min sooner.
2. **No QUESTS TOUR in the first session.**
   - The day-1 streak is a one-tap toast ("DAY 1: +750, CLAIM"). The quests stay in their window for later.
   - CLAIM must always work; no tour blocks it.
   - The tour's SKIP button must hide with the tour.
3. **No paid offers before Growth Spurt 3:** the starter pack sticky, the R$ stamina refill, DEAL. This extends Phase 2b's "calm HUD before Growth Spurt 2".
4. **GO TRAIN stays on for the whole first session.**
   - When the muscle you're on is FULL for the spurt, it says "FULL! Next: CHEST" and takes you there after 3 s unless you tap STAY.
   - The "Heavier weight open" line only shows on a machine.
5. **No stamina wall in the first session.**
   - Stamina refills while you walk / dash.
   - The first time it runs out, a free shake drops into the hotbar with a hand on it.
6. **Playtime gifts from minute 2, every 2 minutes** (2, 4, 6, 8, **10 = a big one: a free trainer roll**), then every 5 min.
   - A small chip counts down to the next one.
   - Time counts during the tutorial too.
   - The Roblox Engagement Rewards package works the same way: time rewards unlock after a set number of seconds in game.
7. **A new player's sky stays day for their first 15 minutes** (client-side ClockTime). Or raise the night fill so the night is never dark (owner rule, 13 Nov).
- Tested and NOT needed for the 10-minute goal (the model says they don't help, so they're out of this phase):
  - x2 EXP for 15 min;
  - a "session ladder" of a new thing every 70 s;
  - a dash to the Pro Gym at GS3.
  - They pull Growth Spurt 3 earlier but leave a longer grind after it (15-min stay fell 2-4 points).

## 10-minute sim (`GYM ARC\Calc\tenmin_gymarc.py`)
- Same kid as the impatient and tutorial sims, run to 30 min, on the measured timeline.
- Calibrated: on live, players who pass 3 min average ~18 min (D1 playtime 11.8 min with 15.2% gone < 1 min and 22.6% at 1-3 min). Calibration in `calib_tenmin.py`.
- Version A already includes the new first 3 minutes (2b + 2d).

| Version (cumulative) | 5 min | 7 min | 10 min | 15 min | Mean |
|---|---|---|---|---|---|
| A minutes 3-10 as live | 98% | 97% | 56% | 43% | 18.3 min |
| B beach grind 70 → 40 | 97% | 97% | 59% | 53% | 19.8 |
| C no quests tour, one-tap claim | 98% | 98% | 73% | 69% | 22.8 |
| D no paid offers before GS3 | 98% | 98% | 71% | 67% | 22.3 |
| E GO TRAIN to what the spurt needs | 98% | 93% | 93% | 90% | 26.0 |
| F no stamina wall in the first session | 100% | 100% | 100% | 95% | 26.8 |
| G x2 EXP 15 min | 100% | 100% | 98% | 91% | 25.7 |
| H GS3 = a trip to the Pro Gym | 100% | 100% | 98% | 90% | 25.0 |
| I playtime gifts every 2 min, big at 10 | 100% | 100% | 100% | 93% | 25.2 |
| J a new thing every 70 s | 100% | 100% | 100% | 90% | 24.3 |
| K day sky for the first 15 min | 100% | 100% | 100% | 94% | 24.9 |
| **LEAN = B + C + D + E + F + I + K** | **100%** | **100%** | **100%** | **98%** | **27.0** |

Sensitivity (patience):
| Patience | Live A, 10 min | LEAN, 10 min | LEAN, 15 min |
|---|---|---|---|
| 5 s (very impatient) | 7% | 92% | 70% |
| 7 s | 21% | 99% | 88% |
| 11 s | 56% | 100% | 98% |
| 16 s | 82% | 100% | 100% |

What it says, honestly:
- **The two biggest levers are E (GO TRAIN to what the spurt needs) and C (no forced quests tour).** On live, kids train a muscle that no longer counts and the bar stops; then a 50 s tour.
- The stamina wall (F) is the next biggest.
- D (no early offers) is neutral in the model; it stays because of the owner's rules and the FTC / kids research.
- 100% is the model's ceiling, not a forecast. Not in the model: lag on cheap phones, bugs, kids who just don't like gym games, friends leaving. Treat it as: **over 90% past 10 min of those who pass 3 min is reachable, even for impatient kids**.
- The real check:
  - the Creator Hub funnel (add steps "GS2", "GS3", "10 min in session");
  - the "61-180 s" and session-length cards;
  - Daily Engagement Rewards (10-min users).

## Bugs seen on the way (fix with this phase)
- The CLAIM DAY 1 button doesn't react while the quests tour runs.
- The tour's SKIP button stays on screen after the tour ends.
- "Heavier weight open! Tap + on the machine" shows when you're not on a machine.
- After GROW (GS1) the "READY TO GROW! Growth Spurt 1" card flashes again for ~1 s.
