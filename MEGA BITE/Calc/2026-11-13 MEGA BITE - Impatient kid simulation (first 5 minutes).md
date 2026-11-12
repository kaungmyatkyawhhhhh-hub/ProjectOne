# MEGA BITE - impatient-kid simulation of the first 5 minutes (13 Nov 2026, 00:00-00:40)
Owner: "ok do the /impatient-kid-sim" (after [[2026-11-12 MEGA BITE - First minute pass 1 (swim hint, welcome school, EAT marker, funnel)]]). Method: [[impatient-kid-sim]] skill / Galaxy's kidsim. Code: `Calc\mb_kidsim.py` + `Calc\variants.py` (this folder).

## Live numbers read from Studio (12 Nov 23:50)
- Evolve: Minnow -> **Piranha 25 EXP** -> Barracuda 200. Reef x1, Open Sea x2.
- Reef food a Minnow can eat: Shrimp (10 schools of 6, 1 EXP), Damsel (14 x 2, 1), Puffer (9 x 1, 2), Sardine (any zone, 9 x 7, 1). Open Sea: Mackerel 5 x 5 (3), Squid 6 x 3 (4), Tuna (too big early).
- Quests: Eat 5 (+3) -> Eat 10 (+5) -> Find 3 kinds (+6) -> Grow into a PIRANHA (+10) -> Swim out to the OPEN SEA (+10) -> Eat 15 in the Open Sea (+20) -> DART away from a predator (+30) -> Grow into a BARRACUDA (+40).
- Fish Index: every 3 new species +10 EXP. Golden fish first at 40 s, then every 120 s (25 EXP, anywhere). Body grows every 8 bites.
- Spawn (0,14,-24); the Safe Reef is radius 300; nearest school after the welcome school measured ~100 studs; the Open Sea ring starts at 300.

## The kid model
- 55 % already know how to swim; the rest need the hint (after 3 s) + 1-3 s to get it (without the hint: ~15 %/s chance to find the controls).
- Swims ~15 studs/s x skill (0.75-1.3); schools are a lognormal gap apart (reef median 55 studs, open median 90); ground arrows make travel faster and less boring.
- Each fish takes 0.6-1.5 s to catch; it catches 55-90 % of a school.
- Boredom +1/s; x0.3 while chasing fish; x0.75 when an arrow / marker guides it; x1.4 when lost (nothing to follow); x0.7 when the evolve bar is over 70 %; x1.3 after 25 s with nothing new.
- Rewards: a bite 2.6 (wears off with every bite), a NEW fish card 7, a quest 6, an Index page 5, the body growing 3.5, an evolve 25, the golden-fish shout 2.
- Patience lognormal, median 11 s (also 7 and 16). 2,000 kids per version.
- **Honest limits:** the long-run numbers (2-5 min) are far too low in absolute terms: the model has no fun in exploring, PvP, skins or friends. Use it to RANK changes and find where kids get stuck, not as a forecast. The real check is the onboarding funnel (MB_Funnel) after launch.

## What was wrong in the live build (second by second, median kid)
- 0-5 s: fine after tonight's pass 1 (first bite median 5 s; the hint lifted "stay 15 s" from 88 % to 96 %).
- 5-34 s: eat the welcome shrimp, follow the ground arrows from school to school; Piranha at ~34 s (88 % get there).
- **After the Piranha: the ground arrows switch off** -> kids wander between schools ("lost").
- **Quest "Swim out to the OPEN SEA": no pointer**, a 150-260 stud trek by the minimap -> the biggest quit point (51 % of all kids quit there).
- In the Open Sea the next school is ~90 studs away -> the second quit point.

