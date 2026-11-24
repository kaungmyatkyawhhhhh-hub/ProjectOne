---
date: 2026-11-25
tags: [gymarc, progress, icon, blender]
---
# GYM ARC - icon rendered in Blender from the real avatar (25 Nov, night)

Handoff: [[HANDOFF - GYM ARC icon render (do the gym arc render)]] · history: [[2026-11-24 GYM ARC - New muscle icon v1 (vs Power Lifters)]]

Nothing uploaded, nothing published, place not saved. Waiting for the owner's pick.

## Result (`GYM ARC/Assets/icon_render_25nov/`)
- **A2 (Claude's pick):** `GYMARC_ICON_A2_close.png` (1024) + `_512.png`. Our Bacon Hair, GYM ARC max build, tanned, one-arm flex holding a giant blue "1000 LB" dumbbell (plates bigger than his torso) by his head, smirk, close low camera, bright gym (ceiling light panels, windows, chrome racks, blue LED strips). Logo v10 bottom-left.
- **A (wider):** `GYMARC_ICON_A_flex.png` — same pose, more gym visible, logo top-right.
- **B:** `GYMARC_ICON_B_press.png` — overhead press of a giant barbell, logo top-right. Weaker (head small, bar cheated toward camera).
- Board vs Power Lifters at 300 / 150 / 60 px: `gymarc_icon_render_board.jpg`.
- Raw renders: `render_*_raw.png`. Blender files: `_work_gymarc_icon*.blend` (scene "GymArcIcon").
- Measured at 64 px: A2 mean 0.43 / 2% near-black (Power Lifters 0.34 / 29%). Brighter than the band on purpose: the owner chose BRIGHT daylight. If it reads washed-out in the row, darken the background, not the body.

## How (repeatable)
1. **Studio (Edit):** `ServerStorage._Builders.ThumbnailRigBuilder`: `B.Build{heightInches=84, looks=B.Looks("max",1), top="Tank", shorts="Black"}` → `B.Pose` → `B.Dress` → `B.Place(m, (0,4000,0))`. Models kept in `ServerStorage.ThumbnailScene`: `ICON_flex_max`, `ICON_press`.
   - Pose axes (checked): shoulder/elbow **+X swings the limb forward**; **Z = in the frontal plane** (right arm: forearm angle from straight down = shoulder Z + elbow Z, e.g. 78 + 108 = flex; 118 + 62 = vertical forearm overhead). Left side = negative Z. Waist **-X leans forward**. Left hand on hip: LeftShoulder Z -35, LeftElbow Z **+80**.
   - "max" looks = smooth blocky sim body (owner's "smooth, not realistic"). "monster" = lumpy, rejected by eye.
2. **Export:** `_tools/IconExport_TEMP.server.luau` as a Script in ServerScriptService, attribute `Models`, press Play, Stop, delete it. The receiver is a tiny HTTP server started INSIDE Blender (no shell on this PC needed). The Assistant's execute_luau can't reach localhost; a Play-mode Script can.
3. **Blender:** `_tools/icon_scene.py` → `compose(hero, db_axis, cam_loc, cam_target, lens, R, head_scale)`; helpers in `icon_lib.py` (from the 4 Nov build_scene), `icon_hero.py` (shirtless: tank pieces get the skin), `icon_set.py` (bright gym, lights, dumbbell/barbell with "1000 / LB" in Impact on the plate face, upright). Face: `_tools/faces/face_classic_smirk.png` (black decal eyes, cocky brows). Head + hair x1.3, body x1.14 wide. Cycles GPU 384 spp ≈ 23 s.
4. **Post:** `_tools/post_icon.py raw logo out corner width` (S-curve, +6% sat, vignette, logo with soft shadow, 512, 64 px mean).

## Gotchas found tonight
- **Templates:** `B.Dress` requires BodyStages in Edit, whose biceps reshape runs ASYNC and empties the 14 `BS_*Arm_Arm_*` templates a few seconds AFTER `RestoreTemplates()`. Wait ~6 s, then restore, then check (done every time; 0 bad at the end).
- **device_commit_files right after a write can send the OLD file** (twice tonight). Wait a few seconds after editing, then commit, then check the text in Blender before running.
- Blender helper materials die when the old hero is deleted: `compose` reloads `icon_hero.py` each time.
- The dumbbell plate shows its number only if its face points at the camera: axis ≈ (0.15, 1, -0.3) for the flex shot.

## Next (after the owner picks)
- Matching 16:9 thumbnails (search shows thumbnails): same set, wider camera, the hero left/right third, the logo in the free side.
- Upload: Creator Hub > Places > Icon / Thumbnails (owner).
