---
date: 2026-11-01
tags: [celestial, supernova, design, economy, math]
status: design v1 (owner approved the topics, not yet built)
---
# Supernova Incremental - full game design v1 (1 Nov night)

Owner: "for 1. dont try to test, instead use mathematics calculations ... 2. research ... get the best one. 3. think about the economy of the game first so it doesnt end up like gym arc ... 4. use ur knowledge and make the best game. 5. we need the best tutorial ... 6 and others use research and knowledge".
Research used: [[Playbook notes - Incremental games]] (Pecorella "Math of Idle Games" I-III, Tuts+ "Numbers getting bigger", prestige formulas, Roblox sessions ~32 min), [[2026-11-01 GYM ARC Economy fix - coin faucets and boost prices]] (what broke GYM ARC), [[Playbook notes - Passes and products catalogue]], [[Playbook notes - Onboarding, retention and live ops]], [[Roblox Playbook - Rules for every game]], [[2026-11-01 Supernova Incremental - Why players keep playing]], [[2026-11-01 Supernova Incremental - Launch content map (first 4 hours)]], + 1 Nov web: Game Maker's Toolkit "Building Better Skill Trees", dev.to "I built 7 idle games in 30 days".
Calculation scripts (Python, the formulas below with a best-choice buyer; maths, not playtesting): `Celestial Incremental/Calc/econ.py`, `bh2.py`.

