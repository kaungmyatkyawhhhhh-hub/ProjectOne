---
tags: [city-legends, yangon, scale, plan, blueprint]
created: 2026-11-16
---
# Yangon rescale plan: everything at player scale (3 studs per metre)

> Owner (16 Nov 2026): "the scaling measurements must be 1:1 accurate too", chose **Everything at player scale**. This is the blueprint for the rebuild and for any future real-world map: one scale (3 studs per metre) for map, buildings, cars and players.
> Made from 5 read-only code surveys (roads and lanes, projection and terrain, buildings and street detail, landmarks / venues / gameplay, performance budget) plus a planning pass that checked them against the files. The full survey data, with every constant and line number, is in `Games/CityLegends/build/rescale/surveys_2026-11-16.json`.
> Method for future games: [[Brain/Methods/Real-world look match]]. Status: plan only, owner questions in section 6.


Repo root: `D:/ObsidianOne/Claude+Obsidian/Games/CityLegends`. All paths below are relative to it unless they start with the vault.

**I checked these in the files myself:**
- `geo.py:14` SPM 1.6, `:17` OX 30000, `:20` BOX_05.
- `ground.py:33` VS 1.6.
- `CarBuilder.lua:68` STUDS_PER_METRE 3.0.
- `Config.lua:9` STUDS_TO_MPH 0.783, with the comment "1 stud ~= 0.35 m".
- `Config.lua:25` LaneWidth 16.
- `roadnet.py:46` and `d23_lanes_v5.py:53` LANE_W {2:16, 3:13}.
- `d18_widen.py:21` HALF 32.
- `shells.py:44,46` GF/FH 12/9 and BAY 12.
- `mc3d.py:31` and `sedona3d.py:32` FLOOR 9.
- `d24_bmesh.py:45` CELL 256.
- `details.py:87,376` PART_BUDGET is scaled by stud area.
- `YangonRoads.luau:32` M.SPM 1.6.
- `default.project.json:42` streaming radius 640.
- The "X > 25000" tests are in TravelSpots:101, DayCycle:137, Chauffeur:261, EntranceRamp:97, Houses:448, Minimap:489 and Towers:975.
- CollisionFidelity Box is set only in `YangonLandmarks.luau:119`. YangonBuildingMeshes and YangonRoadMeshes never set it.
- `d11_sites.py:19` LOT 216, OFF 153.
- `Hotel.lua:85` CROWN_Y 435.
- The vault master plan line 30 still says "Scale stays 1.6 studs a metre".

---

## 1. The scale contract

One number for everything: **3.0 studs per metre**. That covers the plan (X/Z), the heights (terrain VS), buildings, props, cars and players. Every tool reads it from `tools/yangon/city/geo.py` (SPM and a new VS). No file may keep its own 1.6.

**Roads**

| Item | Real | Studs |
|---|---|---|
| Main-road lane | 3.5 m | 10.5 |
| Street lane | 3.0-3.3 m | 9-10 |
| Single one-way lane | 3.5-4 m | 10.5-12 |
| Undivided 2+2 carriageway, half | 7 m | 21 (was 32) |
| Divided 2+2, half (with median) | 8 m | 24 (was 35) |
| Divided 3+3, half (Kabar Aye Pagoda Rd) | 11.5 m | 34 (was 42) |
| Median, full width (kerbs included) | 2 m | 6 (MED 3 half: keep) |
| Kerb width / kerb up | 0.3 m / 0.15 m | 0.9 / 0.5 (keep) |
| Pavement, main road | 2.5-3.3 m | 8-10 (WALK 10 is fine) |
| Pavement, street / lane | 1.3-1.7 m | 4-5 |
| Lane line width | 0.15 m | 0.45 |
| Dashes | 3 m on, 6 m off | 9 on, 18 off |
| Junction kerb radius | 6-10 m | 18-30 (RC 8 is too tight) |
| Flyover clearance | 5.7 m | 17 (keep) |
| Bridge clearance over water | 6 m | 18 (was 10) |

**Buildings (floor to floor)**

| Type | Ground floor | Upper floors |
|---|---|---|
| Shophouse | 4.0-4.5 m = 12-13.5 | 3.0-3.2 m = 9-9.6 |
| Walk-up / house / villa | 3.0-3.3 m = 9-10 | 3.0 m = 9 |
| Condo / hotel | 4.5 m lobby = 13.5 | 3.2 m = 9.6 |
| Office tower | 4.5-5 m = 13.5-15 | 3.8 m = 11.4 |
| Mall podium (Myanmar Plaza) | 5.5 m = 16.5 | 5.0 m = 15 |
| Shed / hall | one storey, 5-8 m = 15-24 | - |

