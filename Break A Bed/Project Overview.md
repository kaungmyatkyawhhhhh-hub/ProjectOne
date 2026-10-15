# Break A Bed: Project Overview

#break-a-bed #roblox

A Roblox game based on Chop A Brick. Train to gain Strength 💪, which raises your Level, then karate-chop your way down a long fenced path of beds for Cash.

- **Status:** 25-bed path, 12 training items and SPAWN button done and play-tested on 2026-10-10 in the Studio place **"Break a bed test version"**. Needs saving / publishing there. See [[Break A Bed/2026-10-10|latest session]].
- **Studio places:** "Break a bed test version" (placeId `92195183145806`) has the current game. "Break A Bed" (placeId `116443177548785`) still has the old first version.
- **Owner:** the game is in the owner's Roblox group **Myanmar Builders Club**. Images, sounds and products for it are uploaded/created under the group. Robux from sales go to the group's funds.
- **Ads:** first campaign and ad pictures in [[Break A Bed/Ads|Ads]].
- **Code folder:** `C:\Users\USER\Documents\Cashgrab` on one PC, `BAB` on the other (its `CLAUDE.md` has the technical notes)
- **Place file:** `Cashgrab\BreakABed.rbxlx` is out of date (scripts only, no map). The map is saved in the Studio place as real models: Workspace folders `Path`, `Beds`, `TrainingArea`, `Upgrades`, `Signs`, `Scenery` (see [[Break A Bed/How It Works|How It Works]]).

## Features
- **Two areas:** a training area next to spawn and a long fenced path of 25 beds.
- **Training (works like beds, 2026-10-12):** 17 training posts, each on its own colored glowing pad (decoration). Press **E / Train** at a post: you're locked in place facing it, the camera goes to the side view, and you **punch by yourself for free** (every 0.25 s); clicking punches faster (up to the normal limit). Each punch gives that post's Strength with "+70 💪" popping out. EXIT, SPAWN, walking or jumping ends it. Locked posts have a **Buy** prompt with the price; not enough cash shows "Not enough money" in red. The VIP post works the same for VIPs ("Get VIP" opens the pass for others). The platform floor is dark grey tiles in a grid (`TrainingArea.FloorTiles`).
- **AUTO PUNCH pass = beds only:** "AUTO PUNCH: breaks beds for you!". Non-owners see a small offer with BUY in the break panel (once per server visit, not during the guide).
- **Level:** comes from Strength. Shown bottom-left: a star with the level number and a studded green bar, above big italic gradient Strength (yellow, red 3D dumbbell) and Cash (green, money art). On phones they sit under the Shop / Boosts buttons.
- **Main screen (FINAL STYLE, 2026-10-12):** Shop and Boosts buttons + the Auto Punch switch on the left; Daily, Spin, Gifts and Settings squares with red badges on the right. Nothing moves when idle. **(2026-10-13)** Shop/Boosts sit in the middle of the left edge; stats bottom-left on PC. Phones: HUD sized from the screen height, stats top-left, squares in a centred right column, everything clear of the thumbstick and jump button; the break screen is at the top.
- **Bed path:** each bed sits in the middle of its own colored floor tile, with white fences down both sides and lamps between tiles. Normal beds sit on cinder blocks. The Air Mattress and Sleeping Bag lie on the tile, and the Bunk Bed has two levels and a ladder.
- **Harder the further you go:** each bed needs more Strength, has more health and pays more Cash, up to the Infinity Bed with 17 trillion health. Name tags show health and the 💪 needed. Until you're strong enough the prompt says "Need X Strength".
- **Break mode:** press **E** to **Break**. The camera zooms in, an **EXIT** button appears, and each click is a karate chop (about 8 a second). Damage per chop comes from Strength.
- **When a bed breaks:** it splinters, cash pops out, and a **COMPLETED ✅** sign appears next to it. The bed respawns instantly.
  - **First time:** you go back to normal view automatically.
  - **Already completed:** you stay in the break screen and can keep breaking it for cash until **EXIT**.
