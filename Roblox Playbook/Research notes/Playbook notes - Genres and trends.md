# Roblox Genre Design and Trends (Simulators, Incrementals, Tycoons, Trend Games), 2025-2026

Research date: 2026-10-28. Source-quality note: Wikipedia, PocketGamer.biz, GamesBeat, GameDiscoverCo, Dexerto/GameWorldObserver (which report official RDC figures) are the stronger sources. Rowatcher.com and rolearn.dev are stats-tracker and blog sites. Their CCU readings are useful but their analysis is secondary, and rolearn says it withdrew earlier claims it could not source.

## 1. Core loop design of successful simulators, incrementals and tycoons

### Takeaway
The proven template has five parts: a fast "earn" loop, spending on multipliers, rebirth/prestige that resets for a permanent multiplier, eggs/pets for collection and status, and weekly updates plus FOMO limited items. Rebirth cost is usually geometric (cost = base x rate^n), and numbers scale to huge suffixes (PS99 reaches the quintillions). I found few public pacing benchmarks (for example time to first rebirth) from primary sources.

### Cited Findings
- Simple rebirth cost formula suggested on the DevForum: C(r) = S x R^r, for example 100 x 1.5^r (first rebirth costs 100, and each rebirth costs 50% more). The original poster's issue was that prices grew "beyond infinity", so the growth rate has to be tuned against income growth. — [DevForum: Simulator Rebirth Formula](https://devforum.roblox.com/t/simulator-rebirth-formula/3162074)
- Pet Simulator 99 (BIG Games): released Dec 1, 2023. It peaked at 400k+ CCU near launch and was at about 44.8k CCU (2.36B visits) at the article's writing. The core loop is hatch → collect → fuse → upgrade, with numbers scaling into the quintillions. Weekly updates ship Saturdays at 5 PM GMT. — [Rowatcher: Inside BIG Games](https://rowatcher.com/news/inside-big-games-how-pet-simulator-became-a-100m-roblox-empire)
- PS99 monetization stack:
  - Hatch-speed gamepasses (Triple Eggs, Octuple Eggs), with free hatching deliberately slow.
  - 400-Robux exclusive eggs whose pets rival long free grinds.
  - Timed limited pets and bundles (PSX reportedly made $10M+ from these).
  - Ultra-rare tiers (HUGE, TITANIC, GARGANTUAN) that work as status items and drive a trading economy.
  - A 100+ creator program for YouTube/TikTok promotion.
  - Source: [Rowatcher: Inside BIG Games](https://rowatcher.com/news/inside-big-games-how-pet-simulator-became-a-100m-roblox-empire)
- Pet Simulator franchise history:
  - Pet Simulator (Aug 4, 2018): 50k CCU on launch day.
  - Pet Simulator X (July 2021): 8B+ visits, with an estimated peak of 4.2M-17M Robux per day.
  - Spinoffs: Pets GO (Oct 2024, an RNG game built from a PS99 event) and Steal a Pet (June 2025, a fast follow on the Steal a Brainrot formula).
  - Source: [Rowatcher: Inside BIG Games](https://rowatcher.com/news/inside-big-games-how-pet-simulator-became-a-100m-roblox-empire)
- Steal a Brainrot loop: a conveyor sells Brainrot characters that generate passive income. Players buy rarer ones or steal from other bases (capture-the-flag style). Bases have a temporary shield button, traps/items can be bought with currency or Robux, and rebirth resets progress for better stats. — [Wikipedia: Steal a Brainrot](https://en.wikipedia.org/wiki/Steal_a_Brainrot)
- Grow a Garden loop: farming where crops "grow offline", which was novel on Roblox and gives players a reason to come back. The core is non-competitive, onboarding is simple ("Roblox players have little patience for tutorials"), and veterans gift fruit to newcomers. — [GameDiscoverCo](https://newsletter.gamediscover.co/p/what-grow-a-gardens-89-million-ccu)
- Grow a Garden is listed on Roblox under Genre: Tycoon (Simulation). Created 25 Mar 2025, 36.0B visits, 11.5M favorites (as of 28 Oct 2026). — [ROLearn case study](https://rolearn.dev/case-studies/idle-garden-zero-to-20m-ccu)

### Inferences
- Several 2025 megahits share an idle/passive income engine: Grow a Garden (offline growth) and Steal a Brainrot (passive income from owned units, plus rebirth). Classic click-to-gain simulators (Muscle Legends, Race Clicker) are the older form of the same loop. Mixing passive income with one social-conflict or social-gift mechanic was the 2025 twist.
- Use geometric rebirth costs with a multiplier that grows more slowly than cost, so each rebirth takes somewhat longer than the last. Tune the growth rate against total income growth, not just the base multiplier.
- Collection tiers (Huge/Titanic) and a trade economy give whales and grinders long-term goals. They also bring inflation and pay-to-win criticism (see section 4).

### Gaps
- I found no primary sources with exact formulas or pacing benchmarks for Muscle Legends, Strongman Simulator, Gym League, Race Clicker, Bee Swarm Simulator or Blade Ball (for example minutes to first rebirth, or multiplier per rebirth). Fan wikis have per-game values, but I did not verify them.
- Blade Ball's design (parry-timing PvP with cosmetic/ability monetization) was not covered in a source I fetched.

## 2. What drove the biggest 2025 hits

### Takeaway
The hits share these traits:
- A one-line concept understandable from a thumbnail (grow plants, steal brainrots, survive 99 nights, ride a train through zombies).
- A broad or meme theme.
- A social/server dynamic (gifting, stealing, co-op survival).
- Weekly scheduled updates with live events.
- Amplification by Roblox's own social channels, big YouTubers, TikTok and the Trending/Up-and-Coming sorts.
- Experienced operators (Splitting Point, DoBig) who scaled small games made by teenagers.

### Cited Findings
- **Grow a Garden** (released Mar 26, 2025):
  - Made in a few days by a 16-year-old (BMWLux). Splitting Point Studios (Janzen "Jandel" Madsen, New Zealand) bought a share at about 500 CCU / 10-20k DAU and co-developed with Do Big Studios.
  - Growth: about 100k CCU within about 2 weeks, about 1M CCU within about a month, then a peak of about 22.3M CCU, about 60M DAU and about 30B plays.
  - Madsen credits the universal farming theme and the offline growth mechanic. He had made 30-40 games before this one, and only 5-6 were good. He has about 12M TikTok followers.
  - Source: [GamesBeat interview](https://gamesbeat.com/janzen-madsen-interview/)
- Splitting Point had 19 developers. It put about 12 staff on Grow a Garden when the game was at about 1k CCU (sources differ: about 500 vs about 1k). Updates ship weekly on Saturdays at 7am PST, with a celebratory gift for players. Do Big also scaled Fisch (3B visits, 500k+ CCU). — [GameDiscoverCo](https://newsletter.gamediscover.co/p/what-grow-a-gardens-89-million-ccu)
- Grow a Garden CCU timeline:
  - 8.9M CCU over a weekend during the limited-time "Monster Mash World Record" event (GameDiscoverCo, spring 2025).
  - 1.5-2.5M CCU on normal days at that time.
  - About 21.3M on 21 June 2025.
  - 22.3M on 23 Aug 2025.
  - Sources: [GameDiscoverCo](https://newsletter.gamediscover.co/p/what-grow-a-gardens-89-million-ccu); [ROLearn](https://rolearn.dev/case-studies/idle-garden-zero-to-20m-ccu)
- **Steal a Brainrot** (May 16, 2025, by SpyderSammy, owned by DoBig Studios):
  - 5M CCU in July 2025.
  - 20M on Aug 23, 2025 during the "admin war" crossover with Grow a Garden.
  - 24M on Sep 13, 2025 (Extinct Event).
  - 25.4M in Oct 2025, the first game past 25M.
  - 12.8M during a Bruno Mars virtual concert in Jan 2026.
  - Developer "admin abuse" events give out exclusive characters.
  - Epic licensed the game for Fortnite Creative as "Steal the Brainrot", which peaked at 400k-500k CCU.
  - Source: [Wikipedia](https://en.wikipedia.org/wiki/Steal_a_Brainrot); Rowatcher gives the Oct 2025 peak as 25.8M ([Rowatcher](https://rowatcher.com/news/is-the-brainrot-trend-dying-what-ccu-data-from-three-top-games-reveals)).
- **99 Nights in the Forest** (Grandma's Favourite Games: Alec Kieft, Cameron Angland, Matthew Hufton):
  - Peak 14.2M CCU, 26B visits by April 2026.
  - Won Best Adventure and Best Horror at the 2025 Innovation Awards.
  - 20th Century Studios film announced Apr 2026.
  - Source: [Wikipedia: List of Roblox games](https://en.wikipedia.org/wiki/List_of_Roblox_games)
- **Dead Rails** (1899 Wild West zombie train survival):
  - Featured on Roblox's official TikTok/Instagram/X in late Feb 2025 (TikTok clip: 499k+ likes). It reached the front page within days.
  - Flamingo's video got 2M+ views. KreekCraft, Thinknoodles and Sketch also covered it.
  - CCU went from hundreds to 200k+, then 600k+.
  - The article frames the success as MAYA ("Most Advanced Yet Acceptable"): familiar mechanics in a new setting, similar to Build A Boat (4.3B plays) and a dusty trip (1.4B visits).
  - Source: [GameAnalytics](https://www.gameanalytics.com/cn/blog/dead-rails-and-the-hit-makers-formula)
- Roblox appears willing to promote fast-emerging games with strong playtime and engagement. About 2,000 new experiences launch per day, and only about 1 in 50,000 reached the Top 10 by spend even for one day (Offpath estimate). — [GameDiscoverCo](https://newsletter.gamediscover.co/p/what-grow-a-gardens-89-million-ccu)
- CCU is a misleading measure of value. Hours played and ARPU matter more (for example, Adopt Me's ARPU is about 5x Brookhaven's). — [GameDiscoverCo](https://newsletter.gamediscover.co/p/what-grow-a-gardens-89-million-ccu)
- The platform record is 47.4M simultaneous users (summer 2025). — [Rowatcher](https://rowatcher.com/news/is-the-brainrot-trend-dying-what-ccu-data-from-three-top-games-reveals)

### Inferences
- Peak CCU records came from scheduled weekend events (Saturday updates, admin abuse, crossovers, concerts), not from steady play. Peaks are 5-10x the normal baseline. A solo dev can copy this pattern by shipping updates at a fixed weekly time and announcing events in advance.
- Meme themes (Italian Brainrot) and universally readable themes (garden, forest, train) give a strong thumbnail and title hook.
- Many hits were made in days by individuals and then scaled by studios. A solo dev's realistic path is a fast MVP and, if it gains traction (around 500-1k CCU), possibly a partner or publisher.

### Gaps
- No primary data on "+1 speed/strength every second" or "Escape X"/"Feed/Throw/Wash" one-verb games beyond the existence of many such titles (for example "Roblox but every second you get +1 speed"). I found no CCU or revenue analysis for them.
- Fisch was only covered via Do Big's involvement (3B visits, 500k+ CCU). I found no release date or dev interview.
- Revenue figures for Grow a Garden and Steal a Brainrot are not public. Dead Rails is described only as "millions monthly", without a figure.

## 3. Trend lifecycle: speed, clones, spotting trends, MVPs, when to stop

### Takeaway
Trends rise over weeks and peak within 2-5 months. They then decay steeply, with each later event spike smaller than the one before, and settle at 1-5% of peak. Players follow the genre more than individual games, so fast "trend + twist" titles can still hit (Escape Tsunami For Brainrots: about 5M CCU peak, launched Dec 2025). Late clones get much smaller numbers (Swing Obby for Brainrots: about 87k peak in Feb 2026).

### Cited Findings
- Grow a Garden decline in 2026 (monthly average CCU):

  | Month (2026) | Average CCU |
  |---|---|
  | May | 90.3k |
  | June | 73.3k |
  | July | 43.4k |
  | August | 32.7k |
  | September | 25.9k |
  | October | 19.7k |

  - Average CCU fell 19-41% each month, and October ended 78% below May.
  - Daily highs were 5-8x the monthly average.
  - Source: [ROLearn](https://rolearn.dev/case-studies/idle-garden-zero-to-20m-ccu)
- Steal a Brainrot fell to about 215k CCU (99.2% below peak) by about spring 2026. Each event peak was followed by a steeper drop than the last. Brainrot meme search interest peaked in May 2025, and the meme's creators declared it "dead" in Dec 2025. — [Rowatcher](https://rowatcher.com/news/is-the-brainrot-trend-dying-what-ccu-data-from-three-top-games-reveals)
- Escape Tsunami For Brainrots: created Dec 15, 2025, peaked at nearly 5M CCU, and was briefly #1 in Jan 2026. Later it was at about 164k. Swing Obby for Brainrots (Feb 18, 2026) peaked at about 87k and held about 57k five weeks later. The article concludes the trend is "normalizing" into a genre and that "players follow the genre more than individual games". — [Rowatcher](https://rowatcher.com/news/is-the-brainrot-trend-dying-what-ccu-data-from-three-top-games-reveals)
- Evergreen baselines for comparison: Brookhaven 700k-1M+, Blox Fruits 400-800k, Adopt Me 300-600k. — [Rowatcher](https://rowatcher.com/news/is-the-brainrot-trend-dying-what-ccu-data-from-three-top-games-reveals)
- BIG Games turned the Steal a Brainrot formula into Steal a Pet within about a month (June 2025, 31M+ visits). It also spun a PS99 event into a standalone game (Pets GO). — [Rowatcher: Inside BIG Games](https://rowatcher.com/news/inside-big-games-how-pet-simulator-became-a-100m-roblox-empire)
- Fortnite fast-followed too: the licensed Steal the Brainrot peaked at 400-500k. DoBig/Spyder sued an unlicensed Fortnite copy ("Stealing Brainrots") in Oct 2025. — [Wikipedia](https://en.wikipedia.org/wiki/Steal_a_Brainrot)
- Early signals for Dead Rails: Roblox's own social accounts, then the Top Trending and Up-and-Coming sorts, then big YouTubers. — [GameAnalytics](https://www.gameanalytics.com/cn/blog/dead-rails-and-the-hit-makers-formula)
- Fast follows only work if executed well. For example, a physics fast follow of Only Up (Steam) sold only about 6k copies despite a viral Reel. — [GameDiscoverCo](https://newsletter.gamediscover.co/p/what-grow-a-gardens-89-million-ccu)

### Inferences
- Window: Grow a Garden went from about 1k to 1M CCU in about a month. A trend's top-games window lasts roughly 2-4 months, and Brainrot spin-offs still hit 6-7 months after the original. To catch a wave, a solo dev should ship an MVP within 1-3 weeks of seeing a theme climb Trending/Up-and-Coming and appear in TikTok and YouTube thumbnails, then add a clear twist (a new verb or theme combination such as "Escape Tsunami" + "Brainrots").
- Stop or pivot rule (my heuristic, not sourced): if D1 retention stays under about 30% (see the ads benchmark in section 5) and CCU does not grow after 2-3 weekly updates, move on. Games that work tend to show traction within days of a promotion spike.
- Trackers (rowatcher.com, rotrends.com, rolearn.dev) give CCU history for spotting rising games.

### Gaps
- I found no systematic dataset on clone success rates (what share of trend clones pass, say, 1k CCU).
- No official Roblox statement on how the Trending/Up-and-Coming sorts work. The DevForum and RDC talks on the discovery algorithm were not fetched.

## 4. Genre-specific pitfalls

### Takeaway
The main documented risks are:
- Pay-to-win and predatory-monetization backlash (PS99 petition, Polygon criticism of Steal a Brainrot's paid "admin" powers).
- Exploiters and auto-farm scripts in passive-income and steal games.
- IP and licensing disputes over meme characters.
- Steep post-hype decline, which needs a steady weekly content cadence to slow it.

### Cited Findings
- PS99: free players say they cannot compete on leaderboards, and a Change.org petition accused the game of predatory monetization targeting minors. The PSX NFT pets (Oct 2021, $153k) drew strong backlash and were never repeated. The 2023 DMCA takedowns led to #BoycottBigGames. — [Rowatcher: Inside BIG Games](https://rowatcher.com/news/inside-big-games-how-pet-simulator-became-a-100m-roblox-empire)
- Steal a Brainrot:
  - Polygon criticized pay-to-win mechanics, including buyable "server admin" powers.
  - GameRant reported widespread cheaters using auto-collect and auto-steal scripts.
  - Viral videos of children crying over stolen Brainrots drew attention.
  - The Tung Tung Tung Sahur character was removed in Sept 2025 after a licensing dispute and returned Nov 29, 2025.
  - Source: [Wikipedia](https://en.wikipedia.org/wiki/Steal_a_Brainrot)
- Content droughts: PS2 updates stopped in Jan 2020 (one month after release), and players consider it the weakest entry. — [Rowatcher: Inside BIG Games](https://rowatcher.com/news/inside-big-games-how-pet-simulator-became-a-100m-roblox-empire)
- Each event spike buys a smaller bump, and decay continues even with updates (Grow a Garden down 78% from May to Oct 2026 while still being updated as of Oct 24, 2026). — [ROLearn](https://rolearn.dev/case-studies/idle-garden-zero-to-20m-ccu)

### Inferences
- In any steal or trade game, validate all economy actions on the server and rate-limit them, because exploit scripts are a known problem.
- Avoid meme characters with identifiable owners, or expect possible takedowns.
- Inflation in pet/trading economies is usually handled with new tiers (Huge → Titanic → Gargantuan) and resource sinks (fuse, enchant). That pattern is visible in PS99 but not documented by the developers.

### Gaps
- No primary postmortem on economy inflation (for example, PSX diamond inflation) was found. The "endgame emptiness" pitfall is not documented with data.

## 5. Studio economics: team sizes, small-dev success, publishers, ads

### Takeaway
Earnings are extremely top-heavy:
- Top 10 creators averaged $65.7M (12 months to Jun 2026).
- Top 1,000 averaged $1.4M.
- The median DevEx participant earned about $1,500.

Hits are often created solo or by tiny teams, then scaled by small studios (12-19 people) or publisher/co-owners (Splitting Point, DoBig). Paid Roblox ads only pay off when monetization and retention are already strong.

### Cited Findings
- RDC 2026 (12 months to Jun 30, 2026):
  - Top 10 creators averaged $65.7M, top 100 $10.8M, top 1,000 $1.4M.
  - Median creator: about $1,500 across 42k+ DevEx participants.
  - Total creator earnings about $1.7B (+~50% YoY). Over $5B lifetime DevEx.
  - Source: [Dexerto](https://www.dexerto.com/roblox/robloxs-top-creators-average-65-7-million-a-year-but-most-make-far-less-3408675/)
- RDC 2025 (Jun 2024-Jul 2025):
  - Top 10 averaged $38.5M, top 100 $7M, top 1,000 $980k. Median $1,440.
  - Over $1B paid to 29k developers from Apr 2024 to Mar 2025.
  - Source: [GameWorldObserver](https://gameworldobserver.com/2025/09/08/how-much-top-developers-earn-in-roblox-official-data)
- Team sizes:
  - Splitting Point: 19 developers, about 12 of them on Grow a Garden.
  - Grow a Garden was created by a teen in days. The original creator keeps a share and contributes ideas.
  - Acquisition terms (revenue share, cash or Robux) are speculative.
  - Sources: [GameDiscoverCo](https://newsletter.gamediscover.co/p/what-grow-a-gardens-89-million-ccu); [GamesBeat](https://gamesbeat.com/janzen-madsen-interview/)
- 99 Nights was made by a 3-person team. — [Wikipedia](https://en.wikipedia.org/wiki/List_of_Roblox_games)
- BIG Games (Preston): its early games failed for years (2011-2018) before Pet Simulator. The studio has an estimated $100M+ lifetime revenue, 25M+ group members and a 100+ creator promotion program. — [Rowatcher](https://rowatcher.com/news/inside-big-games-how-pet-simulator-became-a-100m-roblox-empire)
- Ads break-even math (July 2026; the CPV figures are DevForum estimates):
  - Cost: CPV about 4-12 Robux per visit (higher for obby and tycoon).
  - Payout: DevEx $0.0035 per Robux.
  - Break-even examples: 2% payer rate x 80 Robux ARPPU = 1.6 Robux per visit (a loss). 8% x 150 = 12 Robux per visit (a profit at 7 CPV).
  - Thresholds: monetization above about 5-6% and D1 retention above 30% before buying ads. Test with 5-10k Robux budgets and A/B test thumbnails and titles organically first.
  - Source: [Rowatcher: Roblox Ads break-even](https://rowatcher.com/news/roblox-ads-in-2026-the-break-even-math-small-devs-ignore)

### Inferences
- A solo dev should treat the first games as cheap experiments. Madsen made 30-40 games, with 5-6 good ones, before his hit.
- Weekly updates are achievable solo if the content pipeline is data-driven (new egg, pets, zone and multiplier per week).
- If a game reaches a few hundred to 1k CCU organically, studios like Splitting Point and DoBig have shown they will partner. That is a realistic route to scale.
- Reinvest in ads only after D1 is above 30% and the payer rate is above about 5%. Below that, ads lose money.

### Gaps
- Publishing or "fund" deal terms (Gamefam, DoBig, Splitting Point, Roblox's own creator funds) are not public in the sources I found.
- No verified CPM numbers for Roblox's Ads Manager. The CPV figures are developer estimates.
