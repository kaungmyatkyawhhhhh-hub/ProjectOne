---
date: 2026-11-07
tags: [galaxy, monetization, retention, audit]
---
# Galaxy Incremental: monetization + retention check (7 Nov, read from Studio)

Claude read the scripts and GameConfig in Studio (read-only, while the game was in Play mode). It searched by keyword, so Claude Code should confirm the "missing" items.

## Monetization
| Item | Status |
|---|---|
| Game pass x2 Stardust 249 | live (2070906361) |
| Product Offline x2 25 | live (3728719049) |
| VIP 399 (+25% stardust, +1 Essence per Supernova, VIP trim) | **missing**: in the store mock-up, not created |
| +1 Core Slot 349 | **missing** |
| Auto Roll 199 | **missing** |
| Premium benefits (Premium payouts + a small Premium perk) | **missing** |

## Retention
| Feature | Status |
|---|---|
| Daily rewards + streak, quests, offline earnings, codes, group +10%, friends +10% (max 3), Free Rewards / like board, badges, leaderboards, autosave, analytics | in |
| Badges Mythic + Celestial Collector | ids still 0 (pending creation) |
| Playtime gifts (claim after 5/10/20/40 min) | **missing** |
| Favourite prompt (once, after the first Supernova) | **missing** |
| Invite friends button (SocialService:PromptGameInvite) | **missing** |
| Experience notifications ("your offline stardust is full") | **missing** |
| Share Links (Creator Rewards) in invites | **missing** |
| EventController (2x Stardust hour at launch + weekly) | **missing**: the launch plan needs it |
| What's New panel + ServerRestartScheduled save + update gift | **missing** |

## Prompt for Claude Code
```text
GALAXY INCREMENTAL – MONETIZATION + RETENTION BEFORE THE ALPHA (21 Nov). Quality over speed. Don't publish.

First CONFIRM which of these already exist (I searched by keyword, so I may have missed some); build only what's missing. Follow the Roblox Playbook rules: no fake timers, no "was" prices, no paid random items, never weaken what players own.

MONETIZATION
1. Game passes (I'll create them in Creator Hub and send the ids; until then id 0 = hidden):
   - VIP 399: +25% stardust, +1 Essence per Supernova, VIP name trim.
   - +1 Core Slot 349: equip 1 more Star Core.
   - Auto Roll 199: the Forge rolls by itself while you have Essence.
   Write them into GameConfig.Passes with id 0 and wire the store cards (they already exist in the store design).
2. Premium: Roblox Premium players get +10% stardust (a "PREMIUM" chip in the boosts panel). Non-Premium players see it greyed, with a tap that opens PromptPremiumPurchase. Shown once per session at most.

RETENTION
3. Playtime gifts: gifts at 5 / 10 / 20 / 40 / 60 min of this session (stardust, Essence, a 2x for 10 min), with a gift icon + timer in the HUD (a real timer, it counts real playtime). Resets daily.
4. Favourite prompt: AvatarEditorService:PromptSetFavorite once, right after the player's FIRST Supernova (never again if they answer).
5. Invite button in the friends chip: SocialService:PromptGameInvite (only if CanSendGameInviteAsync). The invite carries a Share Link where supported.
6. Experience notifications: opt-in prompt after the 3rd session; send "Your offline stardust is full!" when the offline cap is reached (max 1/day) and the weekly update message.
7. EventController: config-driven timed events (Events = { {name="2xStardust", start=<UTC>, minutes=60}, ... }); every server checks the time itself; a banner with the real time left. I need it for the alpha launch 2x hour on Sat 21 Nov 15:00 UTC and every Saturday after.
8. What's New panel: opens once per new version (WhatsNew config). Handle game.ServerRestartScheduled: banner "Update incoming!", save everyone, a one-time update gift per version on next join.
9. Forge collection badges Mythic + Celestial: I'll send the ids; keep 0 until then.

TEST + REPORT (stop after): which of 1-9 already existed, PC + phone screenshots of each new thing, a 2-client test of the invite + playtime gifts, and the EventController proven in Studio with a start time 2 minutes from now.
```
