# Prompt: cars that look as good as on Sketchfab, with clean interiors (and a one-by-one replacement routine)

_For Claude Code on the PC, with Roblox Studio connected (MCP) and Blender if it's installed. Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`)._

## Before you start
- Read:
  - `CLAUDE.md`;
  - `Games/CityLegends/CLAUDE.md` ("How the cars work", and the tools `auto_car.py`, `convert_car.py`, `fix_models.py`, `shrink_model.py`, `pack_cars.py`, `take_cars.luau`, `BrandMarks`, `DialLooks`, `TailLights`);
  - `City Legends/City Legends.md` (car notes, logo rules).
- Call `list_roblox_studios` and use the Studio named **City Legends** only. Save a backup first. Never save over `CityLegendsCars.rbxl`.
- **Rules:**
  - fictional names;
  - **no logos or emblems** anywhere (badges, steering-wheel hub, wheel caps, the cluster): cover them;
  - **driver hands are the player's own Roblox R6 avatar arms / hands** (owner, 2026-11-02), not separate realistic hands;
  - interiors and clusters as good as Driving Empire's.

## Why cars look worse here than on Sketchfab (the owner asked)
1. Sketchfab shows them in a **studio light with a reflective HDR environment**; our city has game lighting.
2. Roblox limits: about **20,000 triangles per mesh** and **1024 px textures**. Our tools cut to about 18k triangles, so curves can go edgy and paint crumpled.
3. **Our pipeline drops the metalness / roughness maps** and bakes plain colours (`fix_models.py`: "no metal/roughness maps"). That's the main reason paint, chrome, carbon and leather look **plastic**.
4. Vertex colours, some glass / alpha, and smoothing are lost on import.
5. Weak reflections without Future lighting.

