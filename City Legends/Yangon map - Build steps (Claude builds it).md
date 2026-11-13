---
tags: [city-legends, yangon-map, build-steps]
created: 2026-11-13
---
# Yangon map – build steps (Claude builds it)

**Owner, 13 Nov 2026, 12:32: "lets use claude code".** From step 3 on, each step is run in Claude Code from a prompt in `City Legends/Prompts/` (one prompt = one step + a report). This replaces the earlier rule of the same day ("no prompts for claude code, u ARE the claude code"), under which steps 0 to 2 were built by Claude in chat.
The place is City Legends, placeId 121430381830562. One step per run. Each run starts by reading [[2026-11-13 Yangon map - Step 2 road design]] and this note, and ends by ticking its step here and writing what it did.

Rules for every step:
- Owner's road rules: main roads 2+2 with traffic; streets 1+1 with no traffic; traffic only on main roads.
- Monaco (`Workspace.Riviera`) is not touched until step 11. Yangon is built beside it in `Workspace.Yangon`.
- Save the place with a version note at the end of each step. Write the version number here.
- Lighting is never dark. Models stay light on triangles. Check on phone size.
- Studio tools go in `ServerStorage.ClaudeTools` as ModuleScripts; `require` a `:Clone()`.

## Steps
- [x] **0. Street plan and road design** (13 Nov). Roblox version at the time: 688.
- [x] **1. Backup and setup** (13 Nov, version 708). Save the live place with the note "Monaco backup before Yangon". Check what sits near X 30000 and fix the map's place in the world. Get `ygn_roads.json` and the ground grid into Studio (the repo is public: Studio can fetch committed files from GitHub by commit id).
- [x] **2. Ground** (13 Nov). Terrain from the smoothed ground grid in 4-stud cells: land, Inya Lake's water at 16 m, the lake bed.
- [ ] **3. Main roads.** Give `Roads.luau` a half width per road (streets 16, with kerbs and pavements). Build the Yangon Loop, New Road and University Avenue. Build the roundabout ring. Paint the lines. Prompt written 13 Nov: [[Yangon map - Step 3 - main roads, roundabout, lines]]. Not run yet.
- [ ] **4. Flyovers.** Decks, ramps, pillars, railings and side lanes for the Pyay Road Flyover and the Kabar Aye Flyover. Build the two junctions underneath.
- [ ] **5. Streets.** The 30 streets, their junction mouths, and the barriers at the 16 map-edge road ends.
- [ ] **6. Smooth pass.** Kerbs on bends, surface check (no steps, holes or flicker), then road meshes.
- [ ] **7. Traffic lanes.** Lanes for main roads, side lanes and the roundabout only. Lane checker at 0 problems. Traffic runs on main roads only.
- [ ] **8. Buildings and landmarks.** Yangon-style blocks along the roads, Novotel, Optima and MM Plaza, far-city backdrop at the map edge.
- [ ] **9. Move in the game.** Venues, houses, gas stations, spawn at Optima, fast travel spots, minimap.
- [ ] **10. Night lights.** Street lamps on main roads, lit buildings, never dark.
- [ ] **11. Switch over.** Move Monaco to ServerStorage (kept, not deleted), playtest, phone performance check.

## Log
- 13 Nov 2026: step 0 done in chat. Data and pictures in `Games/CityLegends/imports/refs/map/`.
- 13 Nov 2026, start of step 1:
  - The box Yangon will fill (X 27840 to 33520, Z -6512 to 1888) holds no parts. Monaco (`Workspace.Riviera`) sits at X 9645 to 17591, Z -2887 to 1555. So X = 30000 + x × 1.6 stays.
  - First try at the labelled save failed (Studio did not answer).
