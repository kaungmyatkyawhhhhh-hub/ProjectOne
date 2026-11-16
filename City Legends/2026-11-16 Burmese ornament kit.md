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
| `gable_fingers(w, h, n, side)` | the stepped skyline of carved flame fingers behind a gable frame, one side a piece (Kaba porch, Botataung gate) | 320 / 280 |
| `flame_blade(w, h, t)` | a free-standing carved flame slab (`micro` 62, `lo` 86) for the hundreds of Shwedagon hall fins | 86 / 62 |

- **Real depth:** every piece is stacked slabs with chamfered (bevelled) front edges, standing 0.03-0.2 m proud, so the gold reads by its own shadows. Every piece is checked at <= 600 triangles (`Piece.check`).
- Outlines in code: `flame_outline` (leaf blade with flame tongues that flick up), `scroll` / `curl_outline` (acanthus leaf curling into a volute), `ogee`, `star`. Each landmark maps the kit groups (G gold, R red field, J green glass, W white rim, B hood band, P carved field) to its own looks.
- Adapters: `into_mb` (kaba / maha Blender `MB`), `into_geo` (geom3d / PGeo / Shwedagon `G`), `into_model` (solid3d `Model`).
- UVs: box-projected by each exporter as before (1 UV = 1 stud).
- **Carved field normal map:** `tools/yangon/landmarks3d/ornament_textures.py` draws a seamless heightfield (scroll leaves round a rosette, veins, bead border) and writes normal / colour (white with dark cavities, so the part Color tints it) / roughness / metalness maps -> `build/landmarks/ornament/tex/`. Uploaded (group 33151111): normal **79887407051122**, colour (gold baked in) **74025339071700**, roughness **93959854716182**, metalness v2 (0.45-0.75) **128788515905923**. MaterialVariant **YgnCarvedGold** (Metal, StudsPerTile 1.5) in MaterialService; parts using it get Color (255, 250, 240) (group GPN).
- Traps: a white colour map with a gold part Color read silver-grey on Metal (bake the gold into the map); full metalness read olive-khaki under the Yangon sky.
- No flicker: slab fronts step at least 0.02 m (0.06 studs) apart; pieces checked in each landmark's own flicker test (0 pairs everywhere).

## Where it went (16 Nov, in Studio, not saved)
| Landmark | What changed | Triangles before -> after | Live asset |
|---|---|---|---|
| Kaba Aye | porch gable (frame, fingers, sun disc, scrolls), 88 merlons, 20 arch hoods, 15 leaf panels | 51,749 -> 59,904 | 105750762375498 |
| Sule | pyatthat crests + corner horns on every tier, 8 carved bell panels, 8 shrine door pediments | 24,529 -> 65,793 | 132710134067811 |
| Botataung | gate gable (frame, fingers, sun, scrolls), pond walkway ridge crests, pond pyatthat, carved corridor walls | 23,953 -> 34,754 | 86279914319430 |
| Maha Wizaya | carved flames along both pediment slopes + flame finial on 4 porches, flame rows on the 3 terrace edges | 36,336 -> 56,469 | 132275924726216 |
| Shwedagon | 62 niche-shrine flame hoods, flame finials + gable flames on the lowest tier of all 62 hall pyatthats | 174,033 -> 215,241 | 108253982230149 + 98028844589108 |
| Ngahtatgyi | teak backdrop: 89 carved scroll leaves, 2 layered gold flames | 47,841 -> ~48,400 | 133663873545500 |
| Chaukhtatgyi | head v4 (see its note) + crown filigree from the kit | 70,954 -> 76,717 | 123824298681155 |
- Flicker test: 0 pairs on every landmark (each script's own test). Grazing close-ups in Studio: no flicker seen.
- Swap tools: `tools/yangon/landmarks3d/VisualSwap.luau` (re-placed upload lined up on an unchanged reference part, looks copied by name; for Kaba Aye), the old placers for the rest (each replaces its landmark: no duplicates, collision rebuilt the same). The placers went to Studio as ModuleScripts in one tools upload (`pack_tools.py`, a new version of asset 133014134133489), not pasted.
- Pictures (photo | before | after): ![[Ornament kit - Kaba Aye photo before after.jpg]] ![[Ornament kit - Sule photo before after.jpg]] ![[Ornament kit - Botataung photo before after.jpg]] ![[Ornament kit - Maha Wizaya photo before after.jpg]] ![[Ornament kit - Shwedagon photo before after.jpg]] ![[Ornament kit - Ngahtatgyi photo before after.jpg]] ![[Ornament kit - Chaukhtatgyi head v4 photo before after.jpg]]
- Close-ups: ![[Ornament kit - Kaba Aye porch grazing check.jpg]] ![[Ornament kit - Sule bell carved panels.jpg]] ![[Ornament kit - Botataung corridor carved panels.jpg]] ![[Ornament kit - pieces render.jpg]]
- **The sky changed during the run** (another job's lighting: the before shots are hazy PlayLight, the after shots a clear blue sky), so compare shapes, not colours.

## Still differs from the photos
- The real carving is far denser: our crests and gables have a few big flames and scrolls where the photos show many small layered leaves; the fine detail now comes only from the carved field map (panels, corridor).
- The carved field (YgnCarvedGold) reads olive-khaki in the Botataung corridor, darker than the photo's bright gold; a brighter colour map or a Foil-based variant is the next try.
- The ogee gable frame is concave (S-curved sides); the Botataung gate's real gable is straighter.
- Shwedagon: only the lowest tier of each hall's pyatthat got carved flames (budget: 744 finials and 1,060 fins in unique hall meshes); higher tiers keep the flat fins.
- Traps found: a big flat MeshPart (Botataung parquet) lost half its triangles in Studio at RenderFidelity Automatic: set Precise. A MCP call that loads a model can block Studio ~30 s ("Target is not reachable"): wait, then read the status attribute.
