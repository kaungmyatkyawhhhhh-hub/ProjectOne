---
title: Making Roblox games better
type: research-report
created: 2026-10-28
projects: [GYM ARC, SPEED ARC]
tags: [roblox, game-design, discovery, monetization, live-ops, mobile, kids-games]
---

# Win the 28-day return, not the click

Roblox changed what "better" means on 15 June 2026. The Home "Recommended For You" algorithm, the source of over 90% of platform traffic, now ranks games on a **28-day window** of organic, per-user signals. The heaviest of these are play-through rate, first-play bounce (sessions under 60 s and 61-180 s), play days and playtime per user on Day 1, Days 2-7 and Days 8-28 (playtime capped at 60 min/day), followed by friend co-play days, qualified sessions and spend days ([Creator Hub: Discovery](https://create.roblox.com/docs/discovery)). So for GYM ARC and SPEED ARC the work comes in this order. First, make the first 3 minutes impossible to bounce off on a cheap phone. Second, give kids a reason to come back on day 2, day 7 and day 20, ideally with a friend. Third, sell small, fair, frequently bought items. A thumbnail that over-promises now hurts, because the clicks it earns turn into bounces. A second change matters just as much for a kids' developer. Since the global launch of **Roblox Kids and Select on 16 June 2026**, a new game reaches players under 16 only after the creator is age-checked, ID-verified and on 2-Step Verification, the full Maturity & Compliance Questionnaire is done, and the game passes an engagement-and-safety trial played by **16+ users** ([Kids and Select docs](https://create.roblox.com/docs/production/publishing/kids-and-select)). Many of the levers people talk about online barely reach an 8-14 audience. Experience notifications, Discord/social links, rewarded video ads and the higher adult DevEx rate are all gated to 13+, 16+ or 18+. That leaves in-game design (onboarding, streaks, offline progress, friend boosts, weekly events) as the main lever a solo developer controls. Money is extremely top-heavy. The median DevEx creator earned about **$1,500** in a year, against **$1.4M** for the average top-1,000 creator ([Dexerto, RDC 2026 figures](https://www.dexerto.com/roblox/robloxs-top-creators-average-65-7-million-a-year-but-most-make-far-less-3408675/)). The realistic plan is to treat each game as a measured experiment, improve one bottleneck per week, and scale only what retains.

> **How to use this note.** Sections 1-9 explain the *why* with sources. The **Action checklists** and **Numbers to remember** tables at the end are the quick reference. Items marked *(inference)* are reasoned recommendations, not official Roblox statements. Items marked *(low reliability)* come from third-party blogs.

---

## 1. Home now rewards games kids return to for 28 days

### How the Recommended For You algorithm actually decides

Home works in two stages. **Retrieval** picks candidate games using engagement, retention and monetization signals. **Ranking** then personalizes the order for each player ([Creator Hub: Discovery](https://create.roblox.com/docs/discovery)). Only players who arrived *organically from RFY* count toward ranking. Players from ads, curation, search, friends, teleports or social links do not count, though those sources help a game get *retrieved*, and "even a few players can signal that a game is worth wider distribution" ([Creator Hub: Discovery](https://create.roblox.com/docs/discovery)). Every signal is a **per-user average, not a total**, so a small game with highly engaged players is not disadvantaged. This is the best structural news a solo developer has had in years.

The ranking signals after the June 2026 change, in Roblox's own priority order:

| Priority | Signal | What it means for a simulator |
|---|---|---|
| Most important | **Play-through rate (PTR)** | Share of players who see the tile in RFY and press play |
| Most important | **First-play bounce rate** (negative) | First sessions under 60 s, and 61-180 s |
| Most important | **Play days per user** (D1, D2-7, D8-28) | How many separate days kids come back |
| Most important | **Playtime per user** (D1, D2-7, D8-28) | Capped at **60 min per user per game per day** |
| Important | **Intentional co-play days** | Days a player returns to play with friends (join, invite, private server) |
| Important | Qualified play sessions per user | Sessions long enough to count as real play |
| Important | **Spend days per user** and Robux per user | How many *days* a player spends, not only how much |

Source: [Creator Hub: Discovery](https://create.roblox.com/docs/discovery). The 15 June 2026 change lengthened the lookback from **7 to 28 days** and removed "qualified play-through rate" as a ranking signal, replacing it with PTR plus bounce rates ([DevForum: RFY improvements, 15 Jun 2026](https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575)). Roblox's Chief Growth Officer said the old system "could disproportionately favor games that win attention with exciting thumbnails", and that those games were "displacing games that players value for the long term" ([Roblox Newsroom, 15 Jun 2026](https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox)). The exact signal weights were published only as an image and are not available in text, so nobody outside Roblox can say precisely how much co-play weighs against playtime.

Three consequences follow for GYM ARC and SPEED ARC. First, **the 60-minute daily playtime cap means a longer session past one hour does not help ranking; another return day does** *(inference)*. Second, because spend *days* count, a cheap item a kid buys on several different days does more for ranking than one big purchase *(inference)*. Third, new games do not wait 28 days. Signals arrive in stages: first-session PTR and bounce, then Day 1, then Days 2-7, then 8-28, and "early signals kick in immediately" ([Discovery FAQ](https://create.roblox.com/docs/en-us/discovery-faq.md)).

### Explore, expand, and why a bad launch is not fatal

When you update, Roblox may test the game on a new cohort ("explore"). If that cohort engages and spends well, Roblox recommends it to more similar cohorts ("expand"), and the game settles at a new baseline. A **temporary drop in PTR when impressions rise is normal** ([Creator Hub: Discovery](https://create.roblox.com/docs/discovery)). Roblox tests games daily and states there is "no penalty" for a weak start: fix onboarding and the system keeps testing you with new players ([Discovery FAQ](https://create.roblox.com/docs/en-us/discovery-faq.md)). Impressions also move with things outside your control. Total Home traffic **peaks on Saturdays** and has summer, back-to-school and holiday seasons, and competitors that engage better can take your distribution ([Creator Hub: Discovery](https://create.roblox.com/docs/discovery)). The diagnostic rule from the docs is worth memorizing: "Impression drops usually follow drops in play-through rate, play days, and playtime, along with a rise in first-play bounce rate."

### What gets a game throttled

A **custom thumbnail is required** to receive any Home recommendation impressions. Roblox deprioritizes titles that lead with giveaways or imply monetary rewards, titles or thumbnails that don't match gameplay (also less visible in search), and near-copies of existing games. Quality is reassessed on every update, and the Creator Dashboard shows a daily-updated "reduced exposure" banner ([Creator Hub: Discovery](https://create.roblox.com/docs/discovery)). Among near-identical games, Roblox favours whichever first added the unique metadata or place file ([Discovery FAQ](https://create.roblox.com/docs/en-us/discovery-faq.md)). The Fall 2026 roadmap adds "deceptive game copy takedowns" and "name checks" that protect game names from copycats, both due late 2026 ([Creator Roadmap 2026: Fall Update](https://devforum.roblox.com/t/creator-roadmap-2026-fall-update/4880208)). Since gym and running simulators are crowded genres, GYM ARC and SPEED ARC need their own name, art and twist, not a lookalike of Muscle Legends or Race Clicker *(inference)*.

### Search, titles and charts

Roblox publishes almost nothing about search ranking. Search historically matched exact queries against titles, and it now also supports semantic, natural-language queries ("food games") in all supported languages ([Creator Hub: Discovery](https://create.roblox.com/docs/discovery)). The only official advice is to keep metadata accurate and detailed. Search also pays directly: a player who searches your game's *name* as their first session of the day and plays 10+ minutes can earn you a Creator Rewards Audience Expansion payout ([Creator Rewards](https://create.roblox.com/docs/en-us/creator-rewards.md)). The practical title formula is therefore a short, unique brand word plus the genre nouns kids type. "GYM ARC" and "SPEED ARC" already are brand words. Adding "Gym Simulator" or "Speed Run Simulator" to the title, and putting a plain, keyword-rich first sentence in the description, covers both exact and semantic search *(inference)*. No official source says "[UPD]" tags or emojis help ranking. They are community convention only, and a **"promotional text for updates" field due late 2026** should replace them ([Creator Roadmap 2026: Fall Update](https://devforum.roblox.com/t/creator-roadmap-2026-fall-update/4880208)).

Charts are a separate surface. "Top Playing Now" ranks by live concurrent players (launched 5 March 2025) ([DevForum](https://devforum.roblox.com/t/introducing-top-playing-now-on-charts/3529809)). No official criteria exist for Up-and-Coming, Top Trending or Top Earning. For a small game, charts are a *result* of success rather than a lever you can pull *(inference)*.

### Thumbnails, icons and video: specs and the personalization test

| Item | Spec / rule | Source |
|---|---|---|
| Thumbnail size | 16:9, ideally **1920×1080**; .jpg/.png/.gif/.tga/.bmp; under **3 MB** for personalization uploads | [Thumbnails docs](https://create.roblox.com/docs/en-us/production/publishing/thumbnails.md) |
| Max on details page | **10** images or videos | same |
| Bottom strip | Keep text off the bottom; the player-count overlay covers it | same |
| Video thumbnails | **3 free uploads per month** (rejections count); can appear on Home; no voice-over, no lyrics, no real-life footage, no enhanced graphics, no features the game lacks; free camera = **Left Shift + P** in solo playtest | same |
| Thumbnail Personalization | **2-5** active thumbnails; Roblox serves each to random users, then gives each user segment its winner; average **+8.5%** qualified play-through in testing, some games **+50%** | same |
| How long to hold variants | At least **7 days** between changes; refresh with each major update | [2025 Discovery Roadmap](https://devforum.roblox.com/t/roblox%E2%80%99s-2025-discovery-roadmap-and-ways-to-reach-and-engage-your-audience/3557533) |
| Icon | 512×512 is the long-standing convention (not verified this session); no official icon A/B tool confirmed | — |

Since June 2026, personalization is judged against PTR rather than qualified PTR ([DevForum RFY change](https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575)). Reverting to an older thumbnail "shouldn't negatively affect discoverability" ([Discovery FAQ](https://create.roblox.com/docs/en-us/discovery-faq.md)). Thumbnails also face stricter moderation than icons. One developer received a warning for guns in a thumbnail that passed as an icon ([DevForum, 2023](https://devforum.roblox.com/t/thumbnail-got-me-a-warning-while-icon-didnt/2643599)).

For phone-sized tiles, the working recipe *(inference)* is one large focal subject: an avatar with an exaggerated expression holding the power-fantasy object (giant muscles lifting a glowing dumbbell for GYM ARC; a speed trail and blurred background for SPEED ARC). Add saturated, high-contrast colour, two or three big words at most, and nothing important along the bottom. Run 3-5 *genuinely different* concepts with personalization rather than five colour swaps. Cut a free 15-30 s gameplay video for every major update. Every thumbnail must show something the game really contains, because a misleading tile raises PTR and then raises bounce, and bounce is penalized.

---

## 2. The first 180 seconds decide whether the algorithm ever sees you

### What Roblox says to measure first

Roblox tells creators to focus first on **D1 retention and average session time**, and to get retention, engagement and monetization "comparable to or above" similar games before driving heavy traffic ([Creator Docs: Analytics](https://create.roblox.com/docs/production/analytics.md)). Roblox publishes no fixed "good" numbers. Benchmark scorecards inside the dashboard compare you against "similar experiences" or your genre, need **100+ DAU**, and update daily ([Creator Docs: Analytics](https://create.roblox.com/docs/production/analytics.md)). Outside reference points:

| Benchmark | Value | Reliability |
|---|---|---|
| Simulator retention (promoted games) | **D1 32% / D7 14% / D30 6.2%** | Vendor data, 850+ promoted games, no methodology ([BLOXG](https://bloxg.com/statistics/roblox-retention-benchmarks)) |
| Tycoon | D1 30% / D7 12% / D30 5.1% | same |
| Obby (for contrast) | D1 18% / D7 6% / D30 1.9% | same |
| Minimum floor from experienced DevForum advice | **≥10% D1, ≥8 min average session** | Community rule of thumb ([DevForum](https://devforum.roblox.com/t/suggestions-to-improve-average-session-time-day-1-retention/2935525)) |
| Creator Rewards threshold | **10+ minutes** of play | Official ([Creator Rewards](https://create.roblox.com/docs/creator-rewards)) |

A reasonable target ladder for GYM ARC and SPEED ARC *(inference)*: first clear 10% D1 and 8 minutes per session. Then aim for 20-30% D1. Design the first session so most new players pass **10 minutes**, because both Creator Rewards payouts require 10+ minutes. The 32% vendor figure comes from promoted games, a selected sample, so it is optimistic for a new title. Before treating a D1 change as a game problem, check D1 broken down by acquisition source (added 16 Oct 2025). Players from external links (TikTok, Discord) retain much worse than Home players, so a change in traffic mix alone can drag the average down ([DevForum](https://devforum.roblox.com/t/analytics-view-retention-by-acquisition-source-and-select-your-benchmark-set/4010157)).

### Teach with the world, not with words

Roblox's onboarding guide names three techniques. **Visual elements** are highlights, glow, arrows and feedback. **Contextual tutorials** are triggered by normal play, such as entering a zone or picking up an item. **Timed hints** appear only for players who are stuck ([Onboarding techniques](https://create.roblox.com/docs/en-us/production/game-design/onboarding-techniques.md)). The same page lists what makes players leave: not knowing what to do in the first minutes, long prescriptive tutorials, too much to learn early, skippable text, **text too small on mobile**, **young players still learning to read**, fixed sequences, late hints, and missing feedback that makes the game feel broken. Its worked hint-timing example is concrete. Most testers pressed the key button within 10 s, so the highlight appears at **11 s**, is shown once, and only to players who need it. Named examples are worth copying: Hello Kitty Cafe dims the screen and spotlights the button with an arrow and trail; Jailbreak uses footprints; Squishmallows teaches merging only when the player first holds two identical items.

Your players are 8-14 and some read English as a second language, so arrows, glowing paths, pulsing buttons and big numbers beat any sentence. A third-party opinion piece puts the main drop-off in the first 90 seconds and warns against lore loading screens, control dumps and unskippable NPC dialogue ([RoWatcher](https://rowatcher.com/news/your-first-90-seconds-are-destroying-roblox-retention), *low reliability*). Simulator-specific advice from the DevForum fits the genre: currency counters on the side, bright colours (grey lobbies repel young players), a physical shop in the lobby that shows what to work toward, easy maps because most players are on mobile, short respawns, and playtests with friends where *you say nothing* ([DevForum](https://devforum.roblox.com/t/suggestions-to-improve-average-session-time-day-1-retention/2935525)).

### Instrument the funnel before anything else

`AnalyticsService:LogOnboardingFunnelStepEvent(player, step, stepName)` builds a one-time onboarding funnel. It must be called from the **server**, in a **published** game, and only the first time each step is reached counts. Logging step 3 auto-completes steps 1-2, saved progress expires after 180 days, and you get up to **10 funnels**. Log step 1 on `PlayerAdded`. Roblox's own example lost **70% of players between step 1 and step 2**, and the advice is to fix the single biggest drop first ([Funnel events](https://create.roblox.com/docs/production/analytics/funnel-events.md)). Suggested steps *(inference)*:

| Step | GYM ARC | SPEED ARC |
|---|---|---|
| 1 | Joined | Joined |
| 2 | First lift / click | First run / first step on the track |
| 3 | First strength gained & shown | First speed stat gained |
| 4 | First upgrade or shop purchase (soft currency) | First upgrade (shoes/trail) |
| 5 | First pet or egg | First race finished |
| 6 | Entered second gym / zone | Unlocked second track / world |
| 7 | First rebirth | First rebirth |
| 8 | Reached 10 minutes | Reached 10 minutes |

### Load fast on a cheap phone

There is no official numeric join-time target. The docs do say how to make loading fast. Leave instance streaming on so only the area around spawn loads first, move assets players don't need at join from ReplicatedStorage to ServerStorage, keep ReplicatedFirst to loading-screen assets, preload only the loading screen, menu and spawn area, offer a **"Skip Loading"** button for large preloads, and build UI panels lazily when opened ([Improve performance](https://create.roblox.com/docs/performance-optimization/improve)). A 3-5 s branded loading screen that preloads only the lobby is the right trade-off for kids on mobile data *(inference)*. A crash or 20-second load on a low-RAM phone is a first-play bounce, and first-play bounce is now a top-tier negative ranking signal.

---

## 3. Retention comes from daily hooks, weekly content and friends

### The safe, proven retention stack

Roblox's own design docs endorse **quests, achievements and dailies**, **season passes**, **collections** (collectible pets), limited-time content and leaderboards ([Game design](https://create.roblox.com/docs/production/game-design.md); [LiveOps essentials](https://create.roblox.com/docs/en-us/production/game-design/liveops-essentials.md)). Limited-time content should be available to all players during the event, with objectives that "take most players weeks". Add permanent end-of-progression content for high-level players ([Content updates](https://create.roblox.com/docs/en-us/production/game-design/content-updates.md)). Grow a Garden's breakout hook was **persistent offline growth**: players came back to find plants bigger, which its developer called novel on Roblox ([GamesBeat](https://gamesbeat.com/janzen-madsen-interview/)). DevForum advice adds playtime gifts at milestones (e.g. 10, 20, 60 min), daily login rewards and a visible top-10 leaderboard ([DevForum](https://devforum.roblox.com/t/suggestions-to-improve-average-session-time-day-1-retention/2935525)).

For a gym or running simulator, the stack looks like this *(inference)*:

- Daily login streak with a visible calendar.
- Playtime gifts at 5/10/20/30/60 minutes. The 10-minute gift lines up with Creator Rewards, and the 60-minute gift lines up with the RFY playtime cap.
- Daily and weekly quests.
- A pet collection index.
- Rebirth with a permanent multiplier.
- An **offline-gains mechanic**: "your gym kept training while you were away" or "your pets ran laps overnight".
- Global and friends leaderboards.

The offline-gains item matters most now that Days 2-28 return behaviour is a top ranking signal. Under-13 players cannot receive re-engagement notifications, so the reason to come back has to live inside the game.

### What is banned or manipulative

The hard lines are explicit. Notifications may not use **false time pressure**, disguised ads, bait-and-switch "free" rewards or tricks into purchases ([Experience notifications](https://create.roblox.com/docs/production/promotion/experience-notifications.md)). The monetization rules ban permanent fake "sales", false scarcity and **countdown timers that are inaccurate or reset for the same item** ([Creator Hub: Monetization](https://create.roblox.com/docs/en-us/production/monetization)). Paid eggs need full odds disclosure (Section 4). A University of Sydney study of 15 popular Roblox games found deceptive purchase design in 14. It named fake "worth" prices, loot boxes, prompts to spend after a loss, near-miss visuals, false-urgency timers and pay-to-progress ([University of Sydney, 17 May 2026](https://www.sydney.edu.au/news-opinion/news/2026/05/17/inside-the-pay-to-play-world-of-roblox-targeting-children-.html)). Regulators and journalists are watching kids' simulators specifically, so staying clean is also reputation insurance.

### Live ops: a cadence one person can sustain

Roblox's guidance: "many games release cadence updates every **two weeks to one month**". Keep each update under **three weeks' effort**, reuse existing systems (a new system turns an update into an expansion), build around a theme, and use cheap variants such as recolours ([Content updates](https://create.roblox.com/docs/en-us/production/game-design/content-updates.md)). Look after your own wellbeing and keep the frequency realistic ([LiveOps essentials](https://create.roblox.com/docs/en-us/production/game-design/liveops-essentials.md)). The 2025 megahits ran **weekly Saturday updates**. Pet Simulator 99 ships Saturdays at 5 PM GMT ([Rowatcher](https://rowatcher.com/news/inside-big-games-how-pet-simulator-became-a-100m-roblox-empire)) and Grow a Garden at 7 AM PST ([GameDiscoverCo](https://newsletter.gamediscover.co/p/what-grow-a-gardens-89-million-ccu)). Both had full teams; Splitting Point put about 12 people on Grow a Garden. Even then, by August 2025 Grow a Garden's community called weekly events repetitive. The developer said the cycle squeezed out bug fixes and depth, and moved toward fewer, deeper features ([Roonby, 11 Aug 2025](https://roonby.com/2025/08/11/grow-a-garden-might-not-be-getting-weekly-updates-anymore/)).

Scheduled weekend "Admin Abuse" events produced enormous spikes. On 23 August 2025 Steal a Brainrot hit 20M CCU and Grow a Garden 21.1M, while Roblox set a platform record of 47.4M concurrent. Both games then returned to about 1M ([Tubefilter](https://www.tubefilter.com/2025/08/25/roblox-grow-garden-steal-brainrot-admin-war-record/)). Events buy spikes, not baseline. A sustainable solo rhythm *(inference)* is a small themed drop every two weeks (new pets, an egg, a zone or a gym built with existing systems), one bigger feature a month, and a fixed weekly event time (Saturday, when Home traffic peaks) with an in-game countdown that is truthful, never reset, and announced in advance. With two games, alternate weeks between GYM ARC and SPEED ARC rather than updating both weekly.

### Social features are now a ranking signal, and the best-evidenced lever

Roblox's data shows **sessions with friends average 1.9× longer than solo sessions** ([DevForum: Party](https://devforum.roblox.com/t/party-is-here-unlock-a-new-level-of-engagement/3282068)), and intentional co-play days are an "important" RFY signal. Roblox gives you three tools:

- **Party**: up to 6 friends join the same server together. Under-13s can join, though not use party chat.
- **Friend Referral System** (fully released 23 April 2025). `Player:GetJoinData().ReferredByPlayerId` identifies the inviter so you can reward both sides. A reward banner is set in Creator Hub > Engagement > Referral Rewards, with an optional per-inviter cap (e.g. 3). Links never expire. The game must have been live for at least one day. `ReferredByPlayerId` returns 0 in reserved servers, and abuse prevention needs one-time rewards and DataStore tracking ([Referral system](https://create.roblox.com/docs/production/promotion/referral-system)).
- **Experience notifications**: opt-in, **13+ only**, one per user per game per day, at most 99 characters, analytics after 100 impressions. The opt-in prompt can't be customised and re-shows at most every 30 days. Under-13s receive only update announcements ([Experience notifications](https://create.roblox.com/docs/production/promotion/experience-notifications.md)).

Chat is also limited now. Since January 2026 users are sorted into age bands (<9, 9-12, 13-15, 16-17, 18-20, 21+) and can chat only with similar ages. In-game chat is **off by default for under-9s** unless a parent consents ([Roblox Newsroom, 19 Nov 2025](https://about.roblox.com/newsroom/2025/11/roblox-requires-age-checks-limits-minor-and-adult-chat)). Social design for kids therefore can't depend on chat. It has to work through *mechanics* *(inference)*:

- A visible friend boost, e.g. +10% gains per friend in the server. This is a common convention, not a sourced number.
- Two-sided referral rewards using the banner.
- Cheap or free private servers.
- Co-op goals: group lifting challenges in GYM ARC, relay races in SPEED ARC.
- Emotes and gifting.

---

## 4. Monetization pays 70%, but kids' wallets limit the extras

### What actually pays a kids' simulator

| Stream | Creator share / terms | Reaches under-13s? | Source |
|---|---|---|---|
| Passes (one-time) & developer products (repeatable) | **70%** of Robux | Yes | [Earn on Roblox](https://create.roblox.com/docs/production/earn-on-roblox) |
| Subscriptions | Local currency: **70% month 1, then 100%**; Robux subs: 70% monthly; tiers $2.99/$4.99/$7.99/$9.99/$14.99; Robux subs from **49 Robux**; max 50 per game | Yes (parents pay) | [Subscriptions](https://create.roblox.com/docs/en-us/production/monetization/subscriptions) |
| Creator Rewards: Daily Engagement | **5 Robux per Active Spender per day** (≥$9.99 spent on Roblox in 60 days, 10+ min in your game, among their first 3 games that day) | Yes, if they spend | [Creator Rewards](https://create.roblox.com/docs/en-us/creator-rewards.md) |
| Creator Rewards: Audience Expansion | **35% of a new/returning user's first $100** of Roblox-wide spend over 60 days; needs Share Link/direct link/name search plus 10+ min play; game must average **100+ DAU**; you must be ID-verified | Yes | same |
| Rewarded video ads | EPM × impressions; game needs **2,000+ monthly unique visitors**; publisher 13+, 2FA, ID-verified | **No: viewers must be eligible (13+)** | [Rewarded video ads](https://create.roblox.com/docs/production/promotion/rewarded-video-ads) |

Creator Rewards went live **24 July 2025**, replacing Premium/Engagement-Based Payouts. Its earnings sit on a **60-day hold**, and "unusually long session times may see reduced earnings" ([DevForum: Introducing Creator Rewards](https://devforum.roblox.com/t/introducing-creator-rewards-earn-more-by-growing-the-community/3777628)). At $0.0038 per Robux, 5 Robux is about **$0.019 per qualifying spender per day**, so the daily reward mostly rewards players returning daily. The practical streams for an 8-14 audience are passes, developer products, subscriptions and the daily engagement reward. Rewarded ads and the higher adult DevEx rate barely apply *(inference)*.

### DevEx in numbers

The standard rate is **$0.0038 per Earned Robux** (about $114 per 30,000), effective 5 September 2025. Balances earned before then cash out at the legacy $0.0035. A higher **$0.0054** rate (since 8 June 2026) applies only to spending by **age-verified US adults 18+** in eligible games ([Developer Exchange](https://create.roblox.com/docs/de-de/production/monetization/developer-exchange); [Roblox Newsroom, 30 Apr 2026](https://about.roblox.com/newsroom/2026/04/roblox-fuels-high-fidelity-games-over-18-players-increases-qualifying-devex-rate-42)). Eligibility: age 13+, at least **30,000 Earned Robux**, verified email, a DevEx portal account, and a **W-8 tax form for non-US creators**. You can apply once per calendar month via Creator Hub → Finance → Cash Out, and processing takes about 10 business days the first time and about 5 after that ([Developer Exchange](https://create.roblox.com/docs/de-de/production/monetization/developer-exchange)). The hold on pass and product sales conflicts between official pages. The Monetization page says a **30-day escrow**, the Subscriptions page "about 5 days". Check the Finance tab for your real figure ([Monetization](https://create.roblox.com/docs/en-us/production/monetization); [Subscriptions](https://create.roblox.com/docs/en-us/production/monetization/subscriptions)).

### Pricing: let Roblox test, and never hard-code prices

Since **15 June 2026**, Regional Pricing and Price Optimization are merged into **Managed Pricing** for passes and developer products. Tests run at least every 90 days for about 3 weeks, and a new price is adopted only if total revenue rises. New games and items are auto-enrolled, and you can override. Hard-coded prices must be removed ([DevForum: Managed Pricing](https://devforum.roblox.com/t/managed-pricing-one-system-for-better-pricing-and-earnings-growth/4684738)). Roblox reports regional pricing raised Robux spend **4-10%** and pass purchases **43-52%** in discounted regions, and price optimization raised earnings about **4%** on average. Price testing needs roughly **60,000 transactions in 30 days**, so a small game will get regional pricing well before it qualifies for optimization ([Price optimization](https://create.roblox.com/docs/en-us/production/monetization/price-optimization)). Regional pricing matters to you directly: many players in Southeast Asia, including Myanmar, see lower local prices. The one rule to give Claude Code: **every price shown in the UI must come from `MarketplaceService:GetProductInfo`, never a typed-in number**.

### What to sell, and how to show it to kids

Roblox's taxonomy separates durable from consumable items, and enhancement items (speed, protection, access) from expression items (skins, emotes, **pets**) ([Monetization foundations](https://create.roblox.com/docs/en-us/production/game-design/monetization-foundations)). Simulator staples map onto it cleanly *(inference)*:

- **Durable enhancement passes**: 2× strength or 2× speed, VIP, auto-train or auto-run, extra pet slots, faster hatching.
- **Consumable products**: 15-minute boost potions, currency packs.
- **Expression items**: trails, auras, pets.
- **Optional**: a Robux subscription, e.g. a daily gem drip plus a cosmetic.
- **Optional**: a season pass whose premium track is a *superset* of a real free track, as Roblox specifies.

Pet Simulator 99 shows how far the hatch-speed pass and exclusive-egg model can go. It also drew a Change.org petition over predatory monetization of minors and free-player complaints that leaderboards are pay-to-win ([Rowatcher](https://rowatcher.com/news/inside-big-games-how-pet-simulator-became-a-100m-roblox-empire)). Sell time-savers and cosmetics that free players can also earn, and never prompt a purchase right after a loss.

Roblox's shop guidance: an easy-to-find shop icon, easy entry and exit, explain each item's value against the alternatives, make it "a place to linger and browse", rotate stock, and show offers at natural moments ([Monetization foundations](https://create.roblox.com/docs/en-us/production/game-design/monetization-foundations)). A **starter pack** is officially "an initial offer … that a new user sees within the first few minutes." For minors, Roblox gives exact wording swaps: "GET IT NOW" → **"View Item"**, "LAST CHANCE, ACT NOW" → **"See Price"**, "BUY BEFORE IT'S GONE!" → **"Open Shop"** ([Creator Hub: Monetization](https://create.roblox.com/docs/en-us/production/monetization)).

### Eggs and luck: the non-negotiable rules

Anything random bought directly or *indirectly* with Robux counts as a paid random item. That includes eggs bought with a currency that can itself be bought with Robux. The rules ([Paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items.md)):

- Show **every possible outcome with exact percentage odds totalling 100%, before purchase**. A bare (i) icon is not enough; use a labelled "Info"/"Details" button.
- Luck boosts and pity systems must state their effect in numbers, and the displayed odds must update while a boost is active.
- Update odds when one-time outcomes are already owned.
- Check `PolicyService:GetPolicyInfoForPlayerAsync()`. If `ArePaidRandomItemsRestricted` is true, offer a free path or a direct purchase, or block the item. If `IsPaidItemTradingAllowed` is false, block trading of paid outcomes.

Random rewards earned purely through gameplay need no disclosure. A secondary report says Korea's loot-box rules pushed Roblox to require disclosure worldwide ([TechTimes, 26 Jun 2026](https://www.techtimes.com/articles/319148/20260626/koreas-loot-box-rules-push-roblox-disclose-item-odds-worldwide.htm)). Simulated gambling (betting games) is not allowed at **any** maturity label ([Content Maturity](https://create.roblox.com/docs/production/promotion/content-maturity)).

---

## 5. Reaching under-16 players now requires passing Kids and Select

### The gate every kids' game must clear

This is the policy change most likely to decide whether GYM ARC and SPEED ARC ever reach their intended players. Roblox now runs three audiences: **Roblox Kids (5-8), Roblox Select (9-15) and standard Roblox (16+)**. Content labels map onto them. **Minimal** and **Mild** are shown to Kids and Select, **Moderate** to Select and 16+, and Restricted to verified 18+ only ([Content Maturity](https://create.roblox.com/docs/production/promotion/content-maturity)). A game with no questionnaire is not playable at all. To reach under-16s you need all of the following ([Kids and Select docs](https://create.roblox.com/docs/production/publishing/kids-and-select)):

- An **age-checked, verified creator account** (government ID if 18+), **2-Step Verification**, and good standing.
- The **full** Maturity & Compliance Questionnaire (Creator Hub > Creations > game > Audience). Answer for the most extreme content a player can encounter, and resubmit after any update that changes an answer.
- A one-time **refundable publishing fee** (1,000 Robux per the DevForum) *or* Roblox Plus/Premium held for 2 consecutive months. The fee is refunded 90 days after the game becomes eligible.
- A trial period in which the game is shown to **16+ age-checked players** while Roblox measures engagement from "highly engaged players" and runs a safety review. Progress appears on the **Audience Reach** dashboard.

The figures conflict between sources. The docs say **250 unique plays from highly engaged players in 60 days** and a **50,000 Robux** refundable Expedited Review. The DevForum says **500 Highly Engaged Players**, a maintenance threshold cut from 100 to 25 on 16 July 2026, a further cut to be announced in August 2026, and **100,000 Robux** for a ≤48 h expedited review ([DevForum: Kids and Select launch](https://devforum.roblox.com/t/roblox-kids-and-select-global-launch-upcoming-updates-to-eligibility-ads-manager-and-expedited-review/4685717)). Check the Audience Reach tab for the live figure. Ads Manager has an **"Engagement" objective (beta) that targets players who count toward the threshold**, which is the most legitimate use of a small ad budget for a brand-new kids' game. Note that campaigns don't auto-pause when you reach it ([DevForum](https://devforum.roblox.com/t/roblox-kids-and-select-global-launch-upcoming-updates-to-eligibility-ads-manager-and-expedited-review/4685717)). The strategic consequence *(inference)*: your first players will be **teens and adults**, and the game must appeal to them enough to pass the trial before kids ever see it. Early retention data will not look like your eventual audience.

### Features that silently push a game out of the kids' audience

These descriptors move a game to 16+ or 18+ ([Content Maturity](https://create.roblox.com/docs/production/promotion/content-maturity); [Experience guidelines](https://create.roblox.com/docs/en-us/production/promotion/experience-guidelines)):

- **Social hangouts** are 16+, or 18+ with private spaces. A title or description that says "hangout" can classify the game as one.
- **Free-form user creation**, meaning drawings, writing or pixel canvases visible to others, is 16+. 3D building with assets is fine.
- **Sensitive issues** are 16+.
- Romance, alcohol and strong language are 18+.

Minimal allows occasional mild violence. Mild allows repeated mild violence, mild fear and mild crude humour. A gym or running simulator naturally fits Minimal or Mild *(inference)*. Keep it there: no punching realism, no bedrooms or bathrooms as hangout spaces, no sign-writing, no gambling visuals.

### Text, links and community rules that catch kids' developers

Any text players type or that is stored and shown to others (pet names, crew names, signs) must go through `TextService:FilterStringAsync` on the server. If Roblox detects unfiltered text, "it removes the game until filtering is added" ([Text filtering](https://create.roblox.com/docs/ui/text-filtering)). The simplest safe design is **preset name pickers instead of free text** *(inference)*.

Links are effectively banned inside games. Since early 2026, creators can't post social media links inside experiences ([Roblox Newsroom, 19 Nov 2025](https://about.roblox.com/newsroom/2025/11/roblox-requires-age-checks-limits-minor-and-adult-chat)). Since **30 June 2026**, Social Links on game pages and Communities are visible only to **age-checked 16+** users, with up to 3 per page ([Roblox Help: Social Links](https://en.help.roblox.com/hc/articles/360000910966)). One developer's game was taken down for a kick message that merely said "check our experience social links" ([DevForum, 2025](https://devforum.roblox.com/t/warned-for-directing-users-off-platform-i-have-2-questions/3909424)). Never write "join our Discord", a server name or a QR code anywhere in-game, including signs, decals, kick messages and codes. Independent in-game ads must be labelled and hidden from under-13s through PolicyService. "Free Robux" claims and Robux-prize giveaways are banned ([Rules of Conduct](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct)).

For IP, use only original or licensed art. Rights holders can remove up to 250 creations per request through Rights Manager ([Rights Manager](https://create.roblox.com/docs/production/publishing/rights-manager)). Steal a Brainrot temporarily lost a meme character in a licensing dispute ([Wikipedia](https://en.wikipedia.org/wiki/Steal_a_Brainrot)). Avoid real logos, sportswear brands, celebrity athletes and YouTuber faces, which is a real temptation in gym and running themes *(inference)*.

### Community without Discord

For an under-16 audience, Discord and social links are now invisible on Roblox surfaces. The reliable community channels are the ones inside Roblox *(inference, based on the rules above)*:

- An in-game "What's New" board and an update log in the description.
- Codes released in-game and in the description.
- Your Roblox **Community** (group), with shouts and member perks.
- Personalized notifications to opted-in 13+ players.
- Preset in-game feedback buttons and surveys.

Use Discord for older fans, parents and testers only. Roblox also auto-removes servers with high volumes of violating behaviour ([Roblox Newsroom, 15 Aug 2025](https://about.roblox.com/newsroom/2025/08/extending-roblox-policy-on-romantic-and-sexual-content)), so limiting free-form interaction protects the game as well as the players.

---

## 6. Cheap phones set the technical budget

### Client performance: the official budget and the biggest wins

Roblox's method: pick a **low-end baseline phone** and test on it throughout development. Example targets are about **1,000 draw calls and 1,000,000 triangles**, and the frame budget is **16.67 ms at 60 FPS**. Studio's device emulator is accurate for screen shape and controls but **not for memory**, so test on a real phone ([Design for performance](https://create.roblox.com/docs/performance-optimization/design)). The high-impact rules, all from the official docs ([Improve performance](https://create.roblox.com/docs/performance-optimization/improve); [Streaming](https://create.roblox.com/docs/workspace/streaming)), translated into simulator terms:

| Rule | Why | Simulator application |
|---|---|---|
| Instance streaming on, **StreamOutBehavior = Opportunistic**, ModelStreamingBehavior = Improved, StreamingIntegrityMode = PauseOutsideLoadedArea | Streaming is "the highest-impact way to reduce client memory use" | Gyms/tracks in other worlds don't sit in phone memory |
| Import each mesh once, duplicate in Studio; reuse textures | Identical meshes batch into one draw call | One mesh per pet/dumbbell/shoe type |
| Transparency only **0 or 1** | Partial transparency causes overdraw | No semi-clear glass eggs, zone walls or speed-gate panes |
| **CastShadow off** on small, distant, moving parts; fewer lights | Shadows and lights are expensive | Pets, coins, orbs, decorations |
| Textures **≤512 px**, minor images **≤256 px**; tint one texture rather than making colour variants | 1024² uses 4× the memory of 512² | Rarity variants via colour, not new textures |
| RenderFidelity Automatic/Performance; CollisionFidelity Box/Hull; CanCollide/CanTouch/CanQuery off on decor; anchor static parts | Cuts physics and render cost | Decorative gym props, track scenery |
| AnimationController instead of Humanoid for simple NPCs; animate pets on the client; pool respawning objects | Humanoids are expensive and replicate | Following pets, NPC trainers |
| Tweens and visual effects on the **client** | Server tweens replicate every frame and cause lag | Coin fly-ups, number popups, speed trails |

For a running simulator in particular, long straight tracks tempt you into huge visible worlds. Lower the streaming radius and reuse a modular track kit *(inference)*.

### Server and data: one profile per player, saved sensibly

Store **one key per player** (built from UserId) in a small fixed number of data stores. Load once, keep a server copy, save periodically (the official sample uses 180 s), and also save on leave, on shutdown and after purchases. Wrap calls in `pcall` with backoff, and prefer `UpdateAsync` where several servers might write ([Data store best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices)). Roblox says **not to use DataStore2 for new games**. The community standard is **ProfileStore**, which provides session locking and a 300 s default auto-save. Its predecessor ProfileService is no longer supported ([ProfileStore docs](https://madstudioroblox.github.io/ProfileStore/); [ProfileService GitHub](https://github.com/MadStudioRoblox/ProfileService)). ProfileStore "is not designed … for in-game leaderboards". Use an OrderedDataStore for all-time boards and a MemoryStore sorted map for weekly or fast boards ([Memory stores](https://create.roblox.com/docs/cloud-services/memory-stores)).

The limits as of the **29 July 2026** change, which raised base storage from 100 MB to 500 MB ([DevForum](https://devforum.roblox.com/t/unifying-data-stores-open-cloud-and-game-apis-and-increasing-storage-limits/4739240); [Error codes and limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)):

| Limit | Value |
|---|---|
| Per-server read/write per minute | **60 + 40 × players** |
| Ordered store writes per server per minute | **30 + 5 × players** (write leaderboards rarely) |
| Experience-wide read / write per minute | 300 + 40·CCU / 300 + 20·CCU |
| Value size | ~4 MB per key |
| Total storage | **500 MB + 1 MB × lifetime users** |
| Deleted data store restore window | 30 days |
| MemoryStore item size / expiry | 32 KB / 45 days max |

An 8-player server can make 380 writes a minute, far more than one profile save per player every few minutes needs. Problems only appear when code saves on every coin pickup.

### Security: the server is the only truth

Exploiters can decompile client scripts, fire any RemoteEvent with any arguments at any rate, fire Touched and ProximityPrompt events from any distance, and change their own WalkSpeed ([Security tactics](https://create.roblox.com/docs/scripting/security/security-tactics); [Network ownership](https://create.roblox.com/docs/scripting/security/network-ownership)). The official defences are listed below ([Client-server boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary)), followed by what they mean for a gym or speed simulator *(inference)*:

- **Validate every argument on the server.** Check types with `typeof`, and use `math.isfinite` to reject NaN and infinity. NaN passes "is a number" checks, and in the official example a NaN gold offer slipped past all three checks.
- **Rate-limit per player with a token bucket.**
- **Never trust the client's word.** Never accept "add X strength" from the client; the server computes gains from its own state.
- **Cap train and click remotes** at a human rate (about 10-20 per second).
- **Re-check prices, balance and distance** for eggs and the shop.
- **Re-check rebirth requirements on the server.**
- **Grant developer products only inside `MarketplaceService.ProcessReceipt`.** Record the PurchaseId and return `PurchaseGranted` only after the grant is saved.

Speed hacks matter more for SPEED ARC, because WalkSpeed *is* the stat. Use a soft server check: distance travelled per second over a time window, on the horizontal plane, and rubber-band rather than ban, so laggy kids aren't punished *(inference)*. Roblox's engine-level fix, **Server Authority**, was still in beta in early 2026 and is costly on low-end devices ([DevForum: Server Authority](https://devforum.roblox.com/t/server-authority-how-to-begin/4139185)). Manual checks are the right choice for now. Auto-farm scripts were a widely reported problem in Steal a Brainrot ([Wikipedia](https://en.wikipedia.org/wiki/Steal_a_Brainrot)), which shows passive-income games are prime targets.

---

## 7. Polish is a stack of small, consistent decisions

### Mobile UI that kids can use with thumbs

Keep interactive UI inside the safe area. `ScreenGui.ScreenInsets = CoreUISafeInsets`, the default, keeps buttons clear of the Roblox top bar and phone notches ([On-screen UI containers](https://create.roblox.com/docs/en-us/ui/on-screen-containers)). The touch thumbstick sits bottom-left and the jump button bottom-right, so custom buttons must avoid those zones. Roblox's adaptive-design principles are input fluidity, responsive layout, dynamic sizing and legibility. In practice: collapse lesser buttons into a menu on small screens, show input-specific prompts, avoid thin decorative fonts, and let text grow with the player's text-size preference ([Adaptive design](https://create.roblox.com/docs/en-us/production/publishing/adaptive-design)). The UI/UX doc warns that small screens "can easily get overwhelmed", that games for younger audiences prioritize mobile, and that controls should appear only when relevant ([UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)). Roblox publishes **no numeric minimum touch-target or font size**. General mobile guidelines (about 44-48 pt) are a sensible floor for children's thumbs *(inference, unverified)*.

The proven simulator layout *(inference)*:

- Currency counters top-left or top-centre, below the top bar.
- A vertical column of big icon buttons on the left edge (Shop, Pets, Rebirth, Codes).
- One large contextual action button bottom-right, clear of jump ("LIFT" for GYM ARC, "SPRINT" for SPEED ARC).
- One popup at a time, with rewards queued behind it.
- Large numbers formatted with suffixes (1.23M, not 1234567).

### Looking professional instead of "free model"

Roblox's design rules are specific ([UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)):

- Use vivid colour only for crucial elements, and keep text high-contrast.
- Grey means unusable and red means unaffordable.
- Bigger elements read as more important, so make the best-value bundle larger and set apart.
- Keep the close button in the same place, shape and colour everywhere.
- Write a style guide.

Use **9-slice** images (`ScaleType = Slice`, plus the Studio 9-Slice Editor) for panels and buttons that stretch without distorting ([9-slice](https://create.roblox.com/docs/en-us/ui/9-slice)). For the polished kit *(inference)*, use chunky rounded buttons with thick dark `UIStroke` outlines, a vertical `UIGradient`, one bold rounded display font, icon-first buttons, and one accent colour per currency. Avoid mixing assets from many authors; pick one 5-8 colour palette.

For lighting, `Lighting.LightingStyle` (Realistic or Soft) together with `PrioritizeLightingQuality` now supersedes the old Technology setting ([LightingStyle](https://create.roblox.com/docs/reference/engine/enums/LightingStyle.md)). Lighting looks different on Apple phones, so check it on a real device ([DevForum](https://devforum.roblox.com/t/lighting-issues-on-apple-mobile-devices/3682732)). A stylized "toy" look with Atmosphere haze, a slight saturation lift and mild Bloom reads well on small screens and degrades gracefully on cheap ones *(inference)*.

### Game feel: make every rep and stride feel good

"Juice" is the layer of "little details, little moments of surprise and delight" that makes identical mechanics feel exciting ([roblog summary of "Juice it or lose it"](https://roblog.co.uk/2024/03/juicy-games/)). For simulators *(inference)*:

- **Every action:** floating "+N" popups that rise and fade, coin icons flying to a counter that bumps, and tweened (not snapping) counters.
- **Big moments:** a small camera FOV punch and particles.
- **Egg and reward reveals:** a building wobble, then a flash, then the reveal. Glow, sound and announcements escalate with rarity.
- **Speed in SPEED ARC:** a widening FOV and stronger trail as speed rises, so the stat is something you *feel*.

Keep small feedback small so big moments stay big. Honour `GuiService.ReducedMotionEnabled` by swapping motion for fades ([Accessibility](https://create.roblox.com/docs/en-us/production/publishing/accessibility)).

### Sound

Use only audio you own or that Roblox provides. The Creator Store offers **100,000+ free licensed SFX and music tracks**. Uploads must be under **20 MB and 7 minutes**, and ID-verified users get **2,000 uploads per 30 days** ([Audio assets](https://create.roblox.com/docs/en-us/audio/assets)). Give players separate volume controls for music and effects, and never signal anything with sound alone ([Accessibility](https://create.roblox.com/docs/en-us/production/publishing/accessibility)). Many kids play muted, so every sound cue needs a visual twin *(inference)*. Use upbeat, lyric-free loops that vary by zone, and vary the pitch slightly on repeated sounds to avoid fatigue *(inference)*.

### Accessibility and localization

More than 26% of people have a disability and more than 5% have some colour blindness ([Accessibility](https://create.roblox.com/docs/en-us/production/publishing/accessibility)). Give each rarity a label or icon and border shape, not only a colour. Avoid `TextScaled`, because it ignores players' `PreferredTextSize` setting, and multiply backgrounds by `PreferredTransparency`. **Automatic translation** covers 18 languages and only fills blank entries. In Roblox's June 2025 experiment it raised playtime +0.87% overall and **+4% among new Japanese and Korean speakers**, and payer conversion +0.95% ([DevForum: translation results](https://devforum.roblox.com/t/automatic-translation-experiment-results-and-next-steps/3878129)). It cannot translate text baked into images, so keep words out of button art ([Automatic translations](https://create.roblox.com/docs/en-us/production/localization/automatic-translations)). **Burmese is not among the 18 languages**, though Thai, Vietnamese, Indonesian and Hindi are. Myanmar-language players would need manual translations.

---

## 8. Measure one bottleneck a week, and buy ads only to learn

### What the dashboard gives you, and when

Creator Hub Analytics is free. It covers Overview, Retention, Engagement, Acquisition (including the Home Recommendations signal charts), Demographics, Feedback, Monetization and Explore. Full KPIs unlock after **more than 10 DAU and 10 play-hours for 7 consecutive days**, and benchmarks need **≥100 DAU** ([Analytics dashboard](https://create.roblox.com/docs/en-us/production/analytics/analytics-dashboard)). Event charts take about 24 h, but **"View Events"** shows events in near real time, so you can confirm tracking on day one ([Event types](https://create.roblox.com/docs/en-us/production/analytics/event-types)). The September 2026 update added segmentation by tenure, engagement and spend, plus crash, memory and FPS telemetry **broken down by game version** with real-time alerts ([PocketGamer.biz, 15 Sep 2026](https://www.pocketgamer.biz/roblox-expands-analytics-tools-with-real-time-alerts-and-player-targeting/)). On **12 October 2026** Roblox moved discovery events to a more reliable pipeline. Recorded impressions rose and PTR looks lower from that date, so don't compare across it ([DevForum](https://devforum.roblox.com/t/improved-discovery-measurement-in-creator-analytics/4930122)).

A minimal instrumentation set fits easily within the limits (10 funnels, 100 custom event names, 3 custom fields per event) *(inference based on [Event types](https://create.roblox.com/docs/en-us/production/analytics/event-types))*:

- The onboarding funnel from Section 2.
- One shop funnel (`LogFunnelStepEvent` with a GUID session ID).
- Economy events for the main currency, logged only after a successful transaction.
- Progression events for rebirths and zones.
- A few custom events for key features.

Built-in AnalyticsService is enough. Third-party GameAnalytics adds HTTP calls and privacy exposure, and its docs show maintenance gaps ([GameAnalytics docs](https://docs.gameanalytics.com/event-tracking-and-integrations/sdks-and-collection-api/game-engine-sdks/roblox)).

### A/B testing at small scale

Roblox's **Experiments** run on Configs for 14-60 days, track D1/D7, playtime, ARPU and conversion automatically, and flag early harm. The docs warn that "games with fewer than **1,000 daily active users** may struggle to get useful data" ([Experiments](https://create.roblox.com/docs/en-us/production/experiments)). Test code must use `ConfigService:GetConfigForPlayerAsync(player)`, not `GetConfigAsync()`. Until you have that traffic, the test that works at any scale is **Thumbnail Personalization**. For gameplay changes, compare before and after, one change at a time, same weekday against same weekday. Moving tunable values (rewards, prices, hint delays) into Configs early is cheap and lets you change them live without restarting servers *(inference)*.

### The weekly 30-minute routine *(synthesized from the docs' tools; not an official Roblox checklist)*

1. **Overview/Insights:** DAU, new users and revenue against last week (7-day moving average).
2. **Acquisition > Home Recommendations:** impressions, PTR, first-play bounce, play days and playtime against the benchmark band.
3. **Retention:** D1 and D7 for this week's new cohort against the previous 2-3 cohorts, filtered by source.
4. **Onboarding funnel:** the biggest single drop becomes next week's fix.
5. **Monetization:** payer conversion, ARPDAU, shop-funnel drop and the average currency balance (an inflation check).
6. **Performance by version:** crash rate and memory on mobile.
7. **Thumbnail Performance table.**
8. **Write a three-line log:** what changed, what moved, the next action.

To diagnose a fading spike, check in this order: was the spike organic Home traffic (which counts) or ads and social (which don't)? Did PTR fall and bounce rise in the new cohort? Where did that cohort drop in the funnel? Did D1 and Days 2-7 hold? Did crashes rise in the new version? *(inference, built on [Discovery docs](https://create.roblox.com/docs/en-us/discovery))*.

### Ads, YouTubers and Creator Rewards

**Ads Manager** runs auto-bid sponsored tiles on Home and in Search. You buy credits by card (18+) or by converting Robux (13+). The conversion is **permanent**, the minimum purchase is 1 credit, and earned Robux convert at the US 18+ rate. The first 24 h are a learning period, and reporting lags up to 48 h. Audiences include New, Recent (10,000+ needed) and Lapsed players (20,000+ needed). Ads for games that closely resemble existing games may get "no ad spend and no conversions" ([Ads Manager](https://create.roblox.com/docs/en-us/production/promotion/ads-manager.md)). Ads "do not penalize or downrank your game in RFY", but ad-acquired players don't count toward ranking ([Discovery FAQ](https://create.roblox.com/docs/en-us/discovery-faq.md)). Roblox publishes no cost-per-play benchmarks. A third-party estimate puts cost per visit at **4-12 Robux** and suggests not scaling until D1 is above about 30% and payer conversion above about 5%, testing with 5,000-10,000 Robux ([Rowatcher](https://rowatcher.com/news/roblox-ads-in-2026-the-break-even-math-small-devs-ignore), *low reliability*; its maths uses the old $0.0035 DevEx rate). One experienced DevForum replier told a developer with 2.3% D1 to stop paying for ads entirely ([DevForum](https://devforum.roblox.com/t/suggestions-to-improve-average-session-time-day-1-retention/2935525)).

The right use for a solo developer is **learning, not growth**. Use a small campaign to get onboarding data from real strangers, and the Engagement objective to cross the Kids and Select threshold *(inference)*. Use Experience Betas, or the late-2026 "early testing" for up to 10 friends, to fix onboarding before the public cohort generates signals ([Creator Roadmap 2026: Fall Update](https://devforum.roblox.com/t/creator-roadmap-2026-fall-update/4880208)).

Off-platform, **always share a Share Link, never the plain game URL**. Share Links are tracked, and new or lapsed players who arrive through them and play 10+ minutes earn you Audience Expansion rewards ([Creator Rewards](https://create.roblox.com/docs/en-us/creator-rewards.md)). **Roblox Moments**, a short-video feed with a "Join" button, entered beta on 5 September 2025 ([RDC25](https://devforum.roblox.com/t/rdc25-what-we-announced/3920245)). Dead Rails jumped from hundreds to 600k+ CCU after Roblox's own TikTok featured it and creators such as Flamingo and KreekCraft covered it ([GameAnalytics](https://www.gameanalytics.com/cn/blog/dead-rails-and-the-hit-makers-formula)). YouTube and TikTok restrict under-13 audiences, so reach kids through small Roblox YouTubers. Give them a private server, a boost code and b-roll *(inference)*.

---

## 9. What the 2025 hits teach GYM ARC and SPEED ARC

The 2025 megahits shared a one-line concept readable from a thumbnail (grow plants, steal brainrots, survive the forest), a passive or offline income engine, a social dynamic (gifting, stealing, co-op), and scheduled Saturday events. Grow a Garden went from about 500 CCU to roughly 1M within about a month and peaked at **22.3M CCU** ([GamesBeat](https://gamesbeat.com/janzen-madsen-interview/)). Its maker had built **30-40 games, of which 5-6 were good**, before it. Trends then decay steeply. Grow a Garden's monthly average CCU fell from 90.3k in May 2026 to **19.7k in October 2026** (-78%) despite continued updates ([ROLearn](https://rolearn.dev/case-studies/idle-garden-zero-to-20m-ccu)). Steal a Brainrot fell about 99% from its 25M+ peak ([Rowatcher](https://rowatcher.com/news/is-the-brainrot-trend-dying-what-ccu-data-from-three-top-games-reveals)). A fast "trend + twist" can still hit (Escape Tsunami For Brainrots peaked near 5M in January 2026), while a late plain clone did not (Swing Obby for Brainrots: about 87k). Players "follow the genre more than individual games." Content droughts kill games: Pet Simulator 2 stopped updating one month after release and is remembered as the weakest entry ([Rowatcher](https://rowatcher.com/news/inside-big-games-how-pet-simulator-became-a-100m-roblox-empire)).

For gym and speed simulators, the genre is evergreen rather than trending. Three moves help *(inference)*:

1. **Add the 2025 ingredients.** Offline or passive gains ("your gym trains while you sleep"), a non-toxic social mechanic (spotting a friend's lift for a shared boost, relay races, gifting), and a weekly Saturday event.
2. **Tune rebirth pacing deliberately.** The common formula is geometric, cost = base × rate^rebirths (e.g. 100 × 1.5^r). The permanent multiplier should grow more slowly than the cost, so each rebirth takes a little longer than the last ([DevForum](https://devforum.roblox.com/t/simulator-rebirth-formula/3162074)). Choose the rate so the first rebirth lands *inside* the first session, ideally before minute 10, and later ones fall on return days.
3. **Stage the economy.** Plan tiers and sinks (pet fusion, enchanting, new rarity tiers) ahead of inflation, as Pet Simulator's Huge → Titanic → Gargantuan ladder shows.

Watch rising themes on the Up-and-Coming and Trending charts and on trackers such as rowatcher.com, rotrends.com and rolearn.dev. A theme crossover, such as a seasonal or meme theme layered onto your existing gym or track systems, is a cheap way to ride a trend without starting a new game. If a game reaches a few hundred to 1k CCU organically, studios such as Splitting Point and DoBig have shown they will partner. That is a realistic route to scale for a solo creator ([GameDiscoverCo](https://newsletter.gamediscover.co/p/what-grow-a-gardens-89-million-ccu)).

---

## Action checklists

### A. Before (re)launching a game

- [ ] Creator account: age-checked, ID-verified, **2-Step Verification** on, email verified
- [ ] **Full** Maturity & Compliance Questionnaire done; target **Minimal/Mild**; no "hangout" wording; no free-text drawing or sign features
- [ ] Kids and Select: pay the refundable fee (or hold Premium/Plus for 2 months); watch the **Audience Reach** tab
- [ ] Custom thumbnail(s) at 1920×1080, honest to gameplay, nothing important along the bottom; 3-5 distinct concepts active
- [ ] 15-30 s gameplay video thumbnail (3 free per month)
- [ ] Title = brand word + genre nouns; first description sentence plain and keyword-rich; no "free", "giveaway" or Robux claims
- [ ] Onboarding funnel events (Section 2 table) logged from the server; confirmed in **View Events**
- [ ] Tested on a real low-end phone: join time, FPS, no crash
- [ ] Streaming on, Opportunistic stream-out; no partial transparency; textures ≤512 px
- [ ] ProfileStore for player data; save on leave, on shutdown and after purchases
- [ ] All remotes validated (type, `math.isfinite`, range, distance) and rate-limited
- [ ] ProcessReceipt grants products idempotently, only after saving
- [ ] Prices in UI read from `MarketplaceService`, never typed in
- [ ] Odds table with %s on every egg; luck boosts shown numerically; PolicyService checks for restricted users
- [ ] Any player-named thing filtered server-side, or replaced by preset pickers
- [ ] No links, Discord mentions or QR codes anywhere in-game
- [ ] Separate music and SFX volume; visual twin for every sound cue
- [ ] Automatic translation enabled; no text baked into images

### B. First-session (0-10 minutes) design checks

- [ ] First action possible within ~10 s of spawning, shown by glow/arrow, not text
- [ ] Timed hint appears ~11 s only if the player hasn't acted; shown once
- [ ] Visible "+N" feedback on the very first lift or stride
- [ ] Physical shop or upgrade visible from spawn ("what I'm working toward")
- [ ] First upgrade affordable within ~1-2 minutes; first pet within ~5 minutes *(inference)*
- [ ] Playtime gifts at 5 and 10 minutes; first rebirth reachable in session one *(inference)*
- [ ] Starter pack offered calmly ("View Item"), not on the first screen

### C. Retention and live ops

- [ ] Daily streak calendar plus daily and weekly quests
- [ ] Offline/passive gains on return
- [ ] Friend boost, two-sided referral rewards (banner set in Creator Hub), cheap private servers, co-op goal
- [ ] Notification opt-in prompted at a happy moment (13+ only); event-driven messages; no fake urgency
- [ ] Fixed weekly event time (Saturday) with a truthful countdown
- [ ] Content drop every 2 weeks per game (alternate the two games); new thumbnails each major update
- [ ] In-game "What's New" board, codes in-game and in the description, Community group shouts

### D. Weekly (30 min) - see Section 8 routine

- [ ] Home Recommendations signals against benchmark
- [ ] New-cohort D1/D7 by source
- [ ] Biggest funnel drop identified → this week's single fix
- [ ] Crash/memory by version
- [ ] Three-line log written

### E. Tasks to hand to Claude Code (plain-language prompts) *(inference)*

- "Add onboarding funnel events for these 8 steps, logged from the server, and show me how to check them in View Events."
- "Audit every RemoteEvent: add type, NaN/inf, range and distance checks and a per-player rate limit."
- "Switch player data to ProfileStore with a schema version, and make ProcessReceipt idempotent."
- "Find every hard-coded Robux price in the UI and replace it with MarketplaceService:GetProductInfo."
- "List all parts with partial transparency, CastShadow on small parts, Precise fidelity and textures over 512 px."
- "Add an odds panel to each egg that updates when luck boosts are active, plus PolicyService handling."
- "Make all reward popups respect ReducedMotionEnabled, and remove TextScaled in favour of AutomaticSize."

---

## Numbers to remember

| Area | Number | Source |
|---|---|---|
| Home share of traffic | **>90%** | [2025 Discovery Roadmap](https://devforum.roblox.com/t/roblox%E2%80%99s-2025-discovery-roadmap-and-ways-to-reach-and-engage-your-audience/3557533) |
| RFY lookback window | **28 days** (since 15 Jun 2026) | [DevForum](https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575) |
| Bounce buckets | <60 s and 61-180 s | [Discovery](https://create.roblox.com/docs/discovery) |
| Playtime cap in ranking | 60 min/user/day | same |
| Friends' sessions vs solo | **1.9× longer** | [DevForum: Party](https://devforum.roblox.com/t/party-is-here-unlock-a-new-level-of-engagement/3282068) |
| Thumbnail personalization lift | +8.5% avg, up to +50% | [Thumbnails](https://create.roblox.com/docs/en-us/production/publishing/thumbnails.md) |
| Simulator D1/D7/D30 (vendor) | 32% / 14% / 6.2% | [BLOXG](https://bloxg.com/statistics/roblox-retention-benchmarks) |
| Floor rule of thumb | ≥10% D1, ≥8 min session | [DevForum](https://devforum.roblox.com/t/suggestions-to-improve-average-session-time-day-1-retention/2935525) |
| Creator Rewards session minimum | 10 min | [Creator Rewards](https://create.roblox.com/docs/creator-rewards) |
| In-game sales share | 70% | [Earn on Roblox](https://create.roblox.com/docs/production/earn-on-roblox) |
| DevEx rate | $0.0038/Robux; min 30,000 | [DevEx](https://create.roblox.com/docs/de-de/production/monetization/developer-exchange) |
| Daily Engagement reward | 5 Robux/Active Spender/day; 60-day hold | [DevForum](https://devforum.roblox.com/t/introducing-creator-rewards-earn-more-by-growing-the-community/3777628) |
| Audience Expansion | 35% of first $100 over 60 days; 100+ DAU | [Creator Rewards](https://create.roblox.com/docs/en-us/creator-rewards.md) |
| Rewarded ads eligibility | 2,000+ monthly visitors; viewers 13+ | [Rewarded video ads](https://create.roblox.com/docs/production/promotion/rewarded-video-ads) |
| Price optimization eligibility | ~60,000 transactions/30 days | [Price optimization](https://create.roblox.com/docs/en-us/production/monetization/price-optimization) |
| Notifications | 13+, 1/day/game, 99 chars, 100+ visits | [Notifications](https://create.roblox.com/docs/production/promotion/experience-notifications.md) |
| Social links visible to | age-checked 16+ (since 30 Jun 2026) | [DevForum](https://devforum.roblox.com/t/roblox-kids-and-select-global-launch-upcoming-updates-to-eligibility-ads-manager-and-expedited-review/4685717) |
| Experiments useful above | ~1,000 DAU | [Experiments](https://create.roblox.com/docs/en-us/production/experiments) |
| Analytics unlock | >10 DAU and 10 play-hours for 7 days; benchmarks ≥100 DAU | [Analytics dashboard](https://create.roblox.com/docs/en-us/production/analytics/analytics-dashboard) |
| Performance targets | ~1,000 draw calls, ~1M triangles, 16.67 ms frame | [Design for performance](https://create.roblox.com/docs/performance-optimization/design) |
| Data store writes per server | 60 + 40 × players per minute | [Limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits) |
| Audio upload | <20 MB, <7 min; 2,000 per 30 days (ID-verified) | [Audio assets](https://create.roblox.com/docs/en-us/audio/assets) |
| Median DevEx creator | ~$1,500/yr | [Dexerto](https://www.dexerto.com/roblox/robloxs-top-creators-average-65-7-million-a-year-but-most-make-far-less-3408675/) |

## Conflicts and unknowns to check yourself

- **Purchase hold:** 30-day escrow (Monetization page) vs about 5 days (Subscriptions page). Check Creator Hub > Finance.
- **Kids and Select threshold:** 250 engaged plays (docs) vs 500 Highly Engaged Players (DevForum, with cuts announced). Expedited review costs 50,000 vs 100,000 Robux. Check Audience Reach.
- **Managed Pricing notice period:** 7 days vs up to 30 days.
- **Not published by Roblox:** RFY signal weights, PTR or session benchmarks outside your own dashboard, Ads cost-per-play, chart criteria, minimum touch-target or font sizes, and any evidence that "[UPD]" tags or emojis help.
- **Still to come (late 2026):** name checks, promotional update text, passes shown on Home before joining, the Home redesign, and developer push notifications. Re-check the Creator Roadmap each quarter.

## Conclusion

The 2026 rules shift the solo developer's advantage away from marketing and toward care. Per-user averaging means a 200-player game with devoted kids can out-signal a 20,000-player game with a clickbait thumbnail. The 28-day window means a modest Saturday ritual, offline gains and a friend boost now outrank any launch-day trick. The tension specific to GYM ARC and SPEED ARC is that the gate to their real audience runs through a 16+ trial. The first version has to retain teenagers well enough to *earn* access to the 8-14 players it is designed for, and early analytics will describe a different crowd than the eventual one. Read early data as a check on onboarding and stability rather than on the kids' taste.

The single highest-return habit is therefore not a feature but a loop: instrument the first 10 minutes, fix the one biggest drop each week, ship a small truthful update every fortnight, and keep the economy honest enough that a parent or journalist reading the shop would find nothing to object to. Hits on Roblox come disproportionately from people who ran that loop on many cheap games. Grow a Garden's operator had shipped 30-40 games before it. Two well-instrumented simulators that improve weekly are a better position than one perfect launch.
