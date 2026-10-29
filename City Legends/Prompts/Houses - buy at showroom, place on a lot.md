# Prompt: High tier spread out, smooth roads, gate, and buy-then-place houses

_For Claude Code on the PC, with Roblox Studio connected (MCP). This **replaces** the house-buying parts of `One big island and real estate.md` (Parts 2 and 3) and adds to `Realistic houses.md`. Owner: talk short and simple (caveman mode, see `Preferences.md`)._

## Before you start
- Read:
  - `CLAUDE.md`;
  - `Roblox Playbook/Roblox Playbook - Rules for every game.md`;
  - `Games/CityLegends/CLAUDE.md`;
  - `City Legends/City Legends.md`.
- Call `list_roblox_studios` and use the Studio named **City Legends** only.
- **The map is baked.** Never `rojo build` over `CityLegends.rbxl`. Save a backup copy first (`CityLegends_before_lots.rbxl`).
- Rules:
  - fictional names, no logos;
  - the server checks all money;
  - filter any player-typed text.
- **Reference photo:** `Games/CityLegends/imports/refs/houses/high_tier_hilltop.webp`. A big white mansion alone on a hilltop:
  - its own curved private driveway up to it;
  - a wrap-around porch;
  - gardens on the slope;
  - forest all round;
  - another house far away on a different spot;
  - a view over the valley.
  The High tier should feel like this.

## 1. High tier: spread out on the mountain top, not in a row
- Remove the High tier plots lined up along the summit ring road.
- Make about **8–10 High tier lots spread over the top of the mountain**, each on its own spot: different heights, facing different views (sea, Downtown, valley).
- **Each lot gets:**
  - its own **private driveway** that curves off the summit road (like the photo);
  - a flat pad for the house;
  - a garden slope;
  - trees between lots, so you can't see the next house up close.
- Lots are far enough apart that each feels private: about 150+ studs between houses.
- Mid and Low lots can stay along their roads, but don't line them up perfectly either: vary the gaps, angles and setbacks a little so it looks like a real neighbourhood.

## 2. Smooth roads
- The roads currently show visible **studs and steps** between pieces, and the **lane lines don't match up** at the joins. Fix all island roads (ring road, mountain switchbacks, summit road, side streets, driveways):
  - one smooth surface with no steps, gaps or overlapping bumps at the joins;
  - use smooth material (no stud texture);
  - build curves from enough short pieces, or wedges / meshes, so the edge is smooth;
  - lane lines and kerbs line up across every join, with an even width and the same style as the city;
  - slopes change gradually, no sudden kinks, so cars don't bounce.
- Check:
  - drive the whole island in Studio at low and high speed: no bumps or jumps at joins;
  - `bake_check` passes: road under every lane, nothing in the lanes;
  - `graph_test` passes.

## 3. Gate at the High tier entrance
- At the start of the summit road, build a **proper gated entrance**:
  - stone pillars and walls;
  - a sliding or swinging metal gate (no logos, just the area name, for example "THE SUMMIT", in plain lettering);
  - a guard house with a light;
  - police guards (friendly NPC officers);
  - cameras on poles.
- **The gate opens** (animated, with a sound) for:
  - players who own a High tier house;
  - anyone riding in their car (passenger or chauffeur).
  It closes behind them.
- **Everyone else:** a guard message "Residents only", and the gate stays shut. Add a small barrier so cars can't squeeze past, and walls along the sides so nobody drives round it.
- Wanted players are refused even if they're owners, and police chases can't follow through.

## 4. Buying: choose at the showroom, then place it on a FOR SALE lot
**No houses are pre-placed on lots any more.** All lots start empty with a **FOR SALE** sign.

### The real estate showroom ("Legends Realty")
- A walk-in showroom in Downtown near the causeway, plus a small booth at the bottom of the mountain:
  - an agent NPC at the desk;
  - big screens;
  - a scale model of the island.
