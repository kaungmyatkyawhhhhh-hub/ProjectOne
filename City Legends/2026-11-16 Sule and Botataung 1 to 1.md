---
tags: [city-legends, yangon, 3d, landmark, 1to1]
created: 2026-11-16
---
# Sule Pagoda and Botataung Pagoda: 3D models (1:1)

Both built in pure Python (no Blender), at 3 studs a metre, placed in Studio under `Workspace.Yangon1to1.Landmarks.Sule` and `.Botataung` at their real spots. Photos win over any sheet (no exploded sheet was used).

## Files
- Shared code: `Games/CityLegends/tools/yangon/landmarks3d/pagoda_lib.py` (lathes, wire fans, export with names that carry the centre, templates, flicker test, scene dump).
- Sule: `tools/yangon/landmarks3d/sule3d.py`. Botataung: `tools/yangon/landmarks3d/bota3d.py`. Run from `Games/CityLegends`: `python tools/yangon/landmarks3d/sule3d.py` (writes `imports/sync/landmarks/sule.glb` + `build/landmarks/sule/place.json` + `scene.json`).
- Check renders (Blender 3.6 headless, back faces culled): `tools/yangon/landmarks3d/preview_pagoda_blend.py` -> `build/landmarks/<x>/preview/`.
- Studio: `tools/yangon/landmarks3d/PagodaPlace.luau` (look per group, template instances, invisible collision, lights, TEMP plates); `make_place_run.py <sule|botataung> <asset id>` makes the one-call `execute_luau` body (`build/landmarks/<x>/place_run.luau`).
- New references (Commons, licences in `sources.json`): `build/landmarks/botataung/refs/` (9 photos: the whole stupa before and during the 2018 renovation, the gate pavilion, the shrine hall).

