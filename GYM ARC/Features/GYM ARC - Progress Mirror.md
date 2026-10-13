---
date: 2026-10-08
tags: [gymarc, feature]
status: done
---
# GYM ARC - Progress Mirror

Back to [[00 GYM ARC Home|GYM ARC Home]].

A mirror near the gym door that shows your live reflection and a before / after card.

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

## Planned change
- New features prompt: a photo mode camera button at the mirrors (see [[GYM ARC - Poses and Posing Stage]]).
- Monetization prompt: a mirror in the VIP lounge.

## Related
[[GYM ARC - Muscles and Bodies]], [[GYM ARC - Poses and Posing Stage]]

## Screenshots
![[GYM ARC/Screenshots/mirror_front.png]]
![[GYM ARC/Screenshots/mirror_card_now.png]]
![[GYM ARC/Screenshots/live_mirror_posed.png]]
