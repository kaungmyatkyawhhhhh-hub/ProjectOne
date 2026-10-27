---
date: 2026-10-28
tags: [speedarc, feature]
status: done (parts version); Blender props ready to import
---
# SPEED ARC - Hub World (Hometown Track)

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

## What's there
- **Track:** blue 6-lane oval (smooth curves made with CSG), white lane lines, aluminium inner curb, darker apron, gold start/finish line with a Neon glow, painted lane numbers 1-6.
- **Start/finish arch:** black steel towers with blue Neon bands, gold top beam, LED screens on both sides (SPEED ARC + race countdown), two waving flags.
- **Stands:** 6 rows along the back straight, 115 low-poly fans in team colours (some holding little flags) who bob, and cheer at the start and the finish. A big screen on the back wall: SPEED ARC / NEXT RACE / EVERYONE STARTS SLOW.
- **School:** brick front with two floors of windows (some lit warm), blue doors under a canopy, steps (spawn), two banners (SPEED ARC HOMETOWN TRACK, EVERYONE STARTS SLOW), a clock tower whose face shows the next race, flags on the roof.
- **Plaza:** tiled, with the SPEED ARC emblem painted in the middle, flower planters, benches, lamp posts.
- **Training:** Sprint Lane, Treadmill canopy, Stair Run, each with a sign (name, +MPH per tap, NEEDS ... MPH).
- **Edges and life:** hedges round the hub, 24 round low-poly trees, low hills on the horizon, moving clouds, mowing stripes on the grass.
- **Lighting (Hub preset):** 16:30 afternoon sun, Atmosphere, ColorCorrection (warm tint), light Bloom and SunRays (both off on low graphics), ShadowMap, 0 lights.

## Numbers
878 parts, 0 lights, 0 Glass, 32 Neon, 11 SurfaceGuis (all with MaxDistance). The hub model is "Persistent" for streaming.

## Blender props (ready, not imported yet)
`Downloads\speed_arc_models\hub\`: Tree_Round_A/B, Tree_Pine, Bleacher_Section, Crowd_Fan_A/B/C, Start_Arch, Treadmill, Bench, Cone, Lamp_Post, Starting_Block (.fbx + .blend + previews). Bevelled, vertex colours from the palette, soft shading baked in (ambient occlusion). 144-1,692 triangles each. Script: `hub_kit.py` (also in `Games/SpeedArc/blender`).
Import: Studio 3D Importer, keep "Scale unit: Stud", import as model, put in `ServerStorage/Meshes`. Then Claude swaps them in.

## Rebuilding
`Games/SpeedArc/tools/build_hub.luau` builds the whole hub. Running it again on the same day replaces it; on another day it moves the old hub to ServerStorage as a dated backup first.

## Previews
![[Tree_Round_A.png]]
![[Bleacher_Section.png]]
![[Treadmill.png]]
![[Start_Arch.png]]
![[Crowd_Fan_B.png]]

## Related
[[SPEED ARC - World, Map and Buildings]], [[SPEED ARC - Lighting]]
