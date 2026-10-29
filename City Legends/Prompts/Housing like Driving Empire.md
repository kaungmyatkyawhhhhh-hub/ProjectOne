# Prompt: a housing system like Driving Empire's (our own look)

_For Claude Code on the PC, with Roblox Studio connected (MCP). This builds on `Houses - buy at showroom, place on a lot.md` (read that too). Where they differ, **this file wins**. Owner: talk short and simple (caveman mode, see `Preferences.md`)._

## Before you start
- Read:
  - `CLAUDE.md`;
  - `Roblox Playbook/Roblox Playbook - Rules for every game.md`;
  - `Games/CityLegends/CLAUDE.md`;
  - `City Legends/City Legends.md`;
  - `City Legends/Prompts/Houses - buy at showroom, place on a lot.md`.
- Call `list_roblox_studios` and use the Studio named **City Legends** only.
- **The map is baked.** Never `rojo build` over `CityLegends.rbxl`. Save a backup copy first.
- **Study the reference yourself:** the owner likes the housing in the Roblox game **Driving Empire**. Read its wiki and look at the house pictures:
  - https://drivingempire.fandom.com/wiki/Housing
  - https://drivingempire.fandom.com/wiki/Houses_Dealership
  - https://drivingempire.fandom.com/wiki/Neighborhood
  - each house page (for example https://drivingempire.fandom.com/wiki/The_Delaney)
  - YouTube tours of the houses if you can.
  The cloud assistant couldn't open these (its network blocks fandom.com), so you check the details there.
- **What the owner wants:**
  - the **system works like Driving Empire's**;
  - the **UI looks different**: our own fonts, layout, colours and text sizes;
  - the **houses look close to Driving Empire's** (the owner really likes them), but **not identical**: change proportions, colours, materials, roofs, windows and details, and give every house **our own name**.
  - Never copy their names, logos, UI art, or any assets / meshes / images. Build everything ourselves. This keeps us safe from Roblox's copycat checks (Playbook: don't look like another big game).

## How Driving Empire's housing works (what the cloud assistant found, from search results; check on the wiki)
1. **Houses Dealership:** a building where you step on a pad, and a **Blueprint Shop** opens. You buy a house **blueprint** (the design), not a place.
2. **8 or more blueprints in 3 plot sizes:**
   - **Small:** The Delaney $450K (1-car garage, about 1,588 sq ft), The Auburn $600K, The Everett $650K, The Apollo $750K.
   - **Medium:** Stonehurst Villa $1.45M, Richford Barndominium $1.9M.
   - **Large:** Cambridge Mansion $4.95M, Fiorenza Mansion $9.3M, Somerset Cottage about $17.4M (newer; prices may have changed).
3. **Neighborhood:** you go there and **claim a plot** that fits the blueprint's size (small / medium / large). Your house spawns on it. **One plot at a time.** 49 plots in all.
4. **Garage spaces:**
   - small and medium plots come with **3** free spaces, large ones with **5**;
   - more spaces can be bought (in game cash, and also Robux there).
5. **Inside:** you can use doors, lights, beds, sinks and other items.

## Our version (City Legends)

### 1. The Realty showroom = our "Houses Dealership"
- Keep **Legends Realty** (Downtown near the causeway) from the last prompt, plus the booth at the bottom of the mountain.
- Inside:
  - a glowing **blueprint table** pad: step on it (or press E at the agent) to open our **Blueprint catalogue**;
  - **scale models of a few featured houses** on stands, which you can walk round;
  - a big screen cycling through house photos.

### 2. Blueprints, in 3 tiers = 3 plot sizes
- **30+ blueprints** (from the last prompt): Low 12 / Mid 10 / High 8+.
- Prices **$150K (smallest) → $100M (the biggest house in the game)**.
- **Tier = plot size = place on the mountain:**
  - Low (small plots) at the bottom near the bridge;
  - Mid (medium plots) halfway up;
  - High (large plots) on the summit, behind the gate.
- **Make the houses close to Driving Empire's style.** Include our own versions of each of their kinds (cottage, small family house, modern box, stone villa, barn-style house / barndominium, classic mansion, Italian-style mansion, big estate), then add more of our own to reach 30+:
  - **Don't make the NASCAR / racing-themed house** (owner, 2026-10-29). Leave that one out completely.
  - Low: beach shack, townhouse, bungalow, ranch house;
  - Mid: glass house, cliff house, lodge, Spanish villa;
  - High: Miami white mansion, hilltop estate like `imports/refs/houses/high_tier_hilltop.webp`, mega-mansion with an infinity pool and helipad.
- Our own names, for example "The Harlow", "Bayview Cottage", "Kingsridge Villa", "Summit Crown Estate". No real addresses or brands.
- **Show the owner a mood board** that puts each of our houses next to the Driving Empire house it was inspired by. Get an OK before building.

### 3. Claiming a plot (like their Neighborhood)
- All lots start empty with a **FOR SALE** sign and the plot size on it (SMALL / MEDIUM / LARGE).
- **One placed house at a time** (like Driving Empire).
  - You can **own many blueprints**, but only one stands on a plot at a time.
  - Swap which house is placed from the house menu: the old one is packed away and the new one builds on a plot of its size.
  - _If the owner prefers one placed house per tier (the last prompt), ask; default to one at a time._
