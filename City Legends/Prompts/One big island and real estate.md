# Prompt: one big mountain island, house tiers and a real estate office

_For Claude Code on the PC, with Roblox Studio connected (MCP). Read all of this first, then do it in parts. Owner: talk short and simple (caveman mode, see `Preferences.md`)._

## Before you start
- Read `CLAUDE.md`, `Games/CityLegends/CLAUDE.md` and `City Legends/City Legends.md`. Pay attention to "Map baked into the place" and "Map ownership".
- **The map is baked.** `CityLegends.rbxl` is the master. Never `rojo build` over it. The owner asked for this map change, so you may edit the baked `Workspace.City` in the open Studio place.
- **Back up first.** In Studio, save a copy as `CityLegends_before_island.rbxl` before touching the map. Never save over `CityLegendsCars.rbxl`.
- Rules:
  - Fictional names only. No logos or brand emblems.
  - No alcohol. No clubs or party mode in houses: the DJ booth / party mode stays in penthouses only.
  - Don't auto-load Creator Store / Toolbox models from scripts (see "House models").
- Work one part at a time. After each part:
  1. Play-test in Studio.
  2. Take screenshots and show the owner.
  3. Run the Lune tests and `luau-lsp analyze`.
  4. Commit and push to `master`.
  5. Save the place.

## What exists now
- Three islands in `Config.West.Islands`: Legends Key (r 440, middle, end of the causeway), Palm Isle (north) and Coral Cay (south). Bridges join them (2+2 lanes).
- Layout code:
  - island shapes and plots: `WestLayout.lua` (`housePlots`, `IslandBridges`);
  - the build: `West.lua`.
- Houses: `Houses.lua` and `Config.Houses`. There are 2 types: villa ($4M, 4 bays, tier 1) and mansion ($15M, 6 bays, tier 2).
  - You buy a **type**, and in each server you get a free plot of that type.
  - The ground floor is a glass car gallery with a "Garage setup" button.
- Other places that read the islands: the chauffeur, the minimap, the map labels (`WestLayout.places`), `bake_check.luau`, `world_test.luau` and `graph_test.luau` (traffic graph).

