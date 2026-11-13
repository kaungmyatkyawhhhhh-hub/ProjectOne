# 2026-11-13 MEGA BITE - Kid simulations round 7 (debate, quality nerd, impatient)

Owner 11:52: "do /debate-kids-sim /quality-nerd-kid-sim /impatient-kid-sim". Run on the LIVE Studio build of 13 Nov about
12:00 (Titan Sea, giants, Kraken, hunters, chests, colossal fish, kit dressing, biome sounds). Nothing is published.
All three are MODELS. Measured = read or counted in Studio. Estimated = my scores or behaviour guesses. The real checks:
a playtest with real kids, phone screenshots, the onboarding funnel.
Code (this folder): `mb_longsim.py`, `run_long.py`, `run_meg.py`, `debate_v2.py` (needs `debatekids.py`), `nerd_v3.py`,
`*_out.json`. Earlier rounds: [[2026-11-13 MEGA BITE - Kid simulations on World v2 (round 6)]], `debate_results.txt` (9 Nov).

## 1. Impatient kid
### First 5 minutes (re-run of `r6.py`, 3,000 kids)
Nothing built today changes the first 5 minutes (the first Kraken is at 6:00, the giants and landmarks are further out), so
the numbers are those of round 6: stay at 5 min = 17% / 47% / 74% at patience 7 / 11 / 16 s; 82% reach the Barracuda at
median patience. Top quit place is still the repeat "eat" quests in the Open Sea as a Reef Shark.

### New: minute 5 to minute 90 (`mb_longsim.py`, the kids who are still there at 5:00)
Live numbers used: evolutions 25 / 200 / 620 / 2,400 / 10,000 / 40,000 EXP; eat length = model length (7, 9.1, 16, 16, 22.1,
28.1, 40); 15 fish (length, EXP, school); the fish list, hunters and EXP multiplier of every ring; chest and discovery =
share x the EXP span of your evolution (shares 0.08-0.20, refill 15 min); Kraken every 10 min (0.5% of the span a bite,
20% bonus, 60 of your own bites to beat it alone); slipstream (1 + evolution) EXP a second; red hunters every 3.5 min.
Estimated: a kid feeds at 55% of the best possible rate, which ring it picks, how often it finds things, the boredom meter.
Patience was set so that the game WITHOUT today's content keeps 46% of these kids to minute 15 (the old EXP sim's figure).

Fish EXP per minute (measured numbers, 55% kid): Clownfish 65-100, Barracuda and Reef Shark 245-265, Hammerhead 520 (Far
Deep), Great White 715 (Far Deep) or 1,140 (Titan Sea), Megalodon 1,680 (Far Deep) or 4,100 (Titan Sea).
That is about 2 min as a Clownfish, 2 as a Barracuda, 7 as a Reef Shark, 15 as a Hammerhead, 26-42 as a Great White.

| Version | stay 10 min | 15 | 20 | 30 | 45 | 60 | reach Great White | reach Megalodon (median) | EXP from |
|---|---|---|---|---|---|---|---|---|---|
| A before today (fish only) | 88% | 46% | 10% | 1% | 0% | 0% | 1% | 0% | fish 100% |
| B live today | 96% | 75% | 54% | 23% | 12% | 9% | 59% | 21% (28.5 min) | fish 51, chests 22, hunters 20, Kraken 7 |
| B without the Kraken | 96% | 74% | 42% | 13% | 6% | 4% | 46% | 10% | |
| B without chests | 92% | 56% | 26% | 5% | 0% | 0% | 6% | 0% | |
| E = B with Kraken and refill-chest rewards cut | 96% | 76% | 53% | 20% | 9% | 6% | 56% | 13% (31.5 min) | fish 57, chests 21, hunters 18, Kraken 4 |
(percent of the kids who were there at 5:00; same order at patience 90 and 200)
Reading:
- Today's content is what carries kids through the long stretches: every landmark, chest, Kraken and giant is a NEW thing
  in the Hammerhead and Great White grind (7,600 and 30,000 EXP), where the fish-only game lost everybody.
