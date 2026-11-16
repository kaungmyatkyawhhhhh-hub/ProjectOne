---
tags: [city-legends, yangon, 3d, landmark, kit, ornament]
created: 2026-11-16
---
# Burmese ornament kit (carved gold work for every Yangon landmark)

> Job (16 Nov): the carved gold work was the biggest look gap against the photos at every landmark: crests, pyatthat gables, merlons, flame finials and panels were flat cut-out plates. Now ONE reusable kit makes them as real relief.

## Reference
- Real photos (Commons, licences in the folder's `sources_*.json`): `Games/CityLegends/imports/refs/exploded/ornament/ref1_pyatthat_crest_shwedagon.jpg`, `ref2_flame_finials_shwedagon.jpg`, `ref3_gable_kaba_aye.jpg`, `ref4_gable_botataung.jpg`.
- Exploded close-up sheet (ChatGPT in the owner's Chrome, the 4 photos attached, "copied exactly"; chat "Exploded View Reference Sheet"): `imports/refs/exploded/ornament/ornament_exploded_v1_lowres.png`.
  - Left half: one pyatthat tier crest pulled apart: back board (stepped flame skyline), scroll leaf row, flame fingers, corner flame (upswept horn), bead moulding, scalloped band with green glass drops. Right half: the flame finial: base knob, a pair of curled leaves, the lobed main blade, a raised beaded spine, the tip.
  - **Only a low-res copy (380 x 253) was saved**: this time the browser tool refused the clicks and the zoom capture, so the full-res trick could not run. The parts and layers read fine from it; sizes come from the photos.

## The kit
`Games/CityLegends/tools/yangon/landmarks3d/ornament_kit.py` (pure Python, no shapely or bpy, so both the pure-Python landmark scripts and headless Blender 3.6 import it). `python ornament_kit.py` prints each piece's triangles; `python ornament_kit.py dump <out.json>` writes all pieces for `preview_pagoda_blend.py`.

| Piece | What | Triangles (hi / lo) |
|---|---|---|
| `flame_finial(h)` | kanote finial: ribbed knob, curled leaf pair, lobed blade 0.07 h thick with bevelled faces, raised beaded spine on both faces (`micro`: square knob + thick blade, 78) | 564 / 290 |
| `crest_segment(L, h, n)` | one run of a tier crest: back board, bead moulding, scalloped band with green glass drops, scroll leaves, n flame fingers (`xlo`: board + fingers only, ~55 a finger) | 486 / 448 |
| `crest_corner(h)` | the upswept corner horn with scroll barbs | 374 / 96 |
| `merlon_leaf(h, w)` | parapet leaf: lobed leaf slab 0.09 m, raised inner leaf 0.05, spine 0.04, foot scrolls | 249 / 109 |
| `gable_frame(w, h)` | porch pediment: red board, gold ogee frame band 0.1 m proud, flame fingers up its edge, apex flame, raised sun disc (rays + boss), eave-end scrolls | 566 / 390 |
| `arch_hood(a, rise, band)` | scalloped hood band, raised rim, crown flame, springing scrolls (both switchable) | 360 |
| `panel_tile(w, h)` | bevelled frame, raised 8-petal rosette and boss, corner scrolls, a field in group P | 338 |
| `flame_blade(w, h, t)` | a free-standing carved flame slab (`micro` 62, `lo` 86) for the hundreds of Shwedagon hall fins | 86 / 62 |

- **Real depth:** every piece is stacked slabs with chamfered (bevelled) front edges, standing 0.03-0.2 m proud, so the gold reads by its own shadows. Every piece is checked at <= 600 triangles (`Piece.check`).
- Outlines in code: `flame_outline` (leaf blade with flame tongues that flick up), `scroll` / `curl_outline` (acanthus leaf curling into a volute), `ogee`, `star`. Each landmark maps the kit groups (G gold, R red field, J green glass, W white rim, B hood band, P carved field) to its own looks.
- Adapters: `into_mb` (kaba / maha Blender `MB`), `into_geo` (geom3d / PGeo / Shwedagon `G`), `into_model` (solid3d `Model`).
- UVs: box-projected by each exporter as before (1 UV = 1 stud).
- **Carved field normal map:** `tools/yangon/landmarks3d/ornament_textures.py` draws a seamless heightfield (scroll leaves round a rosette, veins, bead border) and writes normal / colour (white with dark cavities, so the part Color tints it) / roughness / metalness maps -> `build/landmarks/ornament/tex/`. Uploaded (group 33151111): normal **79887407051122**, colour **123978472349307**, roughness **93959854716182**, metalness **84157150462921**. MaterialVariant **YgnCarvedGold** (Metal, StudsPerTile 3) in MaterialService.
- No flicker: slab fronts step at least 0.02 m (0.06 studs) apart; pieces checked in each landmark's own flicker test (0 pairs everywhere).

## Where it went (assets in `build/landmarks/ornament/asset_ids.json`)
See each landmark's note, section "Ornament kit pass (16 Nov)".
