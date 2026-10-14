---
date: 2026-10-14
tags: [gymarc, prompt, performance]
status: in progress
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: lag, find the cause and cut triangles (14 Oct)

```text
LAG: find out what's causing it and cut triangles. Save to Obsidian first.

1. MEASURE FIRST (phone emulator, Starter Gym, 5+ NPCs): MicroProfiler + Stats (Render: triangles/draw calls; Scripts; Memory). Tell me if the lag is mostly rendering (triangles/draw calls), scripts, physics or particles. Put the numbers in PROGRESS.md.

2. QUICK WINS (no Blender needed):
   - Every decorative MeshPart: RenderFidelity = Automatic (Roblox lowers detail with distance), CollisionFidelity = Box, DoubleSided = false, CastShadow = false on small props.
   - Same mesh used many times? Make sure they all share the same MeshId/TextureID (drawn together, cheaper).
   - Delete hidden, duplicate or unused models in Workspace, and free models with hidden extra parts.
   - Muscle meshes: other players far away use the lowest stage mesh (from the LOD prompt). Check that's actually working.

3. LIST THE HEAVY MESHES: make a table of the 20 most expensive meshes: name, MeshId, how many copies are in the place, size, and where they are (machines, plates, NPCs, muscle meshes, props). Luau can't read triangle counts, so check them in Studio (3D Importer / Asset Manager / select + Stats) and estimate where you can't. Put the table in PROGRESS.md.

Don't change any mesh shapes yet. I'll simplify them in Blender. Commit.
```
