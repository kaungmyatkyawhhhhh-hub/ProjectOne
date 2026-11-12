# MEGA BITE - EXP stars made 2D with a 3D look (12 Nov 2026, 21:30)
Owner: "dont make the stars 3d anymore, make it 2d but the art style must look 3d". Follows [[2026-11-12 MEGA BITE - EXP star VFX + sounds]].

## What changed
- The reward stars were real meshes (MB_VFX.Kit.Star3D) in a full-screen ViewportFrame. Now they are plain ImageLabels playing a spin flipbook. The ViewportFrame and its camera are gone (cheaper on phones, no 3D layer to render).
- Art: a puffy 5-point gold star built and rendered in Blender (Cycles, 48 samples): raised centre with a ridge to each tip, heavy bevel, gold (base 1.0/0.66/0.06, metallic 0.55, roughness 0.22, clear coat), soft key from top-left, warm fill, rim light from behind.
- 16 frames of a half turn (the star looks the same from the back, so a half turn loops) with an 18 deg wobble, 256 px cells in a 1024 px 4x4 sheet. Dark warm-orange outline (4 px) added in Python so it reads on any background.
- Image asset **100838108513631** (Approved). Files: `Art\StarSpin2D\` (star.py, proc.py, sheet, dark/light previews).
- MB_UIMotion: each star gets a random start frame, spin speed 22-34 frames/s, random direction and a ±14 deg tilt, so a burst never looks copy-pasted. Size about 5% of screen height (30-52 px), grows to 1.25x at the top of the pop, shrinks to 0.55x as it reaches the counter. Halo, sparkle trail, twinkle, landing flash and the sound ladder are unchanged.
- Checked in Play: a 9-star burst reads as glossy solid 3D stars spinning at different angles, then flies into the EXP counter. Test hook removed.
- Backup: ServerStorage.MB_UIMotion_pre2DStars_12Nov.

## Lesson (K06)
A "3D-looking" UI item does not need 3D: render the real 3D object to a short spin flipbook once and play it with ImageRectOffset. Same look, no ViewportFrame cost, and each copy can start on a different frame and spin at its own speed.
