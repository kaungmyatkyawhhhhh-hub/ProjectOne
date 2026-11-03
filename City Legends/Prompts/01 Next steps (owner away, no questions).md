# Prompt: next steps, one by one (the owner is away: don't ask questions)

_For Claude Code with Roblox Studio connected (MCP) and Blender. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras._

## How to work (owner, 2026-11-03: "do these one by one and step by step ... I will be AFK, don't ask any questions")
- **Don't ask the owner anything.** When a choice is needed, pick the option that best fits the owner's rules and taste (realistic, Monaco look, fictional names, no logos, no neon, no alcohol, phones first), **write the choice and why** in `City Legends/City Legends.md` under a heading "Choices made while the owner was away (date)", and carry on. Keep choices easy to undo (Config values, backups).
- **One step at a time, in the order below.** Before each step, pull from git and check `City Legends/City Legends.md`: if a part is already done, check it quickly and skip it.
- **After every step:**
  - play-test (2 players, PC + phone size);
  - no console errors;
  - Lune tests and `luau-lsp analyze` clean;
  - FPS not worse;
  - **save the place (Ctrl+S / the place autosaves on Team Create), commit and push**;
  - note it in `City Legends/City Legends.md` with before / after screenshots.
- Back up before big changes (copies in `ServerStorage`).
- If the usage limit hits: finish the current change cleanly, save, push, and write "Next: step N" at the top of the owner-away notes, so the next session continues there.

## Step 1: fix what players notice right away (A)
1. `Fix buildings flashing black and white.md`: do it fully.
2. `Smooth roads.md`: do it fully (all 4 lanes of every road, sidewalks, kerbs, junctions tested, 0 problems).
3. Speedometer: the fixes are noted as done (no background, "Get out" moved). Just check them in Play.

## Step 2: driving feel (B): check only
`Realistic car physics.md` and the wind blur are noted as done. Drive a light hatch, a sedan, an SUV and a hypercar to check nothing is broken; fix only real bugs.

## Step 3: cars (C)
1. Class grades, car levels, the car removals and the new starters (`Car class grades and car levels.md`, `Remove 10 starter and mid cars.md`, `More fun starter cars.md`): noted as done. Check in Play: dealer, garage, classes, car levels, starter pick. Fix bugs only. (If the A45 S has no model yet, leave it unsold.)
2. **Better car models and interiors: SKIP for now** (owner: not now).
3. **Upgrade the dealer buy menu UI** (`DealerMenu.lua`; the layout from `Dealership with trims like Midnight Racing.md` stays: brands, models → trims, stats, trim card, BUY / TEST DRIVE, now with the class badge). The owner says it "looks vibe coded" (like a quick placeholder). Make it look **professional and realistic**, like a top racing game's showroom:
   - a proper visual style: one clean font family (bold display font for names and prices, a clear text font), consistent sizes and spacing, aligned columns, a real grid;
   - **no plain flat boxes or default-looking buttons**: designed panels (soft dark glass with blur behind, thin light borders, subtle gradients), real icons (drawn, not emoji or letters), smooth hover / select animations and sounds;
   - the car is the hero: big, well lit on a showroom stage (reflections, soft spotlights, a polished floor), with a slow camera orbit; the UI frames it instead of covering it;
   - clean stat bars with numbers, the class badge in its class colour, the price big and clear, locked / owned states clear;
   - consistent with the new main menu's style (step 6), phone-friendly (big touch targets, readable at 667 × 375).
   - Before / after screenshots (PC + phone).

## Step 4: world and venues (D): check what's left
- Legends Rewards (the casino replacement) is noted as done; check it.
- Venue remodel (`Remodel the venues.md`): Legends Motors and the hotel are done. **Do the rest one by one**: the bank, the 3 towers, Legends Customs, the Gem Showcase, Legends Realty, the chauffeur kiosks, the challenge gantries. As realistic as possible, using cleaned Toolbox models (no scripts, no logos, made our own). Keep every gameplay part working.
- `Make the Monaco map look real (from the drive video).md`, `Realistic graphics, lighting and buildings.md`, `Fix buildings that look off.md`: check what's done in the notes and finish what isn't.

