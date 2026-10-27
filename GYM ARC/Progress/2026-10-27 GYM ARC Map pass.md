---
date: 2026-10-27
tags: [gymarc, progress]
status: done
---
# Map pass (prompt 74)

Back to [[00 GYM ARC Home|GYM ARC Home]]. Prompt: [[2026-10-27 GYM ARC Prompt - 74 Map]].

All done in Studio Edit (each step one Ctrl+Z step). Scans ran over the whole town and the gyms.

## Holes
- Rays every 2 studs over the whole playable area (also through roofs to the lowest floor): no hole anywhere a player can walk. The only empty spot is the cliff strip east of the Pro gym (x 160-200, z -98..-11): the valley-city view, walled in by the Pro gym, the tree line and the boundary, so nobody can get in.

## Floating props (fixed)
- Pendant lamps in the Powerlifting gym (1.0-1.6 studs under the ceiling / purlins) and the Pro gym makeover (0.4 short): 59 rods lengthened to the ceiling.
- Corner / wall speakers in the Starter gym (4) and Pro gym (3): their brackets stretched to the wall or corner (they hung 1.5-2.4 studs off it).
- Lifeguard tower ladders (2): the rungs had no side rails: rails added from the sand to the deck.
- Beach night lamps (2, at x 5.65 and 33.75, z 238.35): the lamps had been moved, two frame bars each were left floating over the sea at z 257: moved onto their lanterns (4 bars each now).
- A doubled string-light bulb on the plaza removed.

## Overlapping parts (owner: "also fix every overlapping parts")
- Coplanar faces of different colour / material that a player can see (z-fighting flicker): 522 pairs found, fixed by making the smaller part 0.03 studs thicker toward the visible side (its face in front, its back where it was), repeated until none were left (5 passes, 542 faces). Hidden ones (bottoms on a floor, faces buried in walls) left alone.
- Note: a first attempt had a bug in the same-plane test (it compared a face with itself) and resized many parts that weren't flickering; it was undone with Ctrl+Z (checked: planter box 1.4, soil 0.1, curb 0.7 back to their sizes) before the real pass.
- Exact duplicates: 7; the push-up handle on the parallettes is the invisible station on purpose (kept).

## Blank walls (fixed)
- Green building beside the Pro gym (side facing the gym-front street): painted mural, kettlebell + TRAIN. EAT. GROW. (white paint, like the alley mural), raised clear of the topiary.
- Beige building at the west end (beside the Powerlifting gym): painted dumbbell + ONE MORE REP. (dark paint).
- Posing stage backdrop's back (a plain grey frame facing the beach): graphite panel, gold POSING SHOW, STRIKE A POSE · WIN THE CROWD, STAGE ON THE OTHER SIDE (SurfaceGui on BackdropFrame).
- Town leaderboard stand's back: the caption was half hidden by the middle post: now GYM ARC | LEADERBOARDS either side of it, plus TOP 10 (BIGGEST · STRONGEST · TALLEST) and MAKE THE BOARD (TRAIN, GROW, POSE AND WIN) panels between the posts.
- Checked and fine: Pro gym back wall (mirror, mural, panels), Powerlifting record board and facade sign, Pump Shop, clothing store back, the gym alley (mural + windows, leads to the Strongman Yard).
- New parts live in `Town.Murals` (two invisible sheets with SurfaceGuis).

## Worth walking to: the edges
- The town's invisible boundary walls had nothing visible in front of them: the streets ran straight into open hills and an invisible wall, the beach into the sea. Now every edge a player can reach shows where the town ends (`Town.EdgeMarkers`): a low wooden post-and-rope fence on grass and sand (185 posts), red and white striped barriers where a road meets the edge (22 boards), and a red / white buoy line in the sea (135 buoys). All anchored, no collision (the boundary still stops players).

## Strongman Yard light pole (owner: "the lightpole is directly in front of the strongman yard entrance (from the alley)")
- The pole just inside the yard gate is part of one imported mesh (`StrongmanYard.Look.LightTower.Remodel_mtown275`) together with the bleachers' frame, a bench and the north light tower, so it can't be moved alone (splitting the mesh would upload new assets). The whole set (that mesh, the bleachers, the gate light's lens and that tower's lenses) moved 11 studs west: from the alley the gate is clear, the pole now stands behind the gym's corner. One Ctrl+Z step ("Yard: light pole out of the gate").
- Side effect: the orange container's ribbed side (behind where the bleachers stood) is now in view; its last ribs stick out at an angle.
- **Undone (owner: "now the light pole is good and other things in that same model are ruined"):** the mesh also holds the orange container's 18 ribs, the bleachers' frame, two benches, posts and the north light tower (125 pieces, read with EditableMesh), so moving it pulled those off their places. Everything is back exactly where it was (one Ctrl+Z step "Yard: light tower set back").
- **The real fix (owner imported it, 28 Oct):** `Downloads\gym_arc_models\yard_props\YardProps_NoPole.glb` = the same mesh (same size, same 8 vertex colours) without the pole and its lamp head (24 of 1,500 triangles), rebuilt from the mesh data (scratchpad script yard_glb.py). Once imported, it replaces `Look.LightTower.Remodel_mtown275` at the same CFrame and size (the old one kept in ServerStorage), and the gate floodlight's lens (`StrongmanYard.FloodLens` at -56.4, -104.2) goes with the pole.
- **Installed (owner imported it, mesh 122193020658233):** `Look.LightTower.Remodel_mtown275` is now the pole-free mesh at the old CFrame and size, turned 180 degrees about Y (the 3D importer flipped X and Z; checked against the old mesh's orange vertices: same spot after the turn). Same look as before (container ribs, bleacher frame, benches, tower) with no pole; the gate is clear from the alley. Backups in `ServerStorage.YardPropsBackup` (the old mesh with the pole, and the gate floodlight lens `FloodLens_GatePole`).
