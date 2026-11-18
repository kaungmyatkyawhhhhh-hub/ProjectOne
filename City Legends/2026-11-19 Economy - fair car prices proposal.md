---
tags: [city-legends, economy, cars, proposal]
created: 2026-11-19
status: proposal - nothing changed in the game
---
# City Legends: fair car prices from real earnings (proposal, 19 Nov 2026)

> Owner, 19 Nov: "we can fix the economy if we want because try to calculate a fair price for the vehicles with the job earnings".
> Owner reminder, same day: import cars can't be bought at the dealership (the rule from [[2026-11-17 Car economy and Skyfreight crate design]]).
> **Nothing in the game is changed.** `Cars.lua` and Studio stay untouched until the owner approves.

Model: `Games/CityLegends/tools/economy/model.py`. Run `python tools/economy/model.py --md out.md --chart out.png` from `Games/CityLegends`. It reads the real numbers from `Cars.lua`, `CarStats.lua`, `Config.lua` and `YangonWorld.lua`. It ports the PI, the trims, the job pay sums and the "Harder cash" multipliers, and it checks its PI against the 3 Nov PI table. Builds on [[2026-11-18 Monetization and economy - plan]], [[2026-11-18 Jobs - ranks and paychecks]] and [[K04 Monetization and economy]].

![[2026-11-19 Economy - cash vs hours chart.png]]

## One-screen summary for the owner

**What players earn now, per hour of play, with no passes:**
- New casual: about **$25k**.
- Mid player: about **$58k**.
- Grinder: about **$124k**.
- AFK post: **$12k** at R1 to **$32k** at R5.

**What the passes do:**
- 2x Cash alone: x1.7. It doesn't touch races or heists.
- Double Pay alone: x1.6.
- Both: **x3.0** for mid players and grinders, and x3.7 for a casual who only does jobs. That's the 2-3x we want.

**Delivery pays about 1.6x the other jobs:** $57k/h at R1, against $30-35k for bus, taxi and police. Everyone will pick it.

**The problem:** car prices are real-world used prices, so old fast cars are almost free.
- A mid player buys an E60 M5 ($23,000) in 25 minutes.
- A GT-R ($105,000) or the R8 ($110,000) takes about 2 hours.
- Only the top Lambos and the Velocité Noirs take real effort.

**The fix:** price each car by how many hours a free mid player should play for it (from its PI, plus a brand / status bonus), then round.
| Car | Target (mid player, free) |
|---|---|
| First real upgrade (Apex Cambria) | about 30 min (casual 1 h) |
| Mid cars (class C / B) | 1-5 h |
| High (class A / S1) | 10-25 h |
| Top supercars (S2 / R) | 25-90 h |
| Hypercars (Velocité Noir) | 140-210 h |

**10 biggest price changes.** All of them go up, and they're all cheap fast used cars:
1. HyperSpeed Tech S7 Top: $55,000 -> $1,100,000
2. HyperSpeed Tech S7 Sport: $42,000 -> $780,000
3. Horizon Z33 Top: $20,000 -> $370,000
4. Golden Six Supercharged Top: $77,000 -> $1,400,000
5. HyperSpeed Tech S7: $32,500 -> $580,000
6. British Vanguard Vanta V12 Top: $85,000 -> $1,500,000
7. Horizon Z33: $12,000 -> $210,000
8. Horizon Z33 Sport: $16,000 -> $270,000
9. Bavarica Werkz E60 V10: $23,000 -> $370,000
10. Bavarica Werkz E63 V10: $25,000 -> $390,000

