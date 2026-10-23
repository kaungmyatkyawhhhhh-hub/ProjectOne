# Break A Bed: Getting on the Roblox charts

#break-a-bed #growth

Back to [[Break A Bed/Project Overview|Project Overview]].

Owner's goal (2026-10-12): **get Break A Bed onto the Roblox charts** (Trending in Simulation, Up-and-Coming).

## How the charts pick games (what we're optimising)
Roblox's discovery ranks games on **engagement**, not on art or ad spend alone. In Creator Hub → Analytics, these are the numbers that matter:
| Metric | What it means | Where we are | Target |
|---|---|---|---|
| Click-through (impressions → plays) | Does the icon make people click? | new icon, not measured yet | 5%+ |
| **Day 1 retention** | % of new players who come back the next day | **0%** (2026-10-12) | 15% first, then 25%+ |
| Day 7 retention | % still playing a week later | – | 5%+ |
| Average session length | minutes per visit | **1.4 min** (2026-10-13) | 15+ min |
| Like ratio | 👍 / (👍+👎) | **83%** (2026-10-13) | 85%+ (trending games are 90–97%) |
| Concurrent players | players online at once | – | steady growth day over day |

**The honest part:** ads and a nice icon bring players in, but the charts only push games that **keep** them. With 0% Day 1 retention, every ad Robux mostly leaks out. So: fix retention first, then spend on ads.

## The plan, in order
### Week 1: measure + stop the leak
**Built 2026-10-13:** item 1 (funnel), item 9 (like goal board) and item 10 (favorite popup), see [[Break A Bed/2026-10-13|2026-10-13]]. Items 2–4 are done by the owner on the Creator Dashboard.
1. **Funnel tracking** (Claude Code): log each step with `AnalyticsService:LogFunnelStepEvent` ("onboarding" funnel): joined → first punch → 10 punches → first bed broken → bought Wooden Post → reached bed 3 → bed 5 → claimed first gift → stayed 10 min. Creator Hub → Analytics → Funnels then shows **exactly where players quit**. Fix the biggest drop first.
2. **Publish the new icon + thumbnails** (`Ad Assets/icon-512-gfx.png`, `thumbnail-4-gfx.png`) and keep the old ones in the rotation. Check click-through after 3–4 days.
3. **The title gets a tag**, like every trending game: **"[🎃HALLOWEEN] Break A Bed"** now (owner picked this, 2026-10-12; change it back or to "[UPD] Break A Bed" after Nov 1), then "[UPD]" or "[NEW BEDS]" with each update. Change it on the Creator Dashboard.
4. **Server size 12** (instead of the default): servers fill faster, so players see others breaking beds, which feels alive.

### Week 2: reasons to come back (from the [[Break A Bed/Retention Plan|Retention Plan]])
5. **Daily Quests** with a "New quests in 05:12:33" timer.
6. **OP Day 7** daily reward, shown from day 1.
7. **Boost Inventory** (save free boosts for next time).
8. **AFK Zone** (long sessions, gifts unlock while away).