## Part 1: the look of every car
> The owner will replace almost all the cars with new, better models, one by one (Part 3). So don't polish the old models: build Parts 1, 2 and 4 into the **conversion pipeline and the game code**, so every new model comes out right automatically. Use the **first new model the owner sends** as the test car.
1. **PBR back on:** use `SurfaceAppearance` with **ColorMap + NormalMap + RoughnessMap + MetalnessMap** (512–1024 px) on paint, chrome, rims, calipers, carbon, leather and Alcantara.
   - Change `fix_models.py` / `auto_car.py` so they **keep** these maps (pack them into each material's textures) instead of throwing them away.
   - Keep solid alpha except glass.
2. **Paint:** a glossy clear-coat look (low roughness, a slight metallic flake for metallic paints).
   - It must still take player paint from Legends Customs: tint the ColorMap with `SurfaceAppearance.Color`, or keep paint as a separate tintable layer.
   - Check matte, gloss and metallic finishes.
3. **Glass:** tinted, slightly see-through, with reflections. Windscreens clear enough to see the cabin.
4. **Smarter triangle budget:**
   - keep detail where players look (body curves, wheels, lights, the cabin from the driver's seat);
   - cut detail under the car, in the engine bay and in hidden parts;
   - split big meshes into several parts instead of crushing one under 20k.
   - Weld seams before decimating so the paint stays smooth.
5. **Lights:** headlights and tail lights look like real lenses and LEDs (glass + a glowing inner part), using `TailLights` for the brake glow.
6. **Check in Studio:**
   - a **showroom test scene** (a neutral HDR-like sky, a soft key light, a reflective floor), with the same camera angles as the Sketchfab page;
   - put screenshots next to the Sketchfab view, then check the same car in the city at day and night.
   - Show the owner before / after.

## Part 2: a proper, clean interior
Every car's cabin must look clean and real from the driver's seat and from outside through the windows:
1. **No mess:**
   - no grey or white untextured parts (find them like the old "grey parts" fix);
   - no floating, doubled or z-fighting pieces;
   - no holes where you can see the road or the engine;
   - no stretched textures.
   - Add a black firewall / floor where the model has none (`FIREWALL` in CarSkin).
2. **Right materials:**
   - leather seats with stitching;
   - Alcantara or leather wheel rim;
   - **carbon** trim;
   - soft-touch dash plastic (not shiny);
   - brushed metal accents;
   - piano-black panels;
   - carpet.
   - Colours from the real car's interior photo. Use `CABIN_RECOLOUR` where the model's own colours are wrong.
3. **Steering wheel:**
   - clean, the right size and tilt;
   - no logo on the hub (covered);
   - turns with the steering;
   - the player's **R6 avatar hands** on the wheel at 9 and 3, turning with it, never covering the cluster.
4. **Cluster and screens: use the model's OWN cluster** (owner, 2026-11-02):
   - **Never draw our own custom cluster over it** (no `DialLooks` overlay, no added dial pictures) on the new models. Use the cluster that comes **in the model** and make it **work**:
     - **analog needles:** cut each needle out of the model as its own part (or, if the needle is painted on the texture, paint it out and make a matching needle part), find its pivot and its 0 and max angle from the dial's numbers, and turn it live for **speed** and **RPM**, plus fuel / temperature if it has those;
     - **digital clusters** (most modern cars, e.g. the Aventador SVJ): keep the model's screen shape and look, and drive what's on it from the game: the **RPM bar / sweep**, **speed number**, **gear** (P/R/N/D or 1–7 / M), the shift-light / redline flash, drive mode (STRADA / SPORT / CORSA style, our own words), fuel, time. Copy the layout and colours of the model's own screen picture, so it still looks like the model's cluster, just alive. Use SurfaceGui on the screen part (pixel-matched to the screen area), not a floating overlay.
   - **Warning lights:** turn signals blink, high beam, handbrake, check-engine at start-up, ABS / TC off light when drifting.
   - **Start-up sequence:** pressing F (start) does a needle sweep or a screen boot animation, like a real car.
   - **Centre screen:** shows something simple (map, music, camera), not a blank grey box.
   - **Smooth and accurate:** needles move smoothly (slight lag like a real needle), the speed matches the HUD exactly, RPM matches the engine sound and the gearbox, and the redline matches the car.
   - Readable at night (backlit), no logos (cover any brand mark on the cluster).
5. **Small details:** pedals, gear lever or selector, seat belts, mirrors that show something (or a dark reflective mirror), door cards, air vents, and the roof lining.
6. **Lighting inside:**
   - the dash glows softly at night (cluster, screen, ambient strip in the car's own colour, no neon look);
   - the cabin isn't pitch black by day: real window light, no fake brightness.
7. **Driver's eye:** the first-person camera sits where a real driver's head is (`EyeHeight`), so you see the cluster and the road like in Driving Empire.
8. **Check:** a first-person screenshot of each car next to a **real interior photo** of that car from the same angle (find one online, or the owner sends one). The owner approves.

## Part 2b: keep every model high quality (checklist for each car)
Run this list on every new model, and don't sign a car off until it all passes:
1. **Scale and stance:** real wheelbase (`CarBuilder.REAL_WB`), real ride height, wheels fill the arches, the right tyre width front and rear (wider rears on supercars), no floating or sinking.
2. **Wheels:** round and smooth (enough sides), the tyre sidewall visible, rims with depth, brake discs and calipers behind the spokes, discs don't spin with the caliper, front wheels steer at the right angle, wheels don't clip the body.
3. **Shading:** smooth curves (no faceted or crumpled paint), no black or inverted faces, no shiny seams, normals correct (check by orbiting under a bright light).
4. **Textures:** sharp at driving distance (512–1024 px), no stretched or blurry decals, no missing (pink / grey / white) textures, the PBR maps applied (Part 1).
5. **Paint:** takes every Customs colour and finish correctly, without colouring the trim, glass, lights, tyres or interior by mistake. Check 3 colours.
6. **Glass:** windscreen and windows tinted and clear from inside, no doubled glass layers that flicker.
7. **Lights:** headlights (low / high), DRLs, tail lights, brake lights, reverse light, indicators: all work and glow in the right places.
8. **Interior:** passes Part 2 from the driver's seat and through the windows from outside.
9. **Cluster:** the model's own cluster works (speed, RPM, gear, lights); no overlay.
10. **Doors:** open like the real car (Part 4), if they're separate.
11. **Logos:** none visible anywhere (badges, wheel caps, the steering hub, the cluster, the brakes, the number plate): covered or removed.
12. **Performance:** the triangle count per car and the total are reported, with a LOD version for far away (traffic and other players' cars use it), and the textures shared where possible. A car must not drop FPS on a phone.
13. **Physics fit:** the collision box matches the body (no hitting invisible walls, no sinking into kerbs), and the exhaust flames / pops come out of the real exhaust tips.
14. **Sound:** the car uses an engine sound that fits it (a V12 for the SVJ).
15. **Screenshots for the owner:** front 3/4, rear 3/4, side, the driver's seat, the cluster close-up, night, doors open, and next to the Sketchfab view.

## First car: Lamborghini Aventador SVJ (owner, 2026-11-02)
- The owner's first new model is an **Aventador SVJ**. In the game it's fictional: **"Enfurecido Aventador SVJ"** (no real badge or name), the top of the "Enfurecido Aventador" series after the LP700 and LP750 (`Cars.Series`). Suggest its price, level, top speed (about 217 mph / 350 km/h) and 0–60 (about 2.7 s) to the owner before adding it.
- Use it as the test car for Parts 1, 2, 2b and 4:
  - its **own digital cluster** working (the RPM sweep, speed, gear, the drive modes);
  - **scissor doors**;
  - Y-shaped lights;
  - the big rear wing and centre exhaust (pops and flames from there);
  - a V12 sound.
- It may also replace the LP750 as the cutscene car (`Cars.CutsceneId`) if the owner likes it. Ask first.

## Part 3: one-by-one replacement routine (the owner will send new models one at a time)
For each new model the owner sends (a `.glb` / `.fbx` in `Games/CityLegends/imports/`, or a Sketchfab link they downloaded; licence CC0 / CC-BY, or bought):
1. **Check it first:**
   - the licence;
   - triangle count;
   - textures;
   - whether it has a full interior;
   - logos;
   - **render it** in Blender from outside and from the driver's seat.
   - Tell the owner if it's good enough before converting.
2. **Convert** with `auto_car.py` (wheelbase from `CarBuilder.REAL_WB`): wheels, steering wheel, tilt, glass, PBR kept, logos covered, the LOD / triangle budget.
3. **Import into Studio** and put it in `ReplicatedStorage.CarModels/<car id>`, **replacing** the old model of that car id. Keep the old one in a backup folder until the owner approves.
4. **Hook it up:**
   - steering-wheel donor if needed;
   - cluster (`DialLooks`);
   - tail lights;
   - brand marks / logo covers;
   - eye height;
   - Customs paint;
   - check traffic and garage still work.
5. **Test drive:** outside and inside, day and night, all cameras, and a phone-size screenshot.
6. **Show the owner:** the Sketchfab look vs. ours (outside + driver's seat) vs. the real interior photo.
7. **When approved:**
   - remove the old model;
   - export with `take_cars.luau` to `assets/CarModels.rbxm`;
   - commit and push;
   - write the car's notes in `City Legends/City Legends.md`;
   - delete the import file from `imports/` (it's done).
- Large files: if a model is over 100 MB, shrink it with `shrink_model.py` first, or have the owner zip it into parts.

## Part 4: doors that open (owner, 2026-11-02)
- **What's needed:** the door must be its **own separate piece** in the model (most good Sketchfab cars have this; some are one solid body). When checking a new model (Part 3, step 1), say whether its doors are separate.
  - If they aren't, they can be cut out in Blender, but that's harder and may leave holes: tell the owner first.
- **The converter:**
  - keep each door as its own part group (`Door_FL`, `Door_FR`, and the rears on 4-door cars), with the door glass, handle and inner door card inside it;
  - find the **hinge point and axis** (front edge for normal doors; near the A-pillar going up and forward for scissor doors; the roof for gullwings);
  - write them into the conversion report.
- **Door styles, matched to the real car:**
  - **normal** (swing out about 60–70°);
  - **scissor / lambo** (swing up about 80–90°, the Lambrini cars);
  - **butterfly** (up and out, some hypercars);
  - **gullwing** (from the roof, like the old SLS);
  - **sliding** (vans like the Alfard's rear doors).
- **When they open:**
  - when you get in or out (a short animation, about 0.6–1 s, with a door sound and a thunk on close);
  - press a key / tap a button to open or close while parked;
  - in showrooms, the dealership preview, house garages and the night car show (doors up looks great);
  - passengers' doors open when they get in.
- **Rules:**
  - doors only move when the car is stopped or very slow (they close automatically above about 5 km/h);
  - they don't change the car's physics (visual only, no collision when open), so they can't be used to glitch or push others;
  - the open / closed state is synced to other players (server-checked, rate-limited).
- **Inside:** the inner door card, handle, window switches and speaker look clean (Part 2).
- **Performance:** a simple tween on the client, only for cars near the camera.
- **Test:** each door type on one car (a normal sedan, a Lambrini scissor, a van), then roll out to every car whose model has separate doors. List the cars without separate doors for the owner.

## When done, tell the owner (short)
- what changed for car looks;
- the interior checklist result per car;
- before / after screenshots;
- which car to send next.
