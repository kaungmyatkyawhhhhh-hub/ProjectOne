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

## Round 2 (26 Nov, owner: fix the 24 left, "some buildings are touching the road", "some grass is overlapping the building floors")
Saved v2147, v2156, v2158 (store back on CityLegends_v1, checked on the Server). Not published. Log:
`build/city_1to1/overlapfix_26nov/fix_log_round2.txt`; everything removed is in `ServerStorage.OverlapFixBackup`
(`Shells`, `PrepareTaken`, `ParkTrees`, `Parts2`, `Night`, tile copies).

### Check 1: placed things overlapping (the 24 left)
**Before 24 thing pairs -> after 0** (the last checker run found 1, a tree crown into a 3-stud wall piece; that piece
was dropped after).
- **5 Shwedagon edge buildings deleted** (their walls / roofs ran into the landmark's hill trees and terrace), 34 kit
  records, and night cells 18x20 / 18x21 re-made without their windows (`tools/yangon/city/night_pages.py`).
- **Edges under 2 studs trimmed:** 3 shells cut back 1.0-1.7 studs (pagoda w289328798, The Central, the P1 car park);
  Sedona's invisible ground collision tiles cut 1.2 off the neighbour building (one 9 x 5 tile under the building edge
  deleted); The Central car park asphalt cut 1.2-1.3; New Day's forecourt strip cut 1.6 off the building to the north;
  an Optima-neighbours park tree moved 2.5 studs off a roof; the Fountain Garden walk now stops at the view-point steps.
- **Lots moved** (`LotFinder`, only spots with no building on them, then `YangonSites.prepare`; every shell / far tree
  it took is copied in the backup):

| Lot | Old spot (x, z) | New spot (x, z), facing | Why |
|---|---|---|---|
| house `y1_mid_9` | 29434.5, 25999.2 | 29174.1, 25500.9, (-0.508, 0.861) | stood on a real OSM car park |
| house `y1_mid_2` | 29539.2, 26808.4 | 29670.6, 26772.7, (0.977, -0.215) | against a building wall |
| house `y1_mid_12` | 29176.6, 26823.7 | 28705.6, 27915.7, (-0.075, 0.997) | a road ran 20 studs into it |
| house `y1_low_1` | 28628.4, 28058.6 | 28790.2, 28071.5, (0.075, -0.997) | 8 road boxes in it |
| hotel | 27227, 30361 | 25391.2, 32424.9, (1, 0) | the real Chinese temple stood 100 studs deep in its lot |

  - **The hotel is now 2.7 km west of the Novotel pin.** It needs a lot square to the world axes, 216 wide, and there
    is none free near the pin (checked out to 3 km: the nearest with no buildings is this one). Its sign still reads
    NOVOTEL YANGON MAX. If the owner wants it back by the pin, the hotel must get smaller or the temple model must move.
  - **Customs and dealership did not move.** They stand at the real Optima Werkz / RIDER AUTO spots, and the nearest
    free lots are 1.4 km away. The Thanlwin Road trees stood on the pavement strip along their pad edges, so the pads
    were cut back 1.4-6.3 studs, 10 trees / signs moved 3.5-11 studs, and **12 trees whose roots stood in the pads with
    the road right behind them were deleted** (copies in `ParkTrees`).
  - Code: `Config.YangonVenues.Sites.hotel`, `src/shared/YangonWorld.lua` (4 house lots), `world_1to1.py` `MOVED`
    (synced into Studio).
- 52 + 2 tree / wall records dropped where they stood in a new lot.

### Check 2: buildings, walls and lots touching the road
Rule checked: no building shell or lot pad inside a carriageway / deck / median / wall box (R, D, M, W) or within 1 stud
of one. Pavement boxes are allowed (buildings stand on the pavement side of the kerb).
- **Lots: before 11 lots (26 box pairs) -> after 0.** 8 pads cut back off the road (+1 stud gap): customs 1.5,
  dealership 9.6, gems 18.7, tower_skyline 12.5, low_12 7.0, low_3 3.5, low_6 0.7, low_9 0.6; 2 house lots moved (above).