## Versions (cumulative, median patience 11 s)
| Version | 15 s | 30 s | 60 s | 120 s | first bite | Piranha at | Barracuda by 5 min | top quit point |
|---|---|---|---|---|---|---|---|---|
| A0 before tonight (no hint, school leaves at 8 s) | 88.0% | 78.7% | 16.9% | 0.3% | 4.7 s | 33.1 s | 0.2% | lost on the way to the Open Sea 46% |
| A live (first-minute pass 1) | 96.3% | 88.3% | 18.3% | 0.2% | 5.0 s | 33.7 s | 0.2% | lost on the way to the Open Sea 51% |
| B + arrows to fish also as a Piranha | 96.3% | 90.1% | 27.6% | 0.5% | 5.0 s | 33.7 s | 0.2% | lost on the way to the Open Sea 80% |
| C + arrows to the OPEN SEA during that quest | 96.3% | 90.5% | 57.3% | 3.8% | 5.0 s | 33.7 s | 1.6% | lost in the Open Sea 41% |
| D + a welcome school at the Open Sea edge | 96.3% | 90.5% | 60.8% | 14.2% | 5.0 s | 33.7 s | 16.7% | the trek itself 36% |
| E + a shorter trek (Open Sea gate near spawn) - NOT built (a map change) | 96.3% | 90.5% | 69.9% | 14.1% | 5.0 s | 33.7 s | 19.0% | lost in the Open Sea 51% |

Sensitivity (A vs B+C+D): patience 7 s: 60 s stay 5.7 % -> 27.9 %; 11 s: 18.9 % -> 61.2 %; 16 s: 38.1 % -> 84.9 %, Barracuda by 5 min 1.1 % -> 37 %. Same direction at every patience. The Piranha time (34 s) does not move: the first evolve stays as tuned.

## Built (13 Nov, 00:30), in Studio, not published
- **B:** `MB_GuideArrows` now also guides a Piranha (Evo <= 2) to the nearest fish it can eat.
- **C:** during the quest "Swim out to the OPEN SEA" (QuestKind = open, not yet OpenSeen), the same ground chevrons point straight out to the nearest edge of the Safe Reef. Checked in Play (top view): 8 chevrons leading out.
- **D:** `MB_FishServer` `welcomeOpen`: the first time a player crosses into the Open Sea, the nearest open-sea school it can eat is moved 22 studs further out on its line and waits until it eats one open-sea fish (up to WelcomeMax 40 s). Checked in Play: a Piranha swimming out got "Squid @ (0, 18, -329)", 3 squid there. Studio-only check attribute `MB_OpenWelcome`.
- Backups: `ServerStorage.MB_GuideArrows_preSim_13Nov`, `MB_FishServer_preOpenWelcome_13Nov`.
- Not built: **E** (a shorter way to the Open Sea) - a map decision for the owner.

## Next
- The new worst point (D): the trek itself and the first minutes in the Open Sea. Ideas to test next: a Piranha that is faster in the trek (cruise 14 -> 16), Open Sea schools a bit denser near the ring, an "Open Sea!" arrival card with the x2 EXP shown.
- After launch: read the 7-step funnel; if step 6 (Open Sea) drops most, it matches the sim.

## 13 Nov 00:15 - owner: "yes do all what sim said" -> the rest built
- **E as a SEA CURRENT (instead of moving the map):** during the "Swim out to the OPEN SEA" quest the ground arrows are a current; swimming along them (heading within ~40 deg) carries you x1.7 (`Bus.State.current`, set in MB_GuideArrows, applied in MB_Swim); the chevrons turn cyan and flow 2.6x faster while you ride. Checked in Play: a Piranha riding it swam 44 studs/s (top 26) and crossed 184 studs in 4 s; no server speed-check warnings (the server allows up to the DART speed, 2.3x top).
- **Piranha cruise 14 -> 16** (GameConfig.Evolutions).
- **Open Sea schools nearer the reef edge:** open-zone fish spawn/respawn at radius OpenSeaMin + (Max - Min) x u^1.7 (was uniform 300-380).
- Backups: `ServerStorage.GameConfig_preSimAll_13Nov` (+ the earlier MB_FishServer / MB_GuideArrows backups; MB_Swim has `MB_Swim_preFpRmb_12Nov` from just before).

