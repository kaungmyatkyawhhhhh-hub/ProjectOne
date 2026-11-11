---
date: 2026-11-11
tags: [stomp-evolution, titan, kid-sims, impatient-kid, quality-nerd, debate-kids, design]
status: done on the PLAN (no build exists). Re-run all three on the live config before any launch.
---
# Stomp Evolution: the three kid simulations (11 Nov, 01:40 MMT)

Owner: "ok what will the game be about use quality-nerd-kid-sim and impatient-kid-sim and debate-kids-sim".
Game: [[2026-11-11 TITAN ARC - Design doc v0 (draft)]] (now named Stomp Evolution; the vault folder is still TITAN ARC). Methods: [[Impatient kid simulation]], [[Quality-nerd kid simulation]], [[Debate kids simulation]].
Code + raw results: `TITAN ARC/Calc/impatientkid.py`, `nerdkid.py`, `debatekids.py` and the three `*_results.txt`.

**Honest start:** all three methods say "read the live game". There is no game yet, so these ran on the plan's numbers. They are good for choosing between designs. They are not proof kids will stay.

## What the game is about (the answer the sims gave)
**You are a small creature in a toy city. Stomp to grow, and every half minute you EVOLVE into something bigger with a new look and a new move, until you step over towers. Everyone sees how big you are. The biggest wears the crown, and the whole server fights a Rampage together.**
1. **Evolution is the game.** 8 forms before the first boss, the first at about 28 seconds, each with its own kit, move and cutscene. With 3 forms (plan v0) a quarter of kids were gone by minute 5.
2. **The city has to look hand-made.** The plan had one house copied down the street, one crumble effect and buildings that pop back: 115 cheap tells in 10 minutes. Fixed in the plan to under 1.
3. **Friends must have a reason to pick it.** Fighting was missing (the Sumo Ring moved to launch, the Rampage is the crown holder against the server), and the first minute and the look were the two biggest "no" reasons.
4. **What design cannot fix:** "nobody plays it". With a small launch crowd, 4 in 10 friend groups still say no.

## 1. Impatient kid (2,000 kids per version, patience median 11 s)
How the kid works: he walks the street and stomps the next prop; he buys an upgrade when he can afford one and notices it. Boredom rises 1 per second with nothing to do, half that while something is pressable, less when a bar is about to fill, more after 25 s with nothing NEW. Repeats wear off; new things count most. Kids are 1.25-1.7x slower than the pacing bot.
```
IMPATIENT KID on the PLAN (2,000 kids per version, patience median 11 s)
version                                                                    15s  30s  60s  2min 3min 5min | 5min@7s | 1st buy 1st evolve | no-NEW gap: min1  5min | evolves by 5min | boss (bot)
A  the plan v0 (first evolve at 2.2 m, flowers only until then)            100% 100% 100% 100%  95%  74% |   32%   |  3.2 s   97.0 s   |      23.8 s  87.8 s |       1        |  9.9 min
B  + evolution-first: 7 evolves before the boss, the first at 1.9 m        100% 100% 100%  99%  98%  92% |   60%   |  3.2 s   39.8 s   |      23.7 s  59.5 s |       4        |  9.9 min
C  + 3 prop kinds on the first street (flower, mailbox, bin)               100% 100% 100% 100%  99%  96% |   72%   |  3.2 s   39.5 s   |      19.7 s  59.4 s |       3        |  9.9 min
D  + step-on upgrade pads along the street (no detour)                     100% 100% 100% 100% 100% 100% |   98%   |  3.0 s   36.6 s   |      22.0 s  53.5 s |       4        |  9.9 min
E  + a golden prop for every new player at ~25 s, first Ground Pound at stomp 6 100% 100% 100% 100% 100% 100% |   98%   |  3.0 s   27.9 s   |      28.4 s  47.5 s |       4        |  9.7 min
F  + 3 visible growth stages inside each form                              100% 100% 100% 100% 100% 100% |   99%   |  3.0 s   27.9 s   |      28.2 s  40.2 s |       4        |  9.7 min
G  + a small street event every ~70 s after minute 2.5                     100% 100% 100% 100% 100% 100% |   99%   |  3.0 s   27.9 s   |      28.3 s  40.0 s |       4        |  9.7 min
H  + fill the 30-60 s hole: bikes at 2.05 m, second evolve at 2.4 m        100% 100% 100% 100% 100% 100% |   99%   |  3.0 s   27.8 s   |      14.4 s  34.2 s |       6        |  9.5 min

sensitivity, patience  7 s: A stays 60 s 98% / 5 min 32%   ->   last version 60 s 100% / 5 min 99%
sensitivity, patience 16 s: A stays 60 s 100% / 5 min 94%   ->   last version 60 s 100% / 5 min 100%

last version, one median kid, NEW things in the first 60 s:
  0s gift  2s new upgrade  8s newprop  12s giant seen  15s ground pound  15s stage  15s stage  17s newprop  24s new upgrade  26s golden  26s evolve  28s newprop  29s stage  45s stage  48s evolve  58s new upgrade  64s stage
```
- **What was wrong in the plan:** the first minute was fine (stomping is instant), but nothing NEW came for long stretches. The first evolve was at 97 s for a real-speed kid (the bot said 57 s), and kids had only 1 evolve in 5 minutes. Longest stretch with nothing new in 5 minutes: 88 s.
- **What moved the numbers:** B (evolution-first) 74% → 92% at 5 minutes; C (3 prop kinds on the first street) → 96%; **D (step-on pads on the street, no detour) → 100%, and for very impatient kids 72% → 98%**: the biggest single change; E (a golden prop at ~25 s + an early Ground Pound) brings the first evolve to 28 s; H closes the hole between 30 and 60 s (second evolve at ~48 s, longest stretch with nothing new in minute 1: 28 s → 14 s).
- **What did not move them:** F (growth stages) and G (street events) change nothing at median patience. F is kept because it cuts the longest quiet stretch in 5 minutes (47 s → 40 s). G is not needed for launch.
- **The big moment barely moved:** the boss is at 9.9 → 9.5 minutes for the bot.
- **Winning first minute:** 0 s gift · 2 s first upgrade · 8 s second prop kind · 12 s a giant player walks past · 15 s first Ground Pound · 17 s third prop kind · 26 s golden prop → **28 s EVOLVE** · 28 s bikes · 45 s growth stage · **48 s second EVOLVE**.

