# Onboarding, Retention, Engagement and Live Ops for Roblox Experiences (2025-2026)

Scope: a practical fact base for a solo developer of kids' simulator games. Research date: 2026-10-28. Official Roblox Creator Hub docs are the main source. Third-party benchmark numbers are flagged as vendor data.

## 1. What benchmarks does Roblox publish (D1/D7/D30, session time, playtime), and what counts as good for simulators?

### Takeaway
Roblox does not publish fixed "good" numbers. Its Creator Hub benchmark scorecards compare each game to "similar experiences" (games your players also play) or to its genre. The scorecards need 100+ DAU and update daily. Roblox says to put D1 retention and average session time first, and to reach benchmark level before spending on traffic. Third-party data puts simulator D1 at about 32%, D7 at about 14% and D30 at about 6% for promoted games. Community rules of thumb set the minimum at 10% D1 and 8 minutes per session.

### Cited Findings
- Roblox says D1 retention and average session time "are key metrics to focus on first." D7 and D30 show long-term progress and return visits. — [Roblox Creator Docs: Analytics](https://create.roblox.com/docs/production/analytics.md)
- On Analytics Home, D1 retention is the share of new users who played again after their first session ended. Session time is total playtime divided by the number of sessions per day. — [Roblox Creator Docs: Analytics](https://create.roblox.com/docs/production/analytics.md)
- Roblox advises getting retention, engagement and monetization "comparable to or above" the benchmarks of similar games before driving heavy new-user traffic. Benchmark scorecards need at least 100 DAU and update daily. They are a point of comparison only and are not a direct discovery signal. — [Roblox Creator Docs: Analytics](https://create.roblox.com/docs/production/analytics.md)
- After each update, Roblox suggests checking D1 and D7 retention and average session time. "Insights" flags large movements in key metrics. A watchlist can track up to 9 other games. — [Roblox Creator Docs: Analytics](https://create.roblox.com/docs/production/analytics.md)
- October 16, 2025 update: creators can switch benchmarks between "Similar experiences" (other games your users play) and "Genre." Benchmarks "don't affect your recommendation impressions." — [DevForum announcement](https://devforum.roblox.com/t/analytics-view-retention-by-acquisition-source-and-select-your-benchmark-set/4010157)
- The same update added D1/D7/D30 retention broken down by acquisition source. Users from "Other" sources (e.g. external links) had much lower D1 than users from Home Recommendations, so a change in traffic mix can lower overall D1 even when the game hasn't changed. Roblox also lists updates, seasonality and other games' performance as causes of retention swings. Home Recommendations use "6 key signals." — [DevForum announcement](https://devforum.roblox.com/t/analytics-view-retention-by-acquisition-source-and-select-your-benchmark-set/4010157)
- Scorecards use red/yellow/green coding, which Roblox restored after developers asked. Developers complained that yellow for slightly below-average results hides problems. One developer reported signals above the 90th percentile on 4 metrics but little algorithmic boost. — [DevForum thread replies](https://devforum.roblox.com/t/analytics-view-retention-by-acquisition-source-and-select-your-benchmark-set/4010157)
- Vendor benchmarks (BLOXG, "850+ promoted games," updated March 2026, no methodology disclosed): Simulator D1 32% / D7 14% / D30 6.2%; Tycoon 30/12/5.1; RPG 35/16/7.8; Obby 18/6/1.9; Horror 22/8/2.8; Social/Hangout 24/13/6.0; FPS 26/11/4.5; Adventure 27/10/3.8. No session-length data. Treat as indicative only. — [BLOXG retention benchmarks](https://bloxg.com/statistics/roblox-retention-benchmarks)
- DevForum rule of thumb, from an experienced replier: aim for at least 10% D1 and at least 8 minutes average playtime. A game with 2.3% D1 and about 3-minute sessions was told to stop paying for sponsored ads until those numbers improve. — [DevForum: Suggestions to improve average session time & D1](https://devforum.roblox.com/t/suggestions-to-improve-average-session-time-day-1-retention/2935525)
- Roblox's monetary incentives reward retention and session length. Under Creator Rewards (from July 24, 2025), a game earns 5 Robux per day for each Active Spender (spent at least $9.99 in the past 60 days) who plays it 10+ minutes as one of their first 3 games that day. Audience Expansion pays a 35% share of a new or reactivated user's first $100 of purchases within 60 days. The user's first session must last 10+ minutes, and the game must average 100+ DAU. These replace Engagement-Based Payouts. — [Roblox Creator Docs: Creator Rewards](https://create.roblox.com/docs/creator-rewards)

### Inferences
- Practical targets for a small kids' simulator: at least 10% D1 and 8+ minutes per session as a floor. Aim for 20-30%+ D1 to compete with established simulators. The 32% simulator figure comes from promoted games, a selected sample, so it is probably optimistic for a new game.
- 10 minutes is a key session threshold because Creator Rewards (both types) only pay for sessions of 10+ minutes. Design the first session so most new players get past 10 minutes.
- Before reading a D1 change as a game problem, check the retention-by-source breakdown, since external-link traffic (e.g. TikTok, Discord) retains worse.

### Gaps
- Roblox does not publish absolute percentile values (e.g. "50th percentile simulator D1 = X%") in its docs. These are visible only inside each creator's dashboard.
- No official or reliable public benchmark for simulator average session time or "stickiness" (DAU/MAU) was found.

## 2. First-time user experience (FTUE) best practices

### Takeaway
Roblox's official guidance is to teach through the world, not through text. Use visual highlights, directional trails, contextual tutorials triggered by play, and timed hints shown only to stuck players. Get to the core action in seconds, and use onboarding funnel events to find the single biggest drop-off.

### Cited Findings
- Roblox's three core onboarding techniques are visual elements (prominence, highlights, hints, feedback), contextual tutorials (triggered by normal play, such as entering a zone or picking up an item) and timed hints (shown only after a player is stuck). — [Roblox Docs: Onboarding techniques](https://create.roblox.com/docs/en-us/production/game-design/onboarding-techniques.md)
- Drop-off causes Roblox names:
  - not understanding what to do in the first few minutes
  - long, prescriptive tutorials
  - too much to learn early
  - text prompts players overlook or skip
  - text too small on mobile
  - young players still learning to read
  - fixed tutorial sequences that restrict choice
  - hints that arrive too late
  - missing feedback, which makes players think the game is buggy
  — [Roblox Docs: Onboarding techniques](https://create.roblox.com/docs/en-us/production/game-design/onboarding-techniques.md)
- Hint timing example from the docs: most playtesters press "PLANT CABBAGE SEED" within 10 seconds, so the highlight appears at 11 seconds. Roblox suggests using Experiments to A/B test hint delays (e.g. 5 vs 10 seconds) and Configs to push the winning value live without restarting servers. Show each timed hint only once, and only to players who need it. Use timed hints for overlooked features, e.g. a trade button that goes unused in a player's first two sessions. — [Roblox Docs: Onboarding techniques](https://create.roblox.com/docs/en-us/production/game-design/onboarding-techniques.md)
- Named examples:
  - Hello Kitty Cafe: dims the screen, spotlights the button, adds an arrow and pink outline, and uses a directional trail.
  - Jailbreak: footprints hint at escape routes.
  - Squishmallows: a contextual tutorial for combining 3 identical items appears when the player first holds 2 of them.
  - Color or Die: a sign explains the core mechanic when the player collects the first paint bucket.
  - Winds of Fortune: rich combat feedback (hit VFX, damage numbers, coin rewards).
  — [Roblox Docs: Onboarding techniques](https://create.roblox.com/docs/en-us/production/game-design/onboarding-techniques.md)
- Funnel API: `AnalyticsService:LogOnboardingFunnelStepEvent(player, stepNumber, stepName)`.
  - Server-only and published-games-only.
  - Each step counts only the first time it is reached. Skipping a step auto-completes the earlier steps.
  - Filters apply only to step 1.
  - Saved progress expires after 180 days of inactivity.
  - Up to 10 funnel tabs.
  - Results can be broken down by age, gender, OS and custom fields.
  - Validate client-sent step numbers on the server to stop exploiters.
  - Example: log step 1 on `PlayerAdded` ("Player Joined").
  — [Roblox Docs: Funnel events](https://create.roblox.com/docs/production/analytics/funnel-events.md)
- Roblox's example funnel lost about 70% of users between step 1 "In Farm" and step 2 "Plant Seed." The suggested fixes were contextual indicators pointing to the seed and positive feedback that requires planting before exploring. Roblox's advice is to start with the onboarding flow, "where most users are typically lost," and fix the largest drop-off first. — [Roblox Docs: Funnel events](https://create.roblox.com/docs/production/analytics/funnel-events.md)
- If a benchmark scorecard shows weak session time and D1, Roblox recommends funnel analytics to improve onboarding. — [Roblox Docs: Analytics](https://create.roblox.com/docs/production/analytics.md)
- Opinion piece (RoWatcher, August 2026, unsourced vendor view): drop-off concentrates in the first 90 seconds. Common mistakes are loading-screen lore, control dumps, gated first actions, explaining a mechanic before the player experiences it, and unskippable NPC dialogue. It cites Adopt Me! putting the player in charge of a baby right away with no tutorial. — [RoWatcher](https://rowatcher.com/news/your-first-90-seconds-are-destroying-roblox-retention)
- DevForum simulator-specific advice for a low-D1 game:
  - classic simulator UI with currency on the side
  - bright colors, because grey lobbies put off young players
  - a physical shop in the lobby that shows rewards to work toward
  - easier maps, since most players are on mobile
  - shorter respawn delays
  - activities while waiting
  - playtests with friends where you don't explain the game
  — [DevForum](https://devforum.roblox.com/t/suggestions-to-improve-average-session-time-day-1-retention/2935525)

### Inferences
- Suggested simulator funnel steps: 1 Joined → 2 First click/collect → 3 First sell/currency earned → 4 First upgrade/purchase → 5 First pet/egg → 6 First rebirth or new zone → 7 Reached 10 minutes. The 10-minute step matches the Creator Rewards threshold.
- Kids are often pre-literate or reading in a second language, so arrows, glow, trails and spotlights beat text. This is directly supported by the docs.

### Gaps
- No official Roblox statistic on how load time affects drop-off was found. No numeric "time to first action" target from Roblox beyond the roughly 10-second hint example.
- No first-party postmortems from top simulators with funnel numbers were found.

## 3. Retention mechanics that work, and what is manipulative or against Roblox rules

### Takeaway
Roblox's own docs endorse quests and dailies, achievements, season passes, collections (pets and their variants), limited-time and seasonal content, experience notifications, and referral rewards. Hard rules exist for paid random items: odds must be disclosed, and regional restrictions apply. Notifications must not use false time pressure, disguised ads or bait-and-switch.

### Cited Findings
- Roblox's game-design docs list quest design ("quests, achievements, and dailies to increase engagement and retention") and season passes ("deliver new content, promote retention, and generate revenue"). — [Roblox Docs: Game design](https://create.roblox.com/docs/production/game-design.md)
- Major-update categories that drive repeat visits:
  - social: guilds, trading, parties
  - competitive: PvP, leaderboards, tournaments
  - collections and achievements: collectible pets, season passes for short-, mid- and long-term goals
  - live events
  — [Roblox Docs: LiveOps essentials](https://create.roblox.com/docs/en-us/production/game-design/liveops-essentials.md)
- Limited-time content should be available to all players during the event, with objectives that "take most players weeks" to finish. Add permanent content at the end of progression for high-level players. — [Roblox Docs: Content updates](https://create.roblox.com/docs/en-us/production/game-design/content-updates.md)
- Grow a Garden's breakout hook, per its developer: persistent offline growth. Players come back to find plants bigger and fruit grown. Jandel calls this novel for Roblox. — [GamesBeat interview, ~July 2025](https://gamesbeat.com/janzen-madsen-interview/)
- DevForum advice: playtime rewards at milestones (e.g. 10, 20 and 60 minutes), daily login rewards, and a visible leaderboard of about 10 players. — [DevForum](https://devforum.roblox.com/t/suggestions-to-improve-average-session-time-day-1-retention/2935525)
- **Experience notifications** (Open Cloud):
  - Eligibility: 100+ visits and no moderation issues.
  - Limits: 1 notification per user per day per experience, plus an aggregate daily cap per user. Delivery is not guaranteed; reach scales with engagement.
  - Opt-in: `PromptOptIn()` shows only to users 13+, with fixed text, at most once every 30 days. Call `CanPromptOptInAsync()` in a `pcall`. Gameplay must not require opting in.
  - Message rules: 99 characters max, personalized to the recipient's in-game activity, and prompting an immediate action. Prohibited: disguised ads, **false time pressure**, bait-and-switch free rewards, and tricking users into purchases.
  - Launch data: up to 200 bytes, read with `GetJoinData`.
  - Analytics: CTR, turn-off rate and dismiss rate, shown after 100 impressions.
  - Under-13 users receive only experience update notifications.
  — [Roblox Docs: Experience notifications](https://create.roblox.com/docs/production/promotion/experience-notifications.md)
- **Paid random items** (eggs, crates, spins bought with Robux or Robux-purchasable currency, including indirect keys or tickets):
  - Show all outcomes with exact percentage odds before purchase. A bare (i) icon without a descriptive word is not enough.
  - Luck boosts and pity systems must state their numeric effect, and displayed odds must update while they are active.
  - Odds must update for one-time outcomes the player already owns.
  - Random rewards earned purely through gameplay need no disclosure.
  - Check `PolicyService:GetPolicyInfoForPlayerAsync()` for `ArePaidRandomItemsRestricted` and `IsPaidItemTradingAllowed`, and offer alternatives (free path, direct purchase, block) in restricted regions.
  - Restricted users may not trade paid-item outcomes.
  — [Roblox Docs: Paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items.md)

### Inferences
- For a kids' simulator, the safe, proven stack is: daily login streak, playtime gifts at 5/10/20/30/60 minutes, daily and weekly quests, pet/egg collection with an index, rebirth/prestige, offline earnings (the Grow a Garden style "come back to progress"), and global leaderboards. Most of this comes from general F2P practice; Roblox docs directly endorse quests, dailies, season passes, collections and leaderboards.
- Most of a kids' audience is under 13 and cannot be prompted to opt in to notifications. Notifications therefore mainly reach teen and older players, and in-game return hooks (offline earnings, streaks) matter more.
- Avoid fake countdowns, "free reward" bait, and paid eggs with undisclosed odds. The first two are explicitly banned in notifications; undisclosed odds break the paid random items policy.

### Gaps
- Could not fetch the Roblox quest-design doc page (fetch error). No numeric Roblox data on how much daily rewards or streaks lift retention.
- No official Roblox document found that broadly lists "dark patterns" beyond the notification rules and paid random items policy.

## 4. Live ops: update cadence, what makes updates succeed, event design

### Takeaway
Roblox recommends a sustainable cadence: weekly to monthly, commonly every 2-4 weeks, with each cadence update under about 3 weeks of work and built on existing systems. Top 2025 games ran weekly updates plus weekend "Admin Abuse" events, producing huge concurrency spikes. Grow a Garden found weekly events became repetitive and shifted toward fewer, deeper features.

### Cited Findings
- Cadence content ranges from weekly to monthly depending on team capacity. Major updates can take months. QoL and bug fixes ship as needed. Protect team wellbeing and keep the frequency realistic. — [Roblox Docs: LiveOps essentials](https://create.roblox.com/docs/en-us/production/game-design/liveops-essentials.md)
- "Many games release cadence updates every two weeks to one month." Keep each under "three weeks' effort." Reuse existing systems, since new systems turn the update into an expansion. The easiest content is simple variants (e.g. recolors). Build each update around a theme. Seasons and holidays are good sources, but choose themes your audience likes. Examples: Adopt Me! pet variants and themed updates, Jailbreak's season pass. — [Roblox Docs: Content updates](https://create.roblox.com/docs/en-us/production/game-design/content-updates.md)
- Grow a Garden went from about 500 CCU to about 100k CCU in 2 weeks and about 1M in roughly a month under Splitting Point's live service with "weekly updates." It peaked at 22.3M CCU and about 60M peak DAU. — [GamesBeat interview, ~July 2025](https://gamesbeat.com/janzen-madsen-interview/)
- Grow a Garden ran weekly Saturday updates, each with an in-game event. In August 2025 players were down about 400k week-over-week and the community said updates felt repetitive. Jandel said the weekly event cycle made events hard to keep fresh and squeezed out bug fixes and depth, so the game moved toward a feature-driven approach with more QoL and fewer one-off events. — [Roonby, Aug 11 2025](https://roonby.com/2025/08/11/grow-a-garden-might-not-be-getting-weekly-updates-anymore/)
- Admin Abuse events: players online during set (weekend) windows get limited items from admins. Earlier weekend events pushed Grow a Garden and Steal a Brainrot to about 15M CCU each against a daily norm of about 1M.
  - The August 23, 2025 "Admin War" was hyped for a week on TikTok, X and Discord, with a charity wager.
  - Steal a Brainrot set a 20M record; Grow a Garden hit 21.1M (its record was 21.6M); Roblox overall hit a record 47.4M concurrent.
  - Both games returned to about 1M afterwards.
  — [Tubefilter, Aug 25 2025](https://www.tubefilter.com/2025/08/25/roblox-grow-garden-steal-brainrot-admin-war-record/)
- Use Discord and groups to gather feedback, and focus on the reasoning behind player requests. QoL targets: UI/UX, aesthetic refresh, accessibility, performance. — [Roblox Docs: LiveOps essentials](https://create.roblox.com/docs/en-us/production/game-design/liveops-essentials.md)

### Inferences
- A sustainable solo plan is a small themed content drop every 2 weeks (new pets, zone or eggs reusing existing systems), a bigger feature monthly, and a scheduled weekend live event with a public countdown and limited items. "Admin abuse"-style scheduled events mainly create spikes rather than lasting retention, since CCU returned to baseline.
- Players expect a fixed update time (Grow a Garden used Saturdays). Common Roblox practice, not sourced here, is to tag updates in the game title (e.g. "[UPDATE]") and show an in-game update log.

### Gaps
- No official Roblox data found on the effect of title tags ([UPDATE], emojis) on traffic, or on countdowns. These are community conventions; mark them as unverified.
- No sourced Pet Simulator 99, Blox Fruits or Adopt Me cadence data was retrieved.

## 5. Social features that raise retention

### Takeaway
Roblox's own data shows co-play sessions are about 1.9x longer than solo sessions. Roblox now ships Party (up to 6 friends join together) and a Friend Referral System with tracked rewards, so friend invites, friend boosts and co-op are the best-evidenced social levers. Roblox docs also list trading, guilds and parties as retention-driving major updates.

### Cited Findings
- Sessions where users play with friends average 1.9 times longer than solo sessions (Roblox data, Q2 2024/June 30, 2024). — [DevForum: Party announcement, Dec 2024](https://devforum.roblox.com/t/party-is-here-unlock-a-new-level-of-engagement/3282068); [DevForum: Friend Referral System, Apr 2025](https://devforum.roblox.com/t/announcing-the-new-friend-referral-system-for-your-experiences/3623795)
- Party: up to 6 friends join the same server together and can move between experiences. Under-13s can join but cannot use Party chat. A Party API (who is in the same party, for matching visuals, team placement, group teleports) was slated for early 2025. — [DevForum: Party](https://devforum.roblox.com/t/party-is-here-unlock-a-new-level-of-engagement/3282068)
- Friend Referral System (fully released April 23, 2025):
  - Tracks the inviter through `Player:GetJoinData().ReferredByPlayerId`.
  - Configurable reward banner in Creator Hub under Engagement > Referral Rewards, with optional limits (e.g. 3 rewards per inviter).
  - Invites can go to non-friends and off-platform; links never expire. Requires the game to have been live for at least 1 day.
  - Recommended abuse prevention: one-time rewards, cooldowns, DataStore tracking.
  - Known issue: `ReferredByPlayerId` returns 0 in reserved servers.
  — [Roblox Docs: Referral system](https://create.roblox.com/docs/production/promotion/referral-system); [DevForum announcement](https://devforum.roblox.com/t/announcing-the-new-friend-referral-system-for-your-experiences/3623795)
- Pet Simulator 99 has an "Invite Friends" reward, raised to 1,000,000 Diamonds with an Area 99 requirement (Feb 2024, fan news account, not official). — [PetSimNews on X](https://x.com/PetSimNews69/status/1761954932222017592)
- Roblox lists guilds, groups, trading and parties as social major updates that encourage collaboration and repeat visits. — [Roblox Docs: LiveOps essentials](https://create.roblox.com/docs/en-us/production/game-design/liveops-essentials.md)
- Creator Rewards' Audience Expansion pays creators for new or reactivated users who arrive through Share Links, links or search, which gives a direct financial reason to build invite loops. — [Roblox Docs: Creator Rewards](https://create.roblox.com/docs/creator-rewards)
- Trading must respect `IsPaidItemTradingAllowed`: restricted users may not trade outcomes of paid random items. — [Roblox Docs: Paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items.md)

### Inferences
- For a kids' simulator, implement: (1) a friend boost (e.g. +10% per friend in the server, a common simulator convention; this number is not from a source), (2) referral rewards for both inviter and invitee using `ReferredByPlayerId`, (3) co-op or shared goals so parties have a reason to play together, and (4) trading only with policy checks and anti-scam UI.

### Gaps
- No public Roblox data on the retention lift from trading or guilds specifically. No numeric data on referred-user retention.
- Could not verify Party API method names from these sources.
