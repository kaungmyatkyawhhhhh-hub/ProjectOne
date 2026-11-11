---
date: 2026-11-03
tags: [tools, blender, mcp, thumbnails]
---
# Blender MCP on the owner's PC vs Claude's cloud Blender (3 Nov)
Owner: "how about i open blender and give u mcp, is it any different from u rendering them in blender".

## Difference
- Same Blender, same scripts, same art: the result looks the same if both work.
- Owner's PC wins on: GPU rendering (Cycles GPU/OptiX, Eevee) = much faster, cleaner (cloud: Blender 4.0.2 on CPU, no OIDN denoiser, no Eevee headless, freestyle crashes); the Studio .obj exports stay on the PC (no uploading big texture folders); owner can watch and tweak in the viewport.
- Cloud wins on: owner's PC stays free; nothing to install.
- Decision: use the MCP on the owner's PC for the thumbnails (speed + quality), cloud as backup.

## Setup (mcp-for-blender, was blender-mcp; v2.0.0, Sep 2026)
1. Install uv (official installer, docs.astral.sh/uv).
2. Terminal: `uvx mcp-for-blender install-addon` (or Blender > Edit > Preferences > Add-ons > Install addon.py, enable).
3. Claude desktop app > Settings > Developer > Edit Config, add: {"mcpServers": {"blender": {"command": "uvx", "args": ["mcp-for-blender"], "env": {"DISABLE_TELEMETRY": "true"}}}} ; restart the app.
4. Blender: N panel > MCP for Blender tab > Start MCP Server / Connect to Claude.
## Rules
- Its socket has no password: keep it on localhost only. Save the .blend before each session (the tool runs Python in Blender).
- Telemetry off (env above). Don't use its AI model generators (Meshy, Tripo, Hyper3D, Hunyuan): "ur the artist", no AI art. Poly Haven HDRIs/textures are CC0 and fine; Sketchfab models need their licence checked.
Sources: pypi.org/project/blender-mcp (2.0.0, 16 Sep 2026), github.com/ahujasid/mcp-for-blender/wiki.
