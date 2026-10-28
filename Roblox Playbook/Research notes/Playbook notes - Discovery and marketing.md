# Roblox Discovery and Marketing (2025-2026): How Players Find Games and How to Pull Every Lever

Context: written 2026-10-28 for a solo developer making kids' simulator games (ages 8-14, mostly mobile). Primary sources are Roblox Creator Hub docs, DevForum staff announcements and the Roblox newsroom. Third-party blogs (rowatcher.com etc.) are flagged as lower reliability. Several of them look like content-farm or AI-written sites.

## 1. How the Home / Recommended For You (RFY) system works, and charts

### Takeaway
Home is where over 90% of Roblox traffic starts. Its "Recommended For You" algorithm has two stages: retrieval, then personalized ranking. Since 15 June 2026 it ranks games on organic-only, per-user-averaged signals over a 28-day window: play-through rate, first-play bounce, play days and playtime (Day 1 / Days 2-7 / Days 8-28), co-play with friends, qualified sessions and spend. Long-term retention is now explicitly the target. "Qualified play-through rate" (qPTR) was removed as a ranking signal. Roblox tests games continuously in explore/expand cycles, and new games start getting tested immediately. Charts are a separate surface, and Roblox does not publish the criteria for getting onto them.

### Cited Findings
**Scale and importance of Home**
- Home is where "over 90% of platform traffic begins". Discovery served over 10.5 billion impressions per day, up from 7.5 billion a year earlier (post dated 19 Mar 2025). — [DevForum: 2025 Discovery Roadmap](https://devforum.roblox.com/t/roblox%E2%80%99s-2025-discovery-roadmap-and-ways-to-reach-and-engage-your-audience/3557533)
- Roblox had 132M DAU (Q1 2026). — [Roblox Newsroom, "Optimizing Discovery", 15 Jun 2026](https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox). It had 111.8M DAU, +41% YoY, in Q2 2025. — [RDC25: What we announced](https://devforum.roblox.com/t/rdc25-what-we-announced/3920245)

**Two-stage system**
- Retrieval picks candidate games using signals such as engagement, retention and monetization. Ranking then personalizes the order. — [Creator Hub: Discovery](https://create.roblox.com/docs/discovery)
- Only organic RFY users count in ranking. "Roblox doesn't count the engagement, monetization, or retention of users first acquired from ads, curation" and other sources. — [Creator Hub: Discovery](https://create.roblox.com/docs/discovery)
- Other sources still help a game get retrieved and considered: sponsored ads, curation, search, charts, friends, teleports, notifications and social sharing. "Even a few players can signal that a game is worth wider distribution." — [Creator Hub: Discovery](https://create.roblox.com/docs/discovery)

**Current signals, from the Creator Hub, in priority order (post-June 2026)**
- Most important:
  - **Play-through rate (PTR)**: how often users play after seeing the game in RFY.
  - **First-play bounce rate** (a negative signal): sessions under 60s, and sessions of 61-180s.
  - **Play days per user** and **playtime per user**, each measured for Day 1, Days 2-7 and Days 8-28. Playtime is capped at 60 min per user per game per day.
  - [Creator Hub: Discovery](https://create.roblox.com/docs/discovery)
- Important:
  - **Intentional co-play days per user**: days a user returns to play with friends through a join, an invite or a private server.
  - **Qualified play sessions per user**.
  - **Spend days per user** and **Robux spent per user**.
  - [Creator Hub: Discovery](https://create.roblox.com/docs/discovery)
- All signals are averaged per user, not totalled, so "smaller games with highly engaged users are not disadvantaged." Roblox publishes no numeric thresholds or weights on the docs page. — [Creator Hub: Discovery](https://create.roblox.com/docs/discovery)

**The 15 June 2026 algorithm change**
- The lookback window grew from 7 to 28 days.
- Roblox removed qualified play-through rate and added PTR plus first-play bounce rates.
- Roblox published the relative importance of each signal, as a chart image (the actual values could not be extracted).
- Thumbnail personalization will now be tested against PTR.
- [DevForum: RFY Algorithm Improvements That Better Value Long-Term Retention, 15 Jun 2026](https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575)
- Roblox's stated rationale: under the old system "the system could disproportionately favor games that win attention with exciting thumbnails", and those games "were displacing games that players value for the long term". In testing, the new algorithm "did a significantly better job surfacing games that retain players over time". — [Roblox Newsroom, John Ciancutti (Chief Growth Officer), 15 Jun 2026](https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox)
- DevForum commenters worried that 28-day signals would slow feedback for new games. Roblox's FAQ answers this:
  - "New games do not have to wait 28 days before Home can recommend them."
  - Signals arrive in stages: first-session PTR and bounce first, then Day 1, then Days 2-7, then Days 8-28.
  - "Early signals kick in immediately."
  - [Creator Hub: Discovery FAQ](https://create.roblox.com/docs/en-us/discovery-faq.md)

**Testing of new and updated games (explore/expand)**
- An update can bring a spike of new users ("explore"). If that cohort engages and spends well, Roblox is "more likely to continue to recommend your game to more such user cohorts" ("expand"). The game then settles at a new baseline. "A temporary drop in play through rate when your impressions increase" is normal. — [Creator Hub: Discovery](https://create.roblox.com/docs/discovery)
- The algorithm tests games daily, so old games can recover. There is "no penalty" for a weak start: fix onboarding and Roblox keeps testing with new users. — [Discovery FAQ](https://create.roblox.com/docs/en-us/discovery-faq.md)
- Impressions also depend on Roblox's own algorithm changes and on total Home traffic. Traffic peaks on Saturdays and has summer, back-to-school and holiday seasonality. Better-engaging competitors can also take your distribution. — [Creator Hub: Discovery](https://create.roblox.com/docs/discovery)

**Things that get a game limited**
- A custom thumbnail is required: "A custom thumbnail is required for your game to receive impressions from homepage recommendations." — [Creator Hub: Discovery](https://create.roblox.com/docs/discovery)
- Roblox deprioritizes:
  - Titles that lead with giveaways or imply monetary rewards.
  - Titles or thumbnails that don't match the gameplay (these also get less search visibility).
  - Near-copies of existing games.
  - Roblox reassesses quality on every update, and the Creator Dashboard shows a daily-updated "reduced exposure" banner.
  - [Creator Hub: Discovery](https://create.roblox.com/docs/discovery)
- Among near-identical games, Roblox favours the one that first added the unique metadata or place file, not the one created first. — [Discovery FAQ](https://create.roblox.com/docs/en-us/discovery-faq.md)
- Roadmap item for late 2026: "Deceptive game copy takedowns" against games that copy another game's title or thumbnail. Also "Name checks" to protect game names from copycats. — [Creator Roadmap 2026: Fall Update, 18 Sep 2026](https://devforum.roblox.com/t/creator-roadmap-2026-fall-update/4880208)

**Analytics and measurement**
- Signals and benchmarks against similar games are under Analytics > Acquisition > Home Recommendations. Benchmarks "do not impact the recommendation algorithm." — [Discovery FAQ](https://create.roblox.com/docs/en-us/discovery-faq.md)
- On 12 Oct 2026 Roblox moved impression, click and play events from Home, Search and Charts to "a more reliable delivery pipeline". Recorded counts are higher, and PTR will look slightly lower. Data from before 12 Oct is not restated, so compare before/after periods separately. The change does not affect RFY ranking. Unverified forum reports describe 26-40% PTR drops. — [DevForum: Improved Discovery Measurement in Creator Analytics, 12 Oct 2026](https://devforum.roblox.com/t/improved-discovery-measurement-in-creator-analytics/4930122)

**Other Home sorts**
- Home sorts include:
  - Continue Playing
  - Friends
  - Sponsored
  - Curated sorts
  - Standout Games (hand-curated novel games)
  - Live Events (limited-time events with quests)
  - [Creator Hub: Discovery](https://create.roblox.com/docs/discovery)
- Dynamic ranking for "People You May Know" and "Continue" launched in Jan 2025. A "Recommended Paid Access Experiences" sort was announced in Mar 2025. — [2025 Discovery Roadmap](https://devforum.roblox.com/t/roblox%E2%80%99s-2025-discovery-roadmap-and-ways-to-reach-and-engage-your-audience/3557533)
- The Fall 2026 roadmap lists four items:
  - A better "Continue Playing" order (shipped).
  - Showing passes and developer products on Home before players join (late 2026).
  - "Promotional text for updates" (late 2026).
  - A Home UI redesign, delayed to late 2026.
  - [Creator Roadmap 2026: Fall Update](https://devforum.roblox.com/t/creator-roadmap-2026-fall-update/4880208)

**Charts (Discover tab)**
- "Top Playing Now" is ranked by real-time concurrent users (CCU). It launched globally on 5 Mar 2025. — [DevForum: Introducing "Top Playing Now" on Charts](https://devforum.roblox.com/t/introducing-top-playing-now-on-charts/3529809)
- Roblox added genre filters and console/VR support to Top Charts, and promised event sorts (Mar 2025). — [2025 Discovery Roadmap](https://devforum.roblox.com/t/roblox%E2%80%99s-2025-discovery-roadmap-and-ways-to-reach-and-engage-your-audience/3557533)
- The public charts page has country and device filters, e.g. `?country=us&device=computer`. — [roblox.com/charts](https://www.roblox.com/charts)
- No official criteria are published for the other charts: Up-and-Coming, Top Trending, Top Earning, Top Rated, Fun with Friends and so on. The Discovery doc only says charts showcase "top-performing content". — [Creator Hub: Discovery](https://create.roblox.com/docs/discovery)
- One DevForum commenter (not staff) claims Up-and-Coming featured games with roughly 10K to 200K+ CCU. — [DevForum comment thread](https://devforum.roblox.com/t/introducing-top-playing-now-on-charts/3529809)

### Inferences
- For a kids' simulator, the levers that matter most now:
  1. **Onboarding in the first 60-180 s**, to cut first-play bounce. On mobile, load time and crashes on low-RAM devices count here too.
  2. **Reasons to come back on Days 2-28**: daily rewards, rebirth or progression arcs, weekly updates and events.
  3. **Friend co-play**: invite rewards, friend boosts, private servers.
  4. **Spend days**: small, frequent purchases may help more than rare large ones, because the signal counts spend days and not only total Robux.
- Clickbait thumbnails were a winning tactic in the 7-day era. They now backfire, because a high PTR followed by a high bounce rate counts against the game.
- Charts mainly reward games that already have high CCU or revenue. For a small game they are a result of success, not a lever you can pull directly.
- Avoid copying a popular simulator's name or thumbnail closely. Near-copy deprioritization is in place now, and takedowns are coming in late 2026.

### Gaps
- The numeric signal weights exist only as an image in the 15 Jun 2026 DevForum post and could not be extracted.
- No official eligibility criteria or thresholds were found for Up-and-Coming, Top Trending or Top Earning.
- No official PTR or retention benchmarks are published. Benchmarks appear only inside each game's own analytics.
- The RDC 2025 talk content on discovery was not found as a text transcript.

## 2. Search: ranking, titles, descriptions, name changes and update tags

### Takeaway
Roblox publishes almost nothing about how search ranks games. Historically it matched exact queries against titles. It now also supports semantic, natural-language search ("food games") in all supported languages. Accurate, descriptive metadata is the only official advice. Misleading titles reduce search visibility. A promotional-text field for updates is coming, which may reduce the need for "[UPD]" tags in titles.

### Cited Findings
- Search "historically" relied on exact queries and titles. Semantic search now supports natural-language queries in all officially supported languages. Roblox does not publish ranking details. — [Creator Hub: Discovery](https://create.roblox.com/docs/discovery)
- Search now blends experiences, avatars, people and more. Genre discovery is expanding, and a "Recently Visited" section launched in search. Creators are told to keep metadata "accurate and detailed" (Mar 2025). — [2025 Discovery Roadmap](https://devforum.roblox.com/t/roblox%E2%80%99s-2025-discovery-roadmap-and-ways-to-reach-and-engage-your-audience/3557533)
- Mismatched titles or thumbnails make a game "less recommended and less visible in search". Titles that lead with giveaways are deprioritized. — [Creator Hub: Discovery](https://create.roblox.com/docs/discovery)
- Users read genre tags and descriptions before playing. Inaccurate metadata causes bounces, which hurt the game's signals. — [Discovery FAQ](https://create.roblox.com/docs/en-us/discovery-faq.md)
- Search is also a Creator Rewards attribution path. A user who searches your game's name as their first session of the day and plays 10+ minutes can earn you Audience Expansion rewards. — [Creator Hub: Creator Rewards](https://create.roblox.com/docs/en-us/creator-rewards.md)
- Fall 2026 roadmap items:
  - "Name checks & promotional text": protects names from copycats and adds promotional text for updates (late 2026).
  - Search landing page, delayed to late 2026.
  - Dynamic filters, delayed to late 2026.
  - [Creator Roadmap 2026: Fall Update](https://devforum.roblox.com/t/creator-roadmap-2026-fall-update/4880208)
- Ads Manager supports sponsored placement in search results. "Search advertising improvements" were promised at RDC 2025. — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager.md); [RDC25: What we announced](https://devforum.roblox.com/t/rdc25-what-we-announced/3920245)

### Inferences
- Put the core genre noun kids actually type into the title, e.g. "Pet", "Simulator", "Gym", "Speed", "Run". Semantic search also reads descriptions, so a clear first sentence of the description helps.
- A short, unique brand word is useful as well. It makes "search by name" attribution work for Creator Rewards and protects against copycats once name checks ship.
- "[UPD]" and emoji prefixes are a common convention, but no official source says they affect ranking. Once the promotional-text field ships, use it instead of cluttering the title.

### Gaps
- No primary source on the effect of renaming a game, or of emojis or [UPD] tags, on search rank. The DevForum threads found ([Roblox Search Optimization](https://devforum.roblox.com/t/roblox-search-optimization/386172), [Do game titles matter](https://devforum.roblox.com/t/do-game-titles-matter/2488068)) are older community opinion and were not reviewed in depth.
- No data on what share of plays comes from search versus Home for typical games.

## 3. Icons, thumbnails, personalization (A/B testing) and video

### Takeaway
Thumbnails are 16:9 at 1920×1080. You can show up to 10 images or videos, plus 3 free video uploads per month. Thumbnail Personalization serves 2-5 active thumbnails to different user segments. In testing it raised qualified play-through by +8.5% on average, and up to +50% for some games. Since June 2026 thumbnails are judged against PTR together with retention, so the thumbnail must accurately show the game.

### Cited Findings
**Specs**
- Images should be 16:9 and ideally 1920×1080, in .jpg, .gif, .png, .tga or .bmp. Personalization uploads must be under 3 MB.
- Up to 10 images or videos can go on the details page.
- Don't put essential text at the bottom: the player-count overlay covers it.
- Use colour to signal the theme, e.g. bright for comedic games.
- [Creator Hub: Thumbnails](https://create.roblox.com/docs/en-us/production/publishing/thumbnails.md)

**Video thumbnails**
- 3 free uploads per month. Rejected videos still count against the quota.
- An approved video shows first on the details page "and can also appear on the Home page".
- Video thumbnails are not supported on Xbox, PlayStation or VR.
- Not allowed:
  - Features the game doesn't have
  - Enhanced graphics
  - Real-life footage
  - Voice-over or narration
  - Music with lyrics
  - Promotional claims
- Free camera for recording: Left Shift + P during a solo playtest.
- [Creator Hub: Thumbnails](https://create.roblox.com/docs/en-us/production/publishing/thumbnails.md)
- "Video preview analytics" was delayed to late 2026. — [Creator Roadmap 2026: Fall Update](https://devforum.roblox.com/t/creator-roadmap-2026-fall-update/4880208)

**Thumbnail Personalization**
- It starts when 2 or more thumbnails are active (2-5 allowed). Each thumbnail is shown to random users per user group. The winner in each group then gets more impressions, while the others keep minimal traffic.
- In testing, games "had an average increase of +8.5%" in qualified play-through rate, and some saw "+50%".
- Metrics:
  - Impressions
  - Qualified plays
  - Average playtime per qualified play
  - Qualified PTR
  - Winning segment
- Advice: don't pick a single winner early. Test several new thumbnails with each major update, then hold them steady.
- [Creator Hub: Thumbnails](https://create.roblox.com/docs/en-us/production/publishing/thumbnails.md)
- Keep variations active for at least 7 days between changes. Show new content, test visually distinct concepts, and expect temporary qPTR dips after Home surges. — [2025 Discovery Roadmap](https://devforum.roblox.com/t/roblox%E2%80%99s-2025-discovery-roadmap-and-ways-to-reach-and-engage-your-audience/3557533)
- Personalization now remembers your existing winning thumbnails. — [DevForum: Thumbnail personalization now remembers your existing winning thumbnails](https://devforum.roblox.com/t/thumbnail-personalization-now-remembers-your-existing-winning-thumbnails/3793665) (title only, not fetched)
- Since 15 Jun 2026, personalization is tested against PTR rather than qPTR. — [DevForum RFY change](https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575)
- You can switch back to old icons or thumbnails. "Reusing an existing thumbnail alone shouldn't negatively affect discoverability." — [Discovery FAQ](https://create.roblox.com/docs/en-us/discovery-faq.md)
- Sponsored ads take up to 10 of their own 16:9 thumbnails per campaign, and Ads Manager can AI-generate 3 variations per description. — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager.md)
- An icon A/B testing feature request exists on the DevForum. — [DevForum: Icon A/B Testing](https://devforum.roblox.com/t/icon-ab-testing/3274267) (not fetched; no confirmation of an official icon-testing tool)

### Inferences
- For kids on mobile, tiles are small:
  - Use one big, readable focal subject: an avatar or character showing exaggerated emotion, plus the "power fantasy" object (huge muscles, a speed trail).
  - Use high-contrast saturated colours and at most 2-3 large words.
  - Keep the bottom strip clear for the player-count overlay.
- Always run 3-5 genuinely different concepts with personalization, and refresh them with each major update.
- A 15-30 s gameplay video is free and can appear on Home, so make one for each major update.

### Gaps
- No official click-through or PTR benchmarks by genre were found. Third-party pages making such claims (e.g. [rowatcher.com thumbnail A/B article](https://rowatcher.com/news/roblox-thumbnail-a-b-testing-what-the-data-actually-shows)) were not verified and are low reliability.
- The icon specification page (512×512 is the long-standing convention) was not fetched in this session.
- No official icon A/B testing tool was confirmed.

## 4. Sponsored ads / Ads Manager and rewarded video ads

### Takeaway
Ads Manager runs auto-bid sponsored tiles on Home and in Search. You pay with ad credits, which you buy by card (18+ only) or by irreversibly converting earned Robux. The minimum purchase is 1 credit. Ad-acquired players don't feed RFY ranking signals, but they don't hurt them either, and they can help a game get retrieved. Roblox publishes no cost-per-play benchmarks. Third-party estimates (low reliability) put cost per visit at about 4-12 Robux. Rewarded video ads are a monetization tool, not an acquisition one: they need 2,000+ monthly unique visitors and only serve players aged 13+.

### Cited Findings
**Ads Manager mechanics** — [Creator Hub: Ads Manager](https://create.roblox.com/docs/en-us/production/promotion/ads-manager.md)
- **Placement and creatives:** sponsored tiles on Home and in search, with up to 10 thumbnails at 16:9.
- **Bidding:** auto-bid from your budget and duration. Cost per play (CPP) = spend ÷ plays.
- **Goals:** Plays, Earnings (limited availability) and Engagement. Engagement usually has a higher CPP.
- **Audiences:**
  - All Players
  - New Players (never played, or not in 180+ days)
  - Recent Players (requires 10,000+ recent players)
  - Lapsed Players (requires 20,000+)
- **Advanced targeting:** location, age, gender, genre and device.
- **Payment:**
  - Ads Manager requires age 13+. A card requires 18+. Robux conversion is open to 13+.
  - Converting Robux to ad credit is "permanent and irreversible", and earned Robux convert at the US 18+ exchange rate.
  - Minimum purchase is 1 ad credit. Unused credits are returned when the campaign ends.
  - Card charges happen at a threshold (e.g. $100) or monthly. First-time card users pay $5 up front.
- **Timing:**
  - The learning period is the first 24 h.
  - Most campaigns need several days. For the Engagement goal, if nothing improves in 3-5 days, fix onboarding.
  - Campaign moderation takes up to 24 h, and assets up to 48 h.
  - Reporting lags up to 48 h and includes plays and earnings up to 30 days after an ad is served.
- **Uniqueness:** ads for games that closely resemble existing games may see "no ad spend and no conversions".
- **Refunds:** invalid-traffic refunds are applied 16 days after the campaign ends.

**Interaction with RFY** — [Discovery FAQ](https://create.roblox.com/docs/en-us/discovery-faq.md); [Creator Hub: Discovery](https://create.roblox.com/docs/discovery)
- "Ads do not penalize or downrank your game in RFY."
- Engagement from ad-acquired users is excluded from RFY signals. Those users generally won't later see the game via RFY, so organic impressions can dip while total acquisition rises.
- Example: 10K daily RFY players plus 5K from ads = 15K total, and Home traffic stays steady.
- Ads are listed as a "retrieval booster" that can get a game considered for RFY.

**Roadmap**
- Ads Manager shipped 40+ improvements in 2025.
- A "Maximize Spend" objective (targets users likely to spend time and money) was announced for early 2026.
- Enhanced reporting and search-ad improvements were promised.
- [RDC25: What we announced](https://devforum.roblox.com/t/rdc25-what-we-announced/3920245)

**Small-dev economics (third-party, low reliability)**
- An estimated cost per visit of about 4-12 Robux, with obby and tycoon at the high end. This is attributed vaguely to "DevForum estimates".
- Example break-even: at 7 Robux per visit, a 2% payer rate needs 350 Robux ARPPU to break even.
- Suggested test budget: 5,000-10,000 Robux.
- Rules of thumb: below about 5% payer conversion ads are likely unprofitable, and D1 retention should be above 30% before scaling.
- All of these are the author's heuristics, not data. — [rowatcher.com: Roblox Ads in 2026: The Break-Even Math](https://rowatcher.com/news/roblox-ads-in-2026-the-break-even-math-small-devs-ignore)
- Related articles (not fetched): [Is Roblox Advertising Worth It for Games Under 1K Daily Players?](https://rowatcher.com/news/is-roblox-advertising-worth-it-for-games-under-1k-daily-players), [Ad Spend Under $500 Will Wreck Your Analytics](https://rowatcher.com/news/roblox-ad-spend-under-500-will-wreck-your-analytics). DevForum threads: [Game launch advertising cost](https://devforum.roblox.com/t/game-launch-advertising-cost/3667546), [Need advice on my game's ad performance](https://devforum.roblox.com/t/need-advice-on-my-games-ad-performance-and-next-steps/4760265).

**Rewarded video ads (monetization)**
- **Publisher requirements:** age 13+, 2FA and ID verification.
- **Game requirements:** public and unrestricted, no free-form user creation, an approved Maturity and Compliance Questionnaire, and an average of 2,000+ unique visitors per month.
- **Ad format:** ads run 6-30 s. Earnings = EPM × impressions.
- **Rewards:** about 3-10 Robux worth of reward is recommended. The reward must be a developer product, granted when the ad finishes, and cannot be randomized.
- **Restrictions:** ads cannot gate progress.
- **Placement advice:** lobbies, menus, or natural breaks such as "Watch this ad for 2x the coins!"
- [Creator Hub: Rewarded video ads](https://create.roblox.com/docs/production/promotion/rewarded-video-ads)
- Rewarded video ads launched in 2025 with Google as a partner (Apr 2025), and access was expanded to more creators. — [Roblox newsroom, Apr 2025](https://about.roblox.com/newsroom/2025/04/roblox-scales-video-ads-partners-with-google); [DevForum: More Creators Can Now Use Rewarded Video Ads](https://devforum.roblox.com/t/more-creators-can-now-use-rewarded-video-ads/3838678) (titles only)

### Inferences
- The most useful role of ads for a small dev is the "explore" phase: buying a few hundred to a few thousand plays to generate early signals and get retrieved by RFY. Don't use ads as a permanent growth engine.
- Check onboarding first, with a small budget. If ad-driven players bounce, more spend won't help.
- Target by device (phone/tablet) and age bands that fit the game. Note that Ads Manager docs don't describe special restrictions for under-13 audiences.
- Rewarded video earnings only come from players aged 13+, so they will be small in an 8-14 audience. Don't design the economy around them.

### Gaps
- Roblox publishes no official CPP or CPM benchmarks, and no USD price per ad credit appeared in the docs fetched.
- No verified postmortems with real campaign numbers from kids' simulator developers were found.
- Whether ads can target or be shown to users under 13 is not stated in the Ads Manager doc.

## 5. Off-platform marketing: YouTube/TikTok, Creator Rewards, Discord, community

### Takeaway
Creator Rewards launched 24 Jul 2025 and replaced Engagement-Based Payouts and the Creator Affiliate program. It pays you for bringing new or lapsed users to Roblox through Share Links, direct links, or name searches: a 35% share of their first $100 of spend over 60 days. That makes off-platform promotion (YouTube, TikTok, Discord) directly paid. Roblox Moments, a short-form video feed with a "Join" button that entered beta in Sep 2025, is a new on-platform video discovery channel.

### Cited Findings
**Creator Rewards** — [Creator Hub: Creator Rewards](https://create.roblox.com/docs/en-us/creator-rewards.md)
- **Daily Engagement reward:** 5 Robux per qualifying "Active Spender" per day. An Active Spender has spent $9.99+ in the last 60 days, played 10+ min in your game, and your game was among their first 3 launches that day.
- **Audience Expansion reward:** a 35% revenue share on the first $100 of qualifying purchases anywhere on Roblox during a new or reactivated user's first 60 days.
- **Attribution paths:**
  - A Share Link click plus 10+ min of play.
  - A direct link, or a search for your game's name, as the first session of the day with 10+ min of play.
- **Conditions:** the experience must average 100+ DAU for the 60 days after the join, and the owner must be ID-verified.
- **Analytics:** a Share Links tab shows clicks, signups, reactivations, spend and estimated payout.
- **Payout:** earned Robux carry a 60-day hold.

**Launch results and program changes**
- 73% of eligible experiences earned more under Creator Rewards than under engagement-based payouts (7/24-8/24/2025). The number of creators earning 5+ Robux rose 171%. — [RDC25: What we announced](https://devforum.roblox.com/t/rdc25-what-we-announced/3920245); [DevForum: Introducing Creator Rewards](https://devforum.roblox.com/t/introducing-creator-rewards-earn-more-by-growing-the-community/3777628)
- The Creator Affiliate program (an older pilot that paid for referring new users) is discontinued and folded into Creator Rewards. — [Creator Rewards](https://create.roblox.com/docs/en-us/creator-rewards.md); [old Creator Affiliate doc](https://create.roblox.com/docs/creator-programs/creator-affiliate)
- "Video Stars" members, Roblox's influencer program, can earn both reward types and see "active spender visits". — [Creator Rewards](https://create.roblox.com/docs/en-us/creator-rewards.md); [Roblox influencer program requirements](https://influencers.roblox.com/requirements) (not fetched)

**Share Link API and Moments**
- A Share Link API lets you deep-link players directly into specific places or moments in the game. — [DevForum: Introducing the Share Link API](https://devforum.roblox.com/t/introducing-the-share-link-api-deep-link-players-directly-into-the-action/3972678) (title only, approx. late 2025)
- Roblox Moments entered beta on 5 Sep 2025. Players capture, edit and share clips, and viewers tap "Join" to play. Moments APIs for creators are "coming soon". — [RDC25: What we announced](https://devforum.roblox.com/t/rdc25-what-we-announced/3920245)

**Other reach factors**
- Real-time text chat translation covers all 17 supported languages. Voice translation is coming in 2026 (EN/ES/FR/DE). — [RDC25: What we announced](https://devforum.roblox.com/t/rdc25-what-we-announced/3920245)
- A YouTubers/TikTokers chart-impact article exists but is low reliability and was not fetched. — [rowatcher.com](https://rowatcher.com/news/how-youtubers-and-tiktokers-move-the-charts-in-2026)

### Inferences
- Put a Share Link, not the plain game URL, in every Discord, YouTube Shorts or TikTok post. It is tracked and it is what earns Audience Expansion rewards.
- Rewards require 100+ DAU sustained for 60 days, so early-stage games may not get paid yet.
- For a solo dev aimed at 8-14-year-olds: YouTube and TikTok audiences of under-13s are restricted on those platforms, so reach them via small Roblox YouTubers rather than your own channel.
- Make a free "creator kit" for YouTubers: a private server, a code that gives a boost, and a b-roll clip.

### Gaps
- No primary-source data on the ROI of paying YouTubers or TikTokers, and no verified successful-dev postmortems were found in this pass.
- No official Discord-community guidance from Roblox was found. Best practice here is community-sourced.

## 6. Experience notifications, friend invites, referrals and share links as acquisition and retention channels

### Takeaway
Friends and co-play are now an explicit ranking signal. Roblox gives you three tools: a Friend Invite Reward (referral) system with customizable reward banners; experience notifications (opt-in, 1 per user per experience per day, 13+ only); and Share Links. For a mostly under-13 audience, notifications reach only the 13+ minority. Friend invites, referral rewards and co-play mechanics therefore matter more.

### Cited Findings
**Friend Invite Reward System** — [Creator Hub: Friend Invite Reward System](https://create.roblox.com/docs/production/promotion/referral-system)
- Players share referral links from invite prompts or the default invite menu. `Player:GetJoinData().ReferredByPlayerId` identifies the inviter, so you can reward both inviter and invitee in your own code.
- Reward banners (Creator Hub > Engagement > Referral Rewards) show at the top of the friend invite modal. A banner has an icon, a name, dates, and an optional limit (e.g. 3 per inviter). Only one banner can be live at a time.
- The game must have been live for at least 1 day.
- Invites are not limited to existing friends, and referral links never expire.
- Roblox gives no effectiveness data.
- The system was announced as upcoming in Mar 2025. — [2025 Discovery Roadmap](https://devforum.roblox.com/t/roblox%E2%80%99s-2025-discovery-roadmap-and-ways-to-reach-and-engage-your-audience/3557533)

**Friends as a ranking signal**
- "Intentional co-play days per user" (friend joins, invites, private servers) is an "important" RFY signal. Friend activity also drives notifications and the Friends sort on Home. — [Creator Hub: Discovery](https://create.roblox.com/docs/discovery)

**Experience notifications** — [Creator Hub: Experience Notifications](https://create.roblox.com/docs/ja-jp/production/promotion/experience-notifications)
- **Eligibility:** the game needs 100+ visits.
- **Audience:** recipients must be 13+. Under-13s get only "experience update" notifications.
- **Opt-in prompt:** `PromptOptIn()`. Its text can't be customized, and it re-shows at most once every 30 days.
- **Limits:**
  - 1 notification per user per experience per day, plus a global daily cap.
  - Messages up to 99 characters, with up to 200 bytes of launch data for deep-linking spawn points.
  - Delivery isn't guaranteed, and higher engagement leads to wider distribution.
- **Analytics:** opt-ins, impressions, clicks, CTR, turn-off rate and decline rate. Analytics appear after 100 impressions. A/B test by creating separate strings.
- **Best practice:** personalized, activity-based messages with a clear call to action. Never gate progress on opting in.
- Developer Push Notification Support (push to opted-in users) is planned for late 2026. — [Creator Roadmap 2026: Fall Update](https://devforum.roblox.com/t/creator-roadmap-2026-fall-update/4880208)

**Experience Betas**
- Experience Betas let you test with small audiences without appearing in search or discovery. They were announced at RDC 2025. — [RDC25](https://devforum.roblox.com/t/rdc25-what-we-announced/3920245)
- The late-2026 "Early testing" item grants up to 10 friends access to in-development games. — [Creator Roadmap 2026: Fall Update](https://devforum.roblox.com/t/creator-roadmap-2026-fall-update/4880208)
- Betas protect early signals: you can fix onboarding before the public cohort hits RFY.

**Ratings feedback**
- Users can leave written feedback after rating a game (announced Mar 2025). — [2025 Discovery Roadmap](https://devforum.roblox.com/t/roblox%E2%80%99s-2025-discovery-roadmap-and-ways-to-reach-and-engage-your-audience/3557533)

### Inferences
- For 8-14 players, build social loops into the core game:
  - A friend boost (e.g. +10% gains per friend in the server).
  - A referral reward banner, with rewards for both sides and a cap per inviter.
  - Free or cheap private servers.
  - Co-op events.
  These feed both the co-play signal and acquisition.
- Still implement notifications for the 13+ slice:
  - Use event-driven triggers such as "your egg hatched" or "new world unlocked". Activity-based messages beat generic ones.
  - Ask for opt-in at a satisfying moment, not on join.
- Use Experience Betas (when available) or private testing so the first public cohort doesn't produce bad bounce and retention data.

### Gaps
- No public numbers on referral or invite conversion rates, notification CTR benchmarks, or how much co-play weighs relative to playtime (the weights are in an un-extracted image).
- The exact launch dates of the referral system and the Share Link API could not be confirmed. The relevant DevForum posts were identified by title only.