- Chests matter most (without them the model falls back to almost the fish-only curve), then the Kraken.
- Cutting the Kraken or the refill rewards does NOT help anything in the model (it only makes the Megalodon 3 min later and
  loses a few kids). So they stay as they are. The stay numbers themselves are soft; the order of the versions is the result.
- Where kids still quit: as a Hammerhead and as a Great White (the two long bars).
- Found by the numbers, fixed: following the turtle paid a Clownfish 180 EXP a minute for doing nothing (eating pays 65-100).
  `Giants.Turtle.ExpSecs = 45, ExpWindow = 240`: the EXP is paid for 45 s in any 4 min, the speed boost is unlimited.
  (`MB_GiantsServer`, backup `_preSlipCap_13Nov`; it parses, NOT play-tested.)

### What a Megalodon does next (`run_meg.py`, 3,000 fresh Megalodons)
| Game | median minutes as a Megalodon before Fossilize or quit | still a Megalodon at 10 min |
|---|---|---|
| before today | 3.2 | 1% |
| + Kraken, chests, giants | 3.3 | 2% |
| + red hunters | 4.3 | 8% |
| + colossal fish | 6.8 | 20% |
| + the Titan Sea (live now) | 6.3 | 13% |
| idea 1: + TITAN LEVELS (a bar that keeps filling, a reward each level) | 16.2 | 72% |
| idea 2: + 2 landmarks with chests in the Titan Sea | 7.5 | 25% |
| ideas 1 + 2 | 19.2 | 78% |
About 60% Fossilize in every row; the rest quit.
Reading: the owner was right ("megalodon have no point"): today's additions doubled the Megalodon's time (3 to 6 min), but
the Titan Sea alone adds nothing more, because it is one wow and then fish with no bar to fill and no hunt (the red
hunters stay in the Open Sea). What is missing is a GOAL: a bar. TITAN LEVELS is the biggest lever by far.

## 2. Quality-nerd kid (`nerd_v3.py`, 2,000 kids, 10 minutes each)
Measured on the live map (a kid 14 studs over the floor, a view every 2 s, 5 swims per zone; "same prop" = one prop name
is 9+ of the last 40 noticed; this round counts by prop NAME, round 6 counted by mesh):
| Zone | props per view | same-prop tells | empty views | set-piece wows | most repeated |
|---|---|---|---|---|---|
| Reef, 2 min | 36.0 | 5.0 (round 6: 7.2) | 0 | 2.2 | BubbleCoral |
| Open Sea r 300-720, 3 min | 24.6 | 9.6 (16.6) | 0 | 1.2 | Spire |
| Open Sea r 720-1150, 3 min | 20.8 | 11.6 (19.6) | 0.2 | 2.0 | Spire |
| Red Trench, 2 min | 8.5 | 12.8 (11.8) | 2.2 (1.0) | 2.0 | SeaFan |
| Titan Sea v1, 3 min | 10.2 | 12.6 | 3.2 | 2.4 | Kelp |
| Titan Sea v2 (fixed today), 3 min | 17.3 | 6.6 | 1.2 | 1.6 | RuinColumn, Kelp, WhipCoral |
Titan Sea fix (`MB_TitanDress`): kelp patches are 3 kelp + sea palms + tube sponges (were 5-7 kelp), patches 180 studs apart
(215), 560 singles (420). Now 2,437 props in 149 patches (was 1,463 in 86).

