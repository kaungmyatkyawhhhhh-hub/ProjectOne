# Prompt: remodel every venue building so it looks a million times better

_For Claude Code with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`)._

## What this is
The venues are the buildings players go **into**, built by script at their Monaco (Riviera Bay) sites:
- **Legends Reserve Bank**;
- **Legends Motors** dealership;
- **Legends Customs**;
- the **3 penthouse towers** (Aurum Residences, Skyline One, The Crown);
- the **Legends Grand Hotel**;
- the **High-Rollers Casino** (scenery only);
- the **Gem Showcase**;
- **Legends Realty** (if built);
- the challenge gantries;
- the chauffeur stands;
- the police station(s).

They still look like the old blocky part-built buildings. **Remodel each one, outside and inside, so it looks like a real luxury building in Monaco and fits the Riviera Bay map.**

## Before you start
- Read:
  - `CLAUDE.md`;
  - `Roblox Playbook/Roblox Playbook - Rules for every game.md`;
  - `Games/CityLegends/CLAUDE.md`;
  - `City Legends/City Legends.md`.
- Also read the look references:
  - `Make the Monaco map look real (from the drive video).md` (day / night / casino square);
  - `Realistic graphics, lighting and buildings.md`;
  - `Fix buildings that look off.md` (the realism checklist);
  - `Dealership model 86483010946222.md` (the Monaco showroom look for Legends Motors, with photos in `imports/refs/dealership/`).
- Call `list_roblox_studios` and use the Studio named **City Legends** only. The place is on Team Create. Save a backup first.
- **Keep every gameplay part working:**
  - prompts, counters, doors, lifts, valet bays, vault, turntables, the safe, the DJ booth and party mode (penthouses only), spawn points;
  - `Config` positions and attributes the code reads.
  - Change the **looks**, not the gameplay. If a gameplay piece has to move, update the code and test it.
- **Rules:**
  - fictional names, no logos;
  - **no neon** (gold and warm white light only);
  - no alcohol (bars become coffee / juice bars);
  - the casino is scenery only (no playable gambling).

## How each venue should look (our own designs, Monaco style)
1. **Legends Reserve Bank:**
   - a grand Belle Époque stone bank: columns, a big bronze door, carved cornice, flags, a stone stair, warm floodlights at night;
   - inside: a marble banking hall, wooden counters with brass lamps, a chandelier, the vault door (a huge round steel door with bolts), a corridor to the vault, CCTV, the guard desk.
   - Heist parts keep working.
2. **Legends Motors:** the Monaco showroom from `Dealership model 86483010946222.md`:
   - Belle Époque block above;
   - gold LEGENDS MOTORS letters;
   - glass front;
   - terrazzo floor;
   - diagonal light tracks;
   - wood-slat walls;
   - angled cars;
   - the buy counter.
3. **Legends Customs:**
   - a clean modern workshop: a glass-and-steel front, a polished grey epoxy floor, 3 bays with lifts, tool walls, tyre racks, a paint booth with soft lights;
   - the TUNING bay lit like a stage;
   - a lounge with a window onto the bays.
4. **The 3 penthouse towers:** each one a distinct landmark:
   - **Aurum Residences:** a warm-stone Belle Époque high-rise;
   - **Skyline One:** a curved glass tower with wraparound balconies;
   - **The Crown:** a slim, very tall tower with a crown-shaped lit top.
   - Each has: a grand lobby (marble, concierge desk, lift lobby with brass doors), the penthouse (open plan, floor-to-ceiling glass, sea views, real furniture, kitchen, bedroom, the car turntable, the DJ booth), and a roof pool with loungers and a helipad.
5. **Legends Grand Hotel:**
   - a classic grand hotel facing the square: cream stone, iron balconies, a big canopy over the entrance with gold letters, doormen, the **valet bay** with a stand, potted palms, red carpet;
   - lobby: chandeliers, marble, reception, a lounge;
   - the suites at the top, each with its own view.
6. **High-Rollers Casino (scenery only):**
   - the jewel of the casino square: a Belle Époque palace with two corner towers, a copper-green roof, a big arched glass entrance, gardens and a fountain in front, floodlit gold at night;
   - inside: a grand hall with gilded ceilings and chandeliers, red carpets, tables as decoration only, the VIP area, the heist vault.
7. **Gem Showcase:**
   - a small luxury jewellery house: black stone and bronze front, tall narrow windows with lit displays;
   - inside: glass display cases on marble, spotlights on each gem, a velvet-dark room, security glass.
   - Smash-and-grab parts keep working.
8. **Legends Realty:** an elegant estate agency: big windows with house photos, a desk, the island / map model on a table, screens.
9. **Police station:** a modern civic building, with blue-and-white signs, the station garage and parked police cars.
10. **Small things:** chauffeur stands (an elegant kiosk with a canopy), challenge gantries (a clean steel arch with a timer screen).

## Quality rules (every venue)
- **As realistic as possible** (owner, 2026-11-02): every venue should look like a real photo of a luxury building in Monaco, not a Roblox build. Pick only realistic Toolbox models (real textures and proportions, no cartoon or blocky ones), use PBR materials, real lighting and small real-life details. Compare each one with a real photo of a similar building and keep improving until it matches.
- **Real scale:** about 3 m per floor (about 9 studs), doors about 2.1 m, people-sized furniture.
- **Depth and detail:** recessed windows with frames, cornices, balconies with railings, a stone base, a roofline, a real entrance (canopy, steps, doors that open).
- **Real materials:** the `MaterialVariant` kit (marble, stone, plaster in Monaco colours, brass, dark metal, glass, wood). No plain plastic.
- **Inside matches outside:** you can walk in and it feels like the same building. No empty boxes, no grey placeholder walls.
- **Lighting:**
  - warm interior lights;
  - floodlit fronts at night;
  - lit windows;
  - a few real lights near the player only (LOD).
  - Day, sunset and night screenshots.
- **Landmarks:** each venue is easy to recognise from far away (its own shape and lit sign), and shows on the minimap.
- **Fit the street:** each one sits correctly on its Riviera Bay site, with the sidewalk, kerbs, lamps, planters, parking / valet bays and a clear way in for cars and people.
- **Performance:**
  - reuse meshes (columns, railings, windows, lamps) across all venues;
  - interiors load only when near (streaming / LOD);
  - aim for under about 2,000–4,000 parts per big venue;
  - report part counts and FPS before / after (phone-size included).
  - It must not run worse on Medium.
- **Use the Toolbox / Creator Store a lot** (owner, 2026-11-02: most of our own building isn't good enough). For each venue, search the Creator Store for good-looking models first (buildings, facades, showrooms, lobbies, furniture, chandeliers, vault doors, jewellery cases, garage lifts, hotel canopies, lamps, planters...) and build from the best ones:
  - search with the Toolbox API (`apis.roblox.com/toolbox-service/...`) or Studio's Toolbox, and pick models with **good ratings, a clean look and sensible part counts**;
  - **insert them in Studio while editing** (through the MCP, or ask the owner to click "Get Model" first if needed). They are saved into the place. **Never make the game load models by ID while it runs**;
  - **clean every model:** delete all Script / LocalScript / ModuleScript, check for hidden `require(` backdoors, odd folders, giant invisible parts, sounds and GUIs with links;
  - **remove logos, brand names and real-brand cars**, and put our fictional names on;
  - **change them enough to be ours** (colours, materials, layout, details), so nobody can say it's their building;
  - fit them to real scale, our Monaco style and our materials; merge or remove hidden detail for performance;
  - keep a list in `City Legends/City Legends.md` of every model used (name, ID, creator) so they can be credited.
- Sketchfab models can also be used (CC0 / CC-BY, credited), converted with our tools.

## How to do it
1. **Plan:** for each venue, a short design (what it looks like, which reference) and a screenshot of the current one. Show the owner the list and order. **Suggested order:** Legends Motors → Hotel → Casino → Bank → the towers → Customs → Gem Showcase → the rest.
2. Remodel **one venue at a time**, outside then inside.
3. After each venue:
   - screenshots before / after (outside day, outside night, inside, phone size);
   - test every gameplay part in it (2 players);
   - FPS and part count;
   - save, commit and push;
   - note it in `City Legends/City Legends.md`.
4. Wait for the owner's OK, then do the next.

## When done with each venue, tell the owner (short)
- what's new;
- before / after screenshots;
- what still works (tested);
- the FPS and part numbers;
- which venue is next.