- Press E at the desk to open the **house catalogue** with **at least 30 houses**:
  - tabs: Low / Mid / High;
  - filters: stories, garage size, price;
  - each card shows a picture or 3D preview, name, stories, bedrooms, garage bays and price.
- **Prices go from $150,000 to $100,000,000.** Suggested spread (show the owner the full list before building):

| Tier | Houses | Sizes | Prices |
|---|---|---|---|
| Low | 12 | 1-story cottages and bungalows, small 2-story family houses, a beach shack, townhouses | **$150K** (the smallest) to about $2.5M |
| Mid | 10 | 2–3 story modern houses, a Spanish villa, a glass house, a cliff house, a lake-view lodge | about $3M – $15M |
| High | 8+ | big mansions, a hilltop estate like the reference photo, a Miami white mansion, a mega-mansion with an infinity pool and helipad | about $20M to **$100M** (the biggest house in the game) |

- **TOUR:** walk through an empty show copy of the house before buying.
- **BUY** (with a confirm step) puts the house in your **owned houses**. It isn't placed yet.

### Placing the house
1. After buying, a button says **"Choose your lot"**. The map / camera shows the free **FOR SALE** lots **of that house's tier**:
   - Low tier: only the low lots near the bridge;
   - Mid tier: only the middle terrace lots;
   - High tier: only the summit lots behind the gate.
2. The player can also drive or walk to any FOR SALE sign of the right tier and press E: "Place my house here".
3. Show a **ghost preview** of the house on the lot first, so they can see how it fits. Then confirm.
4. The house builds on the lot, the FOR SALE sign is replaced by a name plaque with the owner's name, and the garage setup works as before.
5. **A small gate for each home:** every lot gets its own small driveway gate (Low: a simple wooden or metal swing gate; Mid: a modern sliding gate with a low wall; High: a big iron or stone-pillar gate at the bottom of the private driveway, inside the Summit). Each house gate:
   - opens automatically (animated, with a sound) for the owner, their passengers, and visitors the owner allows (Open / Friends only / Locked, see the extras);
   - stays closed for others, with a doorbell / intercom on the gate post;
   - has the house number and the owner's name plaque on the post;
   - shows a FOR SALE sign on the gate while the lot is empty;
   - takes the colour chosen in the house upgrades;
   - lets nobody drive round it: a fence or hedge along the lot edge.
6. **Moving:** the owner can move their house to another free lot of the same tier (from the house menu or a FOR SALE sign). The old lot goes back to FOR SALE.

### Saving and servers
- Saved per player:
  - the houses they own (design ids);
  - their favourite lot per house.
- Lots belong to the **server**. On joining:
  - if your favourite lot is free, your house goes back there automatically;
  - if not, you get the "Choose your lot" button.
- When a player leaves, their house is removed and the lot goes back to FOR SALE.
- A player can own several houses (one per tier at a time, so up to 3 placed, or more if the owner wants).
- **Selling:** sell back for 70% of the price at the showroom. The server checks everything.
- **Old saves:**
  - old villa owners get a Mid house of equal value;
  - old mansion owners get a High house;
  - nobody loses money.
  - `UnlockEverything` owns every design.

## 5. Extra ideas to make it better (do after 1–4; show the owner first, skip any they say no to)
1. **Housewarming:** the first time you place a house, a short camera fly-in to it, confetti, and a one-time gift (5% of the price back, capped at $250K).
2. **Upgrades per house**, bought at the house:
   - bigger garage (+2 bays);
   - pool or infinity pool;
   - helipad (High only);
   - solar roof;
   - garden lights;
   - wall and paint colours;
   - gate colour.
   Each upgrade shows on the house and is saved.
3. **Furniture shop in the showroom:** a few interior themes per house (Modern White, Warm Wood, Dark Luxury, Beach). One click restyles the inside, with no fiddly placing.
4. **Doorbell and visits:**
   - anyone can ring;
   - the owner sets the house to Open / Friends only / Locked;
   - visitors can see the garage cars.
   - No party mode in houses: the DJ booth stays in penthouses only.
