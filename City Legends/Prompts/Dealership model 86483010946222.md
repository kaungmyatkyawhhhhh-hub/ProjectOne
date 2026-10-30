# Prompt: turn Creator Store dealership 86483010946222 into our Legends Motors

_For Claude Code on the PC, with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`)._

## The model
- **Creator Store ID `86483010946222`**: "[Free!] Car Dealership Tycoon! Cars Shop Rp Track", free, uploaded 12 Oct 2026 by Senuloma312, 0 votes.
- **Warning signs** (checked from the store page by the cloud assistant):
  - Its description is stuffed with unrelated tags ("Grow A Garden Brookhaven Rivals Arsenal...").
  - The title names the big game **Car Dealership Tycoon**, so it may be a **copy ripped from that game**.
  - It has signs and text, for example "HIGHLINE MOTORS".
- So:
  - treat it as **unsafe until cleaned**;
  - **change it a lot, not a little**: a ripped build that is only tweaked can still be reported, and can make our game look like a copy (the Playbook says copycat games get hidden from Home).
  - Keep only the general idea (a showroom with glass, a lot, a counter) and make the building clearly ours.

## Steps
1. **Test place only.**
   - Use the Studio named **"Dealer Test"** (not City Legends). Call `list_roblox_studios` and pick it by name. If it isn't open, ask the owner to open a new place and save it as `Dealer Test.rbxl`.
   - Insert model `86483010946222` there, while editing in Studio. The owner may need to click "Get Model" on the store page first.
   - Never make the game load it by ID while it runs.
2. **Clean it:**
   - Delete **every** Script, LocalScript and ModuleScript inside it (`LuaSourceContainer`).
   - Also check for anything odd: `require(` with numbers, hidden folders, parts named strangely, huge invisible parts, sounds and GUI with links. Report what you removed.
3. **Remove all branding:**
   - every logo, decal, texture or SurfaceGui with a brand, name or text, including **"HIGHLINE MOTORS"** and any car brand badges or flags;
   - signs get blank panels for now.
4. **Remove all the cars** in it (showroom and lot).
5. **Redesign it so it's ours** (more than "a bit"):
   - **Shape:** change the proportions (taller glass front, a different roof line, an overhanging canopy over the entrance, the showroom on a different side of the lot).
   - **Materials and colours:** our Legends Motors look (dark glass, brushed metal, light stone floor, warm lighting; no neon).
   - **Layout:**
     - the counter where the Midnight Racing-style menu opens (see `Dealership with trims like Midnight Racing.md`);
     - a central **turntable stage** with spotlights;
     - indoor display spots;
     - an outdoor lot with marked bays;
     - a customer entrance and a car exit door.
   - **New name:** **LEGENDS MOTORS** in our own lettering, on the front and the pylon sign. No logo picture (owner's rule).
   - Remove anything that would make someone recognise the original game's dealership.
6. **Put our cars in:**
   - Fill the showroom and lot with **our own cars** from `ReplicatedStorage.CarModels` / `Config.Dealership.Display` (fictional names).
   - Display models only (anchored, no scripts, no physics), each with a small stand sign: name + price.
   - Pick a good mix (budget at the lot front, top cars inside on the turntable).
7. **Performance:**
   - Report the part count (the original is big).
   - Merge or remove hidden detail.
   - Use LOD and streaming.
   - It must not lower FPS on a phone.
8. **Show the owner:**
   - screenshots from the street, inside the showroom, the turntable and the lot;
   - day and night;
   - next to a screenshot of the original model, so the owner can see it's clearly different.
9. **Only when the owner says OK:**
   - Move it into City Legends on the Legends Motors block, replacing the old building.
   - Keep the buy range / counter working (`Config.Dealership`).
   - Test buying in Play.
   - Save the place. Commit and push any code changes.
   - Write a note in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- what was removed (scripts, logos, cars);
- what changed in the design;
- screenshots;
- the part count;
- whether it's ready to move in.
