---
tags: [city-legends, look, roads, materials]
created: 2026-11-27
---
# Roads: realistic surfaces by road type (27 Nov 2026)

**Owner:** "i think the road textures dont look realistic and looks obvious that its a game, in the tiktok video its completely realistic but also keep in mind that our one is in yangon roads and not every small road is asphalt, the big roads & overhead roads are always asphalt".

References: [[2026-11-26 Study - TorqX Racing TikTok (what makes it look real)]], the owner's Yangon clips (catalogues of 24 and 27 Nov), the Hledan lane street view. Earlier pass today: [[2026-11-27 TorqX match - road surface, worn paint, render distance]].

## Why ours read as a game (before, same spots, Edit with the Play light)
Spots: Kabar Aye Pagoda Road by the spawn (main), the start of Kabar Aye Pagoda Road Flyover #2 (deck), Maw Ya Waddy Street in P1 (small street).

![[refs_2026-11-27_road_surfaces/before_main_noon.jpg]]
![[refs_2026-11-27_road_surfaces/before_small_noon.jpg]]
![[refs_2026-11-27_road_surfaces/before_deck_noon.jpg]]
![[refs_2026-11-27_road_surfaces/before_main_1730.jpg]]

1. **A tiling repeat you can see.** `YgnAsphaltWorn` is a 3 m CC0 photo (Poly Haven asphalt_02) with one long black crack in it, at 9 studs a tile. The same crack comes back every 9 studs over the whole map: rows of parallel cracks on every road.
2. **Too dark and flat in tone.** Colour (80, 80, 84) times the map renders near-black blue-grey. The owner's clips measure Yangon main-road asphalt at about 125-150 mid grey (0929, 0933); TorqX's road is a light grey too.
3. **No large-scale variation.** One tile, nothing at 5-50 stud scale: no tone blotches, no repair patches, no sealed cracks. The road reads as one printed sheet.
4. **Weak relief and no sparkle.** The photo's normal map is soft at 9 studs a tile and its roughness is one flat value (about 0.77), so the sun never glints off stones as in TorqX 2.9 s / 4.7 s.
5. **Every small street is the same dark asphalt with kerbs**, but the owner's lane clips (0934, Hledan street view) show pale cast concrete (about 180, 180, 175), worn, stained, often no markings.
6. No wheel-path darkening (see "Not done").

What the real roads show (frames only):
- Main roads: mid-grey asphalt, "worn, with patching" at big junctions (0933), "a long longitudinal crack / joint line and dark patches" (0930).
- Flyovers and decks: asphalt or concrete deck, double white centre lines (0929).
- Side lanes: "single carriageway 5-6 m, no markings, concrete / asphalt pale grey, crumbly edges, dirt verges" (0934); Hledan lane: grey worn concrete with dark stains.

OSM (Yangon extract, `surface` tags): residential 12,740 ways, 96% untagged; of the tagged ones 281 asphalt, 177 concrete (+5 concrete:lanes), 46 paved, 23 unpaved / ground. Primary / secondary / trunk are mostly tagged asphalt.

## What changed
1. **New maps** (`tools/road_surface/road_textures.py`, procedural, seeded, 1024 px, 6 maps):
   - `YgnRoadAsphalt` (base Asphalt, 24 studs a tile ≈ 7.5 m): fine aggregate grain with a few pale quartz chips, tone blotches at about 7 and 1.5 studs so the tile doesn't read, no cracks in the tile; normal from the grain; roughness 0.93 on the binder, 0.5 on stone tops (sun sparkle).
   - `YgnRoadConcrete` (base Concrete, 32 studs a tile): pale warm grey, worn areas showing aggregate, stains, a few hairline cracks.
   - Colour maps are neutral; each road kind's Part colour sets the shade.

