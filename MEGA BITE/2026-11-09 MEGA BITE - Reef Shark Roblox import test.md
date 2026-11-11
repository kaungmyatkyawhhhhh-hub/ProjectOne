---
date: 2026-11-09
tags: [megabite, roblox, import-test, reef-shark, quality-gate]
---
# MEGA BITE - Reef Shark v4 Roblox import test (quality checks 3, 5, 6)

Place: "Mega Bite" (placeId 131715256145044), owned by group 33151111 (Myanmar Builders Club). Model asset **110833713362358** "MB_ReefShark_v4" (group-owned, approved), uploaded as FBX through the Creator Hub assets API in Chrome. It sits in `workspace.MB_ImportTest`, scaled to 16 studs long. Lighting was restored after the test.
Export: `Art/ReefShark/export_roblox.py`. It gives one mesh and one material with a 7-colour palette texture (each face's UVs sit in its colour's cell: crisp flat colours, no baking). 3,450 tris; Root bone at the origin; 8 spine bones + Jaw; max 3 influences per vertex.
Pictures: `Art/ReefShark/roblox_test/` (`roblox_checks.png` = summary).

## Results
- **3, looks pro at game distance:** PASS (with notes). In Roblox lighting the facets, the zig-zag belly, the glowing-looking cyan eye, the brow, gills, maroon mouth and teeth all read clearly from the side, the front 3/4 and the game camera.
- **5, works in Roblox:**
  - Skinning: PASS. The spine bends smoothly when the bones are posed.
  - Jaw shut: PASS (clean).
  - Gape at 16 degrees: small TEAR at the mouth corner and under the jaw (jaw weights are hard 0/1).
  - Phone size (844x390): face, eye and teeth still read; the steel-blue back is close to the blue water colour.
- **6, owner approval:** pending.

## Fixes found (do before the next export, and for every model)
1. **Imports on its side:** needed a +90 degree X rotation in Studio. Fix the FBX axis/rotation in the export so it imports upright.
2. **One-sided faces:** teeth/decals were invisible until `DoubleSided = true`. Fix: recalculate ALL normals outward in the generator (teeth, fins, decals), then DoubleSided can stay off.
3. **Jaw tear at gape:** blend the jaw weights across the mouth corner/cheek (soft falloff over about 0.15 m), and keep the gape at 16 degrees or less in the Bite clip.
4. **Jaw axis sign flips in Roblox** (+X opens in Roblox, +X closed in Blender). Baked FBX animation handles it; procedural code must use the Roblox sign.
5. **Animations were not inside the Model asset:** import the clips through the Animation Editor (FBX) or upload them as Animation assets next.
6. **Eye glow:** Roblox has no emissive from the palette. Use a small Neon eye part or SurfaceAppearance emissive + Bloom.
7. **Contrast with the water:** pick the water colour with the map lighting. If the water stays bright blue, darken the shark's top to navy (like Fisch's sharks) or add a subtle rim, so sharks pop on phones.


## v4b mouth fix (owner 9 Nov 18:18: "the mouth looks weird and sticks out of the shark lips and also inside the mouth theres like red edges that stick out")
Causes:
- The teeth followed a U-shape as wide as the BACK of the mouth all the way to the front, but the snout narrows, so the front teeth poked out through the lips.
- The flat red side walls of the mouth were a fixed width, so they poked out of the narrowing snout.
- Open shells came out inside-out. DoubleSided hid this in the first test.

Fixes in `reef_shark_v4.py`:
- `lip_w()` reads the TRUE lip-edge width per station from the model.
- The teeth follow the lip edge inset by 0.06, round off at the front, are thinner (0.018), and their bases sink into the gum.
- A real mouth cavity: cheek walls run from the inside of the upper lip to the inside of the lower lip, inset 0.11 so they sit behind the teeth. Each wall has a back-to-back twin, so it reads maroon from both sides. The upper vertices stay with the head; the lower ones follow the Jaw bone.
- Normals: the head and jaw shells are flipped outward when inside-out; teeth, fins and decals are oriented outward.
- Checked with a backfacing-red render in Blender, then in Roblox with **DoubleSided OFF**. It renders correctly and the teeth stay inside the lips.

New asset: **74351388218842** "MB_ReefShark_v4b" (group). It is in `workspace.MB_ImportTest`; the old v4 was removed. Pictures: `roblox_test/v4b_mouth_close.jpg`, `v4b_vs_v4.jpg`, `v4b_mouth_blender_checks.png`.
**Rule for every model: test in Roblox with DoubleSided OFF, and do a close-up of the mouth/face from 3-4 angles before showing the owner.**
