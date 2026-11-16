---
tags: [city-legends, yangon, 1to1, pagoda, generator]
created: 2026-11-16
---
# Pagoda generator (1:1 Yangon)

> Owner (16 Nov): "158 pagodas are bare" ([[2026-11-16 Audit - What is missing from the Yangon map]]); "run them all at once".
> This job: every ORDINARY pagoda / stupa. Not here (their own jobs): Shwedagon (and everything on its platform, Naungdawgyi included), Sule, Botataung, Chaukhtatgyi, Ngahtatgyi, Maha Wizaya, Kaba Aye ([[2026-11-16 Kaba Aye 3D model]]).

## Steps (all in `Games/CityLegends/tools/yangon/`)
1. `city/pagodas_extract.py`: every pagoda / stupa in the OSM box with ALL tags, straight from `build/osm_extract/myanmar-261112.osm.pbf` (e0_extract drops the tags). Picks `man_made=stupa`, `building=pagoda/stupa`, buddhist `place_of_worship` / shrines / attractions whose name says pagoda, zedi, paya, ceti (also in Burmese). -> `build/pagodas/pagodas_osm.json`. Takes ~4 min (pyosmium 4 `FileProcessor` with a tag filter; the plain area handler took 17 min).
2. `city/pagoda_kit.py`: the stupa kit (pure Python, `glb.py`). -> `imports/sync/pagodas/pagoda_kit.glb` + `build/pagodas/pagoda_kit.json`. Check: `city/pagoda_kit_check.py`.
3. `YANGON_SCALE=1to1 python city/pagodas_plan.py`: sizes, shapes, colours, ground, exclusions. -> `build/pagodas/pagodas.json` (all), `build/pagodas/PagodaData.txt` (the rows to place now). Satellite check sheets: `city/pagoda_esri.py` (`sheet()` -> `build/pagodas/sheet_placed.jpg`, `sheet_rest.jpg`).
4. Studio: `PagodaPlace.luau` (kit from asset 129014360989342 into `ServerStorage.YgnPagodaKit`, copies into `Workspace.Yangon1to1.Pagodas`).

## The kit (5 size classes x 6 pieces = 30 unique meshes)
Built from the Kaba Aye pieces (bell profile, moulding steps, ringed cone, lotus petal rows, banana bud, hti with mast, vane and orb), as one parametric zedi on a base width W.
| Piece | What | Colour by scheme |
|---|---|---|
| BASE_sq / BASE_oct / BASE_rd | terraces in the real footprint's shape (1-4 steps) + 3 round moulding rings | gold / white / mosaic |
| BELL | bell + 2 rings + inverted bowl + ringed cone | gold / white / mosaic |
| TOP | lotus petal rows + banana bud | gold / white / mosaic |
| HTI | 3-7 umbrella tiers, mast, vane, orb | always gold |

| Class | Base width | Reference W | Segments | Terraces | Triangles per pagoda |
|---|---|---|---|---|---|
| XS | under 5 m | 3 m | 12 | 1 | ~1,500 |
| S | 5-12 m | 8 m | 16 | 2 | ~2,000 |
| M | 12-25 m | 18 m | 24 | 3 | ~3,500 |
| L | 25-45 m | 35 m | 32 | 3 | ~5,000 |
| XL | over 45 m | 60 m | 48 | 4 | ~7,500-8,900 |

