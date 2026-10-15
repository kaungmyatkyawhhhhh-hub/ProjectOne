---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Progress Mirror

Back to [[00 GYM ARC Home|GYM ARC Home]].

A mirror near the gym door with a before / after card. (Since 15 Oct the mirror is plain: no live reflection.)

## How it works
- **Live reflection:** shows YOUR front, facing you, flipped left / right like a real mirror, with your exact muscles, skin color and stage, clothing and accessories, moving with your pose and animation.
- **Before / after card:** "Day one" (look 0) next to "Now".
- **Lighting:** lit like the gym (key light from the nearby lamps, fill from the ambient light).
- **Mirror mode:** while it shows, your muscle meshes go fully opaque (skin tints pause) so the reflection doesn't turn see-through.
- **Performance:** only updates while on screen (the old version caused 22 FPS near the door; fixed to 60).

## Where it lives
- Mirror client code (MuscleClient / mirror), `MuscleRig.SetMirrorMode`
- Studio hook `TestOpenMirror` (see [[GYM ARC - Studio Test Hooks]])

## Known issues
- A small lip at the outer sides of the shorts' waistband.

## Done (13 Oct)
- [[GYM ARC - Photo Mode]]: the PHOTO button shows at the mirrors.

## Related
[[GYM ARC - Muscles and Bodies]], [[GYM ARC - Poses and Posing Stage]]

## Screenshots
![[GYM ARC/Screenshots/mirror_front.png]]
![[GYM ARC/Screenshots/mirror_card_now.png]]
![[GYM ARC/Screenshots/live_mirror_posed.png]]

## Reflection removed (15 Oct, owner)
- The live reflection is gone (all its code deleted). Every mirror in the game is now a plain mirror: light grey-blue, a little shine, a thin dark frame, no scripts. That is the progress mirror, the mirror wall in the starter gym, the pro gym's mirror and the clothing store's.
- The before / after card still works: it builds its own two bodies and doesn't need the reflection. It is still lit like the gym.
- Why: speed. Measured standing at the mirror in Studio: with the reflection, drawing took about 49 ms of computer time and 16-20 ms of graphics time every frame; without it, 7 ms and 2-7 ms.

![[GYM ARC/Screenshots/2026-10-15_mirror_progress_plain.jpg]]
![[GYM ARC/Screenshots/2026-10-15_mirror_wall_plain.jpg]]
![[GYM ARC/Screenshots/2026-10-15_mirror_card_still_works.jpg]]
