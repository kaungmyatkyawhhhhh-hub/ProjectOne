---
date: 2026-11-05
tags: [gymarc, runcards, balance, report]
---
# GYM ARC - Run Cards v2: balance report (before building)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Prompt: [[2026-11-05 GYM ARC Prompt - Run Cards v2 FULL (talents, unique, every 2 alters)]] · Feature: [[GYM ARC - Run Cards]]

Nothing built yet (only the 15 talent icons uploaded; ids in `Config/RunCards.Art.Types`).

## Model
- EXP per rep = (the added pool + card EXP) x genetics x alter / Hall of Fame bonus. At 7'0" the pool is 4.3 (Growth Spurts) + ~0.4 trainers = **4.7**; at the start of a run it is ~1.0. % cards are diluted by the pool; extra-rep talents (perfect reps, MAX OUT, hold reps, keep-repping) are not.
- Reps: tapped rep 1.05 s, ~30 reps a bar (150 max stamina), 10 s recovering -> ~2,600 reps / hour.
- Cards (odd alters only): ★3 at Alter 3 = 2 run cards + 3 legacy = 5. Late run Alter 15 = 8 + 3 = 11.
- Best Commons (unique): own group +12%, All +5%, Trainers +10% (of a +40% trainer bonus = +4%), Stamina +10% max -> **EXP x1.07** (pool 4.7) / x1.21 (pool 1.0).
- Coins: coin pool 1.25. Lucky Plate assumed 1 shard per 50 reps worth 15 reps' coins.

## Single talents (pool 4.7, EXP/hour vs no cards)
| Talent | x | Note |
|---|---|---|
| Mind-Muscle | 1.40 (40% perfect) - 1.90 (90%) | skill: no upper limit except the player |
| Heavy Day | 1.26 | 25 reps every 2 min |
| Negative Reps | 1.15 | hold 2.6 s = 3 reps, same stamina per rep-worth |
| Unbreakable | 1.16 | rep through the 10 s refill at 50% |
| Lopsided Legend | 1.13 | +60% on one group (diluted) |
| Rest-Pause | 1.09 | walk to a bench ~5 s, 3x refill, 15 reps +40% |
| Second Wind | 1.05 | |
| Specialist | 1.04 | +20% one group |
| Iron Bond | 1.25 | with a friend; must be capped at 25% of YOUR own rep EXP, or a new player next to a 7'0" friend gets thousands of % |
| Adrenaline, Titan's Grip, Iron Lungs, Spotter's Call | ~1.00-1.03 | moments, not rate |

## Builds (EXP/hour)
| Case | Commons | Strongest talents AS WRITTEN | vs Commons |
|---|---|---|---|
| ★3 Alter 3 (5 cards) | x1.07 | Mind-Muscle + Heavy Day + Specialist + Lopsided + Unbreakable: x2.40 (top player x3.25) | **x2.25 (x3.05)** |
| Late run Alter 15 (11 cards) | x1.07 | same core (+ more talents stack) | **x2.25+** |
| Legacy worst: 3 Legendaries, run start | x1.21 | Unbreakable + Lopsided + Iron Bond: x2.32 | **x1.92** |
| Coins: Lucky Plate + Golden Hour | x1.06 | x1.53 | x1.44 (OK) |

Over the ~1.6x cap mainly because of two RARES (Mind-Muscle, Heavy Day), and the owner said tune Legendaries only.
- Tuning Legendaries alone (Unbreakable 25%, Lopsided +40%, Iron Bond 15%): legacy worst case x1.44 OK, but the ★3 / late-run builds stay ~x1.9-2.0.
- Option A (keeps every Rare as written): a server TALENT CAP: the extra EXP from all talents together is at most +60% of your normal EXP over any 10 minutes (a rolling window). Every case is then at most x1.6 vs no cards (x1.5 vs Commons).
- Option B: change Rare numbers: Mind-Muscle perfect = x1.5, Heavy Day = 15 reps (+ the Legendary tunes): x1.57 at 40% perfect, but a top player still x1.90.

Recommendation: Option A + the Legendary tunes. Waiting for the owner.
