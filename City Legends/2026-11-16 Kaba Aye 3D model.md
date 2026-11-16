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
- Check picture: `Games/CityLegends/build/landmarks/kaba_aye/compare.png` (photo left, model right, same camera).

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
| Porches | 5, at bearings 43, 115, 187, 259, 331 deg | Esri z19 (the 5 covered walkways), Wikipedia (5 porches) |
| Arches | 4 between porches = 20, each with a standing gold Buddha | photo 2 |
| Windows | 1 per bay join = 15 | photo 2 |
| Merlons | 88 (~0.9 m pitch, 1.45 m tall) | photo 2 (count over the visible arc) |
| Heights (terrace 8.95, merlon top 10.7, bell 13.0-20.6, ringed cone to 23.4, petals to 25.8, bud to 27.0, hti to 30.0) | | photo 2, measured with the fitted camera |
| Porch: sign 4.9 x 0.9 m, eave 5.25-5.6 m, crest tip 10.3 m | | photo 2 |

## Parts (one Empty per sheet label, one mesh per material)
| Part | Triangles (all copies) | Notes |
|---|---|---|
| 1 hti | 2,084 | 6 tiers, mast, vane, orb, two wire fan hoops |
| 2 banana bud | 256 | |
| 3 lotus petal bands | 3,648 | 8 rings + 3 petal rows |
| 4 bell | 3,192 | profile from the photo; 3 rings + 40 hanging leaves |
| 5 bell base moulding rings | 1,728 | 4 round steps (hidden behind the merlons from the ground) |
| 6 upper terrace ring | 4,304 | roof terrace (terracotta, as on Esri), parapet, 88 merlons = 1 shared mesh |
| 7 circular hall drum | 15,506 | drum, frieze drops, cornice, arcade roof, 20 bays (3 shared meshes), 20 Buddhas (1 shared), 15 windows (1 shared) |
| 8 entrance porch | 1,965 | 5 copies of 6 shared meshes |
| 9 round base platform | 1,440 | |
| **Total** | **34,123** | 25 unique meshes, 226 mesh nodes |

Materials: `YgnGoldLeaf_Bell`, `YgnGoldPlate_Trim`, `YgnRenderPainted_White`, `YgnRenderPainted_Cream`, `YgnPaint_Red`, `YgnPaint_RoofRed`, `YgnGlassMosaic_Teal` (porch pillars, arch niches), `YgnMarbleWhite_Base`, `YgnConcreteBare_Roof`, `YgnTeakPanel_Door`, `YgnSteelPainted_Grille`. Colours measured from photo 2 (13:03).

## Rules applied
- **No interior.** The doors and arch niches are closed (niche back walls, closed teak doors). Interior photos DO exist (`Kaba_Aye_Paya_1.jpg`, `_3.jpg` in the catalogue: the central pillar with a Buddha and the shrine), so an interior is allowed later under the interiors rule.
- **No fake Burmese:** the porch's red name panel is plain.
- **No flicker / overlap (owner rule, 16 Nov):** `check_overlaps()` tests every pair of triangles in world space (instances included) for parallel faces closer than 0.02 m that overlap. Same-facing pairs (flicker) must be 0; opposite-facing pairs (hidden joints) are deleted when fully covered. Final run: 0 same-facing, 0 deletable opposite. Fixed by design: no floor faces on the platform, no bottom on the statue bases, bell/lotus/bud caps, terrace roof under the parapet, porch walls start at the arcade face, eave finials behind the pediment, plates on the pediment without backs, every trim at least 0.04 m proud (0.12 studs).

## What still differs from the photos
- Carving: the real gables, crest and merlons are deeply carved (flames, leaves). Here they are flat saw-tooth plates.
- Merlons in the photo have white strips between them, and the arch hoods have white edges. Here they are plain gold and plain red.
- The arcade's cream flame panels and the porch red field are an ogee arch in real life. Here they are triangles.
- Porch spacing: the 5 walkways on Esri are 62-80 deg apart, not exactly 72. The model uses 72, so the next porch to the right sits about 5 deg off in the photo view.
- The walkways (green roofs), lamp posts, small shrines and the stair rail on the terrace are not modelled.
- Under each porch the real front is open, with gold carving and a dark hall behind. Here there is a closed teak door.

## Next
- Place it in Studio (another step) with the materials JSON and `YangonMaterials.luau`.
