---
date: 2026-11-04
tags: [gymarc, plates, weights, leaderboards, prompt]
---
# GYM ARC - Prompt: PLATE TIERS, heavier weights past the Gem Mine (14 Nov)

Owner (4 Nov): players max out weights and have no competitors; "players will be able to use the bought weights in every machine"; "players want heavier weights on top of the new weights too" (on top of the Gem Mine, 7 Nov).
Decided: coins buy (global, every machine) + strength gate (main muscle) so it's a coin sink but not pay-to-win; % per tier so gyms keep their order; EXP/pace unchanged; plates start above the Gem Mine (unlockLevel 346, 30 coins/rep). Research: core-loop friction kills retention (no manual plate loading); [[2026-10-29 GYM ARC Gym genre research]].

```text
GYM ARC – PLATE TIERS: HEAVIER WEIGHTS PAST THE GEM MINE (PART 9 of the 7 Nov GEM update – owner 4 Nov: "plates should be with the nov 7")
Players: weights max out, nothing to compete on, and they want heavier weights on top of the Gem Mine's too.

1. PLATE TIERS (global, bought once with fixed coins, used on EVERY machine): IRON 25,000 · STEEL 50,000 · CHROME 100,000 · TITANIUM 200,000 · GOLD 400,000 · DIAMOND 800,000 (more tiers later). Sold at a plate rack shop in the Powerlifting Gym + the shop UI.
2. WEIGHT: each tier = +10% on top of each machine's own top weight (Gem Mine copies use their Gem top), so every gym keeps its own numbers and order.
3. STRENGTH GATE: using tier T on a machine needs its main muscle (machine.muscles[1]) at internal level 360 / 375 / 390 / 405 / 420 / 435 (above Gem Mine's 346). Players never see levels: show "Needs <Main muscle> <EXP> exp" (Muscles.Shown), like today's weights. Owned-but-too-weak = greyed with that line. Lopsided builds lift different tiers on different machines (wanted). Re-applies after Growth Spurts / Alters like today's weights.
4. COINS per rep: +9% of that machine's top-tier coins per tier (a %, not flat). Boost cap x4 unchanged. EXP unchanged.
5. FEEL (no friction): when the weight changes, plates slide on with a heavy clank (~0.4 s, never blocks reps); a new heaviest weight = short "NEW PR: <weight>" moment (skippable, ≤1.5 s). No walking/clicking plates.
6. COMPETE: leaderboards BEST BENCH, BEST SQUAT, BEST DEADLIFT, TOTAL (sum), written on every new PR (not only on gain). Board in the Powerlifting Gym + a leaderboard tab with "players near you". Profile card shows the 3 PRs + Total. Powerlifting MEET ranked by real PR on the meet lift.
7. Never lower anyone's weight, best lift or coins; current best lifts become starting PRs.
0. PRIORITY: GEM update parts 1-8 first. If time is short, ship in this order: (a) tiers + gate + shop + weights (1-3), (b) coins (4), (c) PR boards + profile (6), (d) clank/PR moment (5), (e) meet ranking. Tell me by Fri 6 Nov 18:00 UTC what will make it.
8. PLAN FIRST (numbers in one short report, then build the same day): check prices/gates against real data (CoinRate of maxed players, main-muscle levels of the top 50, level drop after spurts/alters). If a tier is bought in < 5 min or a gate is above what ★10 players reach, report and propose new numbers; don't change them yourself.
Test: buy tiers, strong on one muscle / weak on another, PR boards update, meet picks the heavier lifter, phone layout. Progress note. Don't publish.
```
