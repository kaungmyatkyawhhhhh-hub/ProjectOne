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

## Next
- Place it in Studio (another step) with the materials JSON and `YangonMaterials.luau`.
