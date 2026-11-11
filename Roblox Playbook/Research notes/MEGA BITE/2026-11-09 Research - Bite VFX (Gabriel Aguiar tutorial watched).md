---
date: 2026-11-09
tags: [megabite, vfx, bite, research, video-watched]
---
# Research: Bite attack VFX (video watched 9 Nov 23:20)

Video: "Unity VFX Graph - Pokemon Bite Attack" (Gabriel Aguiar Prod., 19:50, 21K views) https://www.youtube.com/watch?v=YtrOYF8r7lc
Watched: full transcript + key frames (original game reference, final effect, texture painting, sparks, flare). The effect idea (two rows of glowing teeth snapping shut) is generic; we make our own textures and shark styling, no Pokemon art.

## How the effect is built (4 layers, total ~0.5 s)
1. **Top teeth + bottom teeth**: ONE flat image each (lightest way; mesh/trail not needed). One particle per row, burst 1.
   - Lifetime **0.3 s**. Start offset **+-1.2** units above/below the centre, then velocity from a curve over the lifetime: **-1 -> 0** (fast at the start, stops at the centre), multiplier **7**. Bottom row = the same, negated.
   - Size 1 (sized against a character-size cube), scale constant.
   - Colour over life: gradient **deep red (H~5) -> orange**, HDR intensity **2.5-3**; alpha key pushed late so it fades only at the end.
2. **Teeth texture** (Krita, 2048 px, black bg): soft hair brush ~350 px, paint a short vertical stroke with a pointy end, erase 30% on top and sides, smear the tip down; **Motion blur 90 deg, max length** (the glowy streaked look). Row = 6 small teeth + a bigger fang each side + smaller ones outside; bottom row = copy rotated 180 deg and **shifted so the big fangs sit BETWEEN the top fangs** (interlock). Export top and bottom separately, alpha on.
3. **Sparks**: burst **30**, **delay 0.27 s** (the moment the jaws meet), spawn in a sphere r=0.1, velocity random **3-10**, aligned to velocity, stretched (scale X 0.15, Y 0.8), size random 0.1-0.8 shrinking over life, lifetime 0.1-0.8, gravity random -7 to -9. Colour: random between a saturated reddish-orange (intensity 3-4) and a less saturated one (2.5) = extra punch.
4. **Flare**: 1 particle, same 0.27 delay, size random 2-3 shrinking fast, lifetime **0.18-0.2**, random rotation 0-360, reddish orange. Texture = soft big dot + smaller brighter dot + a thin horizontal and vertical streak.
- Original game look (frame at 0:21): bright yellow-orange teeth, radial speed lines behind, dark slash shapes - bold comic punch.

## MEGA BITE version (Roblox)
- Teeth: two BillboardGui ImageLabels (or Attachment ParticleEmitters with :Emit(1)), LightInfluence 0, tween Position from +-1.2*size to 0 with **Quad/Expo Out over 0.3 s**, ImageColor3 red->orange, fade ImageTransparency in the last 30%.
- Sparks: ParticleEmitter, LightEmission 1, Orientation VelocityParallel, Squash for the stretch, Speed 3-10 (x studs scale), Acceleration (0,-25,0), Lifetime 0.1-0.8, Size big->0, SpreadAngle 180, `task.delay(0.27, function() e:Emit(30) end)`.
- Flare: ParticleEmitter Emit(1) at 0.27 s, Size 2-3 -> 0 over 0.2 s, Rotation random, LightEmission 1.
- Shark style: white/cyan teeth glow for a normal bite, red/orange for a crit or a big creature; play on the Bite animation's "Snap" marker (frame 9), with the bite sound.
- Textures made by code the same way (soft strokes + 90 deg motion blur): `MEGA BITE\Art\VFX\bite_top_teeth.png`, `bite_bottom_teeth.png` (interlocking), `bite_flare.png`, `bite_spark.png`, preview `bite_preview.png`.