## 2. Quality-nerd kid (2,000 kids, a 10-minute walk)
How the kid works: he looks at a view every 2 s and counts cheap tells and wows. Where the design doc says nothing (set pieces, moving things, borders, streaming), version A assumes the cheap default, because that is what gets built when nothing is written down. Two tells were added for this game: "same crumble every time" and "buildings pop back".
```
QUALITY-NERD KID on the PLAN (2,000 kids, a 10-minute walk; trust tells per 10 min, not the like %)
version                                                                        likes  tells/10min  wows/10min  worst kind  top tells
A  the plan v0: 6 prop kinds per district, one crumble, props pop back            0%   115.2        10.7      65.5     same prop again 65.5, nothing reacts 14.9, same crumble every time 14.9
B  + 3 look-alike variants of every breakable prop (colours, roofs)               0%    50.3        10.7      15.0     nothing reacts 15.0, same crumble every time 14.9, buildings pop back 9.0
C  + a 12-mesh dressing kit (lamps, benches, trees, signs, fences)                0%    49.8        10.7      14.9     nothing reacts 14.9, same crumble every time 14.9, buildings pop back 8.9
D  + a hand-made set piece every ~250 studs that breaks in 3 stages               0%    56.0        23.9      15.1     same crumble every time 15.1, nothing reacts 14.9, pop-in 10.8
E  + moving life: toy cars swerve, birds scatter, lights blink, alarms            1%    40.4        23.9      15.1     same crumble every time 15.1, pop-in 10.8, buildings pop back 9.1
F  + 5 crumbles by material, rubble stays, a visible rebuild                     37%    16.3        24.0      10.8     pop-in 10.8, districts look the same 2.0, invisible wall 2.0
G  + district identity (palette, light, music), natural borders, streaming tuned   99%     1.5        25.8       1.5     new form is just bigger 1.5, same prop again 0.0
H  + evolution-first: 8 forms in 10 min, each with its own kit + cutscene       100%     0.0        33.9       0.0     same prop again 0.0
```
- **Top tells on the plan:** the same prop again (65 per 10 min: the game makes you stomp one kind of thing over and over, so copies are in your face), nothing reacts, the same crumble every time.
- **What to build, in order of effect:** 3 look-alike variants of every breakable prop (115 → 50 tells) · moving life: toy cars that swerve, birds that scatter, blinking lights, alarms (→ 40) · 5 crumbles by material + rubble that stays + a visible rebuild (→ 16) · district identity, natural borders (sea, cliffs, a train line), streaming tuned so set pieces never pop in (→ 1.5) · every form with its own kit and cutscene (→ 0).
- **What did not move the number:** a 12-mesh dressing kit (C) once the variants exist. Low priority.
- Set pieces (D) double the wows (11 → 24) but add pop-in until streaming is tuned: build them together.
- The like % is all-or-nothing in this model; trust tells per 10 minutes. Goal met in the plan: under 3 tells, no kind above 1.

