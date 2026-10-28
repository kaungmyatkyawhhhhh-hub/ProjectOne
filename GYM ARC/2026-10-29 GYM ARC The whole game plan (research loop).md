---
date: 2026-10-29
tags: [gymarc, plan, roadmap, decisions, research]
status: decided by Claude (owner, 29 Oct: "research everything, question yourself, decide, plan the entire game")
---
# GYM ARC: the whole game plan (research loop, 29 Oct)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Research behind it: [[Playbook notes - Whole-game research (Oct 2026)]] · Earlier decisions still valid unless changed here: [[2026-10-29 GYM ARC Every decision - the whole game]], [[2026-10-29 GYM ARC Master plan - one ladder]], [[2026-10-29 GYM ARC Prices - every coin and Robux item]], [[2026-10-29 GYM ARC Auras rework]], [[2026-10-29 GYM ARC Rescue plan - if the game is dying]]

## How this plan was made (the loop)
1. **Find the gaps:** listed everything about the game that earlier research didn't cover.
2. **Research in parallel:** 8 research runs (Roblox platform rules 2025-26, retention evidence, the gym genre today, ads and growth, core loop and economy maths, art/UI/world, sound/VFX/holiday calendar, tech/data/business). Sources are in the research note.
3. **Question every system:** for each part of the game I asked "what does the evidence say, what do we do now, is it worth the work for a solo dev at 12 CCU?" (log below).
4. **Decide and schedule** (this note), then an **independent reviewer attacked the plan** and 15 holes were fixed (section "Reviewer's attack" at the end).

---

## The 6 findings that change the plan most
1. **Kids & Select (Roblox rule since 19 May 2026).** A game only reaches players **under 16** if the owner is ID-verified, has 2-Step on, and has Plus/Premium or pays a **refundable 1,000 R$**, AND the game gets **250 plays from engaged, age-checked players (16+) within 60 days**. If GYM ARC isn't through this, **most of our real audience (kids) can't even be recommended the game**. This may matter more than any feature. → **FIX NOW #1.**
2. **Roblox now ranks on day 1, days 2-7 AND days 8-28**, counts quits **under 60 s and 61-180 s against us**, rewards co-play days, and (since Aug 2026) wants **retention AND spending**. → The first 3 minutes and "come back tomorrow / next week" hooks are what the algorithm reads.
3. **Benchmarks:** big Roblox games' median D1 is **10.3%**, D7 1.6%, session 9.8 min (GameAnalytics 2026). We're at ~4% D1. Target 10% is "median", not a dream.
4. **First reward must come sooner.** Half our new players leave before the first Growth Spurt (~4-5 min). Evidence (Roblox onboarding docs, endowed progress, bounce windows) says: the first big moment inside ~2 min, the bar already partly filled, no reading.
5. **The genre's risers update often (weekly to every 2 weeks) with a code each time, run a fixed weekly event, and use countdown Event pages.** Muscle Legends hit 81.9k CCU with a countdown "comeback" event page and then a weekend event every 1-2 weeks. Gym League, with only 7 updates in 2.5 years, faded (slow updates are likely one cause among several).
6. **Notifications can't reach most kids** (Experience Notifications only go to opted-in 13+). So come-back hooks must live **inside the game** (rested gains, weekly Power Hour, streak, Update Announcements and Community announcements).

---

