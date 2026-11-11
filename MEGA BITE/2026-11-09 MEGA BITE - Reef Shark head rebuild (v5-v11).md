---
date: 2026-11-09
tags: [megabite, art, 3d, reefshark, model]
status: owner approved v11 head (22:42 "ok our one rn is good now")
---
# MEGA BITE - Reef Shark head rebuild (v5 to v11)

**Current generator: `MEGA BITE\Art\ReefShark\reef_shark_v11.py`** (reef_shark_v4.py is stale: device writes could not overwrite it). Export: `export_roblox.py` -> `export\ReefShark.fbx` (4,390 tris). Uploaded 9 Nov 22:50 as **MB_ReefShark_v11, asset 93700816266681** (group 33151111, moderation Approved); in Studio at workspace.MB_ImportTest (ScaleTo x16/441.95, +90 deg X, DoubleSided off). Old v4c/v4d/v5 test copies removed.

## What changed (owner feedback 18:48-22:08)
- Lower teeth no longer poke out under the jaw (inset 0.075, bases barely sunk).
- Brow + eye socket CARVED into the head (bisect along the traced fold/crease/socket lines, brow band pushed out, groove pushed in, groove faces black). No stuck-on slabs.
- Eye = domed glowing lens seated in the groove, turned 40 deg forward, so it reads from side, 3/4 and front.
- Cheek walls are mouth-coloured on both faces (no white slab in the gape); bigger/fewer teeth (10 up, 8 low); chin has real thickness (no razor-thin jaw tip).
- Sheet check: the head sheet's front draws eyes ~6% and mouth ~5% of head height higher than its side; ChatGPT ignored a guide-line template, so the owner chose **split the difference** (face features moved halfway).
- Parameters auto-fitted (~200 versions scored vs the sheet by per-colour overlap + front landmarks): snout shape, lip/jaw heights, eye size, jaw width, teeth size.
- Mouth from the front is a crescent grin (upper lip drops and lower lip rises toward the sides); rounder chin; bigger eyes.

## Still open
- Front brow V / black sockets weaker than the sheet; white upper-lip band thinner in the middle; mouth slightly low.
- Straight-on front at eye level in Studio: eyes only peek over the snout. Then the earlier list (axis on import, jaw tear at wide gape, animation assets, sounds to group).

## Tools / method
See [[2026-11-09 Research - Modelling tools for Claude (round 2)]]: local `bpy` render loop, flat z-buffer scorer, coordinate-descent fit, Mitsuba/libigl available.