- **Buildings: 1,448 shell parts, NOT fixed.** P1 489, P2 476, P3 318 (1,283 together), P4 32, P6 31, P7 24, P11 20,
  P8 19, P9 16, P12 12, P5 9, P10 2. 563 of them go more than 2 studs into the road box; 398 only sit inside the 1-stud gap.
  List: `build/city_1to1/overlapfix_26nov/buildings_touching_roads.txt`.
  - **Cause:** P1-P3's buildings were made on 16 Nov against the road net before J37. The roads were rebuilt after,
    but these three districts' buildings never were. P4-P12 were re-run against the J37 net and have few left.
  - **Why not fixed now:** the visible building is the client kit detail plus the night-window mesh, not the shell.
    Trimming only shells would leave the facades in the road. The right fix is the same district re-run P4-P12 got
    (`district_files.sh P1 --no-roads buildings`, then the DistrictPlace swap), for P1, P2 and P3. It regenerates every
    building there, so it needs its own batch and lock time. Then re-run this check, and re-apply today's P1/P2
    building deletions (the places plan already drops New Day's canopy buildings).

### Check 3: grass on floors
Floors: lot pads, venue / car-care floors and plates, landmark and park floors, plazas, walks, steps and every
places-data slab (797). Grass: terrain Grass / LeafyGrass / Ground / Mud, and grass parts (lawns, beds).
- **Before: terrain grass at or over the floor on 133 floors, 43 grass parts level with a floor (176) -> after 0 / 0.**
- Terrain: cleared over each floor's footprint from 4 studs under its top (a 4-stud voxel under a floor still drew
  its surface over it: Air from 0.3 under did nothing), 8 under where it still showed, and the last few points written
  as empty voxels. Grass parts: cut off the floor, or lowered to 0.1 under its top when a cut would take over 40%.

### Checked in Play
CityLegends_test, then back to CityLegends_v1 and read on the Server. The hotel builds whole on its new lot, the house lot
y1_mid_9 shows its pad and FOR SALE sign beside the road. Not looked at: each trimmed lot pad, the grass fixes by eye,
night windows at night.

![[2026-11-26 Overlaps 2 - hotel on its new free lot (Play) - after.jpg]]
![[2026-11-26 Overlaps 2 - house lot y1_mid_9 on its new spot (Play) - after.jpg]]

## Round 3 (26 Nov, coordinator: hotel back on the real site, P1-P3 buildings against today's roads, floor edges)

### Hotel back on the real Novotel site, renamed (v2162)
- The 2.7 km move is undone. The hotel stands on the real Novotel Yangon Max site on Pyay Road (OSM way 471327865).
  The OSM outline is turned about 16 degrees, and the largest square-to-the-world box inside it (264 x 156) is too
  small for the 200-wide podium. So the hotel now turns with its road: `Hotel.lua` `facadeTurned` builds square and then
  turns with the lot frame. It sits on a 200 lot facing the south service road (`Config.YangonVenues.Sites.hotel`
  x 27333.3, z 30048.6, fx -0.264, fz -0.965).
- The temple next door was checked against its OSM outline and it matches. The temple model is right; the old hotel lot
  was wrong.
- New name (made up): **PYAY ROYAL HOTEL** / Pyay Royal Hotel (Config.Hotel.Name, Hotel.lua letters, WestLayout label,
  Strings `rew.suiteBuy` in English and Burmese, RewardsClient). The Burmese line keeps the name in Latin letters, with no
  kinzi.
- **Real brand names still on signs** (reported, not changed): JUNCTION CITY, THE CENTRAL, Mathnasium, PV AUTO CAR SALES,
  RIDER AUTO / PREMIUM EXCLUSIVE - YANGON (DealerBody), GeoHomes (HouseBodies), SWAN MOBILE 5G, yangonation., AUTOCULT.
  Allowed by the owner: CB BANK, MELIA, SEDONA, MYANMAR PLAZA. Letters made as 3D meshes were not searched.

### P1, P2, P3 buildings re-made against today's roads (v2173, v2174, v2176)
- `buildings_1to1.py P1 / P2 / P3` was run against today's road nets (P1 5,242 buildings, P2 6,286, P3 11,247). This is
  the same step P4-P12 got. Then `BUILDINGS_ONLY=1 place_pack.py` made the packs (new switch: shells, roofs and kit
  data only; terrain, green and pagodas stay as they are).
- The detail meshes (`Data_P1..3`), night windows and collision shells were swapped together. The new tool is
  `tools/yangon/RebuildSwap.luau`:
  - It finds the old shells and roofs from the old `Shell_*.txt` records (asset 92302468599227), first exact, then
    within 10 studs. 1,600 P1 parts in Studio came from an older run than the saved records.
  - Leftovers more than 40 studs inside the district box are swept up too (P1 175, P2 29).
  - Everything goes to `ServerStorage.OverlapFixBackup.RebuildOld_P1..3`.
  - New shells inside a KeepOut box (venue / house lots and the shells deleted there before) are left out:
    P1 164, P2 81, P3 4.
- Night windows: `tools/yangon/city/night_keepout.py` cuts the panes inside the KeepOut boxes out of the new night
  cells before upload. That cut 2,710 panes in P1, 1,183 in P2 and 153 in P3. Pack ids:
  `build/city_1to1/overlapfix_26nov/rebuild_ids_26nov.txt`.
