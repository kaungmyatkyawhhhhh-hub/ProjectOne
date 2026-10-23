---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Gym Lighting

Back to [[00 GYM ARC Home|GYM ARC Home]].

Moody but never dark: warm light pools in the starter gym, brighter spotlight pools in the pro gym, and a sunny town with lamps at night.

## How it works
- **Starter gym:** warm hanging pendants with tight bright pools over each station, 3 extra over the aisle and leg machines, dimmer fills, brighter high windows, the red neon sign kept subtle. 9 warm wall-washer can lights graze the brick on the west and back walls.
- **Pro gym:** brighter, tighter spotlight pools, fills and ceiling bars toned down, 14 neutral wall washers on the east and back walls.
- **Shadows:** only 4 lights in both gyms cast shadows (cut from 14 for the owner's ~20 FPS PC). 109 lights in both gyms.
- **Global settings:** LightingStyle Realistic with PrioritizeLightingQuality (never set the old `Lighting.Technology`), Atmosphere haze, light bloom, warm color correction.
- **Town:** day lighting; street lamps (tag `NightLight`) glow at night.
- All values are at the top of the builder to tweak.

## Where it lives
- Builder `tools/builders/GymLighting` (also run at the end of `Gyms.Build`)
- `Server/NightLightService`

## Done (13 Oct)
- Day / night in town: see [[GYM ARC - Day and Night]] (gym interiors keep this lighting).

## Related
[[GYM ARC - Town and Gyms]]

## Screenshots
![[GYM ARC/Screenshots/lighting_after_starter.jpg]]
![[GYM ARC/Screenshots/lighting_after_pro.jpg]]
![[GYM ARC/Screenshots/lighting_wall_washer.jpg]]
![[GYM ARC/Screenshots/p1_lighting-night_after.png]]
