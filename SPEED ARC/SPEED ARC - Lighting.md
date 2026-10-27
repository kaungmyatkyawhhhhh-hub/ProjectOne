---
date: 2026-10-28
tags: [speedarc, lighting]
status: living document
---
# SPEED ARC - Lighting

Back to [[00 SPEED ARC Home|SPEED ARC Home]] · [[SPEED ARC - Game Design Document|GDD]]

## Goal
Looks premium and "fast" (crisp, high contrast, blue/gold glow) while staying cheap: the look comes from the SKY, ATMOSPHERE, COLOUR GRADING and baked vertex shading, not from many real lights.

## Global rules
- Lighting technology: ShadowMap (good look, OK on phones) with GlobalShadows on for the sun only; every prop light has Shadows = false. Test Voxel/Compatibility on low graphics.
- One sun per area (set per area when you teleport in, tweened 1 s).
- Max ~20 small lights per area, only the area you're in is lit (GYM ARC LightAreaClient lesson). Prefer Neon parts for glow.
- Post effects per area (cheap): Atmosphere, ColorCorrection, Bloom (low intensity), SunRays (low). No DepthOfField in gameplay (only menu/cutscenes).
- Low graphics: no Bloom/SunRays, fewer lights, simpler sky.
- Everything in `Config/Lighting` as presets; `LightingController` applies the preset of the area you're in.

## Presets per area
| Area | Time | Sky | Look | Key values (start) |
|---|---|---|---|---|
| Hub - Hometown Track | late afternoon 16:30 | warm blue sky, soft clouds | sunny, friendly, gold sun on a blue track | Brightness 2.4, Ambient #6B7A99, ColorCorrection Contrast 0.08 Saturation 0.12 TintColor #FFF6E8, Bloom 0.4 |
| City Park Run | morning 09:00 | light blue, haze over skyline | fresh, airy | Atmosphere Density 0.3 Haze 1.2 Color #BFD8FF, Saturation 0.15 |
| Big Stadium | golden hour 18:00 | orange-blue gradient | dramatic, floodlights coming on, long shadows | Brightness 2, sun low, 6 floodlight Neon heads + 4 SpotLights (no shadows), Contrast 0.12 |
| Mountain Trail | early morning 07:30 | pale blue, mist | cool, crisp, mist in valleys | Atmosphere Density 0.4 Haze 2, cool TintColor #E8F0FF |
| World Games | night 21:00 | deep blue night, stars | stadium lights blasting, gold torch, blue LED strips | Ambient #1B2440, Neon LED strips blue, gold torch flame light, Bloom 0.7, camera flashes |
| Legend Track | sunset above clouds | pink-gold to deep blue | dreamy, golden | SunRays 0.15, gold tint |
| Menu | each area's best angle | | cinematic: slight DOF + stronger grade | only on the menu |

## Race lighting moments
- Countdown: the start screen glows blue, "GO!" flashes gold (UI + a Neon pulse on the arch).
- Final stretch: the finish arch's Neon pulses faster.
- Win: a short gold flash + confetti; podium spotlights (3 SpotLights, only during the podium, no shadows).

## Day/night
- Keep areas at their fixed time (no global day cycle): each area's look is designed and cheap to test. Optional later: a slow cycle in the hub only.

## Checklist per area
1. Preset tuned and saved in Config.
2. Light count < 20, no prop shadows.
3. Screenshot at quality 1 and quality 10 from 3 player views; both must look good.
4. FPS check after lighting is done.
