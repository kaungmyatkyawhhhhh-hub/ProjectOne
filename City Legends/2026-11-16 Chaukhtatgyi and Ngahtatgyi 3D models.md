---
tags: [city-legends, yangon, 3d, landmark, 1to1]
created: 2026-11-16
---
# Chaukhtatgyi and Ngahtatgyi: 3D models (1:1)

Two Buddha halls in Bahan, modelled at true size (3 studs a metre). They were built in pure Python, not in Blender, and both have walkable insides made from the interior photos. **Photos win over everything else.**

## Files
- Modeller: `Games/CityLegends/tools/yangon/landmarks3d/solid3d.py`. It does boxes, beams, roof slabs, prisms, lofts, tubes and ellipsoids. Closed solids are turned to face outward, and figures get smooth normals.
- Build: `Games/CityLegends/tools/yangon/landmarks3d/bahan_buddhas3d.py`.
  - `python bahan_buddhas3d.py [key]` writes `imports/sync/landmarks/<key>.glb`.
  - It also writes `build/landmarks/<key>/<key>_place.json` (pivot, looks, collision rows) and runs the flicker check.
- Studio placer: `tools/yangon/landmarks3d/bahan_place_luau.py <key> <asset id>` writes `build/landmarks/<key>/<key>_place.luau`. Paste that file into `execute_luau`.
- Shape check renders (Blender 3.6 headless, Workbench, back faces culled): `tools/yangon/landmarks3d/preview_blend.py`.
  - Get the input from `bahan_buddhas3d.dump(key, out.json)`.
  - The views are in `VIEWS`.
- Satellite check for Ngahtatgyi: `Games/CityLegends/build/landmarks/ngahtatgyi/sat/` (Esri z19, reference only; `sat_osm.jpg` has the OSM outline drawn on).

## Position (Ngahtatgyi fixed)
| | lon, lat | World studs (1:1) | Ground |
|---|---|---|---|
| Chaukhtatgyi (shed centre) | 96.163884, 16.811666 | X 37635.06, Z 32763.72 | Y 69.98 (GLO-30) |
| Ngahtatgyi (OSM bbox centre) | 96.162560, 16.808448 | X 37211.85, Z 33831.02 | Y 73.36 (GLO-30) |

- **Ngahtatgyi was wrong in `landmarks.json`** (96.1645, 16.8104). That point is **299 m off**.
- The real hall is OSM way/314121257, a 72 x 58 m outline. On Esri z19 its red roofs and the gold five-tier tower sit exactly on that outline.
- The covered stairway comes up from Shwegondaing Road on the north side, from the "Nga Htat Gyi Phaya" bus stops at 16.8105, 96.1630.
- The interiors catalogue's spot (96.1488, 16.8072) is also wrong.

## Real sizes used (sources)
| What | Value | Source |
|---|---|---|
| Chaukhtatgyi Buddha | 66 m long (crown end to soles), crown top 16.5 m over the dais | Wikipedia (66 m), thailex (65.85 m), catalogue (16-17 m high) |
| Its glass eyes | 1.77 x 0.58 m | catalogue |
| Chaukhtatgyi shed | 94 x 46 m, long axis bearing 122.3 deg | site audit (Esri Wayback + live z19, OSM traces only part) |
| Shed section | nave 30 m wide, ridge 27 m; aisles 8 m each side, eaves 10 m; clerestory 15-21 m with a window band; lower 4 m open | photos (red corrugated walls, white ceiling panels, maroon trusses, window strip); heights estimated from the photos |
| Shed roof | green | satellite (110, 140, 108) |
| Figure pose | lying on the right side, head SE, face NE (towards the main door), head propped up, feet stacked with the soles to the NW end | photos 1 and 2; head direction from the site audit (one secondary source, likely) |
| Soles | salmon pink with a gold grid (the 108 marks) and a gold wheel; toes stacked vertically | photo `Chauk_Htat_Gyi_Pagoda_2.jpg` |
| Dais | glass-mosaic plinth 2.2 m high, gold spiked railing with lamps in front and at the feet | photos `Pagoda_Chauk_Htat_Gyi_10.jpg`, `_1_.jpg` |
| Niche wall | maroon wall, teal dado, 2 rows of mint niches in gold frames | photo `Pagoda_Chauk_Htat_Gyi_21.jpg` |
| Ngahtatgyi hall | 71.8 x 57.6 m (OSM bbox) | OSM way/314121257 + Esri z19 |
| Ngahtatgyi Buddha | seated 14.0 m (seat to crown tip), knees 13.8 m wide | Wikipedia / renown-travel (45.5 ft, 46 ft wide) |
| Its pedestal | 2.8 m gilt throne (3 tiers) | photos. Sources say "30 ft pedestal", but the photos show the lap only about 3 m over the floor, so the photos win. |
| Figure proportions | chin at 61% of the height, head 3.2 m wide, shoulders 8.4 m | measured on `Ngahtatgyi_Buddha_Image.jpg` and `01-yangon-ngahtatgyi-paya-d02.jpg` |
| Backdrop | carved teak, 21 m wide, 20.6 m high, gold flame wings by the crown | photos 04, d02 |
| Hall inside | red polished floor, mirror-mosaic columns on red bases, white steel trusses, skylight bands along the nave | `Yangon-Ngahtatgyi-12-Halle-gje.jpg`, 04 |
| Roof | rusty red-brown corrugated; a five-tier tower (Nga Htat Gyi = "five tiers") over the shrine, gold finial at 36.5 m | stairs photo, Esri z19 |

## Model (v1)
Triangles and meshes are filled in after the Studio step (see "In Studio").
- **Chaukhtatgyi:**
  - 22,360 triangles, 21 meshes, 0 flicker pairs.
  - The shed has 48 steel columns, 12 nave trusses, aisle rafters, a clerestory window band, gable walls and a green roof with a white ceiling.
  - The dais is glass mosaic with a white lip. There are 2 railings (spikes and lamps) and a 94 m niche wall (about 120 niches).
  - The figure is a robe loft for the torso and legs, plus a head, neck, crown, ears, eyes, lids, brows, nose, lips, both arms and hands, a cushion, two stacked feet with 10 toes, and the sole grids and wheels.
- **Ngahtatgyi:**
  - 9,568 triangles, 18 meshes, 0 flicker pairs.
  - The hall has walls with 4 doors and steps, a glass-block band, a skirt roof, a clerestory with a skylight band and a gable roof.
  - There are 26 mirror columns, white girders, rafters and trusses, and the five-tier tower.
  - The throne has 3 tiers. The figure is seated in the earth-touching pose (bhumisparsha). The teak backdrop has 2 rows of carved leaf plates and gold flames, and there is an offering table.
- Both are far under the 70k budget.
- Flicker: `flicker_check.check` runs on the exported triangles; 0 pairs of different-look faces closer than 0.05 studs. The first run found 64 pairs: the column tops sat flush with the aisle wall tops, inside the roof. Fixed by lowering the columns 0.05 m.

## Rules applied
- **Walkable insides from photos** (interiors rule). Chaukhtatgyi is open in the lower 4 m on 3 sides, as in the photos; the back has the niche wall. Ngahtatgyi has doors on the north (x2), south and west, with 2 steps each.
- **No invented text:** the red name plates on the dais are left out.
- **Buddhas:** respectful and simplified, in the pose and colours of the photos. Both have white faces and hands, gold robes, red lips and black brows. Chaukhtatgyi also has its blue lids and gold crown, and the feet are salmon pink.

## In Studio
(filled in below after placing)
