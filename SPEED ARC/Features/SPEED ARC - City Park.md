---
date: 2026-10-28
tags: [speedarc, feature]
status: done (M3)
---
# SPEED ARC - City Park Run (League 2)

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

## Look
- Bright morning park at x = 2000 (far from the hub, its own streamed model).
- **Landmark:** a fountain island in the middle of a lake, with spray.
- **Race route:** a blue 4-lane running loop round the lake on a grey path. A stone bridge crosses the back straight, so the race runs under it. Start/finish arch with countdown screens.
- City skyline to the north, food carts (ICE CREAM, SMOOTHIES), a gazebo, picnic blankets, ducks that bob, trees, lamps, benches.
- **Edges:** hedges and railings all round show where the park ends.
- Lighting preset "Park", music "Park". 292 parts, 0 lights.

## Training (south of the loop)
| Station | Gain / tap | Needs |
|---|---|---|
| Park Loop | +40 | open in League 2 |
| Hill Sprint | +90 | 1.25M MPH |
| Bench Step-Ups | +200 | 4M MPH |
| Bike Drafting | +450 | 12M MPH |
(x8 League 2 multiplier on top.)

## Spawn plaza
Spawn at (2000, 3, 128) facing the lake. BACK TO HUB gate and the "CITY PARK - FASTEST HERE" leaderboard on the plaza.

## Races
Lap Race and Sprint, every 3 min, 60 s after the hub's.

## Where it lives
`Games/SpeedArc/tools/build_park.luau` (run with `builder_lib.luau`), `Config/Areas.Park`, `Config/Stations`.
