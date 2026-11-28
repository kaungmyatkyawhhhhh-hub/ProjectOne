---
tags: [gym-arc, christmas-update, art, 3d-model]
date: 2026-11-28
---
# Mega Gift Lift rig frame (roblox-3d-model-from-sheet)

Replaces the Part-built frame of `Xmas.Yard.LiftRig` (~136 parts: posts, beams, pad, bulbs, sign, Finish). PREP ONLY: not uploaded or swapped yet (Studio on hold).

## Sheet (ChatGPT chat "Create Rig Design Sheet")
`sheet.png`: FRONT, SIDE, TOP, EXPLODED (pad, hazard border, corner post, top beam, bulb, pulley, sign). The LiftRig screenshot was attached.

## Build
`build_liftrig.py` (headless). Unit = pad width. Charcoal pad, diagonal yellow/black hazard border, 4 square candy-striped posts (bands between parallel slanted planes, so the stripes wrap round the corners), black feet, red caps with gold studs, gold perimeter beams + inner bulb rail + centre cross, 2 rows of marquee bulbs, pulley block with a gold wheel, red sign in a gold frame on the front beam.
- 7 MeshParts: Pad 12, Hazard 336, Black 380, Red 300, White 232, Gold 264, Bulbs 1200 = **2,724 tris**.
- Gates: TOP IoU **0.966** (pass). The FRONT view scores 0.58 because the sheet draws it in perspective (back posts and the pad's top face show); TOP is the only true ortho view, so it is the gate.
- No cable: MegaLiftService resizes the rig's own `Cable` part between `CableTop` and Present.Lid.

## Swap plan (after "go")
Keep `rig.Pad` (MegaLiftClient uses Pad.Position for the ground wave; name the Pad MeshPart `Pad`), `rig.Cable`, `rig.Present`, the GiantCanes and every rig attribute (RiseHeight, CableTop). Fit the mesh to the old frame's posts/pad bounding box; check the pulley sits at CableTop.

Swapped 28 Nov: Model **79991385849553**; Pad + Posts kept invisible (collision / MegaLift), SignBoard invisible with its SurfaceGui in front of the mesh sign. Rig moved to (-14,-172).
