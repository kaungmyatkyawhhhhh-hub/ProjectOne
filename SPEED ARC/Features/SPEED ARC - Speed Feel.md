---
date: 2026-10-28
tags: [speedarc, feature]
status: done (M2)
---
# SPEED ARC - Speed Feel

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

## How it works
- **FOV:** 70 -> 80 with walk speed (CameraController); in races 70 + up to 15 with your speed, +5 kick on BOOST (RaceController).
- **Speed lines:** 22 pooled screen streaks flying out from the centre when you run faster than ~21 or race; more when boosting.
- **Feet:** dust puffs on grass when running, blue sparks on the track above 26.
- **Low graphics (quality 1-3):** half the lines and puffs, no flashes.

## Where it lives
`Client/Controllers/SpeedFeelController`, `CameraController`, `RaceController`.