- The 12-stud facade bay (4 m) stays.
- Today's ordinary-building floors (12 + 9) already match the walk-up row, so only footprints change for those.

**Walkable interiors**
- Player: about 5-5.5 studs (1.7-1.8 m). That is correct now.
- Doors: 2.1 m = 6.3 studs. Shop doors and fronts 2.7-3 m = 8-9.
- Clear ceiling height: homes 2.7 m = 8. Offices 2.8 m = 8.4. Mall 4 m = 12.
- Stairs: riser 0.17 m = 0.5, tread 0.28 m = 0.85. Use ramps and escalators where possible.
- Mall corridors and galleries: 4-6 m = 12-18.

**Props**
- Lamp pole 8.7 m = 26: keep.
- Power pole 8.5 m = 25.4: keep.
- Signal pole 22.5: keep.
- Bus shelter roof 2.6 m = 7.75: keep.
- Bench seat 0.45 m = 1.35 (now 1.7).
- Balcony cage 1.2-1.5 m = 4 (now 2.2).
- Awning 1.5-2 m = 5-6 (now 3.2).
- Eaves 0.6-0.9 m = 2-2.7 (now 1.2).
- Trishaw 2 m long = 6 (now 3.4).
- Rain tree canopy 15-25 m = 45-75 (now 24-46).
- Cars stay as they are: 12-15.9 long, 6 wide (4-5.3 m).

**Spacings along roads** (eases, gores, splits, pier spacing, seam tolerances, tree and pole spacing) are written in metres and multiplied by SPM. They grow 1.875x in studs.

---

## 2. What changes in each subsystem

**Projection and constants (do these first)**
- `tools/yangon/city/geo.py`:
  - SPM = 3.0.
  - Add VS = 3.0.
  - Work out BOX_05 from lon/lat.
  - New origin (owner question 2).
- Private copies of 1.6 or 30000 must import geo instead:
  - `d5_design.py:9`, `d6_export.py:7`, `d7_flyovers.py:29`
  - `d10_plots.py:23`, `d19_buildings.py:24`, `d20_green.py:26`
  - `d23_lanes_v5.py:108` and the literal at `:412`
  - `city/pilot_plots.py`
  - `city/ground.py:33`
  - `city/heights.py:255-257`
  - `city/landmarks.py:1205-1219`
  - `city/details.py:528-621` (court sizes)
  - `roadnet.py:879` and `network.py:286,291` (/1.6)
  - `YangonRoads.luau:32`, `YangonFar.luau:19-24`
  - `YangonTerrain.luau:12-17`
  - Landmark frames: `landmark_glb3d.py:23`, `landmark_mc_glb.py:22`, `landmark_mc_fit.py:24`, `mall_life.py:22`, and the literals in `LandmarkPlace3D.luau`.
- When done, grep for `1.6`, `30000`, `32600` and `-1350`.

**Roads (one mesh pipeline for all of Yangon)**
- `city/roadnet.py`:
  - LANE_W {1:10.5, 2:10.5, 3:10}.
  - Walks 8-10 / 4-5.
  - PAIR_MAX about 72. TAPER and UNPAIR ×1.875.
  - Re-place the Sule ROUND_FIT.
  - push_beside should then do nearly nothing.
- `city/network.py`: big roads half 21 / 33. Streets 10 and lanes 8 stay.
- `city/roadmesh.py`:
  - GRID about 30, PIER about 75, RC 18-30.
  - Dashes 9/18.
  - Kerb red/white as a texture, not 3.2-stud geometry.
  - Cells about 1024 studs.
- `city/roads.py`, `city/streets.py`: BOX_LEN about 75. Seam and ease distances ×1.875.
- `city/heights.py`: WATER_CLEAR 18. CLEAR 17 stays.
- Batch 0.5 main roads: retire the part-road chain (`d6`/`d7`/`d8`/`d18`/`d23` -> `YangonRoads.luau` + `tools/riviera/Roads.luau`/`RoadLines.luau`) and build them through roadnet/roadmesh. The roundabout and the two flyovers (decks, side lanes, gores) are ported into roadmesh with widths taken from real sizes. The fixed sample indices in d7 (2686, 2985, 572, 680, 789) are thrown away.
- Monaco's `tools/riviera/Roads.luau`/`RoadLines.luau` stay unchanged.

