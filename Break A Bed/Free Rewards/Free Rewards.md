# Break A Bed: Free Chest, Ad Reward and Free Gift popup

#break-a-bed #rewards

Back to [[Break A Bed/Project Overview|Project Overview]].

**Status (2026-10-12): built and tested** (see [[Break A Bed/2026-10-12|2026-10-12]]). The chest is now the EXCLUSIVE CHEST (`Workspace.ExclusiveChest`, the section below). The ad board is on hold: removed from the map, code kept behind `GameConfig.AdBoardEnabled = false`.

Owner's request (2026-10-12): copy two things from the simulator the owner likes: a **FREE chest** in the world with a **"Watch Ad To Collect"** board, and a **Free Gift popup** (Like, Favorite, Join the group, then Claim).

## 1. Free chest + ad board (in the world, near spawn)

![[preview-free-chest.png]]

- **FREE chest** (`chest.png` look; build it as a real 3D model or use a Creator Store chest) on a glowing green circle pad, with a big floating green "FREE!" above it (`BillboardGui`, our heavy font, slow bob).
  - Walk onto the pad = claim: a burst of cash (Cash = 20 breaks of your best bed) and the chest pops open.
  - Then "Next chest in 14:59" counts down (every 15 minutes). The timer is saved, so leaving doesn't skip it.
- **"Watch Ad To Collect" board** above it (a `SurfaceGui` on a part): a green studded frame, a tilted "CLICK TO CLAIM" tag, "Watch Ad To Collect:", a big italic green amount (Cash = 100 breaks of your best bed, updated live), a cash pile picture and a play arrow. Clicking it plays a **Roblox rewarded video ad**, and the reward is given when the ad finishes.
  - It uses Roblox's **rewarded video ads** (`AdService`). Roblox only shows these to some players (age, country, device), so the board must check if an ad is available. If not, hide the board or show "Come back later!". **Claude Code: check Roblox's current AdService docs for rewarded video ads; the API is new and may need the experience to be eligible on the Creator Dashboard (Monetization → Ads / rewarded video).**
  - Limit: one ad reward every 10 minutes.

## Change (2026-10-12): the chest is no longer free for everyone
The owner wants the chest to be **for players who like the game, favorite it and join the group**.
- Roblox only lets the game **check the group join**. Likes can't be checked at all, and favorites can only be prompted. Roblox's rules also don't allow rewards just for liking or favoriting.
- So the chest **unlocks when the player is in Myanmar Builders Club** (checked on the server). Like and Favorite are asked on the same screen but never checked.
- **Chest label:** "GROUP CHEST" above it (instead of "FREE!"), with a small "Like • Favorite • Join to open!" line under it until the player is a member. For members it shows "OPEN!" or the "Next chest in 14:59" timer.
- **Walking onto the pad as a non-member:** don't give anything. Open the same 3-step screen as the Free Gift popup (1. Like the game! 2. Favorite it! with the Favorite button, 3. Join the group! with the Join button). Its button says **"I joined!"**, which checks the group again.
- **Members:** the lid opens and Cash flies to the counter, every 15 minutes, with the timer saved. **Reward raised (2026-10-12): 40 breaks of the player's best bed, at least $1,000.** It grows with progress. The screen shows the player's own amount and adds "(grows as you level up!)" so new players know it gets bigger.
- The Free Gift popup and the chest share the same group check, so a player who joins gets both.

## ⭐ EXCLUSIVE CHEST (2026-10-12, replaces the Group Chest)
The owner renamed the Group Chest to **EXCLUSIVE CHEST** and wants it to look unique and full of effects.

![[preview-exclusive-chest.png]]

**To claim it:** like the game, favorite it and join the group. The screen shows all 3 steps. Only the **group join** can be checked (Roblox has no way to check likes, and favorites can only be prompted), so the claim unlocks when the player is in **Myanmar Builders Club**. Likes and favorites are asked, not checked, and not rewarded on their own (Roblox rule).