## Part 1: one big island
Replace the three islands with **one big island**, about the area of all three plus room for a mountain (around 1,800–2,400 studs across; pick what fits the sea and the camera's far distance).
- **Keep:**
  - the causeway from Ocean Drive, landing on the island's east side;
  - the 2+2 lane road style.
  - Remove the two island bridges.
- **A mountain in the middle,** about 250–400 studs high, with rock faces, pine and palm trees, and cliffs facing the sea. The view from the top should look back over the bay to Downtown.
- **Beach** all round, or at least on the west and south sides: sand, palms, a pier, lifeguard towers and a few beach huts. The sea floor drops off gently.
- **Real roads, no grass roads:**
  - a ring road round the bottom;
  - a road that winds up the mountain in switchbacks, with guard rails, street lamps and the same road surface, kerbs and lane lines as the city;
  - side streets into each neighbourhood.
- **Traffic:** every new road joins the traffic graph, and `graph_test` passes (no dead ends, no gaps, turns stay level). Keep slopes drivable for all cars: no steeper than about 12%. Check that a heavy SUV and a low supercar both climb it.
- **Three neighbourhoods by height:**
  - **Low tier:** at the bottom, nearest the causeway / bridge end. Street houses on normal lots, with sidewalks, mailboxes and street trees.
  - **Mid tier:** halfway up the mountain, on terraces. Bigger lots and sea views.
  - **High tier:** the top of the mountain. A **gated community**:
    - one entrance gate with a guard house and **police guards** (friendly NPC officers, standing and patrolling);
    - a barrier that opens only for players who own a High tier house, or who are riding with one (chauffeur or passenger);
    - wanted players are refused at the gate, and police chases can't follow you in;
    - inside: big lots, hedges, private driveways and a lookout over the city.
- Move the helipad and fountain from Legends Key onto the new island (the helipad goes inside the gated community).
- Fix everything that pointed at the old islands: chauffeur destinations, map labels, minimap, `Config.West.Islands`, `housePlots`, `bake_check`, `world_test`, `graph_test`.
- In the baked map, delete the old islands' parts (roads, lawns, sand, trees, houses preview) and put the new island in `Workspace.City`, the same way as the rest of the bake. Run `tools/bake_check.luau` afterwards: road under every lane, nothing in the lanes.

## Part 2: houses in tiers (at least 25 designs)
- **Make at least 25 house designs and list them by tier.** Suggested split and prices (show the owner the list before building; they can change prices):

| Tier | Designs | Size | Price range | Garage bays |
|---|---|---|---|---|
| Low | 9 | 1-story bungalows, small 2-story family houses, a beach shack, a townhouse | $500K – $2.5M | 1–2 |
| Mid | 9 | 2-story and 3-story modern houses, a Spanish villa, a glass cube house, a cliff house | $3M – $10M | 3–4 |
| High | 7 or more | big modern mansions, a Miami white mansion, a mega-mansion with an infinity pool, a hilltop castle-style estate | $15M – $60M | 6–10 |

- **Each design gets:**
  - a name (fictional);
  - stories (1, 2, 3, 4+);
  - bedrooms;
  - a garage size;
  - a price;
  - a tier;
  - a look you can tell apart: roof shape, colours, materials, balconies, pool, glass.
- **Every house can be walked into:** a door that opens, ground floor rooms, stairs to the upper floors, simple furniture and lights at night. Keep each house light, under about 600 parts, so the island doesn't lag. Use `LOD` tags like the rest of the map.
- Every house keeps the **car garage showcase** (Garage setup, drive out a car) that villas and mansions already have.
- **House models:** build the designs yourself in code or in Studio. Optionally, the owner may also want Creator Store houses:
  - list good **search words** for the Toolbox and let the owner insert them by hand;
  - then strip every Script / LocalScript / ModuleScript out of those models before using them (free models often hide bad scripts);
  - never load models by ID from a script.
- **Plots:** lay out lots in each neighbourhood so every design can appear. Same idea as now: you buy a design, and in each server you get a free lot of that tier, the same lot as last time if it's free.
- **Save data:**
  - players who own the old **villa** keep a Mid tier house of the same value;
  - players who own the old **mansion** keep a High tier house;
  - nobody loses money or a house.
  - `UnlockEverything` gives all designs.

## Part 3: real estate office
A walk-in **real estate office**, "Legends Realty" (fictional), in Downtown near the causeway. Also a small booth on the island at the bottom of the mountain.
- Inside:
  - a front desk with an agent NPC;
  - screens with house photos;
  - a big table model of the island showing the three tiers.
- Press E at the desk to open the **house catalogue**:
  - tabs for Low / Mid / High;
  - filters: stories, garage size, price;
  - each card shows a picture or 3D preview, name, stories, bedrooms, bays, price and tier, plus which lots are free in this server.
- **Visit before buying:** a TOUR button teleports you (or drives you with the chauffeur) to an empty show house of that design, and lets you walk in for 2 minutes.
- **Buy, upgrade and sell:**
  - Buy with a confirm step.
  - You can own one house per tier, so up to 3 houses.
  - Sell back for 70% of the price.
  - Move up a tier by trading in.
  - The server checks all money. Never trust the client.
- Add Legends Realty to the minimap and the chauffeur's places.

## Part 4: extras that make it better (do these after Parts 1–3; skip any the owner says no to)
1. **Mountain hill-climb challenge:** a timed run from the bottom of the switchbacks to the gate, on the challenge leaderboard.
2. **Scenic lookout** at the top with a photo spot and telescopes looking at Downtown.
3. **Marina** on the low-tier side: a dock with boats as scenery, and a waterfront walk.
4. **Lighthouse** on a cliff with a turning light at night.
5. **House doorbell and visits:**
   - anyone can ring;
   - the owner can set the house to Open, Friends only or Locked;
   - a name plaque by the gate.
6. **House customise:** pick wall colour, pool on / off and lights colour at the house (server saved).
7. **Daily mailbox:** a small daily cash gift at your house's mailbox (bigger for higher tiers). This gives players a reason to come home.
8. **Home spawn:** "Set as home" on a house, the same as penthouses.
9. **Gate life:** guards wave owners in, the barrier lifts, and a short camera shot plays the first time you enter.
10. **Night lights:** warm windows, garden lamps and the mountain road lit up, so the island looks great from Downtown at night.

## Checks before you say done
- Every Lune test passes. `luau-lsp analyze` is clean.
- `bake_check` passes on the new island.
- All cars can drive up the mountain road.
- The traffic AI drives the island without getting stuck.
- The gate opens only for the right players.
- Old villa and mansion owners still have a house.
- Part count: say how many parts the island adds. Keep the whole map near what it was (about 150,000).
- Write the changes into `City Legends/City Legends.md` and `Games/CityLegends/CLAUDE.md`. Commit, push and save the place.

## When done, tell the owner (short)
- what's new;
- where to go to see it;
- prices of each tier;
- what's still untested.
