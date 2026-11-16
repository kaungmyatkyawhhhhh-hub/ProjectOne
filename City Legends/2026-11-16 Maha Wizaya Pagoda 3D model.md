---
tags: [city-legends, yangon, 3d, landmark, interior, blender]
created: 2026-11-16
---
# Maha Wizaya Pagoda: 3D model at 1:1, with its walkable hollow inside

Built in headless Blender 3.6 (not the owner's Blender) from the real photos, OSM, Esri z19 and Burmese Wikipedia. The interior (the round chamber with the blue star-sign dome, the forest wall and the central shrine) is built because real photos of it exist (interiors rule).

## Files
- Build script: `Games/CityLegends/tools/yangon/landmarks3d/maha_wizaya_blender.py`. It re-uses the Kaba Aye helpers by exec'ing `kaba_aye_blender.py`. Run it with `blender.exe -b --factory-startup --python <script> -- build` (or `render`, or `all`).
- Interior pictures, painted in code (PIL, no photo copied): `tools/yangon/landmarks3d/maha_wizaya_textures.py` writes `build/landmarks/maha_wizaya/tex/{dome,mural,leaves}.png`. The darker copies used in the game are `*_v2.png`.
- Studio placer: `tools/yangon/landmarks3d/maha_wizaya_place.luau`. Paste it into `execute_luau` after LoadAsset into `ServerStorage.MahaWizayaHolding`. It runs in `task.spawn` and reports in `_G.mwPlace`.
- Photo vs game pictures: `tools/yangon/landmarks3d/maha_wizaya_compare.py`.
- Blend file: `build/landmarks/maha_wizaya/maha_wizaya.blend`. The export goes to `imports/sync/landmarks/maha_wizaya.glb` (gitignored), with `maha_wizaya_materials.json`.

## Real sizes (sources)
| What | Value | Source |
|---|---|---|
| Total height | 169 ft = **51.5 m** (stupa to the umbrella 134 ft = 40.8 m, hti 22 ft = 6.7 m, diamond bud 13 ft = 4.0 m) | Burmese Wikipedia (မဟာဝိဇယစေတီ) |
| Base | 165 ft 8 in (50.5 m) across | Burmese Wikipedia |
| Stupa base octagon | **54 m across the flats**, flats facing N / NE / E ..., used as the cream base wall (apothem 27.4 m) | OSM way/180612556; Esri z19 measured 54.8 m |
| Compound | 104 x 104 m; marble plaza **90 x 90 m**; green-roofed gate pavilions mid-side | OSM way/160698623; Esri z19 |
| Porches | 4, at N / E / S / W. Each is **10.7 m wide** and juts out 4.5 m, with a pointed arch 4.1 m wide and 6.3 m high, horned pediment, finial at 12.3 m, and a chinthe pair | Photo `2016_Rangun_Pagoda_Maha_Wizaya_16_` (door 3 m as scale) |
| Terraces | 3 gold octagonal tiers: floors at 5.8 / 9.2 / 12.4 m, apothems 28.05 / 21.2 / 17.4. Small stupas: 8 x 6.5 m, 16 x 2.4 m, 16 x 1.8 m | Esri z19 rings and dots; photos 01 and 2013 |
| Bell | Foot **21.7 m** across at 15.7 m, top at 29.8 m; 9 rings to 38.4 m; lotus and bead bands; glass umbrella fan (6.8 m across) at 41 m; 11-tier hti to 47.3 m; vane; diamond bud tip **51.5 m** | Proportions measured on photo `Yangon_Maha_Wizaya_Zedi_Pagode_01` and `Maha_Wizaya_Pagoda.jpg` (2013, 12:49), scaled to 51.5 m; 11-tier hti (travel sources) |
| Chamber | Round, **22 m across** (r 11). Forest wall 4.85 m high, elliptical dome to 15 m, dark polished floor, 4 doorways (3.4 m wide, wood doors, gold lattice arch) at the cardinal points | Interiors catalogue (estimated 20 m) + photos 17, 20 and 21 |
| Ambulatory | Ring corridor r 13 to 17 m, 4.6 m high. 4 tunnels (4.1 m wide) out to the porches | thailex (ambulatory and tunnel entrances) |
| Shrine | Lotus basin (red petals) 8.6 m across, blue-tiled moat with grating, stepped white octagon, gold band, glass case with 8 seated gold Buddhas (white faces), white bell, gold spire to 9.6 m | Photos 19 and 21; Burmese Wikipedia (8 Buddhas) |

## Model
- **36,336 triangles** (budget about 70,000). There are 172 mesh nodes, of which about 60 are unique meshes. The largest groups: stupa 9,552, small stupas 11,840, interior 3,000, porches 2,800, shrine 1,632, canopy 1,792, Buddhas 2,480.
- **Inside:**
  - Walls: one teal forest-mural picture repeated 4 times round. There are 8 relief tree trunks, each with two limbs.
  - Canopy: one lumpy leaf band round the wall top and the dome foot, hanging lower over each trunk.
  - Dome: a pale-blue tiled dome with our own stylised star-sign figures in a ring (elephant, crocodile, horse, conch, fish, bird, rooster, house, arrow, trident, dotted constellations) round a centre lamp.
  - Floor: 12 glass donation cases and 8 carpets.
- **Checks:**
  - `check_overlaps`: 0 same-facing stacked pairs (no flicker). 166 covered hidden joint faces were deleted.
  - Ray scan (back faces and holes, from 4 inside and 5 outside points): clean, apart from a few grazing rays along shared edges.
  - Two fixes came from the scan: the dome's doorway-gap quad was wound outward at the 0/360 deg wrap, and the canopy had folds and twisted quads (each triangle is now wound to face the floor).

## In Studio (16 Nov)
- **Model asset:** **133204634351791** (v4; earlier test uploads 131269810352921, 93586094495491, 79042621145427).
- **Picture assets:** dome **123923787186968**, mural **119786845550491**, leaves **77892181944887**. Earlier, too-light uploads: 125104872553327 (failed "Invalid image"), 134984883105208, 71590794127717, 140359916646605.
- **Where it sits:**
  - `Workspace.Yangon1to1.Landmarks.MahaWizaya`: `Visual` holds 172 MeshParts (CollisionFidelity Box; CanQuery, CanCollide and CanTouch off). `Collision` holds 120 invisible parts: plaza, inside floors, chamber wall and ambulatory wall rings with doorway gaps, the base mass, porch piers, chinthe, shrine and cases. `Lights` holds 13 PointLights (NoLod).
  - `Landmarks.MahaWizayaPlate_TEMP` is a concrete plate, 336 x 336 x 6 studs, with its top at the ground.
- **Pivot:** stupa axis at **X 33902.884, Y 108.92, Z 38317.361**. That is the OSM tower centroid (96.152209, 16.794919) through `geo.world()` at 1to1, with the ground from GLO-30 `ground.py`. It is turned 180 deg (the importer's half turn). Porches face N / E / S / W.
- The site is clear of Shwedagon: its south stairway foot is about 120 m to the north-west, at about 16.7958, 96.1504.
- **Looks:**

  | Group | Material | Colour |
  |---|---|---|
  | Gold | Metal + YgnGoldLeaf | 226, 222, 245 (Kaba Aye value) |
  | Cream | SmoothPlastic | 246, 236, 192 |
  | White | SmoothPlastic | 255, 255, 250 |
  | Plaza | Marble + YgnMarbleWhite | |
  | Chamber floor | SmoothPlastic | 44, 46, 46 |
  | Gate roofs | Metal + YgnCorrugatedZinc | 50, 100, 75 |

  The textured dome, mural and leaves use **Fabric**: SmoothPlastic put a moving specular streak on the dome.
- **Traps found:**
  - **A MeshPart's Color does not tint its TextureID.** Darken the picture itself (the `_v2` pictures are x0.55-0.86).
  - **Kaba's `export()` scales mesh data but not object locations.** Instanced pieces placed by `location` came in at metres. `export_scaled()` fixes this.
  - The first dome upload failed in Studio ("Invalid image or texture", HTTP 502). Re-uploading with one pixel changed worked.
- **Pictures** (PlayLight 13), all in `Games/CityLegends/build/landmarks/maha_wizaya/`:
  - Photo vs game: `compare_outside.jpg`, `compare_porch.jpg`, `compare_inside.jpg`, `compare_dome.jpg`.
  - Studio shots: `ingame_outside_sw.jpg`, `ingame_porch_south.jpg`, `ingame_porch_tunnel.jpg`, `ingame_inside_shrine.jpg`, `ingame_dome.jpg`.
  - Grazing checks: `ingame_base_graze.jpg`, `ingame_porch_graze.jpg`. No flicker seen.
- The place was not saved and Play was not started.

## What still differs from the photos
- **Carving:** porches, pediment and terrace edges are plain plates. There is no carved relief, no green leaf row on the gable, and no flame / finial rows along the terrace edges. The chinthe are block stand-ins.
- **Gold lattice:** the gold lattice doors and tympanum are a green panel with a gold rosette and spokes, not the real fretwork.
- **Inside light and colour:**
  - The chamber is brighter and paler than the photos: the real one is dim teal and lit by floodlights.
  - The floor reads mid grey, not near-black polished stone.
  - The trees are low-poly tubes, without the photos' plastic-leaf relief and hanging aerial roots.
- **Dome:** the figures are our own simple shapes, so they differ from the real 38 star-sign reliefs (on purpose: no copying). The real figures are raised plaster; ours are flat.
- **Not built:**
  - the ambulatory's niches with bronze Buddhas and the carved panels;
  - the 8 side chambers;
  - the outer-hall showrooms;
  - the floodlights and lamp fixtures;
  - the compound's fence, trees and the U Htaung Bo Road arch gate (photo exists: `The_entrance_gate_of_Mahah_Vijaya_Pagoda_in_the_afternoon.jpg`).
- **Unmeasured / estimated:**
  - Terrace heights and the bell profile are photo estimates scaled to the published 51.5 m.
  - Chamber size is an estimate (22 m).
  - The gate pavilions' size comes from Esri only.
- **Ground:** the plate is temporary (no 1:1 terrain yet). The real site sits on Dhammarakkhita hill, and GLO-30 rises about 1.3 m across the plaza.

## Ornament kit pass (16 Nov)
- Porches: carved kit flames (bevelled, 0.1 m proud, tongues both sides) along both pediment slopes instead of the flat zigzag, and a carved kit flame finial at the pediment's centre.
- Terraces: rows of carved flames (`flame_blade` micro) along all three terrace edges, clear of the porches ([[2026-11-16 Burmese ornament kit]]).
- 56,469 triangles (budget 70,000); overlap check 0 same-facing pairs. Asset **132275924726216**, placed with `maha_wizaya_place.luau` (replaces; collision and lights rebuilt). Gold unchanged (Metal + YgnGoldLeaf).
- ![[Ornament kit - Maha Wizaya photo before after.jpg]]
