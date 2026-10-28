# Analytics and Experimentation for Roblox Experiences (2025-2026)

Research date: 2026-10-28. All Creator Hub docs fetched live on that date unless noted. Roblox renamed "experiences" to "games" in much of its 2025-2026 docs; both terms appear.

## 1. What Creator Hub Analytics offers now (dashboards, benchmarks, funnels, custom events, limits)

### Takeaway
Creator Hub Analytics is a free, built-in suite: KPI dashboards (Overview, Retention, Engagement, Acquisition incl. Home Recommendations, Demographics, Feedback, Monetization, Explore), Insights, benchmarks against similar games, and four kinds of scripted events sent via `AnalyticsService` (onboarding/recurring funnels, economy, progression, custom). Full KPI access needs >10 DAU and 10 play-hours for 7 consecutive days; benchmarks need >=100 DAU. Event charts take ~24 h to populate, but a near-real-time "View Events" list lets you verify tracking immediately.

### Cited Findings

**Dashboard pages and access**
- Pages: Overview, Retention (D1/D7/D30), Engagement (Average Session Time), Acquisition (traffic sources, Play Through Rate), Demographics (age, gender, country, language of MAU), Feedback (comments/ratings), Monetization (business KPIs + downloadable sales data), Explore (custom charts, calculated metrics, tables) — [Analytics dashboard](https://create.roblox.com/docs/en-us/production/analytics/analytics-dashboard); [Analytics overview](https://create.roblox.com/docs/en-us/production/analytics)
- Monetization page shows payer conversion rate, ARPPU and revenue; Acquisition shows new users, sources and home-recommendation play-through rate — [Analytics overview](https://create.roblox.com/docs/en-us/production/analytics)
- Separate Economy, Funnel and Custom pages exist in the game's Analytics dashboard for scripted events, with a "View Events" button giving a near-real-time list of recent events (filter by event type, user ID, keyword) — [Event types](https://create.roblox.com/docs/en-us/production/analytics/event-types)
- Acquisition > "Home Recommendations" tab shows impressions, plays and the discovery signal charts — [Discovery docs](https://create.roblox.com/docs/en-us/discovery)
- "Insights" highlights large movements in DAU, new users and revenue with suggested next steps — [Analytics overview](https://create.roblox.com/docs/en-us/production/analytics)
- Analytics Home: a Watchlist of up to 9 games showing DAU, new users, session time, D1 retention, daily revenue (only public stats like like-ratio/CCU for games you lack permission on); Share Links tab tracks visits from share links you created — [Analytics overview](https://create.roblox.com/docs/en-us/production/analytics)
- Eligibility: full KPI access requires more than 10 DAU and 10 play-hours for 7 consecutive days; enrollment needs verified email + 2-step verification and accepting Terms; chart CSV export not available in first 48 h — [Analytics dashboard](https://create.roblox.com/docs/en-us/production/analytics/analytics-dashboard)
- Filters/breakdowns: age group, gender, country, language, source, first-play date, active payer status, platform spender status, in-experience activity status, user engagement (days played in last 7), platform activity status, platform, OS, memory group (perf only) — [Analytics dashboard](https://create.roblox.com/docs/en-us/production/analytics/analytics-dashboard)
- Segment definitions: Active payer status = Top 15% / Intermediate 35% / Casual 50% / Lapsed (no spend 30 days) / Never; Platform spender "Active" = $9.99+ spent anywhere on Roblox in last 60 days; In-experience activity: Early (first 30 days), Active, Lapsed (30 days), Reactivated — [Analytics dashboard](https://create.roblox.com/docs/en-us/production/analytics/analytics-dashboard)
- Explore supports calculated metrics (e.g. win rate = RoundWins / RoundsPlayed), benchmark and period-over-period overlays (e.g. 28-day offset), 7-day moving-average smoothing, shareable chart URLs — [Analytics dashboard](https://create.roblox.com/docs/en-us/production/analytics/analytics-dashboard)
- Sales data CSV: Buyer User ID, sale time, location, asset ID/name/type, hold status, revenue (after fees), price; monthly downloads up to 2 years back — [Analytics dashboard](https://create.roblox.com/docs/en-us/production/analytics/analytics-dashboard)
- Sept 15, 2026 update: analytics segmentable by in-game activity, engagement level, platform activity, tenure, platform spend; performance monitoring adds error detection with custom rules, real-time alerts, and crash rate / memory / CPU time / frame rate telemetry broken down by game version; Configs gained conditional per-segment values and live changes without server restarts — [PocketGamer.biz, 2026-09-15](https://www.pocketgamer.biz/roblox-expands-analytics-tools-with-real-time-alerts-and-player-targeting/)

**Benchmarks**
- Similar-player benchmarks (Retention, Avg Session Time, ARPPU, ARPDAU, conversion rate, Play Through Rate) are built from games with similar players (fallback: genre, then all games), only from games with >=100 DAU, shown as the 50th-90th percentile band — [Analytics dashboard](https://create.roblox.com/docs/en-us/production/analytics/analytics-dashboard)
- "Overall-success" benchmarks: pool = top 1,000 games by playtime over rolling 30 days (games <30 days old excluded), tiers Top 200/500/1,000 — [Analytics dashboard](https://create.roblox.com/docs/en-us/production/analytics/analytics-dashboard)
- Benchmarks "don't affect the algorithm" and are a rough comparison only — [Discovery docs](https://create.roblox.com/docs/en-us/discovery)

**Runtime segments**
- `AnalyticsService:GetPlayerSegmentsAsync(player)` (yields) returns a dictionary (e.g. `HasData`, `WhenUserFirstPlayed`, payer status) so you can tailor offers or onboarding by segment in-game — [AnalyticsService reference](https://create.roblox.com/docs/en-us/reference/engine/classes/AnalyticsService); [Analytics overview](https://create.roblox.com/docs/en-us/production/analytics)

**AnalyticsService API (current signatures)**
- `LogOnboardingFunnelStepEvent(player, step, stepName, customFields?)` — one-time onboarding funnel — [AnalyticsService reference](https://create.roblox.com/docs/en-us/reference/engine/classes/AnalyticsService)
- `LogFunnelStepEvent(player, funnelName, funnelSessionId, step, stepName, customFields?)` — recurring funnels (shop, upgrades) — [AnalyticsService reference](https://create.roblox.com/docs/en-us/reference/engine/classes/AnalyticsService)
- `LogEconomyEvent(player, flowType: Enum.AnalyticsEconomyFlowType (Source/Sink), currencyType, amount, endingBalance, transactionType, itemSku, customFields?)`; transactionType can use `Enum.AnalyticsEconomyTransactionType.<X>.Name` (e.g. IAP) — [AnalyticsService reference](https://create.roblox.com/docs/en-us/reference/engine/classes/AnalyticsService)
- `LogProgressionEvent(player, progressionPathName, status: Enum.AnalyticsProgressionType, level, levelName, customFields?)` plus convenience `LogProgressionStartEvent / LogProgressionCompleteEvent / LogProgressionFailEvent` — [AnalyticsService reference](https://create.roblox.com/docs/en-us/reference/engine/classes/AnalyticsService)
- `LogCustomEvent(player, eventName, value = 1, customFields?)` — [AnalyticsService reference](https://create.roblox.com/docs/en-us/reference/engine/classes/AnalyticsService)
- Older `FireCustomEvent`, `FireEvent`, `FireInGameEconomyEvent`, `FireLogEvent`, `FirePlayerProgressionEvent` are deprecated (older info — do not use) — [AnalyticsService reference](https://create.roblox.com/docs/en-us/reference/engine/classes/AnalyticsService)
- Funnel events must be sent from the server in published games; "can't be sent from the client or Studio" — [Funnel events](https://create.roblox.com/docs/en-us/production/analytics/funnel-events)

**Funnel rules**
- Funnel starts when step 1 is logged (log step 1 in `Players.PlayerAdded` to start on join); only the first instance of a step counts; logging step 3 auto-completes steps 1-2; validate client-triggered steps on the server — [Funnel events](https://create.roblox.com/docs/en-us/production/analytics/funnel-events)
- funnelSessionId: use `HttpService:GenerateGUID()` for shop funnels (opened many times), `<playerId>-<itemId>` for upgrades spanning sessions; analytics tracks the 10 most recent session IDs per user per funnel — [Funnel events](https://create.roblox.com/docs/en-us/production/analytics/funnel-events)
- A user's saved step expires after 180 days without events; funnels are cohorted by entry date; player/device filters apply only to step 1; up to 10 funnels as dashboard tabs; breakdown by custom fields — [Funnel events](https://create.roblox.com/docs/en-us/production/analytics/funnel-events)
- Docs example shows a 70% drop between onboarding step 1 and 2; best practice is to start with the onboarding funnel since "it's often where most users drop off" — [Funnel events](https://create.roblox.com/docs/en-us/production/analytics/funnel-events)

**Limits**
- Global rate limit 120 + (20 x CCU) requests/minute; 10 economy resource types; 20 transactionTypes and 100 itemSkus before grouping as "Other"; 10 funnels per game; 100 steps per funnel; 100 custom eventNames; max 3 custom fields per event; >8,000 combined custom-field values grouped as "Other"; limits reset daily; events visible 90 days after last data — [Event types](https://create.roblox.com/docs/en-us/production/analytics/event-types)
- Charts take ~24 h; log economy events only after a successful transaction (not on attempt) — [Event types](https://create.roblox.com/docs/en-us/production/analytics/event-types)
- Tip from docs: track one currency (e.g. XP) and put the class in a custom field rather than one currency per class — [Event types](https://create.roblox.com/docs/en-us/production/analytics/event-types)

### Inferences
- For a solo dev, a minimal instrumentation set is: onboarding funnel (5-10 steps covering first 3-5 minutes), one shop funnel, economy events for the main soft currency, progression events for main levels/rebirths, and a handful of custom events for key features. This fits well inside the 10-funnel / 100-event limits.
- Because the dashboard needs >10 DAU for a week, brand-new games with tiny traffic will see little until some ads/friends traffic arrives; View Events is the way to verify instrumentation early.
- The docs page didn't describe a classic "cohort table" view; retention is shown as D1/D7/D30 lines with first-played filters. Treat "cohort analysis" as filtering by "when user first played".

### Gaps
- No official definitions of DAU/D1/D7/ARPDAU formulas were found on the dashboard page (retention definition is implied, not spelled out).
- Could not confirm a dedicated "cohort table" UI or a public Open Cloud analytics API page details (an Open Cloud "Supported metrics and dimensions" page exists at https://create.roblox.com/docs/cloud/guides/analytics/metrics but was not fetched).
- An "Assistant for analytics" docs page exists (https://create.roblox.com/docs/assistant/analytics-assistant) but was not fetched; capabilities unverified.

## 2. Built-in experimentation / A/B testing (experiments, thumbnail personalization, price tests)

### Takeaway
Roblox has three built-in testing systems: (1) Experiments on Configs (in-game A/B tests, plus matchmaking tests) run 14-60 days with built-in significance, MDE, early-harm and sample-ratio checks; (2) Thumbnail Personalization, a bandit-style test of 2-5 Home thumbnails optimizing qualified play-through rate; (3) Price Optimization under Managed Pricing, automatic ~3-week price tests needing ~60,000 transactions/30 days. Games under ~1,000 DAU will struggle to get significant experiment results.

### Cited Findings

**Experiments (Configs-based)**
- Types: In-experience (tests values of a Config key) and Matchmaking (custom matchmaking configs; only one at a time, 100% rollout recommended, up to 3 variants split equally) — [Experiments](https://create.roblox.com/docs/en-us/production/experiments)
- Setup: create a Config → Creator Hub Experiments → Create experiment → name, goal metric, duration 14-60 days, % rollout, up to 2 variants + control with % splits, optional audience targeting (country, tenure, spender tier) → start or schedule; scheduled experiments can't be edited, only rescheduled — [Experiments](https://create.roblox.com/docs/en-us/production/experiments)
- Code: use `ConfigService:GetConfigForPlayerAsync(player)` (NOT `GetConfigAsync()`, which ignores experiments) and call `GetValue(key)` on the snapshot — that call enrolls the player; call it only when the player reaches the tested feature so non-exposed players aren't enrolled; persist values in a DataStore if needed across sessions — [Experiments](https://create.roblox.com/docs/en-us/production/experiments)
- Metrics always tracked: D1 retention, D7 retention, Playtime, ARPU, ARPPU, Payer conversion rate, Session time; results update every 24 h (Playtime/ARPU/conversion every 5 min in first 24 h) — [Experiments](https://create.roblox.com/docs/en-us/production/experiments)
- Sample size: the creation UI shows a Minimum Detectable Effect (MDE); MDE >100% makes significance unlikely; "Games with fewer than 1,000 daily active users may struggle to get useful data"; simple 50/50 one-variant splits on large rollouts recommended — [Experiments](https://create.roblox.com/docs/en-us/production/experiments)
- Significance: a metric is significant when its % change confidence interval excludes 0% (example: ARPU +2.37%, CI 0.55%-4.19%); "Don't act on changes that aren't statistically significant" — [Experiments](https://create.roblox.com/docs/en-us/production/experiments)
- Early harm (first 24 h): flags if entire CI is below Playtime -10%, ARPU -20%, Payer conversion -20%; needs >=10,000 enrolled players in the comparison; notifies via email/tray/webhook — [Experiments](https://create.roblox.com/docs/en-us/production/experiments); early-harm detection and segment targeting announced 2026-09-15 — [PocketGamer.biz](https://www.pocketgamer.biz/roblox-expands-analytics-tools-with-real-time-alerts-and-player-targeting/)
- Sample Ratio Mismatch alert if enrollment proportions are off; recommendation: stop and restart — [Experiments](https://create.roblox.com/docs/en-us/production/experiments)
- One active experiment per config key; key locked while running; on decision, an untargeted winning variant becomes the config default — [Experiments](https://create.roblox.com/docs/en-us/production/experiments)
- Best practices: write a hypothesis, run full duration (novelty effect), avoid content changes during the test, run concurrent tests only if non-interacting, document decisions — [Experiments](https://create.roblox.com/docs/en-us/production/experiments)
- Docs framing: use Experiments to test a change before committing, Configs to tune values live once you know what works — [Analytics essentials](https://create.roblox.com/docs/en-us/production/game-design/analytics-essentials)

**Thumbnail Personalization**
- Activate 2-5 thumbnails via "Edit active thumbnails" on the Home Page tab; algorithm shows each to random users, then shifts impressions to the best performer per user group while keeping minimal traffic on others; goal is qualified play-through rate (share of users who actively play for a significant time) — [Thumbnails docs](https://create.roblox.com/docs/en-us/production/publishing/thumbnails)
- Reported average qualified play-through lift +8.5% in testing, some games +50% — [Thumbnails docs](https://create.roblox.com/docs/en-us/production/publishing/thumbnails)
- Thumbnail Performance table: Impressions, Qualified Plays, Average Playtime (per qualified play), Qualified Play Through Rate (qualified plays / impressions), Winning Segment; stats appear after a few hours; no fixed test end — [Thumbnails docs](https://create.roblox.com/docs/en-us/production/publishing/thumbnails)
- Guidance: test several new thumbnails with each major update, then leave them until next update; keep multiple active rather than picking one winner early — [Thumbnails docs](https://create.roblox.com/docs/en-us/production/publishing/thumbnails)
- Personalization "remembers your existing winning thumbnails" (DevForum announcement, 2025) — [DevForum](https://devforum.roblox.com/t/thumbnail-personalization-now-remembers-your-existing-winning-thumbnails/3793665) (title only seen, not fetched)
- Specs: 16:9, ideally 1920x1080, <3 MB for personalization uploads; keep key elements off the bottom edge (player-count overlay); video thumbnails limited to 3 uploads/month, no voice-over, must show real gameplay — [Thumbnails docs](https://create.roblox.com/docs/en-us/production/publishing/thumbnails)
- A custom thumbnail is required to be eligible for Home recommendations — [Discovery docs](https://create.roblox.com/docs/en-us/discovery)
- Third-party opinion: CTR-only thumbnail optimization is harmful if it raises early bounces; recommends >=7-day comparisons — [RoWatcher, 2026-08-11](https://rowatcher.com/news/roblox-thumbnail-a-b-testing-what-the-data-actually-shows) (author's own thresholds, no primary data — treat as opinion)

**Price testing (Price Optimization / Managed Pricing)**
- Managed Pricing (Monetization > Managed Pricing tab) bundles price optimization and regional pricing; new games/items enrolled by default; regional prices stay 30%-100% of default; hard-coded prices must be fixed before opt-in — [Managed pricing](https://create.roblox.com/docs/en-us/production/monetization/managed-pricing); DevForum announcement [Managed Pricing](https://devforum.roblox.com/t/managed-pricing-one-system-for-better-pricing-and-earnings-growth/4684738) (not fetched); regional pricing launched April 2025 — [Roblox newsroom](https://corp.roblox.com/newsroom/2025/04/roblox-launches-regional-pricing-for-in-experience-items)
- Eligibility: about 60,000 transactions in the previous 30 days "in most cases"; tests take ~3 weeks, run automatically at least every 90 days; users split into groups seeing different prices; during review period 98% see tested prices, 2% original — [Price optimization](https://create.roblox.com/docs/en-us/production/monetization/price-optimization)
- Prices must be read through MarketplaceService (not hard-coded in UI); "Dynamic price check" with up to 5 test accounts verifies this; subscriptions can't be optimized; optimized prices applied only if "positive incremental total revenue" — [Price optimization](https://create.roblox.com/docs/en-us/production/monetization/price-optimization)
- Item-level price recommendations (increase/decrease/keep + approximate revenue impact) — [Price optimization](https://create.roblox.com/docs/en-us/production/monetization/price-optimization); [DevForum](https://devforum.roblox.com/t/price-optimization-now-includes-item-level-price-recommendations/3894427)

### Inferences
- For a small game (<1,000 DAU), Experiments will rarely reach significance except on big-effect changes (e.g. onboarding overhaul affecting D1); prefer thumbnail personalization (works on impressions, available at any scale with 2+ thumbnails) and before/after comparisons with benchmarks.
- Even without price-test eligibility, writing prices via MarketplaceService now future-proofs for Managed Pricing/regional pricing.
- Experiments require the game to be built around Configs; moving tunable values (rewards, prices, onboarding variants) into Configs early is cheap and enables live tuning.

### Gaps
- Exact eligibility for the Experiments feature itself (e.g. minimum DAU to create one) was not stated beyond the <1,000 DAU warning.
- No Roblox-published per-game sample-size tables; MDE is computed in-UI.
- No separate "thumbnail experiment" (fixed A/B) product found beyond personalization.

## 3. Which metrics matter most for discovery, how to read them, diagnosing a fading spike

### Takeaway
Since June 2026, Recommended For You ranks on a 28-day view of long-term retention. Top signals: Home play-through rate, first-play bounce (<60 s and 61-180 s), play days per user (D1, D2-7, D8-28), and playtime per user (capped 60 min/day); secondary: intentional co-play days, qualified play sessions, spend days, Robux per user. Only organic Home users count in ranking. A fading spike almost always shows falling play-through/play-days/playtime and rising first-play bounce before impressions drop.

### Cited Findings
- June 15, 2026: RFY moved from a 7-day to a "28-day view that directly measures long-term retention"; 7-day proxies "overvalued short-term engagement" favoring eye-catching thumbnails; the old qualified play-through rate signal was split into separate play-through, session-quality and spend signals; full signal list now shared with creators and shown in the analytics dashboard — [Roblox newsroom, 2026-06-15](https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox)
- Most important signals: Play-through rate (how often users who see the game in RFY play it); First-play bounce rate (negative; <60 s and 61-180 s); Play days per user (D1, D2-7, D8-28); Playtime per user (capped 60 min per user per game per day). Important: Intentional co-play days per user; Qualified play sessions per user; Spend days per user; Robux spent per user — [Discovery docs](https://create.roblox.com/docs/en-us/discovery)
- All signals are per-user averages (not totals) so smaller games aren't disadvantaged; ranking uses only users who joined organically from RFY — ads, curation, friends, search, social traffic help a game enter consideration but don't count in ranking — [Discovery docs](https://create.roblox.com/docs/en-us/discovery)
- Two stages: Retrieval then personalized Ranking; "explore and expand" tests a game with new cohorts and expands to similar cohorts if engagement/monetization is strong — [Discovery docs](https://create.roblox.com/docs/en-us/discovery)
- Impressions vary with your updates, algorithm changes, total Home traffic and seasonality (weekly peak Saturdays, summer, back-to-school, holidays), and competitors — [Discovery docs](https://create.roblox.com/docs/en-us/discovery)
- "Impression drops usually follow drops in play-through rate, play days, and playtime, along with a rise in first-play bounce rate"; a temporary play-through drop is normal when impressions rise during discovery — [Discovery docs](https://create.roblox.com/docs/en-us/discovery)
- Exposure limiters: titles implying giveaways/Robux, mismatched metadata, near-clone games; Creator Dashboard shows a reduced-exposure banner, reassessed every content update — [Discovery docs](https://create.roblox.com/docs/en-us/discovery)
- Older info (pre-June 2026): thumbnail personalization and dashboards used "qualified play-through rate" as the core acquisition signal — [Thumbnails docs](https://create.roblox.com/docs/en-us/production/publishing/thumbnails)
- Monetization KPIs in dashboard: payer conversion rate, ARPPU, ARPDAU, revenue, with similar-game benchmarks (50th-90th percentile) — [Analytics dashboard](https://create.roblox.com/docs/en-us/production/analytics/analytics-dashboard)

### Inferences
- Diagnosis checklist for a spike that fades: (1) Acquisition: was the spike organic Home (counts) or ads/friends/social (doesn't count toward ranking)? (2) Home Recommendations tab: did play-through rate fall and first-play bounce (<60 s / 61-180 s) rise in the new cohort? → thumbnail/title mismatch or slow/confusing first minute. (3) Onboarding funnel: where did the spike's cohort drop vs. normal cohorts? (4) Retention filtered by "when user first played" = spike days: did D1 and D2-7 play days hold? (5) Playtime per user and co-play: is there a reason to come back with friends? (6) Check performance telemetry by version (crashes/memory on mobile) and seasonality (Saturday peaks) before concluding.
- With the 28-day window, the D8-28 return behaviour now matters; daily rewards, streaks, updates cadence and social features carry more weight than first-session hooks alone.
- Playtime is capped at 60 min/day, so pushing beyond ~1 hour/day sessions doesn't help ranking; more return days do.

### Gaps
- Roblox doesn't publish signal weights or numeric "good" thresholds; benchmark bands in-dashboard are the only official reference.
- Couldn't fetch the companion DevForum post detailing the June 2026 signal list.

## 4. Practical weekly analytics routine and post-update analysis

### Takeaway
Roblox's own guidance is: fix retention, engagement and monetization first, then drive acquisition, then check metrics after every update; no official weekly checklist exists, so the routine below is synthesized from the docs' tools.

### Cited Findings
- Recommended order: optimize retention, engagement, monetization → then drive new user acquisition → check metrics after each update — [Analytics overview](https://create.roblox.com/docs/en-us/production/analytics)
- Start with KPIs for overall health, then pick an area to improve — [Analytics essentials](https://create.roblox.com/docs/en-us/production/game-design/analytics-essentials)
- Explore's period-over-period overlay (e.g. 28-day offset) and 7-day moving average help compare before/after an update; Insights flags big moves in DAU/new users/revenue — [Analytics dashboard](https://create.roblox.com/docs/en-us/production/analytics/analytics-dashboard); [Analytics overview](https://create.roblox.com/docs/en-us/production/analytics)
- Performance telemetry (crash rate, memory, CPU, FPS) broken down by game version — useful immediately after updates — [PocketGamer.biz, 2026-09-15](https://www.pocketgamer.biz/roblox-expands-analytics-tools-with-real-time-alerts-and-player-targeting/)
- Saturdays are the weekly traffic peak — compare same weekday to same weekday — [Discovery docs](https://create.roblox.com/docs/en-us/discovery)
- Upload new thumbnails with each major update and keep them until the next one — [Thumbnails docs](https://create.roblox.com/docs/en-us/production/publishing/thumbnails)
- Funnel step renames show a warning; set date ranges to include the change — [Funnel events](https://create.roblox.com/docs/en-us/production/analytics/funnel-events)

### Inferences (suggested routine for a solo dev)
- Weekly (30-45 min, same day each week, e.g. Monday):
  1. Overview/Insights: DAU, new users, revenue vs. last week (7-day MA).
  2. Acquisition > Home Recommendations: impressions, play-through, first-play bounce, play days, playtime per user vs. benchmark band.
  3. Retention: D1/D7 (and D30) for cohorts first played this week vs. prior weeks.
  4. Onboarding funnel: biggest single drop step → that is next week's fix.
  5. Monetization: payer conversion, ARPDAU, ARPPU; shop funnel drop-off; economy sinks/sources and average wallet (inflation check).
  6. Performance by version: crash rate/memory on mobile.
  7. Thumbnail Performance table.
  8. Write a 3-line log: what changed, what moved, next action.
- After each update: tag the version; check View Events within an hour that events still fire; check crash/error reports on day 0-1; compare D1 of the post-update cohort after 2 days and D7 after 8 days to the previous 2-3 cohorts; avoid shipping other changes during an Experiment; give changes ~1-2 weeks before judging discovery effects.
- One change at a time where possible, so before/after comparisons are interpretable when the game is too small for Experiments.

### Gaps
- No official Roblox weekly routine, RDC talk transcript, or developer case study with concrete numbers was retrieved within budget (Uplift Games/Adopt Me! is named as an Experiments user without numbers — [PocketGamer.biz](https://www.pocketgamer.biz/roblox-expands-analytics-tools-with-real-time-alerts-and-player-targeting/)).

## 5. External tools and privacy rules

### Takeaway
GameAnalytics still offers a free Roblox SDK (GitHub/Wally/Toolbox) that requires HttpService and server init with game/secret keys; it adds things like custom dimensions and remote configs, but built-in AnalyticsService now covers most solo-dev needs without HTTP or third-party data sharing. Privacy: avoid sending personal info off-platform; GameAnalytics offers a switch to disable submission for GDPR.

### Cited Findings
- GameAnalytics Roblox SDK: install from GitHub (https://github.com/GameAnalytics/GA-SDK-ROBLOX), Wally (`wally install gameanalytics`) or Toolbox; requires enabling HTTP requests; init with `GameAnalytics:initServer(gameKey, secretKey)`; whitelists for custom dimensions 01-03, currencies, item types, gamepasses (max 20 values each); games blocked if they submit too many unique dimension values; `setEnabledEventSubmission(false)` for GDPR — [GameAnalytics docs](https://docs.gameanalytics.com/event-tracking-and-integrations/sdks-and-collection-api/game-engine-sdks/roblox)
- GameAnalytics docs page shows no version/date and contains outdated/typo'd sample code (e.g. `ReplicationStorage`, `StarerPlayerScripts`), so maintenance status is unclear — [GameAnalytics docs](https://docs.gameanalytics.com/event-tracking-and-integrations/sdks-and-collection-api/game-engine-sdks/roblox)
- Built-in sales data already includes Buyer User ID and requires 2SV with an authenticator app to download — [Analytics dashboard](https://create.roblox.com/docs/en-us/production/analytics/analytics-dashboard)

### Inferences
- For a solo dev in 2026, start with built-in AnalyticsService (free, no HTTP, no extra privacy surface, feeds the same dashboards Roblox uses); add GameAnalytics only if you need raw event export or features not in Creator Hub.
- When using any external service: send only UserId (not usernames/display names or chat text), never collect off-platform contact info, and keep keys server-side (ServerScriptService / Secrets). This follows general Roblox rules against sharing PII but specific clauses were not verified.

### Gaps
- Could not retrieve and verify the exact Roblox Terms of Use / Community Standards clauses on developers sending user data to third-party analytics; the GameAnalytics example using `player.DisplayName` as custom user ID should be treated cautiously.
- Pricing/limits of GameAnalytics free tier not confirmed.
