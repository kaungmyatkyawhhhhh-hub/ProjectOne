# Prompt: the overnight run: new cars first, then make the whole game smooth and far better

_For Claude Code on the PC, with Roblox Studio connected (MCP) and Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`). Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras: do exactly the steps below, but do each one **to a very high standard**._

## How to work tonight (owner, 2026-11-05: "I'm leaving the PC on tonight ... no need to ask any questions since I can't reply ... continue all of these step by step, slow, with quality")
- **Never ask the owner anything.** When a choice is needed, pick what best fits the owner's rules and taste (realistic, the Monaco look, fictional names, no logos, no neon, no alcohol, phones first), **write the choice and why** under "Choices made overnight (2026-11-05)" in `City Legends/City Legends.md`, and carry on. Keep every choice easy to undo (Config values, backups in `ServerStorage`).
- **Slow and careful beats fast.** One step at a time, in order. Finish a step properly (tested, fixed, re-tested) before starting the next.
- **Before each step:** pull from git, read the notes, and check what's already done (skip what's done, after a quick check).
- **After each step:**
  1. play-test in Studio (2 players, PC and phone-size 667 × 375), day and night;
  2. no console errors or warnings you caused;
  3. Lune tests and `luau-lsp analyze` clean;
  4. FPS / memory not worse (measure the same 3 spots every time: the harbour street, the casino square, the Grand Hairpin);
  5. **save the place, commit and push**;
  6. write what you did in `City Legends/City Legends.md`, with before / after screenshots.
- **Backups** before every big change (copies in `ServerStorage`, named with the date).
- **If the usage limit hits:** finish the current change cleanly, save, push, and write **"Next: step N.M"** at the top of the overnight notes, so the next session continues exactly there.
- **You have all permission** (owner, 2026-11-05): do every step without waiting for approval. The owner can't reply tonight, so don't stop to ask; decide, note it, continue.
- **Take anything you want from the Toolbox / Creator Store** (buildings, gates, props, trees, interiors, materials, skies...): insert it in Studio into a holding folder in `ServerStorage`, **remove every script** (Script, LocalScript, ModuleScript, and check for hidden ones and fake "copy this command" popups), remove logos / brand names / real-brand cars, then use it. Keep a credit list (name, ID, creator) in the notes.
- **Never** save over `CityLegendsCars.rbxl`, never `rojo build` over the place, never auto-load Toolbox models from scripts, never touch the owner's passwords.

## Step 1: the new cars
Do **`City Legends/Prompts/New imports - Murcielago, Urus Performante, Ferraris.md`** fully (Murcielago LP650-4 Roadster, Murcielago LP670-4 SV, Urus Performante, Ferrari California, 458 Spider, 458 Speciale), with its rules for realistic interiors and exteriors and **no grey parts**.
- **The owner can't send cluster photos tonight.** So when a cluster is blurry, broken or missing:
  1. look for a clear photo of that car's real cluster yourself (Wikimedia Commons or other free-to-use sources; save it in `Games/CityLegends/imports/refs/` with its source and licence);
  2. recreate the cluster **1:1** from it (layout, numbers, needles or bars, colours, fonts, warning lights, glow, sharp, no logos) and make it live;
  3. if no good photo can be found, use the best cluster in the same family; if there's none, keep the model's own and **list the car** at the top of the overnight notes as "needs the owner's cluster photo", with the close-up render.
- Licence warnings (NC models) go in the overnight notes for the owner.
- **Better interior materials, only on the newly imported models** (the cars from this job and the Lamborghini / Bugatti / SVJ jobs; leave older models alone): make the cabin materials look premium and real:
  - **carbon fibre:** a sharp woven carbon texture at the right scale (twill weave, about 2–3 mm squares), glossy clear coat on top (low roughness), a subtle normal map so the weave catches light; forged carbon where the real car has it;
  - **leather:** fine grain normal map, slight sheen (roughness about 0.5–0.6), visible stitching lines in a contrast colour where the real car has them, perforated sections on seats if real;
  - **Alcantara / suede:** soft, matte (roughness about 0.9), a fine fuzzy texture, no shine;
  - **metal:** brushed aluminium with directional grain, chrome only where real;
  - **plastics:** soft-touch matte, not shiny; piano black only where real;
  - **carpet** and **roof lining:** soft fabric textures.
  - Use `SurfaceAppearance` (colour, normal, roughness, metalness), textures 512–1024 px, shared between cars (one carbon, one leather, one Alcantara set, tinted per car).
  - Close-up renders / screenshots of each cabin before and after.

- Pack the cars for Import 3D in `imports/new_cars/`. **Studio can't import FBX without the owner**, so if you can't import them, leave the packs ready and write the exact steps for the owner at the top of the notes ("Import 3D these files, then tell Claude 'cars imported'"). Then go on to Step 2.

## Step 2: make the whole game super smooth (performance and feel)
1. **Measure first** (MicroProfiler, Stats, the Script Performance panel, memory, draw calls, triangles) at the 3 spots, day and night, on PC and phone-size. Find the **10 biggest costs** (parts, lights, shadows, scripts running every frame, traffic, pedestrians, streaming, particles, textures, memory from runtime car meshes) and fix them one by one, measuring after each.
2. **Smooth frame rate:** no stutter when driving fast, entering new areas, spawning cars, opening menus, or when traffic / pedestrians spawn. Spread heavy work over frames, pool and reuse objects, avoid every-frame loops over many things, check streaming radii and pre-loading.
3. **Smooth cars:** steady, jitter-free car movement and camera at high speed (no shaking from physics / network ownership, no wheel jitter, smooth camera follow and interpolation), smooth steering and suspension on bumps and road joins.
4. **Smooth environment:** no pop-in near the camera (LOD distances, stand-ins, trees, lamps), no flickering, smooth shadows and light changes, smooth day / night transitions.
5. **Graphics settings** (Low / Medium / High / Ultra) really change the cost; phones default to Low / Medium.
6. **Targets:** 60 FPS on PC High, 30+ FPS on a phone-size Low, no frame over ~33 ms while driving the main roads. Report the numbers before and after.

## Step 3: learn from the videos in `Games/CityLegends/imports/`
Watch them yourself (frames with ffmpeg) and use what they show:
- `Cars FOV and Driving physcis.mp4`: how a smooth car and camera should feel: camera lag, lean in corners, breathing, high-speed sway, low chase camera, motion blur. Compare with City Legends and fix what feels worse (`Camera and car movement like the video.md` has the details).
- `mornign.mp4` (day) and `videoplayback (1).mp4` (night): Monaco's roads, buildings and light: make the environment match them better (`Make the Monaco map look real (from the drive video).md`).
- `cars.mp4`: the casino square at night with supercars and crowds.
- `Houses.mp4`: the house look (for Step 6).
Put a few side-by-side screenshots (video frame vs. game) in the notes.

## Step 4: day and night: quicker time, a cold foggy morning
1. **Make the time of day go faster:** a full day now takes 24 real minutes (`Config.DayCycle.CycleMinutes = 24`). Make it **about 12–16 minutes** (pick one, note it), keeping night long enough to enjoy the lights. Sunrise and sunset stay smooth.
2. **Day time = a cold morning with a little fog:**
   - in the morning (and lightly through the day): **cool, slightly blue-grey light**, a pale soft sun, crisp air;
   - **a light fog / mist**: `Atmosphere` density up a little with a cool haze colour, so far buildings and the mountain fade softly into mist (low-lying near the sea and in the valleys if possible), clearing a bit by midday; never so thick that driving is hard;
   - soft shadows, slightly lower contrast, a cool colour grade;
   - wet-looking roads only if it rained.
   - Keep sunset gold and night warm and golden (no neon).
3. Tune the `DayCycle` keyframes and `Weather`; check every time of day with screenshots.

## Step 5: buildings: fix overlapping and the two-colour flashing
1. Do **`Fix buildings flashing black and white.md`** fully if it isn't done: find every building whose wall shows **two colours** depending on the angle (z-fighting / two faces in the same place, shiny walls, inverted normals, stand-ins) and fix the cause, in the building tools too.
2. **Fix buildings that overlap each other** or overlap roads, pavements, kerbs, lots or venues: buildings poking into each other, walls inside walls, a building standing on the road, double buildings in the same spot. Move, trim or remove the extra ones so every building stands cleanly on its plot. Write a checker that finds overlapping building boxes and run it until it finds none.
3. Check **from the street and from above**, day and night, around the whole map.

## Step 6: remodel the house gates
- Every house's gate (Low, Mid and High, plus the Summit gate) gets a **realistic remodel**: proper pillars (stone / render with caps and lanterns), real gate leaves (wrought-iron or modern steel slats, the right height), a smooth opening animation and sound, an intercom post with the house number and name plate, lights at night, and walls or hedges joining it cleanly (no gaps, no floating, no z-fighting).
- Use cleaned Toolbox models if they look better (no scripts, no logos, made our own).
- Keep the gate logic working (who it opens for, cars driving through, roommates, the FOR SALE sign on empty lots).
- Screenshots of each tier's gate, day and night.

## Step 7: make every bad curve as good as the Grand Hairpin
- The **Grand Hairpin** is the quality bar (smooth shape, smooth surface, clean kerbs and lines, nice island, buildings round it).
- Go round **every curve and hairpin on the map** (the switchbacks, the Summit Pass, the Riviera Highway, the north roads, the side streets) and rebuild the bad ones to that standard:
  - a smooth, realistic curve (no sharp kinks, no saw-tooth edges, a sensible radius for the road's speed);
  - smooth surface and slope (no bumps or steps; follow `Smooth roads.md`);
  - kerbs, pavements and lines that follow the curve cleanly;
  - red-and-white kerbs where it's a sharp bend;
  - walls / guard rails on the outside where there's a drop;
  - nothing in the lanes.
- Run the lane checker on **all lanes** after each area (0 problems), and make sure traffic drives every curve cleanly.
- Before / after screenshots of the worst 10 curves.

## Step 8: a final bug hunt and polish ("a billion times better")
1. Play the whole game as a **new player** and as a **high-level player**, on PC and phone-size: the first 3 minutes, driving, police, races, deliveries, the dealer menu, Customs, car classes and levels, houses, Legends Rewards, the main menu, fast travel, saves.
2. Write every bug, error, stuck spot, ugly spot, lag spot and confusing moment in a list (worst first) in the notes, and **fix them all** that can be fixed safely tonight.
3. Polish: everything feels smooth, looks clean and realistic, and nothing looks placeholder.

## At the end
At the **top** of `City Legends/City Legends.md`, write a short summary for the owner:
- what was done tonight (step by step);
- what's left and where to continue ("Next: step N.M");
- **what the owner needs to do** (e.g. Import 3D the car packs, send cluster photos for the cars listed, approve choices);
- the choices made and how to undo them;
- the before / after FPS numbers.
