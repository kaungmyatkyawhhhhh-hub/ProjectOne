---
tags: [city-legends, traffic, physics-look]
created: 2026-11-27
---
# Traffic: real car motion, fewer overlaps (27 Nov 2026)

Owner, 27 Nov: "the cars rn are unnatural too, they go through each other sometimes, the cut up is just a car rotated and it looks like there is none of our good car physics like the player car physics".

Traffic stays client-side and anchored (BulkMoveTo on lane points). Only the look of real physics was added, not a simulation. Studio version **2311** (saved, not published).

## What changed
**1. Cars no longer drive through each other (`client/Traffic.lua`)**
- **No-overlap check on every step (`stepBlocked`):**
  - Before an everyday car moves, the box it would have after the step (place and heading from `peekPose`) is checked against every car near it.
  - A step that makes an overlap deeper is not taken. The car takes the other car's pace instead.
  - Of two traffic cars, the one ahead along their mean heading has the way, so exactly one waits. A player's car always has the way unless it is behind.
  - Counter: `workspace.Traffic` attribute `Holds`.
- **Following along the lane, not in a straight line (`lookAheadGap`):**
  - A car ahead on the same lane pieces (`pathOff`) is seen round any bend.
  - A car in the lane beside is no longer taken for one in our lane.
  - Lookahead reaches a comfortable stop plus the time gap.
- **Junctions and merges looked at earlier (`crossConflict`):**
  - The check looks at every piece within a comfortable stop, not only the next piece. The 1:1 pieces are about 24 studs, so a car saw a crossing car too late before.
  - It also looks at the other car's next planned piece.
