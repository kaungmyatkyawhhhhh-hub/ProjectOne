# Break A Bed: Project Overview

#break-a-bed #roblox

A Roblox clicker game like Chop A Brick. Walk up to a bed, click to hit it, drain its health bar. When it breaks it falls apart, pays coins, and respawns a few seconds later. Rebirths reset your coins for permanent bonuses and unlock better beds.

- **Status:** working and play-tested in Studio (2026-10-10). See [[Break A Bed/2026-10-10|latest session]].
- **Studio place:** "Break A Bed" (placeId `116443177548785`)
- **Code folder:** `C:\Users\USER\Documents\Cashgrab` (its `CLAUDE.md` has the technical notes)
- **Place file:** `Cashgrab\BreakABed.rbxlx` (includes a baseplate and spawn point)

## Features
- **Beds built from code:** the server builds every bed, health bar and floor pad when the game starts. Nothing to build by hand. The edit view stays empty until you press Play.
- **Hitting:** click a bed within 14 studs. 1 damage per hit (+1 per rebirth), 10% chance of a 3× crit. Max about 8 hits a second (server-checked).
- **Health bar:** name and HP above each bed, green → yellow → red.
- **Breaking:** pieces fly apart and fade after 3s. New bed after 5s.
- **Coins:** split between everyone who hit the bed, by damage dealt, times their rebirth bonus.
- **Rebirths:** see [[Break A Bed/How It Works#Rebirths|Rebirths]].
- **Locked beds:** a 🔒 on the health bar and a red outline. The server refuses the hit.
- **Effects:** white hit flash, fluff particles, damage numbers, gold coin shower, "+X coins" popup, hover outline.
- **HUD:** coin counter (top) and rebirth panel (left) with a confirm dialog.
- **Saving:** coins and rebirths save (needs a published game, or Studio API access turned on).

## Scripts (where they are in Studio)

| Script | Type | Where in Studio | Source file |
|---|---|---|---|
| `BedConfig` | ModuleScript | ReplicatedStorage | `src/shared/BedConfig.luau` |
| `BedBuilder` | ModuleScript | ServerScriptService | `src/server/BedBuilder.luau` |
| `BedServer` | Script | ServerScriptService | `src/server/BedServer.server.luau` |
| `BedClient` | LocalScript | StarterPlayer › StarterPlayerScripts | `src/client/BedClient.client.luau` |

All tuning (health, coins, rebirth costs, layout, sounds) is in `BedConfig`.

## Beds

**Starter area** (front rows, open to everyone): Cot ×4, Single Bed ×4, Double Bed ×3, King Bed ×2, Canopy Bed ×1.

**Tier row** (back row, left to right: bigger, tougher, pays more):

| Bed | Health | Coins | Needs |
|---|---|---|---|
| Cardboard Bed | 15 | 4 | n/a |
| Wooden Bed | 40 | 12 | n/a |
| Cozy Bed | 120 | 40 | 1 rebirth |
| Royal Bed | 350 | 130 | 2 rebirths |
| Golden Bed | 900 | 375 | 3 rebirths |
| Diamond Bed | 2,500 | 1,100 | 5 rebirths |
| Cosmic Bed | 7,000 | 3,500 | 8 rebirths |

## Related notes
- [[Break A Bed/How It Works|How It Works]]: how the systems work
- [[Break A Bed/Decisions|Decisions]]
- [[Break A Bed/Bugs and Fixes|Bugs and Fixes]]
- [[Break A Bed/Ideas|Ideas]]
- Sessions: [[Break A Bed/2026-10-10|2026-10-10]]