### Likes and favorites (they count for ranking)
9. **Like goal board** at spawn: "👍 1,000 LIKES = NEW CODE!" with the current count (`MarketplaceService`/`HttpService` can't read likes from inside the game reliably, so update the number by hand with each update, or just show the goal). New codes are released at each goal.
10. **Favorite prompt at a happy moment**: right after the player's **first bed break**, a small popup "Enjoying it? ⭐ Favorite to find it again!" with `AvatarEditorService:PromptSetFavorite`. Once per player, never during the guide. (No reward for it: Roblox rules.)

### Every week after: updates
11. **One update a week** (new beds / a new zone / an event bed), each with: a new code, a title tag, an update log board at spawn ("NEW: Crystal Zone!"), and a server announcement. Trending games update constantly; it's what the charts reward.
12. **Seasonal events on time:** Halloween crate now (ends Nov 1), then a Christmas crate from Dec 1.

### Ads (only once Day 1 retention is 10%+)
13. Restart Sponsored ads with the new icon, a small daily budget for 7 days, and compare Day 1 retention of ad players vs. normal players.
14. Free promotion: 15–30 s TikTok / YouTube Shorts of a big bed break with huge numbers ("I broke the INFINITY BED 😱"). Short clips are the cheapest way to get players.

## Check every Monday
Click-through, Day 1 / Day 7 retention, session length, the funnel's biggest drop, like ratio, and Robux per player. Write the numbers in the session note so we can see if each change helped.

## Game description (2026-10-12, Halloween version, 732 of 1,000 characters)
Only list codes once the CODES row in Settings is live. After Nov 1, replace the first line with the latest update.
```
🎃 HALLOWEEN EVENT! Open the limited Halloween Aura Crate before Nov 1 and get the 0.1% REAPER aura! 💀

👊 Punch, get stronger and BREAK EVERY BED!

💪 Train on punching posts to get stronger (it punches by itself!)
🛏️ Break beds for Cash — from a Cardboard Bed to the INFINITY BED
💥 Land CRITICAL hits for huge damage
💰 Buy better posts and unlock harder beds
🎁 Free Gifts, Daily Rewards and a Spin Wheel
🏆 Climb the Total Damage leaderboard

🎟️ CODES (Settings ⚙️ → Codes):
RELEASE • BREAKABED • MYANMAR (group members)

👍 Like the game! New code at 1,000 likes!
⭐ Favorite to get notified of updates!
👥 Join Myanmar Builders Club for +10% Strength!

🔄 New update every week!
```

## Problem found (2026-10-13): average session is only 1.4 minutes
Most players leave in the first minute, before the game's fun starts (the first bed break, gifts, quests). Find out *where* before changing more:
1. **Date range:** check whether the 1.4 min is mostly from before today's update (Analytics → set the range to after the publish).
2. **Funnel:** Onboarding funnel step counts: joined → first punch → 10 punches → first bed → Wooden Post. The step with the biggest drop is the problem.
3. **Device split:** session time on phone vs PC. Much lower on phone = phone UI/lag problem.
4. **Traffic source:** ad players vs others. Ads to "All players" bring many who leave in seconds; that alone pulls the average down.
5. **Load time:** how long until a player can move and punch, on a low-end phone.

Likely fixes, depending on what the data shows:
- **Spawn next to the Straw Post** with the guide already pointing at it, so the first punch happens in under 10 s.
- **Fun in the first 30 s:** first bed break within 30 s (a cheap Cardboard Bed right by spawn), big effects and cash.
- **Nothing blocking at join:** no pop-ups before the first bed break (already the rule; double-check on phones).
- **Load faster:** preload only what the first minute needs; stream in the rest.
- **Performance on phones:** Low Graphics on by default for low-end devices; check FPS with many players.

## Funnel results (data up to Oct 13, 6:30 AM; only 42 new players, so numbers are rough)
| Step | Players | Left at this step | Still here |
|---|---|---|---|
| 1. Joined | 42 | – | 100% |
| 2. First punch | 37 | 12% | 88% |
| 3. 10 punches | 37 | 0% | 88% |
| 4. First bed broken | 34 | 8% | 81% |
| 5. Bought Wooden Post | 29 | 15% | 69% |
| 6. Reached bed 3 | 26 | 10% | 62% |
| 7. Reached bed 5 | 25 | 4% | 60% |
| 8. Claimed first gift | 23 | 8% | 55% |
| **9. Stayed 10 min** | **13** | **43%** | **31%** |

**What it means:** the first minutes work (81% break a bed, 60% reach bed 5). The big leak is **between ~2 and 10 minutes**: after bed 5 and the first gift, almost half leave. That's when progress slows (each new post needs more grinding) and nothing new happens. The 1.4 min average session doesn't match this (31% staying 10+ min would give a higher average), so it's probably from older days or counts players who left while loading; recheck it with the date range after the update.

**Fix: something new every ~60 s in minutes 2–10** (see the prompt in the chat / session note):
- Re-tune beds 5–10 and posts 3–7 so a new bed or post comes every 45–75 s for a new player (no grind wall before 10 min).
- Show the next goal clearly: "Next gift in 1:55" right after the first claim, and the next bed bar.
- Daily Quests (now live) give goals in this window; the AFK Zone comes next.

## Fix plan for minutes 2–10 (2026-10-13)
**Built 2026-10-13** (items 1–6, plus the funnel's new Loaded and Played 3/5/7 Min steps in a new "Onboarding2" funnel), see [[Break A Bed/2026-10-13|2026-10-13]]. Check Onboarding2 in Creator Hub 1–2 days after publishing.

Goal: "Stayed 10 min" from 31% to 45%+. Build in this order:
1. **Pacing:** something new every 45–75 s until ~10 min: re-tune beds 5–10 and posts 3–7 (measure first, change only those).
2. **Starter Quests (first session only):** a short chain of 6 tiny goals shown in one small card under the stats, one at a time, each with a quick reward and a ding:
   1. Break the Air Mattress (bed 2) → $ · 2. Buy the 3rd post → $ · 3. Reach bed 5 → x2 Strength 3 min · 4. Claim 2 free gifts → +1 Spin · 5. Spin the wheel → $ · 6. Reach bed 7 → **FREE Halloween crate roll** (see 3).
   After the last one the card turns into the Daily Quests button hint. Saved; never shown again.
3. **A free Halloween aura roll at the end of the Starter Quests (~8–10 min):** opens the real crate animation once, for free, so every new player sees the aura system and owns an aura (most get Ghost). It's the strongest "wow" moment the game has, and it shows the crate for later purchases.
4. **Always a visible next goal:** the next-bed bar ("Next: Water Bed · 💪 340 / 500") always on screen; when a new bed or post becomes affordable, a bouncing arrow + beam points to it (same style as the guide).
5. **Make waiting active:** while auto-training, a small hint "Click to punch 2x faster!" (the first 3 sessions only) and a combo counter for fast clicks (x5, x10 COMBO with a small Strength bonus).
6. **Come-back hook:** the game can't detect a player about to leave, so at ~8 min show once: "Come back tomorrow: Day 2 reward + new quests!" toast once.

## Sales check (2026-10-13)
- Robux spent since launch: **R$537** (passes 501, developer products 36). Two big buys came on the night of 10/11 (~R$200) and the morning of 10/12 (~R$250), then **nothing from 10/12 ~7 AM to 10/13 evening**.
- **To check:** (1) do purchase prompts still open in the live game (buy a pass and a product, then cancel; F9 for errors)? (2) Did visits/players also drop over the same hours (then it's traffic, not the shop)?
- With only ~40–100 players so far, a day with no sales can be normal. Most Robux comes from 1–2 buyers.
- **Engagement data (seen 2026-10-13):** Roblox's charts only go up to **Oct 11** (engagement data comes in 1–2 days late), so Oct 12–13 aren't visible yet.
  - Oct 11 had about **155 new players**. The "23 a day" average is low only because Oct 5–10 were zeros before launch.
  - **First-session retention:** 36.7% still playing at 5 min. The steepest drop is in the **first 4 minutes** (100% → about 38%), then about 13% at 15 min and about 5% at 30 min (the content runs out there).
  - **Sales per player:** about R$3.4 per player so far (R$537 / ~155), which is fine for this size.
  - **To check next:** Oct 12–13 players once they load, and the ad's impressions/clicks for Oct 12–13 in Ads Manager. If the ad stopped delivering, traffic and sales stop together.
- **Correction (owner, 2026-10-14):** the launch buyers were **not fans**. The group had 1 member at release, so they were strangers. So something in the game likely changed on 10/12, the day sales stopped. Suspects, most likely first:
  1. **Purchases broken in the live game.** On 10/12 the whole shop was rebuilt (25 products, new ids, renamed Cash packs, a Studio-only test hook, boost levels). Test: buy the cheapest product for real in the live game and check you get it (F9 for errors). Check there is exactly one ProcessReceipt.
  2. **Too much free stuff.** Also on 10/12–13: 12 free gifts, the free/exclusive chest, the Free Gift x2 Strength, spins, codes, daily rewards, quests, OP Day 7, all giving boosts. Players who get x2/x3 boosts for free have little reason to buy them.
  3. **Fewer buy moments.** The "Need more Strength?" offer at a locked bed was replaced on 10/13 by BREAK IT only when the prompt is used.
  4. Traffic and the Ages 16+ limit (see [[Break A Bed/Ads|Ads]]).
- **Tested (owner, 2026-10-14):** a real purchase in the live game works, so suspect 1 is ruled out. Next: make free boosts weaker than paid ones.
- **Free vs paid boosts plan (2026-10-14):** **Built 2026-10-14**, see [[Break A Bed/2026-10-14|2026-10-14]] (the toast says "x3 for 10 min": the x3 products stay 10 min).
  - Free rewards (gifts, chests, spins, codes, daily, quests) give **only x2** boosts, at most 15 min each. **x3 and higher are only sold.** Swap some free boosts for Cash/Strength rewards.
  - Paid boosts **stack on top of** a running free x2, so a free boost never makes a purchase pointless.
  - When a free boost runs out: one small toast "Boost ended! Get x3 for 15 min" with a BUY button. At most once every 20 min.
  - In the shop's BOOSTS tab, show "FREE x2 → BUY x5" so the paid one looks clearly better.
- **Monetization charts (seen 2026-10-14):** paying users peaked at about **5 in one day** around Oct 11–12, then fell toward 0. The top-10,000 benchmark is about 15–27 a day. Payer conversion spiked to ~50% on the first day (very few players, so 1–2 buyers is a big %), then dropped near 0. The 1.92% "average" is spread over weeks with no players, so ignore it. The charts end around Oct 12–13 (data comes in late). Conclusion: the early buyers were a handful of players on a small day. The drop is mostly too few players, not a broken shop.

