---
date: 2026-10-23
tags: [gymarc, prompt]
status: superseded
---
# 58 Pro Gym lights and windows, then the Garage Gym

Back to [[00 GYM ARC Home|GYM ARC Home]]

Replaced by [[2026-10-23 GYM ARC Prompt - 58 Pro Gym lights, gym pacing, Powerlifting Gym]] (Garage Gym cut for now).

```text
Two parts: finish the Pro Gym, then build the next gym (Garage Gym). Follow CLAUDE.md Speed rules. Mobile first. Never undo the owner's manual Studio changes. Read "GYM ARC\2026-10-20 GYM ARC Gameplay plan.md" (Gyms and machines, Gym bro details) first. Back up before changing: ServerStorage.ProGymBackup_23Oct_b.

PART A: PRO GYM
1) LIGHTS = WHITE
- Replace every yellow/gold neon light in the Pro Gym (LED strips, underglows, neon signs, lamps) with clean WHITE light (cool white, slightly warm is OK: ~5500-6500K). Gold stays only as a material accent on machines and trim, not as light colour.
- That includes the gold floor glow under each Pro machine (prompt 47): make it a soft white glow, or remove it if it looks better.

2) REMOVE THE WELCOME COUNTER in the Pro Gym (the front desk / reception). Fill the space with gym floor or a few benches/plants so there's no gap. Move anything that depended on it (prompts, teleport point, GuidePath target) to a sensible spot and list them.

3) BETTER LIGHTING
- Bright, clean, premium: rows of white linear ceiling lights over every zone, white LED strips along the ceiling edge and under the mirror wall, soft spotlights on the ELITE corner and posing mat. Even light, no dark corners, no orange tint.
- A few lights with shadows for depth; everything else shadows off (phone speed).
- Slight cool atmosphere (ColorCorrection/Atmosphere only while inside, if it's cheap).

4) CITY VIEW THROUGH THE WINDOWS + EXTERIOR
- Big floor-to-ceiling windows on at least one long wall (and the cardio wall), so players see OUT over a city: a skyline of buildings at different heights with lit windows, a road with street lights below, maybe a bridge/water in the distance.
- Build the skyline cheaply: low-poly blocks with window textures/SurfaceGuis or decals, far away, no collisions, no shadows; it can be a backdrop that only streams with the Pro Gym. It should look good in day and night.
- The Pro Gym is on an upper floor or a raised spot so the view looks down on the city (if it's on the ground, raise the floor + add a lobby/stairs or put the windows facing a lower area).
- Finish the exterior to match (prompt 50 4b if not done yet): glass front, white-lit "PRO GYM" sign, canopy, no blank walls.

TEST A: screenshots inside (each zone, white light), the window view day + night, the outside. Short note.

PART B: THE GARAGE GYM (next gym, unlocks at GROWTH SPURT 3)
From the plan: "Home setup: power rack, rubber mats, toolboxes, speaker, fridge". A real home garage gym that gym bros recognize. Fun, warm, a bit messy but tidy enough to walk around.

1) PLACE
- A suburban house at the edge of town with a BIG double/triple garage, roll-up door open, driveway in front. The house facade (windows, porch light, mailbox) is just decoration; only the garage + driveway are playable.
- Big enough for a full server: the garage inside + the driveway as an outdoor training area. Wide paths for 7'0" players.

2) TRAINING SPOTS (heavier tiers)
- Inside: 2 power racks (squat, bench, overhead press, rack row), a deadlift platform, an adjustable bench, a dumbbell rack with the exercise picker, a pull-up bar on the rafters, a cable/pulley station, a crunch/ab mat.
- Driveway: a tire flip, a sled push lane, farmer's carry handles, a kettlebell spot.
- Cover all 6 muscle groups. Weight tiers start at the Pro Gym's top and go higher (same step size + unlock rule), and the gym bonus is the next step in config (+10% over the Pro Gym). All numbers in the same config as the other gyms.

3) LOOK
- Grey concrete floor with black rubber mats under the stations, pegboard walls with tools, red rolling toolboxes, a workbench, a mini fridge full of shakes, shelves with tubs, a bike hanging on the wall, string lights + a few hanging work lamps (warm white), a whiteboard "PR BOARD", original slang posters ("LOCK IN", "NO DAYS OFF", "ONE MORE REP"), a flag/banner in black + gold. Plates stored on wall pegs. A chalk bucket. The gym cat can visit.
- No real brands or people anywhere.

4) UNIQUE FEATURE: THE HYPE SPEAKER
- A big speaker on a shelf. Tapping it (ProximityPrompt "HYPE") plays a 60 s hype track for everyone in the garage: bass pulses, string lights flash to the beat, +10% EXP for everyone training in the garage while it plays. 5 min cooldown (server). Shows "HYPE 0:42" on the speaker. All numbers in config.

5) HOOKUPS
- Locked before Growth Spurt 3: the garage door is down with a sign "UNLOCKS AT GROWTH SPURT 3"; tapping it shows the locked toast with progress.
- Teleport pad / map entry / GO TO target, GuidePath, streaming (phones only load it when near), the unlock guide (prompt 39: Coach Dex line + world marker + teleport), the growth spurt bar "Next: Garage Gym", NPC gym-goers (2-3 lifting there), the PR bell + PR board, lifting sounds, music.
- Speed: reuse existing machine models (re-skinned to look homemade: worn paint, black racks, mismatched plates), simple parts, small props no collisions/no shadows. Check the part count and that walking in on a phone doesn't lag.

TEST B: a fresh save at Growth Spurt 2 (locked door) and 3 (unlock guide, teleport in), train on 3 spots (rack, driveway tire, dumbbells), the hype speaker with 2 players. Screenshots: outside, inside, driveway, the speaker during hype. Short progress note + a new feature note "GYM ARC - Garage Gym" in the vault.
```
