---
date: 2026-10-29
tags: [playbook, research, roblox-platform, retention, liveops, economy, audio, vfx, ui, tech, business]
status: research (8 parallel research runs, 29 Oct 2026)
---
# Playbook notes: whole-game research (Oct 2026)

Back to [[00 Roblox Playbook]] · Used by: [[2026-10-29 GYM ARC The whole game plan (research loop)]]

Eight research runs on 29 Oct 2026, one per area. Tags: **[V]** = checked on an official or primary source · **[U]** = unverified, a third-party claim or an inference. No numbers were invented; where nothing was found, it says so.

## 1. Roblox platform rules and features (2025-2026)
- **Kids & Select (since 19 May 2026) [V]:** a public game only reaches players **under 16** if the owner is ID-verified, has 2-Step on, and has Plus/Premium (2 months running), free Plus, or pays a **refundable 1,000 R$ per game** (refunded ~90 days after the game qualifies). The game is first shown only to age-checked 16+ players and needs **250 unique plays from highly engaged, age-checked users within 60 days**. Track it on Creator Hub > **Audience Reach**. Only Minimal/Mild maturity labels can reach Roblox Kids (5-8). Sources: devforum.roblox.com/t/4573166, /t/4630944; create.roblox.com/docs/production/publishing/kids-and-select. [U] whether ID verification works for Myanmar accounts.
- **Discovery (15 Jun 2026) [V]:** Recommended For You uses 28 days in 3 windows (day 1, days 2-7, days 8-28). QPTR was replaced by play-through rate + **first-play bounce under 60 s and 61-180 s**. Other signals: playtime (capped at 60 min per user per day), play days, co-play days, spend days, Robux spent. Since Aug 2026 Home favours games strong in **both** retention and monetization. Oct 2026: a game needs at least one custom thumbnail to be recommended. "Today's Picks" became curated **Standout Games** (nomination form). Video previews play on RFY. Sources: devforum /t/4684575, /t/4779042, /t/4502571, /t/4953263; create.roblox.com/docs/discovery.
- **Creator Rewards (since 24 Jul 2025) [V]:** 5 R$ each time an "Active Spender" plays 10+ min in a day (first 3 games of their day count); Audience Expansion = 35% of a new/returning player's first $100 if they came by link/name search (needs ~100 DAU). Paid after 60 days. Source: devforum /t/3777628.
- **Experience Notifications [V]:** 100+ visits; only opted-in players **13+**; 1 per user per day; 99 characters; opt-in prompt not shown again for 30 days; no fake urgency; can't gate gameplay on opting in. Source: create.roblox.com/docs/production/promotion/experience-notifications.
- **Rewarded video / immersive ads [V]:** game needs 2,000+ monthly unique visitors; under-13s never see them. Not worth it at our size.
- **Subscriptions (1 Apr 2026) [V]:** min 49 R$/month, 70% share. **Managed Pricing (15 Jun 2026)** merges regional pricing + price optimisation; never hard-code prices. Source: devforum /t/4552995, /t/4684738.
- **Safety [V]:** chat needs an age check worldwide (Jan 2026); social links in games banned; **TextChatService migration required by May 2027**; paid random items need odds totalling 100% behind a labelled button + PolicyService `ArePaidRandomItemsRestricted` (applies if coins can be bought with Robux and buy random things). Sources: docs paid-random-items; devforum /t/4953263.
- **Events/updates [V]:** Update Announcements 1 per 3 days, 60 chars; Experience Events up to 10 with Notify Me; Thumbnail Personalization 2-5 thumbnails (bandit on PTR; weak below ~1,000 DAU); Moments (short video) 16+ only; Party API (`Player.PartyId`) to spawn friends together; Configs + Experiments (A/B suggested from ~500 DAU).
- **Communities [V]:** Announcements replace Shouts (from Jan 2026); push to all members **once every 7 days**; polls + analytics. Source: devforum /t/4657552.

