---
date: 2026-11-09
tags: [galaxy, growth, plan, marketing, monetization, retention, liveops]
status: approved 9 Nov; in-game items built (see Progress 2026-11-09 Growth plan built)
---
# Galaxy Incremental: growth plan to 1,000 CCU + 85K R$/day

Owner (9 Nov): goal **1k CCU with 85K Robux a day**; budget "i can spend any"; tests any time before the midnight cut-off; "takes like 4 mins then it gets boring ALOT"; no TikTok until the game is fixed; **nothing over 449 R$**.
Baseline: [[2026-11-09 Morning report]] (3.5 min playtime, 23 DAU, 0.31% payers, 20 R$/day, reach 6/250, likes 5/8). Playbook rules apply: no paid random items, no fake timers, no "was" prices.

## 0. What the goal means in numbers
| | Now | Goal | Gap |
|---|---|---|---|
| Avg playtime per DAU | 3.5 min | **25+ min** | x7 |
| DAU needed for 1k CCU | 23 | ~**58K** (1,000 x 1,440 min ÷ 25 min) | x2,500 |
| Revenue per DAU | ~0.9 R$ | **~1.5 R$** (85K ÷ 58K) | x1.7 |
| Payer conversion | 0.31% | 2-3% | x8 |
**Order matters:** playtime first (it decides whether Roblox recommends you), then page conversion, then ads at scale, then monetization depth. Spending on ads before playtime > 15 min buys players who leave and tells the algorithm the game is weak.

## 1. MARKETING & ACQUISITION

### What the two campaigns actually show (11 Nov launch ads)
| Campaign | Spent | Impressions | Clicks | CTR | Cost per click |
|---|---|---|---|---|---|
| Engagement (9 creatives) | $16.07 | 54,118 | 900 | 1.66% | $0.018 |
| Plays (4 creatives) | $12.66 | 113,439 | 1,797 | 1.58% | $0.007 |
| **Total** | **$28.73** | **167,557** | **2,697** | **1.61%** | **$0.011** |
- **CTR is NOT the problem.** 1.6% is a normal-to-decent CTR and clicks are extremely cheap.
- **Only ~$29 was spent in total**, far under budget: delivery, not money, was the limit (bids/budget too low for the auction, or short run time).
- **The big leak is AFTER the click:** 2,697 clicks vs only ~160 new players that week = **~6% of clickers pressed Play**. The game page loses ~94%. Likely causes: the **38% like ratio** shown on the page, "[ALPHA]" in the title, few visits/favorites (looks dead), and thumbnails that don't show gameplay.
- Best creatives: **"1.2Qa/s" big number** scaled best (99.5K impressions, 1.6-1.8%), the **logo** was steady (1.6-1.7%), the Supernova avatar had the top CTR (2.2%) but tiny volume. The black hole was weakest (1.3-1.7%).

### Game page (fix BEFORE the next ad)
1. **Title:** drop "[ALPHA]". Use an update tag only while it's fresh: `Galaxy Incremental [SPACE JUMP]` on update day, plain name otherwise. Keep "Incremental" in the name (search + genre fans).
2. **Icon** (the ad and search tile): one huge readable idea at phone size. Test against each other: (a) the big number "1.2Qa/s" style, (b) the avatar + exploding Supernova, (c) the logo. The night shift is making 3 variants.
3. **Thumbnails (in this order):** 1 = the most exciting real moment (Supernova explosion with the island and big numbers), 2 = your island built up with pads, 3 = the Black Hole, 4 = the Forge roll. Short text max 3 words per thumbnail ("GO SUPERNOVA").
4. **Like ratio:** after the pacing fix, the "Enjoying Galaxy? Leave a like!" panel after the first Supernova (no reward). Need ~14 more likes to reach 70%.
5. **Description:** first line = the promise ("Grow a tiny rock into a galaxy and blow it up!"), then the update log and the code. Short.
6. **Game-page video:** galaxy_roblox_video.mp4 is ready (needs your upload).

