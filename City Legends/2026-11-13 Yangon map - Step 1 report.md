---
tags: [city-legends, yangon-map, report]
created: 2026-11-13
---
# Yangon map – Step 1 report (backup, real streets, street plan picture)

Done by Claude in chat on 13 Nov 2026. Nothing was built or changed in Studio.
**Waiting for the owner's OK on the street plan picture before Step 2 (ground and smooth roads).**

![[ygn_street_plan.png]]

![[ygn_junctions_sheet.png]]

## Owner's rules (13 Nov 2026)
- Main roads: 2+2 lanes, with traffic.
- Streets (every other real street): 1+1 lanes, no traffic.
- Traffic only spawns and drives on main roads.

## The 3 main roads
Source: `imports/refs/map/ygn 3 map project.kml` (the newest file; "ygn map project more main roads.kml" is an exact copy).
A drawn line counts as "on a real road" where a real road lies within 15 m of it.

| Main road | Length | On real roads | Made-up (built as drawn) |
|---|---|---|---|
| Main loop `YANGON MAP GAME` (gold) | 13.1 km | 12.0 km: Thanlwin Rd, University Avenue Rd, Kabar Aye Pagoda Rd, Parami Rd, Pyay Rd | 1.1 km: the link from the Hanthawaddy roundabout back to Optima |
| `new roasd` (blue) | 2.5 km | 1.0 km: Kabar Aye Pagoda Rd, south from the loop | 1.5 km: the leg west to the loop link |
| `more roads` (green) | 1.55 km | all of it: University Avenue Rd, from Pyay Rd to Thanlwin Rd | none |

Details per road (sections, real road ids, roundabouts, bridges, landmarks): `imports/refs/map/ygn_main_roads.json`.

## What the real street data holds
Area: the loop plus about 300 m on each side (south 16.8102, west 96.1279, north 16.8568, east 96.1605).
- 2,661 real road pieces, 293 km in total.
  - Big roads: 382 pieces (trunk 75, primary 186, secondary 48, tertiary 10, slip roads 63).
  - Streets: 1,131 pieces (residential 1,089, living street 38, unclassified 4).
  - Service lanes, driveways and parking aisles: 1,148 pieces.
- Roundabouts: 3. One big one on the loop (Hanthawaddy roundabout, about 60 m wide, Pyay Rd / U Wisara Rd). Two mini roundabouts in the north, under 20 m wide; one is about 100 m from the loop's north-west corner.
- Bridges: 5.
  - Pyay Rd flyover over the Hledan junction, about 1.1 km, on the loop.
  - Kabar Aye Pagoda Rd flyover over the University Avenue junction, about 440 m, on the loop and on "new roasd".
  - 3 short bridges (8 to 25 m). One is on the loop (Kabar Aye Pagoda Rd).
- No tunnels.
- Inya Lake sits inside the loop (saved in `ygn_osm_areas.json`).
- Side streets: real side roads touch the main roads at 389 points, mostly residential streets and service lanes. The made-up parts cross 16 real streets (loop link 6, "new roasd" 10).
- Ground height: 8 m to 54 m above sea level. The lake surface reads 16 m.

## Decisions Claude made (say so if you want any changed)
1. **Flyovers:** main-road traffic goes over the top. Roads that join underneath do so at ground level ("more roads" joins Pyay Rd under the Pyay flyover; the loop turns under the Kabar Aye flyover).
2. **Made-up parts stay where you drew them.** The made-up part of "new roasd" runs beside the real Pearl Street, 30 to 60 m south of it. It is kept on your line, not moved onto Pearl Street.
3. **"more roads" is treated as fully real.** Your 4-point line is at most 18 m off University Avenue Rd, so it is built on that road.
4. **Where the loop follows a road with two separate sides** (Pyay Rd, Kabar Aye Pagoda Rd), both sides together are the 2+2 main road.

## Files
All in `Games/CityLegends/imports/refs/map/`:
- `ygn_street_plan.png`: the plan picture (2048 px wide, north up, scale bar).
- `ygn_junctions_sheet.png`: 12 close-ups; the pink numbers match the plan.
- `ygn_osm_roads.json`: every real road (highway type, name, lanes, oneway, roundabout, bridge, layer) plus streams and ponds.
- `ygn_osm_areas.json`: Inya Lake and 2 smaller lakes.
- `ygn_heights.json`: ground heights on a grid of about 60 m.
- `ygn_main_roads.json`: the 3 main roads split into real and made-up sections.
The scripts that made the pictures are in `Games/CityLegends/tools/yangon/` (see its README).

## Backup
- File copy of the vault's place file: `Games/CityLegends/imports/backups/CityLegends_monaco_file_2026-11-13.rbxl` (54 MB). That folder is not synced to GitHub, so this copy lives on this PC only.
- The live place in Studio was at **Roblox version 688** when this ran. The Monaco map is `Workspace.Riviera` (388,029 parts). Version 688 in the place's version history is the Monaco restore point.
- Not done: the separate `.rbxm` export of the map. The vault's place file may also be older than the live place. So before Step 2 touches Studio, save the live place with a "Monaco backup" label and note the version number here.

## How this differs from the Step 1 prompt
- **Street data source:** overpass-api.de refused the request (error 406), so the streets came from OpenStreetMap's own map API. It is the same data. © OpenStreetMap contributors, ODbL: credit them in `Config.Credits`.
- **Heights:** taken on a 60 m grid over the whole area (5,133 points, SRTM 30 m), not every 30 m along each road. SRTM includes roofs and trees, so smooth it before use.

## Next (Step 2, after the owner's OK)
- Labelled Monaco save in Studio.
- Road design: centre lines for the 3 main roads (smooth curves, gentle slopes), then the streets.
- Decide which service lanes to build. Suggestion: skip driveways and parking aisles to keep the part count low.
