---
tags: [city-legends, yangon, 3d, landmark, blender]
created: 2026-11-16
---
# Kaba Aye Pagoda: 3D model (1:1 pilot)

Built in the owner's Blender (3.6, Blender MCP) from the exploded sheet ([[2026-11-16 Exploded diagrams for Yangon 3D models]]) and the real photos. **Photos win over the sheet.**

## Files
- Build script (rebuilds everything): `Games/CityLegends/tools/yangon/landmarks3d/kaba_aye_blender.py`
  - In Blender: `exec(open(r".../kaba_aye_blender.py").read()); build(); check_overlaps(fix=True); check_overlaps(fix=False); export()`
  - `set_photo2_fit(); render_compare(out_png, PHOTO2)` makes the photo vs model picture.
- Camera fit for photo 2: `Games/CityLegends/tools/yangon/landmarks3d/kaba_aye_camera_fit.py` (14 points, rms 40 px).
- Blender file: `Games/CityLegends/build/landmarks/kaba_aye/kaba_aye.blend` (collection `KabaAye`).
- Export: `Games/CityLegends/imports/sync/landmarks/kaba_aye.glb` (gitignored, rebuild with `export()`), plus `kaba_aye_materials.json` (colour per material, because the importer drops base colours).
- Check picture: `Games/CityLegends/build/landmarks/kaba_aye/compare.png` (photo | v1 | v2, same camera).

## Scale and axes
- Modelled in metres; the .glb is written at **1 m = 3 studs** (34 m = 102 studs high, 46.4 m = 139 studs across).
- Pivot = base centre, ground = 0. Blender +Y = north; in the .glb (+Y up) north is -Z. Roblox's importer turns a .glb half a turn: the placer must allow for that.
- UVs: box projection, 1 UV unit = 1 stud, so `Ygn*` MaterialVariants tile at real size.

## Real sizes used (sources)
| What | Value | Source |
|---|---|---|
| Height to the vane tip | 34 m | Wikipedia (111 ft = 33.8 m; another line says 117 ft 6 in) |
| Bell base | 10.0 m across | Wikipedia "111 ft round the base" (10.8 m); Esri z19 ~9-10 m; photo ~9.5 m |
| Roof terrace / merlon ring | 25.6 m across | Esri z19: red-brown disc 24.6 m |
| Arcade ring (arches) | 35 m across | Esri z19 dark ring ~35 m |
| Base platform | 46.4 m across, 1 m high, 4 steps | sheet part 9; OSM's 105 m circle is the whole plaza, not modelled |
| Porches | 5, at bearings 33, 112, 191, 261, 322 deg (79, 79, 70, 61, 71 apart) | Esri z19 walkway spokes measured at radii 28/34/40 m (v2); Wikipedia (5 porches) |
| Covered walkways | 5, 6 m wide, from each porch out to r 52 m (the plaza edge), eave 3.0 m, ridge 3.8 m | Esri z19 spokes; photo 2 (teal roof, gold fringe) |
| Arches | 4 between porches = 20, each with a standing gold Buddha | photo 2 |
| Windows | 1 per bay join = 15 | photo 2 |
| Merlons | 88 (~0.9 m pitch, 1.45 m tall) | photo 2 (count over the visible arc) |
| Heights (terrace 8.95, merlon top 10.7, bell 13.0-20.6, ringed cone to 23.4, petals to 25.8, bud to 27.0, hti to 30.0) | | photo 2, measured with the fitted camera |
| Porch: sign 4.9 x 0.9 m, eave 5.25-5.6 m, crest tip 10.3 m | | photo 2 |

