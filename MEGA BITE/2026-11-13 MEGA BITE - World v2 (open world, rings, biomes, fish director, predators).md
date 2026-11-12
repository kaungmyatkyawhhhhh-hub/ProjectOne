# MEGA BITE - World v2 (13 Nov 2026)

Owner's order: "make the map landscape like realistic terrain ... an open world that people can explore but it gets harder the further they get ... the npc pathwalking need to be better because some are stuck in ground, noclips into props, stays in one place".

Status: built in Studio, tested in Play, **not published** (the owner tests and publishes).

## The world in one picture
![[MEGA BITE/UI/map_art/worldmap_preview.png]]

Studs from the centre (North = -Z):

| Ring | From | To | What lives there |
|---|---|---|---|
| SAFE REEF | 0 | 300 | reef schools, no hunters |
| OPEN SEA | 300 | 510 | Sardine, Mackerel, Squid, Puffer; Hunter Barracuda x6 |
| THE WILDS | 510 | 720 | Mackerel, Squid, Tuna (x1.2 size); Barracuda x3, Reef Prowler x5 |
| DEEP SEA | 720 | 930 | Tuna, Squid, Mackerel (x1.5); Prowler x4, Big Chomper x4, Hammer Brute x2 |
| THE FAR DEEP | 930 | 1200 | Tuna, Squid (x2); Big Chomper x4, Hammer Brute x4, Ancient Titan x2 |
| RED TRENCH (PvP) | 1200 | 1780 | trench schools; cliff 1150-1250, floor at about -128 |

Biomes by direction: **N Kelp Hills** (green hills, kelp forests), **E Sunken Kingdom** (sandstone terraces, mesas), **S Whale Graveyard** (pale dunes, starfish fields), **W Glow Gardens** (dark ridges, violet spires, neon corals).

Landmarks: Kelp Lighthouse (N, 70/-630), The Ocean King (E, 800/90), Whale Graveyard (S, -90/700), Crystal Arch (W, -560/-60), The Lost Galleon (SW, -880/520). The first two are built; the other three are still to model.

## How it is made (all in Studio, ServerStorage; copies in `MEGA BITE/World/`)
- `MB_WorldGen` (ModuleScript): one height function for the whole terrain. `G.write(x0, x1)` writes it. 31.9 M cells.
- `MB_WorldDress`: places the kit props by biome in clusters (194 clusters, about 3,200 parts). Seeded, re-runnable.
- `MB_WorldBake`: bakes two height maps (8-stud cells): the seabed, and the highest solid thing. **Re-run after every map change.**
- `ServerScriptService.MB_World`: reads the baked maps. `floor`, `top`, `clampY`, `wall`, `tier`, `biome`. No raycasts at run time.
- Config: `GameConfig.World` (rings, landmarks, chest numbers), `C.Fish.Pop` (director), `C.Predators.Tiers`.

## Fish
- The reef keeps its own schools.
- Everywhere else a **director** keeps 16 schools within 260 studs of each player (spawned 180+ studs away, mostly ahead; removed beyond 340 studs). Species and size come from the ring.

## Predators
- 34 in total. Each has a ring, a home, patrols within 170 studs, and gives up a chase 330 studs from home.
- Only predators within 450 studs are sent to a client (phones).

## Movement audit (13 Nov, `ServerStorage.MB_AuditMod`)
A Studio test that samples every fish and predator once a second around several spots and counts: under the seabed, inside a solid prop, above the surface, not moving, sudden jumps in height.

| | Before | After |
|---|---|---|
| Fish inside a solid prop | 16-38 per 10,000 samples | **0** per 12,752 |
| Fish under the seabed | 0 | 0 |
| Predators inside a prop | up to 4 per 1,300 | **0** per 1,632 |
| Predators above the surface (y 92) | yes | **0** |
| Schools standing still in front of a wall | yes | 0 (only the welcome schools wait, on purpose, and now mill around) |

What was wrong and what changed:
1. The baked "top" map used one ray per cell: it missed thin spire tips and boulder edges. Now 9 rays per cell.
2. Predators were lifted over anything solid, even spires that reach the surface. Now a thing too tall to hop over is a wall: they slide around it; low things: they rise early and smoothly; never above the surface.
3. Fish climbed spires and sat inside the tip. Now they slide sideways along a wall; a fish that is already inside something swims out toward its school.
4. Schools were given goals (and were even born) on top of spires. Goals and spawns are only in open water now.
5. A school whose way was blocked picked a new goal every step and never moved. Now it goes round the wall.
6. The open-sea welcome school could appear inside a border spire. It now picks open water.
7. A waiting welcome school stood frozen. It now mills gently.

Run it again after map changes (Play, server command):
`require(game.ServerStorage.MB_AuditMod:Clone())({{70,-470},{700,60},{-560,-60}}, 13)`

## Still open
- Balance is a first pass (predator EXP, chest shares, school density).
- Phone performance check with about 6,400 map parts.
- The three unbuilt landmarks; the Open Sea kit props; the giants (turtle, whale, eel, Kraken).
