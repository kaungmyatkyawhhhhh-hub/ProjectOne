---
tags: [city-legends, yangon-map, research, reference-study, plan]
created: 2026-11-14
---
# Yangon batch 0.5: reference study and accuracy plan

Made after the owner's verdict on 14 Nov ("it dont look like the google maps one", see [[Yangon map - Build steps (Claude builds it)]]). Brain method: [[Brain/Methods/Reference study]]. Lesson: "The Yangon map doesn't look like Yangon" in the Lessons note.

## What was looked at
- **OpenStreetMap, the whole batch 0.5 area** (96.1279 to 96.1605 E, 16.8102 to 16.8568 N), downloaded 14 Nov into `Games/CityLegends/imports/refs/map/osm_b05/` (4 tiles; (c) OpenStreetMap contributors, ODbL).
- **Google Earth (web, in the built-in browser):** Inya Lake from above, the Pyay Road embankment, the Kabar Aye embankment, Hledan from straight above. Pictures: `Yangon ref - ...jpg` in this folder.
- **Google Earth has no true 3D buildings for Yangon.** It is satellite photos laid over the ground, so tilting shows the angle but buildings stay flat. Heights must come from OSM floor counts, photos and estimates.

## Findings

### Roads: the lane counts are wrong
OSM lane tags (lanes each way on divided roads):

| Road | Real | In the game |
|---|---|---|
| No.1 Industrial Road | divided, 2 to 3 each way | street, 1 + 1 |
| Pyay Road | divided, 3 to 4 each way | main road, 2 + 2 |
| Kabar Aye Pagoda Road | divided, 3 each way (up to 6) | main road, 2 + 2 |
| Insein Road | divided, 3 each way | street, 1 + 1 |
| Inya Road | 4 lanes | street, 1 + 1 |
| University Avenue Road | 4 lanes (part divided) | main road, 2 + 2 |
| Kanbe Road | 4 lanes | street, 1 + 1 |
| Saya San Road | 4 lanes | street, 1 + 1 |
| Parami Road | 4 to 6 lanes | street, 1 + 1 |
| New University Avenue Road | divided, 2 each way | street, 1 + 1 |

The game's rule from step 0 ("main roads 2+2, streets 1+1") made most of the big real roads too narrow.

### Buildings: the game's are made up
- OSM has **4,125 real building outlines** in batch 0.5 (the game has 1,267 made-up ones along the roads). 417 have floor counts; 63 a height.
- Real blocks are **packed full**: mostly 4 to 8-floor flats with red or grey roofs, mixed with trees, not one row along each road with grass behind.
- **Real towers** (floors from OSM):
  - 30 to 39-floor cluster east of the lake by Kabar Aye (16.8346 N, 96.156 E), drawn with 13 to 36 corners (rounded outlines).
  - Diamond Inya Palace Condo (33, 105 m).
  - Five Diamond Condo towers at Hledan (26).
  - Four 27-floor towers at 16.816 N, 96.129 E.
  - Pyay Garden (25), Myanmar Plaza (25), Melia Hotel (25).
  - Crystal Tower and Pearl Condo (20), Vantage Tower (16), Novotel Yangon Max (12 in OSM).
- Only 3 outlines are truly round in OSM. The round towers the owner means need to be found in photos (or the owner can point at them).

### Inya Lake: banks and park
- **Inya Kan Baung (Pyay Road side):** a long straight embankment. From the water: a sloped concrete edge, a light walkway, a row of big trees and a green strip (the lakeside park), then the wide divided Pyay Road.
- **Inya Lake Kan Baung (Kabar Aye side):** the same on the east shore along Kabar Aye Pagoda Road.
- The islands and peninsulas are covered in trees; the shore is green all round.
- OSM: 9 parks, walls, piers (the Boat Club), swimming pools and pitches inside compounds.

### The look from above
- Yangon is **very green**: big trees everywhere, inside compounds and along roads. The game's ground is bare grass.
- The **university** is a large red-roofed campus by Pyay Road.

## Accuracy plan (proposed, not started)
1. **Roads by real lane counts.** Widths and traffic lanes from OSM: divided roads as two carriageways where they really are (Pyay, Kabar Aye, Industrial, Insein). This rebuilds the roads, lanes, lamps and the lots beside them (everything is placed from the road edges).
2. **Real buildings.** Every OSM outline extruded to its floors (or an estimate from its type and size), roofs in the real colours, towers at real heights with rounded outlines where drawn round. Built as meshes in Blender to keep the part count down (owner allowed Blender for map pieces).
3. **Inya Lake banks and park.** Both Kan Baung embankments (edge, walkway, tree row, park strip, benches, lamps), trees on the islands, the Boat Club pier.
4. **Trees** in the compounds, along roads and round the lake, following the photos.
5. **Venues on real sites.** With real buildings the venue lots have to sit where real open land or matching buildings are.
6. **Side-by-side check** with the satellite view from the same angle before calling it done.
