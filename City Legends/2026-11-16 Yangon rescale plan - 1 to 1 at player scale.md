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
## Owner's answers (16 Nov 2026)
1. **Build place:** in the live place, at coordinates that don't overlap the old map; the old map is deleted after the switch.
2. **Lane width:** 12 studs (about 4 m), a little wider than real so weaving through traffic stays fun.
3. **Backups:** the parked and backup folders are saved to .rbxm files on the PC and removed from the place before the rebuild.
4. **Main roads:** the batch 0.5 main roads, the roundabout and both flyovers become meshes like the rest of the city (this overrides master-plan decision 5).
- Still open, asked when their step comes: the races (keep the real routes, or cut them shorter?), the hotel and The Crown heights (real skyline or fantasy?), the speedometer factor. The origin is a technical choice: the new map goes where it doesn't overlap the old one.
- **Backups moved out (16 Nov, version 937):** `D:\RobloxStudioGameFiles\Yangon.rbxm` (the owner's Save to File, 50 MB) holds YangonBatchesParked, YangonDetails_outside05, YangonFar_b1_removed, YangonReplaced_MC, YangonReplaced_SD and YangonBarriers_b1_removed. The first five were removed from ServerStorage (249,000 objects). YangonSiteHidden was not in the file, so it is still in the place. To bring any of them back: Insert from File into ServerStorage.

## Step 0 done (16 Nov 2026, place version 946)
- **Map check by area:** `Config.isYangonAt` / `Config.mapAt` replace the seven "x > 25000" tests. `Config.laneWidth()` gives the per-map lane width (Yangon 16 for now, 12 at the new scale).
- **One scale setting:** `tools/yangon/city/geo.py` holds `SPM`, `VS`, `OX`, `OZ` and `m()`. The city tools and `d20_green.py` read it, and give the same output as before. The old part-road tools are left as they are (they will be retired).
- **Lighter collision:** 14,062 visual meshes (buildings, streets, trees, details, landmarks) now use box collision and are invisible to rays. The camera only sees colliding parts. The placers do the same from now on.
- **Play test on the test save, live save put back:** clean startup, Yangon detected, fast travel and fuel fine, daylight blend fine.
- **Baseline (Edit, after step 0):**

| Measure | Value |
|---|---|
| Studio memory | 6.8 GB |
| Workspace | 297,260 parts, 14,380 meshes (3,098 unique) |
| ServerStorage | 30,616 parts, 6,531 meshes (3,986 unique) |
| Place file size | not readable from here; the save went through |

- **Next: step 1/2.** The new map's build area (no overlap with the old map) and the building kit pilot. Reference photos and measurements are being gathered in `Games/CityLegends/build/landmarks/refs/kit/`.

## Step 3 progress

### Roads and ground of pilot district P1 (16 Nov 2026, files only)
- **What:** the road network and ground of the pilot district, lon 96.133-96.159, lat 16.810-16.834 (Myanmar Plaza, Kabar Aye Pagoda Road and its flyover, Hanthawaddy roundabout, Sedona, Inya Lake's east shore). Nothing went into Studio.
- **How to run:** `YANGON_SCALE=1to1 python roads.py P1 --jobs 6`, then `YANGON_SCALE=1to1 python roads_check_1to1.py P1` (both in `Games/CityLegends/tools/yangon/city`). Outputs go to `Games/CityLegends/build/city_1to1/` (gitignored).
- **Standalone:** P1 is a pilot tag (`geo.PILOT_LL`, `geo.standalone`). It has no batch 0.5 box, no v4/v5 game roads and no seams. The map edge is the district box.
- **Ground:** Copernicus GLO-30 made bare (opening 270 m + blur 45 m, as the terrain research chose). Inya Lake is 13.5 m and Kandawgyi 12.0 m. Land within 30 m of a lake is 1 m above it.
- **Old tags are unchanged:** without the variable every tool gives the same output as before. Checked on batch 3: the same network, heights, a 5 x 5 cell mesh sample and lanes.

| Measure | P1 |
|---|---|
| Roads | 79.3 km (56 km residential) |
| Meshes | 83 (1 km cells, at most 17,000 triangles each) |
| Triangles | 567,262 in the meshes, about 7,300 per real km (batches 1-3: 7,000-8,600) |
| Collision boxes | 8,350, 105 per real km (batches 1-3: 85-108) |
| Traffic lanes | 657 lanes, 762 links, 0 dead ends (2 dropped by the prune, 18 turn round at the district edge) |
| Kabar Aye flyover | 2+2 deck about 18 m wide, 17.5 studs under the girders over New University Avenue Road, 22 studs at most over the ground, ramps 7% |

**Lanes as built (owner rule: 12 studs where they fit, never under 10):**

| Road | Built | Real (road audit) |
|---|---|---|
| Kabar Aye Pagoda Rd | 3+3 at 10 studs, each carriageway on its own OSM line, 1 m median | 3+3, ~19.5 m. Ours is 21 m, because 3 m lanes are under the 10-stud floor. |
| Kabar Aye flyover deck | 2+2 at 12 | 2+2, ~17 m. OSM says 4 a side. |
| Flyover ground lanes | 1 lane of 12 a side | narrow single lanes (junc_06) |
| Pyay Rd | 3+3 at 11.5 | 2 x 11.5 m |
| U Wisara Rd | 2+2 at 11.25, median 8-10 m (the OSM gap) | 2 x ~7.5 m, a tree median |
| Inya Rd | 2+2 at 10.5 (not measured) | OSM lanes=4 |
| Hanthawaddy ring | 3 lanes at 12, island Ø about 50-55 m | 3 lanes ~14 m, island Ø 48 m |

**What changed in the tools:**
- `geo.py`: `ONE_TO_ONE`, `LK` (the old stud lengths kept in metres), `PILOT_LL['P1']`, `standalone()`.
- `roadnet.py`: the 1:1 cross-section, which uses `REAL_XS` / `REAL_XS_SECONDARY` (measured widths), up to 4 lanes a side, and real pavements. Divided roads keep each carriageway on its OSM line with the real median (`e.med`). The pilot build is standalone. At 1:1, `push_beside` only moves real overlaps.
- `ground.py`: the GLO-30 bare field at 1:1, with no blend into batch 0.5.
- `heights.py`: deck 1.5 m deep, 18 studs over water, lengths in metres, no street pins for a pilot. Sags in a deck between the roads it crosses are filled. Before, the Kabar Aye deck dipped from 22 to 13 studs and got solid ramp walls in the middle of the span.
- `roadmesh.py`: work tiles of 512 studs, meshes grouped per 3,072-stud cell, corners 6 m. Lines are 0.45 wide with 9 / 18 dashes and no outer edge line. Median lines and zebras are yellow (kind `LY`), zebras 12 studs long. Red-white kerbs only on trunk and primary roads and the ring. Parapets 1.1 m.
- `roadlanes.py`: spacings in metres, no seam for a pilot.
- `roads.py`: outputs to `build/city_1to1`, mesh cells regrouped, a collision box covers up to 30 m, no batch 0.5 seam.
- New: `roads_check_1to1.py`.

**Not right yet:**
- Kabar Aye is 1.5 m wider than real (the 10-stud floor).
- The ground lanes beside the flyover moved up to 4 m off their OSM lines. OSM draws them closer to the deck than its real width allows.
- Inya Rd, University Ave and New University Ave have no measured width. They use 3.5 m lanes.
- The 6 m corner closing joins the flyover's ground lanes and ramp foot into one asphalt band from above.
- No stop lines, turn arrows, splitters or kerb parking yet (audit items 11-13).
- Next: upload, place and collision in the new frame, then terrain (step 3.4) and graph_test.

### P1 roads and ground in Studio (16 Nov 2026, not saved)
- **Placed:** `Workspace.Yangon1to1.Roads`: `Meshes` (216 meshes in 33 cell Models), `Collide` (8,350 invisible boxes, YangonRoadMeshes.collide). Terrain skin under the whole district: 1,080 tiles, 4.14 M columns, grass, road beds 1 stud under the roads, Inya Lake as real water at 40.5 (13.5 m x 3). The skin is thin: 12 studs of solid under each tile's lowest top (lowest bottom y 16). `Workspace.Yangon` not touched. Nothing saved, no Play.
- **Looks:** carriageway Asphalt + YgnAsphaltWorn, pavement Pavement + YgnPavementSlabs, kerbs Concrete + YgnKerb (own colours), medians / bridge / edge strips Concrete + YgnConcreteBare, lines SmoothPlastic (white, yellow LY 232, 184, 52). Visual meshes CollisionFidelity Box, CanQuery false.
- **Assets:** meshes 118225667657179, 140026349574196, 133845673202805, 115233685609501, 107098753198662, 100043275291480, 102340709396221 (group 33151111). Collision + terrain data: version 78 of 133014134133489 (22 StringValues, checksums matched, deleted after use).
- **Fixed on the way:**
  - The 3,072-stud mesh cells were too big: a MeshPart is at most 2,048 studs on any axis, so Roblox shrank every cell mesh (roads drawn in the wrong place). `roadmesh.MESH_CELL` is 1536 at 1:1 now (216 meshes, still 567,262 triangles); `roads.py` stops on a mesh over 2,048.
  - Medians came out grass green: the mesh's corner colour tints the variant. MG is concrete grey at 1:1 now.
  - `terrain.py` runs for a pilot (`YANGON_SCALE=1to1 python terrain.py P1`, outputs in `build/city_1to1/`); it no longer lowers Inya Lake to the DEM (it had put it at 39.9).
  - CollisionFidelity set on an unparented clone did not stick; YangonRoadMeshes sets it again after parenting.
- **Checks:** road boxes sit 0.5-3 studs over the terrain (1,531 samples), none under it. Junctions (Pyay x U Wisara, Hanthawaddy) show no z-fighting.
- **Screenshot trap:** in Edit the terrain far from Studio's own camera is drawn coarse and covers the roads (whole areas look roadless). Move `workspace.CurrentCamera` to the view, wait ~4 s, then `screen_capture`.
- **Still wrong:**
  - Inya Lake stops at the district's north edge: water and sand end in a wall.
  - Lane lines and the centre line run through junction boxes.
  - Every road stands about 1 stud over the grass with a small skirt showing.
  - The MaterialVariant textures were still loading for some surfaces (asphalt already shows its cracks on U Wisara Rd).
- **Next:** lanes and graph_test (step 3.5), then save and measure.

### P1 ordinary buildings, compound walls and gates (16 Nov 2026, in Studio, not saved)
- **Placed:** `Workspace.Yangon1to1.Buildings`: `Kit` (per-cell Models of kit MeshParts and plain Parts), `Night` (30 lit-window meshes, tag FacadeNight), `Collide` (invisible boxes). `Workspace.Yangon` not touched, no Play. The coordinator saves.
- **How it is made** (all in `Games/CityLegends/tools/yangon/city/`, run with `YANGON_SCALE=1to1`):
  - `buildings_1to1.py P1` reads the real footprints (OSM + Microsoft), cuts them off the road corridors (carriageway + pavement + 0.6 m), drops water, overlaps and the two landmark sites, picks an archetype per building and writes everything to `build/city_1to1/buildings_P1/` and `imports/sync/ygn1to1_p1/`.
  - `kit_panels.py` is the reusable facade kit: a wall is cut into panels of 1/2/3/4/6 bays x the building's full height, stretched at most 15%. Panels are built from kit.py's details (grilled windows set into the wall, cages, blue hoods, shop bays with shutters and goods, signs, AC units, laundry, rain stains). Tower faces are stacked (podium, bands of 8/4/2/1 floors, top), so the kit stays bounded for the whole city.
  - Studio: `tools/yangon/YangonKitPlace.luau` (`templates`, `place`, `cells`), collision with `YangonBuildingMeshes.collide`. Data went in as StringValues (`tools/yangon/pack_strings.py`, version 80 of asset 133014134133489) and was deleted after use.
- **Floors:** ground floor with shops 13 studs, upper floors 10 studs (3.33 m); houses 3.3 m, villas 3.6 m on a plinth, condo podium 4.5 m.
- **Archetypes (5,345 buildings):** house 2,316, walk-up 1,136, villa 663, civic (school / hospital / mass) 468, shed / hall 458, township shophouse 293, condo 11. Real outlines kept; 11 infill houses only (blocks with no real building in home / shop land use).
- **Empty landmark lots:** Myanmar Centre / Meliá (X 34,534-35,222, Z 27,062-28,027) and Sedona (X 34,641-35,321, Z 26,359-27,135). 25 footprints dropped there.
- **Walls and gates:** 114.6 km of compound wall (villa, civic, condo lots all round; houses on the street side only; 9 OSM walls / fences) as 21,915 kit pieces (2.1 m, pillars every 3.5 m, ridge coping, splash band, stains); 757 gates (dark-green or rusty steel, lamp-topped pillars) on the street side of the lots.
- **Materials:** wall parts are named by their wall code (KW1 / KW4 / KW6 / KWG ...) with Plaster + YgnRenderPainted or YgnRenderStained and the midday-calibrated colour; metal / glass / signs `KGR` (YgnSteelPainted, colours in the vertex colours); roofs by sheet: KRF rust, KRG zinc, KRB blue, KRT clay tile; flat roofs KCO (YgnConcreteBare). Box-projected UVs (1 UV = 1 stud).

| Measure | P1 buildings |
|---|---|
| Unique meshes | 767 uploaded (737 kit, reusable for the whole city; 30 night meshes) |
| Parts | 139,675 (95,779 MeshParts, 20,683 plain Parts for party walls and flat roofs, 23,183 collision boxes) |
| Triangles drawn | about 18.4 M if all were on screen (kit instances 18.3 M, night 0.13 M) |
| Collision boxes | 23,183 (7,273 buildings, 15,910 walls) |
| Studio memory | 5.98 GB in Edit after placing (2.7 GB before the load, other agents' work included) |

- **Assets (group 33151111):** kit 94942980174458, 84391865825287, 90931556475492, 106464368645255, 90898122615860, 107430560242416, 86963099978582, 89401963850662, 118735643115906; night 71151089010596.
- **No flicker (owner rule):** `kit_flicker_test.py` checks every one of the 375 kit pieces and a 2,500-instance placed sample (432,000 triangles) for same-facing faces under 0.05 studs apart that overlap: kit 0, placed 1 (an 0.008 square-stud corner of two wall pillars). Fixed on the way: layers in front of a wall 0.06 studs apart (grime, paint, stains, streaks), kit.py's own 0.005-0.012 m offsets (louvres, awning ribs, AC grilles, sign stripes, shutter ribs), sill and drainpipe against stains, cages against their slabs, floor bands that met at corners (now sloped drips that cross on a line), panel boxes that ran past their ends, plain walls as 0.02-stud sheets, roof slabs 0.75 studs inside the walls, overlapping footprints dropped, wall runs stretched to their exact length, coping ridges, no doubled pillars. Grazing close-ups in Studio of a walk-up facade and a compound wall showed no flicker.
- **Screenshots** (Studio, PlayLight 13), in `C:/Users/kaung/.claude/projects/D--ObsidianOne-Claude-Obsidian/8dbf212d-129a-4909-ba7d-ab448f73c052/tool-results/`: aerial `mcp-Roblox_Studio-blob-1794805603735-9t9wm3.jpg`, residential street `mcp-Roblox_Studio-blob-1794805617099-aa8dar.jpg`, Kabar Aye Pagoda Rd (north part) `mcp-Roblox_Studio-blob-1794805649297-o0my0z.jpg`, facade grazing close-up `mcp-Roblox_Studio-blob-1794805662480-8tcaor.jpg`, compound wall close-up `mcp-Roblox_Studio-blob-1794805673796-rl9cer.jpg`.
- **Still wrong:**
  - The ground between buildings is lawn: real Yangon is concrete forecourts, dust and trees (the green, pavement and detail steps).
  - No trees yet, so villas read bare (the villa critique's main point).
  - Drainpipes stand 0.45 m off the wall (kept clear of signs) and there is one per panel, so long walls get several.
  - Hip roofs are the kit roof stretched to the building's rectangle: big eaves on wide villas.
  - 9,984 plain wall strips where a wall's length does not fit whole bays (up to 15% stretch); 116k parts in one district is heavy for the whole city.
  - One night mesh kept Default collision fidelity (no collision, visual only).
  - Kabar Aye Pagoda Rd next to Myanmar Plaza has few buildings: the real frontage there is the landmark lots and green compounds.
  - Setting CollisionFidelity on new kit templates runs at about 1.4 a second in Studio (521 s for 737).

### P1 buildings made light for the whole city (16 Nov 2026, in Studio, not saved)
- **The idea:** the place keeps only each building's **shell**: its collision boxes drawn in the wall colour (the far look and the collision in one), plus the pitched roofs. Everything else (facade panels, piers, party walls, flat roof slabs, roof props, drainpipes, AC units, compound walls and their collision, gates) is **data**, built on each player's own client within 1,000 studs of the camera from the shared kit (new `src/client/YangonKitStream.client.lua`, decoder `src/shared/YangonKitData.lua`). Near the camera it looks the same as before; the shells of built tiles are hidden on that client only.
- **In Studio:** `Workspace.Yangon1to1.Buildings` = `Shell` (per-cell Models: shell boxes with attribute `T` = tile, roofs) + `Night` (30 meshes, unchanged). `ReplicatedStorage.YgnKit` = `Templates` (794 kit templates, Box collision fidelity) + `Data_P1` (Meta + 873 tile strings). The old folder was deleted after the Play check. `ServerStorage.YgnKitTemplates` (old kit) deleted. Store back on `CityLegends_v1`. Not saved: the coordinator saves.

| Measure (P1, 7.3 km²) | Before | After |
|---|---|---|
| Parts in the place | 139,675 | **10,558** (7,271 shell boxes, 3,257 roof parts, 30 night): 13x fewer |
| Parts per km² | 19,200 | 1,450 |
| Triangles in the place | 18.4 M | 0.23 M (shells + roofs 0.11 M, night 0.12 M) |
| Detail triangles near the camera | (all in the place) | about 1.4 M within 1,000 studs (16.5 M in the whole district's data) |
| Unique meshes | 767 | 775 kit templates (shared by the whole city) + 33 in the place |
| Collision boxes on the server | 23,183 | 7,271 (one set a building) + the roofs; compound walls: 10,313 boxes made on the client near the player |
| File size of the buildings (binary rbxm) | 7.66 MB (1.05 MB/km²) | 2.32 MB (0.32 MB/km²): shells 0.58, detail data 1.65, templates 0.08 |
| Play, dense street (31071, 30003), menu up | 7,664 building parts streamed, **15 FPS**, Studio 10.9 GB | 714 shells + 10,113 near parts (48 tiles), **47 FPS**, Studio 10.5 GB |

- **Whole city (30x the area):** before about 4.2 M parts, 550 M triangles and 230 MB; light about 320 k place parts, 7 M place triangles and **about 70 MB** (50 MB of it the detail data). Unique meshes stay near 1,800 (the kit is shared: piece ids are the same in every district).
- **Next to make it lighter:** the detail data is now the biggest part (1.65 MB a district, base64 text compresses badly). Storing each building as its outline + archetype + seed and laying the panels out on the client would make it about 4x smaller.

**What changed in the tools:**
- `city/buildings_1to1.py`: writes shell records (S / R) to `Shell_<n>.txt` and the detail per 256-stud tile; walls fit whole bays (stretch <= 15%) plus at most one **half-bay pier** (the 9,984 plain end strips are gone; 8,540 piers instead, inside the kit); **one drainpipe and 1-2 AC units a building** on its longest street face (not one a panel); compound walls: lot lines joined and simplified, pieces of 8 / 4 / 2 / 1 bays (15,115 pieces, was 21,915), one collision box per straight chain; **hip roofs only on near-rectangular outlines** (fill > 0.88, was 0.78: the "huge eaves" were the roof rectangle standing past notched outlines), eave 0.75 m on villas, rise capped; shells and roofs stepped so no two share a plane.
- `city/kit_panels.py`: no AC / drainpipe inside panels; `p_pier`; props `pipe` (5 cm, 1 cm off the wall: the old one stood 0.45 m off), `ac`, `cwall2`, `cwall8`; the hip roof is one part (soffit in the roof class); **stable piece ids** from the piece's key (the same in every district).
- New `city/kit_pack.py` (packed format, rbxmx writer); `city/kit_flicker_test.py` also checks shells and roofs.
- `tools/yangon/YangonKitPlace.luau`: `templates(holding, store)`, `shells`, `preview(centre, radius)` / `unpreview` (Edit only: see what a client builds).
- RenderFidelity: every kit mesh was already Automatic (checked 95,749 of 95,749).

**Checks:** flicker test: kit 433 pieces 0; placed sample of 2,500 lines 1 pair (a 0.015 sq-stud corner of two wall copings, as before); shells and roofs 0 (fixed on the way: the new drainpipe's back face 1 cm off the wall, the AC drip next to the township bands, boxes of one building sharing a top, neighbours' eaves at one height). Grazing close-up of a walk-up with its AC: no flicker. Play: tiles build in about 1 s round the camera, shells hide, detail looks as before.

**Screenshots** (same views; `C:/Users/kaung/.claude/projects/D--ObsidianOne-Claude-Obsidian/8dbf212d-129a-4909-ba7d-ab448f73c052/tool-results/`): before Kabar Aye `mcp-Roblox_Studio-blob-1794807184618-oda04x.jpg`, residential `...1794807209536-gg4975.jpg`, aerial `...1794807213456-wu6rjn.jpg`; after Kabar Aye `...1794808890341-mdd9ss.jpg`, residential `...1794808898221-nhw7qv.jpg`, aerial `...1794808872437-fsbugy.jpg`, shells only from the air `...1794808838325-09zd6k.jpg`, in Play `...1794811938628-ylg0x6.jpg`, grazing close-up `...1794812338807-pqje4p.jpg`.

**Still to know:**
- In Edit the owner sees the shells (plain boxes in the wall colour) away from a preview; Play shows the detail. `YangonKitPlace.preview(centre, radius)` shows it in Edit.
- Beyond 1,000 studs a player sees shells (plain boxes): fine in the haze, but no windows on them.
- Compound-wall collision is on the client only (the server has none; NPC traffic stays on the roads).
- Edit memory was not comparable (other agents' work came in; Studio held 7.5 GB after the two Plays).
- Trap: another agent's `git pull --rebase --autostash` put this job's `buildings_1to1.py` into `stash@{0}` mid-run (it ran the old code once); it was restored from the stash. The stash still holds other agents' changes: not dropped.

### P1 greenery, ground and Inya Lake edge (16 Nov 2026, in Studio, not saved)
- Note: [[2026-11-16 P1 greenery, ground and Inya Lake edge (1 to 1)]].
- First version (Ygn dirt / earth / gravel ground + own tree meshes) rejected by the owner ("dirty", "trees so ugly"); now: the game's own grass, clean concrete only on forecourts / parking, the old map's Tree / Palm / PalmA kit at real sizes.
- 27,594 trees as client-streamed data (`YgnKit.Data_P1G`), 2,363 big crowns as far looks in the place, canopy 36% (research ~33%).
- Inya Lake: 820 m bund beside Kabar Aye Pagoda Road (wall, railing, 3 m walkway), natural banks elsewhere.
- Place parts 34,238 -> 39,696; no new unique meshes.

### P1 street detail (16 Nov 2026, in Studio, not saved)
- **What:** the street layer of P1, from the two street research notes. Details and pictures: [[2026-11-16 P1 street detail (1 to 1)]].
  - 1,937 concrete power poles (206 of them transformer platforms) with 1,567 cable spans and 835 house drops.
  - 343 white lamp posts, plus a lamp on every second street pole.
  - 47 signal poles at the 9 OSM signal junctions.
  - 28 YBS stops, 54 junctions with real name signs.
  - 74 tea-shop spills, 129 stalls, 47 trishaws.
  - 62.6 km of slab drains, median railings, litter.
- **How:** a 33-piece kit (11,418 triangles, 66 meshes) and placement data `ReplicatedStorage.YgnKit.Data_P1S`. Each player's own client builds it within 700 studs of the camera.
  - The same streamer and decoder as the light buildings.
  - New records: L (cable spans), K (single cables) and T (name plates from an image atlas).
- **Budget:** 22,551 parts and 2.7 M triangles in the whole district's data (24.7 poles a real km). Near the camera on a dense street: 632 parts, 360 cables, 29 lights, beside the buildings' 13,758 parts. Play: about 58.6 FPS without the layer and 57.3 FPS with it (both at the 60 cap); memory +9 MB.
- **Checks:** flicker 0, on the kit and on a placed sample of 2,398 items. Nothing stands in a lane, on a carriageway, on a building, wall, gate, landmark lot, water, deck or tree trunk.
- **Next:** parked cars, yellow bus-bay kerbs, a photo check of the median railings, then the same tools for P2 (`street_1to1.py P2`).

### P1 road fixes and 1:1 traffic (16 Nov 2026, in Studio, not saved; superseded by the owner's "use the batch 0.5 road builder" plan)
- **Kabar Aye beside Sedona "10 m too wide": not so.** Against Esri z19 the P1 east kerb sits on the real kerb (within ~1 m at old-frame y 330 / 480 / 540); P1 is 2-4 m too wide on the lake (west) side only (the 10-stud lane floor + a 1.6-3 m median vs the real ~1 m barrier). The site audit's Sedona "wall line" (-100, 285) ... (-77, 530) runs along the real median barrier, so the refit's "squeezed" forecourt is closer to real than the audit. Road not changed there.
- **Myanmar Centre slip:** `roadnet.PAVED_WAYS['P1']` = ways 1513604988 + 730091070 (the second slip between the mall and its corner plaza) are paving now (P mesh + pavement collision, no lanes); the plaza joins the mall corner. The right turn keeps slip 317877729.
- **Junctions (roadmesh, 1:1 only):** junction boxes (`Builder._junctions`: convex hull of where different roads' carriageways overlap, nodes within 45 studs = one junction; 42 in P1), medians built once for the district (`M_final`: cut off every carriageway and every box + zebra, rounded ends), no line paint in a box or up to its stop lines, zebras across each arm just outside the box (main x main or signalised; none on a roundabout ring or slip), stop lines (33), turn arrows from OSM `turn:lanes` (33), yellow hatch on splitters / gores / small islands (107), clearMouths line rule for smaller mouths, no zebra / stop line on the Hanthawaddy ring (its arm medians become painted splitters). `junction_check` in the build: 0 medians in boxes, 0 line pieces in boxes, 0 zebras in boxes.
- **In Studio (place 121430381830562):** 134 changed mesh groups replaced (meshes 131410308021789, 96713853552103, 84647779595498; LY needed its own pass: Studio's `YangonRoadMeshes.LOOK` has no LY), 52 collision boxes out / 13 in. Old meshes and boxes in `ServerStorage.P1RoadFixOld` (174; delete once the roads are settled).
- **Traffic in the 1:1 frame (code synced, Play test NOT done):** `Config.Areas.Yangon1to1Areas` (x 15,000-61,000, z 14,000-54,000: the old batches 1-3 reach z ~12,400), `Config.isYangon1to1At`, `Config.laneWidth(pos?)` = 12 there (Chauffeur callers pass a point). Lanes: `tools/yangon/city/lanes_1to1.py P1` -> `src/shared/YangonLanes1to1_1..2.lua` (658 lanes, 763 links, numbered from 1 in the 1:1 set; `RivieraTraffic.build` adds them last with an offset). `Traffic.lua` marks those pieces `oneToOne` and spawns "anywhere" cars only in the player's own area. Checks: 0 lanes without a way on, 85% of lanes in one strongly connected part (4 small closed loops at the district edge); in Studio Edit the full graph builds with the old map's lanes unchanged (6,856 + 658 lanes), 3,336 live 1:1 pieces, 363 pruned by the builder's tail prune.
- **Studio state then:** Config patched by find / replace (Studio's Config was 198 characters off git), the other 6 scripts hash-equal before the sync. Store on CityLegends_v1.

## Step 5 progress: P2

### District P2, north of P1 (16 Nov 2026, in Studio, not saved)
- **Where:** lon 96.133-96.165, lat 16.834-16.862. Inya Lake's north and east shores, Kaba Aye Pagoda, the Mayangon / Yankin edge. It joins P1 along lat 16.834.
- **In Studio (place 121430381830562):**
  - Terrain skin: 1,572 tiles under the district. Inya Lake runs on from P1 at 40.5 (13.5 m).
  - Kaba Aye stands on real ground: a flat concrete court (radius 157.5 studs, top 77.6) replaces `KabaAyePlate_TEMP`, which is deleted.
  - The two P2 pagodas stand on the terrain, with no temp plates: n13601098532, and n11838369698 (new).
  - Buildings use the light pipeline: `Buildings.Shell` (13,032 parts), `Night` (46 meshes) and `YgnKit.Data_P2` (1,090 detail tiles).
  - Greenery: `YgnKit.Data_P2G` (38,963 trees, built on the client) and 3,084 far crowns. The ground is clean grass, with concrete only on forecourts.
  - Inya Lake's Pyay Road bund: see below.
  - P2 roads (`Roads.Meshes.P2Cell_*`, `Roads.Collide.P2`) are **placeholders only**. A roads agent is rebuilding all 1:1 roads with the batch 0.5 builder.
- **How to run:** set `YANGON_SCALE=1to1`, then run `roads.py P2`, `terrain.py P2`, `buildings_1to1.py P2` and `green_1to1.py P2` (all in `tools/yangon/city`). P2 is in `geo.PILOT_LL`.
- **The seam with P1:** `geo.PILOT_SEAMS = {'P2': ('P1',)}`.
  - `roadnet.pilot_seams` moves each P2 road end on the shared edge onto P1's road end there: the same point, the same direction, the same cross-section, and a height pin. All 7 crossing roads matched: Pyay ×2, Kabar Aye ×2, Inya Rd, Kanbe Rd, Thukhawaddy St.
  - `roadmesh` runs a pilot's cut ends past the edge and clips them on it. Before this, an oblique road left a wedge of grass at the seam. The P1 cells along the seam (`Cell_18/19/22/23x16`) were rebuilt the same way.
  - `terrain.py` treats P1 as an earlier batch: P1's road banks reach over the edge, and P1's columns are kept.
  - The lake bed now deepens from the real shore, not from the district edge. P1's 19 lake tiles at the edge were rewritten.
  - Checks:
    - Road height at the seam: equal (44.4 on Kabar Aye).
    - Land across the edge: mean step 0.07 studs. The 2 bigger steps are shoreline columns.
    - Water level: 40.5 on both sides.
    - Seam close-up: no gap.
- **Inya Lake's Pyay Road bund** (owner, via the coordinator), along the OSM straight shore from lat 16.8354 to 16.8414, 0.7 km:
  - The bund top is 2 m above the lake.
  - A 0.5 m concrete edge and a 3 m concrete walkway, then a grass strip easing back to the ground by 21 m.
  - The water is 2 m deep at the wall.
  - A low concrete wall 0.75 m high, `Workspace.Yangon1to1.InyaBund`, 2 Parts.
  - This is `terrain.PILOT_BUNDS`. `green_1to1` also built its own 342 m bund with a railing on the north-west shore, plus natural banks with trees elsewhere.
- **Landmark lots left empty:** `buildings_1to1.LANDMARK_SITES_BY_TAG['P2']`, also used by `green_1to1.LANDMARK_BOXES['P2']`.
  - Kaba Aye: OSM compound 186911800 plus the 315-stud court.
  - Diamond Inya Palace.
  - Inya Lake Hotel and the Yangon Convention Center.
  - Lotte Hotel.
  - Both pagodas.
- **Buildings:** 6,479, from 6,636 footprints.
  - Dropped: 31 on landmark lots, 124 on road corridors, 0 already built in P1, 0 overlapping P1's buildings by the seam.
  - Archetypes: house 3,209, villa 988, walk-up 754, shed 687, township 594, civic 214, condo 26, market 7.
  - 129 km of compound wall, 1,027 gates.
  - Buildings keep off the road corridors in `build/city_1to1/roads_P2_profile.json` (real carriageway + pavement + 0.6 m), so they still fit the new roads.
- **Kit:** 774 templates are used. 42 were new: 22 panels × wall and grille. Only those 42 were uploaded, through the new `city/glb_subset.py`, as asset 136137118940785. Night meshes: 109886462347694.

| Measure (P2, ~8.6 km² of land) | Value |
|---|---|
| Place parts, buildings | 13,032 shells and roofs + 46 night meshes (P1: 10,558) |
| Detail near the camera (data) | 129,832 parts, 16.0 M triangles for the whole district; client-built within 1,000 studs |
| Trees | 38,963 near (data) + 6,168 far-crown parts + 303 lake edge parts |
| Roads (placeholder) | 87.4 km, 290 meshes, 659,595 triangles (7,500 a real km), 8,226 collision boxes (94 a km); junction check 0 / 0 / 0 |
| Lanes | 643 (`YangonLanesBP2_*`, first 10,309), files only |
| New unique meshes | 42 kit + 46 night (+ 290 placeholder road meshes) |
| Studio memory, Edit | 11.0 GB, with all other agents' work |

- **Checks:**
  - Flicker test: kit 0, shells and roofs 0.
  - The placed sample found **99 tiny pairs**: undersides of floor bands where two panels meet at a 90° corner, at most 0.2 sq studs each, at 5 buildings near x 27,800-27,900. They are not fixed yet. They need a corner trim in `kit_panels`.
  - Road tops sit 1 stud over the terrain: p5 0.96, median 1.02, p95 1.07. No terrain lies above a road.
- **Screenshots** (PlayLight 13), in `C:/Users/kaung/.claude/projects/D--ObsidianOne-Claude-Obsidian/8dbf212d-129a-4909-ba7d-ab448f73c052/tool-results/`:
  - Seam, Kabar Aye from P1: `mcp-Roblox_Studio-blob-1794820538774-nabziv.jpg`.
  - Seam close-up, before the fix: `...1794820553667-w1eaft.jpg`. After the fix: `...1794821483505-e9wh5s.jpg`.
  - Kaba Aye on its court: `...1794821243889-v6sx9t.jpg`.
  - Pyay Road and the bund: `...1794821393543-4rqhn7.jpg`. Bund close-up: `...1794821404035-r2j9mr.jpg`.
  - Inya north shore: `...1794821454938-y37g4k.jpg`.
  - Aerial: `...1794821475097-d2ai3z.jpg`.
- **Still wrong:**
  - The shallow lake bed is sand, so near the shore Inya Lake reads white through the water (P1 too). A mud bed would read like the real murky lake.
  - The Kaba Aye court's Concrete renders dark blue-grey (the RivConcrete2 override).
  - The 99 corner-band pairs.
  - P2 street detail (`street_1to1.py P2`) has not been run.
  - Maha Pasana Guha has no OSM outline; only the compound and the court are kept empty.


### Shell facades and the Studio Edit preview (16 Nov 2026, in Studio, not saved)
- **Owner:** "why are the buildings just blocks, even the old one was BETTER"; then "all the buildings in roblox studio look like the ones in game (not some random blocks)".
- **Far look:** all 15,553 shell boxes of P1 + P2 now show windows and floors. Three neutral facade sets drawn in code (walk-up / condo / civic with balcony cages and AC boxes, shophouse with two windows a bay, house / villa with shutters), 10-stud floors, whole bays, window recesses in the normal map, smooth glass. The part's own colour still tints each building. Sheds, halls and markets keep their plain wall.
  - Counts: Walkup 4,149, Villa 9,147, Shop 1,048, kept plain 1,209.
  - Floors line up with each building's ground floor to within 1.25 studs. A material picture hangs from a part's top, so each set has 4 shifted copies.
- **Studio Edit:** a local plugin (`YangonEditPreview`) builds the same detail Play shows within 1,000 studs of the Studio camera: facades, street poles and wires, trees. Nothing it makes is saved or sent to Team Create. Tested: 72 tiles, 14,307 parts round the dense street in about 4 s, and it followed the camera.
- **Owner step:** close Studio and open the place again (the plugin loads at start). The toolbar gets a "Yangon" tab with a "Yangon preview" button to turn it off and on.
- **Detail radius in Play stays 1,000 studs.** At 1,500 the near parts doubled (14k to 30k). FPS did not change measurably on the busy PC (menu up: 8.6 with detail, 9.5 shells only, 11.2 at 1,500), so the radius was left as it is for phones.
- **Screenshots** (`C:/Users/kaung/.claude/projects/D--ObsidianOne-Claude-Obsidian/8dbf212d-129a-4909-ba7d-ab448f73c052/tool-results/`):
  - Before (plain shells, from the light pass): aerial `mcp-Roblox_Studio-blob-1794808838325-09zd6k.jpg`.
  - After, Edit, aerial: `mcp-Roblox_Studio-blob-1794821977510-cmrvl3.jpg`. Street: `...1794821996621-27umup.jpg`.
  - Edit with the preview plugin, street: `...1794822033116-du0hbb.jpg`. Aerial: `...1794822047206-12lv0v.jpg`.
  - Old batch 0.5 buildings for comparison: `...1794805603735-9t9wm3.jpg` (aerial) and `...1794805617099-aa8dar.jpg` (street).

## Owner's order (16 Nov 2026, evening)
> "do up to batch 3 first, then start renovating every house and put interiors by every district from then. also while doing up to batch 3, make the road maker use the same as the friday's builder with real roundabouts, proper markings and all 1:1 roads. BUT FIRST, fix the current roads as the FIRST FIRST priority"

1. **First:** fix the current 1:1 roads with the Friday (13 Nov, batch 0.5) builder: real roundabouts, proper markings. While this runs, `Games/CityLegends/build/studio.priority` names the roads agent, and other agents give it Studio first.
2. **Then:** build the 1:1 map up to batch 3: batches 0.5, 1, 2 and 3 (`geo.BATCH_LL`), every road made with the same Friday builder.
3. **After that:** renovate every house (real looks) and add interiors district by district. Interiors only where real photos exist.
