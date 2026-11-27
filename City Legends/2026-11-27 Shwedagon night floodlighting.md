---
tags: [city-legends, yangon, shwedagon, night, lighting, landmark]
created: 2026-11-27
---
# Shwedagon night floodlighting (27 Nov 2026)

Owner (27 Nov): "at night, theres lights that points to shwedagon pagoda and the shwedagon pagoda reflects golden light and at night it becomes shiny & glossy & bright irl."

Real: the stupa is floodlit from the plinth and terraces, glows bright gold against the black sky, glossy with highlights, the brightest thing in Yangon's skyline; the small stupas are lit a step dimmer; the hti sparkles. Refs: [[Yangon ref - Shwedagon at night from the east (Wikimedia Commons).jpg]], [[Yangon ref - Shwedagon night skyline over Kandawgyi (Wikimedia Commons).jpg]], blueprint section 4 in [[2026-11-16 Research - Shwedagon 1 to 1 blueprint]].

## Before / after (Play, PreviewHour 21)
![[2026-11-27 Shwedagon night - near (ref, before, after).jpg]]
![[2026-11-27 Shwedagon night - from Kandawgyi (ref, before, after).jpg]]
![[2026-11-27 Shwedagon night - from the road (before, after).jpg]]
![[2026-11-27 Shwedagon night - hti sparkle (after).jpg]]

Before: dull bronze metal under the night ambient, almost invisible from Kandawgyi and the roads. After: glossy bright gold with soft flood wash and glints near, a glowing gold cone (with the lit small stupas round it) from Kandawgyi and the city.

