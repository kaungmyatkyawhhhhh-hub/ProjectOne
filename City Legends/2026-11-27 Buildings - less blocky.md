---
tags: [city-legends, yangon, realism, buildings]
created: 2026-11-27
---
# Buildings: less blocky (27 Nov)

Owner, 27 Nov: "also make the buildings look less blocky and more realistic to real life". This follows the TorqX Racing comparison ([[2026-11-26 Study - TorqX Racing TikTok (what makes it look real)]]) and [[2026-11-27 Building fronts - glass and walls]].

Applied in Studio (Edit) and saved. Not published.

## What made them read as blocks (Play, noon, same spots as the building-fronts note)
Checked against the real walk-up photos (`Games/CityLegends/build/landmarks/refs/kit/walkup_apartment/`: Yankin 5-storey blocks, roofscape from Sakura) and the measured palette in [[2026-11-16 Critique - Yangon kit vs real photos]].

1. **Walls too clean.** Every ordinary kit wall used the *painted* render, so every building was one flat pastel colour.
   - Real Yangon walls read 15-35% darker than their paint, with black rain and mildew streaks.
   - The few buildings already on the *stained* render (KWG) were the only ones that looked real in the shots.
2. **Big blank side walls.** Side and party walls are plain Parts (0.02-stud sheets). They showed as large flat, clean slabs: the right-hand building in the township shot.
3. **Near-white flat roofs.** Roof slabs used bare concrete and read as a bright white plate from any raised view. Real roofs are dark, stained concrete.
4. **Sharp box tops.** The roof edge was a 0.12 m band. Real walk-ups have a thick roof slab edge that sticks out, with a dark shadow under it.
5. **Far shells.** The window grid was there, but the walls were clean (light stains under the sills only).

Already fine, so left alone: window reveals (0.35 m), sills, grilles, cages, AC units, tanks, dishes and stair rooms on the roofs, and the glass from this morning.

## Changes
| # | Change | Where | Part cost |
|---|---|---|---|
| 1 | All ordinary kit walls (KW0-KW7, KWB) and the plain side / party walls use the **stained render** `YgnRenderStained` (was `YgnRenderPainted`) | `KD.VARIANT` in `src/shared/YangonKitData.lua`, `YangonKitPlace.VARIANT` | 0 |
| 2 | Flat roof slabs (KCO) use **stained concrete** `YgnConcreteStained` (was bare concrete) | same tables | 0 |
| 3 | **Roof slab lip**: a 0.32 x 0.32 m slab edge from H - 0.1, with end caps; walk-up floor slab edges 0.18 x 0.22 m (were 0.12 x 0.15) | `kit_panels.py` (`lip`, `ROOF_LIP`, `FLOOR_BAND`, `parapet(heavy=)`) -> `city/kit_walls.py` -> 6 Models -> `KitGlassApply` (new KWX branch): 520 wall templates replaced | 0 parts, wall triangles 277,890 -> 279,026 (+0.4%) |
| 4 | **Far shells weathered**: mottling and streaks under every floor slab, drawn on their own random stream, so the windows, normal and roughness maps stay the same | `shell_facades.weather()` -> 12 new colour maps as `ColorMap` of `YgnShell<Set><0-3>` | 0 |

- Colonial rows keep their own heavy cornice. Tower crowns keep the light band: the lip flickered against the striped crown's band.
- Ids: `Games/CityLegends/tools/yangon/city/kit_walls_ids.json` (the first 6 model uploads had the lip on tower crowns too; they are unused).
- Landmarks were not touched.

## Pictures (Play, noon)
| Spot | Before | After |
|---|---|---|
| Township street (34640, 50, 28376) looking west | ![[2026-11-27 Buildings less blocky - township street noon (Play) - before.jpg]] | ![[2026-11-27 Buildings less blocky - township street noon (Play) - after.jpg]] |
| Township rooftops (34760, 120, 28520) | ![[2026-11-27 Buildings less blocky - township rooftops noon (Play) - before.jpg]] | ![[2026-11-27 Buildings less blocky - township rooftops noon (Play) - after.jpg]] |
| Downtown street (35780, 30, 45290) looking north | ![[2026-11-27 Buildings less blocky - downtown street noon (Play) - before.jpg]] | ![[2026-11-27 Buildings less blocky - downtown street noon (Play) - after.jpg]] |
| Kabar Aye spawn (34605, 52, 27600) | ![[2026-11-27 Buildings less blocky - Kabar Aye spawn noon (Play) - before.jpg]] | ![[2026-11-27 Buildings less blocky - Kabar Aye spawn noon (Play) - after.jpg]] |

- Roof lip corner, grazing close-up: ![[2026-11-27 Buildings less blocky - roof lip corner close-up (Play).jpg]]
- Far shell maps (walk-up, shop, villa): ![[2026-11-27 Buildings less blocky - far shell facade maps weathered.png]]
- The spawn view is almost all landmarks (Myanmar Plaza), which were left alone on purpose, so it barely changes.
- The sky in the "after" township shots is hazier because another session was testing the lighting at the same time. It is not part of this change.

## Numbers (Studio Play on PC; kit parts within 1,000 studs / within 300 studs of the camera)
| Spot | Before | After |
|---|---|---|
| Township street | 7,324 / 926 | 7,639 / 926 |
| Township rooftops | 8,330 / 1,035 | 8,822 / 1,035 |
| Downtown street | 9,298 / 803 | 9,298 / 803 |
| Kabar Aye spawn | 1,767 / 62 | 2,027 / 64 |

- Parts near the camera did not change. The totals differ only by how far streaming had got.
- FPS was 11-15 before and 25-59 after. That gap is Studio load (other sessions, the menu still up in the first run), not this change. With the same parts and +0.4% wall triangles, phone cost should be about the same. **Not measured on a phone.**
- Flicker test `kit_flicker_test.py P1`: kit 436 pieces, **0** flickering pairs (the first try had 6 on tower crowns: fixed). Placed sample: 2 pairs, both the old KWC compound walls (same as before). Shells: 0.
- P3 (downtown) flicker test: see the end of `build/kit_walls/flicker_P3.txt`.

## Not checked / risks
- The stained render tiles every 9 studs. On a big blank side wall the blotch repeat can be seen up close.
- Every ordinary wall now looks old. Real villas are cleaner (87% neutral, lightly stained), so a per-age or per-archetype choice could come later.
- The far shells' new maps were checked in the preview picture only, not in Play from a distance (moving the camera loads the kit there).
- Fresh meshes take a few seconds to load on a client: the first frames after the update showed roofs with no walls, until the walls loaded.
- New districts: a full `buildings_1to1.py` run writes the lip itself. For existing panels, run `kit_walls.py` and `KitGlassApply`.
- Not tested on a phone.
