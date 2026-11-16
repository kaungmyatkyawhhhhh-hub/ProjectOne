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
- **Chaukhtatgyi (v3):**
  - 23,482 triangles, 21 meshes, 0 flicker pairs.
  - The shed has 48 steel columns, 12 nave trusses, aisle rafters, a clerestory window band, gable walls and a green roof with a white ceiling.
  - The dais is glass mosaic with a white lip. There are 2 railings (spikes and lamps) and a 94 m niche wall (about 120 niches).
  - The figure is a robe loft for the torso and legs, plus a head, neck, gold crown band, black hair cap, ears with pink insides, eyes, lids, brows, nose, nostrils, lips, both arms and hands, a cushion, two stacked feet with 10 toes, and the sole grids and wheels.
- **Ngahtatgyi (v2):**
  - 9,806 triangles, 18 meshes, 0 flicker pairs.
  - The hall has walls with 4 doors and steps, a glass-block band, a skirt roof, a clerestory with a skylight band and a gable roof.
  - There are 26 mirror columns, white girders, rafters and trusses, and the five-tier tower.
  - The throne has 3 tiers. The figure is seated in the earth-touching pose (bhumisparsha). The teak backdrop has 2 rows of carved leaf plates and gold flames, and there is an offering table.
- Both are far under the 70k budget.
- Flicker: `flicker_check.check` runs on the exported triangles; 0 pairs of different-look faces closer than 0.05 studs. The first run found 64 pairs: the column tops sat flush with the aisle wall tops, inside the roof. Fixed by lowering the columns 0.05 m.

## Rules applied
- **Walkable insides from photos** (interiors rule). Chaukhtatgyi is open in the lower 4 m on 3 sides, as in the photos; the back has the niche wall. Ngahtatgyi has doors on the north (x2), south and west, with 2 steps each.
- **No invented text:** the red name plates on the dais are left out.
- **Buddhas:** respectful and simplified, in the pose and colours of the photos. Both have white faces and hands, gold robes, red lips and black brows. Chaukhtatgyi also has its blue lids and gold crown, and the feet are salmon pink.

## In Studio (16 Nov)
**Where:**
- `Workspace.Yangon1to1.Landmarks.Chaukhtatgyi`: `Visual` = 21 MeshParts, `Collision` = 55 invisible parts.
- `Workspace.Yangon1to1.Landmarks.Ngahtatgyi`: `Visual` = 18 MeshParts, `Collision` = 47 invisible parts.
- Plates: `Landmarks.ChaukhtatgyiPlate_TEMP` (300 x 156 studs, turned with the shed) and `Landmarks.NgahtatgyiPlate_TEMP` (228 x 192 studs). Both are concrete, 6 studs thick, top at the GLO-30 ground.

**Assets (Open Cloud Models, group 33151111):**

| | Asset id |
|---|---|
| Chaukhtatgyi v3 (live) | **129397555354535** |
| Chaukhtatgyi v2 | 110006804909642 |
| Chaukhtatgyi v1 | 112316935260997 |
| Ngahtatgyi v2 (live) | **117322729142436** |
| Ngahtatgyi v1 | 130568123838143 |

