---
tags: [city-legends, yangon-map, plan]
created: 2026-11-14
---
# Whole Yangon map: master plan (Claude builds it, no questions)

**Owner, 14 Nov 2026:**
- "yes do all that until its 1:1 like real yangon. after batch 0.5 is done, do batch 1 then batch 2"
- "the ingame yangon is too clean compared to real life yangon because in real life its compact and in game theres like barely any compared to real life"
- "do all the steps, until the entire yangon map is finished entirely, dont ask me any questions, u can take as much as time that u want. quality > time"
- "also check the roads too, in google earth 3d, some are 4 lane and 6 lane and 2 lane but ingame theyre different"

Batches: [[Yangon map - Build steps (Claude builds it)]] (0.5 = built area, 1 = west to the Hlaing River and down to Shwedagon, 2 = downtown south to the river, 3 = east to Thaketa). Lessons: "In-game Yangon is too clean and empty" and "The Yangon map doesn't look like Yangon".

## What the research found (14 Nov, 5 readers; full reports in `Games/CityLegends/build/plan/*.md` on the PC)
- **Too few streets:** the game has 37.6 km of road; the real network in the same box is about 192 km of public streets (plus 91 km of service lanes). The game shows about 1/5 of the streets.
- **Too few buildings:** OSM only has a part of Yangon's buildings. The built map covers 11% of the buildable land; well-mapped real blocks are 30-43%, and real Yangon is about 45-60% (downtown 70-85%).
- **Road widths and lanes:** OSM lane tags (and the satellite) say:
  - Pyay Road: divided, 3 each way (4 in places).
  - Kabar Aye Pagoda Road: divided, 3 each way (4 on the flyover).
  - Insein Road: divided, 3 each way.
  - No.1 Industrial Road: divided, 2-3 each way.
  - U Wisara Road and New University Avenue: divided, 2 each way.
  - Parami, Inya, University Avenue, Kyuntaw, Saya San, Hanthawaddy, Kanbe: 4 lanes (2 + 2).
  - Residential streets: 2 lanes (1 + 1), many narrower.
- **Parts:** Yangon is already 287,500 parts (roads 185,800, buildings 65,900) and Studio uses 9 GB in Edit. The whole city in today's part style would be well over 1.5 million parts, so new buildings and new streets are built as **meshes** (with simple invisible collision boxes).
- **Motorbikes** are banned in central Yangon: no motorbike clusters (trishaws, bicycles, e-bikes instead).