## 2. Retention benchmarks and tactics
- **GameAnalytics 2026 (500+ Roblox games with 1M+ MAU) [V]:** D1 median **10.3%**, top 1% 22.2% · D7 median 1.6%, top 1% 9.1% · D30 median 0.5% · session median 9.8 min, top 5% 16.6 min. Claims that "20% D1 is good" are inflated. Source: gamedevreports.substack.com/p/gameanalytics-key-roblox-and-roblox. GYM ARC (4%) is below the median of big games.
- **Roblox onboarding guidance [V]:** low early thresholds, starter items, short/mid/long goals visible, end onboarding on a "moment of joy", bouncing arrows/beams, just-in-time tips, **timed hints** (their example: highlight at 11 s if most testers find it in 10 s). Source: create.roblox.com/docs/production/game-design/onboarding(-techniques).
- **Endowed progress [V]:** a card that starts with 2 of 10 stamps filled was completed 34% vs 19% (Nunes & Drèze 2006). **Goal gradient [V]:** effort speeds up near a reward and dips right after one (Kivetz). Fits our drops right after big rewards.
- **Offline progress [V]:** idle-game retention driven by growth while away + each check-in visibly advancing (Pecorella, GDC 2015).
- **Streaks [V, company-reported]:** Duolingo streak freezes +0.38% DAU; milestone animation +1.7 pp day-7 activity.
- **Weekly events [V]:** Grow a Garden / Steal a Brainrot "admin abuse" weekend events made huge spikes that faded within hours; Roblox LiveOps guide: weekly-to-monthly content + big live events for lapsed players.
- **Social [V]:** co-play days are a ranking signal; invite prompts with launch data (friend spawns next to you); Friend Invite Reward system. Voldex: "a third of our returning players are just socializing" (studio figure).
- **Kids UX [V]:** kids skip long instructions (seen on Roblox too), older kids scan, want instant gratification, call things "for babies" fast; can't tell ads from content (NN/g).

## 3. Gym genre right now (29 Oct 2026)
- Platform DAU fell 152M → 123M in 2026; Roblox says players are moving from "slop" to quality/retention games [V, IGN via Yahoo].
- **Gym Star** ~6.9k CCU, Update 33, ~32 passes incl. luck tiers and 6,999 R$ passes (heavy). **Muscle Legends** 81.9k peak on 22 Aug 2026 from a "Muscle Legends is back" update run as a **Roblox Event page with a countdown (260k interested)**, then a weekend event every 1-2 weeks; cheap simple passes 99-799. **Arm Wrestle Sim**: a new world + code every update, timed boost codes, apology codes. **Project Iron** (rising): "realistic" sim, 62 muscles, shows/meets, genetics rolls for height/frame, a social followers app, fast named versions each with a code + apology codes. **Power Lifters** relaunched as a new place (REVAMP, Jun 2026), +654% 28-day average, Halloween candy shop + codes. **Gym League**: 143k peak in 6 weeks, now ~1.2k; only 7 updates in 2.5 years, 25 passes, 8-player servers, favourites per visit ~9x below median. Sources: rolimons, rowatcher, destructoid, robloxden, statroblox.
- **Top games' shared pattern:** a fixed weekly event (Steal An Egg "Admin Abuse" every Saturday ~1 h, then the update), a new zone/items every update, limited items + seasonal currency, countdown event pages. Peak platform time Saturday ~19:00 UTC [U, RoWatcher data].

## 4. Growth, ads, creators, localisation
- **Ads Manager [V]:** objectives Plays / Earnings / Engagement; automatic bidding; small daily budget 3-7 days then raise; pausing restarts the 24-48 h learning period. Benchmarks (Nov 2025): Maximize Plays **$0.0073 per play**, Acquire New Users $0.0187. $20-50 ≈ very roughly 2,700-6,800 plays [U, arithmetic]. Ads accept up to 25 thumbnails per campaign (cheap thumbnail test). Paid players played ~5.4 min vs ~12 from Home [U, forum]. Sources: create.roblox.com/docs/production/promotion/ads-manager; devforum /t/4084863, /t/4909790.
- **Break-even [V rates, U arithmetic]:** 1 R$ spent by a player ≈ 0.7 × $0.0038 = $0.00266 to us, so each paid player must spend ~2.6-7.1 R$ lifetime to repay $0.007-0.019 per play.
- **TikTok/Shorts [U, vendor]:** open on the best moment, vertical, captions, many clips in a few days, many small creators beat one big one. Creator Affiliate was replaced by Creator Rewards share links.
- **Automatic Translations (Jun 2026) [V]:** machine translation of names/descriptions/text; manual translations win. Biggest regions by DAU: APAC, Rest of World, Europe, US/Canada [V]. Priority languages Spanish, Portuguese (BR), Indonesian, Thai [U, inference].

## 5. Core loop, progression maths, economy
- **Juice [V]:** tweening, squash/stretch, particles (not too many), shake matched to impact, hit-stop on strong hits, layered sound, effects that leave a mark (Jonasson & Purho; Nijman).
- **Idle maths (Pecorella) [V]:** cost = base × rate^n (1.07-1.15) against linear income; ×2 milestone bumps; prestige pays off when it gives **+50% to +200%** of current power; after a reset early progress must be quick and the player must get further than last time; slow cycles need a meta layer.
- **Economy (Roblox docs) [V]:** a sink for every source; event currencies keep the main currency safe; keep sources minus sinks near 0; `LogEconomyEvent` (done in our game).
- **Gacha norms [V, secondary]:** visible pity, carried over; duplicates convert to something.
- **Kids' ethics [V]:** FTC vs HoYoverse (Jan 2025, $20M): no loot boxes to under-16s without parental consent, clear odds, no confusing currencies, no design tricks. UK Children's Code standard 13: no nudges that exploit; nudges toward breaks are good. → no near-miss animations, no countdown pressure, never punish absence.