## Real sizes used (sources)
### Sule
| What | Value | Source |
|---|---|---|
| Height | 44.1 m from the street | Wikipedia (144 ft 9.5 in) |
| Stupa base | octagon 34.4 m across the flats (corner radius 18.6 m), turned -8 deg | OSM way/477836654 |
| Roundabout island | the ring's outer face = OSM grounds way/131745510 (94 x 85 m), 3.5 m pavement round it | OSM |
| Ring of shops | 8 m deep; shops at street level 2.7 m with sign fascia to 3.6 m; white upper storey with a blue band and windows to 5.8 m; roof skirt to 6.6 m | photo 1 (Maha Bandula Park), measured at ~37 px a metre |
| Platform | 3.6 m over the street, on top of the shops; 4 stair halls (N, E, S, W) 8 m wide, 20 steps | photos 1, 8 (gates' bearings not checked) |
| Stupa shape | 9 octagonal terraces (34.4 -> 16 m), octagonal bell 15 m across with 8 gold cartouches, round from the shoulder: 4 rings, inverted bowl, lotus, banana bud ~2 m, wire fan ~6 m, 9-tier hti to 42 m, vane, orb | photos 1, 6, 8 (photo 1: bell ~10.5 m across at 17 m, bud ~2 m) |
| Gates | seven-tier green and gold pyatthat over each stair hall | photo 6 |
| Shrines | 8 yellow-tiled rooms 4 x 4 x 4.2 m on the stupa's faces, door out, mint inside, seated Buddha, gold zedi on the roof; 8 gold zedis 7.5 m at the corners | photos 8, 10; interiors catalogue (shrine rooms) |

### Botataung
| What | Value | Source |
|---|---|---|
| Height | 40.1 m from the ground | Wikipedia (131 ft 8 in) |
| Base | octagon 27.6 m across the flats, 29.9 across the corners (corners at the cardinal points) | Wikipedia (96 ft base), OSM way/180605242 (29 x 28 m) |
| Stupa shape | hollow base storey 3.6 m, 7 octagonal terraces, round bell with one raised band, 4 rings, bowl, lotus, bud, 7-tier hti, two wire fans | Commons 2013 "pagoda", 2014 0310, 2018 renovation |
| Inside | zigzag corridor 1.7 m wide, 2.5 m high, right-angle turns round the relic chamber; gilded walls and ceiling, parquet floor; glass window onto the chamber (mosaic walls, gold relic stupa); door with a gold frame and 3 red-edged steps | interiors: Room_Inside_Paya, Yangon-Botataung-20-Eingang, Treasures (2013) |
| Fence | square 41 m: yellow tiled wall 1.3 m, pillars to 3.35 m, gold grilles, a 4 m gate in each side; 4 gold zedis in the corners, 4 white kiosks | 2013 photo |
| Compound | OSM way/314136068 (103 x 214 m), white paving 0.3 m over the ground | OSM |
| Pond | OSM way/314136067 (25 x 24 m, 40-62 m south of the stupa); water 1.4 m under the paving; walkway on stilts along the north and west sides (maroon side, yellow rails, red roofs with a gold crest), a gold pyatthat at their corner, a steel fountain ring | photo "pond" |
| Gate pavilion | north edge of the compound: white hall 15 x 8 m, gold gable to 10 m with a stepped crest, walk-through door 4 x 5 m, side arches, red dado | Commons Konsek 2016 (01-03) |
| Jetty | Botahtaung jetty: OSM pier way/395058306 (two 3.5 m arms 70 m out, a 71 x 10 m end deck with a zinc shed), concrete embankment along the bank, river 3 m under the ground | OSM |

## Triangles, assets, Studio
| | Sule | Botataung |
|---|---|---|
| Site meshes (unique) | 8,317 tris, 15 MeshParts | 8,117 tris, 19 MeshParts |
| Templates (instanced) | pyatthat 422 x4, shrine 108 x8, zedi 380 x8, zedibig 380 x8, Buddha 904 x8 | zedibig 380 x4, kiosk 204 x4, pyatthats 370 x1 |
| Whole scene | 24,181 tris (99 MeshParts) | 10,823 tris (38 MeshParts) |
| Model asset (in use) | **127976774273216** (v3) | **113165297225899** (v2) |
| Collision | 165 invisible parts (ring raster, platform, 4 ramps, shrine walls, 8 cylinder drums) | 213 (paving raster, corridor walls, door ramp, fence, decks, gate, jetty, drums) |
- Older uploads (not used): Sule 130382001638172 (v1, dome bell) and the v2 upload; Botataung 101018967403743 (template names with "_" broke the placer: `zedi_big` was read as `zedi`).
- `Workspace.Yangon1to1.Landmarks.Sule` pivot = stupa centre **X 35993.22, Z 45130.83, ground Y 18.47** (OSM centroid 96.158748, 16.774373 through `geo.world()` at 1to1, GLO-30 ground). `SulePlate_TEMP` 540 x 540 studs, top at 18.47 (GLO-30 varies 14.6-26.7 studs over the island: flat for now).
- `Landmarks.Botataung` pivot **X 40224.41, Z 47091.69, ground Y 18.71** (96.171984, 16.76846). `BotataungPlate_TEMP` = 4 parts round the pond (x -92..68 m, y -187..75 m), `BotataungRiver_TEMP` 1260 x 450 studs, top 9.71 (river 3 m under the ground).
- Each model: `Visual` (MeshParts, look per group, CollisionFidelity Box, CanQuery / CanCollide / CanTouch off; template copies in sub-Models), `Collision` (invisible Blocks, WedgePart ramps, cylinder Drums), warm PointLights (Botataung corridor 9, Sule shrines 8). Placer `ServerStorage.ClaudeTools.PagodaPlace` (`run`, `place`, `fidelity`, `plate`). Place not saved; no Play.
- Ramps checked by raycast (Sule south gate 19.45 -> 29.21 studs, Botataung door 19.61 -> 21.41).
- Pictures (PlayLight 13): `Games/CityLegends/build/landmarks/sule/compare_park.jpg` (photo 1 | game), `compare_platform.jpg` (photo 8 | game), `ingame_facade_graze.jpg`, `ingame_aerial_v1bell.jpg`; `build/landmarks/botataung/compare_stupa.jpg` (2013 photo | game), `compare_pond.jpg`, `compare_corridor.jpg`, `compare_gate.jpg`, `ingame_jetty.jpg`, `ingame_aerial.jpg`. Blender check renders in `build/landmarks/<x>/preview/`.

## Rules applied
- No flicker / overlap: `pagoda_lib.flicker()` runs `city/flicker_check.py` on every triangle of the scene with the template copies placed (keys per triangle, so same-colour duplicates count too): Sule 0 pairs, Botataung 0 pairs (fixed on the way: short shop bays next to the gates, the stair tread vs the platform, the stair sides vs the gold jambs, the two pond walkways' corner, the gate's red dado vs the gold frame).
- Interiors only from photos: Botataung's corridor and Sule's 8 shrine rooms are walkable; Sule's shops and its inner shrine halls / 28-Buddha hall stay closed (photos exist, not built yet).
- No made-up text: Sule's shop boards are plain colour boards, no lettering.

## What still differs from the photos
- **Carving and ornament:** every gold surface is plain YgnGoldLeaf. No relief on the bell cartouches, no carved crests on the pyatthats, shrines or gate (the gate's stepped finger crest reads as one gold strip), no lotus petal shapes, no bells on the hti.
- **Sule:** gates' bearings (N / E / S / W) and the platform height 3.6 m are from the photos, not measured; the pyatthats are simpler and look heavier than the real ones; the shops are closed fronts with plain colour boards (no text, no awnings, no goods); the ring's inside (rooms facing the platform) is a plain cream wall; the inner halls (carved teak pavilions, 28-Buddha hall, nat shrine) have photos but are not built; the island ground is flat although GLO-30 has a 4 m fall.
- **Botataung:** in the 2013 photo the bell is taller and the rings / bud / hti slimmer than in the model (the terraces take too much of the height); the terraces have plain corners (real ones are indented); the corridor is one plain zigzag ring (real: tighter maze, glass showcases with relics, mirror-mosaic sections, red skirting); the chamber's relic is a stand-in stupa; the gate's side arches are dark rectangles (real: gold-framed arches); the compound's other halls (the bronze Buddha hall, monastery, Nat shrine) are not modelled, so the paving looks empty; the river is a flat TEMP plate.
- **Jetty:** shape from OSM only (no photo used); shed and rails are guesses.


## v2 look pass (16 Nov, judged side by side with the photos, same views)
- **Assets now in use:** Sule **85263246762728** (v4), Botataung **136939581125874** (v3). Triangles: Sule 24,529 (site 8,025), Botataung 23,953 (site 21,111). Flicker test 0 pairs on both (Botataung's parquet planks are left out of the pair test: they tile exactly by construction, area sum checked).
- **Sule stupa refit from the park photo** (37.9 px a metre, widths at 12 heights): bell 10.8 m across at 13.7 m, 8.8 @ 19.0, 4.5 @ 24.3; five rings to 28.2 m; lotus 2.9 m; wire fan 4.9 m at 31 m; slender bud 1.6 -> 0.7 m to 36.7 m; hti cage widening to 2.4 m; thin spire, vane, orb at 44.1 m. Ten broad octagonal terraces from 34.4 m to 11.8 m (photo 8). Was a wide squat cone.
- **Sule pyatthats:** gold roof slopes with a row of gold flame fingers on every eave and taller corner flames, dark green friezes, 7 m base, tiers 0.76 of the one below, tall spire (photo 6). Were green and heavy.
- **Sule shops:** roller shutters (half or fully down on some bays), canvas awnings in blue / green / red, 6 sign colours incl. white and orange (no text), same white upper storey with the blue band.
- **Botataung:** terraces 7 x 1.1 m with stepped-in corners; bell 7.75 m radius at the lip, 11 m tall (11.6 -> 22.6 m); slimmer rings, bud and 7-tier hti.
- **Botataung corridor:** embossed gold panel tiles (YgnGoldPlate) in raised gilded frames (dado rail, top frieze, stiles every 0.9 m), red skirting, herringbone parquet (0.6 x 0.15 m planks, two wood tones), 6 glass relic cases with gold relics, mirror mosaic in the passage to the relic window.
- **Gold (test on Botataung, same camera, `gold_test_plastic_vs_metal.jpg`):** SmoothPlastic + Reflectance read flat pale cream; plain Metal with the photo gold through `look_calib` (255, 187, 84) reads closest to the photos and has no blotchy leaf grain -> all big gold. Gilded trim and frames: Foil (230, 160, 50) (SmoothPlastic frames read washed out under the corridor lights; Foil reads as crinkled gold leaf like the photos). Corridor panels: Metal + YgnGoldPlate (255, 206, 130).
- Pictures: `build/landmarks/sule/compare_park_v2.jpg` (photo | v1 | v2), `build/landmarks/botataung/compare_stupa_v2.jpg`, `compare_corridor_v2.jpg` (photo | v1 | v2 | relic case), `compare_pond_v2.jpg`, `gold_test_plastic_vs_metal.jpg`.
- **Still differs:** the parquet shows faint light hairlines at plank joints; carving is frames and tiles, not relief; the Sule hti reads as a solid drum (the real one is open filigree); the Sule pyatthat friezes are green bands (photo: mostly gold with green glass); shops have no goods or people; Botataung's terraces look a little flatter than in the 2013 photo.

## Ornament kit pass (16 Nov)
Flat plates replaced with the carved kit ([[2026-11-16 Burmese ornament kit]]):
- **Sule:** pyatthat tiers carry kit crest runs (flame fingers on a back board; scroll leaves, bead and glass on the eave tier) and carved corner horns on the 4 lowest tiers; the 8 bell cartouches are carved panel tiles (bevelled frame, rosette, corner scrolls, YgnCarvedGold field), lifted off the bell's bulge; the 8 shrine doors got carved pediments. Scene 65,793 triangles (was 24,529; the pyatthat template 9,094). Asset **132710134067811**.
- **Botataung:** gate gable = kit `gable_frame` + `gable_fingers` over the white tympanum; pond walkway ridge crests and the pond pyatthat from the kit; corridor walls = YgnCarvedGold carved field (was flat YgnGoldPlate). 34,754 triangles. Asset **86279914319430**.
- New looks: GCV carved trim = Foil (230, 160, 50) (the settled trim value), GPN carved field = Metal + YgnCarvedGold (255, 250, 240), GJL green glass.
- Flicker 0 pairs on both. Placed with the same placers (replace, collision rebuilt the same). The Botataung parquet lost half its triangles at RenderFidelity Automatic in Studio: set to Precise.
- ![[Ornament kit - Sule photo before after.jpg]] ![[Ornament kit - Sule bell carved panels.jpg]] ![[Ornament kit - Botataung photo before after.jpg]] ![[Ornament kit - Botataung corridor carved panels.jpg]]
- Still differs: the corridor's carved field reads olive-khaki, darker than the photo's gold; the pyatthat crests are coarser than the photo's.
