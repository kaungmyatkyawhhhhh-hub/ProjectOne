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
   - `YgnRoadAsphalt` (base Asphalt, **40 studs a tile**, final v3): fine even aggregate grain with a few pale quartz chips, only faint tone (owner: "fine even speckle", no blotches), no cracks in the tile; normal from the grain (strength 15); roughness 0.93 on the binder, 0.5 on stone tops (sun sparkle). Colour (78, 78, 80): dark charcoal, a little lighter than the old near-black, per the owner's swatch.
   - Small-street concrete (`YgnRoadConcreteSA`, a SurfaceAppearance, tint 228, 224, 214): a **street-aligned** map, one tile = 64 studs along x 32 across: 4 cast slabs of 16 studs with sawn joints across and a centre joint along, each slab half its own tone, one repaired (darker) slab, a spalled corner at a joint, hairline cracks, darker smoother tyre paths at about 4 and 9 studs from the centre, dust toward the edges.
   - **Why a SurfaceAppearance:** Roblox projects a MaterialVariant in world space on a MeshPart (tested: the joints ran at 45 degrees on a diagonal street). A SurfaceAppearance uses the mesh UVs, and the split gives the concrete meshes road-local UVs (along / 64, across / 32 from the centre line).

![[refs_2026-11-27_road_surfaces/concrete_street_map.jpg]]
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

Image ids (approved, `tools/road_surface/ids.json`): asphalt v3 colour 77760241649520, normal 106226455470004, roughness 119840276812247; concrete v3 colour 130716823674053, normal 135714052142659, roughness 98118529041453. Models: 97 in `tools/road_surface/model_ids.txt`.