## 3. Debate kids (3,000 friend groups of 3-5, our game + 3 random rivals)
Rivals: the top live games on 11 Nov 2026 (Roblox Top Playing Now: Steal An Egg 613K, Murder Mystery 2 603K, Brookhaven 349K, Blox Fruits 267K, Throw Food For Animals 184K, Steal a Brainrot 114K, 99 Nights 103K) and our genre (+1 Venom Evolution 24K, Depth Incremental 21K, Bug Evolution 14K, Muscle Legends 2.5K, Grow And Build Giants 2.5K, +1 Titan Evolution 1.7K, Titanus Simulator 2). Scores 0-10 are my estimates from players, likes, age and page text.
```
CALIBRATION (each rival as 'our game' against the others): everyone agrees / 1st pick
  Steal An Egg (613K)               17%   27%
  Murder Mystery 2 (603K)           34%   23%
  Brookhaven RP (349K)              34%   28%
  Blox Fruits (267K)                18%   25%
  Throw Food For Animals (184K)     34%   52%
  Steal a Brainrot (114K)           17%   18%
  99 Nights (103K)                  35%   23%
  +1 Venom Evolution (24K)          33%   43%
  Depth Incremental (21K)           17%   22%
  Bug Evolution (14K)               16%   12%
  Muscle Legends (2.5K)             33%   26%
  Grow And Build Giants (2.5K)      33%   36%
  +1 Titan Evolution (1.7K)          4%    7%
  Titanus Simulator (2, dying)       1%    2%

version                                                                              agree  1st pick  top objections (groups out of 3,000)
S0  the plan v0 (before the other two sims' fixes)                                      9%    16%    first_min: "it's boring at the start" 1266; crowd: "nobody plays it, it's dead" 1239; looks: "it looks like AI slop" 1177
S1  + first-minute fixes (impatient sim H: evolve at ~28 s, pads on the street)        18%    27%    crowd: "nobody plays it, it's dead" 1239; looks: "it looks like AI slop" 1177; pvp_thrill: "there's no real fighting" 1160
S2  + hand-made look (nerd sim H: variants, set pieces, life, crumbles, form kits)     34%    42%    crowd: "nobody plays it, it's dead" 1239; pvp_thrill: "there's no real fighting" 1160
S3  + SUMO RING at launch (size brackets) + Rampage = the crown holder vs the server   59%    57%    crowd: "nobody plays it, it's dead" 1239
S4  + funny and cute: squeaky toy city, silly props, a pet-size first form             59%    59%    crowd: "nobody plays it, it's dead" 1239
S5  + full servers: fill the fullest first, 10 slots, NPC stompers in the city        100%    82%    none
S6  + the difference up front: city + crown + Rampage in minute 1 and on the icon     100%    85%    none
S7  + depth at launch: 8 forms, 3 districts, Smash Index, AWAKEN                      100%    89%    none
S8  + visible weekly updates: board in the plaza, countdown, a code                   100%    92%    none
S9  + launch push (marketing, not design): ads + code + Saturday event                100%    93%    none

robustness (every score of ours +-1, 60 tries): agree median 100% (worst 100%), 1st pick median 92%
  objections that came back (tries out of 60): none
if the launch crowd is only 2/10: agree 59%, 1st pick 68%, top: [('crowd: "nobody plays it, it\'s dead"', 1239)]
if the launch crowd is only 3/10: agree 59%, 1st pick 70%, top: [('crowd: "nobody plays it, it\'s dead"', 1239)]

GROUP 1: Quality nerd, Bored-fast kid, Social kid  |  on the table: STOMP EVOLUTION, Grow And Build Giants (2.5K), Blox Fruits (267K), Titanus Simulator (2, dying)
   BEFORE  Quality nerd: "it looks like AI slop"; Bored-fast kid: "it's boring at the start"  -> they play Grow And Build Giants (2.5K)
   AFTER   nobody says no to STOMP EVOLUTION  -> they play STOMP EVOLUTION

GROUP 2: Little sister (7), Giant fan (8), Cheap-phone kid, Quality nerd, Grinder  |  on the table: STOMP EVOLUTION, +1 Titan Evolution (1.7K), Bug Evolution (14K), Muscle Legends (2.5K)
   BEFORE  Quality nerd: "it looks like AI slop"  -> they play Bug Evolution (14K)
   AFTER   nobody says no to STOMP EVOLUTION  -> they play STOMP EVOLUTION

GROUP 3: PvP sweat, Little sister (7), Cheap-phone kid, Bored-fast kid  |  on the table: STOMP EVOLUTION, Steal a Brainrot (114K), +1 Titan Evolution (1.7K), Depth Incremental (21K)
   BEFORE  PvP sweat: "there's no real fighting"; Bored-fast kid: "it's boring at the start"  -> they play Steal a Brainrot (114K)
   AFTER   nobody says no to STOMP EVOLUTION  -> they play STOMP EVOLUTION
```
- **Calibration:** big games land at 16-35% "everyone agrees" and the dying copy at 1%. The model is harsh (the target was 20-60%; +1 Titan Evolution has 1.7K real players and scores 4%), so read our numbers against the rivals, not as a forecast.
- **Top objections to the plan, in the kids' words:** "it's boring at the start", "nobody plays it, it's dead", "it looks like AI slop", "there's no real fighting".
- **Which fix raised what:** first-minute fixes (first_min 6 → 8) 9% → 18% · hand-made look (looks 4 → 8) → 34% · **Sumo Ring at launch + Rampage as the crown holder against the server (pvp_thrill 3 → 7) → 59%** · full servers (crowd 1 → 4) → 100%.
- **Margin, not vetoes:** funny + cute (S4) did not change the number because the score sat exactly on the little sibling's limit; it stays in as safety. S6-S8 (the difference up front, depth, visible updates) lift 1st pick from 82% to 92%.
- **Robust:** every score moved ±1 at random 60 times: 100% agree every time, no objection came back.
- **Marketing, not design:** if the launch crowd is only 2-3 out of 10, agreement falls to 59%. Only players in the servers fix "it's dead".