## Parts, v2 (one Empty per sheet label, one mesh per material)
| Part | Triangles (all copies) | Notes |
|---|---|---|
| 1 hti | 2,084 | 6 tiers, mast, vane, orb, two wire fan hoops |
| 2 banana bud | 256 | |
| 3 lotus petal bands | 3,648 | 8 rings + 3 petal rows |
| 4 bell | 3,192 | profile from the photo; 3 rings + 40 hanging leaves |
| 5 bell base moulding rings | 1,728 | 4 round steps (hidden behind the merlons from the ground) |
| 6 upper terrace ring | 7,912 | roof terrace, parapet, 88 two-layer leaf merlons (1 shared mesh), 88 white posts between them |
| 7 circular hall drum | 25,564 | drum (white), red drops on gold cartouches, gold band + cornice, arcade roof; 20 bays (5 shared meshes, scaled per sector), 20 Buddhas, 15 windows and 15 curled leaf panels (shared), red steel stair |
| 8 entrance porch | 3,905 | 5 copies of 7 shared meshes |
| 9 round base platform | 1,440 | |
| 10 covered walkway | 2,020 | 5 copies of 3 shared meshes (not on the sheet; photo + Esri) |
| **Total** | **51,749** | 35 unique meshes, 318 mesh nodes |

v1 (first pass) was 34,123 triangles: flat saw-tooth gables, closed doors, even 72 deg porches, no walkways.

Materials: `YgnGoldLeaf_Bell`, `YgnGoldPlate_Trim`, `YgnRenderPainted_White` (drum wall, hood edges, posts: really white in the photo), `YgnRenderPainted_Cream` (cream-yellow 238,228,168 for the arcade and the carved panels, re-measured on the lit panels), `YgnRenderPainted_Mint` (pale green panel outlines), `YgnPaint_Red`, `YgnPaint_Maroon` (name panel), `YgnPaint_RoofRed`, `YgnPaint_DarkHall`, `YgnGlassMosaic_Teal`, `YgnMarbleWhite_Base`, `YgnConcreteBare_Roof`, `YgnSteelPainted_Grille`, `YgnSteelPainted_Red`, `YgnCorrugatedZinc_Green`.

## v2 detail pass (16 Nov)
- **Carved silhouettes:** the arch panels are rows of finger boards with pointed tops (deep notches) stepping up to a raised centre leaf: a pale green back layer (0.1 m) under a cream layer (0.1 m), red buds on the side fingers. The porch crest is 4 layers: red backboard, gold fingers (7 a side + centre), gold ogee frame, red ogee field with the gold sun disc, plus gold scrolls at the eave ends. Merlons are two-layer gold leaves (0.08 + 0.06 m) with white posts between them. Curled leaf panels stand over each bay join.
- **Porch front:** open, with full-height gold jambs, a gold scalloped valance under the plain name panel and a dark hall behind. That hall is a closed recess 1.4 m deep (no walk-in).
- **Arch hoods:** white inner edge, red scalloped band, white outer edge.
- **Porch bearings from Esri;** the bays between two porches are one shared mesh scaled across (x scale 0.80-1.15 per sector, edges exactly on the 17.5 m circle so neighbours meet).
- **Walkways and stair:** a green-roofed walkway runs to each porch, and a red steel stair with rails goes up the drum to the terrace (right of porch 191, as in photo 2).
- The photo camera was refitted for porch 191 (rms 40 px).
- Overlap check v2: 0 same-facing stacked pairs; 170 fully covered hidden joint faces deleted; 50 partial back-to-back pairs left (not visible, no flicker).

## Rules applied
- **No interior.** The porch halls (dark closed recesses) and arch niches are closed. Interior photos DO exist (`Kaba_Aye_Paya_1.jpg`, `_3.jpg` in the catalogue: the central pillar with a Buddha and the shrine), so an interior is allowed later under the interiors rule.
- **No fake Burmese:** the porch's red name panel is plain.
- **No flicker / overlap (owner rule, 16 Nov):** `check_overlaps()` tests every pair of triangles in world space (instances included) for parallel faces closer than 0.02 m that overlap. Same-facing pairs (flicker) must be 0; opposite-facing pairs (hidden joints) are deleted when fully covered. v1 final run: 0 same-facing, 0 deletable opposite. Fixed by design: no floor faces on the platform, no bottom on the statue bases, bell/lotus/bud caps, terrace roof under the parapet, porch walls start at the arcade face, eave finials behind the pediment, plates on the pediment without backs, every trim at least 0.04 m proud (0.12 studs).