**Lanes**
- `d9_lanes.py` / `city/roadlanes.py`: regenerate `src/shared/YangonLanes*.lua`.
  - Point spacing about 45.
  - Lane offsets come from the real lane width (not 8/24).
  - Keep the `first` chain after RivieraLanes.
  - Drop the untracked `YangonLanesB2_*` files.
- `Config.lua`: add a per-map lane width for Yangon (about 10.5). Keep the global LaneWidth 16 for the old city and Monaco.
- Chauffeur and route code read the per-map width: `ChauffeurClient.lua:821,958`, `server/Chauffeur.lua:141`, `ChauffeurRoute.lua:122,186`.
- `WestLayout.kerbFor` uses the real lane width, or snaps to the outer lane.

**Terrain**
- `city/terrain.py`:
  - Write every length constant in metres × SPM.
  - LANDMARK_GROUND from lon/lat and DEM × VS.
  - Batch 0.5 gets its own run. It is no longer excluded.
- `YangonTerrain2.luau`:
  - YTOP about 380.
  - Probe from about 1200.
  - A thin skin (YB = local ground - 12 to 16).
- Retire `YangonTerrain.luau` and the d4/d6 ground field. One SRTM field covers everything, so drop the seam blend.
- `dem_fetch.py` and `dem_ygn.json` are reused as they are.

**Buildings**
- `city/plots.py`:
  - Infill sizes in metres × SPM: shophouse 4-6 m × 12-18 m, walk-up 12-20 m wide.
  - RES about 3.5.
  - Buffers ×1.875.
  - Read the road keep-out from the new real-width roads.
  - Reserve venue, house, hub and landmark lots here.
- New building kit plus a placer, replacing d24's one mesh per cell for ordinary buildings:
  - A few hundred archetypes in 4 m bays × the floor heights above.
  - Wall, roof and night pieces as separate MeshParts, tinted per instance.
  - About ±15% stretch at most.
  - `d24_bmesh.py` stays for landmark cells only.
- `city/shells.py`: real prop sizes for balcony cages, awnings and eaves. Per-type floor heights from section 1.
- `YangonBuildingMeshes.luau` and `YangonRoadMeshes.luau`: set CollisionFidelity Box and CanQuery false on visual meshes. This also saves place size on the current map.
- Retire the part-building path: `d10_plots.py`, `d19_buildings.py`, `YangonBuildings.luau`, `YangonRealBuildings.luau`. Stop `d16_lamps.py` from exec-ing d10.

**Landmarks**
- `city/landmarks.py`:
  - SH = SV = 3 for all of them.
  - Centres from `landmarks.json` via geo.
  - Ground heights probed again.
  - Shwedagon platform Y0 174.
- `landmark_mc_fit.py`, `mc3d.py`, `sedona3d.py`:
  - Real outlines at ×3. The lot clipping should mostly disappear.
  - Mall floors 16.5/15, office 11.4, hotel 9.6, Sedona about 9.6.
  - Fit-out pieces are already player scale: spread them by count.
- `LandmarkPlace3D.luau`: read origin and base from data. Measure the paving plane again.
- `YangonFar.luau`: box and Shwedagon position from geo. SKIRT about 4900.

**Green, lamps, details, street life**
- `city/green.py` / `d20_green.py`:
  - Spacings in metres.
  - Embankment walkway 10-15.
  - The "130 from a main road" rule ×1.875.
  - Bigger rain trees.
- `d16_lamps.py`: spacing 96-120 is already real. Re-project SITES and RING.
- `city/details.py`:
  - PART_BUDGET by m² (not stud²).
  - Pole spacing 90-120, with `YangonDetails.WIRE_MAX` about 130.
  - Patch lane offsets from the real lane width.
  - Repeated props become kit meshes.
- `city/streetlife.py`: new OX/OZ. Sizes stay.

**Venues and gameplay data**
- `d11`/`d13`/`d14`/`d17`: OFF per road (half + walk + 3 + LOT/2), not 153. Read USED from Config. Search the new main roads.
- `d15_world.py` -> `YangonWorld.lua`: lots, races, jobs, chips, hub.
- Config: YangonVenues.Sites, Spawn.YangonNear, Service, the Fuel pumps.
- `WestLayout.lua:234-239` ygn_* places.
- `ChallengeData.lua:101`.
- `Main.client.lua:63-66,344`, `Main.server.lua:1191`.
- `Towers.lua:975` centre.