## Changes to the game plan (all in the design doc now)
| # | Change | From which sim |
|---|---|---|
| 1 | 8 forms before the first boss at 1.9 / 2.4 / 3.0 / 4.5 / 8 / 13 / 21 / 28 m, each with its own kit, move and cutscene | impatient B+H, nerd H, debate S7 |
| 2 | 3 prop kinds on the first street; bikes unlock at 2.05 m | impatient C, H |
| 3 | Upgrade pads are step-on pads along the street, one per block | impatient D |
| 4 | A golden prop near every new player at ~25 s; first Ground Pound at stomp 6 | impatient E |
| 5 | 3 visible growth stages inside each form | impatient F |
| 6 | 3 variants of every breakable prop; 5 crumbles by material; rubble stays; a visible rebuild | nerd B, F |
| 7 | Moving life in the city; a set piece every ~250 studs that breaks in 3 stages; streaming tuned | nerd D, E, G |
| 8 | District identity (palette, light, music) and natural borders | nerd G |
| 9 | Sumo Ring at LAUNCH (size brackets); the Rampage is the crown holder against the server | debate S3 |
| 10 | Funny + cute: squeaky toy city, silly props, a pet-size first form | debate S4 |
| 11 | 10-slot servers filled fullest first, NPC stompers so the city is never empty | debate S5 |
| 12 | The difference in minute 1 and on the icon: the city, the crown, the Rampage | debate S6 |
| 13 | A weekly-update board with a countdown in the plaza | debate S8 |

## Not done, and why
- **No Claude Code prompt:** the methods end with one, but there is no place to send it to. These changes are plan values; the first slice prompt comes when the owner says go.
- **No by-eye check:** nothing to screenshot yet. The nerd model must be followed by phone screenshots against the K06 rules.
- **The real checks:** a friends test (ask each kid what he would play instead and why), then the onboarding funnel and likes after a test build.
