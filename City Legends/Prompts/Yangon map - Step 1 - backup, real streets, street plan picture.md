> **DONE on 13 Nov 2026 (by Claude in chat). Do not run this again.**
> Results: [[2026-11-13 Yangon map - Step 1 report]]. Waiting for the owner's OK on the street plan picture before Step 2.

# Yangon map – Step 1: backup Monaco, download real streets, street plan picture

Game: City Legends (`Games/CityLegends`). Yangon replaces the Monaco map.
Do this step only, then STOP and show the owner the street plan picture. Do not build any roads in Studio yet.

## Decisions (owner, 13 Nov 2026)
- **Main roads = 2+2 lanes, WITH traffic.** Main roads are: the loop `YANGON MAP GAME` (13.1 km), `new roasd` (2.5 km) and `more roads` (1.55 km).
- **Streets = 1+1 lanes, NO traffic.** That means every real street downloaded from map data that isn't one of the main roads above.
- Traffic AI only spawns and drives on main roads. Streets have no traffic lanes and no spawners.
- `new roasd` and `more roads` are drawn by the owner. If a real road lies within 15 m of the drawn line for most of its length, snap the drawn line to that real road. Otherwise build it as drawn, as a fictional road. Either way it is a 2+2 main road.
- Source file: `imports/refs/map/ygn 3 map project.kml`. This is the newest one; `ygn map project more main roads.kml` is the same file. Landmarks: `optima` (player start), `novotel`, `mm plaza`.

## 1. Backup
- Copy `CityLegends.rbxl` to `backups/CityLegends_monaco_full_2026-11-13.rbxl` before touching anything. Also export the Monaco map folder as its own `.rbxm`.

## 2. Download the real streets (OpenStreetMap, Overpass API)
Area (loop plus 300 m on each side): south 16.8102, west 96.1279, north 16.8568, east 96.1605.

```
[out:json][timeout:120];
(
  way["highway"~"^(motorway|trunk|primary|secondary|tertiary|unclassified|residential|service|living_street|motorway_link|trunk_link|primary_link|secondary_link|tertiary_link)$"](16.8102,96.1279,16.8568,96.1605);
);
out geom tags;
```
POST it to `https://overpass-api.de/api/interpreter`. Save the result as `imports/refs/map/ygn_osm_roads.json`.
Keep these tags: `highway, name, lanes, oneway, junction (roundabout), bridge, layer, tunnel`.
- Heights: sample ground height every 30 m along every road from `https://api.opentopodata.org/v1/srtm30m` (100 points per request, 1 request per second). Save them as `imports/refs/map/ygn_heights.json`.

## 3. Street plan picture (for the owner to approve)
Make `imports/refs/map/ygn_street_plan.png` (2048 px, north up, with a scale bar). It should show:
- the real streets in grey (thin);
- the main roads in colour: loop = gold, `new roasd` = blue, `more roads` = green, drawn thick and labelled "2+2, traffic";
- roundabouts as clean circles with a ring outline;
- bridges and flyovers marked with a hatched band and the label "BRIDGE";
- the 3 landmarks as pins (Optima = START).
Also make a zoomed crop of each place where a main road meets a real street (junctions), as `ygn_junctions_sheet.png`.

## 4. Report, then stop
Give the owner a short report: the number of real streets, roundabouts and bridges; whether `new roasd` and `more roads` were snapped to real roads or kept as drawn; and both pictures.
Save the report to the vault as `City Legends/2026-11-13 Yangon map - Step 1 report.md`.
Wait for the owner's OK before Step 2 (ground and smooth roads).
