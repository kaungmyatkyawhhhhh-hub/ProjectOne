---
tags: [city-legends, look, roads, materials]
created: 2026-11-27
---
# Sharp textures up close: kerbs, pavement, road lines (27 Nov 2026)

**Owner** (close-up driving screenshot): "those look blurry". The road, the yellow line and the red/white kerb with the grey pavement all looked soft next to the car.
**Owner, later the same day** (passed on by the map session): "the road markings are not that bad irl and check for blurry textures, the textures need to be ultra high quality like the asphalt texture rn".

## Cause
- **Kerbs (`RMeshKR`, `RMeshKW`) and deck sides (`RMeshB`):** plain Concrete with no MaterialVariant.
  - That falls back to the place's old Monaco override for Concrete: `RivConcrete2`, a 1024 px map stretched over 22 studs (7 m) a tile.
  - On a 1-stud kerb that shows as a big smeared blotch.
- **Pavement (`RMeshP`):** built-in Sandstone with no variant. Its own pattern is large and blotchy on these meshes, so it read as a smear too.
- **Yellow and white lines (`CL_RoadPaintWorn`):** the 27 Nov worn-paint map was only 512 px over 8 studs, with big chip blobs (~10% of the paint missing).
  - Up close those blobs read as smudges.
  - The owner also says real Yangon markings aren't that worn.
- **Not the cause:**
  - **Texture loading:** every road / kerb map returned Success from `ContentProvider`.
  - **Graphics quality:** Studio ran at level 21 (max).
  - **`LowEnd.lua`:** it never touches materials or MaterialService.
- **The asphalt (`YgnRoadAsphalt`, 1024 px over 24 studs) is the quality bar.** The owner likes it, so it was left alone. The roads session owns it.

## Fix (Studio, saved as version 2349, not published)
1. **Kerbs and deck sides:** 765 `RMeshKR`, 767 `RMeshKW` and 68 `RMeshB` now use `YgnKerb`.
   - That is a fine concrete map, 1024 px over 6 studs = 170 px a stud, about 4x sharper than before.
   - It takes each part's own colour, so the red and white bands stay.
2. **Pavement:** 763 `RMeshP` now use the new `YgnPavementFine`.
   - It is the kerb concrete with Sandstone as its base, 9 studs a tile.
   - It takes each part's own grey (128, 124, 116).
3. **Road lines:** `tools/road_paint/worn_paint.py` v2 makes 1024 px maps.
   - Mostly clean, solid paint with light grain and the odd small chip (1.5%).
   - New: a grain normal map.
   - Images: colour 81187869737239, normal 83418647404949, roughness 108697626506455.
   - The old ids are kept on the variant's attributes `OldColorMap` / `OldRoughnessMap`.
   - Same `CL_RoadPaintWorn` variant and 8 studs a tile = 128 px a stud.
   - **State at save:** the three images were Approved, but Roblox was still making their texture-pack copy. Studio's log said "Asset content representation is being generated", so the lines showed flat grey in the after shot.
   - This is the known fresh-image wait. Check again later: the lines should turn clean white / yellow with fine grain.
   - To retry in Studio: clone `MaterialService.CL_RoadPaintWorn`, destroy the old one, then parent the clone.
4. **Undo:** every changed part carries attribute `OldVariant` = "" (it had none before).
   - The rule set `meshRoads` in `tools/yangon/YangonMaterials.luau` re-applies all of it.

## Before / after (car eye height, Kabar Aye Pagoda Road by Myanmar Plaza)
![[2026-11-27 Sharp textures - before (Kabar Aye kerb close-up).jpg]]
![[2026-11-27 Sharp textures - step 1 kerbs (YgnKerb).jpg]]
![[2026-11-27 Sharp textures - after (Kabar Aye kerb close-up).jpg]]

## Other textures checked (all 96 MaterialVariants)
- **Fine:**
  - the Ygn library (0.75 to 12 studs a tile, 1024 px);
  - YgnRoadAsphalt 24 and YgnRoadConcrete 32 (roads session);
  - the kit walls `YgnRenderWeathered*` 36 / 48 (buildings session; streamed in near the camera);
  - the far shells `YgnShell*` 60 (far only).
- **Still on the old Monaco overrides, smaller spots:**
  - Parks: 511 Concrete, 369 Asphalt, 179 Slate parts (paths, courts);
  - `VisibleFix_A` / `_H`: 172 Asphalt `RoadFill` parts (RivAsphalt, 16 studs a tile; next to the new asphalt they may not match: roads session);
  - Walkable 90, Sites 55, Green 57, CarCare 37, Landmarks 26.
  - These are off the main roads. Next pass: give them Ygn variants, or set the base overrides (Concrete, Asphalt, Slate, Plaster, Limestone) to the Ygn ones.

## Phones
- Nothing here costs more memory per map: the same 1024 px size as the asphalt, and the pavement reuses the kerb's maps.
- One new texture set in all: the line paint's normal map.
- Roblox lowers texture sizes on low graphics levels itself, so phones on low get softer maps anyway.
- Not checked on a real phone.
