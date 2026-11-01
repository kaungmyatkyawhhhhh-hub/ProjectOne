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

## The look the owner wants (2026-11-01): a Monaco showroom
**Reference photos** (a real luxury showroom in Monaco, sent by the owner), in `Games/CityLegends/imports/refs/dealership/`:
- `monaco_showroom_front.jpg` (front, big);
- `monaco_showroom/01_front_day.png`, `02_inside.png`, `03_front_wide.png`, `04_street_side.png`, `05_neighbour_shop.png`.

The owner also showed two more (couldn't be saved, described here):
- the **whole building**: a cream / ochre **Belle Époque stone building** with carved stone balconies, black wrought-iron railings, arched windows and ornate stone details. The showroom is its ground floor.
- the **street round the corner**: a covered car entrance with a dark canopy going down to a garage (white panel doors), wooden-slat planter boxes with palms and agaves, white stone cubes, recycling bins, a concrete road bridge passing overhead, tall modern apartment towers behind.

**Build ours like this, with our own name and no logo:**

**The building**
- A tall building with the showroom on the **ground floor**. Above it, a cream / ochre stone apartment block with carved balconies, black iron railings and arched windows (Belle Époque Riviera style). On the other sides, a modern apartment tower is fine.
- Over the showroom, a **curved light-grey concrete band** with **big raised gold serif letters "LEGENDS MOTORS"**, lit warm at night.
- Under it, a **black awning** with thin gold letters "LEGENDS MOTORS" and a gold line.
- A **wide floor-to-ceiling glass front** in thin dark frames, with a **supercar parked right behind the glass** (one of our best cars, changes now and then).
- A **light stone base** with metal vents below the windows, a glass door at the corner, and a small black panel with a TV screen in the window (shows our cars; no crest).

**Inside** (`02_inside.png`)
- **Floor:** light, shiny, speckled terrazzo / white epoxy.
- **Ceiling:** white, with **black linear light tracks running diagonally**, each full of small warm spotlights aimed at the cars.
- **Walls:** **warm wood slats** on the back walls, with **beige floor-length curtains** in places.
- **White square columns.**
- **Cars:** parked close together **at angles** (not in straight rows), noses out, mixed colours (a dark supercar, a gold sports car, red ones behind). Each car has a small black info stand (name, price, level).
- At the back: the sales counter where the buy menu opens, a small lounge (sofa, coffee machine; no alcohol), a glass office, and "LEGENDS MOTORS" in gold letters on the wall.
- **Calm and classy:** warm white and gold light only. **No neon** (owner's rule).

**The street round it**
- A **light stone-paved sidewalk** with darker stone borders.
- **Steel bollards** with red reflective bands.
- **White stone cubes**.
- **Wooden-slat planter boxes** with palms, agaves and grasses.
- A covered **ramp down to an underground garage** at the side (the "delivery" exit for bought cars).
- A **neighbour shop** with a coloured awning next door (like `05_neighbour_shop.png`: a pink-red awning café / bakery, our own fictional name).
- Tall apartment towers around, and ideally a concrete road bridge overhead.

**Never** copy their name ("Exclusive Cars Monaco"), crest, or any text.

### More photos (optional)
The cloud assistant could only get the front photo: google.com is blocked in its network, and a web search found no inside photos (the showroom is "Exclusive Cars Monaco", 1 Rue du Portier, Monaco). You have normal internet, so:
1. Open its Google Maps page, "Exclusive Cars Monaco" (search for it), and go to **Photos**, including inside and "By owner". Also try its Instagram / Facebook and its AutoScout24 dealer page.
2. Save **8–15 photos**: the inside (floor, ceiling lights, walls, car displays, desks, lounge, office), the front by day and night, and the entrance. Put them in `Games/CityLegends/imports/refs/dealership/monaco_showroom/`, small (1280 px or less). Commit and push.
   - If you can't open them, ask the owner to take screenshots from Google Maps (Windows key + Shift + S) and drop them there.
3. Write down what you see in a short list (floor material and colour, wall finish, ceiling and lights, how cars are lined up, the furniture, colours) and use it for the inside. **Our own name and no logo**: never copy their crest, name or text.

**If no inside photos can be found**, build the inside in the same calm luxury style as the front:
- a dark polished stone or grey epoxy floor;
- dark walls with warm wood panels;
- a black ceiling with rows of warm spotlights and track lights aimed at each car;
- cars lined up at an angle facing the glass, each with a small black info stand (name, price, level);
- a sales desk with leather chairs at the back;
- a small lounge (sofa, coffee machine, magazines; no alcohol);
- the counter where the buy menu opens;
- a glass office;
- "LEGENDS MOTORS" in gold letters on the back wall.

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
