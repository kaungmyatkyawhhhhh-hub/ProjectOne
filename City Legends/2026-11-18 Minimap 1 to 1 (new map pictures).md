# Minimap 1:1 (new map pictures), 18 Nov 2026

Owner: "redo the viewable map because on the new yangon map, there isnt a viewable map yet (the one on the screen)".

## Why no map showed
- The 17 Nov pictures (11 tiles, 12 studs a pixel) were fine: approved images in group 33151111.
- **The real fault was in `Minimap.lua`:** it put a picture on a tile only when the player was within 2,600 studs of the tile's MIDDLE. The 1:1 tiles were 12,288 x 6,144 studs, so the middle was never that close and the minimap stayed empty. (Monaco's tiles were 2,048 wide, so it worked there.)
- Now it loads a tile when you are near its BOX (`loadNear`).

## What was made
- `tools/yangon/city/minimap_1to1.py` redone: the J37 roads05 network (`roads05_P1_..._P12`), d12's night look.
  - roads by class (main roads gold, bigger streets light grey, small streets darker), pavements, dark edges, roundabouts, flyover decks with a shadow
  - water with a light edge (Inya Lake, Kandawgyi, the Yangon River, Pazundaung Creek, ponds), green areas (parks, grass, wood), pagoda compounds, every building shell with a soft shadow
  - P1, P2, P3 (in the game) in full colour; P4-P12 greyed (dim, no colour, water still dim blue); nothing past P1-P12 (the OSM cut left torn shapes there).
- Two tile sets (1024 x 512 each), 43 uploads:
  - **detail**: 5 studs a pixel, only over P1-P3 (30 tiles): the minimap, loaded near you.
  - **overview**: 16 studs a pixel, the whole P1-P12 box (13 tiles): the main menu's world map, the loading screen, and the minimap's backdrop past P1-P3.
- `src/client/YangonMapArt.lua` (`detail`, `overview`, `map`, `back`).
- `Minimap.lua`: overview under detail; the whole-map views load only the overview; the full-screen map loads detail tiles in view; icons for Myanmar Plaza and Bogyoke (pink ◆), Sule, Kaba Aye, Botataung and Shwedagon (gold ▲), Hanthawaddy Roundabout (○); names INYA LAKE, KANDAWGYI, DOWNTOWN on the world map. Venue icons (bank, hotel, gems, rewards, GGFest) and live markers as before.

Preview: [[2026-11-18 Minimap 1to1 - overview preview.png]]

## Also fixed: players did not spawn (found in the test)
- In Play the server's `Main` died with "Script timeout" in `Chauffeur.init` -> `ChauffeurRoute.graph` (the lane graph got bigger with the P1-P3 1:1 lanes; `task.spawn` runs it inline until it yields, so the timeout killed Main itself). No character, endless loading screen.
- Fix: `ChauffeurRoute.graph` yields every 2,000 lanes. After that the server started normally.

## Play test (test store, put back to CityLegends_v1, place saved v1437)
- Main menu world map tile: shows the map round Myanmar Plaza. [[2026-11-18 Minimap 1to1 - main menu.jpg]]
- World map page: map + fast-travel icons on the right roads (hotel, delivery, fuel, races on Kabar Aye Pagoda Road). [[2026-11-18 Minimap 1to1 - world map.jpg]]
- Minimap P1 (Kabar Aye by Myanmar Plaza, facing south): Inya Lake side on the right, Myanmar Plaza icon on the left: correct. [[2026-11-18 Minimap 1to1 - P1 Kabar Aye.jpg]]
- Minimap P3 (Sule roundabout, facing north-east): N on the upper left, the ring drawn. [[2026-11-18 Minimap 1to1 - P3 Sule.jpg]]
- Minimap P2 (Kaba Aye Pagoda Road, facing west): N on the right. [[2026-11-18 Minimap 1to1 - P2 Kaba Aye.jpg]]
- All 43 pictures approved at once by Open Cloud; they loaded in Play the first time. No Minimap errors in the Output.
- Not checked: the full-screen map (tap on the minimap) and the loading screen map by eye (same code path as the menu); live markers (no bank robbery / race running during the test, code unchanged).

