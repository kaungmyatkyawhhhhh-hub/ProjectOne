# Stomp Evolution - Three kid simulations v3 (live v127, 13 Nov 11:55)

What was tested: the live Studio build v127, with:
- clicks giving Mass and props giving coins;
- 6 height-locked areas;
- Sumo, Rogue Alert, events every 90 s, the smash index, golden props at 1 in 80;
- wild titans, district music, and the Starter Park v3 rebuild.

Code and results are in `Calc/`: `kid_1311c.py` + `livekid4.py`, `nerd_v127.py`, `debate_v127.py`, and the `*_results.txt` files.

These are models built on estimated scores. The real check is a friends test plus the onboarding funnel after publishing.

## 1. Impatient kid (2,000 kids, median patience 11 s)
| version | 5 min stay | @7 s | @16 s | 1st buy | 1st evolve |
|---|---|---|---|---|---|
| A v126 + clicks 1.2 | 99% | 89% | 100% | 17.4 s | 8.4 s |
| **B LIVE v127** (+ AREA UNLOCKED at 2.4/4.5/8 m, Rogue Alert ~3.5 min) | **99%** | 89% | 100% | 16.9 s | 8.5 s |
| C + welcome coins 20 | 100% | 89% | 100% | 16.7 s | 8.5 s |
| D + first Rogue Alert at ~2 min | 99% | 86% | 100% | 17.5 s | 8.6 s |

- The first minutes are solved: 100% of kids are still playing through minute 2, with a NEW thing every ~3-6 s in the first 30 s.
- The area unlocks land at 29 s, 99 s and 176 s, and fill the old 3-5 minute gap together with the Rogue Alert at 212 s.
- An earlier Rogue Alert doesn't help, so it stays at ~3.5 min.
- More welcome coins make no real difference.
- No change is needed.
- Model fix during the run: the Rogue Alert first counted as "busy but no rewards", which wrongly cost 11 points. It now counts the HIT popups on every stomp.

## 2. Quality nerd (2,000 kids, 10-min walk that starts in the spawn park)
- **Honest miss:** the 13 Nov model said 0 tells while the owner saw an empty Starter Park. It used one prop density for the whole city. The walk now starts in the spawn park (the first ~2 minutes of every session).

| version | tells/10 min | top tells |
|---|---|---|
| P0 v120 (old park) | 5.1 | empty field 5.1 |
| P1 v124 park v3 | 0.0 | none |
| **P2 LIVE v127** (+ wild titans, Rogue, area walls) | **3.5** | wall in the way 1.5, plain NPC heads 1.5, grass patch 0.5 |
| P3 + NPC giants get faces/hair (or helmets) | 2.0 | wall in the way 1.5 |
| P4 + pond grass blended to the slab green | 1.5 | wall in the way |

- The area walls are a design choice (the lock signs explain them), so this tell is accepted.
- **Fixes to build:** give the NPC giants a proper head look, and blend the pond grass patch.

## 3. Debate kids (3,000 friend groups, rivals = top games Nov 2026)
| version | agree | 1st pick | top objection |
|---|---|---|---|
| **V0 LIVE v127** | **59%** | 67% | "nobody plays it, it's dead" (1,239 of 3,000 groups) |
| V1 + visible weekly-update board | 59% | 68% | it's dead |
| V2 + silly squeaky props | 59% | 69% | it's dead |
| V3 + launch push (ads, code, Saturday event, 10-slot servers filled fullest first) | 100% | 93% | none |
| V4 + 2-3 weeks of Saturday drops | 100% | 94% | none |

- "There's no real fighting" is gone (Sumo + Rogue).
- The ONLY objection left is the player count. That is a launch and marketing problem, not design: no design change moves it.
- Robust to every score ±1 once the crowd is there.

## Next
1. **NPC giant heads:** faces/hair or helmets.
2. **Pond grass patch:** blend it to the slab green.
3. **Launch plan:** set servers to 10 slots, filled fullest first (owner, in Game Settings), an ad push, and a code with a Saturday event.
4. **After launch:** a weekly-update board in the plaza.
