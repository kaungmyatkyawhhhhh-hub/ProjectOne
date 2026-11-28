---
tags: [city-legends, yangon, landmark, novotel]
created: 2026-11-28
---
# Novotel Yangon Max: real layout (28 Nov 2026, evening)

Owner (28 Nov): "Novotel Yangon Max is in the wrong position; the real one has an underground car park, a lobby and stuff". Then: "you dont need to build the rooms. just build the swimming pool area and car parking and hotel lobby", "also build the basketball court", "do it on the studio place i opened" (City Legends, place 121430381830562).

**State: built as a staging model, NOT live yet.** `ServerStorage.NovotelYangonMax` (680 parts), made by `Games/CityLegends/tools/yangon/Novotel.luau` (`ServerStorage.ClaudeTools.Novotel`). The game still builds the old hotel on the same lot when you press Play. Nothing saved by me, nothing published.

## What was wrong
- The lot was already on the real spot (OSM way 471327865, 459 Pyay Road). The **building** was wrong: the old Monaco hotel (white tower, gold letters) on a 200 lot, facing the south side road.
- The real hotel faces **Pyay Road (east)**. Its drive is the service lane the game already has: it runs along the north side, turns south along the front and goes back out to Pyay Road.

## Sources (dated; newest first)
| What | Source | Date |
|---|---|---|
| Front at night: grey stone front block, lit glass wall with bronze fins, NOVOTEL letters, fountains, flagpoles | Google Maps, the hotel's own photo | Jun 2026 |
| Front by day, lobby door, pool, lounge | novotelyangonmax.com/photogallery (files uploaded 2026-06) | Jun 2026 |
| Pool deck, court | novotelyangonmax.com/recreation (files named 2026-08-25) | Aug 2026 |
| Lobby reception, lobby lounge, pool | all.accor.com/hotel/9045 | date not stated (current listing) |
| Outline, towers, pool and court on the roofs | Esri satellite + OSM way 471327865 | - |

- The site says: "Outdoor Pool: located on 6th floor".
- The court photo (Aug 2026) shows **both**: a green tennis court with a net and white lines, **yellow basketball lines and a hoop**, red surround, tall dark-green mesh fence.
- The official photos are kept only on this PC (`Games/CityLegends/build/landmarks/novotel/refs/`, not in git: they are the hotel's pictures). Sources in `refs/SOURCE.txt`.
- Not used (too old for the owner's rule): Wikimedia Commons has only 2018 pictures.

![[2026-11-28 Novotel - satellite with the OSM outline.jpg]]

## What is built (staging)
Frame: `a` runs toward Pyay Road, `b` to the right of it, from the outline's south-west corner (27215.6, 30211.9). Levels: car park 54.5, lobby 63.5, pool deck and court 117.5 (54 studs = 18 m above the lobby: the 6th floor), towers to 190.

| Part | What | Where (a, b) |
|---|---|---|
| Front block | grey stone, glass wall with bronze fins, NOVOTEL on the parapet, round white canopy on bronze columns | a 215-300, b -222..-112 |
| Lobby (ground floor of the front block, double height) | cream floor, timber wall with dark sparkle panels, 3 white desk pods, dark ceiling ring, round rug + black table + blue tub chairs, door with scanner and two dark pots; lounge half: timber floor, wire chairs with turquoise cushions, purple rugs, sparkle balls, GOURMET BAR counter | same |
| Forecourt | paved court falling to the lane (follows the lane's real heights 60.0-61.7), fountain basin, flagpoles, hedge planter | a 300-349 |
| Car park | under the lobby level. The site falls to the west, so you drive in **level from the north lane** (gate a 150-190) and it lies below the Pyay Road side. 60 bays, columns, strip lights, 8 studs clear | a 64-265, b -222..-17 |
| Pool deck (6th floor) | L-shaped pool (wade in, 2.6 deep), timber deck + terracotta deck, blue loungers and umbrellas, 2 striped cabanas, pool bar, glass rail | a 232-348, b -112..-6 |
| Court (6th floor) | tennis court with net + yellow basketball lines, 2 hoops, red surround, mesh fence | a 128-232, b -72..-6 |
| Lift | B1 (car park) / L (lobby) / 6 (pool, court). Same parts and tag (`MallLift`) as the Myanmar Plaza lift, so `MallMovers` runs it | a 217-225, b -126..-118 |
| Towers, middle block, ballroom block | plain massing with window strips. **No rooms** (owner). | west and north |

![[2026-11-28 Novotel - preview aerial from the south-east (staging).jpg]]
![[2026-11-28 Novotel - preview front from Pyay Road (staging).jpg]]
![[2026-11-28 Novotel - preview pool deck (staging).jpg]]
![[2026-11-28 Novotel - preview court (staging).jpg]]

The pictures are my own quick renders of the part list (`tools/yangon/city/parts_preview.py`): no text, no materials, no lights. **Studio's window was minimized all evening, so there is no Studio screenshot yet.**

## Checked (by numbers, in Edit)
- Tool in Studio = repo (checksum 1483824598).
- No ground pokes through the car park floor (0 of 650 samples) or the lobby floor (0 of 154).
- Forecourt edge against the lane: lane top 59.97 at b -176 to 61.68 at b -110; the paving is built to that plane.
- Car park gate: the lane's top (54.5) is level with the lot plate; the 2-wide, 4-deep ditch between them is bridged.
- It no longer overlaps the north-east lane corner or the south road.

## Not done
1. **Go live.** `src/server/Hotel.lua` still builds the old hotel on this lot at run time. It needs a "real building" path: valet bay under the canopy, the "Get my car" stand, the suite buy / upgrade plinths, the "Up to my suite" lift and the residents' board placed in the new lobby (markers are in the model: `Markers.ValetBay`, `Entrance`, `Desk`, `CarParkGate`), and a place for the four suite floors (they are the old tower's crown). Then move the model to `Workspace.Yangon1to1.Landmarks`.
2. **Look at it in Studio and in Play** (photos side by side with the real ones): colours, materials, lights, the NOVOTEL letters, driving in from the lane, the lift, the pool.
3. Real palms along the front (the photo shows toddy palms): use the map's palm templates.
4. The car park ramp's real place is not known (no photo found). The level gate on the north lane is my choice from the ground heights.
5. The small second pool on the middle roof is drawn but can't be reached.
6. A 2-5 stud grass strip is left between the forecourt paving and the lane.

## Choices I made (say if you want them changed)
- The hotel's pictures are current official ones; nothing older than 2026 was used.
- AYA Bank's sign on the tower top (seen on the pool photo) is left off.
- The lift is a real moving lift, not a teleport.

## Rebuild
Edit the tool, then `python tools/yangon/pack_tools.py imports/sync/novotel_tool.rbxmx tools/yangon/Novotel.luau`, PATCH asset 133014134133489, `insert_asset`, move `Novotel` into `ServerStorage.ClaudeTools`, then `require(ClaudeTools.Novotel:Clone()).build(game.ServerStorage)` (or `.build()` for the live spot, `.undo()` to remove).
