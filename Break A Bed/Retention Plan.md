# Break A Bed: Retention Plan

#break-a-bed #retention

Back to [[Break A Bed/Project Overview|Project Overview]].

Based on tips from a developer whose game peaks at 1K players (TikTok, shared by the owner 2026-10-12), checked against what Break A Bed already has.

| Tip | Break A Bed now | To do |
|---|---|---|
| Playtime rewards | Planned: [[Break A Bed/Playtime Rewards\|Free Gifts]] | Build it |
| AFK zone | ❌ | **AFK Zone** (below) |
| Lots of content | 25 beds, 17 posts | **Rebirths**, then a new zone of beds per update |
| Login rewards, OP day 7 | ✅ 7-day daily reward | Make **day 7 OP** (below) |
| Quests for coming back | ❌ | **Daily Quests** (below) |
| Boosts players save for next login | ❌ boosts start right away | **Boost Inventory** (below) |
| Events + frequent updates | ❌ | **Weekend event** + an update every week |
| Fun tutorial, show don't tell | Planned: [[Break A Bed/New Player Guide\|New Player Guide]] | Use arrows, beams and effects, very little text |
| First 60 seconds fun | Planned (guide) | First bed breaks in under 30 s |
| Trailer + thumbnails that show the game | Drawn ad art | Real gameplay thumbnails + a short trailer |

## New features
**Built 2026-10-13:** Daily Quests, Boost Inventory and OP Day 7 (see [[Break A Bed/2026-10-13|2026-10-13]]). Next: AFK Zone.

### AFK Zone
- A glowing pad area near spawn: stand in it and every 60 s you get Strength (your best post × 20) and a little Cash. A timer above your head shows the next payout.
- Every 10 minutes AFK = +1 Spin.
- Keeps players online (playtime) and makes Free Gifts unlock while they're away.
- Roblox kicks idle players after 20 minutes, so the zone shows a small "Stay in the zone" reminder. Use a gentle camera nudge only if needed.

### Daily Quests (reset every day at the same time for everyone)
- 3 quests a day, e.g. "Break 30 beds", "Punch 500 times", "Claim 3 free gifts", "Break a new bed".
- Each pays Cash + a boost **into the Boost Inventory**. Finishing all 3 gives a bonus Spin.
- A "New quests in 05:12:33" timer pulls players back the next day.

### Boost Inventory
- Free boosts (from quests, the daily reward, gifts, spins) go into an inventory instead of starting right away. Players use them when they want.
- Boost time is saved, so players come back to use the boosts they saved up.
- Bought boosts still start right away. An inventory button with a count badge sits on the HUD.

### OP day 7
- Day 7 of the daily reward becomes big: **x3 Strength 30 min + x2 Cash 30 min + 5 Spins + a lot of Cash**, shown as a gold card in the daily reward menu so players see it coming from day 1.

### Rebirths (from [[Break A Bed/Ideas|Ideas]])
- Reset Cash and Strength for a permanent +50% Strength (stacks), a Rebirth counter on the leaderboard, and a new bed skin color. It's unlocked after the Infinity Bed (or bed 15, so it comes sooner).

### Weekend event
- Every Friday–Sunday: x2 Strength for everyone, plus a banner "WEEKEND EVENT: x2 STRENGTH" with a countdown. Simple, but it gives players a reason to come back.

## Order to build (after the current plans)
1. New Player Guide → 2. Free Gifts → 3. Daily Quests + Boost Inventory → 4. OP day 7 → 5. AFK Zone → 6. Rebirths → 7. Weekend event → then one content update a week (new beds, a new zone, a limited event bed).

## Thumbnails and trailer
- Take real screenshots in Studio of the coolest moments: a bed shattering with Cash flying, the long path of glowing beds, the leaderboards. Add the title on top.
- A 15–30 s trailer: punch → bed breaks → huge numbers → the Infinity Bed. Record it with Roblox's video recording (Esc → Record) or OBS.

## Next retention features (2026-10-13, after the funnel)
Already in the game: daily reward with OP Day 7, Daily Quests, Boost Inventory, Free Gifts, codes, like goal, favorite popup, Halloween crate. These give reasons to come back; the ones below add the missing ones. Build in this order:
1. **Offline earnings:** when a player comes back, a popup "While you were away you earned 💪 X and $Y!" with COLLECT (and "x2 with Robux" later). Based on time away (max 8 hours) × their best post / bed, at a low rate. Simulators rely on this: players come back to collect.
2. **Experience notifications (opt-in):** ask players once (after the first daily reward claim) with `ExperienceNotificationService:PromptOptIn`, then send "🎁 Your daily reward is ready!" / "⚡ New quests are here!" / "🎃 Halloween crate ends tomorrow!". Sending goes through Roblox's Open Cloud notifications API; Claude Code checks the current docs for how (it may need a small outside server or Roblox's built-in triggers).
3. **Play with friends:** an "Invite friends" button (`SocialService:PromptGameInvite`) and **+10% Strength per friend in the server** (max +30%) shown on the HUD. Players who play with friends come back far more often.
4. **Rebirths:** the long-term goal (reset for a permanent Strength boost + a rebirth counter and title), unlocked around bed 12.
5. **Event countdowns on screen:** "🎃 Halloween ends in 18d 4h" on the crate button and in the shop, so players know to come back before it's gone. Same for every future event.
6. **Weekly updates + group shouts:** each update gets a group shout and a new code ("New code in the group!"), which brings old players back.
