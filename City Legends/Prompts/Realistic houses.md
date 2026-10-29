# Prompt: make the island houses look very realistic

_For Claude Code on the PC, with Roblox Studio connected (MCP). Do this with or after `One big island and real estate.md` Part 2. Owner: talk short and simple (caveman mode, see `Preferences.md`)._

## Before you start
- Read:
  - `CLAUDE.md`;
  - `Roblox Playbook/Roblox Playbook - Rules for every game.md`;
  - `Games/CityLegends/CLAUDE.md`;
  - `City Legends/City Legends.md`.
- Call `list_roblox_studios` and use the Studio named **City Legends** only. Never touch another game's Studio.
- **The map is baked.** Don't `rojo build` over `CityLegends.rbxl`. Save a backup copy first (`CityLegends_before_houses.rbxl`). Never save over `CityLegendsCars.rbxl`.
- **Owner's taste:** realistic, in the style of top Roblox games (Highway Legends), never cheap or blocky. Real-life modern Miami / Los Angeles / Dubai homes.
- Rules:
  - no logos or brands;
  - never load Creator Store models by ID from a script.

## How to get "very realistic" (be honest with the owner)
Houses built only from plain Roblox blocks will always look like Roblox blocks. Real-looking houses need:
1. **Mesh shapes, not blocks:**
   - roof edges with thickness and overhangs;
   - window frames with depth;
   - railings, door handles, steps and kerbs with bevels (rounded edges).
2. **PBR materials** (`SurfaceAppearance` or `MaterialVariant`): textures that look physically real, with colour, normal, roughness and metal maps. Use:
   - real plaster or stucco;
   - wood cladding;
   - stone;
   - concrete;
   - dark metal frames;
   - roof tiles;
   - marble floors;
   - pool tiles.
   Keep textures 512 px or smaller and reuse them across houses.
3. **Proper proportions:** door 2.1 m, ceiling 2.7–3.2 m, stairs 18 cm steps, railings 1 m. Use the game's car scale to convert to studs.
4. **Details that make it real:**
   - window frames and sills;
   - gutters and downpipes;
   - outdoor lights by the door;
   - house numbers;
   - mailbox;
   - AC units;
   - garden lights;
   - plant pots;
   - lawn edges;
   - stone driveway with tyre marks;
   - pool with ladder and loungers;
   - glass balustrades (glass railings) on balconies;
   - curtains or blinds in windows;
   - furniture shapes seen through glass.
5. **Light:**
   - warm interior lights at night, seen through the windows;
   - soft lights in the garden and pool;
   - correct shadows by day.
6. **Landscaping:** grass with colour variation, hedges, palms, bushes, flower beds, gravel and stepping stones. No flat green plate.

Ways to get the meshes. Pick the best for each house, and tell the owner which you used:
- **A.** Build the house in **Blender** (if installed on the PC): modular pieces (walls, windows, roofs, railings) with bevels and UVs, exported as FBX and imported. This gives the best result.
- **B.** Build from parts in Studio, then use **Solid Modeling** (union / negate) for window holes and bevels. Use `MaterialVariant` for realistic materials. This is good enough for Low tier.
- **C.** The owner inserts good free house models from the **Creator Store / Toolbox** by hand. You give exact search words. Then you:
  1. delete every script in them;
  2. fix their scale;
  3. re-material them;
  4. check their licence.
- **D.** Sketchfab models with a licence that allows use (CC0 / CC-BY, give credit in the game's credits). The owner downloads them; you clean and import them.

## Steps
1. **Reference first.** For each tier, find 3 real-life photo references (style only, no copying a real address):
   - Low: Florida bungalows and townhouses;
   - Mid: modern LA houses;
   - High: Miami and Beverly Hills mega-mansions.
   Show the owner the mood board before building.
2. **One test house first:** build ONE Mid tier house fully realistic (outside, garden, and inside the ground floor and garage). Show the owner screenshots:
   - day, front view;
   - sunset;
   - night with lights on;
   - inside;
   - phone size (667x375).
   Wait for the owner's OK on the look before doing more.
3. **Then the rest**, using the same kit of pieces and materials so they look like one world, but with different shapes, colours, roofs and sizes per design.
4. **Performance** (from the Playbook: cheap phones):
   - each house **under ~600 parts**, with meshes reused;
   - textures 512 px or smaller;
   - no shadows on small props;
   - few lights, only on when you're near;
   - glass as fully opaque tinted panels or real windows: no half-see-through parts except the windows you look through;
   - LOD: a simple far version beyond ~400 studs;
   - interiors load only when you're near or inside.
   - Report FPS and part counts on the island before and after.
5. **Check:**
   - 2-player test in Studio;
   - no console errors;
   - each house can be walked into;
   - the garage showcase works.
   - Commit, push and save the place.
   - Write what you did into `City Legends/City Legends.md`.

## When done, tell the owner (short)
- which way (A/B/C/D) each house used;
- screenshots: day / sunset / night / inside;
- FPS and part numbers;
- what still looks off.
