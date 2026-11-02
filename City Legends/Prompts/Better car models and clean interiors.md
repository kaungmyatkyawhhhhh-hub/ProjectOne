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
  - **driver hands real-size**;
  - interiors and clusters as good as Driving Empire's.

## Why cars look worse here than on Sketchfab (the owner asked)
1. Sketchfab shows them in a **studio light with a reflective HDR environment**; our city has game lighting.
2. Roblox limits: about **20,000 triangles per mesh** and **1024 px textures**. Our tools cut to about 18k triangles, so curves can go edgy and paint crumpled.
3. **Our pipeline drops the metalness / roughness maps** and bakes plain colours (`fix_models.py`: "no metal/roughness maps"). That's the main reason paint, chrome, carbon and leather look **plastic**.
4. Vertex colours, some glass / alpha, and smoothing are lost on import.
5. Weak reflections without Future lighting.

## Part 1: fix the look of every car (do one car first: the LP750)
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
   - hands at 9 and 3, real-size, never covering the cluster.
4. **Cluster and screens:**
   - live needles or digital screens matching the real car (`DialLooks` / `DIAL_NEEDLES`), sharp and readable at night, no logos;
   - the centre screen shows something simple (map or music), not a blank grey box.
5. **Small details:** pedals, gear lever or selector, seat belts, mirrors that show something (or a dark reflective mirror), door cards, air vents, and the roof lining.
6. **Lighting inside:**
   - the dash glows softly at night (cluster, screen, ambient strip in the car's own colour, no neon look);
   - the cabin isn't pitch black by day: real window light, no fake brightness.
7. **Driver's eye:** the first-person camera sits where a real driver's head is (`EyeHeight`), so you see the cluster and the road like in Driving Empire.
8. **Check:** a first-person screenshot of each car next to a **real interior photo** of that car from the same angle (find one online, or the owner sends one). The owner approves.

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