### Sponsored Experiences (when playtime > 15 min)
- Run **one Plays campaign** (cheapest per click, best volume) with the 2 best icons. Budget **$30-50/day**, 3-day minimum per test so delivery stabilises.
- **Judge on cost per PLAY and D1, not CTR.** Kill a creative after 5,000 impressions if CTR < 1.2%.
- **Scale rule:** while D1 ≥ 20% and avg playtime ≥ 15 min, double the budget each week. If either drops, hold.
- Weekend bids cost more but kids play more: put 60% of the weekly budget on Fri-Sun.

### Short-form video hooks (later, owner: fix the game first)
Built from Galaxy's real mechanics:
1. "I turned 1 rock into a galaxy" (0.5 s: the rock → time-lapse of the island → Supernova flash on the drop).
2. "What happens at 1 QUADRILLION stardust?" (the number climbing, then the explosion).
3. "Rarest Forge core: 1 in 10,000" (the roll reveal, suspense cut).
4. "The Black Hole ate my whole island" (the pull + reset moment).
5. "Day 1 vs Day 7 island" (split screen).
Rules from the video pipeline: hook in the first second, cut on the beat, loop ending.

## 2. ECONOMY & MONETIZATION

### Broken-economy checklist (run with the Calc bot + analytics)
- **Dead zones:** any stretch > 30 s in the first 30 min with nothing affordable or nothing new (the 3-minute wall = the #1 broken element now).
- **One currency doing two jobs:** each currency has one job (stardust = grow, XP = perks, shards = ring 2, Essence = Forge). Flag any mix.
- **Inflation at the top:** income growing faster than costs after ~1 hour = nothing feels earned. Watch "time to next buy" rising/falling over the session.
- **Dominant choice:** if one upgrade is always the best buy, the others are dead content. The bot logs buy shares: anything < 3% of buys is redesign material.
- **Reset pain:** a Supernova should make run 2 at least ~2x faster than run 1.
- **Pay wall check:** a non-payer must hit every free milestone in the design timeline; a payer must feel the pass inside 60 s.

### Onboarding pass/product structure (all ≤ 449 R$)
| Item | Price | Why it converts |
|---|---|---|
| **Starter Pack** (one-time, shown after the first Supernova, 48 h) | 49 | first purchase is the hardest; tiny price, big value (2x Stardust 30 min + 3 Essence + a trail) |
| **x2 Stardust** (pass, live) | 249 | the core pass; show the doubled number live on the HUD for owners |
| **Auto-Upgrade** (pass) | 199 | incremental players love auto-buy; also a convenience, not power |
| **VIP** (pass) | 399 | +25% stardust, +1 Essence per Supernova, VIP trim, VIP chat tag |
| **+1 Core Slot** (pass) | 349 | the Forge's depth item |
| **Offline x2** (live) | 25 | keep; show it at the offline-earnings screen |
| **Time skips** (products) | 15 / 39 / 99 | "+1 h / +4 h / +12 h of production instantly": the honest skip-stage product |
| **Essence packs** (products) | 29 / 79 / 199 | buy Forge rolls' currency. The roll itself stays earned/visible-odds; no Robux crate |
No crates for Robux (playbook rule + the kids audience). The Forge roll uses Essence that players mostly earn; show the odds.

### Over- vs under-priced (from conversion)
Track per item: **Seen** (shop card/prompt shown), **Prompted**, **Bought** (custom events with the item id), then:
- **Prompt → buy conversion < 3%** with many views = **overpriced or wrong moment**. Move the prompt to a better moment first, then lower the price one step.
- **Conversion > 15% and buyers come back for more** = **underpriced**. Raise one step on new players only (price test by UserId half).
- **Revenue per 1,000 players** is the final score, not conversion alone.
- Test one price at a time, 7 days, the same weekday mix.

### Ethical monetization loops
- **Daily rewards with a streak** (live): add a visible 7-day calendar with a big day-7 reward (Essence + a cosmetic).
- **Playtime gifts** at 5/10/20/40/60 min (real timer).
- **Offline earnings screen** on join ("You earned 1.2M while away") with the Offline x2 offer.
- **Weekly Supernova pass-free goal:** "Supernova 5 times this week = rare core".
- **Premium:** +10% stardust for Premium players (Premium Payouts pay you for their playtime: one more reason playtime is everything).

## 3. RETENTION & ENGAGEMENT

### The churn point
Players quit at **3.5-4 min**, exactly at the "NEXT: 4.22K at 7.2/s" wall. Fix: [[2026-11-09 Galaxy Incremental - Prompt - Fix the 3-minute quit (first 10 minutes pacing)]]. Then the onboarding funnel (in that prompt) shows the next churn point.

### 3-minute tutorial checklist (first dopamine hit instantly)
- [ ] **0:00-0:10** spawn ON your island, first stardust ticking up, LUMI says one line ("Tap the pad!").
- [ ] **0:10** first pad = first purchase. Big pop, sound, the island visibly changes.
- [ ] **0:30** 3+ purchases done, a number visibly jumping (x2 or more).
- [ ] **1:00** first NEW body (Moon) appears in orbit: cinematic mini-moment (0.5 s zoom).
- [ ] **1:00** LVL 2 + the first perk bought.
- [ ] **2:00** Planet; the Supernova bar is visible and moving.
- [ ] **2:30** a free gift (2x for 5 min) right where the wall used to be.
- [ ] **3:00** the player has a goal under 60 s away AND a big goal (Supernova) on screen.
- [ ] **5:00** FIRST SUPERNOVA: the biggest moment of the game, then the like/favorite prompt.
- [ ] Never: a text wall, a forced wait, a locked button without a reason, a popup over the centre.

### Badge map (D1 / D7 / D30)
| When | Badge | Why it brings them back |
|---|---|---|
| 0-5 min | First Pad, First Moon, **First Supernova** | early wins, profile flex |
| Session 1 end | **"Come back tomorrow"**: the day-2 streak reward is shown on leave | D1 |
| Day 2 | Streak 2, Supernova 5 | D1 confirmation |
| Day 3-5 | First Forge core, Black Hole survivor, island fully built | mid-game goals |
| Day 7 | **Streak 7** (a rare core + a title), Supernova 25 | D7 |
| Day 14-30 | Myth Maker, Celestial Archivist (live), all bodies at NOVA, Streak 30 | D30 / collectors |
Each badge comes with an in-game reward and shows on the island or the overhead tag, so others see it.

### Content depth (owner: "4 mins then it gets boring")
After the pacing fix, the next limit is content. Rule: **something new to chase every session**: a new system every ~30-60 min of playtime (pads → perks → Supernova → Forge → Black Hole → the next sector). The night shift can measure the real content length with the bot after the fix.

## 4. LIVEOPS & AUTOMATION

### Recurring calendar
- **Every Saturday 21:30 MMT:** the weekly update + a code + the group shout (the beat in the release plan).
- **Weekend 2x Stardust** (Fri 18:00 - Sun 24:00 UTC) once playtime is healthy.
- **Monthly limited cosmetic** (a trail or island skin) earned by a weekly goal, never sold as random.
- **Server-wide Star Surge** (live) as the hourly mini-event.

### Dynamic switches (no publish needed)
- Put event multipliers, gift timings and prices for tests in **Creator Hub Configs** (like GYM ARC's HallOfFame_EXPScale), read by EventController. Changing a value goes live in minutes.
- **Automatic rules inside the game:**
  - **Stuck helper:** a player with nothing affordable for 60 s gets a free 2x boost for 2 min (once per 20 min).
  - **Comeback bonus:** a player away 3+ days gets a "Welcome back" gift (offline cap raised once).
  - **Quiet-server boost:** a server with ≤ 3 players gets the Star Surge more often (empty servers feel dead).
- **Weekly review loop (night shift, Mondays):** read the funnel + playtime + D1 + per-item conversion, write the morning report, propose next week's one change. You decide; Claude Code builds.

## Order (next 3 weeks)
1. **This week (14 Nov update):** pacing fix, windows fit, space movement, music fix, title without [ALPHA], like panel. **No ads.**
2. **Week 2:** new icon/thumbnails, game-page video, Starter Pack 49 + Auto-Upgrade 199 + time skips, daily calendar, badges D1/D7. **Ads restart small ($30-50/day) only if playtime ≥ 15 min.**
3. **Week 3:** price tests, VIP + Core Slot, weekend 2x, content depth (next sector). Scale ads by the rule above.
