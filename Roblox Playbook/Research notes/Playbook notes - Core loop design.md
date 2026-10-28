# Core Loop Design for Roblox Simulators and Casual Games (2025-2026)

Source-quality note for the writer: Primary or strong sources used here are Wikipedia (with its own citations), Roblox Creator Docs, the GameAnalytics Roblox reports (via the gamedevreports summary), Game Developer (Kongregate's Anthony Pecorella), Deconstructor of Fun, Naavik, the 2006 SDT study press release, and the MDA paper. **RoWatcher** (rowatcher.com) articles are 2026 blog posts that promote RoWatcher's own analytics product, and their author bylines could not be verified. Treat them as opinion, not evidence. Many search results for Roblox game titles were SEO spam pages and were excluded.

## 1. Definitions and frameworks (core vs meta loop, nested loops, SDT, MDA, compulsion vs intrinsic motivation, ethics for kids)

### Takeaway
A core loop is the short repeated action-reward cycle. The metagame or long-term loop wraps around it with goals, optimisation and social layers. Strong research and practice evidence says the core action must satisfy on its own (competence, autonomy, relatedness), with progression amplifying it rather than replacing it. For kids' games, Roblox's paid-random-item rules and the UK Children's Code limit how far "compulsion" tools such as loot eggs can go.

### Cited Findings
- **Core loop and dual session loops.** Michail Katkoff (2013) describes the core loop as the repeated actions that drive play, and says it should be "short, accessible and rewarding." He argues that each core loop contains two session loops: players can stop after the first or continue into the second. This supports both quick on-the-go visits and longer sessions. — [Deconstructor of Fun, Mid-Core Success Part 1: Core Loops](https://www.deconstructoroffun.com/blog//2013/10/mid-core-success-part-1-core-loops.html)
- **Metagame.** Katkoff calls the metagame "the invisible part of the core loop that you have to experience": a layer where players plan strategy, set sub-goals, optimise and interact with others. His advice is to hide complexity so that players discover it themselves. — [Deconstructor of Fun](https://www.deconstructoroffun.com/blog//2013/10/mid-core-success-part-1-core-loops.html)
- **Nested timescales in Clash of Clans.** In Katkoff's example, automated resource collection allows very short visits (seconds), troop training is fast (minutes), and building slows down over time (hours to days), which creates mid- and long-term goals. — [Deconstructor of Fun](https://www.deconstructoroffun.com/blog//2013/10/mid-core-success-part-1-core-loops.html)
- **Cautionary example.** Katkoff names Heroes of Order & Chaos as a warning because its sessions need about 10 minutes of uninterrupted play, which hurts casual pick-up play. — [Deconstructor of Fun](https://www.deconstructoroffun.com/blog//2013/10/mid-core-success-part-1-core-loops.html)
- **Self-Determination Theory (Ryan, Rigby & Przybylski, 2006, *Motivation and Emotion*).** Four studies surveyed about 1,000 gamers. Game appeal comes from satisfying autonomy (freedom and choice), competence (challenge and achievement) and relatedness (connection to other players). Satisfying these needs was linked to enjoyment and intent to keep playing, more than "simple fun." Relatedness mattered especially in MMOs. — [ScienceDaily press release, Dec 2006](https://www.sciencedaily.com/releases/2006/12/061226134706.htm); paper DOI [10.1007/s11031-006-9051-8](https://www.doi.org/10.1007/S11031-006-9051-8)
- **PENS.** The Player Experience of Need Satisfaction (PENS) is the SDT-based measurement instrument from this research line (Immersyve/Rigby). — [selfdeterminationtheory.org PENS page](https://selfdeterminationtheory.org/player-experience-of-needs-satisfaction-pens/)
- **MDA framework.** Hunicke, LeBlanc and Zubek (2004) separate Mechanics (rules), Dynamics (run-time behaviour that emerges from those rules) and Aesthetics (the player's emotional response). The designer works from mechanics towards aesthetics, while the player experiences it the other way round. — [MDA paper PDF](https://users.cs.northwestern.edu/%7Ehunicke/MDA.pdf); [AAAI listing](https://aaai.org/papers/ws04-04-001-mda-a-formal-approach-to-game-design-and-game-research/); [Wikipedia](https://en.wikipedia.org/wiki/MDA_framework)
- **Progression amplifies a loop but cannot create one (opinion piece).** This piece separates the intrinsic core action from the extrinsic progression layer, citing Raph Koster's view that fun comes from learning patterns. It claims Roblox's discovery algorithm rewards session length and return visits, which tempts developers to gate content (daily logins, time-locked currency) instead of deepening the core action. It claims the failure shows up as a D7 drop. Its examples: Tower of Hell retained players with almost no progression for most of its life, and Vampire Survivors is learnable in about 90 seconds. — [RoWatcher, "The Core Loop Mistake Killing Most Roblox Games", 14 Jun 2026](https://rowatcher.com/news/the-core-loop-mistake-killing-most-roblox-games) (low-confidence source)
- **Roblox paid random items rules.** Odds disclosure is required whenever random items are bought with Robux, or with in-game currency that can be bought with Robux. Developers must list every outcome with numerical percentages totalling 100%, visible before purchase behind a labelled "Info"/"Details" button (a bare (i) icon is not enough). The rules cover:
  - capsule items: eggs, wheels, chests
  - enhancement items: potions with random duration, upgrades with a chance of success
  - combination items: merging for a chance at better results
  - probability modifiers: luck boosts, pity systems, rate-up items

  Developers must check `PolicyService:GetPolicyInfoForPlayerAsync()`. When `ArePaidRandomItemsRestricted` is true, they must offer an alternative, such as a free earnable path, a disclosed fixed outcome order, direct purchase priced at expected value, or hiding or blocking the item. Trading of paid random outcomes must be blocked for ineligible users. Random rewards earned from gameplay without paying need no disclosure. — [Roblox Creator Docs: Paid random items](https://create.roblox.com/docs/en-us/production/monetization/paid-random-items)
- **Korea's influence on odds disclosure.** A June 2026 report says Korean loot-box rules pushed Roblox to disclose item odds worldwide. — [TechTimes, 26 Jun 2026](https://www.techtimes.com/articles/319148/20260626/koreas-loot-box-rules-push-roblox-disclose-item-odds-worldwide.htm) (headline only, not fetched)
- **UK Age Appropriate Design Code (Children's Code).** Standard 5: "Do not use children's personal data in ways that have been shown to be detrimental to their wellbeing." Standard 13: "Do not use nudge techniques to lead or encourage children" (mainly aimed at data sharing and weakening privacy). The code does not name streaks or reward loops explicitly. — [Children's Code standards text](https://edlaw.eduverse.com/docs/jurisdiction/nat/gb/childrens-code/STANDARDS.md)
- **Criticism of predatory design in top Roblox games.**
  - Kotaku's reviewer called paying Robux to escape lockouts in Steal a Brainrot "a cruel way to extract money from kids." — [Kotaku](https://kotaku.com/steal-a-brainrot-roblox-empire-review-popular-memes-1851787027)
  - Polygon's Patricia Hernandez criticised Steal a Brainrot's pay-to-win items and its purchasable "server admin" abilities. — [Wikipedia: Steal a Brainrot](https://en.wikipedia.org/wiki/Steal_a_Brainrot)
  - DoBig Studios was criticised for excessive monetisation in Grow a Garden. — [Wikipedia: Grow a Garden](https://en.wikipedia.org/wiki/Grow_a_Garden)

### Inferences
- A useful working taxonomy for a solo developer:
  - **Seconds (micro loop):** a verb plus juicy feedback, for example a click/lift that pops a "+1".
  - **Minutes (core loop):** earn, then upgrade, then unlock a new area or tier.
  - **Hours (session/meta):** rebirth or prestige, collections, quests.
  - **Days and weeks (long-term):** weekly updates, events, limited items, trading and social status.

  Katkoff's dual-session-loop idea and the Clash of Clans timescales support this layering.
- Map loop features to SDT when designing:
  - Competence: visible numbers going up, beating harder zones.
  - Autonomy: choosing which pet, zone or upgrade path to pursue.
  - Relatedness: co-op boosts, trading, showing off.

  Compulsion devices (variable-ratio eggs, FOMO timers) work on top of this, but they are where the ethical and policy risk sits.
- An ethical baseline for kids:
  - Keep random rewards earnable in play.
  - Disclose odds even where it is not required.
  - Avoid "pay to stop losing" mechanics (like Brainrot's paid lock escape).
  - Avoid exploiting loss aversion via theft without protection.

### Gaps
- No primary source was fetched for Nir Eyal's Hooked model (Trigger, then Action, then Variable Reward, then Investment) or for the variable-ratio reinforcement research. The writer should cite Eyal's book (2014) directly if used.
- No fetched source names a "seconds/minutes/hours/days" nested loop diagram explicitly. The timescale layering above is an inference from Katkoff.
- The full Ryan et al. effect sizes were not retrieved, only the press release.
- Roblox-specific child-wellbeing design guidance (beyond paid random items) was not found in this pass.

## 2. How to design a loop (verb, feedback, reward, upgrade, new goal; first-minute clarity; depth without complexity; social loops)

### Takeaway
The winning 2025 Roblox loops (Grow a Garden, Steal a Brainrot) share four features:
- a one-sentence verb chain learnable in seconds
- passive or offline accumulation that gives a reason to come back
- rarity and collection layers added later for depth
- a light social layer (theft, gifting, trading) that creates stories

GameAnalytics data supports first-minute onboarding with an immediate reward, offline progression and social co-play as the drivers of retention.

### Cited Findings
- **Grow a Garden's loop.** Players start with an empty plot among other players' plots and a few Sheckles for carrot seeds, then plant, harvest, sell, and buy progressively more exotic seeds.
  - Crops keep growing while the player is offline.
  - Seed stock rotates in and out.
  - Exclusive items are released weekly and must be claimed while online.
  - Pets come from loot boxes.
  - Robux speeds up waiting and lets players steal crops.

  The first version was reportedly built in about three days by a 16-year-old developer (BMWLux). — [Wikipedia: Grow a Garden](https://en.wikipedia.org/wiki/Grow_a_Garden)
- **Grow a Garden's design lessons (practitioner opinion).** The loop is "Plant → Wait → Harvest → Sell → Upgrade." Depth comes from layered gear, pets, rare crops and weather conditions, "without adding friction." A simple first minute onboards players, and the deeper systems retain them. Stealing and gifting crops form a "light social PvP": gifting turns veterans into mentors, and theft creates emergent stories. Weather events create shared moments. — [MaxPower Gaming, "Why Grow a Garden Is Winning"](https://www.maxpowergaming.co/post/why-grow-a-garden-is-winning-and-what-you-can-learn-from-it)
- **Grow a Garden mutations.** The game has crop and pet mutation systems with value multipliers, a further rarity layer on top of the basic crop. — [PCGamesN mutations guide](https://www.pcgamesn.com/grow-a-garden/mutations) (title and snippet only; multiplier numbers were not retrieved)
- **Steal a Brainrot's loop.** Players buy meme characters ("Brainrots") from a conveyor belt that runs through the map. Owned Brainrots generate passive income, with rarer ones earning far more. Players progress by stealing rarer Brainrots from other bases, which plays like capture-the-flag. Bases have a temporary shield button, traps and gear can be bought, and rebirth resets progress for better stats. — [Wikipedia: Steal a Brainrot](https://en.wikipedia.org/wiki/Steal_a_Brainrot)
- **Lock timing.** Kotaku describes a 60-second lock on your base and the option to intercept purchases on the conveyor. — [Kotaku](https://kotaku.com/steal-a-brainrot-roblox-empire-review-popular-memes-1851787027)
- **Kotaku's play experience.** The reviewer built a large collection in about 40 minutes, partly by robbing an unguarded player. They lost it after forgetting to lock up, and felt real anger. Despite this they felt no pull to return: "Having done everything the game offered in that session, they saw no reason to keep playing." This shows high minute-to-minute intensity but a thin long-term goal for an adult player. — [Kotaku](https://kotaku.com/steal-a-brainrot-roblox-empire-review-popular-memes-1851787027)
- **Screen Rant's view.** Kaitlyn Peterson called Steal a Brainrot addictive because of its "simple, straightforward gameplay loop." — [Wikipedia: Steal a Brainrot](https://en.wikipedia.org/wiki/Steal_a_Brainrot)
- **GameAnalytics 2025 Roblox report on retention drivers.**
  - It attributes 2025 retention gains to re-entry design, offline or idle progression, and social co-play.
  - The "next return session within hours" is stronger when it happens with friends.
  - Short-session games (0-6 minutes) lose players before they engage, so first-minute onboarding and an immediate reward matter.

  — [GameAnalytics 2025 Roblox Report](https://www.gameanalytics.com/cn/reports/2025-roblox-report)
- **The "+1 every second" micro-genre.** There is a cluster of Roblox games with the pattern "every second you get +1 speed/jump" (for example "Roblox but every second you get 1 speed", "+1 Speed Every Second", "every second you get 1 jump power"). The whole loop is that a stat grows passively with time, and players spend it on obby, race or escape courses. — [Bloxodes stats: Roblox but every second you get 1 speed](https://bloxodes.com/stats/games/roblox-but-every-second-you-get-1-speed-4122139330); [Bloxodes: 1 speed every second](https://bloxodes.com/stats/games/1-speed-every-second-4025871682); [Bloxodes: 1 jump power](https://bloxodes.com/stats/games/roblox-but-every-second-you-get-1-jump-power-4417057922) (player-count numbers not retrieved)
- **Recommended loop audit (opinion).** Strip the game to its minimal playable action with no rewards and ask what decision is being made. Choose a target feeling (mastery, social proof, surprise, creativity), then rebuild outward. — [RoWatcher](https://rowatcher.com/news/the-core-loop-mistake-killing-most-roblox-games) (low confidence)

### Inferences
- A template loop for a gym or speed simulator:
  1. **Verb:** click to lift or run, with satisfying feedback.
  2. **Reward:** the stat or currency ticks up visibly.
  3. **Upgrade:** buy better equipment, a pet or a multiplier.
  4. **New goal:** the next zone gate or boss needs X stat.
  5. **Meta:** rebirth multiplies the gain.
  6. **Social:** leaderboards, flexing pets or auras, trading, co-op boosts.
- Grow a Garden and Steal a Brainrot both add a "something is happening while you're away" hook: crops grow offline, Brainrots earn passively. GameAnalytics names offline progression as a top retention driver. Both also add a social risk or gift event, which generates stories and YouTube content.
- Depth without complexity: keep the verb unchanged and add multiplicative modifiers (mutations, weather, pet bonuses) that a child can ignore at first and discover later. This matches Katkoff's "hide complexity" advice.

### Gaps
- No primary design breakdowns (developer interviews or RDC talks) were found for Pet Simulator 99, Muscle Legends, Blox Fruits, Adopt Me, Bee Swarm Simulator or Gym League in this pass. Claims about those games need separate sourcing.
- No source gave a measured "seconds to understand the loop" target for Roblox. The roughly 90-second figure is for Vampire Survivors, from a low-confidence source.

## 3. Pacing and economy (curves, cost/reward ratios, sources and sinks, inflation, prestige, spreadsheets)

### Takeaway
The standard incremental-game recipe: costs grow exponentially, production grows linearly or polynomially through multipliers, and prestige resets let players push further along the curve. This "seesaw" is what creates constant next goals, and it can be modelled in a spreadsheet with a handful of formulas. Track every source and sink so that currency neither balloons nor starves.

### Cited Findings
- **Kongregate's core formulas (Anthony Pecorella, "The Math of Idle Games Part I", 13 Oct 2016).**
  - Next cost: `cost_next = cost_base × rate_growth^owned`
  - Total production: `production_total = (production_base × owned) × multipliers`
  - Bulk-buy cost of n items with k owned: `b × r^k (r^n − 1)/(r − 1)`
  - Max affordable: `floor(log_r(c(r−1)/(b·r^k) + 1))`

  — [Game Developer: The Math of Idle Games Part I](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i)
- **AdVenture Capitalist's Lemonade Stand.** Growth rate 1.07, base cost about 4 (3.738), base production 1.67/sec. Multipliers are ×2 at 25 and 50 owned, stacking. At 10 owned the next cost is about 7.87 and production about 16.7/sec. — [Game Developer](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i)
- **The cost/production seesaw.** Costs grow exponentially while production grows linearly or polynomially, "a seesaw between production rates and costs." Exponential growth eventually beats any polynomial, which is what ends a run and makes prestige meaningful. Prestige resets generators for a persistent currency or multiplier, which lets the player get further along the cost curve each time. — [Game Developer](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i)
- **Choosing between generators.** "Optimal" play buys the best income:cost ratio. Newer generators tend to dominate, which makes old ones irrelevant. Varying per-generator multiplier milestones changes which generator is the priority at each stage. — [Game Developer](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i)
- **Further reading in the series.** Part II covers derivative and production-of-production structures, and Part III covers prestige. — [Part II](https://www.gamedeveloper.com/disciplines/the-math-of-idle-games-part-ii); [Part III](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii) (not fetched in this pass; there is no fetched source for a specific prestige formula such as a square root of lifetime earnings)
- **Sources and sinks (Unity economy guide).** Sources are "places or ways that players can get currency"; sinks are "places or ways that players spend currency." If sources greatly exceed sinks, the game lacks challenge and there is no reason to buy currency. If sinks greatly exceed sources, players get frustrated grinding. Developers should track inventories and currency over time to catch hoarding or shortages, and make sure "no single item is useless at all stages of the game." — [Unity: What is a game economy, Part 1](https://unity.com/how-to/what-game-economy-guide-part-1)
- **Machinations.** Machinations (machinations.io) is the common visual simulation tool for source/sink/converter diagrams. — [Machinations primer, DEV Community](https://dev.to/goldenxp/machinations-primer-2jfe); [Adrian Crook on feedback loops in economies](https://adriancrook.com/?p=8170) (search results only, not fetched)
- **Steal a Brainrot's rebirth.** Rebirth resets progress in exchange for better stats and extra currency. — [Wikipedia](https://en.wikipedia.org/wiki/Steal_a_Brainrot)
- **Grow a Garden's sinks and gates.** Rotating seed stock and paid speed-ups (Robux) act as sinks and time gates. — [Wikipedia](https://en.wikipedia.org/wiki/Grow_a_Garden)

### Inferences
- Building a pacing spreadsheet:
  - Use one row per upgrade or purchase, with columns for level, cost (`base × r^level`), income/sec after purchase, seconds to afford (`cost / income`), and cumulative play time.
  - Plot cumulative time against level, and check that each "next goal" lands within the target window (for example 30-90 seconds early, a few minutes mid-session, a session or a day for rebirth).
  - The growth rate r (1.07 in AdCap) is the main tuning knob. Milestone multipliers (×2 at 25/50) create the felt "jumps."
- Set the rebirth point where time-to-next-upgrade starts to exceed the target session goal, so that rebirth becomes the obviously better choice.
- Add a source/sink ledger per day for simulated "typical" and "heavy" players to detect inflation. Simulator economies with trading need extra sinks (crafting, fusing, consumable boosts) to keep high-tier items valuable.

### Gaps
- No fetched source gives specific Roblox time-to-goal targets (for example "first upgrade within N seconds"). These would be designer heuristics.
- No sourced cost-growth range beyond AdCap's 1.07. Other games' rates were not retrieved.
- No public economy data for Pet Simulator 99 or Bee Swarm was found. Pet Simulator's trading and economy history (for example Pet Simulator X item inflation) is unsourced here.

## 4. Case studies (Roblox and casual mobile): what makes loops sticky, what failed

### Takeaway
Grow a Garden and Steal a Brainrot reached 20M+ concurrent players in 2025 through four things:
- a dead-simple loop
- passive income
- social theft or gifting
- an aggressive weekly update and event cadence ("appointment play," admin-abuse events)

Both drew criticism for monetisation aimed at kids, and reviewers question their long-term depth. Supercell's history shows that even strong teams kill most prototypes when the metrics don't hold up.

### Cited Findings
- **Grow a Garden's concurrency (CCU) records:**
  - about 1,000 in April 2025, when Splitting Point bought a share
  - about 5M at the 18 May "Blood Moon" update
  - 11.7M+ at the 31 May "Bizzy Bees" update
  - 16M+ at the 14 June "Working Bees" update, passing Fortnite's 15.3M
  - 21.3M at the 21 June "Summer Update"
  - 22.3M+ at the 23 August mock admin war with Steal a Brainrot

  It was the fastest Roblox game to 1B visits (33 days), and had 35.3B+ visits by May 2026. The developer estimates about 35% of players are under 13. — [Wikipedia: Grow a Garden](https://en.wikipedia.org/wiki/Grow_a_Garden)
  - Conflict: MaxPower cites a "32.7 million concurrent" record. This probably confuses a platform-wide Roblox figure with the game's own record. Wikipedia gives 22.3M for the game. — [MaxPower](https://www.maxpowergaming.co/post/why-grow-a-garden-is-winning-and-what-you-can-learn-from-it)
- **Grow a Garden's spikes followed updates.** CCU peaks track named weekly updates. MaxPower says new content drops every weekend with countdowns, icon changes and promos ("appointment play"). — [Wikipedia](https://en.wikipedia.org/wiki/Grow_a_Garden); [MaxPower](https://www.maxpowergaming.co/post/why-grow-a-garden-is-winning-and-what-you-can-learn-from-it)
- **Grow a Garden's critical reception.** It has been called the new generation's "FarmVille" (Game File), "more like a prototype than a finished game" (Kotaku), and "a pretty standard AFK game" (PCGamesN). Players trade rare items for real money on eBay and Discord, which violates Roblox's terms. — [Wikipedia](https://en.wikipedia.org/wiki/Grow_a_Garden)
- **Steal a Brainrot's records.**
  - Released 16 May 2025 by SpyderSammy, owned by DoBig Studios.
  - July 2025: 5M CCU.
  - August 2025: 20M.
  - 13 September 2025: 24M, passing Grow a Garden.
  - October 2025: 25.4M.
  - Won Best Creative Direction at the 2025 Roblox Innovation Awards.

  Critics flagged pay-to-win items, cheaters using automation scripts for cash collection and stealing, and "sensory overload" admin-abuse events. — [Wikipedia: Steal a Brainrot](https://en.wikipedia.org/wiki/Steal_a_Brainrot)
- **Steal a Brainrot's weakness for some players.** The Kotaku reviewer felt no reason to return after one roughly 40-minute session (see section 2). — [Kotaku](https://kotaku.com/steal-a-brainrot-roblox-empire-review-popular-memes-1851787027)
- **Tower of Hell (claimed).** It retained players for most of its life with no XP: an attempt, fail, retry, finish loop. — [RoWatcher](https://rowatcher.com/news/the-core-loop-mistake-killing-most-roblox-games) (low confidence)
- **Supercell's kill culture.**
  - Cancelled projects: Rush Wars, Clash Quest, Clash Mini, Everdale, Floodrush.
  - Clash Mini sat in beta for a long time looking for metrics that justified launch.
  - Squad Busters launched after two closed betas and under a month of soft launch, then lost players sharply before stabilising in Q3 2024.
  - mo.co's invite-only launch: downloads fell 94% from 333K on day 1 to 20K by day 30, DAU stabilised just under 400K, and ARPDAU was $0.05.

  Explicit kill thresholds are not public. — [Naavik, Devin Becker, 27 Apr 2025](https://naavik.co/digest/mo-co-and-supercells-new-launch-philosophy/)

### Inferences
- The shared sticky pattern of the 2025 mega-hits:
  1. A trivially understood verb (buy/plant/steal).
  2. Passive accumulation.
  3. Rarity tiers with huge value multipliers.
  4. Visible other players' bases, which drives envy, theft and showing off.
  5. Weekly content beats that synchronise returns.
  6. Creator and YouTube virality.

  A solo developer can copy items 1-4 cheaply. Item 5 (weekly cadence) is the hardest to sustain alone.
- Failure risks in this genre:
  - shallow long-term goals (the Kotaku experience)
  - automation scripts and exploits ruining the economy
  - pay-to-win backlash
  - real-money-trading black markets
  - dependence on trends and memes (Brainrot's licensing dispute over Tung Tung Tung Sahur is documented on Wikipedia)

### Gaps
- No sourced analyses were found for Pet Simulator (X/99), Muscle Legends, Blox Fruits, Adopt Me, Bee Swarm Simulator or Gym League (loops, retention or failures). The writer should not make specific claims about these without new sources.
- No sourced casual-mobile loop failure post-mortems beyond Supercell cancellations.

## 5. Playtesting and measuring a core loop (metrics, observation, fast prototyping, kill criteria)

### Takeaway
Use Roblox's built-in retention analytics and benchmark against the GameAnalytics medians. For games with 1M+ monthly active users, the median is D1 about 10%, D7 about 1.6% and D30 about 0.5%, and the top 1% reach D1 22%, D7 9% and D30 4.7%. Session length is the clearest maturity signal, with 19+ minute games at double-digit D1. Test the bare loop without rewards and watch the first minute. Most strong studios kill prototypes whose metrics don't hold, but there is no public universal threshold.

### Cited Findings
- **GameAnalytics benchmarks (500+ games with 1M+ MAU, August 2025 to July 2026; article dated 25 September 2026).**

  | Metric | Median game | Top 1% |
  |---|---|---|
  | D1 retention | 10.3% | 22.2% |
  | D7 retention | 1.6% | 9.1% |
  | D30 retention | 0.5% | 4.7% |
  | Game session length | 9.8 min (top 5%: 16.6) | 21.1 min |
  | Player session length | 7.28 min | 74.82 min |
  | Daily time per player | 22.4 min | 404.98 min (top 10%: 123.85) |
  | Sessions per day | 1.56 (top 10%: 3.22) | 8.3 |

  — [Game Dev Reports summary of the GameAnalytics Roblox report](https://gamedevreports.substack.com/p/gameanalytics-key-roblox-and-roblox)
- **2025 GameAnalytics Roblox report, medians by average session length.**

  | Session length | D1 | D7 | D30 | ARPPU | Sessions/day |
  |---|---|---|---|---|---|
  | 0-3 min | 4.31% | 0.41% | 0.13% | $0.48 | 1.3 |
  | 4-6 min | 6.20% | 0.88% | 0.28% | $0.70 | 1 |
  | 7-12 min | 7.91% | 0.90% | 0.24% | $0.77 | 1 |
  | 13-18 min | 10.24% | 1.20% | 0.34% | $1.21 | 1 |
  | 19-24 min | 11.46% | 1.61% | 0.46% | $1.71 | 1.8 |
  | 25+ min | 10.76% | 1.82% | 0.50% | $2.12 | 2.2 |

  Long sessions are "necessary but not sufficient": the 25+ tier's 95th-percentile ARPPU is $11.41, against $27.17 for 19-24 minutes. Platform median daily playtime was about 16.8 minutes. — [GameAnalytics 2025 Roblox Report](https://www.gameanalytics.com/cn/reports/2025-roblox-report)
- **Roblox Creator Hub analytics.** It provides retention dashboards, including retention by acquisition source with a selectable benchmark set (2025 DevForum announcement). — [Roblox Creator Docs: Retention](https://create.roblox.com/docs/en-us/production/analytics/retention); [DevForum announcement](https://devforum.roblox.com/t/analytics-view-retention-by-acquisition-source-and-select-your-benchmark-set/4010157)
- **Measure beyond D1.** Track session depth (not just length) and D7/D30 return, since D1 alone can mislead. — [RoWatcher](https://rowatcher.com/news/the-core-loop-mistake-killing-most-roblox-games) (low confidence)
- **Supercell (opinion).** The company deliberately accepts failure: "We do not want to become a company that is so tied up with success that we don't dare risk failure" (Eino Joas). It has moved towards public betas for faster feedback. — [Naavik](https://naavik.co/digest/mo-co-and-supercells-new-launch-philosophy/)
- **Earlier GameAnalytics figure.** The 2023 report put next-day return at 12-15%, but it included smaller projects, so it is not directly comparable. — [Game Dev Reports](https://gamedevreports.substack.com/p/gameanalytics-key-roblox-and-roblox)

### Inferences
- A practical solo test plan:
  1. Build a greybox of the verb, feedback and first upgrade in a day or two. Grow a Garden's first version reportedly took about three days.
  2. Watch 5-10 kids play silently. Note the time to first action, the time to first upgrade, and where they hesitate or leave.
  3. Remove the rewards and see whether the verb is still enjoyable.
  4. Soft-launch with small ad spend or sponsored traffic and read D1, D7 and session length in Creator Hub.
- Indicative kill or iterate thresholds, derived from the GameAnalytics medians rather than a published standard:
  - D1 well under about 8% with sessions under about 6 minutes means a weak loop: rework or kill.
  - D1 at about 10%+ with sessions at 13+ minutes means typical for scaled games: keep iterating.
  - D1 at 20%+ with D7 at 8%+ means top 1% territory.

  Small new games will see noisier numbers.

### Gaps
- No public, sourced kill thresholds from Supercell or Roblox studios were found.
- No RDC or GDC talk specifically on playtesting Roblox simulators was found or fetched in this pass.
- The genre breakdown for simulators is not in the GameAnalytics summaries retrieved.