## Decisions (made by Claude, owner said no questions)
1. **Scale stays 1.6 studs a metre.** A new scale would multiply every part count by 3-4 and throw away batch 0.5. "Compact" comes from the real streets and the real building density, not from the scale.
2. **Lanes follow the real road:** 1 + 1, 2 + 2 or 3 + 3, divided with a raised median where the real road is. Lanes are 16 studs on 2 + 2 roads and 13 studs on 3 + 3 roads (so a 6-lane road stays near its real width), streets 1 + 1 with half 12, narrow lanes half 8.
3. **Real data is a floor:** every block is filled to the real density (OSM outlines first, then infill buildings of the area's own type).
4. **New streets and all buildings as meshes** generated in Python (pure Python glb writer, one facade / roof atlas), placed in Studio by a Luau placer; collision as invisible boxes.
5. **Batch 0.5's main roads stay the part roads** (lanes, decks, roundabout, venues and races depend on them); they get medians and real lane counts through the existing road tool. New streets join them with mouths cut into their kerbs.
6. **One whole-city data source:** Geofabrik's Myanmar extract (OSM, 13 Nov 2026) cut to lon 96.095-96.235, lat 16.750-16.890 by `tools/yangon/e0_extract.py` into `build/osm_ygn/` (54,000 buildings, 25,340 road ways). Heights: SRTM 30 m (opentopodata) or Copernicus GLO-30.

## Phases (tick as done; each ends with a save and a log entry in the build-steps note)
### A. Batch 0.5 to "1:1"
- [x] A1 Lane survey: every main road's lanes, divided or not, median, from OSM + satellite / Google Earth checks (table below).
- [x] A2 Main roads v5: real lane counts and medians (d18 -> v5, RoadLines N lanes, `buildMedians`, d7 gores, d9 lanes with lane 3, spawn on the outer lane, chauffeur guard).
- [x] A3 City generator core (`tools/yangon/city/`): projection, heights, OSM loaders, glb writer, atlas.
- [x] A4 The missing streets as mesh roads (about 150 km) + mouths cut into the part roads + collision + terrain beds.
- [x] A5 Buildings as meshes: OSM outlines + infill to real density, Yangon types, roof colours, night windows; part buildings retired.
- [x] A6 Lived-in layer (parked cars, people, stalls still to come): compound walls and gates, power poles and wires, painted kerb trees, signs and awnings, bus stops, parked cars, tea shops, stalls, trishaws, road patches.
- [ ] A7 Lake details (Boat Club pier, island paths), median lamps, venue lot ground.
- [ ] A8 Test (Play, phone size, night, performance), quality-nerd check, side by side with the satellite, save, notes.
### B. Batch 1 (west to the Hlaing River, south to Shwedagon)
- [ ] B1 Box and edge, heights, water (Hlaing River, Kandawgyi if inside), far city moved out.
- [ ] B2 Roads (mesh) + main-road lanes + flyovers, joined to batch 0.5's edge ends.
- [ ] B3 Buildings, landmarks (Shwedagon at true size, Chaukhtatgyi, Lotte, Yangon University ...), green, clutter, lamps.
- [ ] B4 Minimap, fast travel, test, save, notes.
### C. Batch 2 (downtown south to the Yangon River)
- [ ] C1-C4 as batch 1, plus the downtown grid, Sule Pagoda, City Hall, the Strand, Bogyoke Market, the Zoo and Kandawgyi, the river front.
### D. Batch 3 (east to Thaketa)
- [ ] D1-D4 as batch 1, plus Kaba Aye, the industrial zone, Pazundaung Creek bridges.

## Lane survey (A1)
Source: OSM lane tags in the 13 Nov extract (`tools/yangon/city/lane_survey.py` -> `build/plan/lane_survey_osm.json`, 237 roads), checked on the satellite where marked.

| Road | Real lanes each way (OSM) | Divided | Game before | Target |
|---|---|---|---|---|
| Pyay Road | 3 (4 in places) | yes | 2 + 2 | 3 + 3, median |
| Kabar Aye Pagoda Road | 3 (4 on the flyover) | yes | 2 + 2 | 3 + 3, median |
| Insein Road | 3 | yes | 2 + 2 (1 + 1 before 14 Nov) | 3 + 3, median |
| No.1 Industrial Road | 2-3 (satellite: 2, tree median) | yes | 2 + 2 | 2 + 2, median |
| New University Avenue Road | 2 | yes | 2 + 2 | 2 + 2, median |
| U Wisara Road | 2 | yes | not built (batch 1) | 2 + 2, median |
| Parami Road | 2 (3 in places) | no | 2 + 2 | 2 + 2 |
| Inya Road | 2 | no | 2 + 2 | 2 + 2 |
| University Avenue Road | 2 | no (part) | 2 + 2 | 2 + 2 |
| Kyuntaw Road | 2 | part | street | big street 2 + 2 (mesh) |
| Saya San Road, Hanthawaddy Road, Kanbe Road, Yankin Road | 2 | no | 2 + 2 | 2 + 2 |
| Baho Road | 2 (one-way pairs in places) | part | not built | 2 + 2 (mesh) |
| Residential streets | 1 (about 6-8 m) | no | 15 of them, half 16 | all 1 + 1 (half 10, mesh), narrow lanes half 8 |
| Batch 1-3 roads (Strand 3, Maha Bandula 4, Sule Pagoda 3, Waizayandar 3, Kyimyindine Kannar 4, Bogyoke 2, Anawrahta, Shwe Gone Dine 2 ...) | see the json | | | checked on the satellite when each batch is built |

**Clearance (owner, 14 Nov: "the overhead bridges are too low"):** measured 9.5-9.8 studs under the two flyover decks; target at least 17 studs under the lowest girder (a real flyover clears 5.5-6 m; the cars are 3 studs a metre).
**Fusan Basketball Court (owner, 14 Nov):** in OSM as a building on Kabar Aye Pagoda Road (16.8248 N, 96.1545 E; world 32478, -844); on the satellite a big grey metal-roofed hall. It is now a named hall with a grey gable roof in the plots; every named place gets its real kind.

## Progress log
- **14 Nov, A1 done:** lane survey (table above).
- **14 Nov, A2 in Studio (not saved yet):** main roads v5 (`tools/yangon/d23_lanes_v5.py` -> `imports/refs/map/ygn_roads_v5.json`): real lanes each way, raised medians on divided roads (10,944 parts), both flyovers raised (clearance 17.8 / 18.5 / 19.5 studs; the Kabar Aye ramp lengthened to land at loop sample 866), traffic lanes with lane 3 (`src/shared/YangonLanes.lua` + `YangonLanes2.lua`, 110 lanes). Rebuilt in Studio. **Found after the rebuild:** most of the Yangon Loop's pavements and kerbs were not rebuilt (being fixed).
- **14 Nov, A3-A5 in Studio (not saved yet):**
  - City generator `tools/yangon/city/` (geo, network, plots, streets, bprobe, street_glb, glb, atlas, shells, d24_bmesh, details, landmarks.json; Studio tools `YangonProbe2`, `YangonBuildingMeshes`, `YangonStreetCollide`, `YangonDetails`).
  - Batch 0.5 buildings: 19,098 mesh buildings at real density (OSM outlines + infill; built-up land 13.7% -> 36.6%), 1,877 MeshParts in 626 cells, 1.9 M triangles over the whole area (only the nearby cells stream in), 19,537 invisible collision boxes. The 3,246 old part buildings are in `ServerStorage.YangonBuildings_realparts`; the 3 landmark models stay.
  - The 1,263 missing streets (about 130 km real) as 1,192 meshes + 43,812 collision boxes, terrain cleared under them.
  - Green re-run for the new plots and streets (4,548 city trees, lake walkways lifted over the grass), lamps re-run on v5.
  - Detail layer generated and tested offline (6,596 items, ~23,700 parts: pitches and courts with markings, pools, bus stops, signals, gates, compound walls, power poles + wires, tea-shop stools, trishaws, shop signs, footbridges at 18 studs clearance); to place after the pavement fix.
  - Night windows for the mesh buildings: `WorldFx.setFacadeNight` (tags FacadeNight / FacadeGlow).
  - Minimap redrawn with every street and the real outlines (27 new tiles in `tools/yangon/ygn_minimap_ids.json`).
- **Asset ids** (the building / street mesh packs): `build/ygn_bmesh/b05/assets.json`, `build/city/streets_05_assets.json` (on the PC).
