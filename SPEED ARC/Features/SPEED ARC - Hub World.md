---
date: 2026-10-28
tags: [speedarc, feature]
status: done (Blender meshes in)
---
# SPEED ARC - Hub World (Hometown Track)

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

## What's there
- **Track:** blue 6-lane oval (smooth curves made with CSG), white lane lines, aluminium inner curb, darker apron, gold start/finish line with a Neon glow, painted lane numbers 1-6.
- **Start/finish arch:** black steel towers with blue Neon bands, gold top beam, LED screens on both sides (SPEED ARC + race countdown), two waving flags.
- **Stands:** 5 Blender bleacher sections (6 rows) along the back straight, 129 low-poly fans in team colours (some holding little flags) who bob, and cheer at the start and the finish. A big screen on the back wall: SPEED ARC / NEXT RACE / EVERYONE STARTS SLOW.
- **School:** brick front with two floors of windows (some lit warm), blue doors under a canopy, steps (spawn), two banners (SPEED ARC HOMETOWN TRACK, EVERYONE STARTS SLOW), a clock tower whose face shows the next race, flags on the roof.
- **Plaza:** tiled, with the SPEED ARC emblem painted in the middle, flower planters, benches, lamp posts.
- **Training:** Sprint Lane, Treadmill canopy, Stair Run, each with a sign (name, +MPH per tap, NEEDS ... MPH).
- **Edges and life:** hedges round the hub, 24 round low-poly trees, low hills on the horizon, moving clouds, mowing stripes on the grass.
- **Lighting (Hub preset):** 16:30 afternoon sun, Atmosphere, ColorCorrection (warm tint), light Bloom and SunRays (both off on low graphics), ShadowMap, 0 lights.

## Numbers
575 parts with the meshes (878 before), 0 lights, 0 Glass, 11 SurfaceGuis (all with MaxDistance). The hub model is "Persistent" for streaming.

## Blender props (imported 28 Oct)
In use: 5 bleacher sections, 129 crowd fans (3 kinds), start arch, 4 treadmills, 24 trees (2 round + pine), lamps, benches, cones, starting blocks. Glows stay as thin Neon parts on top of the meshes (arch bands, seat edges, treadmill stripes and screens, lamp glow).
The owner's imports live in `ServerStorage/Meshes/<Name>` (anchored, SmoothPlastic, white so the vertex colours show). The builder uses them when they're there, and falls back to parts when they aren't.
Blender X = Roblox X, Blender Y = Roblox Z (no turning needed except the arch and starting blocks).

`Downloads\speed_arc_models\hub\`: Tree_Round_A/B, Tree_Pine, Bleacher_Section, Crowd_Fan_A/B/C, Start_Arch, Treadmill, Bench, Cone, Lamp_Post, Starting_Block (.fbx + .blend + previews). Bevelled, vertex colours from the palette, soft shading baked in (ambient occlusion). 144-1,692 triangles each. Script: `hub_kit.py` (also in `Games/SpeedArc/blender`).
New props: Studio 3D Importer, keep "Scale unit: Stud", import as model, then Claude moves them into `ServerStorage/Meshes` and rebuilds.

## Screenshots (with meshes)
![[2026-10-28 meshes training area.jpg]]
![[2026-10-28 meshes arch.jpg]]
![[2026-10-28 meshes sprint lane.jpg]]
![[2026-10-28 meshes treadmill play.jpg]]

## Rebuilding
`Games/SpeedArc/tools/build_hub.luau` builds the whole hub. Running it again on the same day replaces it; on another day it moves the old hub to ServerStorage as a dated backup first.

## Props v2 (28 Oct, "Modelling like a human artist" rule)
All 13 props remade in `Games/SpeedArc/blender/hub_kit_v2.py`, exported to `Downloads\speed_arc_models\hub\v2\` with the same names, sizes and pivots as v1 (checked: every bounding box within 0.005 studs). Previews (before / after, same 3/4 camera) in `SPEED ARC\Screenshots\models\`. See [[2026-10-28 SPEED ARC Progress - Hub props v2]].
When v2 is imported, the builder already puts the Neon glows into the new recesses (treadmill belt and screen, lamp head) and gives cones and fans a small random turn.

## Related
[[SPEED ARC - World, Map and Buildings]], [[SPEED ARC - Lighting]]
