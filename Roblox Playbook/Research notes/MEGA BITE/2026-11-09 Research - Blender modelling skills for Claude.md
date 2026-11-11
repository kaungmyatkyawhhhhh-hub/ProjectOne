# Research - Blender modelling skills for Claude (9 Nov 2026)

Why: the Reef Shark v3 (traced from the ChatGPT sheet) still looked worse than the sheet, mainly the head. The owner asked to find modelling skills and what Claude needs for modelling.

## What was searched
- The owner's claude.ai skills and the plugin directory: nothing for 3D modelling (only roblox-dev, which covers Luau code).
- Public skill sites and GitHub.

## Findings
| Skill | What it is | Use? |
|---|---|---|
| **roble3/cc-blender-skill** (MIT, v1.4) | 30 Blender skills for Claude Code/Codex: text-to-blender, blender-modeling, **reference-to-3d** (source-locked rebuild from orthographic sheets), **orthographic-registration**, **contour-to-mesh**, **landmark-fit-repair** (eye/mouth/fin-tip positions checked by name), **reference-look-calibration** (match the sheet's colours and lighting), **multiview-fit-loop**, quality-refinement-autoloop, blender-export. Works with the ahujasid-style Blender MCP. | YES. It matches our sheet-then-trace method and adds the missing checks. Clone: github.com/roble3/cc-blender-skill |
| kevinbadi/blender-skills | Mostly Meshy image-to-3D plus product turntables | NO: AI model generator (against our rule) |
| majiayu000 claude-skill-registry "3d-modeling" | General topology, UV and LOD guidance (persona prompt) | Reference only |
| smithery blender-3d-modeling, terminalskills blender-scripting | Generic bpy scripting help | Not needed |

## Key rules taken from reference-to-3d
- The sheet is the contract: measure first, then build. Repeated "plausible but wrong" models mean the missing step is analysis, not another modelling pass.
- Check the face features **separately** from the body outline. The body outline matched 94%, but the eye, brow, lips and teeth were never checked; that is why the head looked wrong.
- Name landmarks on the sheet (eye centre, brow ends, mouth corner, lip line, every tooth tip, fin tips), measure the same points on the render, and fix by the differences.
- Match the look last: same camera framing, then background, base colours, glow, exposure. Don't hide bad shapes with lighting.
- Don't export until the checks pass. The user's eye is the final judge.

## What Claude needs for modelling (decided)
1. Already have: the owner's Blender (MCP), ChatGPT in Chrome for design sheets, and Python (OpenCV/numpy) for measuring.
2. Add: the cc-blender-skill rules above (landmark and look checks).
3. Per creature: a full sheet PLUS a **big head close-up sheet** (side + front of the head only), because the head is where quality is judged.
4. Model the head as its own piece (brow, lip band, jaw, separate teeth rows), not as the body loft clamped.
5. Optional from the owner: in-game screenshots of 2-3 Roblox sharks they like, front/side/top.
