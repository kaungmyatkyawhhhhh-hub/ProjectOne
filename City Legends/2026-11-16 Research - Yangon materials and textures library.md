---
tags: [city-legends, research, yangon, materials, textures, blueprint]
created: 2026-11-16
---
# Research - Yangon materials and textures library

> Owner: "dont forget about textures & materials & every detail of everything too!"
> 50 real surfaces (CC0, from Poly Haven and ambientCG, plus 8 drawn in code). Each one becomes a Roblox MaterialVariant.
> - **Scripts:** in `Games/CityLegends/tools/yangon/materials/`.
> - **The prepared maps:** in `Games/CityLegends/build/materials/`, which is not in git. Rebuild them with `download.py` then `prepare.py`.
> - **The Studio applier:** `tools/yangon/YangonMaterials.luau`.
> - **Trap:** a mesh shows a texture only if it has real UVs. The landmark and kit exporters wrote every UV as (0.5, 0.5), so they now box-project UVs at real size.


Built 2026-11-16 for the 1:1 Yangon rebuild (3 studs = 1 m). Owner: "dont forget about textures & materials & every detail of everything too!"

- **50 surfaces**: 42 built on CC0 PBR sets (32 on Poly Haven, 10 on ambientCG), 8 fully procedural; 12 of the 42 also have a procedural layer.
- Each folder `build/materials/<slug>/` holds:
  - `sources.json`: asset id, page, download URL, licence CC0 1.0, real size
  - `src/<asset>/`: the downloaded 1K maps
  - `roblox/`: the prepared set and its `manifest.json`
- All 50 sets are listed in `build/materials/manifest.json`, with an `ids` slot per map for the upload.
- Scripts are in `build/materials/_tools/`:
  - `spec.py`: the surface list (the one place to change targets, tile sizes and groups)
  - `download.py`
  - `prepare.py`: run `python -I prepare.py [slug ...]`
- The Studio applier is `tools/yangon/YangonMaterials.luau`. It has not been run, and no maps have been uploaded.
- Size: about 113 MB of downloaded sources plus 106 MB of prepared sets (250 files) = 219 MB.

## What a prepared set is

| File | Format |
|---|---|
| `<slug>_color.jpg` | 1024 px RGB, quality 92. The three masks use `<slug>_color.png` (RGBA, alpha = opacity) |
| `<slug>_normal.png` | OpenGL convention, +Y up. The Poly Haven `nor_gl` and ambientCG `NormalGL` maps are used as they are. A DirectX-only set gets its green channel flipped (none was needed). Procedural normals are written +Y up |
| `<slug>_roughness.png`, `<slug>_metalness.png` | Single channel. Metal comes from the Poly Haven ARM map (blue channel) or the ambientCG Metalness map, or is a constant |

**StudsPerTile** = 3 x the texture's real size:
- Poly Haven `dimensions` and ambientCG `dimensionX` where they are published.
- My estimate where they are not, from counting tiles, ribs or diamonds in the map:
  - CorrugatedSteel007A: 1.2 m
  - Fence003: 0.8 m
  - Tiles043: 2.4 m (0.3 m tiles)
  - Tiles132A: 1.0 m
  - Marble012 / 014: 2 m
  - Metal048C: 1 m

**Colour**: three modes.
- **tint** (fixed colour): each channel is scaled in linear light so that the ColorMap's mean equals the target. This keeps the texture's own variation. Highlights are soft-compressed instead of clipped.
  - Outdoor targets are the measured midday photo colour put through `look_calib.albedo("SmoothPlastic", photo)`: the colour a flat part needs in order to render as the photo under Yangon's light. The ColorMap is pre-brightened, so the part's Color stays white.
  - Interior targets (Meliá, floors) are the photo colour as it is, the same rule as `groups_melia.py`.
- **neutral** (per-part colour): the map is desaturated, with a mean of 228 sRGB (bright). The group's existing calibrated `Part.Color` then sets the hue (`KW*` walls, kerbs, painted steel and wood, canvas, vinyl).
  - The wall maps get darker after their rain streaks are added (stained 208, painted 224). That is intended: real downtown walls read 15-35% darker than their paint.