A few go down:
- Stealth-Apex J310: $117,000 -> $94,000.
- Tri-Star W201 Evo II: $280,000 -> $180,000 (it's a class C car).
- Apex Grand Lounge: $40,500 -> $18,000.

The Orient Voltra stays the free starter.

**Local vs Import (owner reminder):**
- 86 cars are Local: on the shelf, bought with cash.
- 89 are Import-only: crates or the airport, with a "value" instead of a price.
- 26 are marked "?" for the owner to decide (see the table).
- The best Local cars are the Stuttgart 971 Turbo S Top (S1, $1.8M), the Ecstasy (Rolls-style) cars, and the Horizon R35 if it stays Local.
- So a free player can buy up to S1 with cash in about 25 h. Every true supercar and hypercar is an import.

**Big decisions for the owner:**
1. **Approve the price table.** All cars change at once, with a "prices changed" message. Nobody loses a car.
2. **AFK posts out-earn active play per day.**
   - 8 h AFK at R1 = $96k a day, about the same as a 2-hour mid player ($115k).
   - AFK at R5 with both passes = **$1.04M a day**.
   - Proposal: 2x Cash no longer applies to posts (Double Pay still does), and post rank pay tops out at x1.65 (R3).
   - Then AFK with Double Pay = $40k/h, never above an active casual's hour.
3. **Bring delivery pay down to the other jobs:** `JobPayPerStud` 7 -> 4 (about $37k/h at R1).
4. **Cash crates at the new values:**
   - Basic $90,000, Premium $750,000.
   - A duplicate from a cash crate refunds 30% of its value. At 50%, crates would make more money than they cost.
   - Premium pity: a Legendary every 8 crates.
   - Hypercars never come from cash crates. Free players buy them at the airport for cash at their value, from level 60. This is an exception to "imports only from crates".
5. **Keep the class price floors, but raise them** to the curve's own floors:
   - S2 from $1.8M (was $350k).
   - R from $3.1M (was $850k).
   - X from $8.7M.

## The model

**From the code (exact):**
- Driving pays $0.0083 per mph per second above 40 mph (90 mph = $0.75/s).
- A cut-up pays $18 x closeness x speed x combo (x1.25 per combo level).
- Race medals pay $1,350 / $750 / $375 / $150, plus a pot of $600 per racer.
- The bank pays at most $6,000 a bag. The vault opens every 390 s per server.
- Chips pay $375 each, and all 60 add $15,000.
- **Jobs** (`Config.Jobs`, `JobRules`):
  - Task pay = (base + rate x straight-line leg) x rank (1 / 1.3 / 1.65 / 2.1 / 2.7) x Double Pay x 2x Cash.
  - Paycheck: $100 a minute on duty ($200 at posts).
  - Delivery: $0.595 a stud + $5 per second left, with the rank share on top.
- **Distances:** the real dispatch, drop and bus stop places on the 1:1 map (`YangonWorld.lua`, `Config.Jobs.BusStops`). The model makes the same random picks the server makes, 4,000 tasks per job.
- **Dailies:**
  - Streak: $750 -> $5,250. Day 7 is a free Mid car up to $50,000.
  - Playtime gifts: $6,000 for 60 min.
  - 3 daily tasks: about $600 each, x3 by level 41.
  - Free SPIN: average prize $1,755.
  - Weekly: $22,500, plus a free SUPER SPIN (average $12,663).
  - Level-up cash (both kinds): $2,300 at level 10, $4,550 at level 20.
- **What 2x Cash touches** (`Store.earnMult`): driving, cut-ups and jobs. It doesn't touch races, duels, heists, drift, jumps or gifts.

**Estimates** (change them at the top of the model):
- Jobs: average speed 55 mph, roads 1.3x the straight line, 8 s per stop, 70% of job time above 40 mph.
- Races: 58 s between races (lobby 15 + grid 8 + back to the hub 35), a medal mix per player type, 3 racers in a lobby.
- Cut-ups: 4 / 6 / 8 cuts a minute at combo 2 / 4 / 6 (casual / mid / grinder).
- **How each player type spends an hour:**
  - Casual: 55% jobs (any), 45% free roam. 1 h a day.
  - Mid: 50% delivery / taxi at R3, 30% races, 20% free roam. 2 h a day.
  - Grinder: 55% delivery at R5, 25% races, 3 heists, 5% free roam. 4 h a day.
  - AFK: 8 h a day at a post.
- Ranks stay fixed per type (R1 / R3 / R5). In real play rank 2 comes in about 15 min and rank 5 in about 4 h.

**Impatient-kid check on the money curve** (Brain method, numbers from the model):
- A new casual gets $18,000 in the first minutes (start cash + the first Legends Path goals) and the $6,000 playtime gifts in the first hour, then earns about $25k an hour.
- So the first real upgrade (Apex Cambria, $93,000) comes at about 1 h for a casual and 30 min for a mid player.
- From there to the 10 h mark, a new car comes every 30-90 min (class D -> C -> B). That keeps "something new" coming.
- The longest wait without a new car for a free mid player is from S1 (25 h) to the first Legendary import (Premium pity, up to 80 h).
- Fill that gap with parts (a full Legendary set is $0.5-0.76M a car), houses and the Rare / Epic cars from Premium crates.

## Targets and why (research)

- **Southwest Florida** ([[2026-11-18 Research - Southwest Florida jobs]]):
  - Paychecks of $220-$250 a minute at entry and $1,375-$1,750 at the top rank, so about $15k/h -> $100k/h.
  - Hypercars cost $1.3M-$2.8M ([vehicle list](https://www.mejoress.com/en/southwest-florida-roblox-vehicles-updated-full-list/), [best cars](https://progameguides.com/roblox/roblox-southwest-florida-best-cars/)): about 15-30 h at the top rank, 90+ h at entry.
  - Double Job Earnings and another 2x stack to x4.
- **Driving Empire:**
  - Top cars cost $2M-$8.5M: Venom GT $2M, SVJ $2.1M, Regera $8.5M ([RobloxDen](https://robloxden.com/game-codes/driving-empire/guides/the-best-cars-in-driving-empire-free-and-paid)).
  - Playtime rewards of $10k-$30k ([guide](https://progameguides.com/roblox/how-to-make-money-fast-in-driving-empire-roblox/)).
  - Per-hour numbers online are fan guesses and disagree.
- **Car Dealership Tycoon:**
  - The top car (Bolide) costs $37.5M or 1,100 R$ ([Sportskeeda](https://www.sportskeeda.com/roblox-news/bugatti-bolide-roblox-car-dealership-tycoon)).
  - Income comes from driving and display platforms. No reliable per-hour figure found.
- **Our pick from that:**
  - Entry cars in under an hour.
  - A "dream" supercar in 1-2 weeks of normal play (40-90 h).
  - The top hypercar as a long goal (100-200+ h).
  - Paying players 2-3x faster.
- The research was quick and from fan sites. Treat it as a direction, not exact numbers.

## How a price is made
1. **Target hours from the car's stock PI.** Anchors: PI 200 = 0 h, 300 = 0.5, 400 = 1, 500 = 2.5, 600 = 6, 700 = 14, 750 = 24, 800 = 42, 850 = 70, 900 = 120, 935 = 220. In between, the hours rise smoothly (log scale).
2. **Brand bonus**, so luxury sits above economy at the same speed:
   - Ecstasy x1.3.
   - Sovereign, Rocket, Enfurecido, Rosso Rampante x1.25.
   - Speedmark x1.2.
   - British Vanguard x1.15.
   - Tri-Star, Stuttgart, Precision, Stealth-Apex x1.05.
   - Bavarica, Trident x1.
   - Others x0.95.
3. **Status floors in hours** (a trim gets x1.3):
   - By brand: Velocité Noir 140, Ecstasy 22, Speedmark and Rocket 14, Sovereign and Enfurecido 12, Rosso 10, British Vanguard 7.
   - Single cars: LFA 45, LFA Circuit 60, Aventador LP700 60, SV 75, SVJ 90, SVJ 63 100, Revuelto 90, Countach 30, Urus 16, Maybach S 9, G63 and GLS 6, R34 6, Supra 4.
4. **The price** = what the free mid player has earned after that many hours (dailies included), rounded to 2 figures. A SPORT / TOP trim costs at least 10% more than its base car.

**Notes on the table:**
- **Enfurecido LB744 Sport / Top** (made-up trims of the Revuelto) come out class X at PI 905 / 942, above the Velocité Éclair. Proposal: take them off sale, as was done with the Countach and 991.2 trims on 13 Nov. Owners keep them.
- The Orient Voltra is the free starter. Its dealer price isn't used in this proposal.
- Hours start from zero cash and assume nothing else is bought. "Mid + both passes" = 2x Cash + Double Pay.
- Rarity uses the crate design's names, by mid-player hours: Common < 1 h, Uncommon 1-4, Rare 4-12, Epic 12-35, Legendary 35-80, Mythic 80+, Hypercar = Velocité Noir.
- **Source** ("?" = unsure, the owner decides):
  - Local: Toyota / Lexus / JDM used imports, mainstream BMW / Mercedes / Land Cruiser, Chinese EVs.
  - Import-only: BMW M cars, AMG GT / Black Series, US muscle, and every Ferrari-, Lamborghini-, McLaren-, Aston-, Audi R8- and Bugatti-style car.
  - Rolls-, Bentley- and Urus-style cars are Local, because a few are seen in Yangon.

## Model output (made by tools/economy/model.py)

### Task pay at real distances (rank 1, no passes)

| Job | Avg leg (studs) | Avg pay / task | Seconds / task | Tasks / h |
|---|---|---|---|---|
| bus | 1353 | $212 | 33 | 109 |
| taxi | 2355 | $618 | 79 | 45 |
| police | 1248 | $267 | 34 | 106 |
| delivery | 1599 | $1,037 | 75 | 48 |

### Cash per hour (play time, without the dailies)

| Player | Free | 2x Cash | Double Pay | Both |
|---|---|---|---|---|
| New casual (R1 jobs) | $24,904 | $49,809 (x2.0) | $45,960 (x1.8) | $91,921 (x3.7) |
| Mid (R3 jobs + races) | $57,615 | $98,284 (x1.7) | $94,650 (x1.6) | $172,355 (x3.0) |
| Grinder (R5 + races + heists) | $124,001 | $208,852 (x1.7) | $206,686 (x1.7) | $374,222 (x3.0) |
| AFK post (R1, tea shop) | $12,000 | $24,000 (x2.0) | $24,000 (x2.0) | $48,000 (x4.0) |
| AFK post (R5) | $32,400 | $64,800 (x2.0) | $64,800 (x2.0) | $129,600 (x4.0) |

### One job hour by rank (free / both passes)

| Job | R1 | R3 | R5 | R5 + both |
|---|---|---|---|---|
| bus | $30,293 | $49,233 | $79,828 | $317,002 |
| taxi | $35,257 | $57,424 | $93,232 | $370,620 |
| police | $35,366 | $57,603 | $93,525 | $371,790 |
| delivery | $56,835 | $93,027 | $151,491 | $603,654 |
| post (AFK) | $12,000 | $19,800 | $32,400 | $129,600 |

### Dailies (per play-day)

- Streak days 1-6: $750, $1,200, $1,800, $2,700, $3,750, $5,250 (day 7: a free Mid car up to $50,000, unscaled)
- Playtime gifts: $6,000 if you play 60 min
- Daily tasks: about $600 each at level 1, x3 by level 41
- Free SPIN EV $1,755 a day; weekly gift $22,500 + free SUPER SPIN EV $12,663 a week
- Level-up cash (both kinds) at level 10 / 20 / 40: $2,300 / $4,550 / $9,050
- Start: $18,000 (start cash + the early Legends Path goals)

### Price proposal (cars on sale)

| Car | Class (PI) | Rarity | Source | Now | Proposed | Casual | Mid | Grinder | Mid + both passes | Why Local / Import |
|---|---|---|---|---|---|---|---|---|---|---|
| Orient Voltra | D 200 | Common | Local | $38,000 | **free** | 0 min | 0 min | 0 min | 0 min | EVs sold new in Yangon |
| Apex Grand Lounge | D 198 | Common | Local | $40,500 | **$18,000** | 0 min | 0 min | 0 min | 0 min | Japanese used import, very common |
| Apex Grand Lounge Sport | D 238 | Common | Local | $53,000 | **$69,000** | 20 min | 10 min | 5 min | 4 min | Japanese used import, very common |
| Orient Voltra Sport | D 240 | Common | Local | $49,000 | **$70,000** | 23 min | 11 min | 6 min | 5 min | EVs sold new in Yangon |
| Apex J200 | D 263 | Common | Local | $75,000 | **$78,000** | 37 min | 18 min | 9 min | 7 min | Land Cruiser: very common |
| Apex Grand Lounge Top | D 275 | Common | Local | $69,000 | **$82,000** | 46 min | 22 min | 11 min | 8 min | Japanese used import, very common |
| Orient Voltra Top | D 274 | Common | Local | $65,000 | **$82,000** | 46 min | 22 min | 11 min | 8 min | EVs sold new in Yangon |
| Apex J300 | D 305 | Common | Local | $79,000 | **$90,000** | 1.0 h | 29 min | 15 min | 11 min | Land Cruiser: very common |
| Apex Cambria | D 311 | Common | Local | $29,500 | **$93,000** | 1.0 h | 31 min | 16 min | 12 min | Toyota: everywhere in Yangon |
| Stealth-Apex J310 | D 301 | Common | Local | $117,000 | **$94,000** | 1.0 h | 32 min | 16 min | 12 min | Lexus LX: common with the rich |
| Bavarica Werkz G06 Sport | D 370 | Common | Local | $77,500 | **$110,000** | 1.4 h | 45 min | 23 min | 17 min | BMW X: common with the rich |
| Apex AE86 | D 381 | Common | Local | $35,000 | **$110,000** | 1.4 h | 45 min | 23 min | 17 min | JDM used import |
| Apex Cambria Sport | D 351 | Common | Local | $38,000 | **$110,000** | 1.4 h | 45 min | 23 min | 17 min | Toyota: everywhere in Yangon |
| Stealth-Apex J310 Sport | D 340 | Common | Local | $152,000 | **$110,000** | 1.4 h | 45 min | 23 min | 17 min | Lexus LX: common with the rich |
| Apex Cambria Top | D 388 | Uncommon | Local | $50,000 | **$130,000** | 2.0 h | 1.0 h | 31 min | 24 min | Toyota: everywhere in Yangon |
| Bavarica Werkz G06 Sport Sport | C 410 | Uncommon | Local | $101,000 | **$130,000** | 2.0 h | 1.0 h | 31 min | 24 min | BMW X: common with the rich |
| Stealth-Apex J310 Top | D 382 | Uncommon | Local | $199,000 | **$130,000** | 2.0 h | 1.0 h | 31 min | 24 min | Lexus LX: common with the rich |
| Tri-Star Silber C167 3.0 | C 418 | Uncommon | Local | $93,500 | **$140,000** | 2.1 h | 1.2 h | 36 min | 28 min | GLE: common |
| Bavarica Werkz G07 | C 429 | Uncommon | Local | $86,500 | **$150,000** | 2.4 h | 1.4 h | 40 min | 30 min | BMW X: common with the rich |
| Bavarica Werkz G20 Sport | C 443 | Uncommon | Local | $47,500 | **$160,000** | 2.7 h | 1.5 h | 45 min | 34 min | BMW 3: common |
| Tri-Star Silber W213 3.0 | C 448 | Uncommon | Local | $20,000 | **$170,000** | 3.0 h | 1.7 h | 50 min | 37 min | Mercedes E: common |
| Bavarica Werkz G06 Sport Top | C 453 | Uncommon | Local | $132,000 | **$170,000** | 3.0 h | 1.7 h | 50 min | 37 min | BMW X: common with the rich |
| Bavarica Werkz G30 3.0 | C 469 | Uncommon | Local | $26,500 | **$180,000** | 3.0 h | 1.9 h | 54 min | 41 min | BMW 5: common |
| Bavarica Werkz G12 Long | C 464 | Uncommon | Local | $27,500 | **$180,000** | 3.0 h | 1.9 h | 54 min | 41 min | BMW 7: business cars |
| Tri-Star Silber W201 Evo II | C 459 | Uncommon | Local ? | $280,000 | **$180,000** | 3.0 h | 1.9 h | 54 min | 41 min | old Mercedes, the Evo II is rare? |
| Tri-Star Silber C167 3.0 Sport | C 459 | Uncommon | Local | $122,000 | **$180,000** | 3.0 h | 1.9 h | 54 min | 41 min | GLE: common |
| Bavarica Werkz G07 Sport | C 473 | Uncommon | Local | $112,000 | **$190,000** | 3.4 h | 2.0 h | 59 min | 43 min | BMW X: common with the rich |
| Apex JZX100 Tourer | C 487 | Uncommon | Local | $27,500 | **$200,000** | 3.6 h | 2.0 h | 1.0 h | 47 min | Mark II / Chaser: classic Yangon JDM |
| Horizon Z33 | C 493 | Uncommon | Local | $12,000 | **$210,000** | 4.0 h | 2.2 h | 1.1 h | 50 min | JDM used import |
| Tri-Star Silber W221 V8 | C 484 | Uncommon | Local | $20,000 | **$220,000** | 4.0 h | 2.4 h | 1.2 h | 54 min | S-Class: common with the rich |
| Dream-Build Volt Titan | B 503 | Uncommon | Local | $148,000 | **$230,000** | 4.3 h | 2.5 h | 1.3 h | 57 min | Chinese EVs sold new in Yangon |
| Tri-Star Silber C167 3.0 Top | C 496 | Uncommon | Local | $159,000 | **$230,000** | 4.3 h | 2.5 h | 1.3 h | 57 min | GLE: common |
| Bavarica Werkz G12 Long Sport | B 507 | Uncommon | Local | $36,000 | **$240,000** | 4.6 h | 2.6 h | 1.3 h | 1.0 h | BMW 7: business cars |
| Tri-Star Silber W201 Evo II Sport | B 502 | Uncommon | Local ? | $364,000 | **$240,000** | 4.6 h | 2.6 h | 1.3 h | 1.0 h | old Mercedes, the Evo II is rare? |
| Bavarica Werkz G07 Top | B 512 | Uncommon | Local | $147,000 | **$250,000** | 5.0 h | 2.8 h | 1.4 h | 1.1 h | BMW X: common with the rich |
| Ironclad LC V8 | B 525 | Uncommon | Import | $44,500 | **value $260,000** | 5.0 h | 3.0 h | 1.5 h | 1.1 h | US muscle, LHD import |
| Apex JZX100 Tourer Sport | B 526 | Uncommon | Local | $36,000 | **$260,000** | 5.0 h | 3.0 h | 1.5 h | 1.1 h | Mark II / Chaser: classic Yangon JDM |
| Horizon Z33 Sport | B 532 | Uncommon | Local | $16,000 | **$270,000** | 5.2 h | 3.1 h | 1.6 h | 1.2 h | JDM used import |
| Trident Motors Maestrale GTS | B 532 | Uncommon | Local ? | $42,000 | **$280,000** | 5.6 h | 3.3 h | 1.6 h | 1.2 h | rare? |
| Dream-Build Volt Titan Sport | B 543 | Uncommon | Local | $192,000 | **$290,000** | 5.9 h | 3.4 h | 1.7 h | 1.3 h | Chinese EVs sold new in Yangon |
| Ahura FD Rotary | B 546 | Uncommon | Local | $42,500 | **$300,000** | 6.0 h | 3.6 h | 1.8 h | 1.3 h | JDM used import |
| Dearborn C346 Rallye | B 545 | Uncommon | Local ? | $30,000 | **$300,000** | 6.0 h | 3.6 h | 1.8 h | 1.3 h | Ford: sold, the RS is rare? |
| Bavarica Werkz G12 Long Top | B 544 | Uncommon | Local | $47,000 | **$300,000** | 6.0 h | 3.6 h | 1.8 h | 1.3 h | BMW 7: business cars |
| Ronin CP9A | B 551 | Uncommon | Local | $50,000 | **$310,000** | 6.2 h | 3.7 h | 1.9 h | 1.4 h | Mitsubishi: JDM used import |
| Tri-Star Silber W201 Evo II Top | B 542 | Uncommon | Local ? | $476,000 | **$320,000** | 6.6 h | 3.9 h | 1.9 h | 1.4 h | old Mercedes, the Evo II is rare? |
| Apex JZA80 | B 530 | Rare | Local ? | $100,000 | **$330,000** | 6.9 h | 4.0 h | 2.0 h | 1.5 h | JDM used import, rare but real |
| Stealth-Apex Z100 V8 | B 548 | Rare | Local ? | $101,000 | **$330,000** | 6.9 h | 4.0 h | 2.0 h | 1.5 h | Lexus, rare? |
| Ronin CP9A Champion | B 559 | Rare | Import | $80,000 | **value $330,000** | 6.9 h | 4.0 h | 2.0 h | 1.5 h | rare JDM edition |
| Pleiad GC8 Wide | B 567 | Rare | Local | $350,000 | **$350,000** | 7.0 h | 4.2 h | 2.2 h | 1.6 h | Subaru: JDM |
| Apex JZX100 Tourer Top | B 566 | Rare | Local | $47,000 | **$350,000** | 7.0 h | 4.2 h | 2.2 h | 1.6 h | Mark II / Chaser: classic Yangon JDM |
| Ironclad LC V8 Sport | B 564 | Rare | Import | $58,000 | **value $350,000** | 7.0 h | 4.2 h | 2.2 h | 1.6 h | US muscle, LHD import |
| Bavarica Werkz E60 V10 | B 570 | Rare | Import | $23,000 | **value $370,000** | 7.0 h | 4.5 h | 2.3 h | 1.7 h | M cars not sold in MM |
| Tri-Star Silber W222 V12 | B 563 | Rare | Local | $85,000 | **$370,000** | 7.0 h | 4.5 h | 2.3 h | 1.7 h | S-Class |
| Horizon Z33 Top | B 574 | Rare | Local | $20,000 | **$370,000** | 7.0 h | 4.5 h | 2.3 h | 1.7 h | JDM used import |
| Dream-Build Volt Titan Top | B 576 | Rare | Local | $252,000 | **$380,000** | 7.2 h | 4.7 h | 2.4 h | 1.8 h | Chinese EVs sold new in Yangon |
| Trident Motors Maestrale GTS Sport | B 572 | Rare | Local ? | $55,000 | **$380,000** | 7.2 h | 4.7 h | 2.4 h | 1.8 h | rare? |
| Bavarica Werkz E63 V10 | B 576 | Rare | Import | $25,000 | **value $390,000** | 7.5 h | 4.8 h | 2.5 h | 1.9 h | M cars not sold in MM |
| Ahura FD Rotary Sport | B 587 | Rare | Local | $55,000 | **$410,000** | 8.0 h | 5.1 h | 2.6 h | 1.9 h | JDM used import |
| Apex JZA80 Sport | B 575 | Rare | Local ? | $130,000 | **$420,000** | 8.2 h | 5.3 h | 2.7 h | 2.0 h | JDM used import, rare but real |
| Bavarica Werkz E92 V8 | B 588 | Rare | Import | $34,000 | **value $430,000** | 8.5 h | 5.5 h | 2.8 h | 2.0 h | M cars not sold in MM |
| Bavarica Werkz F10 | B 596 | Rare | Import | $35,000 | **value $450,000** | 9.0 h | 5.8 h | 2.9 h | 2.1 h | M cars not sold in MM |
| Horizon BNR34 | B 534 | Rare | Local ? | $165,000 | **$460,000** | 9.2 h | 6.0 h | 3.0 h | 2.2 h | JDM, very rare? |
| Tri-Star Silber W463 V8 | C 420 | Rare | Local | $197,000 | **$460,000** | 9.2 h | 6.0 h | 3.0 h | 2.2 h | G-Class: popular with the rich |
| Tri-Star Silber X167 Royale | C 431 | Rare | Local | $180,000 | **$460,000** | 9.2 h | 6.0 h | 3.0 h | 2.2 h | GLS Maybach: a few |
| Ironclad LC V8 Top | A 606 | Rare | Import | $76,000 | **value $460,000** | 9.2 h | 6.0 h | 3.0 h | 2.2 h | US muscle, LHD import |
| Stealth-Apex Z100 V8 Sport | B 593 | Rare | Local ? | $131,000 | **$460,000** | 9.2 h | 6.0 h | 3.0 h | 2.2 h | Lexus, rare? |
| Bavarica Werkz F80 | A 601 | Rare | Import | $42,500 | **value $470,000** | 9.6 h | 6.0 h | 3.1 h | 2.2 h | M cars not sold in MM |
| Apex JZA80 Top | A 614 | Rare | Local ? | $170,000 | **$500,000** | 10 h | 6.4 h | 3.3 h | 2.4 h | JDM used import, rare but real |
| Bavarica Werkz F82 | A 612 | Rare | Import | $42,500 | **value $520,000** | 11 h | 6.7 h | 3.5 h | 2.5 h | M cars not sold in MM |
| Tri-Star Silber C218 V8 S | A 607 | Rare | Import | $42,500 | **value $520,000** | 11 h | 6.7 h | 3.5 h | 2.5 h | AMG import |
| Ahura FD Rotary Top | A 623 | Rare | Local | $72,000 | **$530,000** | 11 h | 6.8 h | 3.6 h | 2.6 h | JDM used import |
| Trident Motors Maestrale GTS Top | A 615 | Rare | Local ? | $71,000 | **$530,000** | 11 h | 6.8 h | 3.6 h | 2.6 h | rare? |
| British Vanguard Highland | B 510 | Rare | Import | $257,000 | **value $540,000** | 11 h | 7.0 h | 3.6 h | 2.6 h | British Vanguard brand |
| Ironclad Supercharged | A 628 | Rare | Import | $72,500 | **value $560,000** | 12 h | 7.3 h | 3.8 h | 2.8 h | AMG GT import |
| Precision Type 42 V10 | A 621 | Rare | Import | $110,000 | **value $570,000** | 12 h | 7.5 h | 3.9 h | 2.8 h | exotic: not sold in Myanmar |
| HyperSpeed Tech S7 | A 633 | Rare | Local ? | $32,500 | **$580,000** | 12 h | 7.6 h | 4.0 h | 2.9 h | Chinese EV, grey imports seen? |
| Tri-Star Silber X167 Royale Sport | C 473 | Rare | Local | $234,000 | **$590,000** | 12 h | 7.8 h | 4.0 h | 2.9 h | GLS Maybach: a few |
| British Vanguard Highland Sport | B 549 | Rare | Import | $334,000 | **value $620,000** | 13 h | 8.1 h | 4.2 h | 3.1 h | British Vanguard brand |
| Stealth-Apex Z100 V8 Top | A 633 | Rare | Local ? | $172,000 | **$630,000** | 13 h | 8.3 h | 4.3 h | 3.1 h | Lexus, rare? |
| Bavarica Werkz F80 Sport | A 641 | Rare | Import | $55,000 | **value $640,000** | 14 h | 8.4 h | 4.4 h | 3.2 h | M cars not sold in MM |
| Golden Six Supercharged | A 648 | Rare | Import | $45,000 | **value $650,000** | 14 h | 8.6 h | 4.4 h | 3.2 h | US muscle |
| Golden Sting 7 | A 651 | Rare | Import | $67,500 | **value $660,000** | 14 h | 8.8 h | 4.5 h | 3.3 h | US muscle |
| Tri-Star Silber W213 V8 S | A 639 | Rare | Local ? | $67,500 | **$660,000** | 14 h | 8.8 h | 4.5 h | 3.3 h | AMG E, rare? |
| Tri-Star Silber Z223 Royale V12 | B 502 | Rare | Local | $245,000 | **$680,000** | 14 h | 9.0 h | 4.6 h | 3.4 h | Maybach: a few |
| Tri-Star Silber X167 Royale Top | B 510 | Rare | Local | $306,000 | **$680,000** | 14 h | 9.0 h | 4.6 h | 3.4 h | GLS Maybach: a few |
| British Vanguard Vanta V12 | A 633 | Rare | Import | $50,000 | **value $690,000** | 14 h | 9.2 h | 4.7 h | 3.5 h | exotic: not sold in Myanmar |
| Stuttgart 982 | A 646 | Rare | Local | $76,500 | **$700,000** | 14 h | 9.4 h | 4.8 h | 3.5 h | Porsche dealer in Yangon |
| British Vanguard Highland Top | B 590 | Rare | Import | $437,000 | **value $710,000** | 15 h | 9.6 h | 4.8 h | 3.6 h | British Vanguard brand |
| Bavarica Werkz F93 Fastback | A 655 | Rare | Import | $140,000 | **value $720,000** | 15 h | 9.6 h | 4.9 h | 3.6 h | M cars not sold in MM |
| Tri-Star Silber C218 V8 S Sport | A 651 | Rare | Import | $55,000 | **value $730,000** | 15 h | 9.8 h | 5.0 h | 3.7 h | AMG import |
| Stuttgart 971 Turbo S | A 654 | Rare | Local | $245,000 | **$740,000** | 15 h | 9.9 h | 5.1 h | 3.7 h | Porsche dealer in Yangon |
| Rosso Rampante F149 Riviera | A 629 | Rare | Import | $110,000 | **value $740,000** | 15 h | 9.9 h | 5.1 h | 3.7 h | exotic: not sold in Myanmar |
| HyperSpeed Tech S7 Sport | A 671 | Rare | Local ? | $42,000 | **$780,000** | 16 h | 10 h | 5.4 h | 4.0 h | Chinese EV, grey imports seen? |
| Ironclad Supercharged Sport | A 672 | Rare | Import | $94,000 | **value $790,000** | 16 h | 11 h | 5.5 h | 4.0 h | AMG GT import |
| Tri-Star Silber R230 V12 Track | A 668 | Rare | Import | $350,000 | **value $830,000** | 18 h | 11 h | 5.8 h | 4.2 h | Black Series: collector |
| Precision Type 42 V10 Sport | A 667 | Rare | Import | $143,000 | **value $830,000** | 18 h | 11 h | 5.8 h | 4.2 h | exotic: not sold in Myanmar |
| British Vanguard Vela V12 | A 660 | Rare | Import | $125,000 | **value $850,000** | 18 h | 11 h | 5.9 h | 4.3 h | exotic: not sold in Myanmar |
| Bavarica Werkz F90 | A 680 | Rare | Import | $67,000 | **value $870,000** | 18 h | 12 h | 6.1 h | 4.4 h | M cars not sold in MM |
| Sovereign Grand Tourer | B 593 | Rare | Import ? | $345,000 | **value $880,000** | 19 h | 12 h | 6.2 h | 4.5 h | rare? |
| Sovereign Highlands | B 502 | Rare | Local | $227,000 | **$880,000** | 19 h | 12 h | 6.2 h | 4.5 h | a few Bentleys |
| Bavarica Werkz F80 Top | A 683 | Epic | Import | $72,000 | **value $900,000** | 19 h | 12 h | 6.3 h | 4.6 h | M cars not sold in MM |
| Golden Six Supercharged Sport | A 689 | Epic | Import | $59,000 | **value $900,000** | 19 h | 12 h | 6.3 h | 4.6 h | US muscle |
| Golden Sting 7 Sport | A 693 | Epic | Import | $88,000 | **value $920,000** | 20 h | 12 h | 6.5 h | 4.7 h | US muscle |
| Horizon R35 | A 696 | Epic | Local ? | $105,000 | **$940,000** | 20 h | 13 h | 6.6 h | 4.8 h | a few in Yangon? |
| Tri-Star Silber C218 V8 S Top | A 687 | Epic | Import | $72,000 | **value $960,000** | 21 h | 13 h | 6.8 h | 4.9 h | AMG import |
| Stuttgart 982 Sport | A 686 | Epic | Local | $99,000 | **$960,000** | 21 h | 13 h | 6.8 h | 4.9 h | Porsche dealer in Yangon |
| British Vanguard Vanta V12 Sport | A 676 | Epic | Import | $65,000 | **value $960,000** | 21 h | 13 h | 6.8 h | 4.9 h | exotic: not sold in Myanmar |
| Rosso Rampante F149 Riviera Sport | A 671 | Epic | Import | $143,000 | **value $990,000** | 21 h | 14 h | 7.0 h | 5.1 h | exotic: not sold in Myanmar |
| Tri-Star Silber C197 Wingdoor | A 694 | Epic | Import | $250,000 | **value $1,000,000** | 21 h | 14 h | 7.1 h | 5.1 h | collector supercar |
| Rocket W463 800 | C 497 | Epic | Import | $390,000 | **value $1,000,000** | 21 h | 14 h | 7.1 h | 5.1 h | tuner G: import |
| Stuttgart 971 Turbo S Sport | A 693 | Epic | Local | $319,000 | **$1,000,000** | 21 h | 14 h | 7.1 h | 5.1 h | Porsche dealer in Yangon |
| Sovereign Grand Tourer Sport | A 638 | Epic | Import ? | $449,000 | **value $1,000,000** | 21 h | 14 h | 7.1 h | 5.1 h | rare? |
| Sovereign Highlands Sport | B 542 | Epic | Local | $295,000 | **$1,000,000** | 21 h | 14 h | 7.1 h | 5.1 h | a few Bentleys |
| Ironclad Supercharged Top | S1 709 | Epic | Import | $123,000 | **value $1,100,000** | 23 h | 15 h | 7.8 h | 5.7 h | AMG GT import |
| HyperSpeed Tech S7 Top | S1 712 | Epic | Local ? | $55,000 | **$1,100,000** | 23 h | 15 h | 7.8 h | 5.7 h | Chinese EV, grey imports seen? |
| Sovereign Grand Tourer Top | A 674 | Epic | Import ? | $587,000 | **value $1,100,000** | 23 h | 15 h | 7.8 h | 5.7 h | rare? |
| Rosso Rampante F131 | A 695 | Epic | Import | $130,000 | **value $1,200,000** | 26 h | 16 h | 8.5 h | 6.2 h | exotic: not sold in Myanmar |
| Enfurecido L140 Spyder | A 694 | Epic | Import | $120,000 | **value $1,200,000** | 26 h | 16 h | 8.5 h | 6.2 h | exotic: not sold in Myanmar |
| Enfurecido LB724 Rally | A 695 | Epic | Import | $320,000 | **value $1,200,000** | 26 h | 16 h | 8.5 h | 6.2 h | exotic: not sold in Myanmar |
| Enfurecido Brava | A 623 | Epic | Local ? | $285,000 | **$1,200,000** | 26 h | 16 h | 8.5 h | 6.2 h | one or two Urus in Yangon? |
| Tri-Star Silber R230 V12 Track Sport | S1 711 | Epic | Import | $455,000 | **value $1,200,000** | 26 h | 16 h | 8.5 h | 6.2 h | Black Series: collector |
| Precision Type 42 V10 Top | S1 708 | Epic | Import | $187,000 | **value $1,200,000** | 26 h | 16 h | 8.5 h | 6.2 h | exotic: not sold in Myanmar |
| Sovereign Highlands Top | B 586 | Epic | Local | $386,000 | **$1,200,000** | 26 h | 16 h | 8.5 h | 6.2 h | a few Bentleys |
| Rosso Rampante F141 | S1 703 | Epic | Import | $165,000 | **value $1,300,000** | 28 h | 18 h | 9.3 h | 6.8 h | exotic: not sold in Myanmar |
| British Vanguard Vela V12 Sport | S1 705 | Epic | Import | $163,000 | **value $1,300,000** | 28 h | 18 h | 9.3 h | 6.8 h | exotic: not sold in Myanmar |
| Precision Type 42 V10 Lightweight | S1 725 | Epic | Import | $120,000 | **value $1,400,000** | 30 h | 19 h | 10 h | 7.3 h | exotic: not sold in Myanmar |
| Golden Six Supercharged Top | S1 733 | Epic | Import | $77,000 | **value $1,400,000** | 30 h | 19 h | 10 h | 7.3 h | US muscle |
| Stuttgart 982 Top | S1 727 | Epic | Local | $130,000 | **$1,400,000** | 30 h | 19 h | 10 h | 7.3 h | Porsche dealer in Yangon |
| Golden Sting 7 Top | S1 737 | Epic | Import | $115,000 | **value $1,500,000** | 32 h | 20 h | 11 h | 7.9 h | US muscle |
| British Vanguard Vanta V12 Top | S1 721 | Epic | Import | $85,000 | **value $1,500,000** | 32 h | 20 h | 11 h | 7.9 h | exotic: not sold in Myanmar |
| Rosso Rampante F149 Riviera Top | S1 716 | Epic | Import | $187,000 | **value $1,500,000** | 32 h | 20 h | 11 h | 7.9 h | exotic: not sold in Myanmar |
| Ecstasy Nocturne | B 504 | Epic | Local ? | $175,000 | **$1,600,000** | 35 h | 22 h | 12 h | 8.4 h | a few Rolls in Yangon? |
| Ecstasy Grandeur | C 402 | Epic | Local | $432,000 | **$1,600,000** | 35 h | 22 h | 12 h | 8.4 h | a few Rolls in Yangon |
| Tri-Star Silber C197 Wingdoor Sport | S1 737 | Epic | Import | $325,000 | **value $1,600,000** | 35 h | 22 h | 12 h | 8.4 h | collector supercar |
| Stuttgart 991.2 Track | S1 750 | Epic | Import | $190,000 | **value $1,800,000** | 39 h | 25 h | 13 h | 9.5 h | track car |
| Enfurecido L147 Roadster | S1 732 | Epic | Import | $500,000 | **value $1,800,000** | 39 h | 25 h | 13 h | 9.5 h | exotic: not sold in Myanmar |
| Stuttgart 971 Turbo S Top | S1 746 | Epic | Local | $417,000 | **$1,800,000** | 39 h | 25 h | 13 h | 9.5 h | Porsche dealer in Yangon |
| Ecstasy Nocturne Sport | B 549 | Epic | Local ? | $228,000 | **$1,800,000** | 39 h | 25 h | 13 h | 9.5 h | a few Rolls in Yangon? |
| Ecstasy Grandeur Sport | C 443 | Epic | Local | $562,000 | **$1,800,000** | 39 h | 25 h | 13 h | 9.5 h | a few Rolls in Yangon |
| Precision 4S V10 | S2 752 | Epic | Import | $350,000 | **value $1,900,000** | 41 h | 26 h | 14 h | 10 h | exotic: not sold in Myanmar |
| Rosso Rampante F142 Spider | S1 735 | Epic | Import | $250,000 | **value $1,900,000** | 41 h | 26 h | 14 h | 10 h | exotic: not sold in Myanmar |
| British Vanguard Vela V12 Top | S1 743 | Epic | Import | $213,000 | **value $1,900,000** | 41 h | 26 h | 14 h | 10 h | exotic: not sold in Myanmar |
| Rosso Rampante F131 Sport | S1 739 | Epic | Import | $169,000 | **value $1,900,000** | 41 h | 26 h | 14 h | 10 h | exotic: not sold in Myanmar |
| Tri-Star Silber R230 V12 Track Top | S2 757 | Epic | Import | $595,000 | **value $2,000,000** | 43 h | 28 h | 15 h | 11 h | Black Series: collector |
| Ecstasy Nocturne Top | B 589 | Epic | Local ? | $298,000 | **$2,100,000** | 45 h | 29 h | 15 h | 11 h | a few Rolls in Yangon? |
| Ecstasy Grandeur Top | C 486 | Epic | Local | $734,000 | **$2,100,000** | 45 h | 29 h | 15 h | 11 h | a few Rolls in Yangon |
| Enfurecido Classico 5000 | B 563 | Epic | Import | $600,000 | **value $2,200,000** | 48 h | 30 h | 16 h | 12 h | exotic: not sold in Myanmar |
| Rosso Rampante F141 Sport | S1 749 | Epic | Import | $215,000 | **value $2,200,000** | 48 h | 30 h | 16 h | 12 h | exotic: not sold in Myanmar |
| Enfurecido L140 Leggera | S2 759 | Epic | Import | $350,000 | **value $2,400,000** | 52 h | 33 h | 18 h | 13 h | exotic: not sold in Myanmar |
| Speedmark P11 Spider | S2 771 | Legendary | Import | $350,000 | **value $2,600,000** | 56 h | 36 h | 19 h | 14 h | exotic: not sold in Myanmar |
| Tri-Star Silber C197 Wingdoor Top | S2 784 | Legendary | Import | $425,000 | **value $2,700,000** | 58 h | 37 h | 20 h | 14 h | collector supercar |
| Enfurecido L147 ZV | S2 772 | Legendary | Import | $700,000 | **value $2,800,000** | 61 h | 39 h | 21 h | 15 h | exotic: not sold in Myanmar |
| Enfurecido LB724 Aero Spyder | S2 777 | Legendary | Import | $600,000 | **value $2,900,000** | 63 h | 40 h | 21 h | 15 h | exotic: not sold in Myanmar |
| Rosso Rampante F131 Top | S2 776 | Legendary | Import | $350,000 | **value $2,900,000** | 63 h | 40 h | 21 h | 15 h | exotic: not sold in Myanmar |
| Stealth-Apex V10 Halo | S1 737 | Legendary | Import | $900,000 | **value $3,300,000** | 71 h | 46 h | 24 h | 18 h | collector, 500 built |
| Rosso Rampante F141 Top | S2 787 | Legendary | Import | $350,000 | **value $3,300,000** | 71 h | 46 h | 24 h | 18 h | exotic: not sold in Myanmar |
| Rosso Rampante F142 Speciale | S2 791 | Legendary | Import | $520,000 | **value $3,400,000** | 74 h | 47 h | 25 h | 18 h | exotic: not sold in Myanmar |
| Enfurecido LB724 | S2 794 | Legendary | Import | $550,000 | **value $3,500,000** | 76 h | 48 h | 26 h | 19 h | exotic: not sold in Myanmar |
| Speedmark P11 Spider Sport | R 809 | Legendary | Import | $850,000 | **value $4,000,000** | 87 h | 56 h | 29 h | 21 h | exotic: not sold in Myanmar |
| Enfurecido LB724 VTZ | R 807 | Legendary | Import | $850,000 | **value $4,100,000** | 89 h | 57 h | 30 h | 22 h | exotic: not sold in Myanmar |
| Enfurecido LB834 | S2 786 | Legendary | Import | $550,000 | **value $4,300,000** | 93 h | 60 h | 32 h | 23 h | exotic: not sold in Myanmar |
| Stealth-Apex V10 Halo Circuit | S2 758 | Legendary | Import | $1,700,000 | **value $4,300,000** | 93 h | 60 h | 32 h | 23 h | collector |
| Enfurecido LB834 ZV | R 822 | Legendary | Import | $900,000 | **value $5,400,000** | 118 h | 75 h | 40 h | 29 h | exotic: not sold in Myanmar |
| Enfurecido LB834 ZVX | R 841 | Mythic | Import | $1,200,000 | **value $6,400,000** | 140 h | 89 h | 48 h | 34 h | exotic: not sold in Myanmar |
| Speedmark P11 Spider Top | R 862 | Mythic | Import | $950,000 | **value $6,800,000** | 148 h | 95 h | 50 h | 36 h | exotic: not sold in Myanmar |
| Enfurecido LB834 ZVX 63 | R 837 | Mythic | Import | $1,250,000 | **value $7,200,000** | 157 h | 100 h | 54 h | 39 h | exotic: not sold in Myanmar |
| Enfurecido LB744 | R 864 | Mythic | Import | $1,200,000 | **value $7,300,000** | 159 h | 102 h | 54 h | 39 h | exotic: not sold in Myanmar |
| Velocité Noir Origine | R 842 | Hypercar | Import | $2,100,000 | **value $10,000,000** | 219 h | 140 h | 75 h | 54 h | exotic: not sold in Myanmar |
| Velocité Noir Éclair Pure | X 911 | Hypercar | Import | $4,000,000 | **value $10,000,000** | 219 h | 140 h | 75 h | 54 h | exotic: not sold in Myanmar |
| Velocité Noir Éclair | X 916 | Hypercar | Import | $3,250,000 | **value $11,000,000** | 241 h | 154 h | 82 h | 59 h | exotic: not sold in Myanmar |
| Enfurecido LB744 Sport | X 905 | Mythic | Import | $1,560,000 | **value $12,000,000** | 263 h | 168 h | 89 h | 64 h | exotic: not sold in Myanmar |
| Velocité Noir Origine Super Sport | R 890 | Hypercar | Import | $2,730,000 | **value $12,000,000** | 263 h | 168 h | 89 h | 64 h | exotic: not sold in Myanmar |
| Velocité Noir Origine Roadster Vitesse | R 860 | Hypercar | Import | $3,570,000 | **value $14,000,000** | 307 h | 196 h | 105 h | 75 h | exotic: not sold in Myanmar |
| Velocité Noir Éclair Super Sport | X 933 | Hypercar | Import | $4,450,000 | **value $15,000,000** | 329 h | 211 h | 112 h | 80 h | exotic: not sold in Myanmar |
| Enfurecido LB744 Top | X 942 | Mythic | Import | $2,040,000 | **value $20,000,000** | 440 h | 282 h | 150 h | 107 h | exotic: not sold in Myanmar |

### Biggest changes

- Orient Voltra: $38,000 -> $0 (x0.0)
- HyperSpeed Tech S7 Top: $55,000 -> $1,100,000 (x20.0)
- HyperSpeed Tech S7 Sport: $42,000 -> $780,000 (x18.6)
- Horizon Z33 Top: $20,000 -> $370,000 (x18.5)
- Golden Six Supercharged Top: $77,000 -> $1,400,000 (x18.2)
- HyperSpeed Tech S7: $32,500 -> $580,000 (x17.8)
- British Vanguard Vanta V12 Top: $85,000 -> $1,500,000 (x17.6)
- Horizon Z33: $12,000 -> $210,000 (x17.5)
- Horizon Z33 Sport: $16,000 -> $270,000 (x16.9)
- Bavarica Werkz E60 V10: $23,000 -> $370,000 (x16.1)
- Bavarica Werkz E63 V10: $25,000 -> $390,000 (x15.6)
- Golden Six Supercharged Sport: $59,000 -> $900,000 (x15.3)
- British Vanguard Vanta V12 Sport: $65,000 -> $960,000 (x14.8)
- Golden Six Supercharged: $45,000 -> $650,000 (x14.4)
- British Vanguard Vanta V12: $50,000 -> $690,000 (x13.8)

### Class floors (mid player, free)

- S1 from PI 701: $1,100,000 (14 h)
- S2 from PI 751: $1,800,000 (24 h)
- R from PI 801: $3,100,000 (42 h)
- X from PI 901: $8,700,000 (122 h)

### Crates with cash (free path to an import)

- Designed Basic crate $5,000 (17 Nov): casual 0 min, mid 0 min, grinder 0 min
- Designed Premium crate $40,000 (17 Nov): casual 1 min, mid 1 min, grinder 1 min
- Average value by rarity: Common $79,714, Uncommon $219,354, Rare $566,909, Epic $1,427,142, Legendary $3,535,714, Mythic $9,950,000, Hypercar $12,000,000
- Proposed Basic crate $90,000 (Common 70%, Uncommon 25%, Rare 5%): average car value $138,984, a duplicate refunds $41,695 at 30% (46% of the price; 50% would be 77%); casual 1.0 h, mid 29 min, grinder 15 min
- Proposed Premium crate $750,000 (Rare 60%, Epic 33%, Legendary 6%, Mythic 1%): average car value $1,122,745, a duplicate refunds $336,823 at 30% (45% of the price; 50% would be 75%); casual 16 h, mid 10 h, grinder 5.2 h

### Per play-day (AFK check)

| Player | Hours a day | Free / day | Both passes / day |
|---|---|---|---|
| New casual (R1 jobs) | 1 | $24,904 | $91,921 |
| Mid (R3 jobs + races) | 2 | $115,230 | $344,710 |
| Grinder (R5 + races + heists) | 4 | $496,006 | $1,496,888 |
| AFK post (R1, tea shop) | 8 | $96,000 | $384,000 |
| AFK post (R5) | 8 | $259,200 | $1,036,800 |
## Sinks: is there enough to spend on after the cars?
| Sink | Now | At the new prices |
|---|---|---|
| Parts (`PartPriceMult` 2.5) | Common set about $78k; full Legendary set $0.5-0.76M a car | Good: 6-13 h of a mid player per maxed car. Keep. |
| Legends Customs | $1,000-$4,000 a change x tier (1 / 2.5 / 6); a full High restyle about $94k | Too cheap once cars cost millions. Proposal: price x the car's rarity (Common x1 ... Hypercar x20), so a hypercar restyle is about $300k. |
| Houses | $150k -> $100M (31 designs) | Already huge: the $20M-$100M High houses take 250-1,000 h. Fine as the endgame sink. |
| Garage bays | $50k / $100k / $200k / $400k / $800k | Fine. |
| Hotel suites | $2M -> $25M; pay $300 -> $4,500 a minute while in game | **An AFK income** (pays itself back in about 100 h). Proposal: no suite pay while on duty at an AFK post, or halve it. |
| Towers | $750k -> $12M; rent $1,800 -> $24,000 a day | Fine. |
| Fuel, service, tyres | A tank is 1-3% of an hour; oil every 600 mi; tyres every 3.5 h | Small on purpose. Keep. |
| SPIN / SUPER SPIN for cash | $5,000 / $30,000 | Fine (the average prize is under the price). |
| Cash crates (new) | - | Basic $90k, Premium $750k: the main sink for free players after the shelf. |

**Where cash would pile up:**
- A grinder makes about $0.5M a day free, or $1.5M with both passes.
- All Local cars together cost about $43M.
- So after 2-3 months a grinder owns everything Local. From then on the sinks are imports (crates), houses and parts.
- If more is needed later: car collection books with a reward, or a weekly "Legends Auction" of one rare import for cash.

**A free player's path to an import:**
- Basic crate ($90k): about 30 min for a mid player. Gives Common 70%, Uncommon 25%, Rare 5%.
- Premium crate ($750k): about 10 h for a mid player. Gives Rare 60%, Epic 33%, Legendary 6%, Mythic 1%.
- With a Legendary guaranteed every 8 Premium crates, the first Legendary takes about 6 crates on average (about 60 h of a mid player, 80 h at most). That fits the 40-90 h target.
- Skyfreight (399 R$) stays the Robux crate for Epic and above.

## Check list before building (once approved)
- `Cars.lua`: prices and `Cars.TrimPrices` from the table, plus new `Source` (Local / Import) and `Rarity` fields on each car. The dealer shows Local cars only.
- `tools/carlevels_test.luau`: the new S2 / R floors.
- Config: posts without 2x Cash, the post rank cap, `JobPayPerStud` 4, crate prices and the 30% duplicate refund.
- A one-time "prices changed" message. Nobody loses an owned car.
- Sell-back (`Config.Value.SellShare` 0.6) works from the car's price, so old owners would gain: decide whether it uses the price they paid.
- Re-run `tools/economy/model.py` after any change.

## Owner decisions (19 Nov 2026) on the "?" cars
Local means the car is sold at the dealership. Import means it only comes from crates or the airport.

| # | Car | Decision |
|---|---|---|
| 1 | Tri-Star W201 Evo II | Import |
| 2 | Trident Maestrale GTS | Local |
| 3 | Dearborn C346 Rallye | Import |
| 4 | Apex JZA80 | Local |
| 5 | Stealth-Apex Z100 V8 | Local |
| 6 | Horizon BNR34 | Local |
| 7 | HyperSpeed S7 | Local |
| 8 | Tri-Star W213 E | E400 Local, E63 Import |
| 9 | Horizon R35 | Local |
| 10 | Enfurecido Brava | Local |
| 11 | Ecstasy Nocturne | Local |
| 12 | Sovereign Grand Tourer | Local |

**Trims:**
- **E-class (#8):** keep only the E400 and the E63.
- **R35 (#9):** gets 2 trims, a "2010" GT-R and a "2017 Nismo". Fictional names in game.
- **All the other cars in this list:** base only. Their Sport and Top trims come off sale. **They are deleted outright, not kept as Retired (owner: only testers own them).**

The rest of the proposal (prices and the 5 open questions) is still waiting for the owner's check.

## Owner approval (19 Nov 2026): APPLY
- **All 6 suggestions approved:**
  1. The new prices.
  2. Delivery per-stud pay 7 → 4.
  3. AFK limits: 2x Cash doesn't apply at posts, post rank pay stops at R3, and hotel suite AFK pay is capped.
  4. 30% duplicate refund from cash crates.
  5. The Revuelto Sport and Top trims are deleted.
  6. Hypercars come from crates only (no airport cash buy), with a pity guarantee.
- **458 changes:**
  - The old-model Ferrara 458 Italia (`ferrara_458`) is deleted.
  - The 458 Speciale is Import.
  - The 458 Spider is Local (dealership).
