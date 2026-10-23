---
date: 2026-10-23
tags: [gymarc, progress, progym, powerlifting]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Pro Gym lights and Powerlifting Gym (prompt 58)

Prompt: [[2026-10-23 GYM ARC Prompt - 58 Pro Gym lights, gym pacing, Powerlifting Gym]]. Game commit 1716bc7.

## Part A: Pro Gym
- **Backup first:** `ServerStorage.ProGymBackup_23Oct_b`. Taken out: `ServerStorage.ProGymRemoved_23Oct_b`.
- **White light:** every yellow / gold glow is clean white now (LED strips, lamp glow, sign frames, every warm light). Gold stays only as metal: lamp rims, mat lines and wall trims are gold metal (no glow). The floor glow under each Pro machine is a faint soft white.
- **Welcome desk removed.** A bench and two plants fill its spot. Nothing depended on it (no prompt, NPC spot, GO TO or path target).
- **Lighting:** white linear ceiling fixtures in rows over every zone (brighter), white LED strip under the long mirror, soft spotlights on ELITE and the stretch / posing mat. Still only 4 lights cast shadows. The old wall washers left floating on the removed middle wall are gone. A slight cool colour while you're inside (`GymMoodClient`).
- **Windows + city:** the gym is on the ground, so the land **east** of it (outside the town boundary, nobody can walk there) is now a **valley 72 studs lower** with rock cliffs (`ProGymValley`; terrain backup in `ServerStorage.ProGymValleyBackup`).
  - The east wall is floor-to-ceiling glass; the front (cardio) wall's glass goes up to the ceiling.
  - Through it: a city below (240 buildings, roads with street lights right under the windows, a river with a red suspension bridge, a park), taller towers on the horizon. At night the windows, lamps and bridge light up.
  - The city is drawn only on your device and only near the Pro Gym (`BackdropClient`), 2,820 simple parts, no collisions, no shadows.
  - The east mirrors went (the long mirror on the back wall stays); the GYM ARC PRO sign moved over the glass wall to the starter gym; the TVs hang from the ceiling.
- **Outside:** black canopy along the front with white downlights (on at night), white-lit PRO GYM sign, roof edge carried round the new hall, old wall lamps and the small spandrel sign removed. An invisible guard stops anyone walking off the new cliff.

## Part B: gym ladder
| Spurt | Gym | Other unlocks (shown in the Growth Spurt popup) |
|---|---|---|
| 1 | Beach Gym | poses, crews, Local Show |
| 2 | (none) | trainers, arm wrestling, Regional Show |
| 3 | **Pro Gym** (was 2) | auras, Pump Shop |
| 4 | (none) | National Show |
| 5 | **Powerlifting Gym** (new) | Pro Card Qualifier |
| 6 (7'0") | Golden Era Gym later | Universe, Body Alters |
- **Players who already had the Pro Gym keep it:** a save at Growth Spurt 2 that ever trained on a Pro-only machine gets `gymAccess.Pro` on its next join (one time). Note: someone who only walked in without using a machine can't be told apart, so they wait for Spurt 3.
- The Growth Spurt moment shows a gold line "NEW: TRAINERS · ARM WRESTLING · REGIONAL SHOW".
- The growth spurt card says "Next: Pro Gym" at Spurt 2 and "Next: Powerlifting Gym" at Spurt 4.
- Locked texts, Dante's rival line and the loading tip say Spurt 3. Area signs say "Unlocks at Growth Spurt N".
- Garage Gym and Strongman Yard: not built, moved to "Later" in the gameplay plan.
- **Pacing (tests/pacing):** spurts 1-5 unchanged (4.9 / 15.9 / 25.6 / 33.5 / 45.7 min). The Powerlifting tiers made spurt 6 41 min, so its goal went **216 -> 238** (45.0 min again).

## Part B: the Powerlifting Gym
See [[GYM ARC - Powerlifting Gym]].

## Tested (Studio)
- Spurt 1 -> 2: the popup line shows; Pro door padlocked, card "0% · Next: Pro Gym"; walking in blocked; teleported inside -> put back outside the door.
- Spurt 2 with kept access (`TestProAccess`): door open, not put back.
- Spurt 4: Powerlifting shutter LOCKED, "Unlocks at Growth Spurt 5", locked toast, card "50% · Next: Powerlifting Gym"; teleported inside -> put back in the alley.
- Spurt 5: walked in through the open door; Comp Deadlift 815 lb PR -> bell; board "LuigiRED 845 LB" then 875; red 100 lb bumpers; meet (`TestMeet`) -> judge lights white GOOD LIFT on the platform; NPC lifters training.
- Pro Gym day and night window views in play. No script errors.
- All logic tests pass (machines incl. the 875 lb sleeve fit, pacing).
- **Not tested:** two real players beating each other's record (the event was fired by hand: board flash + judge lights + cheer work); phone screen sizes.

## Screenshots
![[GYM ARC/Screenshots/p58/pro_inside_white.jpg]]
![[GYM ARC/Screenshots/p58/pro_window_day.jpg]]
![[GYM ARC/Screenshots/p58/pro_window_night_play.jpg]]
![[GYM ARC/Screenshots/p58/pro_outside_front.jpg]]
![[GYM ARC/Screenshots/p58/pro_outside_cliff.jpg]]
![[GYM ARC/Screenshots/p58/spurt2_unlocks_popup.jpg]]
![[GYM ARC/Screenshots/p58/spurt2_next_pro_gym.jpg]]
![[GYM ARC/Screenshots/p58/pl_door_inside_play.jpg]]

## Needs the owner
- The valley east of town changes the world's look from the east streets (town on a hill above a city). Undo: paste `ProGymValleyBackup.Before` back.
- Powerlifting music uses your heavier Pro tracks for now; pick its own if you like.
- Gym bonus: Pro +10%, Powerlifting +20% (the beach gym has only starter copies, so no bonus).
