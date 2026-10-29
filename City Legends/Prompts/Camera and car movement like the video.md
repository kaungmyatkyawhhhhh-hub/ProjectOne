# Prompt: camera and car movement like the reference video

_For Claude Code on the PC, with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`)._

## The reference
- **The video:** `Games/CityLegends/imports/Cars FOV and Driving physcis.mp4` (65 s, 1280x720, 60 fps, no sound). It's a mod for a big racing game (a McLaren on Japanese mountain roads and a highway) that shows **STOCK vs ACTIVE** for each effect. The owner wants City Legends to feel like the ACTIVE side.
- Watch it yourself if you can (open it, or pull frames with ffmpeg). What's in it, by time:

| Time | Section | What ACTIVE does |
|---|---|---|
| 0:04–0:07 | Immersive camera | A very low camera just behind and beside the rear wheel, close to the road. The road blurs under it. The car fills about a third of the screen. |
| 0:08–0:14 | Character breathing | Parked, in the driver's seat. The view rises and falls very slightly, like breathing (a slow 3–4 s cycle, only a few pixels). The seat view sits a little further back and higher than stock, so you see more windscreen and the whole wheel and hands. |
| 0:15–0:28 | G-forces and corner lean (cockpit) | In corners, the driver's head tilts and slides: the horizon tilts about **5–8°** at the peak of a hard corner, and the view slides towards the outside of the turn, then comes back smoothly. Hard braking (78 → 61 mph) throws the head **forward and down** towards the wheel, then it settles. Pulling away pushes it back. Hands turn the wheel and cross over in tight turns. |
| 0:29–0:41 | High-speed camera shake (cockpit) | From about 110 mph up, the view sways slowly (roll about 2–4°, a few % of the screen up and down, about a 2–3 s rhythm), with a small fast vibration on top. It grows with speed (stronger at 160 than at 115). The car stays readable: no wild shaking. |
| 0:42–1:04 | G-forces and corner lean (chase camera) | STOCK: the camera is locked straight behind. ACTIVE: the camera lags. In corners the car **slides sideways in the frame** (towards the outside) and the camera rolls a little with the road. Under hard acceleration the car **pulls away** from the camera (it gets smaller), and under braking it **comes closer** (bigger). Strong motion blur on the road and trees at high speed. The camera sits **low**, about bumper to roof height. |

- **What does not happen in the video:**
  - The FOV doesn't jump around a lot.
  - The chase camera doesn't zoom wildly with speed.
  - The cockpit FOV stays the same at all speeds.
  - The sense of speed comes from **camera lag, distance, sway, shake and motion blur**, not from a huge FOV stretch.

## What City Legends has now (`Config.Camera`, `Config.DrivingFeel`, `src/client/Driving.lua`)
- **Immersive chase camera:**
  - `Fov 74` + `FovBoost 38` at top speed, so up to about 112°. Much wider than the video; it can look fish-eyed.
  - `Distance 11.5`, `Height 3.4`, `SpeedPull 2.5`, `Lag 3.2`, `Swing 0.3`, `Buzz 0.09`, `Blur 4`.
- **`Drama`** (g-forces):
  - side slide 1.6 studs;
  - roll up to about 9°;
  - pitch 0.04;
  - `AccelFov 8`, `BrakeFov 6`;
  - **`Cabin = 0.3`**: the driver's seat only gets 30% of it.
- **Cockpit:** `InteriorFov 64`, `InteriorFovBoost 0`. The owner chose the same cabin FOV at every speed: **keep that**.
- **Physics:** `Config.DrivingFeel`, with per-class springs in `Suspension`, `BumpKick`, `RoadTexture`, and the speed effects `RushFrom` / `RushTo`, `Vignette`, shift / launch FOV kicks.

## What to change
1. **Chase camera FOV: calmer.**
   - Drop `FovBoost` from 38 to about **10–12** (so about 74 → 86 at top speed).
   - Keep the small accel / brake FOV kicks (about 4–5°).
   - Get the speed feel from distance and lag instead:
     - `SpeedPull` about 4–5 studs: the camera falls back at speed;
     - more `Lag`: the car pulls away on launch and comes closer on braking, like 0:47–0:52;
     - stronger motion blur at speed.
2. **Chase camera in corners**, like 0:52–0:57:
   - the car slides towards the outside of the frame: about 2–3 studs at a hard corner, more with speed;
   - the camera rolls with the corner, but only about **3–5°**, smoothly;
   - it returns to centre over about half a second when you straighten up. No snapping.
3. **Low immersive camera**, like 0:04–0:07: add it as a camera option (the C key cycle): very low (about wheel-top height), close, a little off to the side, strong road blur.
4. **Cockpit: full head movement.** Raise `Drama.Cabin` for the head moves, but keep the FOV fixed:
   - **Corner lean:** the horizon tilts up to about **6°** and the head slides to the outside of the turn (about 0.3–0.5 studs), from the real sideways g.
   - **Braking:** the head dips forward and down (up to about 0.4 studs and 4–6° pitch at full braking), then settles back with a small overshoot.
   - **Launch:** the head pushes back about 0.3 studs.
   - **Spring and damping:** every head move follows a spring (about 4–6 per second response, a little bounce) so it feels like a body, not a fixed camera.
   - **Look into the turn:** the view turns a few degrees towards where the road is going.
5. **Breathing** (cockpit, when slow or parked): a tiny slow rise and fall (about 0.03–0.05 studs, a 3.5 s cycle, with small random changes). It fades out above about 20 mph.
6. **High-speed shake:** above about 100 mph (`RushFrom` to `RushTo`), a slow sway (roll up to about 2–3°, small up / down) plus a fine fast vibration. Both grow with speed, are cabin and chase, and are built from smooth noise, not random jumps. Lighter on bad roads only if it already exists.
7. **Car body movement** (so the car itself looks like the video from the chase camera):
   - **Body roll** in corners: 2–4° on sports cars, 4–6° on SUVs and sedans.
   - **Squat** under acceleration and **nose dive** under braking: 1–2° on sports cars, more on SUVs.
   - Settle after each move with a small bounce, using the existing per-class `Suspension` springs.
   - Check the body moves on the visual model, while the physics box stays steady.
8. **Steering wheel and hands:** the wheel turns more at low speed (up to about 270–450° lock-to-lock-half for parking / slow corners) and less at speed. The driver's hands follow, and cross over on big turns if the rig allows. Small corrections are visible on the straight at speed.
9. **Settings and safety:**
   - Add a **Camera** settings section:
     - Camera shake: Off / Low / Normal;
     - Head movement (cockpit): Off / Low / Normal;
     - Motion blur: Off / On;
     - FOV slider (chase only, 60–90).
   - **Respect `GuiService.ReducedMotionEnabled`** (Playbook rule): if it's on, start with shake and head movement Off.
   - Camera code is client only and sets `Camera.Focus` every frame.
   - No extra cost per frame: a few springs, no loops over parts.
10. **Put every number in `Config.Camera` / `Config.DrivingFeel`** with a short comment, so the owner can tweak them.

## How to test
1. In Studio Play, drive the same 3 things with each camera: a hard corner on the mountain or loop, a hard stop from 80 mph, and flat out on the highway to top speed.
2. Record a short clip or take 4 screenshots per test, and put them next to the video's frames at the same moments (0:23 corner, 0:22 braking, 0:35 shake, 0:47 chase acceleration, 0:53 chase corner). Show the owner.
3. Check on a phone-size screen (667x375): still easy to drive, nothing sick-making.
4. Check FPS before and after: no drop.
5. Every Lune test passes. `luau-lsp analyze` is clean.
6. Write the changes into `City Legends/City Legends.md` (Driving feel) and commit and push to `master`. Save the place.

## When done, tell the owner (short)
- what changed in each camera;
- which keys and settings;
- the side-by-side screenshots;
- what to tweak if it's too much: the Config names.
