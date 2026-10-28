---
date: 2026-10-28
tags: [speedarc, feature]
status: done (M3)
---
# SPEED ARC - Big Stadium (League 3)

> **Prompt 11 (28 Oct):** candy rebuild: light concrete, white / sky stands, a bright purple tunnel, the tents / coolers / camera crane removed, BACK TO HUB moved beside the tunnel exit. The **wall course** runs straight out of the players' tunnel between low stands with a crowd that cheers on every smash; walls in purples / pinks / blues. 885 parts, 4 lights (the floodlights), 296 fans.
![[2026-10-28 p11 stadium course.jpg]]

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

## Look
- Pro athletics stadium at golden hour, at x = 4000 (its own streamed model).
- 8-lane blue oval with a green infield, start/finish arch with countdown screens.
- Stands all round (bleacher mesh), 212 fans (the light v1 fan meshes, to save triangles). Gap in the south stand for the tunnel.
- Giant scoreboard over the west end (race countdown on it), 4 floodlight towers with the area's only 4 lights (no shadows).
- **Players' tunnel:** you arrive in a dark tunnel with blue edge lights and walk out into the bright bowl. "WELCOME TO THE BIG STADIUM" sign inside.
- Team tents with water coolers, press box, camera crane, 8 flags of made-up nations.
- Lighting preset "Stadium" (clock 17.3), music "Stadium" + crowd bed. 443 parts, 4 lights.

## Training (infield)
| Station | Gain / tap | Needs |
|---|---|---|
| Block Starts | +900 | open in League 3 |
| Hurdles | +2,000 | 550M MPH |
| Parachute Run | +4,500 | 1.8B MPH |
| Bungee Sprint | +10,000 | 5.5B MPH |
(x64 League 3 multiplier on top.)

## Races
Lap Race, Sprint and **Hurdles** take turns, every 3 min, 120 s after the hub's.
- Hurdles: 8 across every lane. JUMP button with a timing ring when one comes (J / Up on a keyboard). Jump window 5 studs before, 0.6 after. A miss = "CLIP!", x0.7 pace for 0.6 s, never a stop. NPCs clear 85%.

## Where it lives
`Games/SpeedArc/tools/build_stadium.luau` (run with `builder_lib.luau`), `Config/Areas.Stadium`, `Config/Race` (Hurdles, Hurdle).
