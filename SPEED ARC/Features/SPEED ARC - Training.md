---
date: 2026-10-28
tags: [speedarc, feature]
status: done (M1)
---
# SPEED ARC - Training

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

## How it works
- Walk up to a spot, press TRAIN (E on PC). You're placed on it and the run animation starts.
- **Tap anywhere** (or Space): +MPH. The number pops up (pooled labels), the MPH bounces, a layered footstep sound plays with pitch rising with the combo, and you run faster.
- **Combo:** at least 3 taps a second with no gap over 0.6 s builds x1.0 to x1.5 over 10 s (a sound at each step). It drops back with a soft thud when you stop.
- **Leave:** STOP button, WASD, or push the stick on a phone.
- **Coins from training:** about 20% of the League 1 rate (12 coins a minute at 5 taps a second).
- **Walk speed** in the hub: 16 + 6 x log10(1 + MPH/10), capped at 30. Camera field of view grows from 70 to 80 with it.
- The server checks everything: at most 12 taps a second counted, minimum MPH per spot, one player per spot.

## Spots (League 1, GDD 7.2 numbers)
| Spot | Needs | Per tap | Places |
|---|---|---|---|
| Sprint Lane (GDD's Jog Lane) | 0 MPH | +1 | 3 lanes with starting blocks |
| Treadmill | 40 MPH | +3 | 4 under a canopy |
| Stair Run | 150 MPH | +8 | 2 on the stairs |
Sprint Sled (500 MPH) comes later.

## Where it lives
`Server/Services/TrainingService`, `Client/Controllers/TrainingController`, `Config/Stations`, `Config/GameConfig` (Combo, Walk, Economy). Spots are `workspace.Hub.Training.<Id>` parts named `Slot`.

## Related
[[SPEED ARC - Hub World]], [[SPEED ARC - UI Kit and HUD]]
