---
tags: [mega-bite, controls, leviathan, build-log]
date: 2026-11-14
---
# MEGA BITE - sprint + stamina, Q dart, snake Leviathan, Leviathan camera (14 Nov)

Owner: "leviathan is all the way at the back now, the camera is too far to the front" / "the leviathan movement should be like
snakes, the head turns and then the body follows it" / "hold shift to sprint, mobile compatible. Q to dart, mobile too" /
"make sprint with a stamina system". Built, tested in Play, place saved (not published).
Backups in ServerStorage: GameConfig_preLeviCam_14Nov, GameConfig_preSprint_14Nov, MB_Swim_preSprint_14Nov, MB_HUD_preSprint_14Nov,
BonePlayer_preSnake_14Nov.

| Change | Where | Checked |
|---|---|---|
| Leviathan camera: camAim 0.75 -> 0.42 (0.75 x 210 studs aimed past the head), camDist 0.5 -> 0.62 | GameConfig Evolutions[10] | Play: Leviathan centred, seen from behind |
| SPRINT: hold Shift / gamepad L2 / the SPRINT button (phones, above the ability, left of PVP). x1.45 top speed; stamina 4 s, refills in 3 s after 0.6 s; needs 25% to restart. Stamina bar on the button (green, gold while sprinting, red when low); FOV 77 | GameConfig.Swim Sprint*, Camera.SprintFov; MB_Swim; MB_HUD | Play: Leviathan 66 -> 95 studs/s, bar drains |
| DART: Q or Space (Shift is sprint now); the DART button was already there for phones; key chips "Q" / "SHIFT" on the buttons for keyboard players only | MB_Swim, MB_HUD | Play |
| SNAKE Leviathan: the head's path (from the swim root, not the rocking Spine0) is recorded; each spine bone turns so its piece of body lies on that path (BonePlayer `snake` per-bone turns, on top of the clip). Caps: 0.22 rad per bone, 1.6 rad whole body (else the 210-stud body folds into a U on its ~45-stud turning circle); eased; one-frame snaps carry the path along | GameConfig `snake = true`; MB_Swim snakeAngles; BonePlayer | Play: turning, the bend grows head -> tail (tail out ~67 studs), straightens down the body after |

Not checked: on a real phone (holding SPRINT with the right thumb), with a gamepad.

## Check pass (owner: "check them for me")
| Test | Result |
|---|---|
| Q dart / Space dart | OK |
| SPRINT button held (mouse in Studio) | OK: sprints while held, stops on release (also when released off the button) |
| Shift until empty, refill | OK: 0 -> stops, ~3 s refill |
| Gamepad L2 | FAILED first (handler only read L2 as gamepad input) -> fixed: L2 read from any input type. Retest OK |
| Holding after the bar empties | restarted in short bursts at 25% -> fixed: an emptied bar needs a fresh press (`c.tired`). Retest OK |
| Phone layout 844x390 (scale 0.9; ~0.77 with the top bar) | FOUND (older layout): the 3-tile right column (next ability / FOSSILIZE / PVP) ran ~58 px into DART. Fixed: on short screens the tiles go in a ROW under the minimap (`layoutRC`, RightCol attribute RowLayout). The stamina bar moved INSIDE the SPRINT button and the button is 66 tall, so the row's labels clear it (~9 px) |
Studio-only test readout: player attributes DbgStamina / DbgSprint (MB_Swim, IsStudio only).
Still not possible here: a real phone thumb test and a real gamepad.