**Runtime map checks**
- Replace the seven "X > 25000" tests with `Config.activeMap()` or an isYangon(pos) helper. `Config.activeMap` already exists at `Config.lua:117`.

**Minimap**
- `d12_minimap.py` -> `src/client/YangonMapArt.lua`: covers every built district and reads radii from data. SPP about 4.

**Streaming**
- `default.project.json:42`: StreamingTargetRadius about 1024, StreamingMinRadius 128.

**Vault**
- Master plan decisions 1 (scale 1.6) and 5 (0.5 main roads stay part roads) are now overridden. Update the master plan note.
- The patch_ranks length/checksum line in CLAUDE.md goes stale.

---

## 3. Step order (the game stays playable and the place saveable after every step)

**Step 0: changes that work at both scales, shipped on the live map**
1. Swap the "X > 25000" tests for the map check.
2. Add the per-map lane width (Yangon still 16 for now).
3. Set CollisionFidelity Box on the building and road visual meshes.
4. Make every tool import geo (still 1.6). The output must be the same as before.
5. Move the parked folders out of the place into .rbxm files on disk: YangonBatchesParked, YangonBuildings_step8 / _realparts, YangonReplaced_*, YangonScraps, YangonData_v3backup. This needs the owner's OK.
6. Record the baseline: place file size, Edit and Play memory, unique mesh count.
7. Save and play test.

**Step 1: open a build space for the new scale**
- The old and new maps overlap in coordinates. Build the 3-studs map in a copy of the place (a dev place), or at a frame that does not overlap (owner question 1).
- The live game keeps the 1.6 map until the new pilot district plays better.

**Step 2: kit pilot (no map yet)**
- Build the first kit archetypes: shophouse row, walk-up, house, villa, condo.
- Put them at real scale beside a car and a player, compared with the Hledan reference photos.
- The owner signs off on the look before any district is filled.

**Step 3: pilot district, Myanmar Plaza / Kabar Aye Pagoda Road**
- Area: about lon 96.133-96.159, lat 16.810-16.834 (about 2.7 × 2.7 km real, about 8,100 × 8,100 studs). It holds Hanthawaddy roundabout, Kabar Aye Pagoda Road and its flyover, Myanmar Plaza, Sedona, Fusan court, Optima (the spawn) and today's venue cluster. That makes it playable alone.
- Inside the district, in order:
  1. geo SPM/VS 3.
  2. Ground field.
  3. Roads with real lanes (roadnet -> heights -> roadmesh -> upload -> place + collision).
  4. Terrain.
  5. Lanes plus graph_test and world_test.
  6. Lots and venues reserved (site tools, d15 probe and build).
  7. Plots -> bprobe -> kit buildings.
  8. Myanmar Centre and Sedona re-fit and rebuild at real floor heights.
  9. Green, lamps, details.
  10. Street life.
  11. Spawn, fast travel, fuel, Service.
  12. Minimap.
  13. Play test: phone size, night, a race, a job, the chauffeur, every venue ramp.
- Save, then measure size, memory and mesh count.
- Map-edge barriers close the district.

**Step 4: switch the live game**
- When the pilot district passes the budget gates, it replaces the old 1.6 map in the live place.
- The old map is saved to .rbxm on disk first.

**Step 5: the rest of batch 0.5, one sub-district at a time**
- Order: Inya Lake ring and Pyay Road flyover, then University Avenue / Hledan, then Bahan / Mayangon.
- Each one goes through the full chain above, then save, measure, Play.

**Step 6: batch 1 (west to the Hlaing, Shwedagon at true size), then batch 2 (downtown, the densest), then batch 3 (east).**
- Batch 3 may stay at main roads plus far LOD if the budget runs out.

**Step 7: whole-city far LOD** (one Persistent low mesh per km²) and a full minimap.

Rules for every step:
- Delete data modules right after use.
- Save after each district.
- Never two scales in one Workspace.

---

## 4. Budget rules

- **Unique mesh assets loaded:** at most about 3,000 for the whole map. Batch 0.5's 3,070 loaded cleanly. 15,537 caused HTTP 429/503 and missing pieces.
  - Ordinary buildings come only from the kit.
  - Road and street cells about 1 km, packed to MAX_TRIS.