- **Proportions (W units, H = 1.9 W):** terraces 0-0.30 (half-width 0.50 -> 0.37), mouldings 0.30-0.48, bell 0.48-0.90 (r 0.25 -> 0.115), bowl and ringed cone to 1.22, lotus to 1.38, bud to 1.55, hti to 1.90.
- **Height:** OSM `height` when tagged (none of these had one), else **H = 1.9 x W**. Yangon zedi run 1.6-2.2 x their base width (Kaba Aye's bell, Botataung, small monastery zedi 6-8 m on 3.5-4 m); 1.9 is the middle. The placer scales Y by itself, so a real height can go in per pagoda.
- **No flicker / overlap:** no bottoms, every piece stands open-bottomed on the top of the one below, skirt to -0.05 W into the ground. `pagoda_kit_check.py` (every class x shape, assembled, scaled to the class's smallest real width, through `flicker_check.py`): **0 flicker pairs, 0 duplicate triangles.**
- UVs: box projection, 1 UV = 1 stud at the reference size. Vertex colours white (no tint on the MaterialVariant).

## How each pagoda is sized and coloured
- `man_made=stupa` / `building=pagoda` outline = the stupa: W = short side of the smallest box round it (round ones: 2 x sqrt(area / pi)); shape from corner count and how much of the box it fills (round / octagonal / square); turned to the outline.
- A `place_of_worship` outline over 900 m2 = the compound: the most stupa-like real footprint inside it (OSM + Microsoft, `build/footprints/ygn_footprints.json`: compact, nearest the middle); a compact compound outline with nothing inside is taken as the stupa; else 0.45 x the compound's short side.
- Points: the stupa-like footprint within 12 m, else 6 m (stupa) / 10 m (named pagoda).
- **Then checked by eye on Esri z19 satellite (the photo wins):** `PHOTO` in `pagodas_plan.py` moves, resizes, recolours or drops each one (21 dropped: halls, a Hindu temple, points on roads, and 2 compounds of many small stupas that need their own layout). Automatic gold finding on the satellite was tried and dropped (pale or shaded gold missed, dry trees caught).
- Colour schemes: **gold** (all gold), **whitegold** (white terraces, gold from the bell up), **whitetop** (white terraces and bell, gold lotus, bud and hti), **white** (white, gold hti), **mosaic** (grey-green mirror glass, gold hti: Sein Yaung Chi).
- Materials (Kaba Aye settled values): gold = Metal + `YgnGoldLeaf`, Color (226, 222, 245); white = SmoothPlastic (255, 255, 250); mosaic = Foil (150, 160, 140), Reflectance 0.2.

## Counts (16 Nov)
| What | Count |
|---|---|
| OSM pagoda / stupa objects in the 227 km2 box | **228** (189 outlines, 39 points) |
| On the landmark jobs' sites (skipped) | 156: 149 on Shwedagon's platform (its 64 plinth stupas, Naungdawgyi and the rest), Sule 2, Botataung 2, Chaukhtatgyi 1, Ngahtatgyi 1, Kaba Aye 1 |
| Duplicates (a point inside an outline, the same outline twice) | 8 |
| Dropped after the satellite check (halls, a Hindu temple, points on roads or roofs) | 14 |
| Compounds of many small stupas that need their own layout (Kyitewaing, Thuwunna Myo Oo) | 2 (dropped for now) |
| **Ordinary pagodas in the data** (`build/pagodas/pagodas.json`) | **48**: M 23, S 15, L 8, XS 2; square 35, octagonal 8, round 5; gold 25, whitegold 10, whitetop 9, white 3, mosaic 1 |
| **Placed in Studio now** (in and within ~3 km of P1) | **26** (1 inside P1 on its terrain, 2 on Shwedagon's temp hill, 23 on temp plates) |
| Data only, placed with their districts later | 22 |

- The audit's "158 bare" counted the Shwedagon platform's stupas; outside the landmark jobs there are 48 real ordinary pagodas (plus 2 many-stupa compounds).
- **Studio:** `Workspace.Yangon1to1.Pagodas` (26 Models named by OSM id, attributes Name / Class / Scheme / Shape / Ground; 179 parts: 4 MeshParts + 2 invisible collision parts each, + 23 `<id>_TEMP` plates). Kit templates in `ServerStorage.YgnPagodaKit` (30 MeshParts). **Kit asset 129014360989342** (Open Cloud Model, group 33151111). Unique meshes: 30 in the kit, 21 used so far. Not saved (the coordinator saves).
- Studio fixes: the P1 pagoda (w405364332) was 9 m and moved 5 m east so it clears the compound walls the P1 buildings job had built; w444474741 / w444474745 stand on `Landmarks.Shwedagon_Hill_TEMP` (raycast to it; no plates).
- Checks: no part overlaps (bounds test against every other part, except the two set into the Shwedagon temp hill's slope, as meant); grazing-angle close-up shows no flicker.

## Pictures
- ![[Yangon pagodas - Eain Taw Yar vs satellite.jpg]]
- ![[Yangon pagodas - Maha Bodhi Su Taung Pyae vs satellite.jpg]]
- ![[Yangon pagodas - Sein Yaung Chi vs photo.jpg]]
- ![[Yangon pagodas - P1 gold zedi in its compound (Studio).jpg]]
- ![[Yangon pagodas - grazing check Eain Taw Yar (Studio).jpg]]

## What still differs / to do
- **Only a few pagodas have a real ground photo online** (Commons is nearly empty for them); colours and sizes come from Esri satellite. Heights are the 1.9 x W rule except Original Kabar Aye (OSM height 20 m).
- **Sein Yaung Chi** is a mirror-mosaic tower shrine, not a bell zedi: the mosaic-coloured kit stupa is a stand-in until its own model. **Swe Taw Myat (Buddha Tooth)** is a big hollow pagoda: a 45 m stand-in in the data.
- Real pagodas have shrines (tazaung), corner stupas, chinthe, gates and halls round them; this kit is the stupa alone.
- Kyitewaing and Thuwunna Myo Oo (rows of hundreds of small stupas) need their own layout generator.
- 22 pagodas wait for their districts; when a district gets its 1:1 terrain, re-run the placer for its rows (it raycasts to terrain and leaves out the plate).

## Rules applied
- **No interiors** (none of these has an interior built; Sein Yaung Chi and Swe Taw Myat are hollow and have inside photos online, so they can get one later with their own models).
- Ground: raycast to the P1 terrain where it exists (lowest of 5 hits under the base), else the GLO-30 height (lowest of 5 samples) and a flat concrete plate `<id>_TEMP` (top at the ground, W x 1.2 + 4 studs).
- Collision: two invisible parts per pagoda (terrace box, bell cylinder); visual meshes CanCollide / CanQuery / CanTouch off, CollisionFidelity Box.