## What was built
- **Glossy gold at night:** `ReplicatedStorage.NightGold` holds two SurfaceAppearance templates (metal 1, roughness 0.16, white colour map tinted by `Color` 255,208,112, emissive mask white with a gold `EmissiveTint`): `Stupa` (glow 0.3 near, FarGlow 3) and `Shrine` (0.2 near, FarGlow 1: small stupas, shrines, hall and stair gold). All 244 gold meshes of `Landmarks.Shwedagon` (YgnGoldLeaf / YgnGoldPlate / YgnCarvedGold) carry tag `NightGold` + attribute `NightSA`.
- **WorldFx (client):** `WorldFx.setNightGold` puts a copy of the template on each tagged part at night and takes it off by day (the day look is untouched: the part's own gold variant). The emissive ramps from its near value (under 500 studs) to `FarGlow` (3000+ studs) twice a second, because the haze swallows the glow from far. Tagged ParticleEmitters (the hti sparkle) run at night only. Same switch as the street lamps (`lampsLit`, daylight < 0.55).
- **Floodlights:** `Landmarks.Shwedagon.Night`: 14 SpotLights in three rings aimed up the stupa (4 lamp boxes on stands on the plinth top corners at r 128 -> terraces; 6 over the dais -> bell; 4 over the bell shoulder -> rings, lotus, bud; the upper rings hang on Attachments, no visible parts), warm 255,196,120, angle 120, brightness 1.4, no shadows; plus the hti glow (PointLight 2 / 40). All `LODLight` + `DayOff`, `LodRange` 900 (x render distance).
- **Hti sparkle:** invisible box at 273 studs over the platform (the hti tiers), Sparkles-texture ParticleEmitter (volume, 30/s, size 2.4, LightEmission 1).
- **Far glow needs no real lights:** the stupa's meshes are in the Persistent `FarVisible` model, so every client has them and the emissive shows from anywhere.
- Tool: `Games/CityLegends/tools/yangon/ShwedagonNight.luau` (`ServerStorage.ClaudeTools.ShwedagonNight` in Studio: `build`, `templates`, `tag`, `rig`, `preview(night)`, `check`, `undo`). Code: `src/client/WorldFx.lua` (`setNightGold`). Studio saved v2407.

## Checks
- Day (PreviewHour 13): 0 night SurfaceAppearances, 0 lights, sparkle off; back to night: 244 on, 15 lights. No WorldFx errors.
- Cost: 15 shadowless lights, on only within 900 studs at night; FPS at the road spot 56.9 before / 56.7 after (Studio PC).
- Overlaps: lamp boxes and stands 8 studs clear of every visual mesh box, stand foot 0.06 over the plinth top (raycast on the collision); the upper lights have no parts. `check()` asserts no night SA is saved, lights off and tagged, nothing collides.

## Lessons (tuning, 27 Nov)
- Narrow strong SpotLights (60-70 deg, brightness 6-7) close to glossy gold make round hot spots ("polka dots"); 120 deg at 1.4 reads as a wash with glints.
- Emissive 0.55 up close is a flat orange blob; 0.3 keeps the tiers' shading. From 4,000+ studs the haze needs about 3, so ramp it by distance instead of one value.
- A DayOff light is cut at 560 x scale by WorldFx; a landmark seen from the hill roads needs its own `LodRange`.
- Lower metalness (0.5) made the gold dull and the glow weaker: keep metal 1 for the gold.
- Hti height: the model's hti tiers are at ~265-285 studs over the platform (the collision cylinder ends at ~262).
- Plinth lamps: the 64 plinth stupas stand at r ~142; a lamp at r 140 stood inside one. Check visual mesh boxes, not only collision, before placing fixtures (visual meshes have CanQuery off, so `GetPartsInPart` misses them).

## Round 2 (28 Nov, coordinator review)
Review of round 1: up close "one flat blown-out yellow blob" (the tiers' banding lost); from Kandawgyi "a tiny faint cone", nothing like the ref; no lake reflection. The pictures above are round 2 (the Kandawgyi one now matches the ref's framing: east shore of the lake, telephoto FOV 15).
- **Tier banding kept:** near emissive 0.3 -> 0.16 (Stupa) / 0.2 -> 0.08 (Shrine), the distance ramp starts at 900 studs (was 500), plinth floods 1.4 -> 0.9. Terraces, turban rings and the bell rim now read as bright bands with darker bands between, with gloss highlights.
- **Far: the brightest thing in the view:** `FarGlow` 3 -> 12 with a paler tint (255,226,150) for the main stupa, 1 -> 4 for the rest; the gold small stupas (`PlinthStupa`, `CardinalStupa`, `PStupa`, `Naungdawgyi`) moved from `Visual` into the Persistent `FarVisible` (attribute `MovedFrom`; `undo()` moves them back) so the whole hill of small stupas glows from across the city (they streamed out past ~4,000 studs).
- **Halo:** `FarVisible.HaloAnchor` (invisible, 140 over the platform) carries BillboardGui `NightHalo` (tag NightGold, the lamp-glow sprite, 480 x 620 studs, Brightness 4, not AlwaysOnTop so the stupa hides its middle); WorldFx fades it in from 900 to 3,500 studs (`HaloAlpha` 0.9) and grows it x1.6 (`FarScale`). Day: off.
- **Kandawgyi reflection:** the anchor's attribute `Reflect` makes WorldFx lay a client-only streak (`Camera.NightReflection`, 6 pieces) on the water along the line of sight whenever the camera stands at a shore (terrain Water starting within 220 studs toward the stupa, camera under 160 over the water): pieces widen away from the viewer, each wears the soft lamp-glow sprite and overlaps its neighbour, each 0.1 higher than the last (no flicker). 18 short raycasts twice a second, only at night and only near water. Day: hidden.
- **High masts: not built.** The blueprint only says "3 high masts" (trustees' inventory) with no positions; the real-only rule means no made-up spots.
- Checks: day (PreviewHour 13) 0 SAs, 0 lights, halo off, no streak; night again 244 SAs, halo on, streak on. FPS (Studio PC): near 58.7 with 15 lights on; road 50.3 (56.7 in round 1 there; traffic and people vary between runs, nothing of this runs at the road spot except the emissive ramp). Studio v2429.
- Lessons: a line starting with `(` after a statement is a Luau "ambiguous syntax" error that stopped the whole client (Main -> Driving -> WorldFx): assign to a local instead. A radial sprite stretched over 1,000 studs of water reads as one round blob; hard-edged bands read as a road arrow; overlapping soft sprites read as a reflection. A SurfaceGui on a Top face: canvas X runs along the part's Z (length), canvas Y across (tested with coloured frames). Atmosphere haze eats emissive gold at 4,000+ studs: ramp it by distance (x12 there) instead of one strong value that blows out up close.

## Not done / next
- Not tested on a phone or in low-end mode (SurfaceAppearance emissive on the lowest graphics level not checked).
- The 3 high masts of the blueprint are not built (no real positions found).
- The reflection only shows where terrain Water lies within 220 studs of the camera toward the stupa (Kandawgyi's shores; Inya too if in line).
