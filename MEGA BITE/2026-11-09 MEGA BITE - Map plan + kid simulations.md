---
date: 2026-11-09
tags: [megabite, map, simulation, impatient-kid, quality-nerd-kid, design]
status: design stage (no build yet). Numbers are a model to compare map designs.
---
# MEGA BITE: map plan + impatient-kid and quality-nerd-kid simulations (9 Nov)

Owner: "we need to discuss the map too. use the impatient-kid-sim for the map and quality-nerd-kid-sim too."
Methods: [[Impatient kid simulation]], [[Quality-nerd kid simulation]] (new). Research: [[2026-11-09 MEGA BITE - Full research report]], [[2026-11-09 MEGA BITE - Notes - Map and world]].
Code: `MEGA BITE/Calc/mapsim.py` (run `python mapsim.py`), output in `results.txt`.

## The two kids
- **Impatient kid** (2,000 per version, patience median 11 s): eats the nearest fish (reaction 0.6-2.2 s), follows the guide to the Open Sea after the first evolve, banks when the bag is full. Boredom fills while nothing happens (faster on long empty swims), empties on bites (wear off slowly), SIZE jumps, new fish, landmarks, banks, evolves, events. Quits when boredom passes his patience.
- **Quality-nerd kid** (2,000, 10-minute swim): looks at a view every 2 s. Counts cheap/AI-slop tells (same prop again, empty view 6 s+, fish that don't react, pop-in, zones that look the same, invisible walls) and wows (hand-made set pieces, a zone that looks and sounds different). Then likes, dislikes or doesn't vote.

## Results (cumulative versions)
| Version | Stay 60 s | Stay 2 min | **Stay 5 min** | Nerd: tells / 10 min | Nerd like ratio |
|---|---|---|---|---|---|
| A DEVOUR-like: big map, sparse food, 1 bank, few landmarks | 86% | 63% | **0%** | 104 | 0% |
| B + compact map (~2,000 studs), food 2x denser on the route | 99% | 73% | 5% | 104 | 0% |
| C + a set piece every ~15 s of swimming + a guide current | 98% | 74% | 13% | 112 | 0% |
| D + bank vents every ~30 s of swimming | 99% | 75% | 25% | 112 | 0% |
| E + ambient life (schools scatter, kelp) + 14-mesh kit | 100% | 82% | 39% | 25 | 40% |
| F + zone identity, natural borders, streaming tuned | 100% | 82% | 39% | **1.8** | 99% |
| G + nothing dropped below Reef Shark (keep 25% after) | 100% | 88% | 58% | 1.8 | 99% |
| H + red outline warns of predators, DART dodges | 100% | 91% | 63% | 1.8 | 99% |
| I + a food current along the routes to the vents | 100% | 92% | 67% | 1.8 | 99% |
| J + a BAIT BALL event every ~60 s in the Open Sea | 100% | 92% | 73% | 1.8 | 99% |
| **K + FRENZY at Piranha + ~1 shiny fish a minute** | **100%** | **96%** | **83%** | **1.8** | **99%** |
- Sensitivity (stay 5 min): very impatient kids (7 s) A 0% → K 48%; patient kids (16 s) A 2% → K 96%. Seeds 1/3/4 agree within ±2 points.
- **Tested and dropped (no gain):** a smaller first bag (an earlier bank trip = more empty swimming); Barracuda at 60 EXP instead of 90 (no change).
- The nerd's like ratio is a model artifact (0% or 99%); trust the **tells per 10 min** column: 104 → 1.8.

## What it says
1. **Empty swimming is the killer.** The biggest wins were the ones that put food or something new on every route: a compact map, set pieces every ~15 s, several vents, a food current to the vents.
2. **Losing what you carry makes new kids quit** (58 → 63% from G + H alone). Matches the research (nothing dropped below Reef Shark tier).
3. **Ambient life is the cheapest quality win** for both kids: fish schools that scatter and kelp that sways took tells from 112 to 25 and 5-min stay from 25 to 39%.
4. **Zone identity + natural borders + streaming tuning** remove the last AI-slop tells (pop-in, look-alike zones, invisible walls).
5. **Still short of the 95% goal at 5 min (83%).** The next fixes are content, not map: tune the EXP curve (Barracuda already comes at ~2 min in the model, faster than the research's ~5 min), and test a real build with the onboarding funnel.

## Map plan (version K)
| Zone | Size (studs) | Swim time to cross (20 st/s) | Look / sound | What's there |
|---|---|---|---|---|
| Safe Reef (spawn, bank) | ~400 across | ~20 s | bright turquoise, sun rays, calm music | food every ~22 studs, the evolve shrine, the 10 s try-an-ability shrine, your lair later |
| Open Sea ring | ~700 wide band | ~35 s | deeper blue, light shafts, faster beat | food every ~45 studs, NPC predators with red outlines, bait balls every ~60 s, bank vents every ~600 studs |
| Red Trench (PvP) | ~500, deeper | ~25 s | red glow vents, darker, a drum loop | rare glowing food, the crown shark marked on the map, sea mines |
| Squid cave | 1 set piece | - | ink-black + bioluminescence | the boss every ~15 min |
- Whole map ~2,000 studs across; a free compass + minimap.
- **Set pieces every ~300 studs (~15 s)** on the main routes: shipwreck, sunken statue, whale skeleton, coral arch, a kelp forest, the vent field. Each one tall enough to see from the zone before, each a reason to go there.
- **A glowing current** leads from the spawn to the Open Sea and from every route to the nearest vent; it carries food.
- **Natural borders only:** rock walls, a strong current that pushes you back, a dark deep drop (no invisible walls).
- Kit: ~14 reused meshes (rocks x4, coral x4, kelp x2, wreck parts x3, a vent), dense around set pieces. Fish schools client-animated, pooled (research: 500 NPCs at 20 Hz ≈ 15 KB/s).
- Roblox setup: Terrain Water, WaterTransparency ~0.1-0.3 + high Ambient (check on a phone), StreamingEnabled with landmarks as persistent models and low-detail stand-ins far away, PauseOutsideLoadedArea.

## Honesty
A model, not players. It compares map designs; the swim speed, food spacing and reward sizes are guesses from the research. The real check: a vertical-slice build, the impatient-kid sim on its real numbers, then the onboarding funnel with real kids.