## What still differs from the photos (after v2)
- Carving depth: the panels, crest and merlons are layered cut-out plates, without the real relief (leaves, scrolls, the heart band under the eave).
- The red ogee field and the panels have no gold scroll leaves inside them, and the hoods' bricks are one red.
- The porch interior hall is a dark closed recess. The real hall exists and has photos (`Kaba_Aye_Paya_1.jpg`, `_3.jpg`), so it can be built later.
- Not modelled: lamp posts, small shrines on the plaza, the plaza itself (OSM 105 m circle) and the walkway floors.
- Bays are scaled per sector (x 0.80-1.15). In Studio check that the importer keeps the node scale, because the glb carries it on those 20 bays.
- Porch walls between the walkway roof and the eave: the walkway roof meets the porch below the name panel. That is right for photo 2, but not checked against the other porches' photos (none).

## In Studio (16 Nov, look check)
- Asset **103708452636713** (Open Cloud Model, group 33151111). `Workspace.Yangon1to1.Landmarks.KabaAye` (`Visual` = 318 MeshParts, `Collision` = 11 invisible parts) + `Landmarks.KabaAyePlate_TEMP` (concrete cylinder 315 across, 6 thick, top at the ground). Place version 974.
- Pivot (base centre) at **X 34625.66, Y 77.30, Z 17793.07** (OSM centre lon 96.15447, lat 16.85681 through `geo.world()` at 1to1; ground from GLO-30 `ground.py`, flat within 0.3 studs over the plaza). Turned 180 deg (the importer's half turn): porches at 33 / 112 / 191 / 261 / 322 deg from north, stair at 180.
- **Arch stretch survived:** the importer bakes each node into its own mesh (318 unique meshes, no rotation). Measured bay widths 13.09 / 11.05 / 9.00 / 11.28 studs = 11.49 x 1.139 / 0.96 / 0.782 / 0.98. No re-export needed.
- Visual meshes: CollisionFidelity Box, CanQuery / CanCollide / CanTouch off. Collision: platform as 4 steps (0.75 each, r 69.6 -> 66.5), arcade cylinder r 51.9 to 16.7, drum r 37 to 32.1, a box per porch.
- Materials: gold Metal + YgnGoldLeaf / YgnGoldPlate (colours nudged yellower: bell 232,204,146, trim 218,186,122), white / cream / mint / paints Plaster + YgnRenderPainted, teal Foil + YgnGlassMosaic, platform Marble + YgnMarbleWhite, roof Concrete + YgnConcreteBare, steel Metal + YgnSteelPainted, walkway roofs Metal + YgnCorrugatedZinc. Colours from `kaba_aye_materials.json`.
- Pictures (PlayLight 13): `build/landmarks/kaba_aye/ingame_compare.png` (photo | Studio, photo 2 camera fit), `ingame_photo_view.jpg`, `ingame_aerial.jpg`, `ingame_porch_graze.jpg`, `ingame_porch_graze2.jpg`. No flicker seen at grazing angles.
- Looks wrong / to fix: gold reads orange and the YgnGoldPlate tile grid shows on every trim (reads like tiles, not carving); the arch niches' teal mosaic reads dark grey-green, not glittering glass; the cream bays and white drum render darker and yellower than the photo; the porch roofs and terrace (RoofRed) read salmon pink; Buddhas are plain cones from the ground.

## In Studio: look pass v2 (16 Nov, against photo 2, PlayLight 13)
Settled values (photo sample -> what renders, same camera):
| Group | Material | Color | Rendered vs photo |
|---|---|---|---|
| All gold (bell, lotus, bud, hti, trims, crests, merlons, Buddhas) | Metal + **YgnGoldLeaf** (no more YgnGoldPlate grid) | 226, 222, 245 | bell 231,208,143 vs 229,210,163; merlons 204,172,109 vs 193,161,121 |
| Glass mosaic (arch vaults, porch sides) | Foil, no variant, Reflectance 0.2 | 150, 160, 140 | 156,167,141 vs 144,148,127 (silvery green, sparkles) |
| Cream bays | SmoothPlastic | 236, 219, 148 | 205,191,142 vs 201,191,144 |
| White (drum, hood edges, posts) | SmoothPlastic | 255, 255, 250 | |
| Mint panel outlines | SmoothPlastic | 196, 214, 168 | |
| Terrace + porch roofs (RoofRed) | SmoothPlastic | 96, 42, 32 | reads muted red-brown (was salmon) |
| Walkway roofs | Metal + YgnCorrugatedZinc | 78, 140, 140 | 105,134,127 vs teal 90,125,122 |
Tried and dropped: gold as SmoothPlastic + Reflectance (reads flat cream, plastic) and plain Metal (khaki). Gold Color barely moves the YgnGoldLeaf texture's hue; the bluish tint is what pulls it from orange to yellow-gold. Up-facing faces render far lighter than their colour in this light (pure green rendered 120,240,120), so roofs need dark colours.
- **Buddhas:** the 20 cone stand-ins were replaced by one figure mesh (asset **127278276050216**, `tools/yangon/landmarks3d/kaba_aye_buddha_glb.py`: octagon pedestal + lathe figure with robe, shoulders, neck, head, ushnisha; 744 tris, same 2.3 x 6.5 footprint, no bottom faces), cloned into each niche facing out. Part count unchanged (329). Place version 976.
- Pictures: `build/landmarks/kaba_aye/ingame_compare_v2.png`, `ingame_photo_view_v2.jpg`, `ingame_buddha_v2.jpg`, `ingame_bay_graze_v2.jpg` (no flicker).
- Still differs: crests and merlons are flat cut-outs, no relief (the photo's gold reads by its shadows); bays are flat cream with no column / panel detail; the photo camera fit sits slightly off to the left.

## Next
- Place it in Studio (another step) with the materials JSON and `YangonMaterials.luau`.

## Ornament kit pass (16 Nov)
The flat cut-out plates were replaced with the carved kit ([[2026-11-16 Burmese ornament kit]]), in `kaba_aye_blender.py` (built headless: `blender -b --factory-startup --python-expr "exec(...); build(); check_overlaps(fix=True); export()"`):
- **Porch gable:** `gable_frame(6.9, 4.0)` (red board, gold ogee frame 0.1 m proud, flame fingers, apex flame, raised sun disc with rays and boss, eave-end scrolls) + `gable_fingers` (the stepped skyline, 6 a side + the centre).
- **Merlons:** `merlon_leaf(1.45, 0.6, lo)` x 88 (lobed leaf 0.09 m, raised inner leaf, spine).
- **Arch hoods:** `arch_hood` (scalloped red band 0.1 m proud, raised white rim 0.14 m).
- **Leaf panels:** a kit leaf in cream on a mint backing leaf.
- 59,904 triangles (was 51,749); overlap check 0 same-facing pairs. Asset **105750762375498**, swapped in Studio with `VisualSwap.luau` (318 parts, looks copied by name, Collision kept). Gold looks unchanged (Metal + YgnGoldLeaf 226, 222, 245).
- ![[Ornament kit - Kaba Aye photo before after.jpg]] ![[Ornament kit - Kaba Aye porch grazing check.jpg]] (no flicker at grazing angles)
- Still differs: the photo's porch crest is a dense wall of small fingers; ours has fewer, bigger pieces.