## 6. Art, UI, world
- **Mobile UI [V]:** bottom-left (thumbstick) and bottom-right (jump) belong to Roblox controls; contextual buttons; collapse secondary buttons; AutomaticSize + wrapping; same X in the same corner; grey disabled; lock icon for locked; red for unaffordable prices; minimal HUD for young/mobile players.
- **Rarity ladder [V, industry]:** grey → green → blue → purple → gold/orange (+ one Mythic colour); never colour alone (shape/star count too; Xbox guideline 103).
- **World [V]:** "weenies" (big landmarks that pull players), brightest light on the main path (squint test), entrances that show what's inside, a plaza to show off (Rogers, GDC 2009).
- **Lighting [V]:** Lighting.Technology superseded by LightingStyle + PrioritizeLightingQuality; Future pays off indoors.
- **Accessibility [V]:** `GuiService.ReducedMotionEnabled`, `PreferredTextSize` (ignored by TextScaled), `PreferredTransparency`; every sound has a visual cue; separate music and SFX volume.

## 7. Sound, music, VFX, calendar
- **Pitch [V]:** +1 semitone per step (≈ ×1.06 playback speed) for combos, small random pitch on repeats.
- **Loudness [V]:** no single mobile standard (Sony mobile -18 LUFS; ~-16 common); test on phone speakers + headphones.
- **Ducking [V]:** compressor sidechain on music keyed by reward SFX (AudioCompressor in the new Audio API; SoundGroups discouraged).
- **Licensed music [V]:** Creator Store partner tracks free in experiences: Monstercat, DistroKid, Too Lost (Jul 2026); UMG deal (Dec 2025). Upload only what you own.
- **Particles [V]:** 100 particles/s per emitter on mobile, 20 s max lifetime, flipbooks ≤30 fps and switched off on low-memory phones.
- **Photosensitivity [V]:** max 3 flashes per second (WCAG 2.3.1); no red strobe.
- **Calendar [V]:** Thanksgiving 26 Nov, Christmas Fri 25 Dec, New Year Fri 1 Jan, Lunar New Year **Sat 6 Feb 2027**, Valentine's Sun 14 Feb; Brazil summer break Dec-early Feb [U]; Roblox MAU +9% in December [V, third-party]. Saturday play rises from ~15:00 UTC, peaks ~19:00 UTC; 19:00-23:00 UTC is the NA/EU/BR overlap [U, RoWatcher]. **Our 15:00 UTC Saturday update slot is supported.**

## 8. Tech and business
- **Security [V]:** server owns currency/stats; check type and range of every remote argument; token-bucket rate limits; ProximityPrompts can be fired by exploiters; purchases only via ProcessReceipt. Autoclicking: no clear Roblox rule [U]; cap gains per minute on the server instead of fighting clicks.
- **Data [V]:** 4 MB per key; versions kept 30 days (`ListVersionsAsync` → `GetVersionAsync` → `SetAsync` to roll back one player); ProfileStore is the maintained session-locking library; **Right to Erasure** requests must be handled (webhook).
- **Server Authority [V]:** released 9 Jul 2026, opt-in, for physics cheats; low value for a tap sim.
- **QA [V]:** Error Report (errors per version); Device Simulator = screen/input only (new network simulator beta); ~65% of players on Android, many 2-4 GB RAM; play 10-15 min on a real phone; Configs can roll out over 15 min and target country/tenure/payers.
- **Server fill bug [V, Oct 2025]:** matchmaking sometimes made 1-player servers.
- **DevEx [V]:** $0.0038 per Robux (earned since 5 Sep 2025), min 30,000 R$ ($114), 13+, monthly; we keep 70% of in-game sales.
- **Investor deals [V/U]:** usual shape = % of net revenue until 1-2x recouped, then a smaller tail or end, with a time limit; define "revenue" as DevEx USD actually received; monthly statement; what happens if the game ends; IP stays with the developer (not legal advice).

## Not found / unverified
5-minute retention target for sims; measured friends-retention multiplier; how Muscle Legends/Pet Sim 99 do tapping; button sizes for 8-13; reward VFX/shake numbers; whether creator ad campaigns now reach under-13s; ID verification in Myanmar.
