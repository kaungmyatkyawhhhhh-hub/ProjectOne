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

## Update 06:45: owner "why they look so bad" -> "we need some chatgpt help too"
Why the pure Blender renders looked bad (Claude's own diagnosis): background as bright as the body (2% near-black vs Power Lifters 29%), raw in-game meshes (lumps, abs/shorts seam), flat one-tone skin, a crude hand-drawn face, a toy-like plate, an empty gym.
**Fix that worked: hybrid.** Our Blender render (A2 raw, no logo) attached to ChatGPT as the LAYOUT, + bacon_real_v1.png (head) + Power Lifters (quality only). Prompt: "RE-RENDER image 1 ... KEEP its exact layout ... UPGRADE ONLY THE FINISH". 1 follow-up in the same chat fixed the hair (solid Bacon Hair, not spiky), skin (bronze, less neon), smirk, and over-sharpening.
- Result: `GYMARC_ICON_C_gpt_finish.png` / `_512.png` (logo v10 bottom-left in code). Raw: `gymarc_icon_gpt_repaint_v1/v2.png`. Board: `gymarc_icon_gpt_board.jpg`.
- 64 px: mean 0.347, 11% near-black (Power Lifters 0.337 / 29%).
- ChatGPT chat: "Re-render Roblox Icon".
- Lesson: our render gives the real character, pose and layout; ChatGPT gives the finish. Neither alone was good enough.

## Update 07:15: owner "why is it so tanned now, it looks bad cuz its dark and contrast is bad"
- The owner REJECTS the dark tan (it reads dark and muddy). Skin = the LIGHT bright orange-peach Roblox skin like Power Lifters, the lightest thing in the image, soft orange shadows (never brown). This replaces the handoff's "golden-bronze tan".
- Same ChatGPT chat, one follow-up: lighter skin, a bright sunny gym, cooler/darker background behind him.
- Result: `GYMARC_ICON_D_light.png` / `_512.png` (raw `gymarc_icon_gpt_repaint_v3.png`), board `gymarc_icon_light_board.jpg`. 64 px mean 0.504, 6% near-black.

## Update 07:50-08:00: Power Lifters contrast, the Man face, more contrast on the guy
- LIKED LOOK = Power Lifters contrast: dark moody navy/black background (~1/3 near-black), light glowing orange skin as the brightest thing, glossy white highlights, a thin electric-blue rim light. Not the bright daytime gym (D), not a dark tan (C). -> `GYMARC_ICON_E_contrast.png` (raw v4), 64 px mean 0.333 / 34% near-black (PL 0.337 / 29%).
- FACE (owner, sent the picture twice): the classic Roblox "Man" face: thick dark arched brows, white eyes with dark pupils, a thin lopsided smirk rising to the right, a small cheek line on the right. Attached it to the same ChatGPT chat: "change ONLY the FACE: use EXACTLY the face from the image I just attached". (First try said "Image generation failed"; Try again worked.) Raw `gymarc_icon_gpt_repaint_v5_manface.png`.
- Owner: "more contrast & ONLY A BIT more definition on our guy" -> done in code, not ChatGPT: `_tools/grade_guy.py` (skin-hue mask; brightness contrast x1.25 around his mid tone + local contrast 0.3 at 14 px; colour kept, a first version that also raised saturation turned him too red, so contrast is on brightness only). No-logo graded: `gymarc_icon_v5_graded_nologo.png`.
- **Current: `GYMARC_ICON_F_manface.png` / `_512.png`**, board `gymarc_icon_F_board.jpg`. 64 px mean 0.338 / 34% near-black.

## Update 08:10: owner "something is off, like the colouring"
Measured vs Power Lifters (skin = orange pixels): PL skin sat 0.82 / value 0.93 / shadows 0.49, frame 41% warm vs 22% cool. F: skin sat 0.72, value 1.00 (highlights clipped = flat plastic), shadows only 0.64, frame 29% warm vs 31% cool (cold blue background + blue plate, skin looked pasted on).
Fix:
1. ChatGPT, same chat: change ONLY the background lights: about half warm amber lamps / orange bokeh / a warm glow on the back wall, a few blue LEDs kept low (raw `gymarc_icon_gpt_repaint_v6_warmlights.png`).
2. Code: `_tools/grade_guy.py` then `_tools/grade_color.py` (skin: highlights un-clipped to ~0.93, shadows deeper, saturation up toward 0.82, hue nudged to PL's golden 24; a warm split-tone on mids/highlights). Bug fixed: the hue nudge must only touch orange pixels, or the blue rim turns green.
- **Current: `GYMARC_ICON_G_warm.png` / `_512.png`**, board `gymarc_icon_G_board.jpg`. 64 px mean 0.327 / 34% near-black, 34% warm / 21% cool.
- Rule for this look: dark background WITH warm lamps (not all blue), golden-orange skin that never clips to white, the blue plate as the one big cool colour.

## 08:05 OWNER APPROVED G ("this is way better")
**Final icon: `GYMARC_ICON_G_warm.png` (upload `GYMARC_ICON_G_warm_512.png`).** Not uploaded yet.
Next: 16:9 thumbnails in the SAME look (our Blender render for layout -> ChatGPT finish in one chat -> Man face -> warm lamps in a dark gym -> grade_guy.py + grade_color.py -> logo in code), in a new chat.

## Update 08:25: owner "the skin looks so bad, too glossy, like wet flesh of orange meat"
- RULE: skin = smooth SATIN, almost matte Roblox plastic (a clean toy / premium GFX), soft broad highlights only on the tops of shoulders, pecs, arms; even light golden-orange; soft shading, no wet streaks or dark wet grooves. Never glossy/oily. My grade_color.py (more saturation + deeper orange shadows) made it worse: do NOT use it on satin skin; use only `_tools/grade_guy_soft.py` (contrast x1.15, local 0.2, colour kept).
- Same "change ONLY the SKIN MATERIAL" follow-up sent in both ChatGPT chats (icon: "Re-render Roblox Icon"; thumbnail: "Create Roblox Thumbnail").
- **Current icon: `GYMARC_ICON_H_matte.png` / `_512.png`** (replaces G). **Thumbnail / ad #1: `GYMARC_THUMB_T1_flex_matte.png`.** Board `gymarc_matte_board.jpg`.