v2 fixed three things:
- `face()` built off-plane triangles (the top tier of Ngahtatgyi's tower showed two peaks, and the railing spikes leaned).
- The big floors were 2 long triangles, which showed a light seam line in Studio. They are now tiled.
- Ngahtatgyi's shoulders slope.

v3 gave Chaukhtatgyi bigger eyes, smaller lips, nostrils, pink inner ears and a black hair cap.

**How it was placed:**
- Pivots: Chaukhtatgyi X 37635.06, Y 69.98, Z 32763.72 (shed axis 122.3 deg); Ngahtatgyi X 37211.85, Y 73.36, Z 33831.02 (axis-aligned).
- No 180 degree turn was needed: `glb.py` writes x and z negated, and each part is placed at the box encoded in its name.
- Visual meshes have CollisionFidelity Box and CanQuery / CanCollide / CanTouch off. Holding folders were deleted. The place was not saved and Play was not started.

**Looks:**
- Gold: Metal + YgnGoldLeaf (226, 222, 245).
- Skin: SmoothPlastic (255, 255, 250).
- Mosaic: Foil (150, 160, 140).
- Corrugated walls and roofs: Metal + YgnCorrugatedZinc.
- Teak: Wood.
- The rest is SmoothPlastic in photo colours. The full table is `LOOK` in `bahan_buddhas3d.py`.

**Pictures** (PlayLight 13, camera set, then 4 s), in `Games/CityLegends/build/landmarks/`:
- `chaukhtatgyi/compare_face.png`, `compare_feet.png` (photo | in game)
- `chaukhtatgyi/ingame_inside.jpg`, `ingame_aerial.jpg`
- `chaukhtatgyi/ingame_niche_graze.jpg` (grazing check, no flicker)
- `ngahtatgyi/compare_buddha.png`, `compare_hall.png`, `compare_outside.png`
- `ngahtatgyi/ingame_roof_graze.jpg` (grazing check along the eaves, no flicker)

## What still differs from the photos
- **Ngahtatgyi figure proportions.** The torso is a tall straight barrel. In the photo, the shoulders are broader and slope, the chest is shorter, and the knees spread wider than the shoulders. The crown and face also read smaller than in the photo. The robe has none of the gold jewelled bands, the collar or the bare white chest V. This is the first thing to fix next.
- **Chaukhtatgyi face.** It is simplified: an egg-shaped head with added features. The real face has deep carved eye sockets, a long nose ridge and fuller cheeks. The robe has no folds and no maroon border.
- **Gold reads orange-yellow and grainy** with the settled YgnGoldLeaf. In the photos, Chaukhtatgyi's robe is a paler satin gold.
- **Sole marks.** The 108 marks are a plain gold grid with a wheel; the real cells hold small figures (animals, palaces).
- **Teak backdrop.** The carving is flat leaf plates in two rows, not deep scroll relief, and there is no carved canopy beam.
- **Ngahtatgyi outside:**
  - The walls follow the bbox rectangle (72 x 58 m); OSM has 3 m notches on the north-west and east.
  - The covered stairway up from Shwegondaing Road is not built.
  - The tower tiers are square hips; the photo shows stacked gables.
  - Which way the Buddha faces is a guess (west, down the nave, under the tower in the east half).
- **Chaukhtatgyi outside:**
  - The covered walkways, the main door on the north-east side and the car park are not built (see the site audit).
  - The head-to-the-south-east direction comes from one secondary source.
- **Not built in either hall:** the bell, the small shrines, the display cases, the peacock seat and the lamps.
- **Ground.** Both stand on flat `_TEMP` plates. The GLO-30 ground varies by about +/-4 studs across Chaukhtatgyi, so the plates will need replacing by the 1:1 terrain.

## Figures v2: rebuilt in Blender from turnaround sheets (16 Nov)
The coordinator rejected the first figures: they "read crude / cartoonish", which is disrespectful for sacred images. Both figures were rebuilt.

**Turnaround sheets** (ChatGPT in the owner's Chrome, with the real photos attached, "copied exactly"; full-res capture trick):
- `Games/CityLegends/imports/refs/exploded/chaukhtatgyi/chaukhtatgyi_turnaround_v1.png`: front, top, feet-end, head front and head side views.
- `Games/CityLegends/imports/refs/exploded/ngahtatgyi/ngahtatgyi_turnaround_v1.png`: front, left side, back, top, head front and head side views.
- What the sheets showed: Chaukhtatgyi's head rests on the right hand, with the forearm up from the elbow at the head end. Ngahtatgyi has a short chest, its knees are wider than its shoulders, and it has a short neck with neck rings.

**Model:** `Games/CityLegends/tools/yangon/landmarks3d/buddha_figures_blender.py`, run in headless Blender 3.6 with `-- chauk|ngah <out.json>`.
- **Forms:** smooth metaball shells for the head, neck, arms, hands, feet and lap, converted to meshes. Chaukhtatgyi's body is a smoothed loft with drapery folds and the robe flaring onto the dais.
- **Face:** "sculpt" brushes (gaussian displacement along the normal) for the eye sockets, nose ridge and tip, lips, chin and cheeks.
- **Paint:** eyes, liner, blue lids, brows, lips, hair, the maroon border and the jewelled bands are colour regions on the same surface.
  - Edges where the paint changes are split until the outlines are crisp. `bmesh subdivide_edges` re-fans the faces, so there are no T-junctions.
  - Nothing is stacked on the skin, so nothing can flicker.
- **Extras:**
  - Chaukhtatgyi: a crown band placed on the real head surface by ray casting, with jewels and the lashes.
  - Ngahtatgyi: a tiered crown with a ring of jewels, and flame leaves by the head, on the shoulders and at the elbows.
- **The soles** are cut flat at u = 65. The old gold grid and wheel sit on them.
- **Mirror trap:** the Chaukhtatgyi frame (x = 34 - u) is a mirror, so its triangles are turned over (`MIRROR`). Without that, the first build showed the back of the head from the front.

**Output:**
- The figure is written to `build/landmarks/figures/<chauk|ngah>_fig.json`. `bahan_buddhas3d.add_figure` loads it into the hall model.
- The .glb shares corners on the smooth figure meshes (`solid3d.DMesh`), so the files are 2.7 / 1.8 MB. At 5.8 MB, the Open Cloud upload through the MCP timed out.
- Shape checks: `tools/yangon/landmarks3d/fig_preview.py` (Workbench renders).

**Triangles:**

| | Figure | Whole hall |
|---|---|---|
| Chaukhtatgyi | 37,872 | 50,944 |
| Ngahtatgyi | 43,744 | 47,841 |

0 flicker pairs in both halls.

**Gold:** the paler satin gold of the photos, measured on the lit photo d02 (208, 185, 133).
- Robe FGO: SmoothPlastic (204, 164, 86), reflectance 0.12.
- Bands, crowns and flames FGB: (222, 172, 64), reflectance 0.18.
- No YgnGoldLeaf grain on the figures.
- Skin: (240, 238, 232), reflectance 0.15.
- Black: reflectance 0.04 (with 0.2 the glass eyes mirrored the sky grey).
- The figure meshes are RenderFidelity Precise.

**In Studio:**

| | Live asset |
|---|---|
| Chaukhtatgyi v5 | **102279438796873** |
| Ngahtatgyi v4 | **135129652866498** |

The Visual folders were swapped, and collision and plates are unchanged. Older ids: 106510845884457, 108986933874388.

**Pictures**, in `Games/CityLegends/build/landmarks/`:
- `chaukhtatgyi/compare_face_v2.png`, `compare_face_sheet_v2.png`, `compare_feet_v2.png`, `ingame_inside_v2.jpg`
- `ngahtatgyi/compare_buddha_v2.png`, `compare_face_v2.png`, `compare_face_sheet_v2.png`

**Still differs (honest):**
- **Chaukhtatgyi face:** still simpler and flatter than the photo and the sheet. Studio's flat light hides the sculpted forms (nose, cheeks).
  - The eyes read as flat black almonds with lashes. The photo has a glossy glass eye with a highlight, a thicker winged liner and a fuller blue lid.
  - The head-on-hand pose is close, but the head is not turned three-quarters as in the sheet.
  - Next step: a darker grey shading paint in the eye sockets and under the nose, a white highlight in each glass eye, and a stronger nose ridge.
- **Ngahtatgyi:** the proportions and face now follow the sheet. Missing: the jewelled collar and the chest-band filigree (the bands are plain raised gold), the shoulder flaps, the crown's filigree tiers, and the carved scrolls on the flame leaves.
- **Both:** the robe folds are procedural ripples, not the sheet's sculpted drapery.
