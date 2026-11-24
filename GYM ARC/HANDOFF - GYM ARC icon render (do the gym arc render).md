---
date: 2026-11-25
tags: [gymarc, handoff, icon, blender]
---
# HANDOFF: "do the gym arc render" = the new GYM ARC ICON, rendered in Blender

If the owner says **"do the gym arc render"**, this is the task. Full history: [[2026-11-24 GYM ARC - New muscle icon v1 (vs Power Lifters)]] (GYM ARC\Progress).

## Why (owner, 24-25 Nov)
- 2 CCU; the click rate is 3.7%. The owner thinks the icon is a big part of it. His reference: the **Power Lifters** icon (vault `GYM ARC\Assets\thumbs_nov\refs\ref_powerlifters_icon.png`).
- ~15 ChatGPT rounds were all rejected. The final verdict (03:15): "everything so ugly". Claude's diagnosis: they all look like **AI images** (glossy plastic everywhere, generic muscles, invented gyms). Power Lifters / Gym Star look like **real Roblox GFX**: a real avatar posed and lit in Blender.
- So: **render the REAL in-game Bacon Hair in Blender**, not ChatGPT.

## Decided direction (owner)
- **Audience:** kids + older players who like realistic → semi-realistic, NOT cartoony (Gym Universe style = too kiddy).
- **BRIGHT:** a bright realistic daylight gym (top search games are bright; the owner's rule "lighting never dark").
- **Power Lifters' QUALITIES, not its layout:**
  - a huge, close character (~70% of the width, cropped mid-thigh, leaning in);
  - no empty space;
  - a giant weight bigger than his torso with a big number ("1000 LB");
  - a warm tanned body that pops;
  - 2 colour families only.
- **Don't copy Power Lifters:** no plate stack on the left edge + character right + logo top-left combo.
- **The character:**
  - our real Bacon Hair, tanned (bronze, not neon orange);
  - a Roblox bodybuilder body, smooth and blocky, NOT realistic veins/striations;
  - a confident smirk.
- **Logo:** the new simple blue logo v10 ("GYM" white chrome / "ARC" electric-blue chrome). Transparent file in the owner's Downloads as `gymarc_logo_v10_blue_simple.png`. Place it in code in the empty corner.
- **Name:** keep "GYM ARC" in caps.

## How (pipeline)
1. Read the Brain + the icon recipe: `Roblox Playbook\Research notes\2026-11-05 PLAYBOOK - Roblox icon, thumbnail and logo recipe.md` (sections "Lessons 24 Nov" at the end).
2. **Studio:**
   - pose the real Bacon Hair with GYM ARC's own muscle meshes at max build (as in the 4 Nov pipeline: `GYM ARC\Progress\2026-11-04 GYM ARC New icon and 2 thumbnails (v1).md`, OBJ export via the temp receiver, ThumbnailRigBuilder);
   - pose: a close dumbbell curl or a deadlift, leaning toward the camera.
3. **Blender** on the owner's RTX 3060 PC:
   - Cycles, bright daylight gym set (windows, white walls, chrome racks, black iron plates);
   - a warm sun key, soft fill, a subtle rim;
   - a tanned satin skin material;
   - a giant dumbbell/plates with "1000 LB".
4. **Post in code:**
   - the logo in the empty corner;
   - grade test (mean ~0.30-0.36 like Power Lifters);
   - a 60 px test;
   - a side-by-side with Power Lifters at row size.
5. Show the owner 2-3 renders (different poses), then make matching 16:9 thumbnails (search shows thumbnails, not icons).

## Best ChatGPT attempt so far (fallback only)
`GYMARC_ICON_v2_closeup_logo_512.png` (owner's Downloads): owner said "way better" but "looks like a direct copy of Power Lifters".

## Status 25 Nov ~05:00 (Claude, chat)
Steps 1-4 done for the icon: 3 renders from the real avatar (A2 close flex = pick, A wider, B overhead press), logo in code, board vs Power Lifters. See [[2026-11-25 GYM ARC - Icon rendered in Blender from the real avatar]] (GYM ARC\Progress). Waiting for the owner's pick, then step 5 (16:9 thumbnails).
