---
date: 2026-11-01
tags: [research, modeling, blender, art, supernova, playbook]
---
# Modeling like a professional (stylized low poly for Roblox) - researched 1 Nov 2026

Owner: "we need to design the models like a professional modeler too" (Supernova Incremental kit; owner: "ur the artist", no AI-generated art).
Sources: SS3D art guide "Shape" (github RE-SS3D), BlenderArtists "tips for stylized low poly" thread, DevForum "Low-poly building style tips", + vault: [[Playbook notes - Top games art study (Oct 2026)]] (slop vs premium), [[Playbook notes - Optimization deep dive]], GYM ARC Blender pipeline ([[2026-10-27 GYM ARC Strongman Yard and Blender models]]).

## What pros do (cited)
- **Caricature, not copy**: exaggerate the defining features; models are caricatures of real objects (SS3D).
- **One shape language, "chunky"**: thick edges, big readable parts (SS3D). Avoid plain boxes: add an angle / a lip / a taper so nothing is just a box (DevForum).
- **Silhouette first**: things are seen from far; zoom out often, check from all angles, spend detail only where it changes the silhouette (SS3D).
- **Simplify detail**: just enough to read (a few bricks, not every brick); tiny detail = noise; enlarge important small details (SS3D).
- **Consistent density**: every model the same polygon density and the same side counts for round things (decide early, hard to fix later); smooth shading where round (SS3D).
- **Bevels on big hard surfaces** so edges catch light; skip on small parts (SS3D).
- **Reference views**: front / side / top references in Blender (BlenderArtists).
- **Start from primitives, shape with proportional editing**; radial arrays for repeated petals / spokes (BlenderArtists).
- **Colour**: smooth transitions, a soft gradient (lighter top) reads stylized and appealing (DevForum, BlenderArtists).
- Premium vs slop (vault): one focal point, crisp clean shapes, consistent style across every asset.

## Our pipeline (proven in GYM ARC, 27 Oct)
- Claude writes Blender Python scripts (Blender 5.2 on the owner's PC, run in the background) that build each model: 1 Blender unit = 1 stud, vertex colours (no textures = cheap, instancing-friendly), exported as .fbx + .blend + a preview render. Roblox scripts can't upload meshes, so the owner imports the .fbx (Studio 3D importer); Claude then swaps them in.
- GYM ARC result: city 3,143 -> 1,388 parts, 161 tubs etc.; whole game 10,852 parts -> 1,391 meshes.

## The Supernova kit style guide (decided)
1. Reference board: 10-20 screenshots (top Roblox simulators' props + real observatories / brass instruments / star charts).
2. Shape language: ROUND + BRASS for the built world (rings, domes, rivets, thick rims), SHARP + FACETED only for crystals and stars. Nothing is a plain box.
3. Proportions: chunky, about 1.3x thicker rims and handles than real; big readable parts.
4. Density: one budget per size (small prop <= 300 tris, medium <= 1,500, building <= 5,000); round things 16 sides small / 24 large; bevel big hard edges only.
5. Colour: 3 flat steps per material via vertex colour + a soft top-light gradient; palette = warm pale stone, brass/gold, deep indigo, crystal violet/cyan; no textures except the shared atlas.
6. Variation without new meshes: 2 versions of tiles / rocks, random turn and size, colour jitter +-5%.
7. Check every model in Roblox (not just Blender): at the game's camera distance, at night lighting, on a phone-size screen; silhouette test (all black: still recognisable?).
8. One at a time: blockout in Studio for scale -> Blender script -> preview render -> owner OK -> import -> place.