- **drawn** (procedural colours): colours from the reports, for example the TLB blue 60, 90, 150, the KNT green 48, 100, 60 and the KTP blue 50, 110, 180.

Targets marked "est." in the notes have no measured swatch: pavers, shophouse tiles, gravel, leaf litter, bamboo, glass mosaic and the chequer floor.

## Brightness: the "textured renders dark" trap

`look_swatches_13h_yangon.json` (mix = 0.6 sun + 0.4 shade, mean of R, G and B) gives how much darker each base material renders than SmoothPlastic at the same part colour:

| Base material (as measured, with the place's Riviera overrides) | Grey 145 renders | Grey 195 | Grey 245 | Boost vs SmoothPlastic (145 / 195 / 245) |
|---|---|---|---|---|
| SmoothPlastic / Plastic | 138 | 177 | 204 | 1.00 |
| Glass | 137 | 175 | 202 | 1.01 |
| Marble | 103 | 139 | 169 | 1.34 / 1.27 / 1.21 |
| Metal | 100 | 137 | 166 | 1.37 / 1.30 / 1.23 (and it takes the sky's blue) |
| Sandstone | 99 | 120 | 140 | 1.39 / 1.48 / 1.46 |
| Concrete (RivConcrete2 override) | 76 | 103 | 128 | 1.81 / 1.73 / 1.59 |
| Slate (RivSlate override) | 65 | 87 | 111 | 2.13 / 2.05 / 1.85 |

Not measured: Plaster, Fabric, WoodPlanks, Asphalt, Grass and Pavement. look_calib uses Concrete for them, so assume about 1.6-1.8.

How to read it:
- Most of that darkening is the base material's own ColorMap. The built-in maps and the Riviera override maps are mid-grey and darker.
- A MaterialVariant replaces that map. So the library builds the boost into the maps instead: every fixed-colour ColorMap already carries the SmoothPlastic-equivalent albedo, which is brighter than the photo. For example, concrete 170, 166, 158 becomes a map of 186, 180, 165, and asphalt 114, 112, 108 becomes 124, 118, 103.
- The neutral maps are at 228.
- What is left is the shading from the normal map and roughness. Expect a few percent at most.

Suggested residual boost per base, if a measured variant still renders darker than its target:
- Concrete, Plaster, Pavement, Asphalt: x1.05-1.10 on the map. Their normal maps are strong.
- Metal / CorrodedMetal: x1.15. Metal reflects the blue sky instead of its albedo. For painted metal (YgnSteelPainted, YgnCorrugatedBlue), lower the metalness map before you brighten it.
- Marble, Granite, CeramicTiles: x1.0. They are interior, smooth and low-normal. Under outdoor light the Shwedagon `STONE` rule already multiplies the colour by 236, 232, 229.
- Grass, Ground, Mud: x1.0-1.05.

Measure before boosting: put Ygn variants on the `Swatches.luau` panels (white Color), run `swatch_measure.py`, and compare the result with `look_calib` targets. Then change `NEUTRAL_MEAN` or the targets in `spec.py` and re-run `prepare.py`.

## Before running the applier (main session)

1. **Upload** `roblox/*_color.*`, `*_normal.png`, `*_roughness.png` and `*_metalness.png` per slug as Images (Open Cloud). That is 200 images.
   - A metalness map that is all 0 can be skipped (leave `metalness` nil). Its PNG is tiny.
   - Write each id into `manifest.json` (`ids`).
2. In Studio (Edit), run:
   - `Y.setIds({...})`
   - `Y.createVariants()`
   - `Y.apply(workspace.Yangon, {"kit", "landmarks", "roads"}, {dry = true})` (counts only), then the same without `dry`
   - `Y.terrain()`
3. **Mesh UV trap:** MeshParts take a material's texture from their mesh UVs.
   - `landmark_glb3d.export` (`m.tri(..., (0.5, 0.5) x3)`) and the kit export write every UV as (0.5, 0.5). On today's landmark and kit MeshParts a variant shows a single texel: flat colour, so nothing changes visibly.
   - Parts, the road / kerb / pavement parts and Terrain tile by StudsPerTile straight away.
   - Before the variants can show on the meshes, the exporters need world-scale box-projected UVs. That is a geom3d / glb change I did not make (no other code was edited). Test one mesh against one Part first.
4. **Global overrides:** `Y.terrain()` overrides Grass, LeafyGrass, Ground, Mud, Pebble and Salt everywhere (parts too).
   - Salt is used as a spare terrain material for red earth.
   - The place's existing Riviera overrides (Plaster, Limestone, Concrete, Slate, ClayRoofTiles) are left alone. Variants used by name win over them.
   - `Y.terrain(nil, true)` undoes it.
5. **Masks** (YgnGrilleMask, YgnChainLinkMask, YgnRazorWireMask): MaterialVariants have no alpha.
   - On MeshParts they become SurfaceAppearance clones (`AlphaMode Transparency`, templates in `ServerStorage.YgnMaskTemplates`), which also use the mesh UVs.
   - On Parts they become Textures (Front / Back faces) with StudsPerTile.
6. **The owner's flat white landmark walls** (MEL, RES, SED, CRM, GRN, CEL, GFA, TER) are in a separate opt-in rule set, `landmarkWalls`. Apply it only after a look.
7. **Base materials outside the list given to me:**
   - CeramicTiles: tile floors and pool
   - ClayRoofTiles: roof tiles. The built-in renders near black here, and the variant replaces its map.
   - LeafyGrass, Salt and Mud: terrain slots
   - Foil: the glass mosaic. Glass may not take a variant, and the mosaic's mirror pieces come from its metalness map.
   - DiamondPlate: chain-link, the FEN group's current material

## Surfaces

| Surface | Base material | MaterialVariant | StudsPerTile | Target colour | Game groups / parts | Notes |
|---|---|---|---|---|---|---|
| render stained | Plaster | YgnRenderStained | 9.0 | per part (neutral map, mean 208) | KWD2, KWG, KWC; old colonial plots (KW3 when age > 0.6); compound walls | lime render with black rain/mildew streaks (procedural streak layer over the CC0 base: 40-60% of the width, 0.4-2.5 m long). Source: Poly Haven concrete_wall_003 + procedural |
| render painted | Plaster | YgnRenderPainted | 6.0 | per part (neutral map, mean 224) | KW0-KW7, KWB; landmarks MEL, RES, SED, CRM, GRN, PBD, CEL, GFA (optional, owner liked them flat white) | plain painted render, faint dust streaks only. Source: Poly Haven painted_plaster_wall + procedural |
| concrete bare | Concrete | YgnConcreteBare | 8.13 | photo 170, 166, 158 (outdoor) -> map 186, 180, 165 | KCO (poles, bare concrete), ROF (flat roofs), road Pier / PierCap / Barrier | smooth form-work concrete. Source: Poly Haven concrete_wall_008 |
| concrete stained | Concrete | YgnConcreteStained | 6.0 | photo 100, 100, 99 (outdoor) -> map 104, 104, 103 | road Girder (flyover soffits), walk-up slab edges and pillars, old compound walls (when not KWC) | black-stained concrete (walk-up seen 96,97,97 / pillars 70,69,69 in the shade lines). Source: Poly Haven concrete_wall_006 |
| brick red | Brick | YgnBrickRed | 7.5 | photo 103, 84, 77 (outdoor) -> map 107, 88, 80 | court-style red brick buildings (Secretariat, High Court, Pansodan red brick front); landmark brick groups when added | target = the one measured red brick swatch (overcast, Pansodan row); check against a sunlit court-building photo. Source: Poly Haven red_bricks_04 |
| asphalt worn | Asphalt | YgnAsphaltWorn | 9.0 | photo 114, 112, 108 (outdoor) -> map 124, 118, 103 | road parts 'Road' (main roads), DRV, KRD | worn warm-grey main-road asphalt with cracks (108-120 warm grey). Source: Poly Haven asphalt_02 |
| asphalt patched | Asphalt | YgnAsphaltPatched | 24.0 | photo 108, 106, 102 (outdoor) -> map 112, 110, 106 | 'Road' on township streets and older stretches; alternate with YgnAsphaltWorn per segment | procedural composite of two CC0 asphalts: dark rectangular patches 2-6 m (80-95) in an 8 m tile. Source: Poly Haven asphalt_04, Poly Haven asphalt_02 + procedural |
| asphalt oily | Asphalt | YgnAsphaltOily | 12.0 | photo 100, 99, 96 (outdoor) -> map 104, 103, 100 | lane asphalt (95-105), bus bays, parking strips, lane-centre strips | procedural oil drips and a darker wheel-path band over CC0 asphalt. Source: Poly Haven asphalt_04 + procedural |
| concrete lane slab | Pavement | YgnConcreteLaneSlab | 10.5 | photo 140, 136, 127 (outdoor) -> map 151, 144, 126 | township concrete lanes (cast panels 3-4 m), forecourt aprons | one 3.5 m cast panel per tile, dark joint on two edges; older concrete 130,126,118 to 150,146,136. Source: Poly Haven concrete_floor_worn_001 + procedural |
| pavement slabs broken | Pavement | YgnPavementSlabs | 9.0 | photo 150, 146, 136 (outdoor) -> map 162, 155, 138 | road part 'Pavement', KPV; downtown footways | 1 m grey slabs (3 x 3 per tile), cracked; one slab per tile broken and dirty (real: 1 in 10-20). Source: Poly Haven large_floor_tiles_02 + procedural |
| pavers forecourt | Pavement | YgnPaversMall | 5.4 | photo 160, 155, 145 (outdoor) -> map 173, 166, 149 | PAV (Myanmar Plaza / Hledan forecourts only: pavers appear only in front of malls) | target est. (no forecourt swatch measured). Source: Poly Haven concrete_pavement |
| kerb stone | Concrete | YgnKerb | 6.0 | per part (neutral map, mean 224) | road parts 'Kerb', 'MedianKerb' (keep their red 195,47,45 / white 232,228,218 / yellow paint as Part.Color) | matte cast kerb, dust film darkening toward the bottom of the tile (lay the tile with V up). Source: Poly Haven concrete_floor_02 + procedural |
| drain cover | Concrete | YgnDrainSlab | 3.0 | photo 140, 140, 136 (outdoor) -> map 151, 148, 138 | drain-slab strips along the pavement edge and township lanes (0.5 x 1 m lids, 0.12 m thick) | procedural: two 0.5 x 1 m lids per tile with dark gaps and lifting holes. Source: Poly Haven dirty_concrete + procedural |
| corrugated rust | CorrodedMetal | YgnCorrugatedRust | 6.0 | photo 105, 70, 56 (outdoor) -> map 109, 73, 58 | KRF (rusty corrugated roofs), market shed roofs, vacant-lot fences | lay the ribs down the slope (V along the slope). Source: Poly Haven rusty_corrugated_iron |
| corrugated blue | Metal | YgnCorrugatedBlue | 3.6 | photo 96, 145, 196 (outdoor) -> map 107, 154, 231 | KRB (blue metal roofs), KAW (blue corrugated awnings) | painted blue sheet with small rust spots. Source: ambientCG CorrugatedSteel007A |
| corrugated zinc | Metal | YgnCorrugatedZinc | 5.4 | photo 116, 116, 110 (outdoor) -> map 126, 122, 106 | KRG (faded grey / zinc roofs), shed walls, site hoardings | faded zinc with rust streaks (new zinc reads 160,165,165: set Part.Color brighter for new sheets). Source: Poly Haven worn_corrugated_iron |
| roller shutter | Metal | YgnRollerShutter | 4.11 | photo 150, 150, 148 (outdoor) -> map 162, 160, 153 | KRS (shop roller shutters) | horizontal slats: lay with V up. Source: Poly Haven worn_shutter |
| steel rusty | CorrodedMetal | YgnSteelRusty | 6.6 | photo 166, 120, 83 (outdoor) -> map 181, 126, 73 | KGU (rusty gates), KCU (rust cages: Part.Color multiplier 184,159,154 for the darker 120,75,50) | fully rusted steel. Source: Poly Haven rust_coarse_01 |
| steel painted | Metal | YgnSteelPainted | 3.0 | per part (neutral map, mean 228) | KGT (near-black green gates), KCB (black cages), KGR (black iron), KCW (white cages), KCG (posts), STL, sheet-steel gates (green, blue, maroon) | painted steel with chips and small rust; hue from Part.Color. Source: Poly Haven green_metal_rust |
| steel grille | Metal | YgnGrilleMask | 0.9 | drawn (map mean 220, 220, 220) | window grilles / balcony cage panels drawn as flat quads (KCB, KCU, KCW when panels) | OPACITY MASK (alpha in the ColorMap PNG): use as SurfaceAppearance (AlphaMode Transparency) or a Texture, not as a MaterialVariant (variants have no alpha). Bars every 0.10 m, rails every 0.30 m. Procedural.. Source: procedural. MASK (alpha) |
| chain link | DiamondPlate | YgnChainLinkMask | 2.4 | photo 150, 152, 150 (outdoor) -> map 162, 162, 155 | FEN (chain-link fences), sports grounds, construction sites | OPACITY MASK (alpha in the ColorMap PNG): SurfaceAppearance / Texture only. Source: ambientCG Fence003 + procedural. MASK (alpha) |
| razor wire | Metal | YgnRazorWireMask | 3.0 | drawn (map mean 186, 189, 182) | villa / compound wall tops (about 30% of compound walls), flat strip quads 0.6 m tall | OPACITY MASK, procedural: no CC0 razor-wire texture exists on ambientCG / Poly Haven. Source: procedural. MASK (alpha) |
| clay roof tile | ClayRoofTiles | YgnClayRoofTile | 7.8 | photo 165, 95, 80 (outdoor) -> map 179, 101, 69 | KRT (villa tile roofs), RTL (guard hut: multiplier for 190,82,50), TER (Sedona roofs) | pink-red Marseille tiles; the built-in ClayRoofTiles renders near black here, the variant replaces its map. Source: Poly Haven clay_roof_tiles_03 |
| terrazzo grey | Granite | YgnTerrazzoGrey | 7.2 | photo 205, 205, 200 (interior) -> map 205, 205, 200 | TRZ (Meliá lobby bar), Central Railway Station hall, shophouse and office floors | light grey terrazzo in 0.3 m tiles. Source: ambientCG Tiles043 |
| marble white | Marble | YgnMarbleWhite | 6.0 | photo 232, 230, 225 (interior) -> map 232, 230, 225 | MWH, MDK (Meliá white marble), MAR, Shwedagon platform STONE kind, pagoda stairs | white with grey veins; outdoor use (Shwedagon platform): keep Part.Color 214,210,202 as a multiplier. Source: ambientCG Marble012 |
| marble beige | Marble | YgnMarbleBeige | 6.0 | photo 215, 205, 190 (interior) -> map 215, 205, 190 | MFL (The Market floor), CAR (caramel border: multiplier), mall floors, hotel lobbies | beige marble, soft veins. Source: ambientCG Marble014 |
| tiles shophouse | CeramicTiles | YgnTilesShophouse | 5.7 | photo 200, 192, 178 (interior) -> map 200, 192, 178 | shophouse / tea-shop / walk-up floors, WTL | plain glazed floor tiles; target est. (no floor swatch measured). Source: Poly Haven interior_tiles |
| tiles blue white | CeramicTiles | YgnTilesBlueWhite | 1.8 | drawn (map mean 192, 193, 199) | TLB / TLW (patterned tiles), old shophouse and colonial floors, Sule inner ambulatory | procedural 0.2 m encaustic-style pattern in the measured blue 60,90,150 and white, with its own grout relief (no CC0 blue-and-white encaustic tile exists on either site). Source: Poly Haven interior_tiles + procedural |
| tiles chequer | CeramicTiles | YgnTilesChequer | 6.0 | drawn (map mean 172, 172, 171) | Strand lobby, Shwedagon office, Musmeah Yeshua synagogue, St Mary's (black-and-white chequer floors) | CC0 chequer relief, re-graded to black 38 / white 232. Source: Poly Haven checkered_pavement_tiles + procedural |
| tiles pool | CeramicTiles | YgnTilesPool | 3.0 | photo 150, 200, 220 (outdoor) -> map 152, 215, 255 | POL (pool tiles), WAT surrounds | small blue pool tiles. Source: ambientCG Tiles132A |
| teak shutter | Wood | YgnTeakShutter | 3.0 | photo 110, 70, 40 (outdoor) -> map 114, 73, 42 | KSH (teak shutters, louvres), villa teak upper floors (seen 95,73,50 / 72,58,54) | vertical teak boards; louvre bars are geometry, this is their grain. Source: Poly Haven wood_shutter |
| teak panel | WoodPlanks | YgnTeakPanel | 6.3 | photo 150, 112, 78 (interior) -> map 150, 112, 78 | TEK, TKC (Meliá teak), MBM / MCO (multiplier, dark-stained), Strand Sarkies Bar panelling, pagoda carved-teak backdrops | framed teak panelling. Source: Poly Haven wooden_panels |
| wood painted | WoodPlanks | YgnWoodPainted | 4.8 | per part (neutral map, mean 228) | KSH2 (green shutters), KSH3 (blue), KSH4 (orange-teak painted doors), painted timber houses | rough painted boards with chips; hue from Part.Color. Source: Poly Haven distressed_painted_planks |
| wood raw | WoodPlanks | YgnWoodRaw | 5.4 | photo 140, 100, 65 (outdoor) -> map 146, 104, 68 | KWD (stalls, crates), Kandawgyi boardwalk deck (multiplier for 120,90,60), lean-to sheds | weathered sawn planks. Source: Poly Haven weathered_brown_planks |
| bamboo scaffold | Wood | YgnBamboo | 1.2 | drawn (map mean 209, 178, 103) | bamboo scaffold poles (8 cm culms), market stall frames, fences | procedural single culm (nodes every 0.4 m along V, fibres along V): run poles along V. ambientCG Bamboo001/002 are walls of many poles, which read wrong on a single pole. Source: procedural |
| mesh green | Fabric | YgnShadeNet | 0.75 | drawn (map mean 40, 85, 50) | KNT (green shade / construction net; keep the part's 0.35 transparency) | procedural knitted HDPE net (48,100,60 photo); a variant has no alpha, so the part transparency stays. Source: procedural |
| tarp blue | Fabric | YgnTarpBlue | 4.5 | drawn (map mean 60, 115, 198) | KTP (blue tarps), market covers, roof patches | procedural woven PE tarp with creases (50,110,180). Source: procedural |
| canvas awning | Fabric | YgnCanvas | 1.2 | per part (neutral map, mean 228) | KAR (faded red canvas), shop awnings, umbrellas, KL1-KL6 laundry (optional) | coarse woven canvas; hue from Part.Color. Source: ambientCG Fabric061 |
| banner vinyl | Fabric | YgnVinyl | 6.0 | per part (neutral map, mean 227) | KSV (vinyl banners), RED (banners), stretched shop banners (not the hard signboards) | procedural: smooth PVC with sag wrinkles and a faint scrim weave; prints come from Decals. Source: procedural |
| gold leaf | Metal | YgnGoldLeaf | 3.0 | photo 212, 175, 92 (outdoor) -> map 255, 191, 83 | landmark GOLD kind (Shwedagon terraces to the bell, Sule, Botataung, Kaba Aye), SGD, finials | gold leaf on lacquer: 10 cm leaf squares with faint overlaps over the CC0 impure-gold base; metal 1. Source: ambientCG Metal048C + procedural |
| gold plate | Metal | YgnGoldPlate | 3.6 | photo 212, 175, 92 (outdoor) -> map 255, 191, 83 | Shwedagon banana bud and bell top (13,153 + 33,699 plates of about 30 cm), hti | 30 cm gold plates with seams; use above the middle band of the bell. Source: ambientCG Metal048C + procedural |
| glass mosaic | Foil | YgnGlassMosaic | 0.9 | drawn (map mean 186, 184, 179) | pagoda pillars and shrine back walls (mirror mosaic), Tuesday corner shrine, Ngahtatgyi plinth | procedural: 1-2 cm mirror and coloured glass pieces (metal map = mirror pieces); Glass can't carry a variant, so Foil. Source: procedural |
| grass lawn | Grass | YgnGrassLawn | 4.2 | photo 78, 112, 52 (outdoor) -> map 81, 117, 54 | terrain Grass; LAW, KGS, HDG (multiplier), road verges and medians, park lawns | watered lawn (post-monsoon photo target 78,112,52). Source: ambientCG Grass004 |
| grass dry | LeafyGrass | YgnGrassDry | 6.0 | photo 160, 150, 95 (outdoor) -> map 173, 160, 88 | terrain LeafyGrass (dry-season / campus / compound ground), vacant lots | straw grass with bare patches. Source: Poly Haven withered_grass |
| earth red | Salt | YgnEarthRed | 6.0 | photo 150, 110, 75 (outdoor) -> map 162, 116, 63 | terrain Salt (spare material re-used as red-brown laterite): pitches, paths, under dense compound trees | bare red-brown earth with laterite stones. Source: Poly Haven red_laterite_soil_stones |
| dirt packed | Ground | YgnDirtPacked | 9.0 | photo 150, 128, 100 (outdoor) -> map 162, 135, 94 | terrain Ground; compound yards (30%), street shoulders, lane edges | dry packed dust (wet reads 95,80,65). Source: Poly Haven park_dirt |
| gravel | Pebble | YgnGravel | 6.75 | photo 140, 134, 124 (outdoor) -> map 151, 142, 123 | terrain Pebble; road shoulders (dirt and gravel strips 1-3 m), rail ballast, building sites | target est. (no gravel swatch measured). Source: Poly Haven gravel_floor |
| mud lake edge | Mud | YgnMudEdge | 3.9 | photo 95, 80, 65 (outdoor) -> map 99, 83, 68 | terrain Mud (YangonTerrain2 m / n / w codes: lake and river edges, tidal banks) | wet dark mud; the Yangon River tidal banks read lighter (155,140,100): use Part.Color / terrain colour. Source: Poly Haven brown_mud_02 |
| leaf litter | Ground | YgnLeafLitter | 6.0 | photo 120, 95, 65 (outdoor) -> map 125, 99, 68 | parts / meshes under rain trees, compound gardens (15-20% of open ground); not a terrain override (Ground is dirt) | target est. (between packed earth and dry leaves). Source: Poly Haven dry_decay_leaves |
| bark tree | Wood | YgnBark | 3.0 | photo 95, 82, 70 (outdoor) -> map 99, 85, 73 | KTW (tree trunks), GreenKit trunks | rain-tree / padauk bark. Source: Poly Haven bark_brown_02 |
## Surfaces with no CC0 source (made procedurally)

- razor wire (YgnRazorWireMask): neither ambientCG nor Poly Haven has one.
- steel window grille (YgnGrilleMask): drawn to the critique's spec, bars every 0.10 m and rails every 0.30 m. ambientCG Fence007/008 are welded grates, not window bars.
- blue-and-white patterned tiles (YgnTilesBlueWhite): no CC0 encaustic tile in blue and white.
- bamboo scaffold pole (YgnBamboo): ambientCG Bamboo001 / 002 are walls of many poles.
- green construction / shade net (YgnShadeNet)
- blue tarpaulin (YgnTarpBlue)
- printed banner vinyl (YgnVinyl)
- pagoda glass mosaic (YgnGlassMosaic)

Procedural layers on CC0 bases:
- rain streaks on both renders
- asphalt patches (a composite of two Poly Haven asphalts)
- oil drips
- lane-slab joints
- broken pavement slab
- kerb dust
- drain lids
- chequer re-grade to black and white
- gold-leaf squares and 30 cm gold plates
- chain-link alpha from ambientCG's own opacity map
