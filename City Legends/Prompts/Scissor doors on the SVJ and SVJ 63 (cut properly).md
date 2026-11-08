# Prompt: proper scissor doors on the SVJ and SVJ 63, cut from their own models (no holes), easy to revert

_For Claude Code on the PC, with Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`) and Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. **Do it properly: slow and careful. The owner will look at the result and may revert it, so make reverting one step.**_

## What the owner wants (2026-11-08)
Working **scissor doors** on the **Enfurecido LB834 ZVX** (`lambrini_svj`) and **ZVX 63** (`lambrini_svj63`), cut out of **their own models** (no door from another model: it wouldn't match), with **no holes**: when a door opens you see a painted door frame and a real door inside, never an empty shell.

The notes say both models have **no separate doors** (`City Legends/City Legends.md`, "Aventador SVJ and SVJ 63"). Start from the **converted** files the game uses now (the ones made by `paint_glb.py` / `auto_car.py`, with logos already removed), so nothing else changes.

## 0. Make reverting one step (do this first)
- **Backups:** copy both current car models in Studio to `ServerStorage/Backups/2026-11-08 SVJ before doors` and keep the current Blender / `.glb` / packed files next to them (e.g. `imports/backups/svj_before_doors/`).
- **A switch:** `Config.Doors = { lambrini_svj = true, lambrini_svj63 = true }`. If a car's switch is off, the game uses the **old model with no doors**, exactly as before. Write in the notes: "To revert: set `Config.Doors.lambrini_svj = false` (and `_svj63`), or put back the backup models."
- Do the whole job in **its own commits** (one per car) so `git revert` also works.

## 1. Cut the doors (Blender, one car at a time, the SVJ first)
1. **Find the real door lines.** The door's outline is the thin panel-gap line on the body: the front edge by the A-pillar / front wheel arch, the top along the window and roof, the back edge in front of the big side intake, the bottom along the sill. Follow the model's own gap lines (the darker shut-line faces). Look at real SVJ photos for the exact shape; the door includes the window glass and the front part of the side blade if the real door does.
2. **Cut along those lines** (knife / bisect along existing edges where possible, adding edges only where needed) and **separate** the door's faces into their own object, for each side: `Door_L`, `Door_R`. Include every layer the door has (outer paint, carbon pieces on it, the side glass, the mirror if it's on the door on the real car: on the SVJ the mirror is on the door).
3. **Fill the opening on the body: the door shut (jamb).**
   - The cut leaves an empty hole: extrude its edges **inwards about 6–8 cm** to make the frame's depth, then close it with the real surfaces: the A-pillar face (front), the B-pillar / intake face (back), the **sill** (the wide carbon step you climb over on an Aventador) and the roof edge (top).
   - Materials: the frame faces in **body paint** (they take Customs paint like the body), the sill in **carbon**, the rubber seals as a thin black strip round the opening.
   - No faces into the cabin may be missing: from outside with the door open you see the sill, the seat side, the dash end and the floor, all solid.
4. **Give the door a real body:**
   - extrude the door's cut edges inwards for **thickness** (about 6–10 cm), so the edges look like a real door edge (painted), never a paper-thin shell;
   - **the inner door panel:** use the cabin's own door card if the model has one (move it with the door); if not, model one in the car's real style: Alcantara / leather panel, a carbon strip, the door handle, the armrest pocket, a small speaker grille; no logos;
   - the side window stays with the door.
5. **Fix the cabin side:** if the cabin had no wall where the door card was (it relied on the door), check it from inside and outside; nothing see-through.
6. **The hinge (the pivot):** an Aventador's scissor door hinges at the **front, low on the A-pillar, near the top of the front wheel arch**, and swings **up and slightly forward**, to about **70–80°**. Put each door's origin exactly on that hinge point with the right axis (across the car, tilted a little as on the real car). Test the swing in Blender: at full open the door must not hit the body, roof, mirror or ground, and the front of the door must not go into the wing.
7. **Renders before / after** (the same cameras): side, front 3/4, rear 3/4, from above, the door **half open** and **fully open**, close-ups of the jamb, the sill, the door edge and the inner panel, from outside and from the driver's seat. Check: **no holes, no see-through, no grey, no gaps or overlap when closed** (the panel gaps look the same as before).
8. Repack with the normal pipeline (`cut_pieces.py` / `pack_cars.py`); keep unique texture names and every PBR map.

## 2. In the game (Studio)
- **Import the new packs yourself** (the owner gives permission); if you truly can't, leave them ready and write the steps at the top of the notes.
- Each door is its own MeshPart, jointed to the body (a `Motor6D` / weld with a CFrame around the hinge, or a `HingeConstraint`): smooth animation, about **0.7 s** to open, a slight ease, the right angle.
- **When they open:** getting in and out of the car (the door opens, the character climbs in, the door closes); a key / button to open and close while parked (free key, check the existing ones; plus a phone button); they close on driving off. Other players see them (synced like the lights).
- **Collisions off** on the doors while moving; no pushing the car or players; doors never open while driving fast.
- A soft door sound (from sounds already in the game or the Roblox library).
- Customs paint covers the doors and the frame; tail lights, clusters, the side lettering (ZVX) and everything else still work.

## 3. Then the SVJ 63
Repeat 1–2 for `lambrini_svj63` (it's a different model with its own livery: keep the stripes / numbers lining up across the door gaps).

## Check before you say done
- In Play (PC and phone 667 × 375), each car: open / close from outside and inside, get in and out, look from every angle (low, high, inside, at the jamb), day and night; another player sees the doors; no errors; FPS fine.
- One picture per car: before vs after, door open, close-ups of the jamb and inner panel.
- The revert test: switch `Config.Doors.lambrini_svj = false`: the car goes back to exactly the old model; switch it on again.
- Lune tests and `luau-lsp analyze` clean. Save the place, commit, push; note it in `City Legends/City Legends.md`, with **how to revert**.

## When done, tell the owner (short)
- the pictures (open / closed / close-ups);
- the key / button to open the doors;
- **how to revert** (the switch, or the backup models).