- **Upgrade boards** on the left of the spawn plaza: ⚡ **Training Speed** (multiplies the Strength from every punch, x1.00 → x1.15 → …) and 👟 **Walk Speed** (16 → 18 → …). Each board shows your current → next value and the price (red when you can't afford it). Step on the green pad in front to buy a level; click while standing on it to buy more. Not enough cash shows "Not enough money" in red.
- **Critical hits:** 1 in 10 chops is a **CRITICAL!** (orange text, 3× damage, bonus Cash).
- **Leaderboards:** four boards in a row by the training area (`Workspace.Signs`): TOP TOTAL DAMAGE and TOP TOTAL MONEY (top 10 across all servers, every 3 minutes), SERVER TOP DAMAGE and SERVER TOP MONEY (players in this server, live). Each shows your own total. Total money = all Cash ever earned.
- **Bed signs** show the bed name, the Strength needed and the Cash a break pays you (with your boosts).
- **Group Reward:** the "Group Bonus: +10%" line under the stats opens it: join the group, claim +10% Strength from punching forever (`GameConfig.GroupId`).
- **Settings** (blue square): Music and Sounds on/off.
- **Shop:** one scrolling page with sections FEATURED / STRENGTH / CASH / PASSES and category icons on the right; Boosts opens it at Strength.
- **Robux shop and free rewards:** the Strength tier card in the shop (x2 → x15), passes (Auto Punch, x2 Cash, VIP, Fast Walk, Break Spam), 25 cheap developer products ([[Break A Bed/Shop Plan|Shop Plan]]: x2/x3/x5/x10 boosts, Fast Punch, Server x2 Strength, Cash/Strength/Level/Spin packs, Instant Break, Starter Pack), daily reward, spin wheel, VIP lounge (walking into its door without VIP opens the VIP pass purchase window). Script `Shop` (StarterPlayerScripts) draws it; `VipLounge` (ServerScriptService, run once in Edit mode) built `Workspace.VipArea`. All pass and product ids are set in `GameConfig`.
- **Boosts:** each level has its own timer; only the highest active Strength and Cash boost counts, and they multiply with passes. Timers show at the top center.
- **Impulse buys:** **BREAK IT** (2026-10-13): pressing a bed you can't break yet shows one green BREAK IT button; the product and its live price depend on how many beds ahead it is (5 products, INSTANT BREAK 1–5). "Buy again" when a boost runs out, and a one-time Starter Pack pop-up after the first bed break.
- **Free Rewards** ([[Break A Bed/Free Rewards/Free Rewards|Free Rewards]]): an EXCLUSIVE CHEST near spawn (`Workspace.ExclusiveChest`, floating purple-and-gold with effects; Myanmar Builders Club members only, Cash = 40 breaks of the best bed (at least $1,000) every 15 min, saved; non-members get a Like / Favorite / Join screen with "I joined!"), a "Watch Ad To Collect" board (rewarded video ads; **on hold**, switched off by `GameConfig.AdBoardEnabled = false` and not on the map) and the Free Gift popup (Like / Favorite / Join; Claim checks the favorite on the device and the group on the server → Cash + x2 Strength 15 min + Group Reward, once). Script `FreeRewards`.
- **Free Gifts** ([[Break A Bed/Playtime Rewards|Playtime Rewards]]): 12 gifts from 1 to 90 minutes each session, the red Gifts square on the right (countdown, badge), SKIP ALL. Script `FreeGifts`; its effects (glows, halos, shines, twinkles, bar fill, claim burst) are in `GiftsVfx`.
- **New Player Guide** ([[Break A Bed/New Player Guide|New Player Guide]]): beam + arrow through punching, the first bed and the Wooden Post, then the next bed. Since 2026-10-13 everything at the top centre is **one slim pill** (tutorial step → Starter Quest → next bed, script `Tracker`); boost timers are small chips above Strength. No SKIP; the guide ends with "TAP TO BED!" then "TAP SPAWN!" on a dimmed screen with a cut-out, glow and arrow. The quest / next-bed pill can be hidden with its x (TRACK in the Quests window brings it back). Script `Tutorial`.
- **Content update (2026-10-13, [[Break A Bed/Content Plan|Content Plan]]):** 17 unique training posts with their own punch effects and sounds (`PostFx`), 12 gloves (Glove Shop stand by spawn, `GloveShopUI`, `GloveModel`), beds 11–25 and posts 8–17 re-tuned, **Rebirths** with a token shop (`Rebirths`, `RebirthUI`), undiscovered beds/posts as black silhouettes (`Silhouettes`), an Invite Friend stand with a friend bonus (`FriendBonus`, `Stands`).
- **Leaderboards (2026-10-13):** TOP TOTAL DAMAGE / MONEY / REBIRTHS with GLOBAL/SERVER tabs and a scrolling top 100 (`Leaderboards` server, `LeaderboardUI` client). Glove Shop window in Ninja Legends style with BUY ALL / EQUIP BEST. Plaza re-laid out (stands in front, training floor 76x88). Music is a shuffled 3-song playlist.
- **AFK training (2026-10-13):** "AFK-friendly!" notice when training starts; idle 15 min while training = saved + teleported back into the server, training again at the same post (`AfkTraining` client, `afkRejoin` server, reuses the Soft Shutdown Resume).
- **To Bed** button (2026-10-13): alone in the top middle; on the bed path it slides left and SPAWN appears beside it (small on phones). Teleports you to the best bed you can break right now (highest bed whose Strength you have), with a quick fade and a 3 s cooldown.
- **Minutes 2–10** (2026-10-13, [[Break A Bed/Charts Plan|Charts Plan]]): **Starter Quests** (6 goals in the first session, the last is a free Halloween aura roll; shown in the top-centre pill; server `StarterQuests`, client `Onboarding`). The next-bed bar is always on screen, and newly affordable beds/posts get the arrow + beam (which goes through the arch, never through the fence). "Click to punch 2x faster!" while training (first 3 sessions) and a training **combo** (x5 / x10 / x25 = +10 / 20 / 30% Strength). "Come back tomorrow: Day 2 reward + new quests!" once a session at 8 min.
- **UI Kit style** ([[Break A Bed/UI Kit/UI Kit|UI Kit]]): sharp image buttons and windows, Montserrat text with shadows, animations and UI sounds everywhere. Scripts `UIKit` and `UIAssets` (image ids).
- **SPAWN button** at the top: only on the bed path (fades in/out), hidden in the break screen; teleports you back to spawn.
- **Look:** the UI Kit's FINAL STYLE (2026-10-12): solid studded buttons with same-colour dark outlines and white glyphs, solid dark studded windows with a green shiny title bar and red X (no light rays), lime price buttons, money art for Cash, Montserrat Heavy text with outlines and shadows, no emoji; short numbers everywhere (1.14M, 1.9T, 392Qa), including Roblox's player list.
- **Punching:** left hook → right hook → uppercut combo. **Bed breaks:** chunks, cash bills, coins, sparkles, confetti, all pooled and capped so fast breaking doesn't lag.
- **Scripts added:** `Icons` (ReplicatedStorage), `UIKit`, `Fx`, `Combo` (StarterPlayerScripts).
- **Scripts added 2026-10-11:** `ScreenFx`, `Ambient` (StarterPlayerScripts, screen effects and moving map pieces), `Decor` (ServerScriptService, map zones/hub/nature, run once in Edit mode). Map: 5 themed zones with gates, title sign on the entrance arch. `City` (ServerScriptService, run once in Edit mode): the city backdrop in `Workspace.City` (roads, houses, shops, apartments, towers, Bed Mart, Mattress Factory, Grand Sleep Hotel); it replaced the trees, hills and pond.
- **Mobile:** tap controls; the HUD shrinks on phone screens; Low Graphics starts on.
- **Limited Aura Crates** ([[Break A Bed/Auras/Limited Auras|Limited Auras]], client module `Auras`): the Halloween crate (until Nov 1) in the shop's FEATURED section, 6 auras (Ghost → Reaper) that multiply Strength and add Walk Speed, opening animation, Auras button + inventory with EQUIP, Aura Dust stars, pity at 50, Reaper announcement, gifting. Product ids not set yet.
- **Effects** ([[Break A Bed/Effects/Effects|Effects]], client module `Effects`): bloom and colour grade, big bed-break bursts (bigger from the Crystal / Galaxy beds), glowing beds from the Ice Bed, player auras by Level / VIP / boost, hit sparks and big italic numbers, server announcements, big centre text, level-up fountain, world sparkles and neon gates. Settings: Low Graphics and Others' Effects.
- **Look and feel:** grass terrain with trees and bushes, a brick spawn plaza, soft sunlight with haze and bloom, real sound effects and background music (on/off in Settings), beds that jolt on every hit, dust, flying coins and a screen flash when a bed breaks, numbers that count up, glossy buttons.
- **Karate belts and Sensei (2026-10-14, [[Break A Bed/Content Plan|Content Plan]] 11):** White → Black belt from the belt-test beds (3, 6, 9, 12, 15, 18, 21, 25), +10% Strength per belt, a gold stripe per rebirth and master belts every 5 rebirths. Each test bed has a custom torii gate; only the next unearned test has a soft light column. The floating Sensei by spawn; his song fades in within 6 studs and the music dips. "Belt +X%" sits under "Rebirth x1.5" on the Strength row.
- **Cutscenes (2026-10-14):** first time per belt colour (Sensei, belt ties on), black belt, 8 rebirth versions with the custom animals (phoenix, tiger, crane, gold/ice/galaxy dragon, fire phoenix, rainbow koi), master belt change, first-join intro. Custom VFX (`RebirthVFX`) and custom sounds; Low Graphics turns the VFX down.
- **Phoenix rebirth rewards (2026-10-14):** rebirth 1 Phoenix Dummy (1.5x your best post, by the training area), 2 Phoenix Gloves (a look + 20% on any glove, kept forever; last tile in the glove shop), 3 Rebirth Aura, 4 pet slot (soon), 7 Phoenix Beds (own screen, Settings switch). Plus fast replay, Head Start, Golden Bed, Lucky Hour and a daily challenge (section 12).
- **Reference-game feel (2026-10-15):** bicep popups, X2/X3/X5 training cubes, front bed camera, white-key prompts, hit chips + hit marker, pink health bar with a time estimate, shattering beds, screen cash, a sound per bed, do-re-mi combo notes, 25 themed bed zones; no Strength lock (scripts `Juice`, `PromptStyle`, `BedZones`, `ServerStorage.BedZonesSetup`).
- **Hidden zones (2026-10-15):** a solid cloud wall 2 zones past your Strength hides the rest of the path (removed on your screen), with a sign on the cloud; it opens when you touch it with enough Strength ("NEW ZONE REVEALED!", several at once in a chain) and never comes back after a rebirth; a silent self-check runs each time it's placed (`CloudZones`, saved `FurthestZone`). Training pickups (X2/X3/X5) are on-screen buttons with a boost timer chip.
- **Personal progress:** each player breaks their own copy of a bed (effects are client-side), and COMPLETED signs are personal. Everything saves.

## Scripts (where they are in Studio)

| Script | Type | Where in Studio | Source file |
|---|---|---|---|
| `GameConfig` | ModuleScript | ReplicatedStorage | `src/shared/GameConfig.luau` |
| `WorldBuilder` | ModuleScript | ServerScriptService | `src/server/WorldBuilder.luau` |
| `Environment` | ModuleScript | ServerScriptService | `src/server/Environment.luau` |
| `GameServer` | Script | ServerScriptService | `src/server/GameServer.server.luau` |
| `GameClient` | LocalScript | StarterPlayer › StarterPlayerScripts | `src/client/GameClient.client.luau` |
| `UIAssets` | ModuleScript | ReplicatedStorage | UI Kit image ids (2026-10-12) |
| `Tutorial` | ModuleScript | StarterPlayer › StarterPlayerScripts | New Player Guide (2026-10-12) |
| `Tracker` | ModuleScript | StarterPlayer › StarterPlayerScripts | The one slim top-centre pill: tutorial step → Starter Quest → next bed, hide x (2026-10-13) |
| `FreeGifts` | ModuleScript | StarterPlayer › StarterPlayerScripts | Free Gifts menu (2026-10-12) |
| `GiftsVfx` | ModuleScript | StarterPlayer › StarterPlayerScripts | Free Gifts window effects (2026-10-12) |
| `SettingsMenu` | ModuleScript | StarterPlayer › StarterPlayerScripts | Settings window: volume sliders, 5 switches, CODES, Replay Tutorial; saved (2026-10-12/13) |
| `SoftShutdown` | Script | ServerScriptService | Moves players to a new server on an update (2026-10-13) |
| `OnboardingFunnel` | ModuleScript | ServerScriptService | "Onboarding2" analytics funnel, 13 steps: Loaded … Played 3/5/7 Min, Stayed 10 Min (2026-10-13; the old 9-step "Onboarding" funnel keeps its data) |
| `StarterQuests` | ModuleScript | ServerScriptService | Starter Quests chain, first session only, saved (2026-10-13) |
| `Onboarding` | ModuleScript | StarterPlayer › StarterPlayerScripts | Starter Quest (in the Tracker pill), click hint + combo counter, come-back toast, "Joined" report (2026-10-13) |
| `LikeGoalBoard` | Script | ServerScriptService | The like goal board at spawn, live from ReplicatedStorage.LikeGoal (2026-10-13) |
| `LikeGoal` | ModuleScript | ServerScriptService | Reads the real like count (RoProxy), switches on like-goal codes (2026-10-13) |
| `Retention` | ModuleScript | ServerScriptService | Daily Quests + Boost Inventory (2026-10-13) |
| `QuestsUI` | ModuleScript | StarterPlayer › StarterPlayerScripts | Quests window + square, MY BOOSTS window + badge (2026-10-13) |
| `FavoritePrompt` | ModuleScript | StarterPlayer › StarterPlayerScripts | "Favorite to find it again!" popup, once (2026-10-13) |
| `SoftShutdownScreen` | LocalScript | StarterPlayer › StarterPlayerScripts | "UPDATING THE GAME..." screen (2026-10-13) |
| `Belts` / `BeltUI` / `BeltModel` | Server / client / ReplicatedStorage | Karate belts, Sensei, belt-test arenas (2026-10-14) |
| `Cutscenes` | ModuleScript | StarterPlayerScripts | Belt, rebirth (8), master belt and intro cutscenes (2026-10-14) |
| `RebirthVFX` / `RebirthVFXAnchors` | ModuleScript | ReplicatedStorage | Custom cutscene VFX + anchor points on the models (2026-10-14) |
| `PhoenixRewardsUI` / `PhoenixGloves` | Client / ServerScriptService | Phoenix rebirth rewards (2026-10-14) |
| `SenseiZone` | ModuleScript | StarterPlayerScripts | Sensei's song fades in/out, music dips (2026-10-14) |
| `RunExtras` / `RunExtrasUI` | Server / client | Fast replay, Head Start, Golden Bed, Lucky Hour, daily challenge (2026-10-14) |
| `ImportedModelsSetup` / `PhoenixRewardsSetup` | ModuleScript | ServerStorage | Run once after importing the custom models (2026-10-14) |

The Studio place has the newest scripts; the `src` files are older.

All numbers (beds, training items, damage, levels) are in `GameConfig`.

## Training posts
Posts 4–7 and beds 6–10 were re-tuned on 2026-10-13 so a new player gets something new at least every ~75 s in minutes 2–10 ([[Break A Bed/2026-10-13|2026-10-13]]).


| # | Post | Strength per punch | Price |
|---|---|---|---|
| 1 | Straw Post | +1 | free |
| 2 | Wooden Post | +4 | $50 |
| 3 | Bamboo Post | +17 | $600 |
| 4 | Brick Post | +70 | $4.3K (was $5K) |
| 5 | Stone Post | +290 | $41K (was $40K) |
| 6 | Iron Post | +1.2K | $100K (was $250K) |
| 7 | Steel Post | +4.9K | $1.4M (was $1.5M) |
| 8 | Gold Post | +20K | $6M |
| 9 | Emerald Post | +84K | $25M |
| 10 | Ruby Post | +350K | $100M |
| 11 | Sapphire Post | +1.5M | $400M |
| 12 | Diamond Post | +6.2M | $1.5B |
| 13 | Lava Post | +26M | $6B |
| 14 | Neon Post | +110M | $25B |
| 15 | Galaxy Post | +460M | $100B |
| 16 | Black Hole Post | +1.9B | $400B |
| 17 | Infinity Post | +7.9B | $1.5T |

## Upgrades

| Upgrade | Each level | Range | First price | Price growth |
|---|---|---|---|---|
| ⚡ Training Speed | +0.15× Strength per punch | x1.00 → x10.00 (60 levels) | $200 | ×1.45 per level (x4.00 → x4.15 costs ~$340K) |
| 👟 Walk Speed | +2 walk speed | 16 → 60 (22 levels) | $100 | ×2 per level (34 → 36 costs ~$51K) |

## Beds (in path order)

| # | Bed | Needs 💪 | Health | Cash |
|---|---|---|---|---|
| 1 | Cardboard Bed | 0 | 6 | $5 |
| 2 | Air Mattress | 7 | 20 | $15 |
| 3 | Sleeping Bag | 22 | 65 | $45 |
| 4 | Wooden Bed | 73 | 220 | $140 |
| 5 | Bunk Bed | 240 | 710 | $400 |
| 6 | Water Bed | 2.4K (was 770) | 7.2K | $1.2K |
| 7 | Hospital Bed | 5.1K (was 2.6K) | 15K | $3.6K |
| 8 | Royal Bed | 12K (was 8.7K) | 36K | $11K |
| 9 | Gold Bed | 22K (was 28K) | 66K | $33K |
| 10 | Diamond Bed | 58K (was 93K) | 170K | $98K |
| 11 | Emerald Bed | 310K | 920K | $300K |
| 12 | Ruby Bed | 1M | 3M | $890K |
| 13 | Ice Bed | 3.3M | 10M | $2.7M |
| 14 | Lava Bed | 11M | 33M | $8M |
| 15 | Crystal Bed | 37M | 110M | $24M |
| 16 | Neon Bed | 120M | 360M | $72M |
| 17 | Robot Bed | 400M | 1.2B | $220M |
| 18 | Alien Bed | 1.3B | 3.9B | $650M |
| 19 | Lunar Bed | 4.3B | 13B | $1.9B |
| 20 | Solar Bed | 14B | 43B | $5.8B |
| 21 | Galaxy Bed | 47B | 140B | $17B |
| 22 | Nebula Bed | 150B | 460B | $52B |
| 23 | Black Hole Bed | 500B | 1.5T | $160B |
| 24 | Cosmic Bed | 1.7T | 5.1T | $470B |
| 25 | Infinity Bed | 5.7T | 17T | $1.4T |

## Related notes
- [[Break A Bed/How It Works|How It Works]]: how the systems work
- [[Break A Bed/Decisions|Decisions]]
- [[Break A Bed/Bugs and Fixes|Bugs and Fixes]]
- [[Break A Bed/Ideas|Ideas]]
- [[Break A Bed/UI Kit/UI Kit|UI Kit]]: the new button and shop style (images + how to use them)
- [[Break A Bed/Free Rewards/Free Rewards|Free Rewards]]: free chest, watch-ad board, Free Gift popup (like/favorite/join)
- [[Break A Bed/Auras/Limited Auras|Limited Auras]]: weekly aura crates that boost Strength and Walk Speed
- [[Break A Bed/Effects/Effects|Effects]]: bed breaks, auras, glow, announcements (with particle images)
- [[Break A Bed/Settings|Settings]]: settings menu (volume, low graphics, hide HUD…) and codes
- [[Break A Bed/Retention Plan|Retention Plan]]: AFK zone, daily quests, boost inventory, OP day 7, rebirths, events
- [[Break A Bed/New Player Guide|New Player Guide]]: first-minute guide to fix 0% retention
- [[Break A Bed/Playtime Rewards|Playtime Rewards]]: Free Gifts menu, 12 gifts that unlock the longer you play
- [[Break A Bed/Charts Plan|Charts Plan]]: what the Roblox charts measure and the steps to get on them
- [[Break A Bed/Soft Shutdown|Soft Shutdown]]: updates don't kick players; they come back in the same place
- [[Break A Bed/Content Plan|Content Plan]]: unique posts, Rebirths, Gloves, Bed Mastery, World 2 (players finished in 30 min)
- [[Break A Bed/Shop Plan|Shop Plan]]: lots of cheap products (x2/x3/x5/x10 boosts, packs, impulse buys)
- Sessions: [[Break A Bed/2026-10-10|2026-10-10]], [[Break A Bed/2026-10-11|2026-10-11]], [[Break A Bed/2026-10-12|2026-10-12]]