- 13 Nov 2026, step 1 (owner: "ok start doing it"):
  - **Monaco backup saved: Roblox version 708**, note "Monaco backup before Yangon". This is the restore point.
  - Studio's `execute_luau` cannot fetch from the web here: every domain (GitHub, localhost) is refused by the Assistant HTTP allowlist. So data does not come in by HttpService.
  - **How data gets into Studio:** pack it as ModuleScripts in one `.rbxmx` (JSON in `return [==[ ... ]==]`, under 190,000 characters each), save it in `Games/CityLegends/imports/sync/`, upload it as a Model to group 33151111 with `open_cloud_invoke` (POST `/assets/v1/assets`), then `insert_asset` into ServerStorage. `tools/yangon/mk_rbxmx.py` builds the file.
  - First pack: `imports/sync/yangon_data_1.rbxmx` = `YangonData` (Terrain, Roads_1 to Roads_3, Design, Tools/YangonTerrain). The ground builder's source is `tools/yangon/YangonTerrain.luau` (782 tiles of 256 studs, ground 1 stud under road height, lake water at 25.6 studs).
  - The owner approved `D:\ObsidianOne\Claude+Obsidian\Games\CityLegends\imports` for uploads (Studio > Assistant Settings > MCP Permissions).
- 13 Nov 2026, step 2 (ground) done:
  - Data pack 2 uploaded (`imports/sync/yangon_data_2.rbxmx`, asset 85224774084372; pack 1 was 114024008709031) and put in **`ServerStorage.YangonData`**: `Terrain`, `Roads_1` to `Roads_3`, `Design` (JSON strings) and `Tools.YangonTerrain`. `insert_asset` brings it in as a package: delete the PackageLink.
  - Ground written with `YangonTerrain` (`T.prepare()`, `T.run(1, 400)`, `T.run(401, 400)`, about 10 s each): 782 tiles of 256 studs over X 27648 to 33536, Z -6656 to 2048, Y 0 to 64. Grass on land, Inya Lake and 9 ponds as water at 25.6 studs, sand bed 10 studs down.
  - Checked: 3,000 random spots, the water matches the data at 2,999; the land surface sits exactly 1 stud under the road height (median difference 0.00, 5% to 95% 0.00). Water is 13.9% of the box (2.8 km²).
  - **Trap:** smooth solid terrain shows 2 studs (half a voxel) above "voxel bottom + occupancy × 4". Water does not. The builder takes 2 off for land and sand (`SOLID_LIFT`).
  - **Trap:** Studio sometimes answers "Target is not reachable" to `execute_luau` or `save_place`. A second try usually works. The save after step 2 failed 4 times in a row, so **step 2 has no labelled version yet**: save first thing in step 3 (note "Yangon step 2: ground and Inya Lake"). The place is in Team Create, so the ground is already in the live place.
- 13 Nov 2026, 12:40, before step 3 (owner: "lets use claude code"): the step 3 prompt is `Prompts/Yangon map - Step 3 - main roads, roundabout, lines.md`. Nothing was built or changed in Studio. Found while reading the data and `Roads.luau`:
  - Studio state: `ServerStorage.YangonData` and `ClaudeTools.Roads` / `RoadLines` are there, `Workspace.Yangon` does not exist yet, a loose `ZProbe` and `Part` sit in `Workspace`. Two Studios are open (City Legends and Stomp Evolution): pick by name.
  - **Trap: rank is the wrong way round.** `Roads.luau` treats the lower rank as the bigger road (Monaco: 0 = biggest). `ygn_roads.json` has main roads 5 and streets 4, 3, 2, and the three main roads tie. Left alone, every street beats the main roads.
  - **Trap:** kind `route` gets grey `Shoulder` strips, not kerbs and pavements; an edge narrower than `HALF - 0.5` (every street, half 16) is read as a hairpin leg and gets a stone `LegWall`; `PAVER` is Monaco's red-pink.
  - **Trap:** the Yangon Loop starts and ends at the roundabout's centre (29072, 47.3, 1173), so its samples inside 108 studs are left out for the ring. Open ends get a `TurningCircle` unless told not to.
  - **Trap:** flyover samples sit 14 studs up. A road passing under a deck (University Avenue's west end, the loop under New Road) would be lifted onto it by `alignJunctions`. Step 3 builds nothing inside the two flyover corridors (70 studs either side of the deck line); step 4 does.
  - The design chain's `.pkl` files are not in `imports/refs/map`, so `d6_export.py` cannot simply be re-run: patch the ranks in the json and in Studio.
