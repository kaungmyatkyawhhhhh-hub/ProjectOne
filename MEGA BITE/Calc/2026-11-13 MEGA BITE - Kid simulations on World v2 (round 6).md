# 2026-11-13 MEGA BITE - Kid simulations on World v2 (round 6)

Both kid simulations run again after World v2, Combat v1 and the late-game pass (work order item 16). Models, not real players: the real check is a playtest.
Code: `Calc/r6.py` (needs `mb_kidsim.py`, `r4.py`), `Calc/round6_out.json`, `Calc/nerd_live_v2.lua` (run in Studio, Edit).

## 1. Impatient kid (first 5 minutes, 3,000 kids per row)
What changed for the first 5 minutes, read from the live GameConfig: Open Sea schools now live around each player (16 within 260 studs, about 58 studs apart; 55 before); ring 1 has Sardine, Mackerel, Squid and a few Puffers. The reef and the quest chain are the same.

| Patience (median) | Version | 30 s | 60 s | 2 min | 3 min | 5 min | reach Barracuda |
|---|---|---|---|---|---|---|---|
| 7 s | round 5 (before World v2) | 74% | 60% | 48% | 36% | 19% | 57% |
| 7 s | round 6 (World v2 live) | 74% | 59% | 46% | 35% | 17% | 55% |
| 11 s | round 5 | 93% | 85% | 78% | 69% | 48% | 83% |
| 11 s | round 6 | 93% | 85% | 77% | 68% | 47% | 82% |
| 16 s | round 5 | 99% | 96% | 93% | 89% | 75% | 94% |
| 16 s | round 6 | 99% | 96% | 92% | 88% | 74% | 94% |

Reading: World v2 did not change the first 5 minutes (1-2 points, inside the noise). The top quit place is the same as in round 5: the repeat "eat" quests in the Open Sea as a Reef Shark (11% of kids at median patience). The new King Mackerel (from ring 2, 3 bites for a Reef Shark) is a new thing in exactly that stretch, but it is outside this model's 5 minutes.

## 2. Quality-nerd kid (live map, mean of 5 swims per zone)
| Zone | props per view | "same prop again" tells | empty-view tells | set-piece wows |
|---|---|---|---|---|
| Reef, 2 min | 35.1 | 7.2 | 0 | 2.8 |
| Open Sea + Wilds (r 300-720), 3 min | 25.1 | 16.6 | 0 | 1.2 |
| Deep Sea + Far Deep (r 720-1150), 3 min | 20.1 | 19.6 | 0.4 | 1.6 |
| Red Trench (r 1250-1690), 2 min | 10.7 | 11.8 | 1.0 | 2.0 |

Before World v2 (same kid, old map): Open Sea 15.6 props per view, 38 same-prop tells and 1 wow in 5 minutes (= 22.8 tells and 0.6 wows per 3 minutes).
- Better: more in view (15.6 to 20-25), fewer repeats (22.8 to 16.6-19.6 per 3 min), twice the set pieces per minute.
- Still the top tell: "same prop again". The map now has 35 unique meshes, but the sea rings are made of 11 (Kelp 815, SeaFan 562, BubbleCoral 381, BrainCoral 352, Starfish 352, TableCoral 340, BranchCoral 309, rocks 526).

### Forecast: the 8 new kit props + the 3 landmarks that wait for upload
| Version | r 300-720: tells / wows | r 720-1150: tells / wows |
|---|---|---|
| live | 16.6 / 1.2 | 19.6 / 1.6 |
| 30% of the sea flora swapped to the 8 kit props + 3 landmarks | 16.8 / 1.6 | 20.0 / 1.6 |
| 50% swapped + 3 landmarks | 14.8 / 1.0 | 20.6 / 1.6 |

Reading: swapping pieces one for one does NOT remove the tell. The props stand in single-kind patches (a kelp patch, a fan-coral patch), so one mesh is still more than 9 of the last 40 a kid notices.
**Rule for the dressing pass after the upload (`MB_WorldDress`):** every patch mixes at least 5 kinds (old + new, no kind above about 20% of a patch), and single-kind fields are kept only as a few planned set pieces (a kelp forest, a sea-whip field). The three landmarks add little to the count because the kid's random route rarely passes them: they matter as goals on the map, not for this number.

## What to do with this
1. After the uploads: dress by mixed patches (the rule above), then run `nerd_live_v2.lua` again. Goal: under 3 tells per 10 minutes per zone.
2. The mid-game repeat quests in the Open Sea are still the place kids quit. Next idea to test in the model: a quest that sends the Reef Shark to ring 2 for its first King Mackerel.
