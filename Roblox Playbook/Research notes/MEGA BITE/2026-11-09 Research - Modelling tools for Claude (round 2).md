---
date: 2026-11-09
tags: [megabite, art, 3d, blender, tools, research]
---
# Research - Modelling tools for Claude, round 2 (9 Nov 2026, evening)

Why: the Reef Shark head still did not look 1:1 like the head sheet (owner 19:08 / 19:45 / 19:59: "find stuff on internet for tools that model and add in ur skill"). Round 1: [[2026-11-09 Research - Blender modelling skills for Claude]] (cc-blender-skill, landmark checks).
Owner rules still apply: no Creator Store models, NO AI model generators (Meshy, Tripo, Hyper3D Rodin, Hunyuan, TRELLIS). Tools below are geometry/measuring tools, not generators.

## Tools found and tested
| Tool | What it does for us | Licence | Status |
|---|---|---|---|
| **bpy as a Python module** (`pip install bpy`) | Full Blender in the cloud workspace: build + render + compare locally in seconds, no round trips to the owner's PC | GPL | Installed, used (Blender 5.2.3) |
| **Mitsuba 3** (`pip install mitsuba`, variant `llvm_ad_rgb`) | Differentiable renderer that runs on CPU: optimise vertex positions and colours so renders match the sheet's side AND front views (inverse rendering, like the PyTorch3D "fit textured mesh" tutorial: silhouette loss + RGB loss + Laplacian/edge/normal regularisers) | BSD-3 | Installed, CPU variant loads |
| **libigl** (`pip install libigl`) | ARAP / biharmonic deformation: move named landmark vertices (eye, lip, jaw) to target positions and let the rest of the head bend smoothly, no lumps | MPL-2 | Installed, ARAP available |
| **trimesh** | Mesh checks: watertight, normals, ray casts, section outlines | MIT | Installed |
| PyMeshLab | Remesh/decimate | GPL | Installs, many filters need OpenGL libs in the cloud; use Blender's Decimate instead |
| PyTorch3D | Same fitting as Mitsuba, tutorial "fit_textured_mesh" (CPU works, slow) | BSD | Not needed if Mitsuba works |
| **Official Blender MCP (Blender Lab, v1.0, Apr 2026)** | Blender's own MCP: code execution, renders, screenshots, **search over the Blender Python API docs and manual**; no generation | GPL-3 | Optional upgrade to the current MCP; no AI generators |
| MCP for Blender (ahujasid, ex blender-mcp) | What we use; also has Hyper3D/Hunyuan/Tripo generators | MIT | Keep, but NEVER use its generators |
| StraySpark MCP / Blender MCP Pro | 120-556 tools, verify tools (measure, verify_export); paid/proprietary, include AI generators | paid | Not needed (owner pays nothing) |
| **Monster Mash** (Google, SIGGRAPH Asia 2020) | Sketch-and-inflate modelling: turns a 2D outline into a rounded 3D blob | Apache-2.0 | Idea only: we inflate traced outlines in code the same way |
| Blender **UV Project modifier / projection painting** | Project the sheet's colour regions straight onto the mesh from the side/front cameras | core Blender | Use for exact colour regions (eye, socket, white line) |

## Lessons from the Reef Shark head (9 Nov)
- **Check the sheet first:** draw horizontal guide lines across the side and front views. The ChatGPT head sheet's front put the eyes ~6% and the mouth ~5% of head height higher than its side. No single 3D head can match both. ChatGPT ignores guide-line templates (tested), so regenerating doesn't fix it. Owner decision: split the difference.
- Brow/socket as stuck-on decals look like separate parts. **Carve them into the head:** bisect the head along the traced fold, crease and socket lines, push the brow band out and the groove in, colour the groove black.
- Eye = a domed lens seated in the groove, angled 45 deg between side and front, so it reads from both.
- Score every change: render at the sheet's exact scale, then compare per colour (white/black/maroon/cyan IoU) and look at a mismatch map. Don't judge by eye.
- Device file writes can silently fail to overwrite an existing file: write each version to a NEW file name and check the size before running it.

## Sources
- [PyTorch3D: fit a textured mesh](https://pytorch3d.org/tutorials/fit_textured_mesh)
- [Official Blender MCP vs community servers, 2026](https://www.strayspark.studio/blog/official-blender-mcp-server-comparison-2026)
- [Google Monster Mash (GitHub)](https://github.com/google/monster-mash)
- [libigl Python bindings docs](https://libigl.github.io/libigl-python-bindings/igl_docs)
- [Blender manual: UV Project modifier](https://docs.blender.org/manual/en/latest/modeling/modifiers/modify/uv_project.html)
