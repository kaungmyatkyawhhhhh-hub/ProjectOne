---
tags: [city-legends, yangon-map, build-steps]
created: 2026-11-13
---
# Yangon map – build steps (Claude builds it)

**Owner, 13 Nov 2026: "no prompts for claude code, u ARE the claude code".**
Claude builds the Yangon map itself in Studio (City Legends, placeId 121430381830562). No prompts are written for another Claude. One step per chat. Each chat starts by reading [[2026-11-13 Yangon map - Step 2 road design]] and this note, and ends by ticking its step here and writing what it did.

Rules for every step:
- Owner's road rules: main roads 2+2 with traffic; streets 1+1 with no traffic; traffic only on main roads.
- Monaco (`Workspace.Riviera`) is not touched until step 11. Yangon is built beside it in `Workspace.Yangon`.
- Save the place with a version note at the end of each step. Write the version number here.
- Lighting is never dark. Models stay light on triangles. Check on phone size.
- Studio tools go in `ServerStorage.ClaudeTools` as ModuleScripts; `require` a `:Clone()`.

## Steps
- [x] **0. Street plan and road design** (13 Nov). Roblox version at the time: 688.
- [ ] **1. Backup and setup.** Save the live place with the note "Monaco backup before Yangon". Check what sits near X 30000 and fix the map's place in the world. Get `ygn_roads.json` and the ground grid into Studio (the repo is public: Studio can fetch committed files from GitHub by commit id).
- [ ] **2. Ground.** Terrain from the smoothed ground grid in 4-stud cells: land, Inya Lake's water at 16 m, the lake bed.
- [ ] **3. Main roads.** Give `Roads.luau` a half width per road (streets 16, with kerbs and pavements). Build the Yangon Loop, New Road and University Avenue. Build the roundabout ring. Paint the lines.
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
  - The labelled save did NOT go through: Studio did not answer the save request from chat. The place is still at version 688 and nothing was built. Try the save again first thing in step 1; if it fails again, the owner presses Ctrl+S once.