## 1. NUMBERS (calculated)
### Formulas
- Body cost: `cost = 10 * 8^k * 1.15^owned` (k = tier 0..7; 1.15 = the standard growth rate, Cookie Clicker; costs x8 per tier like Cookie Clicker's ~x5-x8).
- Body income: `income = 5^k * owned * milestone` per second; milestone x2 at 25, 50, 100, 200, 300, 400 owned (AdVenture Capitalist style, keeps every tier useful).
- Payback of the first body per tier = 10 * 1.6^k s: 10 s, 16 s, 26 s, 41 s, 66 s, 105 s, 168 s, 268 s (newer tiers slightly less efficient, like Cookie Clicker).
- Supernova gives `shards = floor(10 * sqrt(stardust earned this run / 1,000,000))` (square root like AdCap / Realm Grinder: doubling shards needs 4x stardust; generous enough for short Roblox sessions). First Supernova needs 1M earned this run (10 shards).
- Shards are spent in the tree; the shard ring is priced so a sensible build is worth about `x(1 + 0.1 * shards earned)` income.
- Black Hole: needs 100,000 shards earned since the last Black Hole; gives `Dark Matter = floor(sqrt(shards / 1,000))`; each Dark Matter = +25% shards gained (dark ring adds the rest).
| Tier | Unlocks |
|---|---|
| Asteroid, Moon, Planet, Gas Giant | from the start (Moon / Planet / Gas Giant unlocked by cheap tree nodes in the first minutes) |
| Star | Supernova 1 |
| Binary Star | Supernova 3 |
| Pulsar | Black Hole 1 |
| Quasar | Black Hole 2 |
### Calculated pace (best-choice buyer; a real player is ~1.3-1.5x slower)
| Supernova | at (min) | that run (min) |
|---|---|---|
| 1 | 9.8 | 9.8 |
| 2 | 14.0 | 4.1 (2.4x faster: the "worth it" reset) |
| 3 | 18.2 | 4.2 |
| 5 | 24.4 | 3.0 |
| 8 | 32.5 | 3.0 |
| 10 | 40.4 | 4.7 |
| 12 | 61.0 | 13.0 |
| 14 | 106 | 25.1 |
| 15 | 146 | 40.2 (too slow alone) |
- Real player: first Supernova ~12-14 min (target 10-20, research).
- Runs 12-15 get long (13-40 min) with bodies + tree alone: this is exactly where the Forge (from Supernova 3), challenges (from Supernova 8) and comets must add their multipliers, ~x10 together by 1:30, which brings Black Hole 1 to ~2:00 and keeps every run under ~10-12 min.
- After Black Hole 1 (12 Dark Matter, +300% shards) the next 40x of shards takes ~66 min (Black Hole 2 ~3:00, Ring Nebula). The third climb is fast (~17 min) so the Big Bang gate (update 1) sits at Black Hole 3 + 1e10 shards (~4:00).
- Numbers stay below ~1e20 in the first 4 h (safe in normal Luau numbers; formatter K, M, B, T, Qa, Qi..., scientific option).

## 2. THE CONSTELLATION TREE (researched)
Rules from GMTK "Building Better Skill Trees" + dev.to idle lessons:
- Nodes that CHANGE how you play (automation, new tiers, comet chains) beat small % bonuses; no filler (a tight tree beats a huge one).
- Show the next 2-3 nodes, the rest "?" (no spreadsheet wall).
- Real choices: each ring ends in a capstone where you pick 1 of 3 (free swap at every Supernova, so kids can't get stuck, nerds optimise).
- Points come from deliberate goals (Supernova, Black Hole), never from just standing around.
- Fast menu: one tap to buy, "BUY ALL AFFORDABLE" button for kids.
### Ring 1 - Stardust (resets each Supernova, ~2 min to rebuy, auto later): 8 nodes
First Light (free: asteroid x2) - Lunar Pull (unlock Moon) - Planet Seed (unlock Planet) - Gas Giant (unlock) - Orbit Speed (all x1.5) - Comet Lure (comet every 45 s -> 30 s) - Milestone Hunter (extra x2 milestones at 10 and 75 owned) - Supernova Readiness (+20% shards this run)
### Ring 2 - Shards (permanent until Black Hole): 18 nodes in 4 branches + capstone
- STELLAR: Starfire (all x1.5, 5 levels), Star tier, Binary Star tier, Heavy Elements (each tier x(1 + 0.25 * tier number)).
- COMETS: Comet Chain (catch 3 in a row = x2 burst), Golden Comets (5% chance x10), Comet Tail (burst = 60 s of income).
- FORGE: Star Forge unlock (Supernova 3), +1 Essence per Supernova, Forge Luck (+10%), Bulk Roll x3.
- AUTOMATION: Auto-buy Asteroid+Moon, Auto-buy Planet+Gas Giant, Keep Ring 1 on Supernova, Offline 4 h -> 6 h, Offline 50% -> 75%.
- CAPSTONE (pick 1, free swap each Supernova): IDLE STAR (x3 income, comets off) / COMET CHASER (comets x5, income x1) / FORGE MASTER (+2 Essence per Supernova, +25% luck).
### Ring 3 - Dark Matter (permanent): 10 nodes + capstone
Auto-Supernova (at a target you set), Pulsar tier, Quasar tier (Black Hole 2), Dark Pull (+25% shards per DM), Keep Automation branch through Black Hole, Event Horizon (shard formula sqrt -> power 0.55), Ring Nebula unlock (Black Hole 2), Challenge slots 5-8, Offline 8 h, Essence Siphon (+1 Essence every 10 min online).
CAPSTONE (pick 1): SINGULARITY (x10 income, Forge rolls cost 2x) / NEBULA HEART (fusion shiny chance x2) / TIME DILATION (offline 100%).

## 3. ECONOMY FIRST (what broke GYM ARC and how we prevent it)
GYM ARC broke because (1) fixed rewards (100/200/300 x spurt, show prizes up to 8,000) were sized for slow players, so fast players got 100k coins in 15 min, (2) cheap coin boosts stacked (+60%) and beat the Robux ones, (3) one currency (coins) paid for everything, so being rich made every shop trivial.
Rules for Supernova Incremental:
1. **One job per currency**: Stardust = bodies + ring 1 (resets every Supernova, so it can't pile up). Shards = ring 2. Dark Matter = ring 3. **Star Essence = the Forge only**, earned at a fixed slow rate. Stardust can NEVER buy Essence (stardust hyperinflates; rolls would become free).
2. **No flat rewards in a growing currency**: every stardust reward (comet, quest, gift, Lost Star, Time Warp) = "N seconds of your current income", capped (comet 30-60 s, Lost Star 90 s, quest 5 min, daily 10 min). Correct at every stage, never worth more than playing.
3. **Essence budget** (the only scarce currency): Supernova +1 (+1 tree, +2 capstone), quests 2-3 a day, daily streak 2-5, playtime gifts 1 each, Siphon 6/hour after Black Hole. Active player ~8-12 rolls/hour, ~40-60 by 4 h. All odds tuned to that.
4. **Boost stacking rule**: boosts of the same kind don't stack (strongest counts); different kinds multiply. Robux boosts are never beaten by free ones of the same kind; free ones are shorter.
5. **Robux never buys a currency that buys luck** (no Essence for Robux), never shards / Dark Matter directly (leaderboard fairness).
6. **No trading** at launch (no inflation of rare cores, no scams).
7. Every number in Config, checked with the calculation script before each update.

## 3b. THE STAR FORGE
- Roll a Star Core: 1 Essence (Bulk Roll x3 = 3). Equip 3 cores (+1 slot pass, +1 slot Ring 3).
- Odds (shown, sum 100%): Common 60, Uncommon 25, Rare 10, Epic 4, Legendary 0.9, Mythic 0.09, Celestial 0.01.
- Pity (owner rule from GYM ARC: none for anything above 3%): Legendary guaranteed by roll 200, Mythic by 1,500, Celestial none at launch.
- Core effects (one stat each, so choosing 3 is a real choice): Stardust x, Shard gain +%, Comet value x, Offline rate +%, Forge luck +%, one tier x (e.g. "Gas Giant x5").
- Strength by rarity (Stardust core): Common x1.2, Uncommon x1.4, Rare x1.8, Epic x2.5, Legendary x4, Mythic x8, Celestial x20. Duplicates level a core 1-10 (+10% of its power each).
- Collection book: 7 rarities x 6 kinds = 42 cores; complete a row = a permanent bonus.
- Expected at 4 h (~50 rolls): ~30 Common, ~12 Uncommon, ~5 Rare, ~2 Epic, ~36% chance of a Legendary. Mythic / Celestial = long-term chase.

## 4. BLACK HOLE, CHALLENGES, RING NEBULA (my design)
- **Challenges** (Supernova 8, 4 at launch): reach a Supernova under a twist. NO COMETS (reward: +1 Essence per Supernova), HEAVY COSTS (cost growth 1.25; reward: cost growth 1.15 -> 1.14 forever), THREE TIERS (only Asteroid..Planet; reward: low tiers x3), DIM STAR (income /2; reward: shards x1.5). Each once, permanent. Nerd content, optional.
- **Black Hole** (~2:00): resets Stardust, Shards, Ring 2 (except Automation if bought). Keeps Forge cores, Essence, challenges, Supernova count, rank, Dark Matter. Pulsar tier, Ring 3, Auto-Supernova. Reverse cinematic.
- **Ring Nebula** (Black Hole 2, ~3:00): the fusion island. Put 3 "max" bodies of a tier (100+ owned) into the Fusion Ring: it takes 100 of each (a stardust sink) and makes a NEBULA BODY of that tier = that tier x2 permanently until the next Black Hole; 5% chance of a SHINY nebula body (x5, glows, everyone sees it). Collection: 8 tiers x normal / shiny. Free luck, no Robux.
- **4:00**: Black Hole 3 + the Big Bang gate glowing across the void: "THE BIG BANG - next update".

## 5. THE TUTORIAL (research: first action <15 s, first reward <60 s, show don't tell, one hint line + a world arrow, hints only when stuck, nothing stacked on a hint, no offers until Supernova 1, onboarding funnel)
| Step | What the player does | Shown how |
|---|---|---|
| 0 s | nothing: the asteroid already orbits and "+1" pops | the number counts up |
| 1 | tap SYSTEM -> BUY an asteroid | the SYSTEM button glows + arrow; hint line "Buy an asteroid" only after 5 s idle |
| 2 | tap TREE -> FIRST LIGHT (free) | node glows; asteroid x2 with a pop + sound (first reward ~20 s) |
| 3 | buy Lunar Pull -> first Moon | the Moon flies in (smear + snap): first WOAH, small |
| 4 | a comet streaks by: tap it | slow-mo for 0.5 s + a circle on it, first time only |
| 5 | reach 10 asteroids (milestone preview) / Planet / Gas Giant | the goal bar "SUPERNOVA 0% -> 50%" fills; "50%" pops |
| 6 | SUPERNOVA ready: big gold button | the full cinematic; rank SPARK; shards fly into the HUD |
| 7 | spend shards: STARFIRE | ring 2 opens with 3 nodes visible |
| end | "Next: STAR FORGE at Supernova 3" teaser | the Forge gate glows in the world |
Funnel steps 1-7 logged (AnalyticsService onboarding funnel). No popups, no shop, no daily window until step 7.

## 6. SERVERS AND PADS
- 8 players per server (8 pads around the Core; incremental play is solo-with-company; fewer players = better FPS on phones). Pads are claimed on join, freed on leave; your system is saved, not the pad.
- Other players' systems: full detail within ~60 studs, simpler far away (LOD), their big moments still visible.
- Private servers 0 R$ at launch? -> 100 R$ (common, friends-only play).

## 7. SOCIAL
- STAR SURGE: every Supernova in the server fills the shared bar (5% each); full = x2 stardust for everyone for 3 min (max once per 10 min). Server message names who filled it last.
- Shared sky: constellations anyone lit (keep).
- Friends +10% each (max 5), group +10% (P&L Studios XP). Rank over the head; a big burst over your pad on Supernova.
- Likes / favourites board: NOT at launch (needs a third-party proxy: reliability + security risk); revisit after launch.

## 8. COMING BACK
- Offline earnings: 50% of income for up to 4 h (dev.to uses 50%; Egg Inc caps 2 h), extended by the tree; shown on return as a reward screen.
- Daily streak (7-day cycle): Essence 2/2/3/3/4/4/5 + a Time Warp on day 7.
- 3 daily quests sized to one session (e.g. "Go Supernova 2 times", "Catch 10 comets", "Roll the Forge 3 times"): Essence + income-scaled stardust.
- Playtime gifts at 5 / 15 / 30 / 60 min: Essence 1 each.
- Weekly event, Saturday 15:00 UTC: METEOR WEEKEND (x2 comets, golden comets x2), rotating later.

## 9. MONETIZATION (fair; first pass under 400 R$; benefit names; no paid luck; prices read live)
| Pass | R$ | What |
|---|---|---|
| x2 Stardust | 249 | all stardust x2 forever |
| VIP | 399 | +25% stardust, +1 Essence per Supernova, VIP pad trim, chat tag |
| +1 Core Slot | 349 | equip 4 Star Cores |
| Auto Roll | 199 | the Forge rolls by itself while you have Essence (convenience only) |
| Product | R$ | What |
|---|---|---|
| Time Warp 1 h | 49 | 1 hour of current income now (scales, honest) |
| Time Warp 6 h | 199 | 6 hours of income |
| Server Surge | 99 | fills Star Surge for the whole server (x2 for everyone 3 min): social, everyone thanks you |
| Supernova Starter (once, after Supernova 1) | 99 | x2 stardust 30 min + 1 h Time Warp + a cosmetic pad trim (no Essence: that would be paid luck) |
No Robux for Essence, shards or Dark Matter. Offers only after Supernova 1, calm wording, never during cinematics.

## 10. MUSIC
Roblox Creator Store licensed music (zero copyright risk), one loop per layer: Stardust (calm dreamy synth), Supernova layer (driving, brighter), Black Hole (deep, slow), Ring Nebula (airy). Crossfade 1-2 s on change, music ducks for every hero moment, the 3-note Supernova motif in stingers.

## 11. STORE PAGE
- Icon: the Supernova burst with a small chunky avatar silhouette in front (one subject, readable at 150 px), our star-chart gold; drawn by Claude as vectors (no AI).
- Thumbnails (one template, 3 versions): the progression chain asteroid -> ... -> SUPERNOVA (centre, biggest) -> black hole -> ???; a before/after (one asteroid vs a full quasar system); the Supernova blast moment (real game capture).
- Title "Supernova Incremental"; description first sentence = what you do: "Build a star system that earns for you, then go SUPERNOVA."

## 12. LAUNCH
- Target Sat 8 Nov, 15:00 UTC (the weekly slot). Must-have: Stardust + tree rings 1-2, Supernova (cinematic), Forge, Black Hole, tutorial, UI kit, sounds, 4 passes + 3 products, saves. Ring Nebula + challenges if time allows, else update 1 with the Big Bang next.
- Before launch: Maturity questionnaire, 2-player Studio test, phone-size checks (667x375), FPS on a phone, onboarding funnel live, custom thumbnail (needed for Home recommendations).

## Ring 1 prices: PROPOSED (calc, 2 Nov, Claude Code)
Owner rules (2 Nov):
- Unlock nodes = the new tier's first body cost (10*8^k). First Light is free.
- Orbit Speed and Comet Lure are priced so each pays back like the best next body at the moment a normal player can first afford it (~30-60 s of income).
- Comets are worth 30-60 s of income.
- All of ring 1 must be rebought in ~2 min after Supernova 1. If it isn't, Orbit / Lure are scaled down, not the unlock nodes.

Script: `Calc\ring1.py` (same formulas as `econ.py`, best-choice buyer; real player ~1.4x slower).

**Assumption: a normal player catches about half of the comets.**
- Comet Lure's extra income = 0.5 x 45 s x (1/30 - 1/45) = +25%.
- Orbit Speed = +50%.

| Node | Effect | Cost | Status |
|---|---|---|---|
| First Light | asteroids x2 | free | design |
| Lunar Pull | unlocks the Moon | 80 | owner rule (10*8^1) |
| Planet Seed | unlocks the Planet (needs Lunar Pull) | 640 | owner rule (10*8^2) |
| Gas Giant | unlocks the Gas Giant (needs Planet Seed) | 5,120 | owner rule (10*8^3) |
| Orbit Speed | every body x1.5 | **55,000** | PROPOSED (calc) |
| Comet Lure | comets every 30 s (was 45 s) | **80,000** | PROPOSED (calc) |
| Milestone Hunter, Supernova Readiness | - | not priced yet | not in the friends test |

Script output:
```
OrbitSpeed: best body payback reaches 90 s at 183 s best-choice (~4.3 min real), income 2432/s -> cost 45 s of income = 109418 -> 110,000; payback 90 s vs best body 91 s
CometLure: best body payback reaches 180 s at 235 s best-choice (~5.5 min real), income 3624/s -> cost 45 s of income = 163080 -> 160,000; payback 177 s vs best body 184 s
Fresh game (mult 1): whole ring 1 owned at 308 s best-choice (~7.2 min real)
Rebuy check after Supernova 1 (fresh run, x(1 + 0.1*10 shards) = x2): whole ring 1 at 159 s best-choice (~3.7 min real)
  of which the 3 unlock nodes alone: 55 s best-choice (~1.3 min real)
  Orbit/Lure x0.5: 55,000 / 80,000 -> whole ring at 127 s (~3.0 min real)
  Orbit/Lure x0.25: 28,000 / 40,000 -> whole ring at 106 s (~2.5 min real)
FINAL: LunarPull 80, PlanetSeed 640, GasGiant 5,120, OrbitSpeed 55,000, CometLure 80,000
  OrbitSpeed 55,000: costs 45 s of income at 143 s best-choice (~3.3 min real), income 1288/s, payback 85 s vs best body 48 s
  CometLure 80,000: costs 45 s of income at 165 s best-choice (~3.8 min real), income 1858/s, payback 172 s vs best body 69 s
  fresh game: whole ring 1 at 250 s (~5.8 min real); rebuy after Supernova 1: 127 s (~2.1 min best-choice, ~3.0 min real)
```

**Reading:**
- The payback rule gives 110,000 / 160,000, but then the rebuy after Supernova 1 takes 2.7 min (best-choice).
- x0.5 brings it to **2.1 min best-choice (~3 min real)** = the design's "~2 min". The design's own pace table is best-choice time.
- At the halved price, both are first affordable a bit earlier (~3.3 / 3.8 min real) and pay back faster than the rule's target. That is the cost of the 2-minute rebuy.
- To hit ~2 min in real time, x0.25 (28,000 / 40,000) would be needed.

Kept in ONE Config table: `ReplicatedStorage.Galaxy.EconConfig` -> `Econ.Ring1` (id, name, cost, effect, tab, requires). The Upgrades window reads it for the friends test, and the Constellation Tree reads the same table from the alpha.

## Ring 2 (STELLAR) + Supernova Readiness prices: PROPOSED (calc, 3 Nov, Claude Code)
Script: `Calc\ring2.py` (same formulas, best-choice buyer, ring 1 at its game prices, half the comets caught).
**Rule (design):** a sensible ring-2 build is worth about x(1 + 0.1 x shards spent). A new tier isn't a flat multiplier, so a build's worth = (time to 1M with no build) / (time to 1M with it). Each purchase is priced so the build after it hits the rule.

| Node | Effect | Shards | Status |
|---|---|---|---|
| Starfire | every body x1.5 a level, 5 levels | 5 / 8 / 15 / 25 / 40 | PROPOSED (calc) |
| Star | unlocks the Star (needs Supernova 1) | 3 | PROPOSED: calc says 2, floor 3 |
| Heavy Elements | each tier x(1 + 0.25 x its number) (needs Star) | 20 | PROPOSED (calc) |
| Binary Star | unlocks the Binary Star (needs Supernova 3, Star) | 5 | PROPOSED: calc says 1, floor 5 |
| Supernova Readiness (ring 1) | +20% shards at this Supernova | 400,000 stardust | PROPOSED: ~60 s of late run-1 income |

**Why the floors:** in 1M-stardust runs a Star / Binary Star barely pays back. By the rule they're worth 2 and 1 shard. They are "new tier" moments, so not 1-shard throwaways.

**Script output (campaign, Supernova as soon as ready):**
- Supernova 1: run 5.4 min best-choice (~7.6 real), +10 shards.
- Supernova 2: run 3.2 min (1.7x faster).
- Supernova 3 at 10.8 min total; Supernova 5 at 14.2 min; Supernova 10 at 18.8 min (runs under 1 min by then).
