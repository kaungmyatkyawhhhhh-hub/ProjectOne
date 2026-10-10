# Break A Bed: Project Overview

#break-a-bed #roblox

A Roblox game based on Chop A Brick. Train to gain Strength 💪, which raises your Level, then karate-chop your way down a long fenced path of beds for Cash.

- **Status:** 25-bed path, 12 training items and SPAWN button done and play-tested on 2026-10-10 in the Studio place **"Break a bed test version"**. Needs saving / publishing there. See [[Break A Bed/2026-10-10|latest session]].
- **Studio places:** "Break a bed test version" (placeId `92195183145806`) has the current game. "Break A Bed" (placeId `116443177548785`) still has the old first version.
- **Code folder:** `C:\Users\USER\Documents\Cashgrab` (its `CLAUDE.md` has the technical notes)
- **Place file:** `Cashgrab\BreakABed.rbxlx` (includes a baseplate and spawn point)

## Features
- **Two areas:** a training area next to spawn and a long fenced path of 25 beds.
- **Training:** 17 training posts, each on its own colored glowing pad. Stand on a pad and click to punch; each punch gives that post's Strength with "+70 💪" popping out. Locked posts show a 🔒 and their cash price; buying without enough cash shows "Not enough money" in red.
- **Level:** comes from Strength. Shown top right with a progress bar, along with Strength (yellow 💪 icon) and Cash.
- **Bed path:** each bed sits in the middle of its own colored floor tile, with white fences down both sides and lamps between tiles. Normal beds sit on cinder blocks. The Air Mattress and Sleeping Bag lie on the tile, and the Bunk Bed has two levels and a ladder.
- **Harder the further you go:** each bed needs more Strength, has more health and pays more Cash, up to the Infinity Bed with 17 trillion health. Name tags show health and the 💪 needed. Until you're strong enough the prompt says "Need 💪 X".
- **Break mode:** press **E** to **Break**. The camera zooms in, an **EXIT** button appears, and each click is a karate chop (about 8 a second). Damage per chop comes from Strength.
- **When a bed breaks:** it splinters, cash pops out, and a **COMPLETED ✅** sign appears next to it. The bed respawns instantly.
  - **First time:** you go back to normal view automatically.
  - **Already completed:** you stay in the break screen and can keep breaking it for cash until **EXIT**.
- **Upgrade boards** on the left of the spawn plaza: ⚡ **Training Speed** (multiplies the Strength from every punch, x1.00 → x1.15 → …) and 👟 **Walk Speed** (16 → 18 → …). Each board shows your current → next value and the price (red when you can't afford it). Step on the green pad in front to buy a level; click while standing on it to buy more. Not enough cash shows "Not enough money" in red.
- **Critical hits:** 1 in 10 chops is a **CRITICAL!** (orange text, 3× damage, bonus Cash).
- **🏆 TOP Total Damage Dealt** sign on the right of the spawn plaza: top 10 across all servers, refreshed every 3 minutes, with your own total.
- **🎁 Group Reward** button on the right of the screen: join the group, claim +10% Strength from punching forever. Needs the group id (`GameConfig.GroupId`).
- **Robux shop** on the left of the screen: +1 / +3 / +9 Level packs and a permanent x2 Strength game pass. Needs the product and pass ids.
- **SPAWN button** at the top: teleports you back to spawn from anywhere, even mid-break.
- **Look and feel:** grass terrain with trees and bushes, a brick spawn plaza, soft sunlight with haze and bloom, real sound effects and background music (🔊 mute button), beds that jolt on every hit, dust, flying coins and a screen flash when a bed breaks, numbers that count up, glossy buttons.
- **Personal progress:** each player breaks their own copy of a bed (effects are client-side), and COMPLETED signs are personal. Everything saves.

## Scripts (where they are in Studio)

| Script | Type | Where in Studio | Source file |
|---|---|---|---|
| `GameConfig` | ModuleScript | ReplicatedStorage | `src/shared/GameConfig.luau` |
| `WorldBuilder` | ModuleScript | ServerScriptService | `src/server/WorldBuilder.luau` |
| `Environment` | ModuleScript | ServerScriptService | `src/server/Environment.luau` |
| `GameServer` | Script | ServerScriptService | `src/server/GameServer.server.luau` |
| `GameClient` | LocalScript | StarterPlayer › StarterPlayerScripts | `src/client/GameClient.client.luau` |

All numbers (beds, training items, damage, levels) are in `GameConfig`.

## Training posts

| # | Post | Strength per punch | Price |
|---|---|---|---|
| 1 | Straw Post | +1 | free |
| 2 | Wooden Post | +4 | $50 |
| 3 | Bamboo Post | +17 | $600 |
| 4 | Brick Post | +70 | $5K |
| 5 | Stone Post | +290 | $40K |
| 6 | Iron Post | +1.2K | $250K |
| 7 | Steel Post | +4.9K | $1.5M |
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
| 6 | Water Bed | 770 | 2.3K | $1.2K |
| 7 | Hospital Bed | 2.6K | 7.7K | $3.6K |
| 8 | Royal Bed | 8.7K | 26K | $11K |
| 9 | Gold Bed | 28K | 84K | $33K |
| 10 | Diamond Bed | 93K | 280K | $98K |
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
- Sessions: [[Break A Bed/2026-10-10|2026-10-10]]
