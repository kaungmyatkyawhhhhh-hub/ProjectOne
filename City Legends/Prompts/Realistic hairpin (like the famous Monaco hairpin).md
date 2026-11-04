# Prompt: make the hairpin realistic, like the famous Monaco hairpin (1+1 lanes, buildings round it)

_For Claude Code with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. Do it together with `Smooth roads.md` (curved road meshes)._

## References (owner, 2026-11-04), in `Games/CityLegends/imports/refs/map/hairpin/`
- `hairpin_map_satellite.webp`: the map / satellite view of Monaco's famous hairpin (Avenue des Spélugues below the big hotel). **The shape:** the road comes down the hill, does a very tight U-turn (about 180°) round a small **teardrop-shaped central island**, and goes back up next to itself; the two legs run side by side, close together, separated by a raised kerb / pavement; a big curved hotel building wraps round the outside of the bend; Grand-Prix-style red-and-white kerbs on the inside of the turn.
- `hairpin_day_above.webp` and `hairpin_night.webp`: the hairpin from above, day and night:
  - **one lane each way** (1+1), with a white centre line (dashed) and white edge lines;
  - a small **raised planter island** in the middle of the bend (palms, agaves, shrubs) with **red-and-white striped kerbs** round it;
  - **red-pink brick pavements** on both sides with stone kerbs and more red-and-white kerbs on the outer edges;
  - lamp posts in the island, buses and scooters going round, people watching from the pavements and balconies;
  - tall apartment towers (cream, pink, salmon, white, with balconies) right round it, the mountain behind; at night warm street lamps and lit windows, the bend glowing orange.
- `hairpin_aerial_hotel.webp`: aerial view: the hairpin under a **big curved hotel** (pool on the roof, the sea behind), the bend's legs, an apartment block in the inside of the bend with a garden, red-and-white kerbs everywhere, palm gardens below.
- `hairpin_wall_street_level.webp`: street level on the approach: a **tall curved stone retaining wall** (rough pale limestone, plants growing from it), a narrow red-brick pavement with a stone kerb, a drain grate, a dark asphalt road with one solid white line, a tall thin dark lamp post, a white railing fence on the other side, a small roundabout warning sign, white apartment towers and palms, the rocky mountain above.

## Can you use Google Maps / Google Earth?
- **Yes for looking:** if your network allows google.com, open Google Maps (satellite and Street View) for the Fairmont Hairpin in Monaco and check the shape, the island and the buildings round it. Google Earth's 3D view is hard to read from a script, so don't rely on it.
- **For the actual shape, use OpenStreetMap** (the map already uses its data): download the real road lines of the hairpin and the building outlines around it (the Overpass API), and scale them to our map. Credit "© OpenStreetMap contributors". Don't copy Google's map data or images into the game.

## What to build
1. **The bend's shape:** rebuild the existing hairpin(s) on the Riviera map to match the real one: a very tight ~180° turn round a small teardrop island, the two legs close and nearly parallel, the right slope (the road falls through the bend), smooth curve meshes (no blocks, no bumps; see `Smooth roads.md`).
2. **1+1 lanes** on the hairpin and its approach (owner's choice): one lane each way, same lane width as now (16 studs), a dashed white centre line and solid edge lines. Narrow down from the 2+2 road before the hairpin with a smooth, clearly marked taper, and widen back after it.
3. **The island:** a raised planter island with palms, agaves and shrubs, **red-and-white striped kerbs** round it, a lamp post or two, the right size so cars, buses and the traffic AI can get round.
4. **Kerbs and pavements:** red-pink brick pavements, stone kerbs, red-and-white striped kerbs on the inside and outer edge of the bend, a drain grate, a white railing on the open side, the tall curved **stone retaining wall** on the hill side.
5. **Buildings round it** (as realistic as possible; cleaned Toolbox models allowed): a big **curved hotel** wrapping the outside of the bend (fictional name, e.g. "Grand Hairpin Hotel", no real name or logo), an apartment block inside the bend with a small garden, tall apartment towers in cream / pink / salmon / white with balconies around and up the hill, palms and gardens. Lit windows at night.
6. **Night look:** warm street lamps, the bend glowing orange, lit windows, like `hairpin_night.webp`.
7. **Traffic:** the lane graph follows the 1+1 hairpin (traffic slows a lot for it and never cuts the island); buses / big cars make it round without getting stuck. Races and chauffeur routes through it still work.
8. **Optional photo spots:** the balcony / pavement view from above the bend (good for Photo Mode), since it's a famous view.

## Check before you say done
- Drive the hairpin both ways in a hatch, an SUV and a hypercar, slow and fast: smooth, no bumps, kerbs and island in the right place, nothing blocking the lane.
- The lane checker on both lanes: 0 problems.
- Traffic drives through it for a few minutes without getting stuck.
- Screenshots next to each reference photo (from above, day and night, and street level).
- FPS not worse. Save, commit, push; note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- what changed;
- the side-by-side screenshots;
- anything to check.
