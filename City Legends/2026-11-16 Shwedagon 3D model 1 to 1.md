---
tags: [city-legends, yangon, 3d, landmark, shwedagon, 1to1]
created: 2026-11-16
---
# Shwedagon Pagoda: 3D model at 1:1 (in Studio)

Built from [[2026-11-16 Research - Shwedagon 1 to 1 blueprint]] and the photos in `build/landmarks/refs/shwedagon/`. Pure Python (no Blender). 3 studs = 1 m.

## Files
- Build script: `Games/CityLegends/tools/yangon/landmarks3d/shwedagon3d.py`
  - Run: `python shwedagon3d.py` (add `check` for the flicker test).
  - Writes `imports/sync/landmarks/shwedagon/shw_1.glb` and `shw_2.glb` (gitignored), plus `build/landmarks/shwedagon/place.json` and `ShwData.luau` (the placement data).
- Studio placer: `Games/CityLegends/tools/yangon/landmarks3d/ShwedagonPlace.luau` (`place(holding, dataText, parent)`).
- The data and the placer go to Studio inside the rbxmx `imports/sync/landmarks/shwedagon/shw_tools.rbxmx`, uploaded as a new version of asset 133014134133489.

## In Studio (16 Nov)
- `Workspace.Yangon1to1.Landmarks.Shwedagon`:
  - `Visual`: 748 MeshParts in one Model per piece.
  - `Collision`: 507 invisible parts: platform strips, plinth, terraces, stupa cylinders, halls, posts, stair ramps and side rails.
- `Workspace.Yangon1to1.Landmarks.Shwedagon_Hill_TEMP`: the temporary hill, one mesh. It collides (PreciseConvexDecomposition). Delete it when the 1:1 terrain reaches Shwedagon.
- The frame: stupa axis at world X 33065.66, Z 37182.89, platform Y 174 (58 m). The complex is turned +17 deg about Y.
- Mesh assets (Open Cloud Model, group 33151111): **73419025900706** and **103394098296729** (v3, live).
  - Older uploads, not used: 100235429218200, 127579074421330 (v1), 112754602972830, 116703047224988 (v2).
- Visual meshes: CollisionFidelity Box, CanQuery, CanCollide and CanTouch off.
- Not saved: the owner saves the place.

## Real sizes used
| What | Value | Source |
|---|---|---|
| Total height (platform to orb tip) | 99.36 m | Trustees' 8-part table (326 ft) |
| Plinth | 6.13 m high; faces at 51.4 m with 11 m wide bays to 56 m; stepped chamfered corners | OSM way 779515064, Trustees |
| 3 terraces | 4.29 m each; half-widths 41, 37.6, 34.2 m; redented corners; 3 moulding bands per step | Trustees, OSM |
| Octagonal dais | 19.0 to 26.87 m; 60 m across at the foot, 46 m at the top | Trustees, OSM |
| 5 turban rings | 26.87 to 34.24 m; diameter 42.4 to 31 m | Trustees, OSM, photo |
| Bell + inverted bowl | 34.24 to 48.24 m; rim about 31 m; girdle band; 16 garlands and shoulder ornaments | Trustees, photo, Sacred Destinations |
| 7 rings | 48.24 to 61.44 m; 18 to 9.4 m | Trustees, photo |
| Lotus | 61.44 to 70.23 m; 28 down petals, bead band, 28 up petals | Trustees, photo |
| Banana bud | 70.23 to 86.06 m; widest 7.2 m | Trustees, photo, OSM |
| Hti | 7 tiers, 4.72 to 1.07 m across, bell fringe; screw-pine flower 3.66 m; vane ring; orb 0.56 m x 0.27 m | Trustees |
| Plinth top | 64 small stupas (4.4 m) + 4 cardinal stupas (8.4 m) | Blueprint 1c |
| Plinth foot | 62 niche shrines (3 x 3 m, about 6.8 m with spire), flame hood, seated image | OSM shrines, photos |
| Platform | OSM outline 213 x 278 m, stupa off-centre, white marble with grey-beige octagon bands and radial strips | OSM, Trustees, photos |
| 4 adoration halls | 18 x 15 m against the plinth bays, 7-tier gilded pyatthat with green necks, seated Buddha | OSM, photos |
| 12 planetary posts | at the OSM points: basin, Buddha, red post and sign, guardian, small spire, rail, the day's animal | OSM, post photos |
| Other platform buildings | 70 OSM footprints. Concave ones are split into up to 4 rectangles. Each footprint shrinks until nothing overlaps; 3 at the stair tops left out. 34 OSM stupas (gold, white on the SW). | OSM `platform_plan.json` |
| Naungdawgyi | 46 m, the main profile scaled, plus 28 small stupas | Trustees, OSM |
| Great bells | Singu 2.34 m high, 2.06 m mouth; Tharrawaddy 2.59 m, 2.34 m mouth; open pavilions with 3-tier roofs | Trustees |
| Bodhi trees | 13 on the platform; the 4 corner ones 18 m with railed gilded planters | OSM, Trustees |
| Stairways | OSM lines from the top to the foot, widths S 19.2, E 16.8, N 18.3, W 12.2 m. Steps: S 143 (real 152), E 190 (204), N 111 (143), W 160 (164); 0.15 m risers from the DEM ground. Roof sections S 10, E 5, N 6, W 5. Spires: 5 tiers at the top, 9 at the S gate, 7 at the others. Red columns, shop openings. | Trustees, OSM, GLO-30 |
| Chinthe | a pair at each foot: S 9 m, others 5.5 m | Blueprint 2b |
| Elevators | S, E, N towers + covered bridges (simple boxes) | OSM |
| Hill (TEMP) | Copernicus GLO-30 (trees opened out), 10 m grid, platform cut out, stair corridors carved; 124 instanced slope trees | GLO-30 |

