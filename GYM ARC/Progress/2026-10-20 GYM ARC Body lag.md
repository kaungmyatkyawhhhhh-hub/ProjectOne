---
date: 2026-10-20
tags: [gymarc, progress, performance]
status: done (owner: test on a phone)
aliases: [Cheap pump, Blob shadows]
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-20 GYM ARC Body lag

Owner: "The game started lagging after the latest body changes." Prompt: [[2026-10-20 GYM ARC Prompt - 13 Find the body lag]].

## The cause
**Your own body was rebuilt far too often while you train.** Every level-up started a 0.4 s growth animation, and your body's meshes were rewritten up to 20 times a second during it. Each rewrite makes one frame take 65-90 ms. A new player levels up almost every rep, so a training player got 8 to 26 rewrites a second.

The owner's own account never showed it: those muscles are maxed, so they never change.

## Measured (Studio on a PC, fresh player training on the bicep curl, 3 reps a second)
| | Before | After |
|---|---|---|
| Body rewrites a second | 8 to 26 | 0 to 5 |
| FPS (per second, 10 s) | 15 to 57, mostly 20-35 | 32 to 56, mostly 42-49 |
| Average FPS | about 33 | about 46 |
| Slow frames (over 34 ms) a second | up to 15 | up to 12, mostly 2-7 |

Studio can't act as a phone here (the device emulator can't be driven remotely), so the numbers are from the PC. A phone needs its own test (F9 Developer Console).

## Top costs, 6 bodies on screen (you + 5 regulars, starter gym)
1. Drawing the map: about 9-10 ms of the drawing time each frame. The gym lights' shadows alone are about 600-750 shadow draw calls and 700-840 thousand shadow triangles. No body casts a shadow.
2. Your body rewrites while training (fixed, see above): each one a 65-90 ms frame.
3. The 5 regulars' bodies: about 156,000 triangles, about 2.3 ms of drawing time.
4. Your own live body: about 120,000-180,000 triangles drawn (its color layers repeat part of it). On the PC, hiding it changed the drawing time by less than 0.5 ms.
5. The muscle scripts for 14 bodies: about 0.5-1.2 ms a frame (at most about 2.5 ms when nothing is rewritten).

## Checked, all fine
- **Stage meshes:** all 90 templates are low-poly. Torso 4,986 triangles, arm 3,432, leg skin 2,002, shorts 1,348, forearm / calf 1,816, waist 158. None came from the old `other_player_stages` or `upper_traps_stages` folders. Nothing to re-import.
- **No duplicates:** no leftover imported meshes anywhere in the place, and no body has two copies of a stage.
- **New parts:** the upper traps, adductors, back and chest are part of the same mesh rewrite (no extra loop, no second mesh). The elbow / knee joint balls are one plain ball each, updated 10 times a second, and never rewrite a mesh.
- **Statue and mirror:** anchored, and never rebuilt every frame.

## What changed
- **Your body is rewritten at most once a second.** Changes in between are batched into that one rewrite. There's no growth animation any more: you see the new size within a second. (Shared/MuscleRig `WRITE_EVERY`)
- **The small "pump" every 10 levels and the pose pump no longer change the mesh.** Each one used to rewrite the body about 10 times. The red training flash still shows on every rep.
- **Low-end phones:** your own body uses the low-poly stage meshes (like everyone else's) when the camera is more than 15 studs away, and goes back to the live body nearer than 12 studs. A device counts as low-end once its FPS stays under 40 for 5 seconds, or when the player set Roblox's graphics quality to 1-3. (MuscleClient; Studio test: Workspace attribute `TestLowEnd` = true.) Tested in Studio: the switch both ways, with no plain body showing through.
- **Stage templates:** 48 templates had a "Default" collision shape. All 90 are now set to Box, with no collisions, no touch or query, no shadow, and single-sided.

## Needs the owner
- Test on a phone: train with a new player and check that it feels smooth.
- Decide: is losing the small pump every 10 levels and in poses OK? It could come back as a color flash instead.
- The torso stage meshes don't cast a shadow (none do). The prompt allows a torso shadow, but it would add drawing cost, so it was left off.
- The biggest cost left is the gym lights' shadows, not the bodies. That's the next thing to cut if phones still lag.

## Follow-up (owner's answers, [[2026-10-20 GYM ARC Prompt - 15 Cheap pump, blob shadows, light shadows]])
- **Cheap pump** (Shared/VFX/BodyPump): your whole character grows 3.5% over 0.15 s and back over 0.4 s (Model:ScaleTo, no mesh rewrite), with a short gold flash (a Highlight) and about 10 gold sparks. It plays on the level-up pump (whenever a muscle passes a multiple of 10 levels, like the old pump) and on every pose hit. Other players posing get the flash and sparks but are not scaled. Tested: peak +3.5%, back to exactly 1.0, the flash and sparks clean themselves up. The old mesh pump code is removed from MuscleRig.
- **Blob shadows** (BlobShadowClient): a soft dark round shadow under every body (players, regulars, trainers, statue). It's a flat part with a black radial-fade image (uploaded: rbxassetid://76083127218780), raycast to the floor, sized to the torso plus both upper arms, lighter and bigger while jumping, and hidden past 120 studs. No stage mesh casts a shadow. On the dark rubber gym floor it is subtle (Transparency 0.2 under the body).
- **Light shadows:** the place already had shadows on only the main lights: 2 big spots in the starter gym, 2 in the pro gym and 1 on the posing stage (5 of 296 lights). Every small / accent light was already off, so nothing changed in the place. New LightShadowsClient: on a phone or a low-end device (Shared/LowEnd: FPS under 40 for 5 s, or graphics quality 1-3) every light's shadow is turned off on that device, including lights that stream in later.
- Shared/LowEnd now holds the low-end check (MuscleClient uses it for the far look too).

### FPS before / after, 7 bodies on screen (starter gym)
Studio's phone emulator can't be driven remotely, so "phone" is Studio set to graphics level 1 on the PC (the closest stand-in). Each line is the average of 3 rounds of 2.5 s.

| Graphics | Setup | FPS | Render CPU | GPU | Shadow draw calls |
|---|---|---|---|---|---|
| PC max (21) | before: no blobs, 5 light shadows | 51.5 | 16.2 ms | 3.7 ms | 673 |
| PC max (21) | after, PC: blobs, 5 light shadows | 53.2 | 14.8 ms | 3.9 ms | 661 |
| PC max (21) | after, phone rule: blobs, light shadows off | 51.5 | 16.0 ms | 3.5 ms | 575 |
| PC max (21) | (info) also sun shadows off | 54.7 | 14.4 ms | 2.8 ms | 0 |
| Level 1 (phone-like) | before | 57.2 | 11.4 ms | 1.2 ms | 0 |
| Level 1 (phone-like) | after, phone rule | 54.8 | 14.2 ms | 1.0 ms | 0 |

What it shows:
- At low graphics quality Roblox already draws **no shadows at all**, so on phones the light switch makes no measurable difference. The differences between rows are within Studio's noise (about ±2 FPS).
- On a PC the 5 lights are only about 100 of about 670 shadow draw calls. The rest come from the sun's shadows (Lighting.GlobalShadows) on the map's parts. Turning the sun's shadows off gave about +3 FPS and 1 ms less GPU on the PC, but that was not changed (it's a big visual change; owner decides).
- The blob shadows cost nothing measurable.