![[refs_2026-11-27_road_surfaces/new_maps_asphalt_concrete.jpg]]
Old library maps (asphalt worn with the repeating crack, patched, oily, lane slab): ![[refs_2026-11-27_road_surfaces/old_library_maps.jpg]]
2. **Road meshes split by real surface** (`tools/road_surface/road_surface_split.py`, from the place's own R meshes, the 26 Nov bake):
   - Each triangle is given the road under it (roads05 network P1-P12, by corridor and level; the bigger road wins in a junction).
   - **R** = big roads (OSM trunk / primary / secondary / tertiary and links) and every flyover deck: asphalt.
   - **RC** = small streets: concrete (untagged residential / service / living_street / unclassified, OSM concrete).
   - **RA** = small streets OSM-tagged asphalt / paved: rough lane asphalt (same asphalt maps, lighter).
   - **RU** = small streets OSM-tagged unpaved / ground: gravel (`YgnGravel`).
   - Sparse **repair patches** (one every ~100 studs of big road: 5-16 stud rectangles, some long trench patches) and **tar-sealed cracks** are cut into the R mesh in its own plane and darkened by vertex colour. Nothing is laid over the road, so nothing can z-fight; the paint still sits 0.08 over the surface.
   - Area in = area out (116,883,512 sq studs, checked by the script).

## Numbers (offline split of all 420 place R meshes, 26 Nov bake = what the place holds; checked against Studio's mesh ids)
| | before | after |
|---|---|---|
| road surface meshes | 420 `RMeshR` | 896 (R 4 kinds by cell) |
| triangles | 3,668,164 | 4,000,000 (+9%) |
| asphalt R (big roads + decks) | all | 38.2 M sq studs (33%), incl. 513 k patches + 37 k sealed cracks |
| concrete RC (small streets) | none | 75.0 M sq studs (64%) |
| lane asphalt RA (OSM asphalt) | none | 3.0 M sq studs (2.6%) |
| gravel RU (OSM unpaved) | none | 0.22 M sq studs (0.2%) |
| new texture maps | | 6 (2 x colour / normal / roughness, 1024 px); `YgnAsphaltWorn` stays in the place but is no longer used by the roads once swapped |
| glb files to upload | | 97 (~5 MB each) in `imports/sync/RSURF_glb/` |

Image ids (approved): asphalt 106420386734912 / 118937246156752 / 119840276812247, concrete 91186461247844 / 111294739232406 / 74085596867182 (`tools/road_surface/ids.json`). The two MaterialVariants were made in Studio (Edit) on 27 Nov.

## State at the end of 27 Nov: NOT swapped in Studio yet
- Studio's MCP stopped answering at about 12:20 (the first Studio shut down; the reopened one stayed unreachable for 50+ minutes, its log shows the Assistant's networking hanging and network time-outs). Three 10 MB glb uploads were in flight when it went: **upload at most ~5 MB a file** (the split now writes 45,000-triangle files).
- So the place still shows the old roads. No place save was made by this job.
- **To finish** (Studio "City Legends", lock held): upload the 97 glbs in `imports/sync/RSURF_glb/` as Models (group 33151111), `InsertService:LoadAsset` each into one holding folder, put `tools/road_surface/YangonRoadSurface.luau` into `ServerStorage.ClaudeTools.YangonRoadSurface` (Source; the copy there now is a placeholder), `S.variants()`, `S.place(holding, cells)` with every cell in `swap.json`, then the after shots at the same 3 spots / 2 times, a grazing close-up of paint on the new surfaces, a Play test (test store), save, delete the holding folder and, once checked, `ServerStorage.RoadSurfaceOld`.
- Tune by eye after the swap: `S.LOOK` colours (R 150, RC 205, RA 170) against the Yangon frames (main road ~140 grey, lanes ~180).

## Not done / not checked
- **Wheel-path darkening:** not done. The road UVs are world x / z (box projection), so a lane-aligned darkening can't live in the tiled texture; cutting strips along every lane would add hundreds of thousands of triangles. A later bake could carry lane-aligned vertex colours if the road mesh were denser.
- Tone at the zebra / paint edges was not tuned separately.