## Questions I asked myself (and the answers)
| # | Question | Answer (decision) |
|---|---|---|
| 1 | Is the Hall of Fame launch on Saturday still right? | Yes. It's built, opt-in, and the countdown system works. Prompt 95 first. |
| 2 | What's the single biggest reason players leave? | The first 3-5 minutes (half leave before Spurt 1). Prompt 106 fixes it on 7 Nov. |
| 3 | Could something outside the game be hiding us? | Yes: Kids & Select. Check Audience Reach today (FIX NOW #1). |
| 4 | Should the first Growth Spurt be faster? | Yes: **~2 min for a real new player** (who always has the new-player 2x boost; now ~4-5), bar starts **20% filled** ("Welcome bonus"), spurt 2 ~5 min, total time to 6'0" stays ~1 h (later spurts absorb it). Nobody mid-run ever gets a higher goal. |
| 5 | Is the 9-step tutorial too long? | Yes. **4 steps**: walk (beam) → lift (bouncing arrow) → watch the bar → GROW. Stamina, shake, squat, stats, Coach Dex become just-in-time tips. |
| 6 | Deepwoken-style cards? | **Yes, small: "Run Cards"** (prompt 105, with the alter fix 21 Nov). Pick 1 of 3 at every alter, reset at the Hall of Fame, 1 Legacy card kept per star (replaces Star Perks: one system, not two). |
| 7 | Do we need notifications? | Yes but small: 13+ only, 2 personal messages ("rested", "a friend passed your height"). The main come-back hooks are in-game. |
| 8 | Weekly event like "Admin Abuse"? | **Yes: POWER HOUR, twice every Saturday: 12:00 UTC (Asia evening, 18:30 Myanmar) and 19:00 UTC (Americas/Europe)**, automatic on all servers, no countdown pressure, its cosmetics come back in rotation. Replaces the removed rush hour. |
| 9 | Rested bonus? | **Yes**: away 8 h+ → "WELL RESTED: x2 EXP for 15 min", applied in full after the soft line. Positive framing (like WoW's rested XP). |
| 10 | Ads now? | Only the **$20-50 measuring test after 7 Nov** (also collects Kids & Select's 250 plays if needed). Each paid player must later spend ~2.6-7.1 R$ just to break even; no scaling before Gate 2 passes. |
| 11 | New Robux products (subscription, rewarded ads)? | **No** until Gate 2 passes (D1 8%+) and we see payer % (Home now wants retention AND spending, so the existing fair store must be easy to find, but no new items). Rewarded ads need 2,000 visitors/month and can't show to under-13s. Subscription idea "Gym Club 99 R$/month" decided at Gate 2 at the earliest. |
| 12 | Paid random items legal? | Coins can be bought with Robux, so trainer/aura rolls count. Odds button must say **"Odds"**, and players where PolicyService says restricted get **no Robux coin packs, DNA products or Starter Pack (it contains a DNA token)**; their coins are earn-only. The Robux "Luck" supplement is removed (it broke our own no-paid-luck rule). Prompt 108, 7 Nov. |
| 13 | Switch saving to ProfileStore? | **No.** Ours already has a session lock and retries; switching risks wiping saves. Add a `dataVersion` + migrations, weekly backups, and the Right to Erasure process (108). |
| 14 | Fight autoclickers? | **No.** Server caps gains per minute (anti-exploit), Auto Rep exists anyway. Fight injected scripts, not clicking speed. |
| 15 | Server size? | **20 players** until CCU passes ~30 (with max 12 at 14 CCU we'd get one full server and one nearly empty). Co-play counts in ranking. |
| 16 | Re-rack coins (open question): fixed 50 or the owner's LVL scaling? | **Keep the owner's version** (5 + 1 per LVL, capped at LVL 400). It IS a fixed number for each level, not "minutes", and we never undo the owner's changes. Prompt 103 must not change it. |
| 17 | Is our Saturday 15:00 UTC slot right? | Yes: Saturday play starts rising then and peaks ~19:00 UTC, so there's time to hotfix before the peak. Keep. |
| 18 | Music licence safe? | New tracks only from Creator Store partner music (Monstercat, DistroKid, Too Lost) or the existing licensed library; nothing we don't own. No lyrics (kids, video rules). |
| 19 | Too many features again? | Every addition here is small and sits on an existing moment (alter = card pick, Saturday = Power Hour, rejoin = rested). Nothing new on the HUD. Cut list from 29 Oct stays. Multipliers are counted: no hard cap any more (owner, 29 Oct) but soft stacking: 4 parts multiply, bonuses add inside a part, extra above x10 counts half; Power Hour and rested apply after that like PUMPED; max 3 Legacy cards active. |
| 20 | What if the game is dying anyway by January? | The rescue gates stay (21 Nov, ~5 Dec). If both fail: maintenance mode (weekly code + Power Hour keep running by themselves) and the next game. |
| 21 | Should we copy the "realistic" trend (Project Iron, Power Lifters)? | No. Our hook is **height** and a fun stylised world; realism needs a different game. We copy their habits (named weekly versions, a code each, apology codes, showing bodies off), not their style. |
| 22 | Translations? | Yes, cheap: owner adds manual Spanish, Portuguese (BR), Indonesian and Thai name + description in Creator Hub. In-game text uses Roblox's automatic translation. |

---

## FIX NOW (today 29 Oct → Friday 30 Oct)
**Owner, in Creator Hub (no publish needed):**
1. **Kids & Select / Audience Reach** (Creator Hub > GYM ARC > Audience / Audience Reach): see if GYM ARC can reach under-16s. If not: turn on 2-Step, do ID verification (tell me if Myanmar ID isn't accepted), and pay the **refundable 1,000 R$** fee (Plus only counts after 2 months in a row, so the fee is faster). Answer the **maturity questionnaire** truthfully (the game should come out Minimal/Mild). Screenshot the page for me. If the game still needs its **250 plays from age-checked 16+ players**, the 8-14 Nov ad test is how we collect them (target 16+ if Ads Manager allows it).
   - **Backup if ID verification isn't possible from Myanmar:** ask whether a trusted adult group admin can own/verify, or ask Roblox support; until then everything else in this plan still helps the 16+ players we can reach.
2. **VIP pass description:** remove the lounge line (the lounge isn't built yet).
3. **Server size:** Places > GYM ARC > Max players → **20** (until CCU is above ~30), so our 12-14 players land together instead of in a full server + a nearly empty one.
4. **HALLOWEEN code** (the Halloween season ends 2 Nov) from the console, no publish: `game.ServerStorage.Admin:Invoke("code", "add", "HALLOWEEN", { rolls = 1, shakes = 2 }, "2026-11-02", false)`
5. **Hall of Fame launch marketing (for Sat 31 Oct 15:00 UTC):** an **Experience Event** "HALL OF FAME OPENS" (so people can tap Notify Me), an **Update Announcement** on launch day (60 characters, e.g. "The Hall of Fame is OPEN! Become a legend. Code HALLOFFAME"), a **Community announcement** with the push (allowed once per 7 days), and the owner's planned name `[🎃🏆 HALL OF FAME] GYM ARC 💪` (drop the 🎃 after 2 Nov).
6. **Back up the place before launch:** File > Save to File (or Version History > Open Local Copy, then save) → keep the .rbxl in a cloud folder. The place was lost once (8 Oct).
7. **Translations:** name + description in Spanish, Portuguese (BR), Indonesian, Thai (Creator Hub > Localization). Description's first line: "Lift to grow taller, from 4 feet to 7 feet, and enter the Hall of Fame!" (**7, not 8**: 7'0" is the real top until more alters exist; promising 8 feet is an overpromise).
8. **Brother's deal on paper** before any money moves (checklist below).
9. **Still open from 28 Oct:** Workspace StreamOutBehavior → **LowMemory** (stops the ~1 s lag spike when gyms reload on phones).
10. **Like + favourite reward: KEPT (owner, 29 Oct).** The "free 1,000 coins for like + favourite" stays as it is; don't make it bigger and don't add more rewards for likes.
11. **DevEx from Myanmar:** before the brother's deal, check in Creator Hub > DevEx that cashing out works for your country/tax form, so nobody signs a deal that can't be paid.

**Claude Code before Saturday:** prompt **95** (Hall of Fame fixes, fairness, fixed coin packs).

**Saturday 31 Oct after launch (owner, 15 min):** Error Report (errors new in this version), CCU during the launch, `LaunchEvent_Seen` count. Hotfix only if something breaks; otherwise nothing changes until Sunday's review.

---

## The schedule (every Saturday 15:00 UTC = 21:30 Myanmar)
(Rebuilt after the reviewer's attack: at most ~2 prompts a week, the save-touching work first, and one no-release week a month.)
| Date | Update (name tag + code) | Prompts | Why now |
|---|---|---|---|
| **Sat 31 Oct** | HALL OF FAME (code HALLOFFAME) | 95 (+90, 88 done) | Built; launch event ready |
| Sun 1 Nov | First weekly review (routine below) | - | |
| **Sat 7 Nov** | FAST START: first 3 minutes + cuts + safety pass (code GROW) | **106**, 104, **108** | Biggest leak first; 108 fixes paid-random compliance before the ad test and adds the save version that 105 needs. Not slippable |
| 8-14 Nov | Ad test $20-50 ("Plays", 7 days, never paused, 5-10 thumbnails as creatives; 16+ targeting if Kids & Select still needs its 250 plays) | - | Enough new players to measure 106 |
| **Sat 14 Nov** | MY ROAD: Future You + Progression Road + fixed coin values (code ROAD) | 91, 103 | Re-run 95's run-2 pacing after 106 changed the spurts |
| **Sat 21 Nov** | **GATE 1 read in the morning**, then TRANSFORM: alter fix + **Run Cards** (code TRANSFORM) | 96, **105** | Alters 1-5 and 8-9 leak. 98 mockups start this week |
| **Sat 28 Nov** | POWER HOUR (first ones 28 Nov) + rested gains + friends + stronger aura visuals, Thanksgiving week (code POWERHOUR) | **107**, 102A | Days 2-7 and 8-28 ranking windows |
| Sat 5 Dec | **GATE 2** + GOLDEN ERA GYM (Event page with countdown made ~21 Nov; code GOLDENERA) | 98 | Alter 8 wall |
| Thu 10 Dec | Winter Lifts season starts by itself; owner adds code WINTER from the console | - | |
| Sat 12 Dec | CHAMPIONS | 92 | One ladder of rivals |
| Sat 19 Dec | FEATS, start of the winter break (code FEATS) | 93 | Use your strength |
| Sat 26 Dec | **No release** (Christmas): gift code GIFT from the console only | - | Rest week; December is the platform's busiest month, don't risk bugs |
| Sat 2 Jan | NEW YEAR: AURA ALTAR (code 2027) | 102B | Fresh coin sink for holiday savings |
| Sat 9 Jan | Sound, music, VFX polish (Audio API migration here, not in December) | 100 | |
| Sat 16 Jan | Economy + store pass + boosts merged into 3 | 99, 97 | |
| Sat 23 Jan | **No release**; Gem Event page live 2 weeks ahead | - | Buffer |
| Sat 30 Jan | **GEM ALTERS 16-20** big update with countdown (code GEM) | new prompt | Alter-15 players need more |
| Sat 6 Feb | Lunar New Year: Collection book (code LUNAR) | new prompt | |
| Sat 13 Feb | Valentine's/Carnival: real-player arm wrestling + weekly board | new prompt | Social, PvP |
| Sat 20 Feb | **No release** | - | Buffer |
| Mar 2027 | Spring updates: Gem alters 21-25, a spring/Easter (28 Mar) event, subscription decision | later | |
| When needed | Star track 101 (Legacy cards) once anyone is past Alter 10 on run 2; latest 9 Jan | 101 | Needs 105 first |
Every update week: one code, the name tag, an Update Announcement, a Community announcement at a **fixed 15:30 UTC** (push max 1 per 7 days), an apology code after any bad bug, 10-15 min on a cheap Android before publishing. No-release weeks: a code from the console only.
**Owner's pace rule:** max ~2 prompts per update, Sunday review 20 min, one no-release week a month. If a week runs late, the update moves a week; never publish untested on a Saturday night.
**Gates** (from the rescue plan): Gate 1 (21 Nov) = first spurt reached by 60%+ of new players, 5-min retention 40%+, D1 6%+ and rising. Gate 2 (5 Dec) = D1 8%+. **Read them on organic players only, pooled over 7 days, and write the player counts next to each %** (at our size a few players move D1 a lot; ad players play about half as long). Not working → fix the worst funnel step + new thumbnail; twice not working → maintenance mode (weekly code + Power Hour keep running) + next game.

---

## Every part of the game: what changes now (on top of the 29 Oct decisions)
### First minutes (prompt 106, 7 Nov)
- First Growth Spurt **~2 min for a real new player (with the new-player 2x)**; spurt 2 ~5 min; total to 6'0" stays ~1 h; nobody mid-run gets a higher goal.
- After Spurt 1 things come **one per minute** (Beach Gym line → calendar → playtime gift → tips → notification opt-in), never all at once.
- The "This could be you" Dante camera move (91 item 2) is dropped: it would add a step back.
- The Growth Spurt bar starts **20% full** ("WELCOME BONUS"), a first-rep reward in the first 15 s (exists, check).
- Tutorial **4 steps** (walk with a beam → lift with a bouncing arrow → watch the bar → GROW); other tips become just-in-time (shake tip the first time stamina is low, stats tip after Spurt 1, Coach Dex after Spurt 1). Dex lines max 1 short sentence.
- **Timed hints**: 10 s of doing nothing → the arrow/beam pulses again.
- PLAY tappable within 2 s of the menu; nothing else on screen in minute 1 except the Growth Spurt card, Future You and coins.
- The first Growth Spurt is the "moment of joy": short, loud, gold, then "Next: Beach Gym".
- Funnel: a **new funnel "Onboarding_v2"** (the old one stays as history, so the dashboard doesn't show fake drop-offs); players saved mid-tutorial jump to the matching new step; on/off Config switch so it can be undone live.

### Progression, alters, Hall of Fame
- Alters: prompt 96 as written (measure, +0.8" each, mass monster goal, never shrink, flat goals, a reward every alter).
- **Run Cards (prompt 105):** at every alter pick 1 of 3 cards (muscle gains, trainer, coins, feat, stamina; Common/Rare/Epic/Legendary with odds shown; Epic+ appear once you hold 2 of the same type = builds; one free reroll per pick, **never for Robux**). Go in the BODY part of the GAINS number (soft stacking, shown in "My Build"), switched off in shows, Showdown and arm wrestling. Reset at the Hall of Fame; **1 Legacy card kept per star** (this replaces the planned "Star Perks"; max 3 Legacy cards active, the rest stored). Veterans' missed picks are exempt from the Hall of Fame cheat check. On/off Config switch.
- Hall of Fame: prompt 95 + star track 101 (Star Perks → Legacy cards).
- Prestige check (Pecorella): a reset should feel worth it when it gives +50% to +200% power, and run 2 must go further faster. Star 1 = x2 EXP + start at Spurt 3 fits; check the real run-2 time after launch.

### Come-back hooks (prompt 107, 28 Nov)
- **POWER HOUR** every Saturday at **12:00 and 19:00 UTC** (one hour each) on every server, automatic: x2 gains (applied after the soft line, and the server's gains-per-minute check knows about it), a golden "Power Rack" in the plaza, an earned cosmetic from a rotating list that comes back later (never sold, no fear of missing out), listed as a recurring Experience Event. No countdown card: just a "POWER HOUR NOW" pill while it's on. Runs even if nobody touches the game (maintenance mode friendly).
- **Rested gains:** away 8 h+ → x2 EXP for 15 min, shown on the Welcome back card with the offline coins; uses today's boost tile system (97 converts it later).
- **Streak:** milestone animation on day 3 and day 7 (grace day exists).
- **Friends:** invite with launch data (friend spawns next to you), Party members land in the same server, the "train together +10%" bonus gets a visible chip.
- **Notifications (13+ opted in, max 1/day):** "Your muscles are rested: x2 gains waiting" and "<friend> passed your height!". Ask for opt-in after the first Growth Spurt (in the one-per-minute queue), never before. Sending needs Open Cloud: Claude Code checks it can be sent from our servers; if not, notifications are dropped (they're a small part).
- **Wellbeing:** after 2 hours in one session, one calm optional line "Great training! Water break?" (setting to turn off). Fits the UK Children's Code; costs nothing.

### Gains and the MAX BOOST cap (owner, 29 Oct: "there shouldn't be any max boost cap")
- **No hard cap and no MAXED state any more.** Soft stacking instead: BODY x TRAINERS x BOOSTS x GEAR multiply; bonuses inside one part add; the total counts fully up to x10, extra above x10 counts half, above x20 a quarter (line +x1 per alter tier and per star). Moment boosts (PUMPED, BIG REP, Power Hour, rested) apply after, in full. Coins work the same way.
- Why not no limit at all: multipliers multiply each other (x40+ possible), so stages would take seconds, the fixed prices would become pocket change and boards would go to whoever paid most.
- Never weaker than today for any existing player; pacing checked for a free player vs a heavy payer (prompt 91 item 9, 14 Nov).

### Economy and prices
- Fixed values (103) stay; re-rack stays the owner's LVL formula.
- Every new source needs a sink (Roblox economy guide): Power Hour pays a cosmetic, not coins; Run Cards give % not coin piles.
- Watch the economy events: if average coin balances keep rising week after week, add a cosmetic sink, not price rises.
- Event currency for big seasons (candy, snow) later, so the main currency stays stable (January at the earliest).

### Monetization
- Passes/prices as in the prices note. **No new products** until D1 ~10%.
- **PolicyService:** restricted players don't see coin packs, DNA Robux products or the Starter Pack; the odds button says "Odds"; the Robux Luck supplement is removed (108).
- Prices always from Roblox (Managed Pricing/regional pricing on).
- LATER (Gate 2+): "Gym Club" subscription 99 R$/month (daily coins + a monthly cosmetic, no power). Rewarded video ads: not for us.

### Trainers, auras, gear, boosts
- Unchanged from the 29 Oct notes except dates: Aura Altar 2 Jan, boosts merge 16 Jan, gear ladder (98/99), trainer pools per gym later.
- Pity always visible and carried over; duplicates always useful; no near-miss animations (a roll never "almost" shows a better rarity).

### Social and competition
- Server size 12; plaza as the show-off place (statues, boards, server crown, Power Rack).
- Shows/Showdown/arm wrestling ignore Run Cards and paid boosts stay out of competitions.
- Real-player arm wrestling + weekly board: 13 Feb.

### World
- The Hall of Fame tower must be visible from spawn (the big landmark that pulls players); the main path brightest (squint test); every gym entrance shows what's inside; GO TO teleports stay.
- New places (Golden Era, rooftop) built to the Pro Gym budget.

### UI
- Bottom-left and bottom-right stay free on phones (Roblox thumbstick and jump). Audit in 100.
- One rarity ladder everywhere: grey → green → blue → purple → gold → Mythic red, **with star counts** (never colour only). The UI's gold for progress numbers stays; rarity gold always comes with stars + glow.
- Same X in the same corner; grey + lock for locked; red price when you can't afford it.
- New screens use AutomaticSize + wrapping and respect the player's text size (old screens stay).

### Art and characters
- One stylised look, no realistic free models, no shirtless marketing.
- NPCs speak in 1-line barks, personality through poses and reactions (kids skip text).

### Music and sound (prompt 100 + small bits in 106/107)
- New music only from Creator Store partner catalogues or the existing licensed library; no lyrics; separate music/SFX sliders (exist).
- **Rep tick rises one semitone per rep inside a set** (resets at "Set done"), clank keeps its random pitch.
- Each rarity has its own chord; one UI sound family.
- Music ducks under reward sounds (AudioCompressor sidechain in the new Audio API, migrate in 100).
- Check loudness on a phone speaker and on headphones.

### VFX
- Reward VFX: anticipation → burst → settle, bigger by rarity, ≤100 particles/s per emitter on phones, flipbooks with a fallback (they switch off on low-memory phones).
- **Max 3 flashes per second**, never a red strobe; `GuiService.ReducedMotionEnabled` turns off shake, hit-stop and zooms (not just tweens).

### Performance
- Every Saturday: 10-15 min on a cheap Android (heat, FPS, memory in F9). Textures ≤512 px for most things; no half-transparent parts where avoidable; streaming on.

### Data, security, safety (prompt 108)
- Keep our session-locked DataStore; add `dataVersion` + step-by-step migrations by item ID (never delete old IDs).
- **Forward-safe saves:** old server code never saves over data with a higher `dataVersion`; unknown fields are always kept; after a publish that bumps the version, use "Migrate to latest update"; never roll the place back past a version bump (switch the feature off in Configs instead).
- Weekly .rbxl backup + git for scripts.
- Right to Erasure: webhook to a channel the owner reads + an admin console command `erase <userId>`.
- Server-side: every remote checks type/range and is rate-limited; gains per minute capped using the player's real multipliers (so Power Hour and boosts are never cut); leaderboard/statue sanity (95).
- TextChatService check (in 108), no links in game, text filtered, calm wording, no fake timers.
- Analytics event names never contain ids (`RunCard_Picked` with the id in a custom field), so we stay under Roblox's 100 event names.

### Analytics and weekly review (every Sunday, 20 min)
- Read (organic players, last 7 days, with player counts): new players, first-spurt %, 5-min %, D1, D7, session length, step funnel (96), payer %, Error Report, Power Hour attendance (107), Run Card picks (105), notification opt-ins.
- Write one line per number in the week's progress note; fix ONE biggest leak next week; undo with Configs if a change hurt.
- Targets: D1 4% → 6% (Gate 1) → 8% (Gate 2) → **10% (the median of games with 1M+ monthly players; a stretch for us, not a promise)**; session ≥12 min (also earns Creator Rewards at 10+ min); D7 ≥1.6%.
- A/B Experiments only from ~500 DAU; until then Configs.

### Store page and marketing
- Thumbnails: personalisation with 3-5 (weak at our size, still free); the ad test is the real thumbnail test (per-creative stats).
- Gameplay video stays first (videos now play on Home); re-record after big visual updates (3 uploads/month).
- **Event page with a countdown** for the big ones (Hall of Fame now, Golden Era 28 Nov, Gem alters 23 Jan).
- **Standout Games nomination** after the 7 Nov update.
- Short clips (TikTok/Shorts) when the owner has time: open on the growth moment, vertical, captions; a Creator Rewards share link on each. Optional, never blocks updates.

### Ads and the brother's deal
- Test: "Plays", All/New players, 7 days, not paused, 5-10 thumbnails. Judge: paid players' first-spurt %, D1 and playtime vs organic, cost per play.
- Scale only after Gate 2 passes and paid D1 is close to organic.
- Check first that DevEx works from Myanmar for the owner's account.
- Deal (not legal advice; write it down and both sign): option A (brother 70% of revenue until he has 1.5x his ad money back, then 15% for 12 months); "revenue" = DevEx USD actually received from the game; monthly statement from Creator Hub; DevEx needs 30,000 Robux minimum ($114 at $0.0038/R$), so the first payout can take months; nothing owed if the game shuts down; the game and its IP stay the owner's; the owner decides when ads run.

### Other games
- SPEED ARC stays paused until GYM ARC D1 ≥8%. MOW ARC on hold.

---

## Reviewer's attack (29 Oct) and what changed
An independent reviewer read the plan, the prompts and the current feature notes and attacked them. What it found and what I did:
| # | Problem found | Fixed how |
|---|---|---|
| 1 | Kids & Select had no backup; Plus needs 2 months | Pay the refundable fee; ad test collects the 250 plays; truthful questionnaire; backup if Myanmar ID fails |
| 2 | Save versions could be overwritten by old servers or a rollback | Forward-safe save rules in 108 |
| 3 | Order was wrong (105 needed 108; 106 changes run-2 pacing) | 108 on 7 Nov, not slippable; 95's pacing re-run on 14 Nov; rested uses today's boost tiles |
| 4 | Weeks over-full (5 prompts on 7 Nov), Audio API migration in December | ~2 prompts a week, no-release weeks 26 Dec, 23 Jan, 20 Feb, Audio API in January, Golden Era mockups 2 weeks early |
| 5 | Starter Pack (has a DNA token) and a Robux Luck item escaped the paid-random fix | Both handled in 108; Luck removed |
| 6 | Multipliers piling up; server gain cap could cut Power Hour | Power Hour/rested applied after the soft line (the hard cap itself was later removed by the owner) and known to the server check; max 3 Legacy cards active |
| 7 | Power Hour at 01:30 Myanmar/Indonesia/Thailand; countdown = pressure on kids | Two Power Hours (12:00 and 19:00 UTC), no countdown, rotating cosmetics come back |
| 8 | Tutorial contradictions (Dante step), funnel would show fake drops, popups pile up after Spurt 1 | Dante step dropped, new funnel Onboarding_v2, one thing per minute after Spurt 1, mid-tutorial saves migrate |
| 9 | Older notes still mention the skill tree, rush hour, Star Perks, Champion Arena, 8 feet | Clean-up pass on those notes (same day) |
| 10 | "4 to 8 feet" overpromises (top is 7'0") | "4 to 7 feet" everywhere |
| 11 | Gate numbers too small / mixed with ad players | Organic only, 7-day pools, player counts shown; 107 moved off the gate day |
| 12 | Max 12 players splits a 14-player game | Max 20 until CCU 30+ |
| 13 | Some claims too strong | Reworded (median = big games only; weekly-to-biweekly updates; Gym League cause is one of several) |
| 14 | Calendar gaps | Winter code 10 Dec from the console; 16/30 Jan covered; Community push at a fixed 15:30 UTC; plan to March |
| 15 | Notifications need Open Cloud; event names with ids; veterans' card picks look like cheating; codes/playtime still pay "minutes"; no on/off switches | All added to 105-108 and 103; notifications dropped if they can't be sent from our servers |
Not changed: fixed coin packs stay fixed (owner's rule); if they feel small late-game, the 16 Jan store pass looks at it again.

---

## What I decided NOT to do (and why)
- No switch to ProfileStore (wipe risk). No Server Authority (physics cheats aren't our problem). No rewarded ads (2,000 MUV, no under-13s). No new Robux products before D1 10%. No trading. No realism pivot. No relaunch as a new place (we'd lose favourites/visits; only an option at Gate 2 failure). No streak loss punishments. No near-miss animations. No notifications to kids under 13 (Roblox doesn't allow it anyway).

## New prompts from this plan
- [[2026-10-29 GYM ARC Prompt - 105 Run Cards]] (21 Nov, with 96)
- [[2026-10-29 GYM ARC Prompt - 106 First 3 minutes]] (7 Nov)
- [[2026-10-29 GYM ARC Prompt - 107 Come-back hooks]] (28 Nov)
- [[2026-10-29 GYM ARC Prompt - 108 Safety, data and policy pass]] (7 Nov, not slippable)

## Progress 29 Oct (later)
- Prompt 95 done in Studio by Claude (not published): [[2026-10-29 GYM ARC Prompt 95 done - Hall of Fame fixes]]. Starter Pack is 49 R$ on Roblox now.
- Playtest of the first 6 minutes: [[2026-10-29 GYM ARC Playtest - first 6 minutes]] (21 problems; the fixes are added to prompt 106).
