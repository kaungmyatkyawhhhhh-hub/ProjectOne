---
date: 2026-10-28
tags: [speedarc, feature]
status: done (M4)
---
# SPEED ARC - First 15 Minutes (tutorial)

> **Prompt 11 (28 Oct):** the steps are now Welcome -> FIRST STEP (walk: +10 SPEED, +100 coins) -> FIRST WALL (smash wall 1) -> tutorial race -> podium -> shoes -> Silver -> coach roll at the COACH AGENCY. The step ids are `FirstStep` / `FirstWall` (saves keep their numbers). The race card is a small card top right under NEXT RACE. Test: first step 4.7 s, wall 1 34 s after PLAY. GDD 21 has the new minute-by-minute. The rest of this note is the tap version.

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

GDD 21, built in M4. The server keeps the step (saved, so a rejoin carries on); the client draws it.

## Steps
| # | Step | Done when | Safety (counts only while possible) |
|---|---|---|---|
| 0 | Loading screen + PLAY | PLAY pressed | starts by itself after 25 s |
| 1 | Benji: "Everyone starts slow. Let's fix that!" + NEW RUNNER BOOST 2x for 15 min | 3.5 s | 6 s |
| 2 | GO TO Sprint Lane (gold path + GO HERE) | first tap: FIRST STEP! +100 coins +10 MPH | 45 s: GO TO done for you |
| 3 | "Keep tapping = FASTER!" | combo x1.2 | 25 s |
| 4 | "A RACE IS STARTING!" + RACE! button (after 30 s of training) | the tutorial race ends | 55 s: starts by itself |
| 5 | GOLD MEDAL card | 4 s | 6 s |
| 6 | Buy your first shoes (coins topped up to 250, Canvas Runners glow) | owns Canvas Runners | 75 s: GO TO + Locker |
| 7 | Train to Silver (GO TRAIN) | Silver rank, then a free coach roll | 600 s |
| 8 | Free coach roll (GO TO Coach Corner) | first roll | 75 s |
| 99 | Done: GO TRAIN button whenever you're not training | | |

- **Tutorial race:** private Sprint on the outside lanes vs 3 NPCs at 0.55-0.75x your speed, pace x1.45 (short and exciting). NPCs stay close but are never ahead at the end. One big TAP BOOST! prompt until you boost. It's a gold medal and a win, but it doesn't count for Go Pro.
- **Rules (GYM ARC lessons):** hints never vanish while needed (they pulse every 12 s), hide while a window or race covers them, no popups or race toasts on top, no shop offers, nothing can get stuck (after twice the timeout the step moves on).
- Old saves that already played skip it.

## Studio test switches
`TestAutoPlay` (presses PLAY), `TestTutStep` (start at a step), `TestAddSpeed` (adds MPH now).

## Where it lives
`Server/Services/TutorialService` (+ GO TO / GO TRAIN teleports), `Client/Controllers/TutorialController`, `ReplicatedFirst/LoadingScreen`, `Config/Retention.Tutorial`.
