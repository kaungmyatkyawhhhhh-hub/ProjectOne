---
date: 2026-11-09
tags: [galaxy, progress, growth, monetization, retention, liveops]
status: in Studio, NOT published. One short Play run: no script errors.
---
# Galaxy Incremental: the growth plan's in-game items (9 Nov, Claude Code)

Plan: [[2026-11-09 Galaxy Incremental - Growth plan to 1k CCU (marketing, economy, retention, LiveOps)]].

**Owner, 9 Nov:**
- "All in-game items".
- **Essence packs and VIP +1 Essence: BUILD BOTH.** The Forge shows its odds before every roll, and PolicyService is checked per player.

**Already done earlier today:** pacing fix, windows fit, space movement ([[2026-11-09 Galaxy Incremental - Fix the 3-minute quit + space movement]]).

**Test:** one Play run to check startup. Every new attribute was set on the owner's test save, 8 badges were given (35 Supernovas), both Sector 2 doors were built, and the console showed no script errors. Not tested: buying (no product ids yet), phone layout of the new cards, 2 players.

## Week 1 (the rest)
| item | what I did |
|---|---|
| **Music "4 tracks that no longer load"** | **They load fine:** public APM tracks; a Studio load test and GetProductInfo both work. The player waited only 10 s, then crossed a track off for the session; on a slow phone, while the map streams, a 2-3 MB song takes longer. Now it waits **30 s** and only leaves a track out after **3** failed loads. Kept the 4 tracks (picked for hype on 7 Nov). |
| **Sector 2 walk-round** | A **second invisible door** across the start of the Sector 2 bridge (rail to rail, 22 tall), built by GalaxyMapService. GalaxyMapClient opens **every** Barrier after Ignition 1, also one that streams in later. Today's plaza rail closes the rest of the gap. |
| **Like panel** | Once, after the first Supernova. It waits 20 s and for the favourite prompt to be done, then a calm moment. "If you like the game, tap the THUMBS UP on the game page." No reward, no link. |
| **Update code** | **SPACEJUMP** = 2x stardust 15 min, until 31 Dec. Change the word in CodesConfig if you like. |
| **What's New v2** | 4 lines (space jump, faster start, phones fixed, badges + weekly goal + the code), gift +2 Essence (like ALPHA). Players from before get it on their next join. |
| Title without [ALPHA] | **You**, in Creator Hub, when you publish. |