5. **Daily mailbox:** a small daily cash gift at your house's mailbox, bigger for higher tiers. This gives players a reason to come home on day 2, 7 and 20 (Playbook).
6. **"Set as home":** spawn at your house when you join.
7. **Estate leaderboard** at the showroom: the most valuable homes in the server (house + upgrades), with the owner's name.
8. **Show homes:** each tier has one show house always open to visit, so new players see what they can earn.
9. **Lot perks:** a few special lots are worth more and cost a lot fee to claim (cliff edge, ocean view, next to the lookout), so players compete for the best spots in a server.
10. **Security:** owners get a CCTV screen in the house showing the driveway, and a ding when someone rings.
11. **Tier perks** that feel worth it:
    - High owners get through the gate;
    - the summit helipad (helicopter tour);
    - a private lookout;
    - their name on the gate's resident board.
12. **House income:** a small "rental" income while you're in the game (like the hotel suites), more for bigger houses, paid into a house safe you collect at home.
13. **House value goes up:** each house slowly gains value the longer you own it (up to +20%), so selling later pays a little more. Upgrades add to the value.
14. **Car lift and turntable** in High tier garages: one car on a spinning display, the rest on lifts. Press E to drive any out.
15. **Driveway car show:** park up to 2 cars in your driveway to show off. Others see them when driving past.
16. **Weekly open-house event:** for one hour each week, all houses can be visited, and players vote for the best house. The winner gets a trophy at their house plus cash.
17. **Neighbour quests from the agent:**
    - "Tour 3 Mid houses";
    - "Drive to the summit lookout";
    - "Buy your first house".
    Small rewards that guide new players to the houses.
18. **Starter goal for new players:** the $150K cottage is the first big money goal, shown on the HUD ("Save for your first home: $43K / $150K").
19. **Moving truck:** when you place or move a house, a moving truck drives up to the lot and the house builds piece by piece (short, skippable).
20. **Night look:** each house has warm interior lights, garden lights and lit pools at night. High tier mansions glow on the mountain top, seen from Downtown.
21. **Weather on the island:** fog rolls over the summit in the early morning, and rain makes the driveways shiny.
22. **Pets** (cosmetic): a dog or cat that wanders your garden and greets you at the door.
23. **Photo spot:** a "Take house photo" button that sets up a nice camera angle of your house with your best car in front. Players share these, which brings new players.
24. **Mountain life:** deer near the forest roads, birds, a lookout bench, a hiking path to the top for on-foot players, and a picnic spot.
25. **Real estate badges:**
    - First Home;
    - Mid-Life (first Mid house);
    - Summit Club (first High house);
    - Tycoon (own all 3 tiers).
26. **Helicopter to the summit:** High owners can call the helicopter from the showroom roof to fly to their mansion (a short cutscene, skippable).

## 6. Check before you say done
- 2-player test in Studio (also: B can't get through A's house gate unless A allows it):
  - player A buys a Low house and places it;
  - player B can't place on that lot;
  - B's High house can't be placed on a Low lot;
  - A leaves and the lot frees;
  - A rejoins and the house comes back on the favourite lot.
- The gate opens only for High owners and their passengers.
- Driving all island roads is smooth.
- No console errors. FPS and part counts are reported.
- Screenshots:
  - the High tier from the air (spread out, like the photo);
  - the gate;
  - the showroom catalogue;
  - the ghost preview;
  - a placed house with its plaque;
  - phone size (667x375).
- Every Lune test passes. `luau-lsp analyze` is clean.
- Write the changes into `City Legends/City Legends.md` and `Games/CityLegends/CLAUDE.md`. Commit, push and save the place.

## When done, tell the owner (short)
- the list of 30+ houses with prices;
- how buying and placing works;
- where the gate is;
- what's untested.
