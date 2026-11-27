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

## Not done / next
- Not tested on a phone or in low-end mode (SurfaceAppearance emissive on the lowest graphics level not checked).
- No Kandawgyi water reflection of the stupa (the real photo's gold streak on the lake).
- The 3 high masts of the blueprint are not built.