| Version | tells per 10 min | top tells | wows | like |
|---|---|---|---|---|
| A this morning (round 6) | 59.0 | same prop 55.4 | 9.0 | 1% |
| B live at 11:50 | 40.1 | same prop 35.9, empty 1.8 | 10.6 | 11% |
| C live now (Titan Sea v2) | 38.0 | same prop 34.3, empty 1.3 | 10.6 | 11% |
| D forecast: a third of the tall spires swapped for other tall shapes | 28.8 | same prop 25.2 | 10.5 | 20% |
| E forecast: D + half the trench sea fans swapped | 25.7 | same prop 22.6 | 10.6 | 23% |
Reading: a third fewer tells than this morning, more wows, but the goal (under 3 per 10 min) is far away and "same prop
again" is still nearly all of it. The cause is now clear: TALL props are seen from far away, so one tall kind fills the view
(spires in the Open Sea, sea fans in the Trench, kelp in the Titan Sea v1). Mixing the small props did not touch that.
Rule for the next dressing pass: no tall kind (over 40 studs) may be more than a fifth of the tall things in a region.
Estimated, not measured: props that do not react 1.0 per 10 min; pop-in 0.5 (Titan Sea 2.0: its water is clearer than the
600-stud cull line was tuned for); plain gold ring for the Titan Sea on the map. Check these by eye on a phone.
Fish Index tiles: redone twice today on the owner's word, not part of this count.

## 3. Debate kids (`debate_v2.py`, 3,000 friend groups of 3-5, our game + 3 rivals)
Round 1 (9 Nov) scored the PLAN with every launch feature. This round scores only what is in the build.
Rivals: the 10 of round 1 + DONT SPLASH, +1 Venom Evolution, Cat Battles, RIVALS, Adopt Me! (GGRecon 2 Nov 2026; Rowatcher
Jun 2026). Calibration: Brookhaven 34% agree, Blox Fruits 17%, Fish It! 59%, Be Fish 59%, DONT SPLASH 19%, DEVOUR 1%.
Live build scores (my estimates, 0-10): first minute 8, depth 8, social 5, PvP thrill 7, PvP safety 8, fair money 8, looks 7,
cute/funny 6, scary 4, players online 1, updates 4, phone 6, easy 8, new 7, collect 7, show-off 7, ocean 10, original 7.
Why social is 5: 60-player servers, the Kraken and the lamp are shared, but there is no crew, no join-a-friend, nothing two
friends do as a pair. Why updates is 4: nothing in the game shows that updates are coming. Phone 6: not tested on a device.
| Version | everyone agrees | 1st pick | top objections (groups of 3,000) |
|---|---|---|---|
| L0 the live build | 34% | 41% | "we can't even play TOGETHER" 1,243; "nobody plays it, it's dead" 1,195 |
| L1 + PLAY TOGETHER (join a friend, crew of 4, crew bonus at the Kraken) | 60% | 54% | "nobody plays it" 1,195 |
| L2 + update board at spawn (countdown, what is next, a Saturday event) | 60% | 57% | same |
| L3 + phone pass measured on a cheap phone | 60% | 59% | same |
| L4 + launch crowd (marketing: fill servers first, creators) | 100% | 80% | none |
| L5 + launch push (code + event day) | 100% | 84% | none |
Robust to every score +-1 at L5 (worst 100% agree). At L0 the phone score sits exactly on the Cheap-phone kid's limit:
one point lower brings "it lags on my phone" back, so the phone test is not optional.
Example debates on the live build: Social kid + PvP sweat + Quality nerd choose Cat Battles; Grinder + Quality nerd + Social
kid choose RIVALS. Both times the only thing said against MEGA BITE is "we can't even play TOGETHER".
Reading: no kid in the model objects to the game's depth, looks, fairness, fear or first minute any more. Two objections are
left: one is design (playing together), one is marketing (an empty game at launch).

## What to build next (in this order)
1. TITAN LEVELS: a bar for the Megalodon (every 20,000 EXP = a level, a reward and a little growth). Model: 6 to 16 min.
2. PLAY TOGETHER: join a friend, a crew of up to 4, a crew bonus at the Kraken. Model: 34% to 60% of friend groups.
3. Tall props: swap a third of the spires and half the trench sea fans for other tall shapes (forecast 38 to 26 tells).
4. Something to find in the Titan Sea (a landmark with a chest), and let the red hunters come there too.
5. Update board at spawn; phone test on a real device before launch.
Not changed on purpose: Kraken and chest rewards (cutting them helped nothing in the model).
