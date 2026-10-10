# Break A Bed: Project Overview

#break-a-bed #roblox

A Roblox game based on Chop A Brick. Train to gain Strength 💪, which raises your Level, then karate-chop your way down a long fenced path of beds for Cash.

- **Status:** 25-bed path, 12 training items and SPAWN button done and play-tested on 2026-10-10 in the Studio place **"Break a bed test version"**. Needs saving / publishing there. See [[Break A Bed/2026-10-10|latest session]].
- **Studio places:** "Break a bed test version" (placeId `92195183145806`) has the current game. "Break A Bed" (placeId `116443177548785`) still has the old first version.
- **Code folder:** `C:\Users\USER\Documents\Cashgrab` (its `CLAUDE.md` has the technical notes)
- **Place file:** `Cashgrab\BreakABed.rbxlx` (includes a baseplate and spawn point)

## Features
- **Two areas:** a training area next to spawn and a long fenced path of 25 beds.
- **Training:** walk up to a training item, press **E** (or tap the button on mobile) to **Train**, then click. Every chop gives Strength. 12 items, from the free Pillow to the Black Hole Cube. Better items cost Cash and give more Strength per chop.
- **Level:** comes from Strength. Shown top right with a progress bar, along with Strength (yellow 💪 icon) and Cash.
- **Bed path:** each bed sits in the middle of its own colored floor tile, with white fences down both sides and lamps between tiles. Normal beds sit on cinder blocks. The Air Mattress and Sleeping Bag lie on the tile, and the Bunk Bed has two levels and a ladder.
- **Harder the further you go:** each bed needs more Strength, has more health and pays more Cash, up to the Infinity Bed with 17 trillion health. Name tags show health and the 💪 needed. Until you're strong enough the prompt says "Need 💪 X".
- **Break mode:** press **E** to **Break**. The camera zooms in, an **EXIT** button appears, and each click is a karate chop (about 8 a second). Damage per chop comes from Strength.
- **When a bed breaks:** it splinters, cash pops out, and a **COMPLETED ✅** sign appears next to it. The bed respawns instantly.
  - **First time:** you go back to normal view automatically.
  - **Already completed:** you stay in the break screen and can keep breaking it for cash until **EXIT**.
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

## Training items

| Item | Strength per chop | Price |
|---|---|---|
| Pillow | +1 | free |
| Wooden Plank | +4 | $500 |
| Brick | +10 | $4.5K |
| Cinder Block | +40 | $40K |
| Steel Bar | +210 | $400K |
| Titanium Slab | +2.2K | $3.6M |
| Diamond Block | +25K | $32M |
| Obsidian Block | +270K | $290M |
| Meteor Rock | +2.9M | $2.6B |
| Star Core | +31M | $23B |
| Galaxy Orb | +330M | $200B |
| Black Hole Cube | +3.8B | $1.9T |

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
