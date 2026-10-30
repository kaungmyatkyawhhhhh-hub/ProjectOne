# Prompt: remake the City Legends map in the shape of Monaco

_For Claude Code on the PC, with Roblox Studio connected (MCP). Read all of this first. This is a big job: work in phases, save and push after each. Owner: talk short and simple (caveman mode, see `Preferences.md`)._

## What the owner wants
The owner thinks the current map looks bad and wants the **map shaped like Monaco**. Reference: `Games/CityLegends/imports/refs/map/monaco_shape.webp`. What that means:
- **The land:** a long, thin strip of coast, running about south-west to north-east, with the sea on the south-east side and hills / the border on the north-west side.
- **Two harbours cut into the coast:**
  - a **big main harbour** in the middle (like the Port of Monaco), with long piers and yacht berths;
  - a **smaller harbour** in the south-west (like Fontvieille).
  - Between them, a **rocky headland** with an old town on top (like Monaco-Ville).
- **The roads:**
  - a few long main roads running along the strip, **curving with the coast and the hills** (not a square grid);
  - a road all round the main harbour;
  - **hairpin bends** and roads that **climb in zig-zags** up the hillside districts;
  - a **tunnel** along the coast;
  - small grid-ish streets only in the flat harbour district (like La Condamine).
- **Districts** (our own fictional names, no real place names), from south-west to north-east:
  1. **a new-build district** round the small harbour: a stadium, a park, modern flats;
  2. **the old town on the headland:** a palace square, narrow streets, cliffs;
  3. **the harbour district:** a tight street grid, shops, the yacht harbour;
  4. **the hillside districts** above it: winding roads, terraces, villas;
  5. **the casino quarter:** a big square with gardens, the grand hotel, luxury shops (our casino, hotel and gem showcase go here);
  6. **the beach district** at the north-east end: a sandy beach, beach clubs (without alcohol), a sports complex;
  7. **the mountain road** above everything, along the top edge (great views, used for races).
- **Names:** fictional only (for example "Riviera Bay", "Old Rock", "Harbour Quarter", "Casino Heights", "Sandy Point"). **Never** write Monaco, Monte Carlo or any real name in the game.
- **Look:** a Mediterranean / Riviera style:
  - cream, pastel, ochre and white buildings;
  - terracotta roofs;
  - balconies;
  - palms;
  - tall harbour apartment towers;
  - stone walls and cliffs;
  - yachts in the harbours.
  - Low poly but with real-looking textures (game-ready, not cartoon).

## The night look and the roads (owner, 2026-10-30): like `imports/refs/map/monaco_night_look.webp`
- **No neon at all any more.** Remove the city's neon signs, neon strips and coloured neon trims everywhere, not just by day (this replaces the "neon at sunset and night" idea). Police, traffic and car lights stay.
- **Night = warm, golden, elegant**, like the photo (Monaco at blue hour):
  - **Sky:** deep blue twilight / blue hour (not black), mountains as dark silhouettes against it.
  - **Street lamps:** **warm golden / sodium-orange light** (about 2,700–3,000 K), many of them, lining every road. Roads glow orange-gold and you can follow their curves up the hills by their lamps.
  - **Buildings:** **warm-lit windows** (yellow-white), lots of them, plus soft warm floodlights on the fronts of the big buildings (cream and ochre walls glowing gold). Terracotta roofs catch the light.
  - **Harbour:** rows of white yachts with small lights, a big lit cruise ship, lit piers, and **the lights reflecting on the dark-blue water**.
  - **The hills:** the hillside roads and houses make chains of little golden lights going up the mountain.
  - **Colour mood:** gold and orange against deep blue. No pink, purple or cyan neon.
- **Roads like the photo:**
  - curving roads that wrap round the harbour edge and wind up the hill between buildings;
  - lined with **ornate street lamps** (dark metal posts with warm lanterns);
  - trees and palms along them;
  - stone walls on the hill side;
  - smooth dark asphalt with white lines;
  - a few roads raised on walls / short viaducts where the hill is steep.
  - Sidewalks on both sides in town. Low railings along the harbour.
- Update the lighting setup and `DayCycle` night keyframes to this look. Remove the neon systems and tags (`NightNeon` and similar) and the neon prompt's work. Show the owner a screenshot of the harbour at blue hour and at full night, next to the reference photo.

