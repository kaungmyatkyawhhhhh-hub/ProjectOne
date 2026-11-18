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

## Play test
(see below)
