---
date: 2026-11-25
tags: [city-legends, roads, roads05, bugs, map]
---
# Road bug sweep: whole map (25 Nov 2026)

Owner flew over the map: "countless bugs" on the roads. Shots: `refs_2026-11-25_owner_road_bugs/` (4).
State and ids: `Games/CityLegends/build/city_1to1/rebuild_progress.json` "roadbugs_25nov". Data: `build/city_1to1/roadbugs_25nov/`.

## How the bugs were counted (new tools)
- `tools/yangon/city/roadbugs_index.py`: matches every road mesh in the place (3,805, list printed from Studio) to the local .glb it came from (3,549). The 29 P8 cells (baked on the laptop, no files here) were read in Studio with EditableMesh (`roadbugs_p8.py`).
- `roadbugs_detect.py`: counts each bug kind per 1536 cell from the real triangles (`RB_FAST=1` = only spike + gap; `RB_OVERRIDE=<glb folder>` = check a new bake before it goes in).
- `roadbugs_view.py`: top-down picture of the meshes with the spots ringed.
- `tools/yangon/RoadTerrainPoke.luau` (Studio): grass terrain lying over the asphalt.
- Every kind was checked by eye on top-down pictures before counting it.

## Bug kinds, causes, counts
| Kind (owner shot) | Cause | Before | After | Fixed how |
|---|---|---|---|---|
| Grass lying on the road (3, 4) | terrain from the verge fill bulges 0.1-4.9 studs over the road. The old trim tested one point per 4-stud cell, and smooth terrain rises between cells | 4,893 road boxes (805 over 0.5) | 155 (13 over 0.5) | carved every spot of a road box with terrain over it down to road top - 2, two passes. RoadVerge05.trim now tests 5 points and can take a list of boxes. Saved v2054 |
| Sawtooth / slivers sticking into the grass (2) | the bake clipped PARTS by their centre at a district edge. A road quad is two wedges, so every other wedge was dropped (teeth); the far side was baked from other data or not at all (map edge) | 180 spike tips in 85 cells | see below | `roads05_clip.py`: the bake keeps parts 60 studs past the edge and cuts every triangle exactly on the edge (one straight line) |
| Small bare holes inside the road surface (3: grass triangle) | cracks and pockets the builder leaves at mouths and seams | (run 2) | see below | `roads05_gapfill.py` in the bake: holes under 600 sq studs in the union of all surfaces are closed with asphalt or pavement (roundabout middles, islands, decks left open) |
| Lane dashes not lining up (1, 3) | each lane line started its dash pattern at its own start | 1,503 lone dashes | not rolled out | `roads05_paint.py`: dashes keep step with the road's centre-line distance. Needs a paint re-run per build |
| Crumpled kerbs at a mouth corner + grass pocket (4) | builder corner code (YangonRoads corners / mouths) | 404 kerb pieces off the kerb line | not fixed | builder work, next pass |
| Median nose = long white/red wedge into the junction (1) | the data eases the median to 0 over several samples and the builder lays the narrowing part as one kerb-coloured nose | 169 stubs, 23 in a junction | not fixed | data (roads05_fix: end medians blunt) + rebuild |
| Yellow lines crossing / into a junction (4) | paint polygons of two roads overlapping | 81 crossings, 140 yellow in a junction | not fixed | paint rules |
| Ramp wall at ground level in a junction (4) | deck ends (deck agent's area) | 878 low wall triangles near junctions | left to the deck agent | |

## Proof on one cell: 12x11 (P5 map edge)
- Before: road ends in a sawtooth at the map edge, 4 spike tips, 5 gaps. After: straight cut, 0 spikes, 0 gaps.
- Pictures: `2026-11-25 Road bugs - P5 map edge sawtooth (top-down mesh) - before/after.png`, `... straight cut instead of sawtooth (Edit) - after.jpg`.
- The Baho Road junction picture (`... Baho Road mouth, crumpled kerb corner and median nose wedges (Edit) - before.jpg`) shows the kinds not fixed yet.

## Roll-out (mesh-only swaps, whole cells, same build as in the place)
- `roadbugs_rebake.py plan` finds each cell's owner build from its meshes; `bake <tag>` re-collects that build's pages with the pad and bakes only those cells (2-15 min a build).
- Cells the deck agent was re-baking were left out (list in the progress file).

## Lessons
- See `Roblox Playbook/Map placement rules (every game).md`, lesson 25 Nov "road bug sweep".