## Done in Studio (27 Nov, evening)
- All 896 new meshes placed (891 + the 5 pilot ones), 0 duplicates; the 420 old `RMeshR` are in `ServerStorage.RoadSurfaceOld` (attribute `OldCell`; `YangonRoadSurface.undo()` puts them back).
- **Every other visible asphalt piece now uses the same variant** (owner: "some are plain, some are with texture"): `VisibleFix_*` RoadFill (172), the car parks (361), drives, drive ramps, the Legends Service forecourt, `Visual/ASP`, the `DRV` meshes: 561 pieces to `YgnRoadAsphalt` and colour 78, 78, 80 (old values in attributes `OldColor` / `OldVariant`). The base Asphalt override (`RivAsphalt`) is unchanged, so a NEW plain Asphalt part would still look different.
- **Why the asphalt looked plain:** at 12 or 24 studs a tile the fine grain blurred into flat grey at driving distance, while the plain Asphalt pieces kept Roblox's coarse default speckle. At 40 studs a tile the grain reads all the way down the road (pictures below). Lesson: on a big road, judge grain at chase-camera distance, not close up.
- Saved to Roblox (Team Create; version 2379 after the swap, then a later save with the tile size). Store back on `CityLegends_v1`, `PreviewHour` removed.
- Play check (test store, noon and 17:30): about 60 fps at the spawn and on the deck, the same as before the change (59). No flicker in the grazing close-ups (lines 0.08 over the road, patches and seams in the road's own plane).

## After (Play)
Main road, noon (first swap, 24 studs a tile) / the owner's "plain" look / the fix (40 studs a tile), noon and 17:30:
![[refs_2026-11-27_road_surfaces/after_main_noon_play.jpg]]
![[refs_2026-11-27_road_surfaces/asphalt_fix_before_plain_play.jpg]]
![[refs_2026-11-27_road_surfaces/asphalt_fix_after_noon_play.jpg]]
![[refs_2026-11-27_road_surfaces/asphalt_fix_after_1730_play.jpg]]
Owner's swatch (dark charcoal, fine grain) and a close-up of the new asphalt:
![[Owner ref - asphalt colour (darker, fine grain) 2026-11-27.png]]
![[refs_2026-11-27_road_surfaces/asphalt_close_play.jpg]]
Small street (Maw Ya Waddy St) noon / 17:30 / close-up:
![[refs_2026-11-27_road_surfaces/after_small_noon_play.jpg]]
![[refs_2026-11-27_road_surfaces/after_small_1730_play.jpg]]
![[refs_2026-11-27_road_surfaces/after_concrete_closeup_play.jpg]]
Flyover deck noon / 17:30 / grazing close-up of the lines:
![[refs_2026-11-27_road_surfaces/after_deck_noon_play.jpg]]
![[refs_2026-11-27_road_surfaces/after_deck_1730_play.jpg]]
![[refs_2026-11-27_road_surfaces/after_graze_deck_paint_play.jpg]]
(The "after" small-street and deck shots were taken with the asphalt at 24 studs a tile, before the fix.)

## Traps found
- **A MaterialVariant on a MeshPart is projected in world space**: road-aligned detail needs a SurfaceAppearance plus mesh UVs.
- Fresh images can stay flat grey for minutes in a variant or SurfaceAppearance: wait before changing anything.
- Each Studio restart lost the unsaved swap (twice). Save right after a big placement.
- 10 MB glb uploads came just before an Assistant hang: upload ~5 MB files, two at a time.
- `S.place` sets CollisionFidelity Box after parenting: about 12 minutes for 896 meshes.

## Round 2 (27 Nov, night): owner corrections, applied and saved (version 2397)
**Owner on the concrete:** "i dont think concrete comes in panels and symmetrical gradient line?" The first concrete map had slab joints (across and down the middle), a tone per panel and tyre / edge bands mirrored left-right.
- **Now (v4):** one continuous cast-concrete surface. No joints, no panels. Irregular soft blotches at several sizes, two tyre-polish paths that wander and fade at DIFFERENT offsets (not mirrored), oil / dirt stains, a few random hairline cracks, irregular cement repairs. Same SurfaceAppearance and street UVs, pale tint 228,224,214.
- **Lesson (permanent):** Yangon concrete streets are continuous. Never draw panels or joints, and never put anything symmetric across the street.

**Owner on the asphalt:** "only the batch 0.5 roads are correct in color and other road asphalt became gray ... the asphalt road texture rubbles are too big ... they look blurry ... need to be sharp".
- **Grey:** the swapped `RMeshR` meshes were placed with the module's old default colour (150,150,152). The module copy in Studio came from a save made before its colours were updated. The road fill pieces and the two pilot cells had the right charcoal, which is the "correct" look the owner meant. Now every `RMeshR` and every other asphalt piece has one colour, 110,110,112 on the v4 map (mean 0.42). Lane asphalt is 140,139,135.
- **Big, blurry grain:** the earlier maps were blurred noise, made bigger to show at distance. **v4** has hard-edged 1-3 px stones (60,000 per tile), each its own grey, a few pale chips (3%), dark sandy binder, a domed normal per stone and glossier stone tops. StudsPerTile 16 (64 px a stud): stones about 0.5-1.5 cm, sharp close up, a fine even speckle down the road.
- **Lesson:** don't fix "plain at distance" by making the grain bigger. Make it crisp (hard-edged small stones) at a small tile size.

Before (grey, big blurry grain) / after, main road noon, down the road and close:
![[refs_2026-11-27_road_surfaces/asphalt_fix_after_noon_play.jpg]]
![[refs_2026-11-27_road_surfaces/v4_asphalt_main_noon_play.jpg]]
![[refs_2026-11-27_road_surfaces/asphalt_close_play.jpg]]
![[refs_2026-11-27_road_surfaces/v4_asphalt_close_play.jpg]]
Owner's swatch and the v4 map close-up:
![[Owner ref - asphalt colour (darker, fine grain) 2026-11-27.png]]
![[refs_2026-11-27_road_surfaces/v4_asphalt_map_detail.png]]
A road-fill asphalt piece next to a concrete street (same asphalt look as the road meshes):
![[refs_2026-11-27_road_surfaces/v4_asphalt_roadfill_patch_play.jpg]]
Concrete before (panels, mirrored bands) / after (continuous), same street:
![[refs_2026-11-27_road_surfaces/after_small_noon_play.jpg]]
![[refs_2026-11-27_road_surfaces/v4_concrete_street_noon_play.jpg]]
![[refs_2026-11-27_road_surfaces/v4_concrete_close_play.jpg]]
![[refs_2026-11-27_road_surfaces/concrete_street_map_v4.jpg]]
Play: 59-60 fps (as before). Ids: asphalt v4 colour 132495685801163 / normal 111398551171073 / roughness 118818663269495; concrete v4 colour 140378176617994 / normal 131246815654167 / roughness 111691553348338.
Not checked: 17:30 with the v4 maps; a real phone.

## Not done / not checked
- **Wheel paths:** small streets have wandering tyre polish in the concrete map. On the big roads they are still not done: The road UVs are world x / z (box projection), so a lane-aligned darkening can't live in the tiled texture; cutting strips along every lane would add hundreds of thousands of triangles. A later bake could carry lane-aligned vertex colours if the road mesh were denser.
- Tone at the zebra / paint edges was not tuned separately.
- Not checked on a real phone: texture memory (2 new MaterialVariant maps sets + 1 SurfaceAppearance set, 1024 px) and the +9% road triangles.
- Concrete streets wider than about 30 studs repeat the joint / tyre pattern across; the edge dust assumes about 20-stud lanes.
- `ServerStorage.RoadSurfaceOld` (420 old meshes) should be deleted once the owner is happy (place size).