**Look (unique, nothing else in the game looks like this):**
- **The chest:** a royal **purple-and-gold** chest (`exclusive-chest.png` look) with a gold crown on the lid, a pink gem lock, cyan side gems and glowing runes. Build it as a model (purple + gold parts, Neon gems) or take a chest from the Creator Store and recolor it.
- It **floats** about 3 studs above the ground, slowly bobbing (2 studs, 3 s loop) and turning (one turn every 8 s).
- **A rune circle** on the ground: 3 glowing rings (purple, gold, cyan), Neon parts or a `Decal` with `LightEmission`, the outer one slowly turning one way and the inner one the other way, with small gold diamonds around the edge.
- **A light pillar:** a tall purple `Beam` going up from the circle (`fx-beam.png`, Width 10, LightEmission 1, Transparency 0.6), visible from far away so players find it.
- **Particles:** `fx-star4` sparkles orbiting the chest (purple, gold, white), `fx-glow` orbs rising slowly, and a purple `PointLight` (Brightness 3, Range 18) pulsing.
- **Rays** (`fx-rays`) behind the chest on a BillboardGui, slowly turning, purple.
- **Title** above it on a BillboardGui: "EXCLUSIVE CHEST" in a gold gradient with a thick dark stroke, and under it "Like • Favorite • Join" in light purple. For members it shows "OPEN!" (bouncing), or the "Next chest in 14:59" timer.

**Claiming (member):** the chest shakes, the lid flies open with a big white flash, a `fx-ring` shockwave, a purple + gold sparkle fountain and a beam of light, then `money-big.png` cash bursts out and flies to the counter. Play a magical "chime + whoosh" sound.

**Not a member:** a small bounce, and the Exclusive Chest screen opens (same 3-step design as the Free Gift popup, but with a purple title bar "Exclusive Chest!" and `exclusive-chest.png` as the big picture) with the "I joined!" button.

**Reward:** 40 breaks of your best bed, at least $1,000, every 15 minutes (the timer is saved).

## Ads: on hold (2026-10-12)
The game isn't eligible for Roblox rewarded video ads yet (not enough players). **Remove the "Watch Ad To Collect" board from the map for now** (keep its code, turned off by a `GameConfig` switch `AdBoardEnabled = false`), so there's no empty board. Turn it back on when Roblox allows ads: create the AD REWARD CASH product, set `AdBoardEnabled = true` and turn on Rewarded Video in Monetization → Ads.

## 2. Free Gift popup (Like, Favorite, Join the group)

![[preview-free-gift.png]]

- It pops up **once**, after the [[Break A Bed/New Player Guide|New Player Guide]] (never during it), and can be reopened from the Gifts menu until claimed.
- **Look:** the FINAL STYLE window with a cyan "Free Gift!" title bar, a big cash pile with a glow on the left, **big** "~ LIMITED TIME! ~" in red (about 60 px) and a **huge** "+$50K CASH!" in green (about 86 px), filling the space right of the pile without touching the window edge (both moved 10 px higher), then 3 dark step cards (1. Like the game! 2. Favorite it! 3. Join the group!), each with a small picture of where to click and a red arrow, then a big green **Claim!** button.
- **What can be checked:** only the **group join** can be checked (`player:IsInGroupAsync(GroupId)` for **Myanmar Builders Club**). Roblox gives games no way to check likes, and favorites can only be prompted (`AvatarEditorService:PromptSetFavorite`), not checked.
  - So **Claim!** works when the player is in the group (otherwise: "Join the group first!"). Like and Favorite are just asked nicely.
  - Add a **Favorite** button on step 2 that opens Roblox's favorite prompt.
  - **Roblox rule:** don't give rewards *only* for liking or favoriting. Asking is fine. The reward is for joining the group, which is allowed and checked.
- Reward: Cash (+$50K at the start, scaling with progress) + x2 Strength for 15 min, once per account. This merges with the existing 🎁 Group Reward (+10% Strength forever), which is still given too.

## For Claude Code (in the code folder: `Cashgrab` or `BAB`)
1. Free chest: a model + pad + BillboardGui, with the saved 15-minute cooldown on the server.
2. Ad board: a SurfaceGui, a rewarded video ad via `AdService` (check eligibility; hide the board if no ad is available), the reward given on the server after the ad completes, a 10-minute limit.
3. Free Gift popup: the FINAL STYLE window like `preview-free-gift.png`, a group check on the server, given once (saved).
