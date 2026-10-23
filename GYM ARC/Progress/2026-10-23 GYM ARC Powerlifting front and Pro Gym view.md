---
date: 2026-10-23
tags: [gymarc, progress, world, powerlifting, progym]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Powerlifting front and Pro Gym view (prompt 62)

Prompt: [[2026-10-23 GYM ARC Prompt - 62 Powerlifting front and Pro Gym view|62 Powerlifting front and Pro Gym view]]. Features: [[GYM ARC - Powerlifting Gym]], [[GYM ARC - Pro Gym expansion]]. Game commit f34ba11.

## 1. Powerlifting Gym: a real street front
- **Backups first:** the whole gym in `ServerStorage.PowerliftingBackup_23Oct_p62`. The 6 Main Street buildings that stood in front of it, plus the old front wall, the alley, the painted sign and the old door sign, are in `ServerStorage.PowerliftingFrontRemoved_23Oct` (each building remembers where it was). Terrain under the new paving: `PowerliftingForecourtTerrain` / `PowerliftingPassageTerrain`.
- The hall's front wall (z -3) already lined up with the starter gym's front, so with the buildings gone it faces Main Street directly, with paving like the starter gym's forecourt up to the same sidewalk. The three gyms now read as one gym row: Powerlifting, Starter, Pro.
- **Facade:** red-brown brick base, a row of 8 tall industrial windows (steel frames and muntins, lit from inside, a soft glow at night), steel I-beam columns, a steel beam across, ribbed dark steel above, a lit **POWER**(white)**LIFTING**(red) sign on black with a red neon edge and "GYM ARC" under it, white industrial wall lamps (on at night), a steel side door, two bollards at the loading door, two planters.
- **Roof:** sawtooth warehouse roof (6 teeth) in dark grey with skylights on the slopes and north glass, mushroom vents, 2 AC units. Top at 35.5 studs, below the taller Main Street buildings (up to 56).
- **East side wall** (seen down the passage to the starter gym): a chalk-white painted barbell mural "CHALK UP. LIFT HEAVY.", ribbed steel above it, the passage paved in concrete.
- **Loading door:** the same door logic. Locked = clean steel shutter with a black + white plate "UNLOCKS AT / GROWTH SPURT 5" and a padlock (no red LOCKED). Walking up or **tapping the door** shows the locked toast with your progress. Unlocked = the shutter is rolled up and you see the gym inside.
- The hydrant moved off the door's path; the building west of the front moved 2 studs so it no longer overlaps the corner.
- 316 new parts (+ roof touch-ups), every decoration part anchored, no collisions, no shadows. Builder: `tools/builders/PowerliftingFront.luau`.

## 2. Pro Gym windows: a city, not a void
- The city from prompt 58 was there (only drawn on each player's device), but it was pale grey and the town's haze washed it out to a grey fog.
- **City rebuilt** (backup `ServerStorage.ProGymCityBackup_23Oct_p62`): warm, varied facades (brick, sandstone, terracotta, cream), teal / navy glass towers, a taller middle skyline, low green hills on the horizon and both sides. Still ~3,100 simple parts, no collisions, no shadows. Windows light up at night (as before).
- **Haze:** inside the Pro Gym the haze thins (Atmosphere density 0.3 -> 0.12, haze 1.4 -> 0.4) and comes back when you leave (`GymMoodClient`), so the city reads clearly.
- **Near view:** big oaks and cypresses (copies of the town's) on the strip south-east of the gym hide the backs of the 3 Main Street buildings; bushes and rocks along the cliff top give the edge a green rim. Builder: `tools/builders/ProGymCliffGreenery.luau`.

## Tested (Studio, PC)
- Street, above and night shots of the Powerlifting front; locked as a temporary Spurt 4 player (plate, walk-up toast, tap toast "LOCKED · UNLOCKS AT GROWTH SPURT 5" with progress); unlocked on your test account (door rolled up, gym visible inside; lamps, sign and windows lit at night).
- Pro Gym windows from the middle, the stretch / posing mat and the cardio row by day, and at night in play (city lit, haze thinned). No script errors.
- Not checked: phone screen sizes walking past the front (the build is world geometry, nothing on screen changed).

## Needs the owner
- The 6 town buildings are kept in ServerStorage; delete them when you're happy, or tell me to put any back.
- From high above the town (outside the Pro Gym / east side) the valley still shows bare ground: the city only draws near the Pro Gym to keep phones fast. Say if you want it visible from more of the town.

![[GYM ARC/Screenshots/p62/pl_front_before.jpg]]
![[GYM ARC/Screenshots/p62/gym_row_street.jpg]]
![[GYM ARC/Screenshots/p62/pl_front_locked.jpg]]
![[GYM ARC/Screenshots/p62/pl_door_tap_toast.jpg]]
![[GYM ARC/Screenshots/p62/pl_front_night_unlocked.jpg]]
![[GYM ARC/Screenshots/p62/pl_above_roof.jpg]]
![[GYM ARC/Screenshots/p62/pl_mural_passage.jpg]]
![[GYM ARC/Screenshots/p62/pro_window_before.jpg]]
![[GYM ARC/Screenshots/p62/pro_window_middle.jpg]]
![[GYM ARC/Screenshots/p62/pro_window_posing.jpg]]
![[GYM ARC/Screenshots/p62/pro_window_cardio.jpg]]
![[GYM ARC/Screenshots/p62/pro_window_night.jpg]]
