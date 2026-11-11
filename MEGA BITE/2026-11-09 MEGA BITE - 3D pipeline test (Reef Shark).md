---
date: 2026-11-09
tags: [megabite, art, 3d, blender, pipeline, rig, animation]
status: pipeline proven headless (Blender 5.2, Claude's workspace); next run in the owner's Blender, then import to Studio
---
# MEGA BITE: 3D pipeline test, the Reef Shark (9 Nov)

Owner: "yes blender through my blender. no models from creator store."
Rules: [[2026-11-09 MEGA BITE - Art style guide]] (chunky toy cartoon, big eyes, no blood/scars), [[2026-11-03 Blender MCP on the owner's PC vs cloud Blender]] (no AI model generators).
Files: `MEGA BITE/Art/ReefShark/` (scripts, .blend, FBX, texture, previews).

## The pipeline (all by code, so every shark is consistent and re-buildable)
1. `reef_shark.py`: builds the body from cross-sections (a radius profile along the body), fins from 2D outlines (solidify + subdivision), eyes set INTO the head from a surface function, a smile wrapping the front of the snout, teeth on the lip, gills, brows; joins it; a 5-bone spine rig; **weights by position along the body** (every part follows); a 1-s swim loop (travelling sine wave, head nearly still, strongest at the tail).
2. `bake_export.py`: smart UVs, bakes all colours into ONE 512 px texture, one export material, FBX with mesh + rig + Swim action, texture embedded.
3. `render_preview.py` / `anim_strip.py`: 3 preview views + swim frames for checking.

## Result
- **8,920 triangles**, 5 bones, `ReefShark.fbx` 375 KB + `ReefShark_Color.png` 512 px.
- The baked render looks the same as the Blender materials (nothing lost on the way to Roblox).

## What went wrong on the way (and the rule)
| Try | Problem | Fix / rule |
|---|---|---|
| v1 | 21K triangles, a long thin "torpedo", eyes stuck out of the head, mouth a hose under the chin, fins hidden, too shiny | chunky proportions (~2.4x as long as tall), a surface function places every part ON the body, roughness ≥ 0.55 |
| v2 | teeth hung under the chin ("legs" from the front), small fins, belly line too high | the smile wraps the FRONT of the snout; bigger pectoral fins; countershading line lowered |
| swim v1 | eyes and gills floated off while swimming (automatic weights skip separate parts) | weights by position along the body for every vertex |

## Next
1. Owner: open Blender, MCP for Blender tab > Start/Connect; Claude re-runs the scripts in the owner's Blender (same result, GPU renders).
2. Owner: Studio > Import 3D > `ReefShark.fbx` (rig + Swim animation) into the MEGA BITE place (group P&L Studios XP).
3. Then the other 6 evolutions from the same code (Great White + Megalodon reuse the Reef Shark body), ~18 NPC fish at lower detail (~1-2K triangles), and the kit.
