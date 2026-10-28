# Practical Roblox Analytics: Instrumentation and Diagnosis (2025-2026)

Research date: 2026-10-28. This builds on /home/claude/research_notes/Making Roblox games better/analytics_experiments.md (API signatures, funnel rules, event limits, benchmark definitions, Experiments, thumbnail personalization, discovery signals). That material is NOT repeated here except where needed. Docs pages were fetched live on 2026-10-28. One docs page failed to load (progression-events) and is noted as a gap.

## 1. Instrumentation plan for a kids' simulator (funnels, economy, progression, custom events, code patterns, mistakes)

### Takeaway
Build five layers, all server-side. (1) One onboarding funnel of about 8-10 steps covering the first 5 minutes. (2) Recurring funnels for shop, rebirth and pet-hatch, using a GUID per attempt. (3) Economy Source/Sink events for one or two currencies using the six built-in transaction types, with accurate ending balances and SKUs. (4) Progression events for zones and rebirths. (5) A small set of action-named custom events, with variants in custom fields rather than in names. The most common mistakes are client/Studio calls (silently dropped), logging purchase attempts instead of successes, negative sink amounts, per-variant event names, and editing funnel steps without resetting the dashboard date range.

### Cited Findings

**Economy events (new detail beyond earlier notes)**
- Built-in `Enum.AnalyticsEconomyTransactionType` values: `IAP` (Source, e.g. starter pack bought with Robux), `TimedReward` (Source, e.g. daily bonus), `Onboarding` (Source, welcome bonus), `Shop` (Source or Sink), `Gameplay` (Source or Sink, e.g. quest completion), `ContextualPurchase` (Sink, situational spend such as extra lives). Custom names are allowed, but the docs recommend starting with the defaults. — [Economy events](https://create.roblox.com/docs/en-us/production/analytics/economy-events)
- Argument order: player, flowType, currency name, amount, balance after transaction, transactionType name (e.g. `Enum.AnalyticsEconomyTransactionType.Gameplay.Name`), optional itemSku, plus optional custom fields (up to 3). — [Economy events](https://create.roblox.com/docs/en-us/production/analytics/economy-events)
- Amounts are always positive (the dashboard shows sinks as negative). If itemSku is omitted, tables show "N/A". The ending balance feeds the average-wallet charts, so it must be accurate. Docs examples: earning 50 coins gives balance 50, then 100; a 1000-coin bundle with SKU "1000CoinBundle" gives balance 1020; a Shop Sink of 80 for "DoubleJumpUpgrade" leaves balance 20. — [Economy events](https://create.roblox.com/docs/en-us/production/analytics/economy-events)
- The Economy dashboard has these charts. **Total sources and sinks by category**: the net (sources minus sinks) should stay near zero; if it grows, add sinks. **Average wallet balance** for users, payers and non-payers: rising balances, especially for payers, mean you should add sinks. **Top sources and sinks**: low IAP sourcing suggests price or offer changes, and low spending on a resource suggests it needs new sinks. **All sources and sinks**: combined view. Up to 5 currencies can be charted, and charts can be filtered by age, platform and gender and by custom fields. — [Economy events](https://create.roblox.com/docs/en-us/production/analytics/economy-events)
- Log economy events only after a successful transaction (from the earlier notes). — [Event types](https://create.roblox.com/docs/en-us/production/analytics/event-types)

**Funnels (new detail)**
- Docs example recurring funnel: `LogFunnelStepEvent(player, "ArmoryCheckout", HttpService:GenerateGUID(), step, stepName)`. The server-side example validates client-reported step numbers and `warn`s if a step exceeds the maximum. — [Funnel events](https://create.roblox.com/docs/en-us/production/analytics/funnel-events)
- After you edit steps, the dashboard shows a warning on the affected step if the date range spans the change. To see the new funnel, start the date range at the change date (e.g. step 2 changed 6/14, view 6/14-6/21). The docs do not say what happens to historical data when step numbers change. — [Funnel events](https://create.roblox.com/docs/en-us/production/analytics/funnel-events)
- Repeated steps count only once in the funnel but still count toward the global rate limit. Funnels can be broken down by up to 3 custom fields (e.g. starter car or map). — [Funnel events](https://create.roblox.com/docs/en-us/production/analytics/funnel-events)
- The funnel docs do not define conversion-rate or time-to-step metrics. The dashboard example shows step-to-step drop-off percentages (70% from "In Farm" to "Plant Seed"). — [Funnel events](https://create.roblox.com/docs/en-us/production/analytics/funnel-events)

**Custom events (new detail)**
- There are two kinds. Counters (`LogCustomEvent(player, "MissionStarted")`) have value 1, so their min/max/avg are always 1. Valued events (`LogCustomEvent(player, "MissionCompletedDuration", 120)`) can be batched, e.g. send "10 zombies" once instead of 10 calls. — [Custom events](https://create.roblox.com/docs/en-us/production/analytics/custom-events)
- Explore-page aggregations: Count, Count unique users, Average value, Sum value, Min, Max, Average value per user. Charts are aggregated daily (up to 24 h delay). — [Custom events](https://create.roblox.com/docs/en-us/production/analytics/custom-events)
- Naming: event names describe the action (`MissionStarted`, `HarvestPlant`). Event names have a much tighter cardinality limit than custom fields, so use one `PlantSeed` event with a Plant field instead of `PlantCabbage`/`PlantTurnip`. The limit is 100 event names per game. — [Custom events](https://create.roblox.com/docs/en-us/production/analytics/custom-events)

**Error reports (useful as an instrumentation companion)**
- The Error report shows server and client Luau errors and warnings over time, filterable by place, severity, platform, OS and "Show version". The table has Count, Severity, Type, Message, First seen at and First seen version, plus expandable stack traces. A "New errors since" version filter is available. — [Error report](https://create.roblox.com/docs/en-us/production/analytics/error-report)
- Custom rules (exact string or regex) can Ignore or Group errors, up to 100 per experience. They run top to bottom, first match wins, and apply only going forward. Tracking caps are 500 unique errors + 500 warnings + top 100 new errors per version, reset every 6 h. Strip dynamic values (user IDs, timestamps) from error messages so duplicates group together. — [Error report](https://create.roblox.com/docs/en-us/production/analytics/error-report)

### Inferences

**Suggested simulator event map.** This is a synthesis built on the documented APIs, not a Roblox-published plan.

- *Onboarding funnel* (`LogOnboardingFunnelStepEvent`, log step 1 in PlayerAdded):
  1 Joined → 2 CharacterLoaded/DataLoaded → 3 FirstClick (first train/collect action) → 4 FirstCurrencyEarned → 5 FirstShopOpened → 6 FirstUpgradeBought → 7 EnteredZone2 / first pet hatched → 8 FirstRebirthPromptSeen → 9 Played5Min → 10 Played15Min.
  Time-based steps (5 and 15 min) give a first-session survival curve that lines up with the Engagement page's "New user first session retention" and with the discovery bounce windows (<60 s, 61-180 s).
- *Recurring funnels* (`LogFunnelStepEvent`, max 10 funnels):
  - "Shop": Opened → ItemViewed → PurchaseClicked → PurchaseSucceeded. Use a GUID per opening. For a Robux product, log the last step in `ProcessReceipt` after granting.
  - "Rebirth": RebirthEligible → RebirthMenuOpened → RebirthConfirmed. Use the session ID `userId.."-"..rebirthCount`.
  - "EggHatch": EggViewed → HatchClicked → Hatched → PetEquipped.
  - "DailyReward": RewardAvailable → Claimed.
- *Economy* (keep to 1-3 currencies, e.g. Coins, Gems, Strength/Speed as "XP-like"):
  - Sources: Gameplay (training clicks, batched every N seconds), TimedReward (daily, playtime gifts), Onboarding (starter coins), IAP (Robux coin packs), Shop (selling pets).
  - Sinks: Shop (eggs, upgrades, zones), ContextualPurchase (instant boosts), Gameplay (rebirth costs, if currency is consumed).
  - Always pass the SKU (e.g. "Egg_Forest", "Zone_Desert", "Coins_1000") and the true post-transaction balance.
- *Progression*: path "Zones" (start/complete per zone level number) and path "Rebirth" (complete at each rebirth count). The progression-events docs page could not be fetched, so check the exact dashboard output; the signatures are in the earlier notes.
- *Custom events* (well under 100): `PetHatched` (fields: Rarity, Egg), `CodeRedeemed`, `FriendInvited`, `GroupJoinRewardClaimed`, `TradeCompleted`, `SettingsOpened`, `AFKKicked`, `BoostUsed` (field: BoostType), `SessionLength` (valued, on PlayerRemoving).
- *Naming conventions*: PascalCase verbs (`PetHatched`, not `pet_hatch_v2`). Stable step names that never contain versions or dates. Variants go in custom fields. Use one shared module (e.g. `ServerScriptService.Analytics`) that wraps every call, so names live in one table and you can add a dedupe guard.

**Code pattern** (author's own sketch using documented signatures; the custom-field key syntax should be verified against the AnalyticsService reference):
```lua
-- ServerScriptService/Analytics.lua (ModuleScript, server only)
local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")
local A = {}
local onboardingDone = {} -- [userId] = highest step logged this server

function A.Onboarding(player, step, name)
    local uid = player.UserId
    if (onboardingDone[uid] or 0) >= step then return end -- avoid double fires
    onboardingDone[uid] = step
    AnalyticsService:LogOnboardingFunnelStepEvent(player, step, name)
end

function A.Earn(player, currency, amount, newBalance, txType, sku)
    AnalyticsService:LogEconomyEvent(player, Enum.AnalyticsEconomyFlowType.Source,
        currency, amount, newBalance, txType, sku)
end

function A.Spend(player, currency, amount, newBalance, txType, sku)
    AnalyticsService:LogEconomyEvent(player, Enum.AnalyticsEconomyFlowType.Sink,
        currency, math.abs(amount), newBalance, txType, sku)
end

function A.NewFunnelSession() return HttpService:GenerateGUID(false) end

game:GetService("Players").PlayerRemoving:Connect(function(p) onboardingDone[p.UserId] = nil end)
return A
```
- Batch high-frequency sources: for click-to-train games, accumulate coins earned and log one Gameplay Source every 30-60 s or on zone change. Logging every click hits the 120 + 20×CCU per-minute rate limit from the earlier notes.
- Client UI events (shop opened, button clicked) go through a RemoteEvent to the server. Validate and rate-limit them before logging, as the docs example does.

**Common mistakes checklist**
1. Calling from LocalScripts or testing in Studio, which logs nothing. Verify in a published game with "View Events".
2. Logging the purchase attempt instead of a confirmed grant.
3. Negative sink amounts, or Source instead of Sink.
4. Wrong ending balance, e.g. logging before updating the wallet.
5. Firing twice because both the client handler and a server handler log, or because of respawn handlers (CharacterAdded fires every respawn).
6. Renaming or reordering funnel steps mid-analysis without resetting the date range. Treat any step edit as starting a new funnel period.
7. One event name per pet, egg or zone instead of custom fields.
8. More than 100 SKUs or 20 transaction types, which collapse into "Other".
9. Dynamic values inside error messages, which explode the unique-error cap.

### Gaps
- The progression-events docs page returned an error, so its dashboard charts for progression are not documented here.
- The docs do not state whether renaming a funnel step keeps or splits historical counts; they only say a warning appears.
- Exact custom-field dictionary syntax was not re-verified in this pass.

## 2. Reading every Creator Hub page: what each chart means, good/bad signs, benchmarks

### Takeaway
Each page answers one question. Acquisition: who sees you and plays. Engagement: do new players survive the first minutes. Retention: do they come back, by cohort. Monetization: who pays and how much. Economy: is the currency balanced. Performance: is it crashing or lagging. Demographics: who they are. Feedback: what they say. Roblox gives no numeric targets. The in-dashboard similar-game band (50th-90th percentile, needs at least 100 DAU) is the official yardstick. External GameAnalytics data for large games puts the median at D1 about 10%, D7 about 1.6%, D30 about 0.5%, with payer rate about 3.8%.

### Cited Findings

**Acquisition**
- Charts: New users with plays per source, New users with impressions per source, Returning users with plays per source, Returning users with impressions per source, Play through rate (impressions → plays), and Cumulative new users funnel by source. — [Acquisition](https://create.roblox.com/docs/en-us/production/analytics/acquisition)
- Sources: Home recommendations, Continue play, Today's Picks, Home other (favorites etc.), Friends, Search (includes Recommended on game details pages), Charts, Sponsored ads (incl. Sponsored Takeovers), Search ads, Portal ads, Teleport, Other (unknown/external). — [Acquisition](https://create.roblox.com/docs/en-us/production/analytics/acquisition)
- Per-source attribution metrics:
  - Users with plays.
  - Conversion rate: % who played after an impression.
  - D7 retention: played again on day 8.
  - 7D playtime per user.
  - 30D payer conversion.
  - 30D revenue per user, excluding subscriptions, engagement payouts and immersive ads.
  — [Acquisition](https://create.roblox.com/docs/en-us/production/analytics/acquisition)
- Guidance: fix play-through with an accurate, unique title, description and icon, plus images and video. If the game is excluded from recommendations, Home recommendations metrics show zero. Share links track off-platform acquisition. Good share links bring users with high 7D playtime, D7 and 30D revenue. — [Acquisition](https://create.roblox.com/docs/en-us/production/analytics/acquisition)
- Home recommendation signal charts are shown per signal for Day 1, Day 2-7 and Day 8-28. Read each window separately, then together: "strong Day 8-28 results rarely follow poor Day 1 and Day 2-7". Workflow: Acquisition first (did recommendations drive the DAU change?), then the signal charts. — [Discovery FAQ](https://create.roblox.com/docs/discovery-faq)
- A temporary play-through drop is normal when impressions rise. Impressions can fall even when your signals hold, because competitors improved or total Home traffic changed. — [Discovery FAQ](https://create.roblox.com/docs/discovery-faq)
- The RFY update (2026-06-15) said signals and their relative contribution would be brought into Creator Analytics. — [DevForum announcement](https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575)
- Earlier related analytics announcements: Home Recommendations conversion rate ([DevForum](https://devforum.roblox.com/t/analytics-view-home-recommendations-conversion-rate-and-recent-icon-updates/2731683)), Recommendations Qualified PTR + similar-experience benchmarks ([DevForum](https://devforum.roblox.com/t/analytics-recommendations-qualified-play-through-rate-and-similar-experiences-benchmarks/3075185)), and the April 2025 RFY analytics post ([DevForum](https://devforum.roblox.com/t/boost-your-discovery-with-the-improved-recommended-for-you-algorithm-and-analytics-for-creators/3587441)). These were titles from search, not fetched.
- A known bug report says Engagement could not be broken down by "Source". — [DevForum bug](https://devforum.roblox.com/t/unable-to-breakdown-the-engagement-category-in-analytics-by-source/4726148) (title only)

**Engagement**
- Average Session Time = total time in game / number of sessions. — [Engagement](https://create.roblox.com/docs/en-us/production/analytics/engagement)
- New User First Session Retention: the share of new users still playing X minutes after first joining, compared with the previous period. Bad sign: a significant week-over-week drop at the 5-minute mark. Check recent onboarding changes and the error/performance reports. — [Engagement](https://create.roblox.com/docs/en-us/production/analytics/engagement)
- Guidance: show the fun within 5 minutes, avoid long tutorials (use tooltips and starter items/currency), support group play, and don't gate the fun. — [Engagement](https://create.roblox.com/docs/en-us/production/analytics/engagement)

**Retention**
- Charts: D1, D7 and D30 retention (x-axis = cohort first-play date; recent D7/D30 values stay empty until the time passes) and a New user retention cohort table. The daily view tracks each cohort over its first 10 days; the weekly view groups Monday-Sunday joins over 10 weeks. — [Retention](https://create.roblox.com/docs/en-us/production/analytics/retention)
- Cohort down-funnel metrics: 7D playtime per user, 7D payer conversion, 7D revenue per user and 30D revenue per user (all cumulative). — [Retention](https://create.roblox.com/docs/en-us/production/analytics/retention)
- Which lever moves which metric:
  - D1 depends on the core loop, FTUE (fun in 5 minutes or less) and performance.
  - D7 depends on the progression system (short and long goals, variety, pacing; track how many reach each level).
  - D30 depends on the "ending system": small updates every 2-4 weeks, big ones every 2-3 months, and social features (trading, parties, guilds, PvP, leaderboards).
  — [Retention](https://create.roblox.com/docs/en-us/production/analytics/retention)
- A retention dip for cohorts around a large acquisition date is "typical and temporary" after a big influx. — [Retention](https://create.roblox.com/docs/en-us/production/analytics/retention)

**Monetization**
- Metrics: Revenue (hourly and daily, split by developer products, passes and commissions), Conversion rate (% of DAU who paid), Paying users, ARPPU and ARPDAU. — [Monetization](https://create.roblox.com/docs/en-us/production/analytics/monetization)
- Drill-downs: Developer Products, Passes, Avatar items, Subscriptions, Immersive ads, Creator rewards. — [Monetization](https://create.roblox.com/docs/en-us/production/analytics/monetization)
- Signs:
  - High ARPPU with low ARPDAU means revenue comes from a small subset of players.
  - Healthy means ARPPU and ARPDAU rising together.
  - Fixes for low conversion: check price, visibility and appeal; add first-buyer/welcome offers; review the purchase funnel.
  - Fixes for ARPPU: mix one-time and repeatable purchases, add variety around top sellers, add seasonal items.
  - Fixes for ARPDAU: offer a range of price points and improve retention.
  — [Monetization](https://create.roblox.com/docs/en-us/production/analytics/monetization)

**Performance**
- Client charts: Concurrent users, Session time, Client frame rate, Client crash rate (crashes / ended sessions, by device), Unexpected out-of-memory exits, Client crash count, Client memory usage, Client memory %, Client CPU time. — [Performance](https://create.roblox.com/docs/en-us/production/analytics/performance)
- Server charts: Server CPU time, Server frame rate (cap 60), Server memory, Server memory by age, Cores used per server, Compute efficiency. — [Performance](https://create.roblox.com/docs/en-us/production/analytics/performance)
- Thresholds and how to read them:
  - CPU time below 16 ms per frame (needed for 60 FPS).
  - Server memory below 50% and under about 3 GB.
  - Client memory % near 100% on a platform means crash risk.
  - An OOM-exit spike after an update means a memory regression.
  - A dashed crash-rate line means noisy, low-session data, so use crash count instead.
  - Break down by Place Version to compare releases.
  - The client and server charts need at least 100 DAU.
  — [Performance](https://create.roblox.com/docs/en-us/production/analytics/performance)

**Demographics**
- Shows country (% of MAU, downloadable), gender, age, top 10 languages and server frame rate. Age or gender groups with fewer than 3 users are hidden. Uses: plan content, localize metadata, find underrepresented audiences, show sponsors. Platform is not on this page; use the platform filter/breakdown elsewhere. — [Demographics](https://create.roblox.com/docs/en-us/production/analytics/demographics); [Analytics dashboard](https://create.roblox.com/docs/en-us/production/analytics/analytics-dashboard)

**Feedback**
- Chart view:
  - Total feedback (upvotes and downvotes).
  - % upvotes over the period.
  - Relative % change vs the prior equal period.
  - Trend chart, e.g. to spot a downvote spike after an update.
  - Date presets of 7/30/60/90 days.
  — [Feedback](https://create.roblox.com/docs/en-us/production/analytics/feedback)
- Detailed view and data notes:
  - Each row shows the rating, device type, platform and filtered comment text, and can be exported as CSV.
  - Ratings update daily.
  - Vote data starts Feb 1, 2025 and comments start Mar 17, 2025.
  - Hiding feedback is permanent.
  — [Feedback](https://create.roblox.com/docs/en-us/production/analytics/feedback)

**AI analytics assistant**
- Weekly and monthly AI reports identify drivers of DAU and revenue changes, detect outlier segments and summarize feedback. Analytics reports need 1,000+ DAU, feedback reports need 20+ comments, and Overview insights update daily at 100+ DAU. Models used: Gemini 2.5 (reports) and Llama 3 (feedback). The reports "can make mistakes". — [Analytics assistant](https://create.roblox.com/docs/assistant/analytics-assistant)

**Benchmarks**
- In-dashboard band example: Day 1 Retention 12.11%-18.73% means 50% of similar games are at or below 12.11% and 10% are at or above 18.73%. — [Analytics dashboard](https://create.roblox.com/docs/en-us/production/analytics/analytics-dashboard)
- GameAnalytics 2026 Roblox Report covers 500+ games with more than 1M MAU, Aug 2025-Jul 2026, 4.76B sessions. All its figures are biased upward for small games.
  - Retention: median D1 10.3% / D7 1.6% / D30 0.5%; top 1% reaches 22.2% / 9.1% / 4.7%.
  - Game session length: median 9.8 min, top 5% 16.6, top 1% 21.1.
  - Payers: 3.8% of players spent anything.
  - Game ARPPU: median $0.70, top 10% $2.33.
  - Daily playtime per player: median 22.4 min.
  — [GameDev Reports summary, 2026-09-25](https://gamedevreports.substack.com/p/gameanalytics-key-roblox-and-roblox)
- GameAnalytics 2025 Roblox report (data Jan 2023-Jul 2025, games with more than 1M MAU). Retention by average session length (median / top 10%):
  - Games with 0-3 min sessions: D1 4.31% / 9.25%.
  - 13-18 min: D1 10.24% / 14.96%, D7 1.20% / 2.70%.
  - 25+ min: D1 10.76% / 18.86%, D7 1.82% / 5.86%.
  - Median ARPPU rises with session length, from $0.48 to $2.12.
  — [GameAnalytics 2025 Roblox report](https://www.gameanalytics.com/cn/reports/2025-roblox-report)
- Conflicting third-party claim: RoWatcher says you need 25-30% D1 before buying ads and that "most new games sit below 20%". These figures come from unnamed developer benchmarks and are far above the GameAnalytics medians, so treat them as opinion. — [RoWatcher, 2026-06-07](https://rowatcher.com/news/is-roblox-advertising-worth-it-for-games-under-1k-daily-players)

### Inferences
- For a kids' simulator, the realistic yardstick is the in-dashboard similar-game band once you reach 100 DAU. Before that, GameAnalytics medians (D1 about 10%, D7 about 1.5%, session about 10 min, about 3-4% payers, ARPPU about $0.70) mark "average among big games". Being below them at small scale is normal, but D1 under about 5% points to a first-session problem.
- Read the pages in order (Acquisition → Engagement first-session → Retention cohorts → Monetization → Economy → Performance). Each step either explains the next metric or rules out a cause.

### Gaps
- No official numeric "good" thresholds for any metric. Exact Overview chart list and Home Recommendations tab chart names were not documented on the pages fetched.
- No genre-specific (simulator) public benchmarks with sound methodology were found. RoWatcher genre articles exist but cite no primary data.

## 3. Diagnosis playbooks

### Takeaway
Every playbook follows the same path: locate the drop (which source, which cohort, which step, which version), check stability (errors, crashes), then fix the earliest broken step. Roblox's docs give the causal mapping: D1 depends on FTUE and performance, D7 on progression, D30 on updates and social; impression drops follow falling play-through, play days and playtime plus rising bounce.

### Cited Findings
- Spike that fades: impression drops "usually follow drops in play-through rate, play days, and playtime, along with a rise in first-play bounce" (earlier notes, [Discovery docs](https://create.roblox.com/docs/en-us/discovery)). Retention dips for big-influx cohorts are typical and temporary ([Retention](https://create.roblox.com/docs/en-us/production/analytics/retention)). Competitor gains and Home traffic seasonality can also cut impressions ([Discovery FAQ](https://create.roblox.com/docs/discovery-faq)).
- High early bounce: use New User First Session Retention (minutes after joining) and check recent onboarding changes and error/performance reports. — [Engagement](https://create.roblox.com/docs/en-us/production/analytics/engagement)
- Good D1, bad D7: the D7 lever is progression (goal ladders, content variety, pacing; track how many reach each level). — [Retention](https://create.roblox.com/docs/en-us/production/analytics/retention)
- Low payer conversion: check price, visibility and appeal, add first-time-buyer offers, review the purchase funnel. — [Monetization](https://create.roblox.com/docs/en-us/production/analytics/monetization)
- Revenue drop after update: break performance down by Place Version, watch OOM exits, use "New errors since" and First seen version, and check the feedback trend for a downvote spike. — [Performance](https://create.roblox.com/docs/en-us/production/analytics/performance); [Error report](https://create.roblox.com/docs/en-us/production/analytics/error-report); [Feedback](https://create.roblox.com/docs/en-us/production/analytics/feedback)
- Ads acquire users who then usually won't see the game in RFY, which can lower RFY impressions even while total acquisition rises. Ad users are excluded from RFY signals. — [Discovery FAQ](https://create.roblox.com/docs/discovery-faq)

### Inferences (playbooks)

**A. Traffic spike that fades (within days)**
1. Acquisition by source: was the spike Home recommendations (algorithm test), Sponsored ads, Friends/Other (a YouTuber or TikTok)?
2. Home recommendation signals for the spike window: did PTR drop and first-play bounce rise? A bounce rise means a thumbnail or title mismatch, or a slow load / confusing spawn.
3. Onboarding funnel filtered to the spike's first-play dates: which step lost the extra players compared with a normal week?
4. Engagement: New-user first-session retention at the 5-minute mark.
5. Retention cohort table: did D1 and D2-7 for the spike cohorts fall far below normal cohorts (beyond the "typical" dip)?
6. Performance by version and platform: mobile OOM or crash counts during the spike (bigger servers, more pets rendered).
- Fix order: the first-minute experience, then thumbnail honesty, then the day 2-7 return reason (daily reward, limited egg, friend boost).

**B. High bounce in first 60 s**
- Likely causes: long load (too many assets on join), spawning players without a clear first action, mandatory tutorial walls, UI covering the screen on phones, thumbnail promising something not visible at spawn, crashes on low-memory devices.
- Check funnel steps 1→3 (Joined → DataLoaded → FirstClick) and the time between them.
- Check the client memory % and OOM exits for phones.
- Check Performance "Client API calls in first 60 s after join" (top games only).
- Fix: make the first action obvious within seconds (big glowing button or arrow) and grant a reward in the first 30 s.

**C. Good D1, bad D7**
- The first session is fun, but there is no next goal.
- Check: progression events (where do players stall: zone 2? first rebirth?), the Rebirth funnel's Eligible→Confirmed drop, and economy wallet balance (rising balance with nothing to buy means a content or sink gap; very low balance means grind too steep).
- Fixes: visible next-goal UI, daily rewards and streaks, collection goals (pet index), limited-time eggs, friend-join boosts. The D2-7 window is a ranking signal (earlier notes).

**D. Low payer conversion**
- Check: Shop funnel (Opened → Viewed → Clicked → Succeeded). Low Opened means a visibility problem; low Viewed→Clicked means a price or appeal problem; low Clicked→Succeeded means the purchase prompt was cancelled (parental limits are likely for kids).
- Check the "Top sources" economy chart for low IAP sourcing.
- Check the payer segment filters.
- Fixes: a cheap first offer (starter pack), passes with obvious value (2x coins, auto-train, extra pet slots), sensible price ladder.
- Kids' audiences have a structurally lower payer rate (author inference; not verified with data).

**E. Revenue drop after update**
- First rule out stability: errors (New errors since version), crash/OOM by version, server FPS.
- Then check revenue by product (did a top product break, or its prompt move?), and shop funnel steps before vs after.
- Then economy: did the update add a big free Source that removed the need for IAP (net source going up)?
- Then DAU/new users: is revenue down just because DAU is down (ARPDAU flat)?
- Compare same weekday (Saturday peaks) and use the 28-day offset overlay.

**F. Ad campaign evaluation**
- See section 5.
- Compare ad-sourced vs organic users using the Acquisition per-source metrics (Conversion, D7, 7D playtime, 30D payer conversion, 30D revenue per user) and retention filtered by source.

### Gaps
- No Roblox-published case study with before/after numbers for any of these playbooks was found.

## 4. Small-game realities: thresholds, noise, deciding with few players, qualitative feedback

### Takeaway
Many analytics features are gated by DAU:
- More than 10 DAU for 7 days: KPIs.
- 100 DAU: benchmarks, performance charts, daily insights.
- 1,000 DAU: AI reports and reliable Experiments.

Below those thresholds, use View Events plus raw counts, weekly cohorts rather than daily, big changes one at a time, and heavy qualitative input: watch players, read Feedback comments, run small playtests and time-limited public tests.

### Cited Findings
- Thresholds:
  - KPIs need more than 10 DAU and 10 play-hours for 7 consecutive days (earlier notes).
  - Benchmarks need 100 DAU or more ([Analytics dashboard](https://create.roblox.com/docs/en-us/production/analytics/analytics-dashboard)).
  - Performance client/server charts need 100 DAU or more ([Performance](https://create.roblox.com/docs/en-us/production/analytics/performance)).
  - Overview insights need 100+ DAU; AI analytics reports need 1,000+ DAU; feedback AI summary needs 20+ comments ([Analytics assistant](https://create.roblox.com/docs/assistant/analytics-assistant)).
  - Experiments struggle under 1,000 DAU (earlier notes).
- Low-session data shows as a dashed crash-rate line ("noisy"); use crash count. — [Performance](https://create.roblox.com/docs/en-us/production/analytics/performance)
- Demographic groups under 3 users are hidden. — [Demographics](https://create.roblox.com/docs/en-us/production/analytics/demographics)
- Roblox testing ladder:
  - Small-group playtests with invited users (do they understand it, is it fun?).
  - A limited-time public test for a weekend or a week, for organic D1 and session length.
  - A closed group beta for long-term retention and monetization (needs a community).
  - "Join your game to watch what players do and say, and ask them directly."
  — [Recommended strategies](https://create.roblox.com/docs/get-started/strategies)
- Signals are per-user averages, so small games with engaged users aren't disadvantaged, and a "very low minimum number of plays from any source" is enough to enter retrieval. — [Discovery FAQ](https://create.roblox.com/docs/discovery-faq)
- Feedback comments give player text with device/platform. Read comments, not just votes. — [Feedback](https://create.roblox.com/docs/en-us/production/analytics/feedback)
- Opinion: under about 1,000 DAU, retention data is "too noisy to act on". — [RoWatcher](https://rowatcher.com/news/is-roblox-advertising-worth-it-for-games-under-1k-daily-players) (third-party, no primary data)

### Inferences
- **Rule of thumb on noise**: with 50 new users a day, a D1 of 10% is about 5 returners, and the 95% interval is roughly ±8 points (binomial). So:
  - Use weekly cohorts from the cohort table.
  - Pool 2+ weeks before and after a change.
  - Only trust changes of several points that repeat.
  - Prefer funnel step conversion, which has a larger denominator, over D7/D30.
- **Decision rules**: one change per update. Write the hypothesis and the expected metric before shipping. Judge D1 2 days after release and D7 9 days after. Revert if a funnel step drops sharply.
- **Session-recording alternatives**: Roblox has no built-in session replay (no evidence found). Options:
  - Join live servers and watch.
  - Ask friends or family kids to play while you watch over their shoulder or on a video call with screen share, thinking aloud.
  - Record your own screen when testing on a phone.
  - Add a server-side "breadcrumb" custom event (e.g. `StuckNoAction60s`) to find where people idle.
  - Use the onboarding funnel with time-based steps as a "replay by numbers".
- Use the Feedback CSV export and tag comments weekly (bug / too hard / wants feature).
- Seed traffic for measurement: a small ad campaign or a time-limited public test gives enough new users to read the onboarding funnel. Read the ad cohort separately.

### Gaps
- No official guidance on minimum sample sizes outside Experiments' MDE display.
- No Roblox product for session recording/heatmaps was found.

## 5. Ads Manager reporting and judging a campaign

### Takeaway
Ads Manager reports Spent, Impressions, Clicks, Plays, CPP (spend / plays), Playtime and Earnings (with ROAS on Earnings campaigns), with attribution split into New, Recent, Resurrected-7D and Resurrected-30D users. Judge a campaign after the 24-h learning period and the 48-h data lag. Use CPP to compare creatives. Judge quality by ad-cohort D1/D7, playtime and 30-day earnings versus organic, and judge value by attributed earnings versus spend. Ads don't change RFY ranking.

### Cited Findings
- Metric cards: Amount Spent, Impressions, Plays (joined because of ad), Playtime. — [Ads Manager](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)
- Table columns:
  - Campaign, On/Off, Status (Learning, Active, Completed, Rejected), Spent, Impressions.
  - Clicks (Home and Search), Plays.
  - CPP = spend / plays.
  - Playtime.
  - Earnings: ad revenue + Creator Rewards + in-game purchases, excluding subscriptions; shown in Robux and USD at the DevEx rate.
  - Clicking a campaign shows asset-level (per-creative) breakdowns and a daily chart.
  — [Ads Manager](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)
- Objectives:
  - Plays: broad reach and testing.
  - Earnings (Limited): likely spenders, for mature economies.
  - Engagement: age-checked, highly engaged users toward the Roblox Kids and Select threshold. It has a higher CPP, does not auto-pause at the threshold, and if there is no progress in 3-5 days you should review onboarding.
  - Automated bidding is the default.
  — [Ads Manager](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)
- Attribution:
  - New Users: credit lasts 30 days from first join via ad.
  - Recent: under 7 days since last play; only sessions starting with an ad click count.
  - Resurrected 7D: 7-29 days lapsed, credit lasts 7 days.
  - Resurrected 30D: 30+ days lapsed, credit lasts 30 days.
  - All Users: combined.
  - If All Users looks weak, check Recent/Resurrected.
  — [Ads Manager](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)
- Timing:
  - The first 24 h are learning.
  - Most campaigns need several days.
  - Impressions and clicks are real-time; plays and earnings lag up to 48 h and include events up to 30 days after the ad.
  - ROAS = attributed earnings USD / spend, shown as "Estimated ROAS" while still accruing.
  — [Ads Manager](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)
- Up to 10 thumbnails (16:9) per campaign. Non-unique or clone-like games get little spend. Ads don't change RFY ranking. — [Ads Manager](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)
- May 2025 Ads Manager upgrade (DevForum, 2025-05-21):
  - New-flow campaigns saw CPP -44% and quality play-through rate +89% as of early May.
  - 2 in 5 campaigns used 2+ creatives.
  - Pacing spikes fell 80%.
  - New objectives: Drive Retention (played in last 30 days) and Reactivate Users (lapsed 30-180 days).
  - Minimum setup is 10 ad credits (5/day × 2 days).
  — [DevForum: More Ads Manager upgrades](https://devforum.roblox.com/t/more-ads-manager-upgrades/3659656)
  - Note that the current docs list the objectives as Plays / Earnings / Engagement, so the 2025 objective names may be outdated.
- Use earned Robux rather than purchased Robux for ads, because purchased Robux cost more per Robux. — [Recommended strategies](https://create.roblox.com/docs/get-started/strategies)
- Ad-acquired users and their later behaviour are excluded from RFY signals. — [Discovery FAQ](https://create.roblox.com/docs/discovery-faq)
- Conflict: RoWatcher claims ad traffic lowers session length and return rate and "can hurt algorithmic placement", and quotes CPC of 30-150+ Robux from DevForum estimates. Roblox's own docs say ad users are excluded from RFY signals, and the current model is auto-bid CPP, so treat RoWatcher's claims as outdated or anecdotal. — [RoWatcher](https://rowatcher.com/news/is-roblox-advertising-worth-it-for-games-under-1k-daily-players) vs [Discovery FAQ](https://create.roblox.com/docs/discovery-faq)

### Inferences (how a solo dev should judge a campaign)
- **Before launching**:
  - Make sure the onboarding funnel and economy events are live, so the ad cohort is measurable.
  - Run 2-4 creatives and use a modest budget over 5-7 days.
  - Record the start date so you can filter Creator Hub retention by first-play date and source = Sponsored ads.
- **Day 2-3**: compare CPP across creatives (asset breakdown). Pause clear losers. Ignore day-1 numbers (learning).
- **Day 7-10**: compare ad users with organic users on the Acquisition per-source metrics: Conversion, D7, 7D playtime, 30D payer conversion, 30D revenue per user.
  - Ad D1/D7 near organic means a healthy campaign that is worth continuing to seed discovery testing.
  - Ad D1 far below organic means a creative/game mismatch (thumbnail promising something else).
- **Day 30**: Earnings / spend (ROAS). Few small simulators will reach ROAS ≥ 1 directly. The value is in measurement data and in seeding retrieval for RFY, since ad users themselves don't count toward ranking.
- **Simple break-even**: CPP (in Robux) vs 30D earnings per ad user (Robux). Example: a 10 Robux CPP needs at least 10 Robux of earnings per play within 30 days. This is illustrative arithmetic only, not a Roblox figure.

### Gaps
- No official typical CPP ranges or benchmarks for kids' simulators were found. The DevForum ad-performance thread fetched had no visible numbers.
- Whether Creator Hub retention can be filtered precisely to "Sponsored ads" for a specific campaign (vs all ads) was not confirmed.