- No new kit pieces were needed: every P1-P3 piece id was already in `YgnKit.Templates`.
- Not re-run: green (trees) and street props. Their data is unchanged, and the overlap check covers them.

### Buildings touching roads
- Rule as in round 2: no shell or roof inside an R / D / M / W road box or within 1 stud of one.
- **Before 1,448, after the re-run 184, after trimming 0** (141,367 road boxes, 197,171 shell and roof parts, map-wide).
  - 174 parts were cut back from the road side (mostly under 1 stud, the largest 6.9).
  - 10 thin slivers were removed.
  - Originals are in `OverlapFixBackup.RoadTrim26`. List: `build/city_1to1/overlapfix_26nov/road_trim_round3.txt`.

### Overlap check after the re-run
- **0 -> 631 real pairs -> 0** (v2184; 4,098 box pairs checked, 0 real). The new P1-P3 buildings had come back on lots,
  landmarks and parks.
  - 12 buildings were deleted. Their night panes were cut from 7 cells (asset 75359284329355).
  - 225 compound-wall records and 6 street props by Sedona were dropped.
  - **2,214 kit records whose parts all stood inside a KeepOut box were dropped.** These were the facades of buildings
    whose shell `placeNew` had left out; they would have stayed as loose panels.
  - 18 more records were dropped near the Strand Hotel, The Central and the Thanlwin Road / Optima parks.
- Grass check: not re-run. The floors and terrain did not change in round 3.

### Hollow ground under floors
- Measured in Play (Server, terrain raycasts every 4 studs along each edge of the 55 lot / venue pads). 8 pads had
  open air under an edge, 0.4 to 2.0 studs deep: gems 2.0, rewards 1.0, lot_y1_mid_1 1.0, high_1 0.9, high_10 0.8,
  mid_6 0.7, hotel 0.5, low_10 0.4. Cause: round 2 cleared terrain 4 studs under each floor top (the grass fix), and
  the ground dips under some edges.
- **Fix, with no flicker:** each of those pads was made 2-3 studs deeper. The top stays where it was, so the side face
  now reaches into the ground and no faces share a plane. Attributes `SkirtAdded` / `SkirtOldSizeY` record the change.
- Checked in Play at the gems corner and along the Rewards edge. Both sit on the ground with no gap.

### Hotel bug found in Play, fixed
- The Play test showed `Hotel:1061: attempt to perform arithmetic (add) on nil`: the turn change had removed the
  `worldBox` values the name band used. Because of that, the top name band and everything built after it were missing.
  The band is now built in the hotel's own frame. In Play the hotel builds whole (4,783 parts) with no errors.

### Checked in Play
CityLegends_test -> back to CityLegends_v1 (read on the Server: v1, the hotel built) -> saved.
- 0 building parts touching a road after the road agent's last swaps (141,367 road boxes).
- Not looked at: kit facades on the client near every trimmed shell (they follow the shells' old faces, at most 6.9
  studs on one building, most under 1), and night windows at night.

![[2026-11-26 Overlaps 3 - Pyay Royal Hotel on the real Novotel site (Play) - after.jpg]]
![[2026-11-26 Overlaps 3 - Pyay Royal Hotel front (Play) - after.jpg]]
![[2026-11-26 Overlaps 3 - Rewards pad edge on the ground (Play) - after.jpg]]
![[2026-11-26 Overlaps 3 - gems pad corner (Play) - after.jpg]]

### Hotel name reverted (26 Nov, coordinator)
- The rename to "Pyay Royal Hotel" was a mistake and is undone. The owner's rule of 22 Nov in
  `Games/CityLegends/CLAUDE.md` says venues carry the real name of the place they stand by (Rider Auto, Optima Werkz,
  Novotel Yangon Max, Lotte, Kan Thar Yar, CB Bank, Myanmar Gems Museum). That rule beats the fictional-names rule,
  which still holds for cars.
- Back to **NOVOTEL YANGON MAX** in: the sign, the name band, `Config.Hotel.Name`, the WestLayout label, Strings
  `rew.suiteBuy` (English and Burmese) and RewardsClient. Repo and Studio both.
- Kept: the real-site position and the name-band crash fix.
- The other real sign names listed above stay as they are, under the same rule.
- Checked after the power cut: Studio had kept the revert. Play on CityLegends_test: the hotel built whole (4,783 parts,
  NOVOTEL YANGON MAX, no errors). Back to CityLegends_v1, read on the Server, saved **v2200**.
![[2026-11-26 Overlaps 3 - Novotel Yangon Max front, name reverted (Play) - after.jpg]]
