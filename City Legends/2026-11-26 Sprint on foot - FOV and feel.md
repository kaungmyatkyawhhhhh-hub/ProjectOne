# Sprint on foot - FOV and feel (26 Nov 2026)

Owner asked: "make it so that we can sprint and add some fov changing while sprinting too and find ways to increase their dopamine".

## What it does
- **PC:** hold Shift. **Gamepad:** L3 toggles. **Phone:** round SPRINT button left of Roblox's jump button. A tap turns it on, and it turns off by itself once you stop walking. A tap while standing still waits until you move.
- Only while walking on the ground on foot. Never in a car, a menu (`UI.modalOpen`), or a screen that freezes you (WalkSpeed 0: dealer, workshop). A jump during a sprint keeps the speed.
- Free for everyone. No paid speed.

## Numbers
| | Walk | Sprint | Ease up | Ease down |
|---|---|---|---|---|
| Walk speed | 16 (StarterPlayer) | 25.6 (x1.6) | ~0.43 s | ~0.33 s |
| FOV | 70 | 82 (+12, added on top) | ~0.6 s | ~0.5 s |
| Footsteps (Running sound speed) | 1.0 | 1.35 | with the speed | |

Measured in Play (Shift + W): 16 → 21.8 → 24.7 → 25.6 in 0.4 s; FOV 70 → 82 in ~1.2 s; back to 16 / 70 about 0.6 s after Shift was let go.

## Feel-good (cheap on phones)
- A short whoosh when a sprint starts (`Audio.whoosh`, existing sound).
- Faster footsteps (Roblox's own Running sound, played faster).
- Soft speed streaks at the screen edge (`UI.setSpeedLines`, the driving ones, at 55%; phones get 40% of that).
- A light head bob through `Humanoid.CameraOffset`, so it doesn't fight any camera code.
- A small dust puff at the heels every 0.27 s (2 particles). **Off in low-end mode.**
- The SPRINT button lights up (accent fill, white outline) while sprinting.

## Code
- `src/client/Sprint.lua` (new). `OnFoot.init` calls `Sprint.init(OnFoot)`.
- `src/client/UI.lua`: the button in `buildTouchControls` (same `touchButton` as N2O / DRIFT), `UI.onSprintTouch`, `UI.setSprintButton`.
- `src/shared/Strings.lua`: `foot.sprint` = SPRINT / SPRINT (an English word kept in Burmese, owner rule of 26 Nov).
- Studio test hook: player attribute `TestSprint = true` keeps it on.

## Tested (Studio Play, test store, 26 Nov)
- Shift + W on PC: speed, FOV, bob, footsteps, dust and the button's lit state all logged frame by frame (see the numbers above). No script errors.
- Phone-size shots (PreviewPhone + phone_preview):

![[2026-11-26 Sprint - phone HUD standing.jpg]]
![[2026-11-26 Sprint - phone HUD sprinting.jpg]]

## Not tested
- A real finger tap on the phone button (MCP can't tap buttons). Toggle logic is code-read only.
- Gamepad L3.
- Getting into a car or opening a menu mid-sprint (the code drops the boost and eases the FOV back).
- Feel on a real cheap Android phone.

## Skipped on purpose
- No "distance sprinted" goal. Goals are counted on the server (`ctx.note`), and sprint lives on the client. Adding one needs a new remote with checks against cheating. That's worth doing only if the owner wants it.
