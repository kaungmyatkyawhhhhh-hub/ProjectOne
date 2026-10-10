# Break A Bed: Project Overview

#break-a-bed #roblox

A Roblox game based on Chop A Brick. Train to gain Strength 💪, which raises your Level, then karate-chop your way down a long path of beds for Cash.

- **Status:** rebuilt to the new spec on 2026-10-10 and play-tested in a test copy (`BreakABed.rbxlx`). Not yet installed in the real "Break A Bed" place. See [[Break A Bed/2026-10-10|latest session]].
- **Studio place:** "Break A Bed" (placeId `116443177548785`)
- **Code folder:** `C:\Users\USER\Documents\Cashgrab` (its `CLAUDE.md` has the technical notes)
- **Place file:** `Cashgrab\BreakABed.rbxlx` (includes a baseplate and spawn point)

## Features
- **Two areas:** a training area next to spawn and a long path of 15 beds.
- **Training:** walk up to a training item, press **E** (or tap the button on mobile) to **Train**, then click. Every chop gives Strength. Better items cost Cash and give more Strength per chop.
- **Level:** comes from Strength. Shown top right with a progress bar, along with Strength (yellow 💪 icon) and Cash.
- **Beds:** each sits on cinder blocks with its name (and health) floating above it.
- **Break mode:** press **E** to **Break**. The camera zooms in, an **EXIT** button appears, and each click is a karate chop. The health bar shows e.g. 6 / 6. Damage per chop comes from Strength.
- **When a bed breaks:** it splinters into flying pieces, cash pops out, and a **COMPLETED ✅** sign appears next to it. The bed respawns instantly.
  - **First time:** you go back to normal view automatically.
  - **Already completed:** you stay in the break screen and can keep breaking it for cash ("Broken x3") until you press **EXIT**.
- **Personal progress:** each player breaks their own copy of a bed, and COMPLETED signs are personal. Everything saves (published game, or Studio API access turned on).

## Scripts (where they are in Studio)

| Script | Type | Where in Studio | Source file |
|---|---|---|---|
| `GameConfig` | ModuleScript | ReplicatedStorage | `src/shared/GameConfig.luau` |
| `WorldBuilder` | ModuleScript | ServerScriptService | `src/server/WorldBuilder.luau` |
| `GameServer` | Script | ServerScriptService | `src/server/GameServer.server.luau` |
| `GameClient` | LocalScript | StarterPlayer › StarterPlayerScripts | `src/client/GameClient.client.luau` |

All numbers (bed health, cash, training items, damage, levels) are in `GameConfig`.

## Training items

| Item | Strength per chop | Price |
|---|---|---|
| Pillow | +1 | free |
| Wooden Plank | +3 | $50 |
| Brick | +10 | $400 |
| Cinder Block | +30 | $2.5K |
| Steel Bar | +100 | $15K |
| Diamond Block | +350 | $100K |

## Beds (in path order)

| # | Bed | Health | Cash |
|---|---|---|---|
| 1 | Cardboard Bed | 6 | $5 |
| 2 | Camping Cot | 15 | $12 |
| 3 | Kids Bed | 40 | $30 |
| 4 | Wooden Bed | 100 | $70 |
| 5 | Water Bed | 250 | $160 |
| 6 | Cozy Bed | 600 | $350 |
| 7 | Hospital Bed | 1.4K | $800 |
| 8 | Racecar Bed | 3K | $1.7K |
| 9 | Princess Bed | 6.5K | $3.5K |
| 10 | Royal Bed | 14K | $7.5K |
| 11 | Golden Bed | 30K | $16K |
| 12 | Ice Bed | 60K | $33K |
| 13 | Lava Bed | 120K | $65K |
| 14 | Diamond Bed | 250K | $130K |
| 15 | Cosmic Bed | 500K | $260K |

## Related notes
- [[Break A Bed/How It Works|How It Works]]: how the systems work
- [[Break A Bed/Decisions|Decisions]]
- [[Break A Bed/Bugs and Fixes|Bugs and Fixes]]
- [[Break A Bed/Ideas|Ideas]]
- Sessions: [[Break A Bed/2026-10-10|2026-10-10]]