## Rerun
`YANGON_SCALE=1to1 python minimap_1to1.py build P1_P2_P3_P4_P5_P6_P7_P8_P9_P10_P11_P12` (about 1.5 min) -> upload `imports/sync/minimap_1to1/{d,o}_*.png` (Image, group 33151111) -> `ids.json` -> `--lua ids.json`. When a new district is built, add it to `FULL` and rerun.

## 19 Nov fix: the map always loads whole, zoom out to all of it (owner bug)
Owner (full-screen map shot): "the minimap rarely loads all of it, and i think all of the minimap must load and also it should be so that the player can zoom out all the way to see the entire map because rn the max zoom out in the minimap is like only 10% of the map".
- **Overview always underneath:** the 13 overview tiles (16 studs a pixel, the whole P1-P12) get their pictures at once in the corner minimap, the full-screen map, the menu map and the loading screen, and are fetched ahead with `ContentProvider:PreloadAsync`. So a view is never an empty rectangle: a sharp tile still loading shows the overview under it.
- **Sharp tiles (5 studs a pixel) only when close:** a view under 9,000 studs across loads the sharp tiles in view (+ a margin) and drops the ones more than 2 views away (`sharpen`); zoomed further out they are all dropped. The corner minimap loads them within 2,600 studs of you and drops them past 7,000. The full map drops all of them when it is shut. Memory: 13 overview tiles at 1024x512 is about 27 MB decoded; at most about 10 sharp tiles more (about 20 MB).
- **Zoom:** the full map zooms out until the whole P1-P12 map fits (`Minimap.fitScale`), and fully zoomed out it recentres on the map's middle; in to street level (400 studs across). Pinch to zoom on phones (`TouchPinch`), one finger drags, + / - kept. The view stays on the map when dragged. The menu world map zooms out to the whole map too. The corner minimap's far zoom (at speed) went from 0.12 to 0.09.
- **Also fixed (again):** the server's Main was killed by Studio's script timeout in `ChauffeurRoute.graph` (RivieraTraffic.build takes 4-5 s with the P1-P3 + P7 lanes and ran inline in Chauffeur.init). graph now yields before building, one build at a time.

Play test 19 Nov (test store, put back to CityLegends_v1):
- Full map opened (sharp, street level round Myanmar Plaza): [[2026-11-19 Map - full map opened (PC).jpg]]
- Zoomed all the way out, before the recentre fix (the map cut off on the right, centred on the player): [[2026-11-19 Map - zoomed out before recentre (PC).jpg]]
- Zoomed all the way out after the fix, phone HUD: the whole map, every overview tile drawn (13 of 13 loaded), all icons: [[2026-11-19 Map - full map zoomed all the way out (phone HUD).jpg]]
- Zoomed in at Sule and at YCC: sharp: [[2026-11-19 Map - zoomed in at Sule.jpg]], [[2026-11-19 Map - zoomed in at YCC.jpg]]
- Corner minimap, phone HUD: [[2026-11-19 Map - corner minimap (phone HUD).jpg]]
- Corner minimap over 8,000 studs (2.7 km) south down Kabar Aye into P7, a check every 1,000 studs: the sharp tile under you had its picture and was loaded every time (2 s after arriving); 8-10 sharp tiles kept at once. [[2026-11-19 Map - corner minimap after 2.7 km (P7, phone HUD).jpg]]
- Not tested: a real finger pinch / drag (Studio's MCP can't send touches or mouse drags), panning to every corner by drag (checked instead: zoomed out, all 13 overview tiles loaded, the view clamps to the map), driving under power (the test car would not move after the teleport; the 2.7 km was done by moving the player). The phone view was the phone HUD (PreviewPhone) on a PC-sized window.
