---
date: 2026-11-04
tags: [gymarc, progress, body]
---
# GYM ARC - Legs max look = 80% of the mass monster (players)

Back to [[00 GYM ARC Home|GYM ARC Home]]. In Studio, not published.

## What changed (visual only)
- A player's legs (quads, hamstrings, glutes, calves) are drawn at most **80% of their mass monster look** (0.8 x each muscle's MonsterG; Quads 2.132 -> 1.71, Hamstrings 2 -> 1.6, Glutes 1.8 -> 1.44, Calves 1.875 -> 1.5).
- Up to the full aesthetic look nothing changes. Past it, the mass monster part is squeezed, so legs reach the 80% top at the same EXP where they used to reach the full monster. It grows smoothly all the way, with no flat stretch.
- Players' leg WIDTH (the body part widening) keeps the same share of the mass monster widening (~59%).
- Where: `Config/Muscles` (`LegLook`, `DrawLook`, `LegWidthShare`), `MuscleRig` (`legCap` option; the skin stage still uses the uncapped look), `MuscleClient` (legCap on for players + statues), `BodyService.WidthFactors(data, fullLegs)`, `GymGoerService` (NPC giants keep full legs).

## Not changed
- `Muscles.LookG` and everything that reads it: Stats grades (mass monster still 100%), arm wrestling strength, posing scores, leaderboards, levels, EXP, gates, weights, coins.
- NPCs (gym goers, giants, bullies) and the trainer presets keep their full legs. Note: no trainer is built from player data, so there was nothing to change there.

## Where it shows
Your own body, other players, the plaza statue, Hall of Fame statues, VIEW MY STATUE and the potential vision (all statues = player bodies). The mirror and the genetics camera show your real body, so they follow it. Shorts and gear are meshes on the legs, so they follow the smaller legs.

## Test (Studio, 3 bodies built like the Hall of Fame statues, at 7'4")
- Max legs: leg meshes ~9% narrower overall (the muscle on top of the leg ~20% less), body height the same (5.02 studs both), so feet stay on the floor and poses / walk / squat keep the same leg length. Arms and torso the same.
- Lopsided (max arms, legs at 80%): arms full, legs follow the cap, stands on the floor.

![[GYM ARC/Screenshots/2026-11-04 legs cap - front after (left) vs before (right).jpg]]
![[GYM ARC/Screenshots/2026-11-04 legs cap - lopsided front.jpg]]
![[GYM ARC/Screenshots/2026-11-04 legs cap - lopsided side.jpg]]
