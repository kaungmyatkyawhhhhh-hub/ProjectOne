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
| Average session length | minutes per visit | – | 15+ min |
| Like ratio | 👍 / (👍+👎) | – | 85%+ (trending games are 90–97%) |
| Concurrent players | players online at once | – | steady growth day over day |

**The honest part:** ads and a nice icon bring players in, but the charts only push games that **keep** them. With 0% Day 1 retention, every ad Robux mostly leaks out. So: fix retention first, then spend on ads.

## The plan, in order
### Week 1: measure + stop the leak
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
