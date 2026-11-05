---
date: 2026-11-05
tags: [gymarc, growthspurts, pacing, report]
---
# GYM ARC - Early Growth Spurts: report (before building)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Feature: [[GYM ARC - Growth Spurts]]

Owner (5 Nov): lower early requirements instead of inflated strength; new players start at 0; GS1 in ~30 s, then gaps x1.5-2 until the current curve; existing players never lose strength or spurts, missing spurts granted quietly.

## Today
- The goal is a LEVEL in every trainable muscle group (6 groups). In strength (all 18 muscles): GS1 L6 = 264K (FastStart; the table says L8), GS2 L33 = 3M, GS3 L58 = 7.9M, GS4 L73 = 11.9M, GS5 L99 = 20.6M, GS6 L124 = 31.3M (6'0", the last spurt). Every Growth Spurt resets the muscles to 0 (strength shown restarts), with a bigger permanent bonus.
- Strength per rep at the start (Flat Bench lightest, genetics B, no tapping): ~6,200, falling slowly (6,209 -> 5,478 over 10 reps).
- What inflates the start:
  1. WELCOME BONUS (FastStart, 29 Oct): every muscle starts at level 1 = 35,294 strength before any rep.
  2. NEW PLAYER BOOST (Playtime.NewPlayer): +100% EXP (and 2x coins) for the first 25 min: ~12,400 a rep.
  3. On top (normal game, not new): PUMPED x2 when tapping, BIG REP x3 (1 in 12), heavier weights x1.3 / x1.65 as levels rise, Muscle of the Day +100%. With all of them a rep reaches ~100K, so ~1M in ~10 reps is possible right at the start.
  4. FastFirstLevel 6 (GS1 lowered from 8).
- Pacing (Studio simulation with the live formulas: lowest group first, walk 8 s per machine, ~50% tapping, stamina + 10 s refills; training minutes, no menu/tutorial time): with the 2x boost GS1-6 at 1.3 / 5.5 / 14.4 / 27.2 / 57.9 / 99.3 min; without it 1.5 / 7.8 / 20.9 / 37.9 / 68.3 / 109.3.

## The 30 s problem
The goal needs EVERY group: walking to 6 machines alone is ~50 s. The fastest possible GS1 under that rule is ~1 min (goal level 1-2). 30 s needs a different first goal (e.g. GS1 counts only the groups the tutorial trains). Owner to choose.

## Proposed table (doubling gaps from 1 min; joins the current curve at GS6)
| GS | Now (level / strength) | New (level / strength) | Gap now -> new (min) | Total now -> new (min) |
|---|---|---|---|---|
| 1 | L6 / 264K | **L2 / 74K** | 1.5 -> 1.0 | 1.5 -> 1.0 |
| 2 | L33 / 3M | **L11 / 582K** | 6.3 -> 2.0 | 7.8 -> 3.0 |
| 3 | L58 / 7.9M | **L24 / 1.8M** | 13.1 -> 4.0 | 20.9 -> 7.0 |
| 4 | L73 / 11.9M | **L48 / 5.7M** | 17.1 -> 8.0 | 37.9 -> 14.9 |
| 5 | L99 / 20.6M | **L75 / 12.4M** | 30.3 -> 16.0 | 68.3 -> 30.9 |
| 6 | L124 / 31.3M | **L124 (unchanged)** | 41.0 -> 41.0 | 109.3 -> 71.9 |
- The doubling gap would be 32 min at GS6, the current gap is 41: GS6 stays as it is; alters, plate gates and everything after are untouched.
- Build plan (after OK): new players start at 0 (no welcome bonus), the NEW PLAYER BOOST's +100% EXP removed (its 2x coins: owner to say), tutorial lines updated; existing players who now qualify get the missing spurts on join WITHOUT a muscle reset (strength never drops), one popup "You earned N Growth Spurts".
