---
tags: [city-legends, yangon, landmark, novotel]
created: 2026-11-28
---
# Novotel Yangon Max: real layout (28 Nov 2026, evening and night)

Owner (28 Nov): "Novotel Yangon Max is in the wrong position; the real one has an underground car park, a lobby and stuff". Then: "you dont need to build the rooms. just build the swimming pool area and car parking and hotel lobby", "also build the basketball court", "do it on the studio place i opened", "I give u access to do everything", "i will leave my pc overnight do what u have to do".

**State: LIVE in the place, saved v2466, not published.** `Workspace.Yangon1to1.Landmarks.NovotelYangonMax` (about 1,150 parts), built by `Games/CityLegends/tools/yangon/Novotel.luau` (`ServerStorage.ClaudeTools.Novotel`). The old Monaco-style hotel is no longer built on the lot.

## What was wrong
- The lot was already on the real spot (OSM way 471327865, 459 Pyay Road). The **building** was wrong: the old Monaco hotel on a 200 lot, facing the side lane.
- The real hotel faces **Pyay Road (east)**. Its drive is the service lane the game already had: along the north side, then south across the front, back out to Pyay Road.

## Sources (dated; newest first)
| What | Source | Date |
|---|---|---|
| Front at night: grey stone front block, lit glass wall with bronze fins, NOVOTEL letters, fountains, flagpoles | Google Maps, the hotel's own photo | Jun 2026 |
| Front by day, lobby door, pool, lounge | novotelyangonmax.com/photogallery (files uploaded 2026-06) | Jun 2026 |
| Pool deck, court | novotelyangonmax.com/recreation (files named 2026-08-25) | Aug 2026 |
| Lobby reception, lobby lounge, pool | all.accor.com/hotel/9045 | date not stated (current listing) |
| Outline, towers, pool and court on the roofs | Esri satellite + OSM way 471327865 | - |

- The site says: "Outdoor Pool: located on 6th floor".
- The court photo (Aug 2026) shows **both**: a green tennis court with a net and white lines, **yellow basketball lines and a hoop**, red surround, tall dark-green mesh fence. Both are built.
- The hotel's photos and the real-versus-ours sheets are only on this PC (`Games/CityLegends/build/landmarks/novotel/refs/` and `compare/`, not in git: they are the hotel's pictures).
- Not used (too old for the owner's rule): Wikimedia Commons has only 2018 pictures.

![[2026-11-28 Novotel - satellite with the OSM outline.jpg]]

## What is built
Frame: `a` runs toward Pyay Road, `b` to the right of it, from the outline's south-west corner (27215.6, 30211.9). Levels: car park 54.5, lobby 63.5, pool deck and court 117.5 (18 m above the lobby: the 6th floor), towers to 190.

| Part | What |
|---|---|
| Front block | stone, glass wall with bronze fins, NOVOTEL on the parapet, round white canopy on bronze columns |
| Lobby (ground floor, double height) | light oak walls and ceiling, cream marble floor, 3 white desk pods with oak fronts, dark sparkle panels and columns, ceiling ring, pendants, round rug + table with an orchid + 4 blue chairs, palms, luggage cart, scanner at the door, sofa group, slat screen; lounge half: timber floor, turquoise chairs on purple rugs, sparkle balls, GOURMET BAR counter |
| Forecourt | paved court that follows the lane's real heights (60.0 to 61.7), fountain basin, flagpoles, hedge planter |
| Car park | under the lobby level. The site falls to the west, so you drive in **level from the north lane** and it lies below the Pyay Road side. 60 bays, columns, strip lights, blue wall band, 8 studs clear |
| Pool deck (6th floor) | L-shaped mosaic pool (wade in, 2.6 deep), hardwood deck + terracotta pavers, blue loungers on both sides, square blue umbrellas, palms, 2 striped cabanas, pool bar, glass rail |
| Court (6th floor) | tennis court with net + yellow basketball lines, 2 hoops, red surround, mesh fence |
| Lift | B1 (car park) / L (lobby) / 6 (pool, court). Same parts and tag (`MallLift`) as the Myanmar Plaza lift |
| Towers, middle block, ballroom block | plain massing with window strips. **No rooms** (owner). |

Surfaces use six materials made with Studio's material generator (in MaterialService): `NovoOakLight`, `NovoMarble`, `NovoDeck`, `NovoPaver`, `NovoPoolTile`, `NovoStone`. Chairs, sofa, palms, plants and the luggage cart are the place's own `ServerStorage.VenueKit` pieces, recoloured.

![[2026-11-28 Novotel - front from Pyay Road (Studio).jpg]]
![[2026-11-28 Novotel - lobby (Studio).jpg]]
![[2026-11-28 Novotel - pool deck (Studio).jpg]]
![[2026-11-28 Novotel - court (Studio).jpg]]
![[2026-11-28 Novotel - car park (Studio).jpg]]
![[2026-11-28 Novotel - preview aerial from the south-east (staging).jpg]]

(Studio Edit pictures with the Play light. The last one is my own rough render of the part list: it shows the whole layout.)

## The game side (`src/server/Hotel.lua`, `src/shared/Config.lua`)
- With the real building in the place, `Hotel.buildWorld` makes no building. `buildReal` puts the venue's working pieces at the model's `Markers`: the valet bay under the canopy, the VALET stand by the doors ("Get my car"), the 4 suite plinths and the residents' board on the lobby's north wall, the SUITES lift door ("Up to my suite"), 3 receptionists in purple jackets.
- **The four suite floors now stand 1,400 studs above the hotel** (`SUITE_SKY`), out of sight from the street. The real hotel has 12 floors and the suite stack would double it. Owners keep their suite, the pay and the lift. One number puts them back on top of a tower.
- The hotel's site frame now faces Pyay Road, so the fast-travel spot is on the lane in front.

## Checked
- In Edit, by numbers: tool in Studio = repo; no ground through the car park floor (0 of 650) or lobby floor (0 of 154); nothing of the map inside the hotel's box; it does not overlap the lanes or the south road.
- **Play (test save, put back on `CityLegends_v1` after): the server built the venue, the old hotel did not appear, 1 valet bay, 1 valet stand, 4 suite plinths, 1 suite lift, the hotel lift registered, no script errors from the hotel.**
- Lune `world_test`: ALL OK. `luau-lsp`: no new errors.

## Not checked / not done
1. **Nobody has walked or driven it in Play.** This PC (16 GB) ran out of memory in Play (Studio 10 GB, 0.3 GB free): the MCP could not take pictures or drive. To test on the bigger PC: drive in from the lane, the car park gate, the hotel lift B1 / L / 6, the pool, valet, buying a suite, the suite lift.
2. Colours in Play (Edit shows everything a little blue).
3. Toddy palms along the front as on the photo (use the map's palm templates).
4. The real car park ramp's place is unknown (no photo found); the level gate on the north lane is my choice from the ground heights.
5. The small second pool on the middle roof is drawn but can't be reached.
6. A 2-5 stud grass strip is left between the forecourt paving and the lane.
7. AYA Bank's roof sign (seen on the pool photo) is left off.

## Rebuild
`python tools/yangon/pack_tools.py imports/sync/novotel_tool.rbxmx tools/yangon/Novotel.luau`, PATCH asset 133014134133489, `insert_asset`, move `Novotel` into `ServerStorage.ClaudeTools`, then `require(ClaudeTools.Novotel:Clone()).build()` (`.build(game.ServerStorage)` for a staging copy, `.undo()` to remove: with the model gone the old hotel is built again).