| Patience | Version | still playing at 60 s | 120 s | Barracuda by 5 min | Piranha at |
|---|---|---|---|---|---|
| 11 s | A live before the sim | 18.3% | 0.2% | 0.2% | 33.7 s |
| 11 s | B+C+D | 60.8% | 14.2% | 16.7% | 33.7 s |
| 11 s | ALL | **74.0%** | **21.4%** | **34.0%** | 33.2 s |
| 7 s | A -> ALL | 5.7% -> 40.0% | 0% -> 5.3% | 0% -> 12.4% | |
| 16 s | A -> ALL | 38.2% -> 91.5% | 1.7% -> 44.6% | 1.1% -> 57.9% | |

**New top quit points (median kid):** lost in the Open Sea while eating 15 there (37 %) and waiting for a predator for "DART away from a predator" (31 %). Next ideas: a predator that comes to you during that quest (a "practice" Barracuda that lunges slowly), arrows to Open Sea fish for that quest, the Eat 15 goal lowered to 10.

## 13 Nov 00:45 - owner: "we need it to be 100% for all" -> round 2
The sim now also models the repeatable quests after the chain (QuestRepeat, scaled by evolution), Reef Shark at 620 EXP, predators passing by (1 per ~45 s in the Open Sea) for the DART quest, and the golden fish.
Built (in Studio, not published):
- **G** `MB_GuideArrows`: a Barracuda is still guided to food while out in the Open Sea; quest "Eat 15 fish in the OPEN SEA" -> **10**.
- **H** `MB_PredatorServer`: a player on "DART away from a predator" is sensed from **4x** as far (and chased up to 4.5x), so a predator comes to them. Backup `MB_PredatorServer_preSim_13Nov`.
- **I** welcome: a **second** nearby school (any Minnow-size) joins the welcome school a little to the side. Checked: shrimp 6 + damsel 2 within 35 studs at 3 s.
- **J** denser reef: Shrimp schools 10 -> **14**, Damsel 14 -> **18**.
- **K** repeat quests shorter: eat 15+5e -> **10+3e**, Open Sea eat 10+5e -> **6+3e** (rewards unchanged).
- **L** golden fish every **60 s** (was 120), first at **30 s** (was 40), spawning **40-70 studs from a random player** (`Golden.NearPlayer`). Checked: appeared 60 studs away at ~29 s.
- Not built: Barracuda 200 -> 150 (the sim showed no gain).
- Backups: `GameConfig_preSimAll_13Nov`, `MB_FishServer_preSimAll2_13Nov`, `MB_PredatorServer_preSim_13Nov`.

| Patience | Version | 30 s | 60 s | 2 min | 3 min | 5 min | Barracuda in 5 min |
|---|---|---|---|---|---|---|---|
| 7 s | before the sim | 64.0% | 5.7% | 0% | 0% | 0% | 0% |
| 7 s | now | 75.0% | 50.8% | 38.0% | 25.6% | 10.0% | 46.5% |
| 11 s | before the sim | 88.3% | 18.3% | 0.3% | 0% | 0% | 0.3% |
| 11 s | round 1 | 91.4% | 74.0% | 22.6% | 2.4% | 0.1% | 35.7% |
| 11 s | **now** | **94.1%** | **82.3%** | **72.5%** | **57.5%** | **32.1%** | **78.9%** |
| 16 s | before the sim | 97.2% | 38.2% | 1.8% | 0.3% | 0% | 1.3% |
| 16 s | now | 98.7% | 95.4% | 90.3% | 80.3% | 59.5% | 93.4% |

**Why not 100 %:** in this model no game reaches 100 % for every kid: a 7-second-patience kid quits before most games load, and the model has no exploring, friends, PvP or skins, so its 3-5 minute numbers are low by design. Real Roblox simulators keep about a third of new players to the next day (vault: Simulator D1 ~32 % in promoted games). The aim is "no kid quits because the GAME left them stuck" - the remaining quit points are long grinds (repeat "eat N" quests as a Barracuda/Reef Shark) and the first trek out, both of which need NEW things to do (next round), not more arrows.