## Before you start
- Read:
  - `CLAUDE.md`;
  - `Roblox Playbook/Roblox Playbook - Rules for every game.md`;
  - `Games/CityLegends/CLAUDE.md` (the map is baked; how CityLayout, the lane graph, `world_test`, `graph_test` and `bake_check` work);
  - `City Legends/City Legends.md`.
- Call `list_roblox_studios` and use the Studio named **City Legends** only.
- **Work on a copy:**
  - save the current place as `CityLegends_before_monaco.rbxl` (backup);
  - build the new map in **`CityLegends_Monaco.rbxl`**;
  - only replace `CityLegends.rbxl` when the owner says the new map is better.
  - Never save over `CityLegendsCars.rbxl`.
- **Using real map data (allowed, recommended):** OpenStreetMap has Monaco's coastline and road lines for free. You may use it **only as a shape guide** (coast outline, main road curves, harbour shapes): download it from the Overpass API or a Monaco `.osm` extract, scale it, and simplify it. Add "Map shape based on © OpenStreetMap contributors (ODbL)" to the game's credits. Don't copy real building names or signs.
- **Keep the roads the SAME SIZE as now** (owner, 2026-10-30): every road uses today's sizes: `Config.City.LaneWidth` = 16 studs per lane, `LanesPerSide` = 2 (so 2+2 lanes, `RoadWidth` = 64), `SidewalkWidth` = 10, and the highway's 3+3 lanes where there's a highway. Don't make roads narrower or wider. Real Monaco streets are much narrower; ours keep our size, so fit the strip to about the current map's size and use fewer, bigger roads instead of many tiny alleys.

## How to build it (phases: show the owner after each)
**Phase 1: shape and roads (the base)**
1. Make a **2D plan**:
   - the coastline;
   - the harbours;
   - the district areas;
   - the **main road network** as smooth curves (splines);
   - the hills (heights).
   Render it as a picture and **show the owner before building anything 3D**.
2. Build the **ground**: terrain hills, sea, cliffs, beaches and the harbour basins (with piers).
3. Build the **roads from the curves**:
   - smooth road surfaces with no stud steps;
   - matching lane lines;
   - kerbs and sidewalks;
   - junctions;
   - traffic lights at the big junctions;
   - roundabouts where the map has them;
   - the tunnel;
   - bridges / viaducts where a road crosses a valley.
4. **Rebuild the traffic lane graph from the same curves**, so traffic, police, the chauffeur, the minimap and races follow the new roads. The grid code (`CityLayout` grid, `roadCoord`) can't describe curvy roads. Add a **spline / graph road system** (for example a `RoadNetwork` module: nodes, curved edges, lane counts) and make Traffic, Police, ChauffeurRoute, Minimap and Challenges read it.
5. Tests:
   - update `world_test`, `graph_test` and `bake_check` for the new roads: no dead ends, no gaps, road under every lane, nothing in the lanes, turns stay level;
   - drive every road in Studio.

**Phase 2: districts and buildings**
6. Fill each district with Riviera-style buildings: reuse and restyle our building generators where they fit, plus a few landmark models.
7. Keep it light for phones: LOD, streaming, `LOD` tags, a part count close to the old map's.
8. Night: the warm golden look above (lit windows, golden street lamps, harbour lights reflecting on the water). No neon.

**Phase 3: move the game's places onto the new map**
9. Place everything in the right district and fix their code to use the new positions:
   - Legends Motors;
   - Legends Customs;
   - the bank;
   - the towers / penthouses;
   - the hotel, casino and gem showcase (in the casino quarter);
   - Legends Realty;
   - the houses (hillside districts: Low lower down, Mid on terraces, High at the top behind the gate);
   - police stations;
   - speed cameras;
   - challenges (drift spots on the hairpins, a speed trap in the tunnel, a jump);
   - races;
   - the chauffeur stands;
   - spawns.
10. Re-bake the map into `CityLegends_Monaco.rbxl` the same way as the first bake.

**Phase 4: test and hand over**
11. 2-player play-test of everything; phone-size screenshots; FPS and part count compared with the old map.
12. Show the owner screenshots from the air and from the street in every district. **The owner decides** if it replaces the old map.

## Usage warning (tell the owner)
This is the biggest job in the game: roughly **8–15 usage windows** (a window resets every 5 hours on Pro), done over several days. Commit and push after every step so nothing is lost when the limit hits. Start each phase in a fresh chat with "Pull from git, read the Monaco prompt, continue from Phase N".

## When done with each phase, tell the owner (short)
- what's done, with 2–4 screenshots;
- what's next;
- anything that broke.
