---
date: 2026-11-26
tags: [city-legends, map, overlaps, fuel, places, buildings, bugs]
---
# Overlaps: gas station and building merged (26 Nov 2026)

Owner: "the gas station and a building is merged in together" (Kabar Aye Pagoda Road by Myanmar Plaza). Owner rule: no
overlapping parts, no z-fighting, anywhere.

## What it was
There are two real (OSM) fuel stations on Kabar Aye Pagoda Road near Myanmar Plaza, both built from the places layer
(`places_1to1.py`, data `Data_P1P` / `Data_P2P`):

| Station (OSM) | Where | What was wrong |
|---|---|---|
| New Day (`n2578264080`, P2) | north of Myanmar Plaza, (34887, 24640) | a 3-storey "building" stood in the middle of the forecourt and the canopy ran through it (up to 23 studs deep). The building was 4 Microsoft footprints (`m96155337_16836218_0..3`) that are really the station's own canopy roof seen from the satellite. The places plan had marked them "cleared", but they were never removed. |
| Myawady (`n2956795311`, P1, the game's fuel stop `fuel_yangon`) | south of Myanmar Plaza by the flyover, (34607, 29128) | the canopy's end stood 0.5 studs from the shophouse next door and that building's awning ran under the canopy; a tree crown stood in the kiosk. |

## Why the placement check missed it
- P2's buildings in the place are still the run made BEFORE the places plan (`buildings_P2_before_places`). The plan
  said "clear these 4 buildings", but only P1's buildings were re-run and swapped; P2's never were.
- `places_1to1.py build` checks "nothing in a building" against `buildings_P2/plots.json`, a NEWER run that no longer
  had those 4 buildings, so it reported 0. It never looked at what is really in the place.
- The lot checks we had (`LotFinder`, `VenueLots1to1`) test venue lots only, against road boxes and shells. Nothing
  tested the places layer, the kit detail (walls, awnings, trees) or the landmarks against each other.
- The Myawady lot is a guessed 34 x 26 m rectangle (OSM has only a point). It was cut clear of footprints + 0.6 m, but
  kit walls, awnings and roofs reach about 1 m past a footprint.


## The checker (new): `Games/CityLegends/tools/yangon/OverlapCheck.luau`
- Every placed thing (venue pads in `Sites`, `CarCare`, `Landmarks`, `Pagodas`, `Parks`, `InyaBund`, and every place in
  `Data_<district>P`, built from the data and grouped per place) against every building shell, the kit detail of the
  tiles round it (walls, awnings, roofs, trees `Data_*G`, street props `Data_*S`, with the KeepOut boxes taken out the way
  the streamer does) and every other placed thing.
- Overlap = more than 0.5 studs into each other on every axis. Pass 2: a pair with a MeshPart only counts when the mesh's
  own triangles go 0.5 studs into the other box (box only: 10,943 pairs; real: 3,264).
- Things built onto each other on purpose are not counted (`O.JOINED`): Legends Service on its pad, the Melia joined to
  Myanmar Plaza, signs / floodlights / shops on Myanmar Plaza and Sule, the plinth on The Central's plaza.
- Fixer: `tools/yangon/OverlapFix.luau` (edits the data strings record by record, compact tiles expanded first; every
  changed tile and every removed shell kept in `ServerStorage.OverlapFixBackup`). Night panes: `tools/yangon/city/night_cut.py`.

## Counts (thing pairs = one placed thing against one other thing)
| | Part pairs | Thing pairs |
|---|---|---|
| Before | 3,092 | 1,009 |
| After | 139 | 24 |

Before, per district (thing pairs): P1 429, P7 278, P2 126, landmark sites (Myanmar Plaza, Sedona, Shwedagon, YCC, Botataung) 140, P3 31, P11 6, P4 4, P6 1.

## What was done (saved v2128, v2131, v2133, v2135; never published)
- **New Day station:** the 4 canopy "buildings" (and a 5th that ran 3.8 studs into the forecourt) deleted, with their kit records and 58 night panes. Its forecourt was one
  102 x 102 slab that also ran 1-3 studs into the drive roads round it (the "invisible thing on the road" there was this
  slab's collision box): cut into 45 strips clear of the drives (+ their collision).
- **Myawady station (`fuel_yangon`):** canopy, columns, lights, pump islands, pumps and bollards moved 8 studs along the
  road, away from the shophouse (now 8.5 studs clear of its wall, the awning no longer under the canopy); the tree in the
  kiosk removed. `Config.Fuel.Stations` pumps / chargers / arrive and the fuel job post moved with it (synced to Studio).
- **47 buildings deleted** that stood more than 3 studs inside a real landmark or place (list:
  `build/city_1to1/overlapfix_26nov/deleted_buildings.txt`): 34 at Shwedagon (a row of 6 "buildings" up to 70 studs deep
  was the west covered stairway read as buildings), 5 at New Day, Holy Trinity 1, Strand Hotel 1, Immanuel 1, High Court 1,
  4 at the Optima / Thanlwin Road parks. Their kit records went too (515) and their night panes (8 night cell meshes
  re-made without them, old ones in the backup).
- **Trees and street props** standing in a placed thing: 910 records removed. **Compound walls / leftovers** running into
  lots, places and landmarks: 445 records removed. **Car-park pieces inside YCC and Sedona:** 96 removed.
- Full log: `build/city_1to1/overlapfix_26nov/fix_log.txt`.

## Checked
- Play (store CityLegends_test, put back to v1, checked on the Server): New Day with no building in it, Myawady canopy
  clear of the shophouse. Re-run of the checker after: 0 overlaps at either station.

![[2026-11-26 Overlaps - New Day fuel station, building standing in the forecourt (Edit) - before.jpg]]
![[2026-11-26 Overlaps - New Day fuel station, building gone (Play) - after.jpg]]
![[2026-11-26 Overlaps - Myawady fuel station, canopy against the shophouse (Edit) - before.jpg]]
![[2026-11-26 Overlaps - Myawady fuel station, canopy clear of the shophouse (Play) - after.jpg]]
![[2026-11-26 Overlaps - Shwedagon west stairway with a building row on it (Edit) - before.jpg]]

## Left (24 thing pairs, 139 part pairs)
| Where | What | Depth | Needs |
|---|---|---|---|
| P1 | house lot `y1_mid_9` sits on a real OSM place (car park / pitch at 29445, 26022) | 5.8 | move the lot (Playbook: lot + everything on it, `world_1to1.py` MOVED) |
| P1 | Thanlwin Road park trees / sign posts on the customs and dealership pads | 3.2-3.5 | move the two venue lots or the trees (the trees were put back, not deleted) |
| P4 | the Chinese temple (Hanthawaddy) on the hotel venue pad | 4.6 | move the hotel lot (the temple is real) |
| P1 | house lot `y1_mid_2` against a building wall | 3.3 | move the lot |
| P7 | 9 Shwedagon edge buildings (roofs 2-11 studs into the landmark) | 2-11 | delete like the others (needs another night-pane re-make for cells 18x20 / 18x21) |
| P1 / P2 / P3 | building edges 0.9-1.6 studs into Sedona, The Central, The Central car park, a pagoda, two places, New Day's side | <= 1.6 | trim, or accept as touching |
| P6 | Fountain Garden walk into the Shwedagon view point step | 5.0 | trim one of the two hand-made parks |

## Fictional brands
The stations show no brand text (green fascia only). In-game names: "Kabar Aye Fuel" (fuel stop) and "Fuel Station"
(job). The OSM names (New Day, Myawady) are only in the data files, never on screen.

## Not checked
- Runtime venue buildings (bank, dealership, hotel ...) are built by the server in Play; this run checked their pads in
  Edit only. Client-only street extras (`YangonRoadside` poles / billboards) were not in the check.
- Night panes were checked by numbers, not looked at at night.
- Edit screenshots near the stations are unreliable while the Yangon preview plugin is on: it caches the kit data at
  start and showed the deleted building until Studio was restarted. Judge in Play.
