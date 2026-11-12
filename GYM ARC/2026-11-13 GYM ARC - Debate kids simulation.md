---
date: 2026-11-13
tags: [gymarc, sim, debate-kids, retention, plan]
---
# GYM ARC: Debate kids simulation (13 Nov, build v1882)

Owner (13 Nov, 03:11): "run /debate-kids-sim on our game". Run on autopilot (past the midnight limit). Method: [[Brain/Methods/Debate kids simulation]]. Code + output: `GYM ARC/Calc/debatekids_gymarc.py`, `Calc/debatekids_gymarc_results.txt`.

**Result: today only 4% of friend groups have nobody vetoing GYM ARC (11% would pick it first).** Five objections hit about equally hard. Six design fixes plus a launch push take it to 100% (93% first pick), robust to ±1 on every score. **The one that design can't fix: "nobody plays it, it's dead"** (56 players now). That one is marketing.

## How it works
- 3,000 friend groups of 3-5 kids (10 kid types), each choosing between GYM ARC and 3 rivals. Half the groups already want a gym game (rivals from the gym genre), half pick from the big hits.
- Friends only play a game NOBODY vetoes; among those, the best total score.
- **Rivals, live players checked 13 Nov ~03:00 MMT:** Gym Star 3,244 · Power Lifters 3,169 · Muscle Legends 2,412 · Arm Wrestle Sim 1,830 · +1 Break Walls 1,100 · Gym League 622 · Project: Iron 301 · **GYM ARC 56**. Big hits: Brookhaven, Steal a Brainrot, 99 Nights, MM2, RIVALS, DONT SPLASH.
- **Calibration (no veto, any group):** Arm Wrestle Sim 60%, RIVALS 59%, Gym Star / 99 Nights / Power Lifters / Brookhaven / MM2 / DONT SPLASH 33-35%, Steal a Brainrot / Gym League / Muscle Legends 17-18%, +1 Break Walls 9%, Project: Iron 1%. In range (big games 20-60%, small ones near 0).
- **GYM ARC's starting scores** (from the 12 Nov critic review, the funnel note and the owner's 13 Nov report that it gets dislikes for lag):
  - first minute 7, depth 8, social 5, PvP thrill 4, fair money 5, looks 7, cute/funny 5, crowd 2, updates 8, **phone 4**, easy 7, new 6, collect 7, show-off 8, gym theme 10, original 7.

## Versions (cumulative)
| Version | Agree | 1st pick | Top objections left |
|---|---|---|---|
| G0 today (v1882) | **4%** | 11% | pay to win 1,241 · lag 1,223 · dead 1,202 · can't play together 1,192 · no fighting 1,160 |
| G1 + LAG PASS: auto low-end mode on phones, stream out the far town, fewer parts/triangles, particle caps | 8% | 18% | pay to win, dead, together |
| G2 + FAIR MONEY: no full-screen pack before Spurt 2, no "worth / save % / 30 min only" anywhere, a free daily boost, no pay-only walls | 18% | 33% | dead, together, fighting |
| G3 + PLAY TOGETHER: JOIN FRIEND button, SPOT ME duo lifts (+EXP for both), crew gym sessions | 35% | 46% | dead, fighting |
| G4 + REAL PVP: arm wrestle any player (ranked, weekly board), posing show voted by players | 60% | 63% | dead |
| G5 + full-feeling servers: fill the fullest server first, 12 slots, NPC gym regulars | 60% | 66% | dead |
| G6 + margin: first rep within 10 s; a goofier bully and funny poses | 60% | 70% | dead |
| G7 + launch push (**marketing**): ads, creators, the ELEMENTS event, a code | **100%** | **93%** | none |

- Groups that want a gym game: 100% agree, 99% first pick. Groups choosing among the big hits: 100% / 86%.
- **Robustness:** every score ±1 at random, 60 tries: agree median 100% (worst 100%), first pick median 91%. No objection comes back.
- **Crowd test:** if the crowd stays 2-3/10 (where it is now), everything else fixed still gives only **60%**. It needs to read as 4/10 (a few hundred players in busy servers) for 100%.

## Example debates (same groups, before → after)
1. Quality nerd + Bored-fast kid + Social kid vs Arm Wrestle Sim, Gym Star, Project: Iron.
   - Before: the Social kid says "we can't even play TOGETHER", so they go to Gym Star.
   - After: nobody vetoes, and they pick GYM ARC.
2. Little brother + Gym fan + Cheap-phone kid + Quality nerd + Grinder vs +1 Break Walls, Gym League, Power Lifters.
   - Before: the Cheap-phone kid says "it lags on my phone", so they go to Gym League.
   - After: they pick GYM ARC.
3. PvP sweat + Little brother + Cheap-phone kid + Bored-fast kid vs +1 Break Walls, Muscle Legends, Arm Wrestle Sim.
   - Before: "you can't even fight anyone" plus "it lags", so they go to Arm Wrestle Sim.
   - After: they pick GYM ARC.

## What this changes in the plan (priority order)
1. **Lag pass first.** It's the owner's own 13 Nov complaint (dislikes), and every "cheap phone" group vetoes. It's also needed before any ad money, since ads bring phone kids.
2. **Fair money:** finish the critic fix: no full-screen pack before Spurt 2, no anchor prices or fake timers anywhere, and a free daily boost so No-Robux kids see a path.
3. **Play together:** a JOIN FRIEND button and SPOT ME duo lifts. These are the cheapest real social features for a gym game.
4. **Real PvP:** player-vs-player arm wrestling with a weekly ranked board (the tables and tug-of-war already exist; it needs matchmaking and a board), and posing shows voted by players.
5. **Servers:** fill the fullest server first, with smaller servers, so 56 players feel like a busy gym.
6. **Marketing, not design:** "it's dead" only goes away with players. Use the ELEMENTS launch on Saturday, ads (the shareholder), creators and a code. Ads before fixes 1-2 would bring lag and pay-to-win vetoes.

## Honest limits
- This is a model of arguments with estimated scores; the "after" scores assume each fix lands well.
- The real check:
  - a friends test: ask each kid what they'd play instead, and why;
  - the onboarding and Intro funnels after the next publish;
  - the like ratio after the lag pass.