## Week 2: money + retention
| item | what I did |
|---|---|
| **Starter Pack 49 R$** | Product, once. Offered for **48 real hours** from your first Supernova; players who already went Supernova get their 48 h from their next join. The window never resets. Gives x2 STARDUST 30 min + 3 Essence + the **STARDUST TRAIL**. A pink chip in the left column shows the real time left (only from tutorial step 14, like the Store) and opens the Store. Store card: the price, "Offer ends in 47:59:59", then OWNED / ENDED. |
| **Auto Upgrade 199 R$** | Pass: AUTO-BUY I + II from the start. Its Store card becomes an AUTO: ON / OFF switch. |
| **Time skips 15 / 39 / 99 R$** | +1 h / +4 h / +12 h of your current income, at once; it counts toward the Supernova. |
| **Essence packs 29 / 79 / 199 R$** | 5 / 15 / 45 Essence. **Hidden and refused** for players whose PolicyService says paid random items are restricted (or when Roblox can't answer). |
| **VIP +1 Essence a Supernova** | Only for players checked and allowed by PolicyService. The VIP description says it. |
| **Daily calendar** | It already existed (7 days, day 7 = 5 Essence + 1 h warp). Day 7 now also gives the **STREAK TRAIL** (cosmetic, once). |
| **Badges** | 12 new: First Pad, First Moon, First Supernova, 2 days, 5 Supernovas, first Star Core, Black Hole, island complete (20 pads), 7 days, 25 Supernovas, 30 days, all bodies at NOVA. Each gives **1-5 Essence once** + a toast. The Roblox badge is awarded once you create it and put its id in GameConfig; saves that already earned it get it on their next join. "Days in a row" is a new counter, not capped at 7. |
| Trails | Made on the server, so everyone sees them. Worn: the last one you got. |

## Week 3 + LiveOps
| item | what I did |
|---|---|
| **Live switches (Creator Hub Configs)** | New `GalaxyLiveConfig`: values copied to `Live_<key>` attributes, refreshed when you publish a change (~15-60 s), defaults from GameConfig.LiveDefaults if a key is missing. |
| **Weekend 2x** | Event "2x STARDUST WEEKEND", Fri 18:00 - Sun 24:00 UTC every week. **Off** until you set `Weekend2x_Enabled` = true (the plan: once playtime is healthy). |
| Event scale | `EventStardust_Scale` multiplies every event's boost (2 = a 3x hour). |
| **Stuck helper** | Nothing you can buy for 60 s → free x2 STARDUST 2 min + a toast, at most once per 20 min, never on top of a running x2. |
| **Comeback** | Away 3+ days → the offline earnings cap is 12 h for that return. |
| **Quiet server** | 3 or fewer players → every Supernova fills the Star Surge 2x (the plaza board says so). |
| **Weekly goal** | 5 Supernovas this week (Mon-Sun UTC) = a free **RARE Star Core**. A new row at the bottom of the DAILY window with a bar. |
| **Store seen → prompted → bought** | Custom events `StoreCardSeen` (per card, once a session), `PassPromptShown` / `ProductPromptShown`, `PassBought` / `ProductBought`. |
| **Price tests** | `GameConfig.PriceTests[key].b` = a 2nd product at the other price: odd UserIds get it. The events carry `:A` / `:B`. All off (b = 0). |

## Not built (not in-game, or needs you)
- Icon / thumbnails / game-page video, the ads, the title.
- Content depth (the next sector): a design task first.
- Badges on the overhead tag: the plan says "shows on the island or tag". Only the toast + reward for now.

## OWNER: Creator Hub to-do
**1. Game pass** (Monetization > Passes), then put the id in GameConfig.Passes:

| pass | price | GameConfig key |
|---|---|---|
| AUTO UPGRADE | 199 R$ | AutoUpgrade.id |

**2. Developer products** (Monetization > Developer Products), then put each id in GameConfig.Products:

| product | price | GameConfig key |
|---|---|---|
| Starter Pack | 49 | StarterPack |
| +1 Hour | 15 | Skip1 |
| +4 Hours | 39 | Skip4 |
| +12 Hours | 99 | Skip12 |
| 5 Essence | 29 | Essence5 |
| 15 Essence | 79 | Essence15 |
| 45 Essence | 199 | Essence45 |

Until it has an id, each one stays hidden.

**3. Badges (optional):** create any of the 12 and put their ids in GameConfig.Badges. Names are in GameConfig.BadgeRewards.

**4. Configs** (Creator Hub > Configs), only if you want to change one; missing = the default:

| key | type | default |
|---|---|---|
| StuckHelper_Enabled | bool | true |
| Comeback_Enabled | bool | true |
| QuietBoost_Enabled | bool | true |
| WeeklyGoal_Enabled | bool | true |
| LikePanel_Enabled | bool | true |
| StarterPack_Enabled | bool | true |
| Weekend2x_Enabled | bool | **false** |
| EventStardust_Scale | number | 1 |

**5. When you publish:** remove [ALPHA] from the title.

## Files (Studio)
- **New:** ServerScriptService.GalaxyGrowthService, ServerScriptService.GalaxyLiveConfig, StarterPlayerScripts.GalaxyGrowth.
- **Changed:**
  - `ReplicatedStorage.Galaxy`: GameConfig, EconConfig, CodesConfig, UIKit.
  - `ServerScriptService`: GalaxyEconService, GalaxyStoreService, GalaxyLiveService, GalaxyStarSurgeService, GalaxyMapService.
  - `StarterPlayerScripts`: GalaxyStore, GalaxyDaily, GalaxyHUD, GalaxyMapClient.
- Vault code copies not updated (no file sync from Studio).
