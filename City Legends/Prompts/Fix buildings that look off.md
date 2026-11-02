# Prompt: the buildings look off and not realistic, find out why and fix them

_For Claude Code with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). This goes with `Realistic graphics, lighting and buildings.md` (Part 3) and `Make the Monaco map look real (from the drive video).md`. Where they overlap, this file is the to-do list for the buildings._

## Before you start
- Read:
  - `CLAUDE.md`;
  - `Roblox Playbook/Roblox Playbook - Rules for every game.md`;
  - `Games/CityLegends/CLAUDE.md`;
  - `City Legends/City Legends.md`;
  - the two prompts above.
- Call `list_roblox_studios` and use the Studio named **City Legends** only.
  - The place is on Team Create: no `rojo build` over it.
  - Save a backup copy first.
- **Reference:** the owner's Monaco videos in `Games/CityLegends/imports/` (`mornign.mp4` day, `videoplayback (1).mp4` night, `cars.mp4` casino square). Pull frames with ffmpeg and keep them open while you work. Real buildings are the measuring stick.

## Step 1: find out exactly what looks wrong (do this before changing anything)
1. Take screenshots of the city from where players actually are:
   - **street level while driving** (first-person and chase cam);
   - on foot on a sidewalk;
   - from a hill looking over the city;
   - at noon and at night;
   - on PC and at phone size.
2. Put each one **next to a real frame from the videos** of a similar street.
3. Go through this checklist and **write down every problem you find** (these are the usual reasons Roblox buildings look fake):
   - **Flat boxes:** windows painted on or flush with the wall, no depth, no frames or sills.
   - **Wrong scale:** floors too tall or too short, windows too big or small, doors not human-sized, buildings too short for the street width. Real: about **3 m per floor** (about 9 studs at our 3 studs = 1 m), doors about 2.1 m, window about 1.2 × 1.6 m.
   - **Copy-paste:** the same building repeated, same colour, same height, in a row.
   - **Plastic look:** `SmoothPlastic` / `Plastic` walls, plain flat colours, no texture, no wear.
   - **Too clean and sharp:** no cornices, no roof edge, no base, no dirt or weathering, perfectly square everything.
   - **Dead ground floor:** no shops, doors, awnings, signs or lights at street level.
   - **Empty roofs:** flat grey tops, with nothing on them.
   - **Windows at night:** all lit, all dark, or all the same colour; or see-through to nothing.
   - **Gaps and floating:** buildings floating above or sunk into the ground, gaps between neighbours, sidewalks not meeting walls, z-fighting (flickering faces).
   - **Wrong colours for Monaco:** too grey or saturated, missing the cream / ochre / peach / salmon walls and terracotta roofs.
   - **Lighting on them:** no shadows, flat light, no ambient occlusion feel, glowing too much at night.
   - **LOD pop-in:** buildings switching detail or appearing too close to the camera.
4. **Show the owner the list** with screenshot pairs (ours vs. real) and rank the problems: worst first. Wait for the OK, or for the owner's own notes ("this one looks worst").

## Step 2: fix them, worst first
For each problem, the fix:
- **Depth:**
  - recess every window about 0.3–0.5 studs into the wall, with a frame, sill and top lintel;
  - balconies stick out with slab edges and real railings (wrought iron or glass);
  - add a cornice / roof band and a stone base.
- **Scale:** rebuild to real sizes (floors about 9 studs, doors about 6.3 studs, windows about 3.6 × 4.8 studs), and match building heights to the street (Monaco streets have 5–15+ floors on each side).
- **Variety:** use kits per style (Belle Époque, 1970s balcony towers, glass towers, hillside villas, grand hotel / casino), with random height, colour tint, balcony type, shutters, shop and roof per building. No two neighbours the same.
- **Materials:**
  - `MaterialVariant`s for stucco / plaster, stone, concrete, roof tile, metal and glass (512 px or smaller);
  - small colour shifts per building;
  - a darker dirt band at the bottom and stains under windows and balconies.
- **Ground floor:** shopfronts with big glass, frames, awnings (varied colours), fictional signs, doors, lights inside, and café tables in some places.
- **Roofs:** AC units, water tanks, antennas, terraces with plants and umbrellas, terracotta tiles on old buildings.
- **Windows:**
  - shutters, blinds and curtains (some open, some closed);
  - a simple room behind the glass (a dark box with a lamp, or an interior picture);
  - at night, 30–50% lit, warm yellow mostly, a few cool white or TV blue.
- **Fit:** snap every building to the ground and sidewalk, close gaps, remove overlaps and z-fighting.
- **Colour:** the Monaco palette (cream, ochre, honey, peach, salmon, pink walls; terracotta roofs; dark green or grey shutters; black iron).
- **LOD:** push full detail out to about 300 studs. Far versions keep the right outline and colour (a front texture), so the skyline still looks right.
- **Build detail as reused MeshParts** (frames, railings, cornices, balusters), so detail stays cheap. Aim for under about 300–800 parts per building.

## Step 3: check and hand over
1. Redo the **same screenshots from Step 1** (same spots, same times) and put them **before / after / real video frame** side by side.
2. Measure FPS, memory and part count before and after (PC + phone size). **It must not run worse on Medium.**
3. Fix one district fully first (the harbour), show the owner, then roll out to the rest.
4. Save the place. Commit and push code changes. Write what changed in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- the top problems you found;
- what you fixed;
- before / after screenshots;
- FPS before and after;
- what's left.