## Budget and checks
- Triangles placed: **174,033**. That is the landmark about 154,000 plus about 20,000 for the temporary hill and slope trees.
- 102 unique meshes, 364 instances: repeated stupas, shrines, posts, trees and chinthe are one mesh each.
  - Biggest pieces: Halls 26.4k, Stupa 20.0k, Niche shrines 62 x 305, Plinth stupas 92 x 166, stairs 4.7k to 7.4k each.
- **Flicker / overlap test:** `shwedagon3d.py check` tests every placed triangle with `flicker_check.py`: **0 pairs**.
  - The plan-footprint test on everything standing on the platform also gives **0 overlaps**.
  - Fixed on the way: duplicate niche slots, niche cornices meeting at the corners, two Bodhi planters overlapping, stair treads coplanar with the platform floor, a bell pavilion against a hall.
- Grazing close-up in Studio (`build/landmarks/shwedagon/ingame_graze_niches.jpg`): no flicker seen.

## Pictures (Studio, PlayLight 13)
In `Games/CityLegends/build/landmarks/shwedagon/` (photo | Studio):
- `compare_platform.jpg`
- `compare_above.jpg`
- `compare_south_gate.jpg`
- `compare_stair_inside.jpg`
- `compare_far_west.jpg`
- `compare_south_hall.jpg`

Copies in this folder: "Shwedagon 1to1 - vs photo (...)".

## Look settled in Studio
- Gold: Metal + YgnGoldLeaf (226,222,245) below the bell's girdle band; Metal + YgnGoldPlate (226,222,245) above it. At this distance the plate grid doesn't show.
- Floor: Marble + YgnMarbleWhite rendered mid grey, darker than the beige inlay. Changed to SmoothPlastic (204,202,198), with the inlay SmoothPlastic (150,138,130). It now reads as the photos' white marble with low-contrast bands.
- Stair outer walls: white with a gilded eave band. The stained render variant read as grey stone. The platform's retaining walls keep Plaster + YgnRenderStained.

## What still differs from the photos
- **Gold** reads flat yellow, with less of the mirror sparkle and dark reflections of the real plates. The terraces read as a few big steps; the real ones show many fine mouldings.
- **Niche shrines and pavilions** are layered plates and frusta without the carved flame work. The halls' pyatthat tier counts are not checked against each hall's photos (adoration halls use 7). The OSM halls' styles (red, white or gold roofs; 3, 5 or 7 tiers) are picked by rule, not from photos.
- **The floor** has no teal walkway. One Commons photo shows a teal or green band, which the blueprint missed: check it.
- **Stairways** are straight lines from the top to the foot (the real S and N have slight bends). They have no paintings, lamps, ogres, 1842 arch, crocodiles or escalators. The shop fronts are flat dark openings.
- **Animals** are block stand-ins. **Chinthe** are simplified.
- **Hill**: the TEMP heightfield is smooth, with sparse slope trees; the real hill is dense forest. The middle terrace (museums, parking) is not modelled.
- **Night**: no floodlights or glow yet (blueprint section 4). **Done 27 Nov:** [[2026-11-27 Shwedagon night floodlighting]] (glossy emissive gold at night, 14 floods, hti sparkle).
- The far views wash out in the current Edit haze (Atmosphere), unlike the clear photos.
- 3 OSM buildings at the stair tops are left out, because the corridors use that space.

## Next
- A night pass (floodlit gold, high masts, lit niches).
- Carved detail on the adoration halls and the gate pavilion.
- Remove `Shwedagon_Hill_TEMP` when the 1:1 terrain is built there.

## Ornament kit pass (16 Nov)
- The 62 niche shrines' flame hoods are carved kit flames (`flame_blade`, bevelled, 0.12 m thick) instead of two flat plates.
- Every hall pyatthat's lowest tier: carved kit flame finials (square knob + thick flame) at the corners and carved flame fins on the faces ([[2026-11-16 Burmese ornament kit]]). Higher tiers keep the old fins (budget: 744 finials and 1,060 fins in unique meshes).
- 215,241 triangles placed (was 174,033); flicker test 0 pairs; footprint overlaps 0. Assets **108253982230149** + **98028844589108**, ShwData re-sent in the tools upload; `ShwedagonPlace` replaced the old model (one copy).
- ![[Ornament kit - Shwedagon photo before after.jpg]]