## 13 Nov - owner: "ok do those" -> round 3 (new things to do in the grind)
Built (in Studio, not published), all in `GameConfig.Fish.Grind`:
- **Shiny fish**: 1 in 40 fish is shiny (x5 EXP, its own toast and sound, counted in the saved `Shinies`).
- **Combo**: bites within 2.5 s chain; every 5th bite pops a COMBO x5/x10... popup.
- **Feeding Frenzy**: every 60 s (first at 45 s) a bait ball of 14 fish appears near players for 15 s with x2 EXP and a FRENZY chip. Spawn distance adds half the shark's length (they spawned inside big sharks at first).
- Client: `MB_GrindFx` (toasts, combo popup, x2 chip).

| Patience | Version | 30 s | 60 s | 2 min | 3 min | 5 min | Barracuda in 5 min |
|---|---|---|---|---|---|---|---|
| 7 s | round 3 | 75.5% | 52.6% | 42.6% | 35.0% | 19.4% | 50.2% |
| 11 s | **round 3** | **94.2%** | **82.8%** | **75.1%** | **67.8%** | **51.1%** | **80.8%** |
| 16 s | round 3 | 99.0% | 95.2% | 91.8% | 88.1% | 78.0% | 94.3% |

Top quit points left: the trek out to the Open Sea (nothing happens on the way) and the repeat "eat N fish" quests (the same goal again and again).

## 13 Nov - owner: "ok do them rn" -> round 4 (bubble rings + quick quests)
Built (in Studio, not published):
- **Bubble rings on the current** - `StarterPlayerScripts.MB_CurrentRings` (new): during "Swim out to the OPEN SEA", glowing neon rings (14 segments, radius 6.5) every 34 studs along the current to the reef edge. They spin and pulse; swimming through one plays a ting that climbs a scale, pops the ring and gives **+1 EXP** (server `MB_SwimServer` "Ring": only during that quest, max 1 per 0.8 s, max 40). Rings rebuild if you leave the line by 70+ studs.
- **Quick quests** - `MB_QuestServer`: on every other repeat cycle the "eat N fish" quest is swapped for a short different goal from `C.QuickQuests`: **Get a COMBO x10**, **Eat a SHINY fish** (shiny chance x6 while on it), **Eat 5 fish in a FEEDING FRENZY**. New stats `Combo10s` and `FrenzyBites` (MB_FishServer).
- Bug found in Play and fixed: the ring script waited on a remote called "Action" (the real one is `SwimAction`), so no rings showed.
- Checked in Play (fresh player, Piranha, open quest): 8 rings on the line, swam through them with W, EXP 0 -> 5 (Pass x2 on), rings cleared on arrival, no errors.
- Backups: `MB_SwimServer_preRings_13Nov`, `MB_QuestServer_preQuick_13Nov`, `MB_FishServer_preQuick_13Nov`. `MB_FreshPlayer` set back to false.

Sim (`r4.py`, 2,000 kids each). The round-3 script was lost when the chat was compacted, so round 3 was rebuilt from the live config; the rebuild scores a bit lower than the recorded round 3 (81.5% / 39.9% vs 82.8% / 51.1% at 11 s), so read the **change**, not the absolute numbers:

| Patience | Change | 60 s | 2 min | 5 min |
|---|---|---|---|---|
| 7 s | round 3 -> + rings -> + quick quests | 51.3 -> 61.0 -> 61.0% | 36.2 -> 40.0 -> 40.0% | 12.9 -> 13.1 -> 15.6% |
| 11 s | round 3 -> + rings -> + quick quests | 81.5 -> 86.0 -> 86.0% | 70.6 -> 73.2 -> 73.2% | 39.9 -> 40.2 -> 45.4% |
| 16 s | round 3 -> + rings -> + quick quests | 94.7 -> 95.7 -> 95.7% | 89.2 -> 89.8 -> 89.8% | 68.1 -> 68.1 -> 73.6% |

Applied to the recorded round 3, the median kid is now about **87% at 1 min and about 56% at 5 min** (was 83% / 51%). Rings help the first trek (minute 1-2); quick quests help the grind (minute 3-5). The biggest quit point left is still the repeat "eat N" quest as a Barracuda in the Open Sea. The real check is the onboarding funnel (`MB_Funnel`) after the owner's playtest.
