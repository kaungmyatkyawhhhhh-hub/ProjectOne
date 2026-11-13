# MEGA BITE - Round 7 build (13 Nov 2026, afternoon)

Owner: "ok do all that" = the five items from [[2026-11-13 MEGA BITE - Kid simulations round 7 (debate, quality nerd, impatient)]].
Everything is in Studio, **not published**. `MB_FreshPlayer` is `false`.

## What was built

| # | Item | Where | State |
|---|---|---|---|
| 1 | **Titan Levels**: a gold bar above FOSSILIZE for the Megalodon | `C.Titan`, `C.TitanNeed`, `C.TitanLevel`; server + client `MB_TitanLevels` | Tested in Play |
| 2 | **Crews**: Roblox friends in the same server, max 4, EXP bonus near each other, no biting crewmates, crew bonus at the Kraken | `C.Crew`; `MB_CrewServer`, `MB_Crew` (chip top-left, invite button) | Built; **needs 2+ players to test** |
| 3 | **Tall props mixed** | `MB_WorldDress` `put()`; in-place swaps in Border / RedTrench | Measured (below) |
| 4 | **The Titan's Gate**: landmark 6 at (2180, 340) with a chest (share 0.25); red hunters also hunt in the Titan Sea | `MB_Map.Landmarks.TitanGate`, `MB_Map.Chests.TitanGate`; `MB_PredatorServer` | Tested in Play |
| 5 | **Update sign at spawn** + **Kraken Saturday** (twice as many Krakens, bonus x1.5, live countdown in UTC) | `MB_UpdateSign`; `C.Giants.Kraken.SatEvery / SatBonus` | Sign tested; the event itself only runs on a real Saturday |

## Titan Levels: changed after the first test

First version: one level per 20,000 EXP, a Gold Rush with every level. In the test account (Fossil III + x2 pass = EXP x6) the shark went from level 11 to level 51 in about 12 minutes, so the Gold Rush never stopped. Fixed the same afternoon:

- Each level is 8% bigger than the last: `need(L) = 20000 x (L + 0.04 x L x (L - 1))`. Level 1 = 20K, level 10 = 272K, level 25 = 980K, level 50 = 2.96M EXP past the Megalodon.
- A level gives a Gold Rush at most every 45 s (`RushGap`), and never shortens a longer rush (the Kraken's).
- Checked: level 28 -> 29 gave a rush, 29 -> 30 right after did not renew it.

## Checks (Play, Megalodon)

- 0 script errors or warnings on the client in three sessions.
- Chest at the Titan's Gate opens (`ChestAt` set, refill 15 min). Base reward for a Megalodon = 7,500 EXP x the player's multipliers.
- World map: 6 landmark rows fit, "6/6 FOUND".
- A hunt started in the Titan Sea (2 Red Titans).
- Zone toast in the Titan Sea: changed to gold, "TITAN SEA · x3 EXP · no PvP" (it used the red danger style). Edited and parse-checked, **not yet seen in Play**.
- Movement audit, 16 spots (Open Sea, Trench, Titan Sea), 58,679 fish samples and 11,424 predator samples: 0 fish in the ground, 0 in solid props, 0 predators in solid props.
- **Found and fixed:** predator #24 (Big Chomper) had its home inside the Kraken's pit (the bake marks the pit as shut) and hung still at the surface. `MB_PredatorServer` now refuses homes and patrol points in a shut cell or inside an arena (`clearAt`). After the fix: 0 predator homes in an arena.

## Quality-nerd measure after the build

Live map, `nerd_live_v3.lua`, 10 seeds per zone ("same prop again" per minute):

| Zone | Noon | Now | Forecast was |
|---|---|---|---|
| Reef (not touched) | 2.5 | 3.05 | 2.5 |
| Open Sea inner (r 300-720) | 3.2 | 2.4 | 2.0 |
| Open Sea outer (r 720-1150) | 3.87 | 3.23 | 2.2 |
| Red Trench | 6.4 | 3.0 | 3.0 |
| Titan Sea | 2.2 | 2.3 | 2.2 |

Model (`nerd_v4.py`): **38 -> 32 tells per 10 minutes** (the forecast said 25.7). Honest reading:

- The Trench hit its forecast. The Open Sea improved less than forecast.
- The first spire swap made the round boulder the new "same prop" (14-18% of what the kid sees). Second pass: 45% of spires are a moss rock or sea stack, 4 in 10 round boulders are a moss rock or flat rock; in the Trench a third of the branch corals and a quarter of the fans and kelp became anemones, barrel sponges, whip corals, tube sponges.
- The reef was not touched and moved 2.5 -> 3.05, so about ±0.5 per minute is noise.
- The measure counts one very tall spire again in every view it stays visible. Part of the remaining "Spire" tells are the same few spires, not copies.
- Titan Sea: the top repeat is the ruin column (82 in the sea + 9 at the gate).

## Not tested / still open

- Crews with 2+ real players (bonus, no friendly bites, Kraken crew bonus).
- Phone test (owner's device): crew chip at top-left, Titan bar above FOSSILIZE, the sign at spawn.
- Kraken Saturday on a real Saturday.
- The Titan's Gate uses the generic chest icon on the map; it has no own drawn icon yet.
- From earlier today, still not re-tested: red hunter damage 300/450, lighthouse beam, slipstream cap, kill feed with a real kill.
- Tier rooms in the Shop/Index: not built.

## Owner's friends (12:37)

"The game needs some polishing and also more evolutions cuz they got to megalodon and game got boring." Titan Levels is a bar, not a new shark. Next job: new evolutions after the Megalodon (sheet -> Blender -> upload, one at a time).

## Backups in ServerStorage

`GameConfig_preRound7_13Nov`, `GameConfig_preTitanGrow_13Nov`, `MB_TitanLevelsServer_preGrow_13Nov`, `MB_TitanLevelsClient_preGrow_13Nov`, `MB_PredatorServer_preArenaHome_13Nov`, `MB_WorldDress_preRockMix_13Nov`.

Calc: `nerd_v4.py`, `nerd_v4_out.json`, `nerd_live_v3.lua`.
