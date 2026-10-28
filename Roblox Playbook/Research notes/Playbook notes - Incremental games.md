# Incremental / Idle Game Design and Math (with Roblox focus), 2025-2026

## Incremental design fundamentals (generators, cost growth, multipliers, automation, offline, prestige, layers, challenges)

### Takeaway
The core rule is that **costs grow exponentially** (base about 1.07 to 1.15 per purchase) while **production grows polynomially**, through linear counts times milestone multipliers. This creates a seesaw: fast early progress, then a wall. Prestige trades the run for a permanent multiplier so the player gets further along the cost curve each time. Later layers (for example Antimatter Dimensions' Infinity at 1.79e308) repeat that pattern with new currencies and mechanics.

### Cited Findings
**Cost and production**
- Core cost formula: `cost_next = cost_base × rate_growth^owned`. Total production: `production_total = (production_base × owned) × multipliers` — [Game Developer, Math of Idle Games Pt I (Pecorella)](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i)
- AdVenture Capitalist Lemonade Stand: growth rate 1.07, base cost 4 (technically 3.738), base production 1.67/sec. With 10 owned, the next one costs 4×1.07^10 = 7.87 and production is 16.7/sec. A stacking ×2 applies at 25 and 50 owned — [Pt I](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i)
- Bulk-buy cost for n items, given base b, rate r and k owned: `cost = b × r^k × (r^n − 1)/(r − 1)`. Max affordable with currency c: `max = floor( log(c(r−1)/(b·r^k) + 1) / log(r) )`. These only hold for pure exponential costs — [Pt I](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i)
- Common multipliers are 1.07 to 1.15. Clicker Heroes heroes use 1.07 and Cookie Clicker buildings use 1.15. "Monster" uses 2.5, which the article calls very steep. A multiplier of 1 gives linear costs, which are boring — [Tuts+, Numbers Getting Bigger](https://code.tutsplus.com/numbers-getting-bigger-the-design-and-math-of-incremental-games--cms-24023a)
- Cookie Clicker building base costs rise about 5× per tier (Cursor 15 up to Prism 75,000,000,000), while income rises only about a third per tier, so newer tiers are less efficient. AdVenture Capitalist and Cookie Clicker grow fast for roughly the first 8-10 hours and then flatten — [Tuts+](https://code.tutsplus.com/numbers-getting-bigger-the-design-and-math-of-incremental-games--cms-24023a)
- Purchase-order heuristic: buy the upgrade that minimises `cost/nps + cost/(nps+rate)`. Example: at 5 nps, buying the cost-20 (+1/s) upgrade before the cost-100 (+10/s) one reaches 16 nps in 20.67 s, versus 21.33 s the other way round. Designers can use this to find unintended time spikes — [Tuts+](https://code.tutsplus.com/numbers-getting-bigger-the-design-and-math-of-incremental-games--cms-24023a)

**Multipliers and milestones**
- Multipliers (explicit, or tied to owned-count milestones) exist to keep production near or ahead of cost. If only the top generator gets milestone boosts, older generators become irrelevant. Shifting which generator dominates is "much more interesting" — [Pt I](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i)

**Generators of generators (Antimatter Dimensions style)**
- When tier N produces tier N−1, the currency grows like the integral chain 1, x, x²/2, x³/6 … xⁿ/n!. With 4 tiers, currency grows as x⁴/24. As the number of tiers goes to infinity the chain approaches eˣ. Finite chains stay sub-exponential, so exponential costs still win in the long run, which the author considers good balance — [Pt II](https://www.gamedeveloper.com/disciplines/the-math-of-idle-games-part-ii)
- Derivative Clicker example: cost `5 × 1.1^n`, based on *purchased* count, not total owned. Each purchased tier-1 building adds +0.05% tier-1 production, which keeps manual buying meaningful even when automated production is huge — [Pt II](https://www.gamedeveloper.com/disciplines/the-math-of-idle-games-part-ii)

**Prestige math**
- Realm Grinder: `p = (sqrt(1 + 8·c_max/1e12) − 1)/2`. Doubling prestige currency needs about 4× the previous run's earnings — [Pt III](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii)
- AdVenture Capitalist angels: `p = 150·sqrt(c_lifetime/1e15)`. Doubling needs about 3-4× the earnings — [Pt III](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii)
- Cookie Clicker heavenly chips: `p = cbrt(c_lifetime/1e12)`. Doubling needs about 8× — [Pt III](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii)
- Egg, Inc.: `Δp = (c_run/1e6)^0.14` (roughly the 7th root). Doubling needs about 128×. This rewards active play under a 2-hour offline cap. Sub-prestige tiers multiply earnings by about 5× each — [Pt III](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii)
- Clicker Heroes bases prestige on upgrades bought this run. Since costs are exponential, this effectively takes a log of earnings, so repeated resets at the same point still pay. Formulas on lifetime or max earnings force progress; formulas on the current run flatten the curve and can enable degenerate "reset at the same spot" strategies — [Pt III](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii)
- Pt III's spreadsheet model ran about 120 minutes per run before stalling at 500 generators (16× multiplier). The author warns that spreadsheets build intuition and are not precise predictions, and recommends varying prestige timing and multipliers so resets feel uneven. No single "optimal" reset formula is given — [Pt III](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii)

**Multi-layer example: Antimatter Dimensions**
- Infinity is 2^1024 ≈ 1.79769e308, the double-precision float limit. Reaching it allows a "Big Crunch" reset. The first crunch gives 1 Infinity Point and unlocks Infinity Upgrades, Break Infinity, Replicanti and Normal Challenges. Before Break Infinity every crunch gives exactly 1 IP, and a repeatable upgrade doubles IP gain — [AD wiki, Infinite](https://antimatterdimensions.wiki.gg/wiki/Infinite)
- After Break Infinity: `IP = floor(IP_mult × 10^(log10(maxAntimatter)/308 − 0.75))`. Each extra 1e308 of antimatter gives ×10 IP. Achievements and Time Studies lower the divisor (307.8, 285) — [AD wiki](https://antimatterdimensions.wiki.gg/wiki/Infinite)

**Discovery and gating**
- Start simple and gate features behind currency thresholds. There are two styles: "known unknowns" (visible locked sections, as in Idling to Rule the Gods) and "unknown unknowns" (hidden features, as in Cookie Clicker). Revealing everything upfront kills discovery — [Tuts+](https://code.tutsplus.com/numbers-getting-bigger-the-design-and-math-of-incremental-games--cms-24023a)

**Offline progress**
- Offline progress was popularised by AdVenture Capitalist and is now standard. The longer a player is away, the bigger the pull to return. Idle timers act as a built-in "energy system" — [Game Developer, The rise of games you mostly don't play (Pecorella GDC)](https://www.gamedeveloper.com/design/the-rise-of-games-you-mostly-don-t-play)

### Inferences
- **Worked numbers for a grass-mowing game (my own synthesis, not sourced):**
  - Upgrade costs: `base × 1.12^level` for core upgrades. Use 1.07-1.10 for "many small buys" upgrades and 1.15-1.5 for capped, powerful upgrades.
  - Milestones: give a ×2 boost every 25 levels (AdCap-style).
  - Regrow (first prestige) currency: `floor(sqrt(grassThisRun / threshold))`, similar to AdCap and Realm Grinder, so doubling it needs about 4× earnings. Sqrt is more generous than Cookie Clicker's cube root, which suits a short-session Roblox audience.
  - Season (second layer): use a harsher formula on the *Regrow points* earned, e.g. `floor(log10(RP / 1e3))+1`, or a cube root.
  - Prestige bonus: multiply production by `(1 + RP)` or `(1 + RP)^0.5`.
- A good per-layer target is that each prestige run finishes about 1.5-3× faster to the previous wall, and that the first prestige comes around 10-20 minutes into play. This is consistent with Pt III's "2-hour run" model being too long for Roblox sessions (see the session data below).
- Each new layer should automate the previous layer's busywork and add one new mechanic, as Antimatter Dimensions does with Infinity unlocking challenges, Replicanti and autobuyers.

### Gaps
- No primary source gives a canonical "optimal time-to-prestige" formula. The usual community heuristic (prestige when gain ÷ run time peaks, i.e. maximise prestige currency per second) was not verified from a citable source in this session.
- Specific layer formulas for NGU Idle, Trimps, and Realm Grinder beyond R1 were not fetched. Eternity and Reality requirements for Antimatter Dimensions were also not fetched (the wiki page reached covers Infinity only).
- No sourced formula for offline-earnings caps or efficiency. Egg, Inc.'s 2-hour cap is the only figure found.

## The math tooling: spreadsheets/simulation, big numbers in JS and Luau, notation, walls

### Takeaway
Model the game in a spreadsheet or simulation, using the optimal-purchase heuristic as a bot. On Roblox, beyond about 1.79e308 you need a mantissa/exponent big-number module. Most Roblox incrementals sit within double range plus a suffix formatter. Several Luau libraries exist (BigNum, Quicknum, APInt, QubitNum), but their benchmarks are self-reported.

### Cited Findings
- Pecorella's Pt I/III models drive purchases by the best income:cost ratio at each step. This model is biased toward expensive generators because it measures income per second, and should be treated as intuition-building, not prediction — [Pt I](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i), [Pt III](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii)
- An indie postmortem names "no automated balancing" as a major pain. Content tuning was manual, which killed motivation. Other lessons: prototype in a console app, separate the logic from rendering, and set a deadline of about one month — [Game Developer, Lessons of my first incremental game](https://www.gamedeveloper.com/design/lessons-of-my-first-incremental-game)
- break_infinity.js handles values up to about 1e9e15 by trading accuracy for speed. Its benchmarks vs decimal.js: 15× faster add, 66× faster multiply, 250× faster pow. Antimatter Dimensions' script time improved 4.5× after switching. break_eternity.js is the sequel and handles tetration-scale values (10^^3, 10^^4…) — [npm break_infinity.js](https://npmjs.com/package/break_infinity.js)
- **Luau, Quicknum:** stores a 16-byte buffer (mantissa × 2^exponent), with range up to about 2^2^1024. Self-reported ns/op: add 37.75 vs BigNum 73.61 vs QubitNum 215.51; mod 55.34 vs 140.74 vs 890.47. It avoids metatables and offers in-place `addeq`/`subeq`, plus `hexencode`/`hexdecode` (32-character hex) for saving. Equality uses epsilon 1e-14 — [DevForum Quicknum](https://devforum.roblox.com/t/quicknum-fastest-big-number-library/3878728)
- **Luau, APInt:** an exact arbitrary-precision integer (base-2^52 digit array) with metamethod operators. Self-reported speedups vs RoStrap BigNum (Validark) in Studio: 8.2× creation, 5.4× div/mod, 19.5× tostring. No log support and no K/M/B formatting; the author suggests picking the suffix from string length. It is a poor fit for incrementals that need log/pow — [DevForum APInt](https://devforum.roblox.com/t/a-pint-unlimited-numbers-library-for-incremental-games-and-simulators/3936725)
- Roblox devs report games breaking after 1e308, where a plain number becomes inf — [DevForum thread](https://devforum.roblox.com/t/after-1e308-leaderstat-game-breaks/3740242)

### Inferences
- **Recommendation for a solo Roblox developer:** if the design stays below about 1e300, use plain Luau numbers (float64) plus a suffix formatter (K, M, B, T, Qa, Qi…, then switch to scientific notation like 1.23e45 beyond the suffix table), and save them as numbers. If the game will pass 1e308, adopt a mantissa/exponent library (Quicknum-style). Keep the math in log space where possible (`log10` of currencies) and save as string or hex. Avoid exact big-int libraries (APInt) for game economies.
- Leaderstats IntValue/NumberValue cannot show huge values, so display formatted strings in a StringValue.
- Build a headless Luau or Python simulation that buys greedily using the Tuts+ heuristic and logs time-to-each-unlock and time-to-prestige per run. Tune until the curve hits the targets.

### Gaps
- InfiniteMath, EternityNum (a Luau break_eternity port) and other Roblox libraries were not verified in this session. Their names circulate on the DevForum, but no page was fetched.
- No independent benchmark of the Luau libraries was found.

## Engagement: active vs idle, "number go up", content gates, endgame, updates

### Takeaway
Idle games work because "everything is going up": each check-in gives a celebratory jump, and returning pays more the longer the player is away. The genre's risk is a predictable plateau. Fix it with discovery (gated reveals), shifting optimal choices, and uneven prestige pacing.

### Cited Findings
- Pecorella (GDC): progress happens without interaction, the feedback is constantly positive, check-ins are rewarding, and rewards scale linearly while play is about optimisation. At the time, 3 of Kongregate's top 10 most-played games were idle games, and some players spent over $1,000 — [Game Developer](https://www.gamedeveloper.com/design/the-rise-of-games-you-mostly-don-t-play)
- Games sit on a spectrum from active (CivClicker) to idle (AdVenture Capitalist). Demanding too much involvement can violate humane design. Waiting time grows exponentially the longer a run lasts — [Tuts+](https://code.tutsplus.com/numbers-getting-bigger-the-design-and-math-of-incremental-games--cms-24023a)
- Several upgrade paths with non-linear costs keep the optimal choice shifting. One-time flat boosts and upgrades that change cost or rate variables extend the possibility space — [Tuts+](https://code.tutsplus.com/numbers-getting-bigger-the-design-and-math-of-incremental-games--cms-24023a)
- Pt III: vary prestige timing and multiplier sizes so resets feel uneven, like progression within a run — [Pt III](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii)

### Inferences
- **Walls by design:** place each layer's unlock at a wall the player feels (production stalls), but make the reward clearly worth it (for example, the first Regrow should be about ×2-×3 faster). Then add a new mechanic per layer: Regrow adds automation, Season adds new grass types or areas and challenges.
- **Avoiding hyperinflation boredom:** when numbers jump by e10 per click, they stop meaning anything. Use softcaps (for example, an exponent of 0.5 past a threshold), new currencies per layer, and display rates as "×N" instead of raw numbers.
- **Endgame:** challenges (runs under restrictions that grant permanent rewards) and achievements with small multipliers give replay without new layers. Updates usually add a new layer or area at the top of the game.

### Gaps
- No quantitative retention data was found for active-vs-idle ratios.

## Roblox incrementals specifically: games, loops, numbers, audience, monetization

### Takeaway
The biggest Roblox example is LethalDolphin's **Grass Cutting Incremental**: 30.1M visits, about 3.5K peak CCU, now about 180 average CCU, and 32.6-minute average sessions. Its loop is walk-to-cut grass, then upgrades, then Level, Perks, Prestige (at level 31), Tiers, Platinum, and automation (which includes offline progress). Roblox incrementals monetise lightly (4 dev products, 0 passes for GCI). General Roblox monetisation advice favours repeatable dev-product boosts and never blocking progress behind payment.

### Cited Findings
- **[AWAKENING] Grass Cutting Incremental** (creator LethalDolphin, created Apr 6 2022): 30.1M visits, 82.5K favourites, 89% like ratio (44.3K votes), 3.5K peak CCU, 112 current players. 7-day average CCU 183.7 with a 32.6-minute average session. Placements: Top Trending #38 (Sep 2024), Top Earning #249. Monetisation: 0 game passes, 4 developer products. Last updated Aug 17 2026 — [RoTrends](https://rotrends.com/game/3478678937)
- **GCI loop:** grass blocks spawn about 1/sec on a field and you cut them by walking through. Grass buys upgrades (speed, range, value). Levelling grants Perks. Prestige unlocks at level 31: it resets grass, upgrades and perks for Prestige Points spent on permanent upgrades. The first prestige also unlocks Tiers (earned through TP from cutting). Platinum blocks at Tier 3 fund permanent Platinum upgrades. Automation unlocks at Tier 2 and cuts grass for you, including offline — [Sportskeeda guide](https://www.sportskeeda.com/roblox-news/grass-cutting-incremental-a-beginner-s-guide)
- **Grass Incremental (Unequal Games):** rebirth unlocks around 1,000 grass. Islands unlock at 5, 25, 100 and 500 rebirths. Rebirths every 10-15 minutes for active players, 30-45 for casual. There is reportedly no gamepasses and a group-join bonus. Caution: this is a low-reliability, possibly AI-generated guide with unverifiable figures — [OfZenAndComputing](https://ofzenandcomputing.com/grass-incremental-tips-tricks/)
- **Regrowth Incremental:** you extract energy from a rock with a singularity and revive the world over chapters. It has "dozens of distinct currencies" and hundreds of upgrades, and codes grant Eternal Shards — [RobloxDen](https://robloxden.com/game-codes/regrowth-incremental)
- **Roblox monetisation guidance (DevForum, 2021):**
  - Gamepasses are for permanent perks, with at most 15 slots. Repeatable boosts and currency should be developer products.
  - Price tiers: entry 50-400 Robux, mid 400-6,000, whale 6,000+.
  - About 75% of revenue comes from 1-5% of players.
  - Offer a cheap first purchase, and a purchase "should never block" play.
  - [DevForum Monetization Guide](https://devforum.roblox.com/t/roblox-game-monetization-guide/1235207)

### Inferences
- A 32-minute average session (GCI) suggests Roblox incremental players play in sittings of about 30 minutes. The first prestige should therefore land inside the first session (around 10-20 minutes), and a meaningful unlock should arrive every few minutes. Pecorella's 2-hour runs are too slow for this audience.
- The Roblox audience is younger and social, so visible progression (titles, leaderboards, area unlocks seen by others), group-join bonuses, and codes act as retention and social hooks. GCI's success with zero gamepasses suggests light, fair monetisation works in this niche.
- **Fair monetisation for a grass-mowing incremental:**
  - Timed ×2 boosts as dev products.
  - An auto-mower or extra offline-cap gamepass. Grant automation by play eventually as well, and sell only the earlier or bigger version.
  - A permanent ×1.5-×2 gamepass.
  - Do not sell prestige currency directly.

### Gaps
- Player counts or CCU for Regrowth Incremental, Magnet or Tree incrementals, and "+1 every second" games were not retrieved (a RoTrends/Bloxodes fetch failed or was not attempted).
- No sourced demographic data on Roblox incremental players versus web or Steam players. Statements on audience differences are inferences.
- 2025-2026 Roblox-specific monetisation data for incrementals is lacking; the DevForum guide is from 2021.

## Common mistakes in incremental design

### Takeaway
The recurring failures are pacing errors (unlocks too fast or too slow, linear costs, an endless plateau), no balancing tooling, showing everything at once, demanding constant clicking, and scope creep or no deadline.

### Cited Findings
- **Pitfalls:** linear costs (predictable and boring), unlocks too fast or too slow, revealing everything upfront, excessive required player involvement, and poor or inconsistent UI and art — [Tuts+](https://code.tutsplus.com/numbers-getting-bigger-the-design-and-math-of-incremental-games--cms-24023a)
- **Postmortem:** no deadline (the biggest mistake), the theme not built into the core actions, mechanics that clashed with the idle design, no automated balancing, and story added before the gameplay worked. You can only have two of: long playtime, enough content, fun — [Game Developer](https://www.gamedeveloper.com/design/lessons-of-my-first-incremental-game)
- Generators going irrelevant when only the newest one matters (fix with distributed milestone multipliers) — [Pt I](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i)
- Current-run prestige formulas can enable degenerate strategies of resetting at the same point — [Pt III](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii)
- Numbers past 1e308 breaking a Roblox game — [DevForum](https://devforum.roblox.com/t/after-1e308-leaderstat-game-breaks/3740242)

### Inferences
- Further Roblox-specific mistakes (inferred):
  - Letting server-authoritative currency be computed client-side, which invites exploits. GCI has public "scripts" pages, which shows that exploiting is common in the genre.
  - Not compressing DataStore saves of big numbers.
  - Making the first prestige take longer than one session.

### Gaps
- No r/incremental_games consolidated "mistakes" thread was fetched; the community consensus is summarised only through the Tuts+ article and the postmortem.
