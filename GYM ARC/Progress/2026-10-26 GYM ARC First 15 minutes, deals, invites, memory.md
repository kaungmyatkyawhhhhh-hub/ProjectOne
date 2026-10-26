---
date: 2026-10-26
tags: [gymarc, progress, retention, monetization, performance]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-26 GYM ARC First 15 minutes, deals, invites, memory

Prompt: [[2026-10-26 GYM ARC Prompt - First 15 minutes, deals, invites, performance]]. Game commit 4e6f31a (+ the late-alter goals after it).

## First 15 minutes
- **NEW PLAYER BOOST:** 2x EXP and 2x coins for the first 15 minutes of play, from the first second (tutorial included; what's left comes back on a rejoin). `Config/Playtime.NewPlayer`, `PlaytimeService` (BoostService source "NewPlayer"). Coach Dex's first line announces it.
- **First rep:** +100 coins, a coin burst, the level-up sound and "FIRST REP! YOU GOT STRONGER" (`Config/Onboarding` Stamina step `gift.coins`, `ActionService`, `TutorialClient`).
- **Goal early:** the GROWTH SPURT card shows from the first second (the right column shows its bottom part during the tutorial; quest / daily cards still wait for the end). Coach Dex's second line: "Your goal: grow every muscle to your first GROWTH SPURT and get TALLER."
- **Starting coins:** 750 when the tutorial ends, finished or skipped (was 50, and skipping gave nothing).
- The first machine already had the glowing path, gold arrow and GO TO button; after the tutorial the GO TRAIN button leads on.
- Spurt 1 was already ~5 min of bot play; with the 2x boost it's faster, so the tutorial + Spurt 1 fit well inside 15 minutes.

## Starter Pack (limited) and VIP deal
- 79 R$ (owner sets it in Creator Hub), shown as **250 R$ crossed out** (what the contents cost one by one at the Store's prices) with a red line drawn through, then 79 R$ slamming in, -68%.
- Only in the **first 24 hours of play** (`data.playtime.total`, new lifetime playtime in PlaytimeService); countdown "ENDS IN 23:59:15". Existing players start their 24 hours now.
- Pops up every **5 minutes** of play (after the tutorial, never over a window, the menu or a lift) until **Growth Spurt 4**; then it flies into the SHOP tile once ("The Starter Pack is in the SHOP"). A red **DEAL** tag on the SHOP tile opens it any time.
- Buyer gets **+50% EXP and coins for 16 hours** (real time, BoostService "StarterRush", put back on rejoin).
- After buying: **VIP 30% OFF** (299 crossed out -> 209) with VIP's perks listed, for 24 h of play. Needs the owner's `VIPDeal` game pass id (grants VIP).
- `StarterPackClient` (new), `Config/Monetization` (StarterPack window / popup / rush settings, VipDeal, StarterOpen, VipDealOpen, Clock), `MonetizationService` (grants, rush, VIPDeal = VIP), `StoreClient` (tile text + hidden after the window), `OfferClient` (old once-only card removed).

## Trainers
- **BEST EQUIP** button (MY TRAINERS header): your strongest trainers by stats (all boosts added, after stage x level) in your slots. MY TRAINERS sorted by the same stats, best first (`Trainers.CopyValue / BestSet`, TrainerService "BestEquip").

## Alters: ~27 min each with trainers
- `Alters.Goals = { 237, 413, 494, 526, 553, 581, 623, 653, 674, 689, 709, 748, 774, 937, 1072 }` tuned with `lune run tests/pacing tunealters` (players rolling trainers): alters 1-13 about 27.5 min each, alter 14 about 46 min and alter 15 about 61 min (owner: harder after ~8 hours of play).

## Friends
- **INVITE +50%** button under the left menu's tiles (after the tutorial) and in the Crew window: Roblox's invite screen with launch data `invite:<UserId>`.
- **Invite boost:** a friend who joins through your invite gives you +50% EXP for 30 min (once per friend per day; saved in the "InviteRewards" DataStore if you're offline, up to 120 min); a NEW player who joined that way gets the same welcome boost. `Config/Social.Friends`, `FriendService`, `FriendClient`.

## Look
- **Main menu:** the logo slams in (flash, boom, shake), its glow beats like a heart, embers drift up, a red light breathes from the bottom left, the tagline punches through hype lines. `MenuClient` (MENU_DRAMA).
- **Overhead ALTER pill:** the NEXT alter card's background (dark, the alter's art under a shade, its colour outline), the ALTER button's chunky font.

## Server memory (543 MB, up 218%)
Found by a code search, fixed:
- Players who left were re-added to tables by slow callers while their save was still running (BoostService, LeaderboardService, ShowOffService, BodyService, FriendService) -> each now skips players who left.
- TrainerService `lastSnack` never cleared; CrewService view cache grew with every crew ever viewed (now only real crews, reset past 300); PosingCompService's Heartbeat watcher stayed connected forever after a failed show.
- A player's character is destroyed 15 s after they leave (frees every per-character connection).

## Not changed / owner
- Phone FPS 31: lights already cast no shadows on phones, NPCs are culled. The biggest lever left is **Workspace > StreamingTargetRadius** (now 256; 128-160 would load about half the town). The map has ~24,000 parts, 421 lights and 681 surface signs.
- Starter Pack price: set the product to **79 R$** in Creator Hub.
- VIP deal: create a game pass **"VIP 30% OFF" at 209 R$** and send its id.