- **To claim:**
  1. drive or walk to a FOR SALE lot of the right size and press E;
  2. or pick on the map ("Choose your lot").
  3. See a ghost preview, then confirm.
- **Saving:**
  - the favourite lot is remembered;
  - on rejoin, the house goes back there if it's free, or you choose again;
  - leaving frees the lot.
- High plots are inside the Summit gate. Every house has its own small gate (last prompt).

### 4. Garage spaces (like theirs, but fair)
- Free spaces: **Low 3, Mid 3–4, High 5**.
- **The 5 most expensive houses: a 10-car garage plus 3 driveway spots** (owner decision).
- **Buy extra garage spaces with in-game cash**, rising in price: for example $50K, $100K, $200K..., up to the house's max bays.
- No Robux garage spaces for now. Ask the owner first: Playbook money rules apply (read prices from Roblox, grant only in ProcessReceipt).
- Pick which cars stand in the bays and on the driveway in Garage setup. Press E on any car to drive it.

### 5. You can actually go inside every house
Every house is a **real house you walk into**, not a shell or a fake front:
- The front door opens and you walk in.
- Every floor is real, with stairs between them, to the roof terrace where there is one.
- Every room is furnished: living room, kitchen, bedrooms, bathrooms. Size and furniture match the price, so bigger houses have more and nicer rooms.
- Windows look out at the real view. At night the lights inside show through the windows from outside.
- Go from inside straight into the **garage** (an inside door) and from the garage out to the driveway.
- High tier houses also get the pool deck, balconies and the helipad you can walk out to.
- The camera works indoors: it doesn't clip through walls or ceilings, and the third-person camera zooms in when the room is tight.
- To keep FPS up, the inside builds or switches on only when you're near or inside (streaming / LOD). Outside you see the shell and lit windows.

**Things you can use inside:**
- Doors open and close, every room's lights switch on and off, curtains / blinds, TV on and off with a picture, shower and taps with water, fridge opens, and beds.
- "Sleep" on the bed: a fade to black, skip to morning or evening (just for you, the camera only), and set as home spawn.
- Wardrobe: opens the existing Flex / outfit menu.
- Sound and a small effect on each interaction (Playbook: feedback on every action).
- Keep it cheap: interactions are ProximityPrompts that only show when near. No loops.

### 6. Our UI (different from Driving Empire's)
- Use City Legends' own style: the same look as our HUD, garage and dealership screens (dark glass panels, our accent colour).
- **Fonts:**
  - pick one display font for titles and one clean font for text;
  - don't use the same font or sizes as Driving Empire (check theirs and choose different ones);
  - make titles bold and large;
  - prices are big numbers.
- **Catalogue layout:**
  - a big 3D preview of the house on the left (it slowly turns; you can drag to spin it);
  - the list on the right as cards with a photo, name, tier chip (LOW / MID / HIGH), stories, bedrooms, garage spaces and price;
  - filters across the top;
  - a big BUY button, plus TOUR.
- **Plot claim screen:**
  - a map of the island with FOR SALE lots shown as pins, coloured by size;
  - taken lots greyed out with the owner's name.
- **Phone first:** buttons at least 44 px, readable at 667x375. Test both phone and PC.

### 7. My extra ideas
1. **Neighbourhood board** at the bottom of each tier: a sign listing who lives there (lot number + name).
2. **Blueprint unlock levels:** some houses also need a player level (like cars). This gives a goal ladder from the $150K house to the $100M one.
3. **Open house:** you can let others tour your house (Open / Friends / Locked), and visitors can leave a ⭐ like. Show "most-liked house in the server" on the Realty screen.
4. **House colour and roof picker** at claim time (3–4 palettes per house), so the same blueprint looks different on each plot.
5. **Garage elevator** for the top 5 houses: cars come up on a lift into the driveway.
6. **Interior themes** (Modern / Warm Wood / Dark Luxury / Beach), switched in one click.
7. **Daily mailbox gift** and **rent safe** (from the last prompt) grow with tier.
8. **House radio:** your own music only inside your house (Roblox's free library, no copyrighted songs).
9. **Seasonal decorations** (Halloween now): pumpkins and lights on houses, switched on by Config on update day (Playbook: Saturday 15:00 UTC).
10. **First-house moment:** after the first claim, a short cutscene drives the camera up your driveway to your front door. You can skip it after 1 s.
11. **Real estate quests:** "Tour 3 houses", "Claim your first plot", "Own a High house". Small rewards, and they point new players to the system.
12. **Estate value leaderboard:** house + upgrades + garage cars.

## Check before you say done
- 2-player test in Studio:
  - buy blueprints, claim plots, swap houses, garage spaces, driveway cars;
  - the gates;
  - leave and rejoin.
- No console errors.
- Every house can be walked into: all floors, stairs, garage door. Every interaction works (doors, lights, TV, taps, bed).
- Screenshots:
  - the catalogue;
  - the plot map;
  - 3 houses next to their Driving Empire inspiration;
  - inside a house;
  - phone size.
- FPS and part counts reported.
- Every Lune test passes. `luau-lsp analyze` is clean.
- Write the changes into `City Legends/City Legends.md` and `Games/CityLegends/CLAUDE.md`. Commit, push and save the place.

## When done, tell the owner (short)
- the house list with prices and which Driving Empire house each is like;
- how buying and claiming work;
- what's untested.