## Step 5: houses (E): use very good Toolbox houses
The owner says Claude Code isn't good at building houses, so **use very high-quality houses, villas and mansions from the Toolbox / Creator Store** for the housing designs (`Housing like Driving Empire.md`):
- search for realistic, well-rated, good-looking modern houses, Mediterranean villas and luxury mansions (real textures and proportions; no cartoon / blocky ones); pick the best for each tier (Low, Mid, High);
- insert in Studio into a holding folder in `ServerStorage` first; **clean every one**: delete all scripts (watch for hidden scripts and fake "copy this command" popups), remove logos / brand names / real-brand cars, remove broken or invisible junk;
- make them work as our houses (`look.body` / `HouseBodies`, `HouseBuilder.wireBody`): doors, lights, TV, kitchen, bed, garage bays, the mailbox, gates, FOR SALE lots; fit them to the lots and the right tier;
- change them enough to be ours (colours, materials, small details); keep a credit list (name, ID, creator) in the notes;
- keep them light (merge parts, LOD, interiors stream in near the player). Screenshots of each house outside and inside.

## Step 6: a bigger map with a mountain highway and the marina parking
1. **Make the map bigger** with a **mountain-highway** style area (the hills above / beyond Riviera Bay): long roads through the mountains with **realistic curves** (sweeping bends, some hairpins, cliffs, tunnels and viaducts where it fits) **and also long straight stretches** for driving fast. Same road sizes and the smooth-road rules from `Smooth roads.md` (curved meshes, no bumps, all 4 lanes tested). Join it to the existing roads cleanly. Realistic scenery (rock, pines, guard rails, mountain views, distant sea).
2. **Traffic on those new mountain / highway roads: at most 10 cars in total** (a Config value), so players can drive fast. Traffic elsewhere stays as it is.
3. **Marina parking you can drive onto** (owner's example photo: `Games/CityLegends/imports/refs/map/marina_parking_supercars.png`, a quayside car park right next to the yachts in Monaco's harbour, with painted white bays and numbers on dark asphalt, supercars parked in a row, yachts' sterns and masts behind, the city and the mountain in the background):
   - a drivable quay car park along the harbour with marked bays (white lines and numbers), a smooth ramp / entrance from the harbour road, bollards and the harbour edge (a low kerb or rail so cars don't fall in);
   - space next to it for **yachts** (the owner will add yachts later: leave berths / water space beside the parking, and make it easy to place yacht models there);
   - good photo spots: the lighting and the view (yachts, harbour, city and mountain behind) should look great for screenshots and Photo Mode, day and night.
4. Update the lane graph, the minimap, fast travel, chauffeur places and races for the new roads. Performance: streaming and LOD; FPS not worse.

## Step 7: the main menu (F): make it look a million times better, and add HOUSES
1. The menu (`MainMenu.lua`, `Main menu (tile style).md`) "looks vibe coded". Make it look **professional and realistic**:
   - the same quality bar as the dealer menu in Step 3 (designed panels, one clean font family, aligned grid, real drawn icons, smooth animations and sounds, a live blurred game scene behind);
   - big readable tiles, clear states (selected, locked, new), consistent spacing; phone-friendly.
   - **Reference** (layout idea only, don't copy its look): `Games/CityLegends/imports/refs/ui/hud_side_buttons_example.png`: another game's HUD with a column of small square icon buttons on the left (map, shop, home, paint), a "Ready!" badge with a red notification dot, the cash in a pill at the bottom left with a "+" and a green "Claim Now! FREE" button. Use the idea (compact icon buttons with clear badges and a tidy cash pill) in our own style for the HUD buttons that open the menu pages.
2. **Top bar tabs: CAMPAIGN · CARS · HOUSES · STORE.** The new **HOUSES** tab shows your house(s): the placed house, owned blueprints, teleport home, place / change house, the house settings (access, roommates), and a button to Legends Realty (waypoint or fast travel). Reuse `HousingClient` / the server's house calls.
3. Screenshots of every tab (PC + phone), before / after.

## At the end
- Write a short summary at the top of the owner-away notes: what's done, what's left, the choices made, and anything the owner should check first.
