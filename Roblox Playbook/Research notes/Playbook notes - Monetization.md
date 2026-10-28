# Roblox Monetization (2025–2026) for a Solo Developer of Kids' Simulator Games

Research date: 2026-10-28. Official sources were preferred: Creator Hub docs, DevForum announcements and the Roblox newsroom. Third-party sources are labelled as such.

## 1. Revenue streams, Roblox's cut, DevEx, and holds

### Takeaway
The main income for a simulator is still in-game sales: passes and developer products pay the creator 70%. On top of that there are now Subscriptions (70% in month 1, then 100% for local-currency subscriptions), Creator Rewards (which replaced Premium/Engagement-Based Payouts on 2025-07-24), rewarded video ads (13+ and ID-verified only), and avatar items. DevEx converts Earned Robux to USD at $0.0038 per Robux (since 2025-09-05), with a higher $0.0054 rate for spending by age-checked US adults. A kids' game will rarely earn that higher rate.

### Cited Findings
**Passes and developer products (the core streams)**
- Pass: "allows you to charge a one-time Robux fee" for special privileges (restricted-area access, avatar items, permanent power-ups). Developer product: an item that can be bought more than once (currency, ammo, potions). — [Creator Hub: Monetization](https://create.roblox.com/docs/en-us/production/monetization)
- The creator receives 70% of Robux sales of in-game items. Avatar items earn 70% when sold in-game and 30% on the Marketplace. Paid access earns up to 90% for real-money purchases. — [Creator Hub: Earn on Roblox](https://create.roblox.com/docs/production/earn-on-roblox)
- Platform scale figures from Roblox: 132M DAU averaging 2.6 h/day (Q1 2026). The top 1,000 creators averaged $1.3M in 2025 (+50% YoY). More than 35,000 creators are in DevEx, and the **median DevEx creator received $1,550** in the 12 months to 2025-12-31. — [Earn on Roblox](https://create.roblox.com/docs/production/earn-on-roblox)
- An academic critic (Prof. Marcus Carter, Univ. of Sydney) says Roblox takes "around 50 percent" of revenue generated on the platform once app-store and platform costs are counted. This is his characterisation, not Roblox's figure. — [Univ. of Sydney news, 2026-05-17](https://www.sydney.edu.au/news-opinion/news/2026/05/17/inside-the-pay-to-play-world-of-roblox-targeting-children-.html)

**Pending/escrow hold (sources conflict)**
- The Monetization page says: "There is a 30 day escrow hold for each purchase." — [Creator Hub: Monetization](https://create.roblox.com/docs/en-us/production/monetization)
- The Subscriptions page says Robux subscription earnings "follow the same hold as passes and developer products, about 5 days". — [Creator Hub: Subscriptions](https://create.roblox.com/docs/en-us/production/monetization/subscriptions). **CONFLICT:** the two official pages give different holds. Check the Creator Hub Finance tab.

**Subscriptions (launched 2023, current terms)**
- Local-currency price tiers: $2.99 / $4.99 / $7.99 / $9.99 / $14.99. Robux-priced subscriptions can be any amount of at least 49 Robux. — [Subscriptions](https://create.roblox.com/docs/en-us/production/monetization/subscriptions)
- Revenue share:
  - Local currency: 70% in the first month, then 100% each month after. Example: a $5 plan pays 350 Robux, then 500 Robux a month.
  - Robux subscriptions: 70% every month.
  - Both are paid out in Robux. — [Subscriptions](https://create.roblox.com/docs/en-us/production/monetization/subscriptions)
- Local-currency subscriptions need an ID- or phone-verified account and work only on Web, the App Store and Google Play. They are not available in Argentina, China, Colombia, India, Indonesia, Japan, Russia, Taiwan, Türkiye, UAE, Ukraine or Vietnam. Holds: 30 days for local currency, about 5 days for Robux. Robux subscriptions are non-refundable. — [Subscriptions](https://create.roblox.com/docs/en-us/production/monetization/subscriptions)
- Rules:
  - Maximum of 50 subscriptions per game.
  - Robux prices can change at most every 60 days, and a price increase needs 30 days' notice.
  - Don't make mutually exclusive Bronze/Silver/Gold tiers.
  - Give the same benefits on every platform and honour them for the full term.
  - Check status on the server with `GetUserSubscriptionStatusAsync` and `UserSubscriptionStatusChanged`. — [Subscriptions](https://create.roblox.com/docs/en-us/production/monetization/subscriptions)

**Creator Rewards (replaced Premium Payouts / Engagement-Based Payouts)**
- Announced 2025-06-24 and live 2025-07-24. It replaced Engagement-Based Payouts (the successor to Premium Payouts) and the Creator Affiliate program. — [DevForum: Introducing Creator Rewards](https://devforum.roblox.com/t/introducing-creator-rewards-earn-more-by-growing-the-community/3777628); [DevForum: Creator Rewards is Live](https://devforum.roblox.com/t/creator-rewards-is-live/3838257)
- **Daily Engagement Reward:** 5 Robux per "Active Spender" per day. The Active Spender must:
  - play your game for 10 or more minutes that day (summed across sessions);
  - have launched it as one of their first 3 experiences that day;
  - have spent at least $9.99 in the last 60 days (Robux, Premium or subscriptions).
  - Roblox says the amount "may change." — [DevForum announcement](https://devforum.roblox.com/t/introducing-creator-rewards-earn-more-by-growing-the-community/3777628); [Creator Hub: Creator Rewards](https://create.roblox.com/docs/en-us/creator-rewards.md)
- **Audience Expansion Reward:** a 35% revenue share on the first $100 a new or reactivated user (inactive 60+ days) spends anywhere on Roblox in their first 60 days. Conditions:
  - the user arrived through your direct link or by searching your game's name, and played for 10 or more minutes;
  - your game averages 100+ DAU over the 60 days;
  - your account is ID-verified (docs) and registered with Tipalti (announcement). — [Creator Rewards docs](https://create.roblox.com/docs/en-us/creator-rewards.md); [DevForum](https://devforum.roblox.com/t/introducing-creator-rewards-earn-more-by-growing-the-community/3777628)
- Both rewards are paid as Earned Robux after a **60-day hold**. Payouts are uncapped. Experiences with "unusually long session times may see reduced earnings," and rewards can be withheld when an account's chargeback rate is high. — [DevForum](https://devforum.roblox.com/t/introducing-creator-rewards-earn-more-by-growing-the-community/3777628)
- At RDC25, Roblox said 73% of eligible experiences earned more under Creator Rewards than under EBP, and the number of creators earning 5+ Robux rose 171%. — [DevForum: RDC25 What we announced](https://devforum.roblox.com/t/rdc25-what-we-announced/3920245)
- Developers have pushed back on the 60-day hold (DevForum thread). — [DevForum: Shorten the hold period…](https://devforum.roblox.com/t/shorten-the-hold-period-of-engagement-payouts-or-restore-the-old-premium-payouts-system/3956591)

**Rewarded video ads**
- Publisher requirements:
  - age 13+, 2FA on, ID verified;
  - game public and unrestricted, with no free-form user creation;
  - approved Maturity & Compliance Questionnaire;
  - **average of at least 2,000 unique visitors per month**. — [Creator Hub: Rewarded video ads](https://create.roblox.com/docs/production/promotion/rewarded-video-ads)
- Earnings = EPM × impressions / 1,000, and the first frame shown counts as an impression. Ads run 6–30 s. The recommended reward value is 3–10 Robux. The reward must be a developer product that is normally purchasable, and it "cannot be randomized items." — [Rewarded video ads](https://create.roblox.com/docs/production/promotion/rewarded-video-ads)
- API:
  - `AdService:GetAdAvailabilityNowAsync(Enum.AdFormat.RewardedVideo)` (returns `PlayerIneligible` for ineligible users, e.g. under-age players);
  - `CreateAdRewardFromDevProductId`;
  - `ShowRewardedVideoAdAsync`;
  - the reward is granted via `ProcessReceipt`. — [Rewarded video ads](https://create.roblox.com/docs/production/promotion/rewarded-video-ads)
- Placement advice: lobbies and menus, natural breaks (after a level, when out of lives or resources), 1–2-click prompts. The "Exclude likely purchasers" option exists. Availability was widened in 2025. — [Rewarded video ads](https://create.roblox.com/docs/production/promotion/rewarded-video-ads); [DevForum: More creators can now use RVA](https://devforum.roblox.com/t/more-creators-can-now-use-rewarded-video-ads/3838678)

**DevEx (cash-out)**
- Rates:
  - Standard: **$0.0038 per Earned Robux** ($114 per 30,000).
  - Legacy: $0.0035 for Earned Robux balances held before **2025-09-05 10:00 PT**. Those are paid at the old rate until used up.
  - Higher: **$0.0054** for certain pass, product, subscription and private-server earnings from **US players aged 18+ who are age-verified**, in eligible experiences. — [Creator Hub: Developer Exchange](https://create.roblox.com/docs/de-de/production/monetization/developer-exchange)
- The 42% boost for spending by age-checked US 18+ players took effect June 8 (2026). It covers passes, Robux subscriptions, select items and private servers, and is tied to "eligible games" (R15-avatar games are mentioned). — [Roblox newsroom, 2026-04-30](https://about.roblox.com/newsroom/2026/04/roblox-fuels-high-fidelity-games-over-18-players-increases-qualifying-devex-rate-42)
- The move from $0.0035 to $0.0038 (+8.5%) was announced at RDC25 (Sept 2025). — [DevForum RDC25](https://devforum.roblox.com/t/rdc25-what-we-announced/3920245)
- Eligibility:
  - age 13+;
  - at least 30,000 Earned Robux;
  - verified email;
  - DevEx portal account;
  - W-9 (US) or W-8 (non-US) tax form;
  - compliance with the ToS and Community Standards.
- Process and limits:
  - Apply via Creator Hub → Finance → Cash Out. One application per calendar month.
  - First-time applicants must finish portal setup within one week.
  - Processing takes about 10 business days the first time and about 5 for returning applicants. — [Developer Exchange](https://create.roblox.com/docs/de-de/production/monetization/developer-exchange)
- Roblox said it was on track to pay out about $1B to creators in 2025. More than $1B was earned by creators in the 12 months to 2025-06-30. — [DevForum RDC25](https://devforum.roblox.com/t/rdc25-what-we-announced/3920245)

**Other streams**
- RDC25 also mentioned:
  - in-experience clothing and accessory sales (players buy avatar items inside games);
  - a licensed-IP catalog (Blue Lock, Polly Pocket and others);
  - Ads Manager improvements.
  - No revenue numbers were given. — [DevForum RDC25](https://devforum.roblox.com/t/rdc25-what-we-announced/3920245)
- "Commerce" (physical goods through native checkout) and Billboard ads are listed as streams, but no creator shares are stated. — [Earn on Roblox](https://create.roblox.com/docs/production/earn-on-roblox)

### Inferences
- In a kids' simulator most players are under 13. They cannot see rewarded ads, and their spending does not earn the $0.0054 adult rate. The practical streams are passes, developer products, Robux subscriptions and the Creator Rewards daily engagement reward.
- That reward pays 5 Robux × active spenders × days. At $0.0038 per Robux, that is about $0.019 per qualifying spender per day. Players returning every day matters more than raw visits.
- The Audience Expansion reward makes it worth encouraging players to share direct links. Off-platform promotion (YouTube, TikTok and similar) that brings new users in through a direct link earns 35% of their first $100 of spending.

### Gaps
- The hold for passes and products conflicts between official pages (30-day escrow vs about 5 days). Not resolved.
- No current official percentage for Marketplace/UGC item fees. The fees page (https://create.roblox.com/docs/en-us/marketplace/marketplace-fees-and-commissions) was not fetched.
- Rewarded-ad EPM values are not published publicly; they appear only in the dashboard calculator.

## 2. Price optimization, regional pricing and Managed Pricing

### Takeaway
As of **2026-06-15**, Roblox merged Regional Pricing (launched April 2025 for passes, later extended to developer products) and Price Optimization (A/B price testing) into **Managed Pricing**. It covers passes and developer products. Roblox reports average lifts of about 4–10% in Robux spend from regional pricing and about 4% from price optimization.

### Cited Findings
- **Regional pricing launch:**
  - April 2025 for in-experience items (passes first). — [Roblox newsroom, 2025-04](https://about.roblox.com/newsroom/2025/04/roblox-launches-regional-pricing-for-in-experience-items)
  - Then extended to developer products. — [DevForum: Regional Pricing for Developer Products](https://devforum.roblox.com/t/introducing-regional-pricing-for-developer-products/3971235)
- **Managed Pricing (announced 2026-06-15):**
  - Combines regional pricing and price optimization in a Managed Pricing tab under Monetization.
  - Tests run at least every 90 days; test groups see prices around the baseline for about 3 weeks.
  - A new price is adopted only if it shows positive incremental total revenue.
  - Creators are notified ahead (7 days per the announcement, up to 30 days per a staff reply, which is inconsistent) and can override or revert.
  - New games and items are auto-enrolled with an opt-out; existing items are opt-in.
  - Subscriptions and private servers are regionalized automatically.
  - No price linking between items; hard-coded prices must be removed.
  - Players aren't told when they are in a test. — [DevForum: Managed Pricing](https://devforum.roblox.com/t/managed-pricing-one-system-for-better-pricing-and-earnings-growth/4684738)
- **Reported results:**
  - Regional pricing: 4–10% average increase in overall Robux spend; 1–6% more players and playtime; 43–52% more pass purchases in discounted regions (top 2,500 games, 2025).
  - Price optimization: +4% average earnings for eligible creators; Slap Battles reported over +15%. — [DevForum: Managed Pricing](https://devforum.roblox.com/t/managed-pricing-one-system-for-better-pricing-and-earnings-growth/4684738)
- Docs: [Managed pricing](https://create.roblox.com/docs/en-us/production/monetization/managed-pricing), [Regional pricing](https://create.roblox.com/docs/en-us/production/monetization/regional-pricing), [Price optimization (older page)](https://create.roblox.com/docs/en-us/production/monetization/price-optimization.md)
- **Discount honesty (relevant to anchoring and limited offers):**
  - "A discount is not genuine if an item is always 'on sale'."
  - Very short discounts used to pressure players are unfair.
  - Don't claim false scarcity, and don't use countdown timers that are inaccurate or reset for the same item. — [Creator Hub: Monetization](https://create.roblox.com/docs/en-us/production/monetization)
- Official definitions:
  - Starter pack: "an initial offer … that a new user sees within the first few minutes."
  - Bundle: "a group of in-experience items packaged into a single purchasable item."
  - Season passes: offer free and premium tracks, with the premium track "a superset of the free pass rewards." — [Creator Hub: Monetization foundations](https://create.roblox.com/docs/en-us/production/game-design/monetization-foundations)

### Inferences
- **Price display:** prices shown in your UI must come from `MarketplaceService:GetProductInfo` (or the equivalent) rather than hard-coded Robux numbers. Otherwise regional and test prices won't display correctly, and Managed Pricing requires removing hard-coded prices.
- **Price anchoring:** "Was X, now Y" anchors are only fair if X was really charged for a meaningful period. The policy explicitly bans permanent fake "sales."

### Gaps
- No official or authoritative source gives typical Robux price points for simulator passes (2x, VIP, auto, extra slots, luck). Third-party guides exist (rolearn.dev, creation.dev, rowatcher.com) but could not be fetched or verified, so no numbers are reported.

## 3. What top simulators sell and benchmarks

### Takeaway
Roblox's official docs describe item categories, not specific simulator best-sellers, and publish **no** public conversion/ARPDAU/ARPPU benchmarks. Benchmarks are visible only inside Creator Analytics (peer benchmarks), so none could be verified.

### Cited Findings
- Roblox's taxonomy:
  - durable items (e.g. cosmetic skins) vs consumable items (temporary boosts);
  - enhancement items (speed, protection, event access) vs expression items (skins, emotes, **pets**).
  - Each item should have a clear purpose and an accurate description. — [Monetization foundations](https://create.roblox.com/docs/en-us/production/game-design/monetization-foundations)
- Probability modifiers (luck boosts, pity systems, rate-up scrolls) and capsules (eggs, chests, prize wheels) fall under the paid random items rules. This covers the egg-hatching and luck-pass staples of pet simulators. — [Paid random items](https://create.roblox.com/docs/en-us/production/monetization/paid-random-items)
- A University of Sydney study (2026-05-17) of 15 popular experiences found deceptive or misleading purchase design in 14 of them:
  - inflated "worth" prices and fake discounts;
  - loot-box mechanics;
  - prompts to spend after a loss and near-miss visuals;
  - false-urgency timers;
  - pay-to-progress.
  - The authors call for a regulatory probe. — [Univ. of Sydney](https://www.sydney.edu.au/news-opinion/news/2026/05/17/inside-the-pay-to-play-world-of-roblox-targeting-children-.html)

### Inferences
- Common simulator offers (2x currency, auto-farm, VIP, extra pet slots, luck, hatch speed) map onto Roblox's categories:
  - permanent passes = durable enhancement;
  - potions and boosts = consumable developer products;
  - pets = expression, random if from eggs.
- Luck passes and eggs carry the most compliance work: odds disclosure, odds that update while a boost is active, and handling for restricted regions.

### Gaps
- No verified public numbers for simulator conversion rate, ARPDAU or ARPPU. Roblox's peer benchmarks sit behind Creator Analytics logins.
- No developer postmortem with revenue figures for a simulator was found in this pass.

## 4. Store/shop UX that converts on mobile, offer timing and pay-to-win backlash

### Takeaway
Roblox's guidance:
- Make the shop easy to find and easy to leave.
- Explain each item's value against the alternatives.
- Rotate stock.
- Show offers at natural moments (lobby, after a level, when out of resources).
- For minors, use calm call-to-action wording instead of urgency wording.

### Cited Findings
- Shop design:
  - an easy-to-find shop icon consistent with your UI;
  - enter and exit without disruption;
  - context on each item and how it compares to other options;
  - "a place to linger and browse";
  - rotate content.
  - Think about the lobby and first-entry flow when deciding where offers appear. — [Monetization foundations](https://create.roblox.com/docs/en-us/production/game-design/monetization-foundations)
- Season-pass UX: preview rewards, show the time remaining and XP per level, space rewards to match average session length, and give the free track real rewards. — [Monetization foundations](https://create.roblox.com/docs/en-us/production/game-design/monetization-foundations)
- Wording with minors: replace "GET IT NOW" with "View Item," "LAST CHANCE, ACT NOW" with "See Price," and "BUY BEFORE IT'S GONE!" with "Open Shop." Promotions should be suitable for all audiences by default. — [Creator Hub: Monetization](https://create.roblox.com/docs/en-us/production/monetization)
- Rewarded-ad prompt UX: 1–2 clicks, a clear disclosure of what the player does and gets, offered at natural breaks; roll out new placements to a percentage of users first. — [Rewarded video ads](https://create.roblox.com/docs/production/promotion/rewarded-video-ads)

### Inferences
- **Fairness:** to avoid pay-to-win backlash, sell time savers and cosmetics that free players can also earn. This matches Roblox's "premium is a superset of free" season-pass model. Avoid prompting purchases right after a player loses, which the Sydney study flags.

### Gaps
- No official mobile-specific conversion data (button sizes, shop placement A/B results) was found.

## 5. Policies that limit monetization (random items, minors, advertising, deceptive practices, receipts)

### Takeaway
The hard requirements are:
- Disclose exact numeric odds (as percentages totalling 100%) for anything random bought directly or indirectly with Robux.
- Use `PolicyService` to block or change paid random items and trading for restricted users.
- No fake discounts, false scarcity or resetting timers.
- Grant purchases reliably through `ProcessReceipt`.

### Cited Findings
- **Odds disclosure:**
  - "You must indicate all possible outcomes and the actual numerical odds."
  - Odds are shown as percentages totalling 100%; rounding is allowed with a disclaimer.
  - The odds must be visible before purchase. A bare "(i)" icon is not enough; use an "Info"/"Details" button.
  - Odds must be shown before players spend *in-game currency* on random outcomes, because indirect purchases count.
  - Luck boosts must state their effect numerically, and the displayed odds must update while the boost is active.
  - Random rewards earned without paying need no disclosure. — [Paid random items](https://create.roblox.com/docs/en-us/production/monetization/paid-random-items)
- **Restricted users:**
  - `PolicyService:GetPolicyInfoForPlayerAsync()` returns `ArePaidRandomItemsRestricted`. When it is true, choose one of: provide a free earnable path, use a disclosed fixed order, sell specific outcomes at their expected value, hide the item, block the purchase with an error, or keep the user out of those areas.
  - `IsPaidItemTradingAllowed`: when false, players must not be able to trade paid or paid-random outcomes.
  - The docs page doesn't list which countries are restricted. — [Paid random items](https://create.roblox.com/docs/en-us/production/monetization/paid-random-items)
- **News (2026-06-26):** Korea's loot-box rules pushed Roblox to require odds disclosure worldwide. This is a secondary report. — [TechTimes](https://www.techtimes.com/articles/319148/20260626/koreas-loot-box-rules-push-roblox-disclose-item-odds-worldwide.htm)
- **Deceptive practices:**
  - "Users must never be misled, confused, or pressured into purchases in ways they did not intend."
  - No false "almost out of stock" or "limited time" claims.
  - No countdown timer "that isn't accurate or automatically restarts for the same item."
  - Use PolicyService to check eligibility by location, age and platform. — [Creator Hub: Monetization](https://create.roblox.com/docs/en-us/production/monetization)
- **Under-13 limits:**
  - Rewarded video ads require eligible viewers, so ineligible users get `PlayerIneligible`.
  - DevEx and ad publishing require the developer to be 13+.
  - The higher DevEx rate applies only to age-verified US adults. — [Rewarded video ads](https://create.roblox.com/docs/production/promotion/rewarded-video-ads); [DevEx](https://create.roblox.com/docs/de-de/production/monetization/developer-exchange)
- **Subscriptions conduct:**
  - Don't send users to other platforms to buy.
  - Don't require extra tasks (such as social posts) after payment.
  - Don't secretly revoke benefits. — [Subscriptions](https://create.roblox.com/docs/en-us/production/monetization/subscriptions)
- **Receipts:**
  - Rewarded-ad rewards and developer products are granted through `MarketplaceService.ProcessReceipt`. — [Rewarded video ads](https://create.roblox.com/docs/production/promotion/rewarded-video-ads)
  - The official guide on purchases with data stores: [Implement player data and purchasing systems](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing).
  - Store purchase data with DataStoreService. — [Monetization](https://create.roblox.com/docs/en-us/production/monetization)
- **Chargebacks:** a disproportionately high chargeback rate can lead to Creator Rewards being withheld. — [DevForum Creator Rewards](https://devforum.roblox.com/t/introducing-creator-rewards-earn-more-by-growing-the-community/3777628)

### Inferences
- **ProcessReceipt pattern (from the engine contract, not fetched in full this pass):**
  - Record the `PurchaseId` in the player's saved data so the same receipt is never granted twice.
  - Return `PurchaseGranted` only after the grant has been saved.
  - Otherwise return `NotProcessedYet` so Roblox retries.
  - Keep a single ProcessReceipt handler per server.
- **Kids' simulators:** the safe default for egg/luck mechanics is to also sell or award specific pets directly for restricted users, and to show the odds table on every egg stand.

### Gaps
- The exact list of countries where paid random items are restricted is not published on the docs page (it is resolved at runtime by PolicyService).
- The ProcessReceipt documentation page and the official advertising standards page were not fetched in this pass. Their exact current wording should be verified at https://create.roblox.com/docs/reference/engine/classes/MarketplaceService and https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing.
- Not checked: Roblox Terms of Use text on under-13 spending and parental controls (e.g. monthly spend limits set by parents).
