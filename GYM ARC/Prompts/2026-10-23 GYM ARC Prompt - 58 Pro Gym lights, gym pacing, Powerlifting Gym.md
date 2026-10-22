---
date: 2026-10-23
tags: [gymarc, prompt]
status: done
---
# 58 Pro Gym lights and windows, gym pacing, Powerlifting Gym

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Two parts: finish the Pro Gym, then change the gym pacing and build the next gym (Powerlifting Gym). Follow CLAUDE.md Speed rules. Mobile first. Never undo the owner's manual Studio changes. Read "GYM ARC\2026-10-20 GYM ARC Gameplay plan.md" (Gyms and machines, Gym bro details) first. Back up before changing: ServerStorage.ProGymBackup_23Oct_b.

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

PART B: GYM PACING + THE POWERLIFTING GYM (owner, 23 Oct: not a new gym every spurt)

1) NEW GYM LADDER (update the unlock config, the growth spurt "Next:" text, the map, locked signs, unlock guides, and the gameplay plan note in the vault)
- Start: Starter Gym
- Spurt 1: Beach Gym (as now)
- Spurt 2: NO gym (trainers, arm wrestling, Regional Show stay here)
- Spurt 3: PRO GYM (moved from Spurt 2). Players who already unlocked it KEEP access (migrate: anyone at Spurt 2 who has been inside keeps it).
- Spurt 4: NO gym (National Show + the other non-gym unlocks already planned for 3-4 stay where they are)
- Spurt 5: POWERLIFTING GYM (new, below)
- 7'0": Golden Era Gym + Body Alters (later)
- Garage Gym and Strongman Yard: cut for now (not built, remove from the map/plan list, keep the idea in the plan note under "Later").
- The +10% gym bonus steps stay per gym in order (Starter, Beach, Pro, Powerlifting).
- Spurts without a gym still feel big: the growth spurt popup lists what unlocks ("TRAINERS · ARM WRESTLING · REGIONAL SHOW").

2) THE POWERLIFTING GYM (unlocks at GROWTH SPURT 5)
From the plan: "Chalk, deadlift platforms, heavy bars, record board". A serious, loud strength gym that gym bros recognize. Raw and heavy, not fancy.
- PLACE: a big old warehouse/industrial building at the edge of town: brick + steel, high ceiling with steel beams, big roll-up loading door, a painted sign "POWERLIFTING" (original, no brands). Big enough for a full server; wide paths for 7'0" players.
- TRAINING (the heaviest tiers so far): rows of wooden deadlift platforms with heavy bars and big bumper plates, competition squat racks with safety arms, competition bench presses, a monolift, a deficit/block-pull station, a dumbbell rack with the picker, a few accessory machines so all 6 muscle groups are covered. Weight tiers start at the Pro Gym's top and go higher (same step size + unlock rule); the gym bonus is the next step in config.
- LOOK: dark rubber floor, chalk dust in the air (light particles, cheap), chalk bowls on stands, steel and black everywhere with RED accents (plates, signs), bright white industrial hanging lamps (no yellow neon), a big wall of original slang banners ("LIFT HEAVY", "CHALK UP", "NO EGO, JUST WEIGHT"), loudspeakers, a raised competition platform at the back with judge chairs and three judge lights (white/red).
- UNIQUE FEATURE: THE RECORD BOARD + PR BELL
  - A huge board on the main wall: the server's heaviest lifts in this gym per lift (squat, bench, deadlift) with the player's name and weight, plus an all-time top 3 per lift (saved).
  - Setting a new personal record anywhere in this gym rings the PR BELL (loud bell + gold flash for everyone in the gym, small toast "Rong hit a 1,250 LB DEADLIFT PR!" only inside this gym).
  - Beating the server record: the board flashes, the name slides to the top, and the three judge lights turn white ("GOOD LIFT") with a crowd cheer.
  - Optional "MEET" event every ~10 min: a 60 s window where PRs on the competition platform give +20% EXP and the judge lights react to every lift. All numbers in config.
- HOOKUPS: locked door sign "UNLOCKS AT GROWTH SPURT 5" with the locked toast + progress, teleport pad / map entry / GO TO target, GuidePath, streaming (phones only load it when near), the unlock guide (prompt 39), the growth spurt bar "Next: Powerlifting Gym", 2-3 NPC lifters, lifting sounds (heavy plate drops), music.
- SPEED: reuse machine models re-skinned (black + red, worn steel), simple parts, small props no collisions/no shadows. Check the part count and that walking in on a phone doesn't lag.

TEST B: a save at Spurt 2 (Pro Gym locked, unless it was already unlocked), Spurt 3 (Pro unlock guide), Spurt 4 (no gym, popup lists the unlocks), Spurt 5 (Powerlifting unlock guide, teleport in). Train on 3 stations, set a PR (bell), beat a record (board + judge lights) with 2 players. Screenshots: outside, inside, the record board, the competition platform. Short progress note + a new feature note "GYM ARC - Powerlifting Gym" + the updated gym table in the gameplay plan note.
```