- **No new part roads.** All Yangon roads are meshes with invisible collision boxes. Batch 0.5's 185,800 road parts would become about 350k at the new scale.
- **Every count is set per real km or km², never per stud.** That covers details, trees, lamps, poles, lane points and collision boxes. If it is not converted, it grows 3.5× (area) or 1.875× (length).
- **Studio Play memory:** 14 GB at most (15.3 GB was hit before).
- **Place file size:** stay well under the size that failed on version 842. Measure that number first. Terrain is the biggest unknown: use a thin skin, and flat water beyond river banks.
- **Visual meshes:** CollisionFidelity Box, CanQuery false.
- **Triangles:** road triangles per real km stay at today's figure or fewer. Persistent far LOD stays under 1.5 M triangles.
- **Streaming:** about 1024 studs target radius (about 340 m real). Test on a phone-class client every district.
- **Image uploads:** minimap at about SPP 4 (100-200 tiles for the whole city, not 600).

---

## 5. Gameplay retunes

- **Races:** routes get about 1.9× longer. Optima Run goes from about 4,800 to about 9,000 studs. Medal times follow length by themselves (`ActivityData.lua`).
  - Checkpoint step 250-300 (now 180).
  - Owner picks: keep the routes and raise RaceRewards, or cut shorter routes. New race ids reset saved best times.
- **Jobs:**
  - Pay is per stud, so cash per minute stays about the same.
  - JobMinDistance 900 -> about 1,700.
  - Duel distances 1,100-2,200 -> about 2,000-4,000.
  - Chips spaced about 550, with more chips for the bigger area.
  - Check with the impatient-kid sim.
- **Traffic and police:** radii are in player studs and stay (CarCount, RecycleDistance, police zones). Narrower real lanes make weaving through traffic tighter: test it in Play. Speed cameras stay Monaco-only unless the owner asks.
- **Speeds:** STUDS_TO_MPH 0.783 means 2.857 studs/m. At 3.0 the speedometer reads 5% high. A real 100 km/h is about 83 studs/s.
- **Venues:**
  - Buildings and lots (216, 304, 80) are already player scale. They only get new sites.
  - Venues 1.9× further apart in studs keep their real distances.
  - Add more Yangon fuel stations: the map is 3.5× the area and the tank range is the same.
  - Hotel suites from 435 studs (145 m) and The Crown at 460 (153 m) would tower over real Yangon (about 100-110 m).
- **Chauffeur:** per-map lane width (split and pull-over offsets).
- **Minimap zoom:** ZoomNear 0.32 shows about 107 m. About 0.18 keeps today's real view.

---

## 6. Risks and owner questions

**Risks**
- One forgotten 1.6 or 30000 copy puts that layer at half size. Grep after step 0 and step 3.
- Kit buildings snap real OSM outlines to rectangles. Odd shapes lose some accuracy. Landmarks keep exact outlines.
- Real lanes (10.5) will feel narrow next to the 16 the owner asked for on 22 Oct ("the road is too small").
- Terrain and place size: 3.5× the area. Measure every district.
- Roads, buildings, terrain, lanes, collision and every uploaded mesh must be regenerated. Scaling them is not valid. Only point data (sites, spawn, checkpoints) may be scaled as a first guess and then snapped.
- Ceilings at 8 studs may clip the third-person camera indoors. Test in the Myanmar Plaza interior.

**Questions (real decisions only)**
1. Build the new scale in a copy of the place and switch over after the pilot district (my recommendation), or build it in the live place at a non-overlapping offset?
2. Origin: recentre Yangon near 0 (smallest coordinates; fine if Monaco never comes back into this place), or move OX to about 40,300 so all of Yangon stays east of x 25,000?
3. Lanes at a true 3.5 m (10.5 studs), or a little wider (about 12) so weaving through traffic stays fun?
4. Batch 0.5's main roads, roundabout and flyovers move to the mesh road pipeline (this reverses master-plan decision 5)?
5. Races: keep the real routes (longer, bigger rewards) or cut shorter ones? Reset best times?
6. Hotel and The Crown: cut to Yangon's real skyline (about 110 m), or keep them as fantasy landmarks?
7. Speedometer: keep STUDS_TO_MPH 0.783 (5% high at 3 studs/m), or set it to 0.7457 and re-tune every mph setting?
8. May the parked and backup folders go to .rbxm files on disk and leave the place before the rebuild?