- **Spawning and recycling:** cars are placed 40 studs apart (was 30, and a bus placed 30 from another's middle sat inside it). A car held for 12 s by the check is moved away once it is out of view.
- **Racers:** they keep their own no-touch check. A lane move now needs a faster car to be `LaneChangeS` + 0.5 s back, not 1.5 s.

**2. Lane changes and cut-ups look real**
- **Racer lane change (`laneMove` / `laneAt`):** an S-curve (quintic, minimum jerk) over `TrafficMix.Racer.LaneChangeS` = 2.4 s for a whole lane at speed.
  - Steer in, then counter-steer. The nose follows the path's tangent and turns at most about 8 degrees off the lane.
  - A new target starts from the car's current place, side speed and side acceleration, so there is no snap.
  - Checked offline: 12 studs at 150 studs/s takes 2.4 s, yaw 3.6 degrees; at 30 studs/s it takes 5.4 s, yaw 8 degrees.
  - Before, a racer slid sideways at up to 22 studs/s and its nose was turned towards the side: "a car rotated".
- **Body on the chassis (`TrafficBodies.prepare`):** the body now hangs on a `BodyTilt` Motor6D at the wheel hubs' height (part `BodyRoot`), so it can tilt while the wheels stay on the road.
- **Body motion (`bodyMotion`, cars within 160 studs and in view):**
  - It uses the player car's own body springs (DrivingFeel `BodyRoll` 3.4 deg/g, `BodyPitch` 3.0 deg/g, spring 90 / 70, damping 12 / 10), times `Config.Traffic.BodyRollK` / `BodyPitchK` 1.4.
  - Vans and buses lean x1.45 / x1.3, racers x0.6 / x0.7.
  - The yaw rate comes from the heading change and gives the sideways g. The forward g comes from the speed change.
  - In Play, a racer through Sule roundabout leaned 0.5-2 degrees and dipped its nose up to 3 degrees.
- **Wheels:** the front wheels steer to the path's curve (wheelbase model, eased). Every wheel spins at the real speed for its size (`WheelR`, measured from the model; was 1.1 for all).
- **Lane joints:** every car now rounds the joints between the straight 1:1 lane pieces over 12 studs each side (`racerSample`). Before, the nose snapped at every lane point.
- **Indicators: not added.** The 21 traffic models have no turn-lamp parts (only a few have tail or head lamp meshes), and the owner said on 2 Nov there are no lights on traffic cars.

**3. Speed changes**
- `driveSpeed`: the pull fades near the wanted speed and at top speed. Braking grows with how much too fast the car is. Both build up at `Jerk` (x4 for a hard stop), so no car changes speed in one frame.
- `Config.Traffic`:

  | Setting | Now | Was |
  |---|---|---|
  | Accel | 8 studs/s² (about 2.7 m/s²) | 28 |
  | Brake | 14 (about 0.5 g) | 70 |
  | EmergencyBrake | 27 (about 0.95 g) | 140 |
  | PlanBrake (new) | 9 (stops and gaps are planned at this) | - |
  | Jerk (new) | 30 studs/s³ | - |
  | Headway | 1.5 s | 0.5 s |

- `TrafficMix.Racer`:

  | Setting | Now | Was |
  |---|---|---|
  | Accel | 24 | 40 |
  | Brake | 40 (1.4 g) | 95 (3.4 g) |
  | MaxBrake (new) | 48 | - |
  | Headway (new) | 0.6 s | - |

  `racerCap` now looks up to 50 pieces ahead (was 14), because the real braking distance is longer.
- **Everyday cars brake in time:**
  - for the next turn, found as far ahead as a comfortable stop;
  - for lights up to 16 pieces ahead (was 4 pieces / 160 studs);
  - for bends at lane joints, at about 0.3 g sideways (`jointSpeed`, cars in sight only).
- **A car that cuts in** (a player or a racer) makes the car behind drop back under its pace. Before, it braked to a full stop.

## Overlap test
- **Tool:** `Games/CityLegends/tools/traffic_overlap_test.luau`, run on the client in Play.
- **What it counts:** every frame, the traffic Chassis boxes (shrunk 0.2 a side) that overlap another traffic car or the player's car. One count = one new overlapping pair.
- **Conditions:** test store, 46 cars, 60 s per spot. The player's car is parked on the road at each spot. Sule ran right after a traffic respawn with `TestRareChance` 0.3 (racers).

| Spot | Before: NPC pairs (frames) | Before: with player | After: NPC pairs (frames) | After: with player |
|---|---|---|---|---|
| Kabar Aye by Myanmar Plaza / Sedona junction | 4 (54) | 0 | **1 (3)** | 0 |
| Hanthawaddy roundabout | 78 (every frame, 2835) | 9 | **2 (1193)** | 0 |
| Sule roundabout, 3-7 racers | 30 (1834) | 3 | **1 (3)** | 1 |
| **Total** | **112** | **12** | **4** | **1** |

- An earlier build in the same session got 0 and 0 at the first two spots (then 1 and 1 on a second run). Runs vary with where cars spawn.
- **What is left (not 0 yet):**
  - **Hanthawaddy roundabout entries** ((28144, 32220) and (28313, 32298)): two queues on converging lanes. One car waits by the rule and the other keeps rolling along its own lane into it. The pair then stays overlapped while the queue stands (1193 frames). Two stricter rules were tried and measured worse (more standoffs, which ended in overlaps), so they were taken out:
    - "wait for any car whose middle is ahead of you";
    - "never drive into a waiting car".
  - **Next fix:** give way earlier at lane merges in the lane data (a zipper point where two lanes join), not at contact.
  - **Sedona junction** (34697, 26947): 3 frames.

## Cost (ScriptProfiler, client, Studio PC, 30 s at the Kabar Aye spawn, 0 racers)
- `Traffic.update` was **1.79 ms/frame** before (43 fps in Studio). After: **2.33 / 2.54 / 2.97 ms** in three runs (40-44 fps).
- The last run also has another job's change from the same day (far cars slide every frame between thinks, commit 09e6cf41), which adds BulkMoveTo work.
- New parts, ms/frame:
  - `stepBlocked` + `boxDepth` 0.19-0.25
  - `jointSpeed` 0.07-0.10
  - `racerSample` for every car 0.05-0.09
  - `bodyMotion` 0.04-0.07
- Already trimmed:
  - crossConflict skips pieces that cross nothing;
  - lookAheadGap skips cars farther than it looks;
  - the joint cache;
  - bends only within a comfortable stop and in sight;
  - body motion only in view.
- So Traffic is about 0.5-0.7 ms a frame dearer on a PC. Phones in low-end mode run 14 cars, and the pair checks shrink with the square of the count. Not measured on a phone.

## Pictures
- Before:
  - ![[2026-11-27 Traffic motion - roundabout queue (before) 1.jpg]]
  - ![[2026-11-27 Traffic motion - roundabout queue (before) 2.jpg]]
  - ![[2026-11-27 Traffic motion - racer turned sideways behind the player (before).jpg]] The Ferrari racer stood turned about 20 degrees, stuck beside the player's car. That is the "car rotated" cut-up.
- After:
  - ![[2026-11-27 Traffic motion - roundabout (after).jpg]]
  - ![[2026-11-27 Traffic motion - roundabout merge close-up (after).jpg]] The merge queue at the roundabout entry: cars wait in line, but two converging queues still sit close.
  - ![[2026-11-27 Traffic motion - Kabar Aye junction with bus (after).jpg]]
  - ![[2026-11-27 Traffic motion - racer at Sule (after).jpg]]
- **Not captured:** a clean frame strip of a racer lane change. Studio screenshots take about a second each, and no followed racer changed lane during the 60 s window. The S-curve is checked by numbers (above). Look at it in Play behind a racer on Kabar Aye.

## Traps
- The repo's `Traffic.lua` was edited by another job at the same time (commit 09e6cf41, far NPCs smoother, "repo only, Studio closed"). Its two hunks were put into Studio with this job, so Studio = repo now (hash checked).
