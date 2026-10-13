---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Day and Night

Back to [[00 GYM ARC Home|GYM ARC Home]].

The town has a day / night cycle. Built 13 Oct (new features run, task 7C).

## How it works
- **One day = 20 minutes**, and 70% of it is daytime (06:00 to 18:00), so it's light most of the time. A new server starts at 09:00. Everyone in a server sees the same time.
- **At night:** the street lamps, wall lamps and string lights glow, the shop windows and about 6 in 10 of the town's windows light up warm (a few cool), and the gym and shop signs light themselves.
- **Gyms keep their own lighting:** only the outdoor light changes; inside a gym it looks the same day and night.
- **Performance:** no new lights were added for windows and signs, and none of the night lights cast shadows. Measured in Studio: night is no slower than day.

## Where it lives
- `Config/DayNight` (length, daytime share, start hour, dusk / dawn, night outdoor color), `Server/NightLightService` (runs the clock, switches lamps, windows and signs), `DayNightClient` (moves the sky on each player's screen).
- Windows and signs were tagged once by the builder `tools/builders/NightGlow`.
- Studio test switch: `TestClock` (an hour, for example 21).

## Related
[[GYM ARC - Gym Lighting]], [[GYM ARC - Town and Gyms]]

## Screenshots
![[GYM ARC/Screenshots/town_day_plaza.jpg]]
![[GYM ARC/Screenshots/town_night_plaza.jpg]]
![[GYM ARC/Screenshots/town_night_street.jpg]]
