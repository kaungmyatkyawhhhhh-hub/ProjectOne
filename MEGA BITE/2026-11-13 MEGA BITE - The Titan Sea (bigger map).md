# 2026-11-13 MEGA BITE - The Titan Sea (bigger map)

Owner 11:14: "put even further ones for megalodon cuz megalodon have no point rn". Owner 11:27: "make the map bigger".
Based on: [[2026-11-13 MEGA BITE - Bigger sea, landmarks and giant creatures (plan)]] (it planned a wider sea with the trench
moved out), [[2026-11-13 MEGA BITE - Megalodon prey (colossal fish)]], the quality-nerd rule "a bigger sea never ships empty".
Decision: the trench and its props stay where they are; the new water is a ring BEYOND the trench (cheaper, nothing built
today has to move, and it is the "even further" place for the Megalodon). Nothing is published. Tested in Studio Play, one
player, PC.

## The map now (studs from the centre)
| Zone | Radius | Notes |
|---|---|---|
| Safe Reef | 0-300 | unchanged |
| Open Sea (4 biomes, 4 rings) | 300-1150 | unchanged |
| Red Trench (PvP, EXP x4) | 1200-1800 | PvP now ENDS at 1800 (`Trench.End`); before it ran to the edge |
| **TITAN SEA** (new, no PvP, EXP x3) | 1800-2480 | golden shelf at about -60; swim border 2440 / 2480; wall to the surface at 2500 |
Playable radius 1780 -> 2480: the map's area is 1.94x what it was (about +9.4 M studs^2).

## What the Titan Sea is
- Idea: everything is GIANT. The brightest water in the game (owner rule: never dark): gold sand, turquoise meadows,
  clear warm light. You reach it by crossing the Red Trench and climbing its far cliff.
- Terrain: `MB_WorldGen` (backup `_preTitanSea_13Nov`): the far cliff climbs from the trench floor (-128) to the shelf
  between r 1690 and `World.TitanIn` 1830; shelf to `TitanOut` 2400 (long swells, hills, a few seamount ridges); the wall that
  reaches the surface is at `WallTop` 2500. Materials: Snow = gold sand, LeafyGrass = turquoise meadow (terrain colours set
  in `G.colours()`). `G.write(x0, x1, nil, {r0, r1})` now writes only the chunks that touch a ring (the whole ring took 13 s).
  Terrain box: `TerrainHalf` 1920 -> 2560. The reef, the Open Sea, the Kraken pit and the eel burrow were not rewritten.
- Dressing: new `ServerStorage.MB_TitanDress` -> `workspace.MB_Map.TitanSea`: 1,463 props in 86 patches + 420 singles, 19
  kinds, the same hand-made props 2-4x bigger (giant clams 26-46 studs, mushrooms up to 100, kelp up to 125, a ring of
  64-96 stud columns "titan gate", seamount spires). Six patch recipes, each mixes 5+ kinds.
- Fish (`Fish.Pop.Tiers.titan`): Emperor Prawn, Abyss Squid, Elder Tuna, Thunder Mackerel (3 shares each), Titan Tuna 3,
  Monster Puffer 2, King Mackerel 2, Tuna 2. `ZoneMult.titan = 3`.
- Hunters (`Predators.Tiers.titan`): 6 Ancient Titans (they hunt Megalodon players: 600 a hit, beaten in about 9 bites),
  4 Hammer Brutes, 3 Big Chompers. `tier.outer = true` gives a ring its own bounds in `MB_PredatorServer` (they never go
  down into the trench). The red-hunter hunts stay in the Open Sea.
- Mood: `MB_BiomeMood` blends to a bright gold-turquoise water past the trench and switches the "further = darker" rule off
  there; `MB_PvPClient` fades the red trench mood out up the far cliff.
- Maps: the painted map picture still reaches r 1780 (`World.MapImgR`); the Titan Sea is drawn as a gold ring around it on
  the world map (with its name) and on the minimap. The red trench band on the minimap ends at `Trench.End`.
- Creature height maps: `MB_WorldBake` HALF 1800 -> 2560 (640 x 640 cells, 11-14 s).
- Backups: `GameConfig_preTitanSea_13Nov`, `MB_WorldGen_`, `MB_WorldBake_`, `MB_PredatorServer_`, `MB_FishServer_`,
  `MB_PvPClient_`, `MB_BiomeMood_`, `MB_HUD_`, `MB_WorldMap_` (all `..._preTitanSea_13Nov`).

## Checked in Play (Megalodon at r 2050)
- Zone reads TITAN SEA, not PvP; within 400 studs: 10 Abyss Squid, 10 Elder Tuna, 6 Thunder Mackerel, 12 Titan Tuna, 20 Tuna.
- 13 hunters live beyond r 1700 (6 Ancient Titan, 4 Hammer Brute, 3 Big Chomper), all inside the ring.
- Movement audit over the new ring: 0 fish in the ground or in props, 0 predators in props or above the surface (the audit's
  "predGround 144" is the four sleeping red hunters parked under the map).
- World map and minimap show the gold ring; 0 script errors or warnings.

## Not done / not checked
- No landmark, chest, giant or own sound in the Titan Sea yet. It has props, fish and hunters only.
- The world-map picture was not repainted: the Titan Sea is a plain gold ring, and the old map is drawn 28% smaller in the disc.
- Phones: not tested. The terrain is 1.8x the voxels of before and there are 1,463 more props (memory in Studio Play 2.6 GB,
  which says little about a phone). Triangles in view were not measured there.
- The patches are 215 studs apart: from a Megalodon camera that reads full; a small shark would see open sand between them.
- The quest text still says "Open Sea" for fish eaten there; the kid sims were not re-run.
