---
date: 2026-10-28
tags: [speedarc, vfx]
status: living document
---
# SPEED ARC - VFX

Back to [[00 SPEED ARC Home|SPEED ARC Home]] · [[SPEED ARC - Game Design Document|GDD]]

## Rules
- Few particles, well designed: custom textures (made by script, like GYM ARC's `gymarc_vfx.py`: soft glow, spark, streak, ring, puff, star, confetti, speed line), colours from the palette, good size/lifetime curves.
- Budget: < 300 particles on screen; own effects full, other players' simplified; far (> 80 studs) others' trails off.
- Pool everything (no new instances per tap). Effects pause when off-screen.
- Low graphics / Reduced Motion: half the particles, no screen shake, no flicker.

## Speed feel (the most important VFX)
- **Camera FOV:** 70 walking -> up to 85 at top race pace; +5 kick on BOOST (0.2 s ease out).
- **Speed lines:** screen-space streaks (UI ImageLabels moving outward from the centre) when running fast or boosting; density follows pace.
- **Wind streaks:** a few thin white beams/trails past the character at high walk speed.
- **Footstep dust:** small puffs per step on dirt/grass, sparks on the track at very high speed.
- **Speed aura:** past each league's Champion rank, a soft blue glow outline + light streaks behind the character (cheap: Highlight off, use a few Beams/attachments).

## Training
- Tap: small "+12 MPH" number pops (pooled TextLabels/BillboardGuis), colour = blue, gold on combo max.
- Combo meter flame: blue flame grows to gold at max; a burst at each combo step.
- Treadmill belt scroll (texture offset), sled dust, stair tower step glow.
- Rank up: gold ring shockwave on the ground + rising sparkles + screen flash (light).

## Races
- Start: countdown numbers slam in, GO flashes gold, a dust burst from all runners.
- Boost: blue burst at the feet, short motion streaks, FOV kick, boost pips light up/empty.
- Slipstream: faint wind tunnel lines between drafter and leader.
- Overtake: a quick blue swoosh on the overtaking runner.
- Final stretch: the finish arch pulses, gold particles drift.
- Finish: tape breaks (1st), gold confetti, camera slow-mo 0.3 s for the winner (own screen only).
- Podium: spotlights, confetti cannons, medal shine sweep.

## Trails (each one designed, cheap)
- Built from 1 Trail + 0-2 small emitters at the feet. Gradient colour + width curve.
- Dust (grey puffs), Chalk Lines (white dashes), Leaf Swirl (green leaves), Fire Streak (orange-gold flame trail + embers), Ice Streak (blue crystals), Lightning (blue zig-zag beam flicker + sparks), Rainbow (smooth gradient ribbon), Comet (gold head + long blue tail), Star Dust (gold stars), VIP (gold + black ribbon with sparkles), event trails.

## Coaches and rolls
- Roll: name roller with blue glow; rarity-scaled reveal (GYM ARC 49/55 approach): Common pop -> Legendary+ themed cutscene (Zephyr storm wind, Kai sunrise, Flying Ghost old-film grain, Mercury golden temple).
- Coach follow: tiny dust at their feet; evolved coaches get a coloured aura ring.

## UI VFX
- Buttons: press squash + shine sweep on primary buttons every few seconds.
- Coins fly to the counter + count up.
- Rarity borders: rotating highlight (UIGradient) on rare items.
- Windows: quick scale-in, no full-descendant fades (lesson).

## Texture list to make (script, 256-512 px, transparent PNG)
glow_soft, spark, streak, speed_line, ring_shockwave, puff, star, confetti_sheet (4 shapes), leaf, ember, ice_crystal, lightning_bolt_strip, comet_head, medal_shine.
