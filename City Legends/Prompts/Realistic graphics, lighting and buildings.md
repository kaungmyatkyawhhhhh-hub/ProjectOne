# Prompt: make City Legends look far more realistic (graphics, lighting, buildings)

_For Claude Code with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`)._

## Before you start
- Read:
  - `CLAUDE.md`;
  - `Roblox Playbook/Roblox Playbook - Rules for every game.md` (performance rules: phones first);
  - `Games/CityLegends/CLAUDE.md`;
  - `City Legends/City Legends.md`;
  - `City Legends/Prompts/Make the Monaco map look real (from the drive video).md` (the look we're going for: Monaco by day, blue hour and night, from the owner's videos).
- Call `list_roblox_studios` and use the Studio named **City Legends** only.
  - **The place is on Team Create.** Don't `rojo build` over it. Save a backup copy first.
  - If the owner is also in the session from another computer, don't edit what they're working on.
- **Owner's rules:**
  - realistic, like the top Roblox driving games (Highway Legends, Driving Empire), never cheap or blocky;
  - **no neon at all**;
  - night = warm golden lamps and lit windows under a navy blue-hour sky;
  - fictional names, no logos.
- **Measure before and after:** FPS on PC and on a phone-size Studio emulation (and on a real low-end phone if the owner can), part count, draw calls, triangles and memory, at the same 3 spots (harbour street, casino square, a hill road) at noon, sunset and night. **Never ship anything that makes Medium graphics slower than before.**

## Part 1: lighting (the biggest win)
1. **Lighting engine:**
   - `Lighting.Technology = Future` (real light from every lamp and window, with shadows);
   - `EnvironmentDiffuseScale` and `EnvironmentSpecularScale` ≈ 1, so surfaces pick up the sky;
   - `ShadowSoftness` ≈ 0.15;
   - `GlobalShadows` on.
2. **Sky:** a realistic skybox per time of day (Roblox's own or free Creator Store skies, inserted by hand by the owner).
   - Day: deep blue Mediterranean.
   - Sunset: gold-orange.
   - Blue hour: navy.
   - Night: dark navy with stars.
   - Blend between them in `DayCycle`.
3. **Atmosphere:** low `Density` (about 0.25–0.3) with a little `Haze` and `Glare`, so far towers and the mountain fade naturally. No grey fog wall.
4. **Post-processing**, kept subtle (no "filter" look):
   - `ColorCorrection`: slight contrast, saturation about 0.05–0.1, warm tint by day;
   - `Bloom`: low intensity, only on real lights;
   - `SunRays`: small;
   - `DepthOfField`: only in menus and cutscenes, never while driving.
5. **Time of day:** tune the `DayCycle` keyframes to match the reference videos:
   - morning: crisp, clear blue, strong sun;
   - golden hour: warm long shadows;
   - blue hour: navy sky with lamps just on;
   - night: warm sodium-orange streets, white-warm in the shopping and casino streets.
6. **Real lights at night:**
   - every street lamp gets a `SpotLight` pointing down (warm, about 2,700–3,000 K), so you get pools of light on the road;
   - shop windows get soft `SurfaceLight`s;
   - tunnels get rows of lights.
   - **Only lights within about 150–250 studs of the camera are switched on** (keep using the `LOD` / `LODLight` system), so phones don't die.
7. **Reflections:** wet roads after rain reflect lamps and headlights (lower `Roughness`, a `MaterialVariant` for wet asphalt). Glass and car paint pick up the sky.

## Part 2: materials (make every surface look real)
1. Make a **material kit** in `MaterialService` with **`MaterialVariant`s** (PBR textures: colour, normal, roughness; 512 px or smaller, tiled):
   - asphalt (new and worn), road paint, red-pink paving, granite kerb, sidewalk stone;
   - plaster / stucco in the Monaco colours (cream, ochre, peach, salmon), limestone, rough stone wall;
   - concrete (smooth and board-formed), terracotta roof tile, slate;
   - dark metal, wrought iron, wood slats, glass (clear, tinted, mirrored);
   - marble, terrazzo;
   - grass, soil, sand, rock.
   - Sources: Roblox's built-in materials as a base, free CC0 textures (ambientCG, Poly Haven) uploaded by the owner, or Creator Store material packs inserted by hand. **No auto-loading from scripts.**
2. Swap the old plain `SmoothPlastic` / `Plastic` on buildings, roads and props for these. Nothing in the city should be plain flat plastic except tiny details.
3. **Colour variety:** walls vary slightly in tone (no two neighbouring buildings exactly the same colour), and there's light dirt / weathering at the bottom of walls and under windows.

## Part 3: buildings (much more realistic)
1. **Kill the "box" look.** Every building gets:
   - **depth on the front:** windows set into the wall (recessed), with frames, sills and lintels;
   - **balconies** with real railings (wrought iron or glass), and slab edges that stick out;
   - **cornices and roof edges** (a thicker top band, parapets);
   - **a ground floor that's different:** shopfronts with awnings, big glass, doors, signs (fictional), lights, a stone base;
   - **roof detail:** AC units, water tanks, antennas, roof terraces with plants, terracotta roofs on old buildings;
   - **shutters, blinds and curtains** behind windows (some open, some closed);
   - **interior hint:** a simple room box behind the glass (an "interior mapping" style picture or a dark room with a lamp), so windows don't look flat or see-through to nothing.
2. **The 5 Monaco building styles** (from the realism prompt): Belle Époque, 1970s balcony towers, modern glass towers, hillside villas, grand hotel / casino. Make a **reusable kit** per style (window bays, balcony bands, corners, shopfronts, roofs), and build every building from the kits with random variation in height, colour, balcony type and shop, so the city never looks copy-pasted.
3. **Use meshes, not hundreds of parts.**
   - Detailed pieces (window frames, railings, cornices, balusters) as **MeshParts reused across the whole city** (one mesh, many copies = cheap), built in Blender if it's installed, or as unions converted to meshes.
   - Aim for under ~300–800 parts per building (more only for landmarks).
4. **LOD:**
   - near: full detail;
   - mid (beyond ~300 studs): a simpler version, with flat balcony bands and no railings or roof clutter;
   - far: a simple block with a texture of the front (lit-window texture at night).
   - Use `LevelOfDetail = StreamingMesh` and streaming. Far buildings must still look right on the skyline.
5. **Night windows:** a random mix of lit windows (30–50%), warm yellow and a few cool white / TV blue. They change slowly over the night. Cheap: done with textures / surface colour, not one light per window.

## Part 4: the street level (where the player looks most)
- Kerbs with real height and a rounded edge, drains, manhole covers, road wear, patches and crack decals, tyre marks at junctions.
- The street furniture from the realism prompt (3 lamp types, bollards, railings, planters, signs, bus shelters, parked scooter rows), all with the new materials.
- Trees with good leaves (umbrella pines, palms, cypresses) that sway a little, using LOD: far trees are simple cards.
- Shadows under cars and trees. Small details like litter bins, benches and café tables.

## Part 5: graphics settings and performance (must do)
- A **Graphics** setting in the menu: **Low / Medium / High / Ultra**. It sets lights near the player, shadow casters, LOD distances, particle counts, tree sway, post-effects and reflections.
  - Phones default to **Low** or **Medium**.
  - Respect the player's Roblox graphics level too.
- **Keep the Playbook limits:**
  - about 1,000 draw calls and 1M triangles on screen;
  - textures 512 px or smaller;
  - no shadows on small props;
  - few lights near the player only;
  - no half-transparent parts except glass you look through;
  - reuse meshes.
- Report FPS and memory before and after on each setting.

## How to do it (in this order, show the owner after each)
1. **Lighting** (Part 1) on the existing map. Screenshots at noon, sunset, blue hour and night, next to frames from the owner's Monaco videos.
2. **Material kit** (Part 2) applied to roads and a few streets.
3. **One building of each style** rebuilt with the kits (Part 3). The owner picks the look.
4. Then roll it out **district by district** (start with the harbour), with the street level (Part 4).
5. **Graphics settings** (Part 5) and a final performance check.
- After each step:
  - play-test (2 players);
  - phone-size screenshot;
  - Lune tests and `luau-lsp analyze` for code changes;
  - save the place, commit and push;
  - write what changed in `City Legends/City Legends.md`.

## When done with each step, tell the owner (short)
- what changed;
- before / after screenshots;
- FPS before and after;
- what's next.
