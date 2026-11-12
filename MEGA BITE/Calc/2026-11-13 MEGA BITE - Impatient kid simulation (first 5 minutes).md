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
