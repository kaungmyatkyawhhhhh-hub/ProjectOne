# City Legends: notes for Claude

A Roblox night-city driving game. Players earn money driving and "cutting up" traffic (close passes), buy cars in a garage, and level up. It is built with Rojo from Luau source in this repo. `README.md` has the full feature list and player-facing setup; this file is the working context for continuing development.

## About the owner

The game lives inside the owner's Obsidian vault (repo `kaungmyatkyawhhhhh-hub/ProjectOne`, folder `Games/CityLegends`). Follow the vault's root `CLAUDE.md`. That means reading its start notes before replying, never announcing it, and saving new decisions to the vault. City Legends notes go only in the vault's `City Legends` folder (main note: `City Legends/City Legends.md`). Never mix them with another game's notes.


- **Not a programmer.** They work in Roblox Studio and often use a phone, so give short, plain steps ("open X, click Y").
- **Deliverable is a place file.** Build `CityLegends.rbxl` (binary, gitignored; `rojo build default.project.json -o CityLegends.rbxl`, then `python3 tools/fix_rbxl.py CityLegends.rbxl`, which Studio needs: Rojo can compress the big SSTR chunk larger than raw and Studio then refuses the file) after changes. Chat downloads of big files get cut off (Studio then shows a readData error), so the built `CityLegends.rbxl` is committed and pushed (owner chose this 2026-10-11): it reaches their PC through Obsidian Git, or from github.com. Mention the GitHub path when sending.
- **Target look is "Highway Legends"** (another Roblox game): realistic cars, a Highway Legends-style HUD, a rainy night city.
- **Never ask for or accept their Roblox / alt account logins or cookies.** They offered once; it was declined.
- **Fictional names only.** Cars use fictional names and no real badges (owner, 2026-10-17: logos, badges and names removed from every car; BNW, Mercer and Lexis get look-alike fictional emblems). Car looks can be inspired by real cars.

## Layout

- `src/shared`: modules used by both sides.
  - `Config`: all tuning: economy, progression, daily gift, traffic, sounds, theme.
  - `Cars`: the roster of 69 cars in 3 tiers (Starter, Mid, High), ids like `suzaki_swift`.
  - `CarBuilder`: part-built car, physics hitbox, interior, driver arms. `getDims(class, id)` gives per-car proportions through `DIM_OVERRIDES`.
  - `CarMesh`: procedural lofted car meshes, with a `DESIGNS` table per car.
  - `CityLayout`, `FacadeTex`.
- `src/server`:
  - `Main.server.lua`: remotes, car spawn, cash / XP / cut-up validation, daily gift, console cash hook.
  - `PlayerData`: DataStore profile with Cash, Owned, Selected, Level, XP, LastDaily.
  - `CityBuilder`, `CityPremium`.
- `src/client`:
  - `Main.client.lua`: startup order.
  - `UI`: HUD, garage, menus.
  - `Driving`: car controller, exhaust flames.
  - `CarSkin`: swaps part bodies for meshes or imported models.
  - `Traffic`: NPC cars that obey red lights.
  - `Weather`: rain cycle, wet roads.
  - `Audio`, `Cutscene`, `WorldFx`, `BuildingSkin`.
- `tools/`:
  - `export_models.luau` (run with Lune) plus `make_glb.py`: export every car as a `.glb` for Studio's 3D Importer into `build/models` (gitignored).
  - `shrink_model.py`: makes a downloaded model (Sketchfab `.glb`, `.fbx`, `.obj`) fit Studio's 3D Importer. Each mesh gets at most 18,000 triangles, textures at most 1024 px, and the result is one `.fbx` with the textures inside. Run it with Blender's Python module: `pip install bpy` in a venv, then `python tools/shrink_model.py imports/car.glb`. The owner sends models by pushing them into `Games/CityLegends/imports` (GitHub takes files under 100 MB).
  - `convert_car.py` plus a layout file in `tools/cars/*.json`: the full conversion of a downloaded car for the game.
    - It removes stray objects and sizes the car in metres.
    - It cuts the steering wheel out of every mesh as its own tilted part `SteeringWheel`.
    - It makes the road wheels into FL/FR/RL/RR parts in a `Wheels` group.
    - It names windows `SeeThrough_*` and bakes plain colours into tiny textures.
    - To find the layout numbers, render the cabin with Blender (Cycles, CPU) from the driver's eye and highlight the picked pieces.
  - `auto_car.py`: the same conversion with no layout file (`python tools/auto_car.py car.glb <real wheelbase m> out.blend ['{"front": -1, "tilt": 20}']`).
    - It finds the wheels, the steering wheel, the front and the steering tilt by shape.
    - It writes a `.blend` plus a JSON report. Always render each car from outside and from the driver's seat (steering wheel highlighted) before sending: a wrong pick turns the car back to front.
    - Meshes that get thinned out are welded at their seams first; otherwise glossy paint comes out crumpled.
    - Parts coloured by vertex colour (Studio drops those, the car comes in white) are split by colour, each with a plain colour.
    - When the steering wheel pick is wrong, set `DEBUG = True` to print the candidates, and pass the right one as a hint: `{"steer": [side, up, along], "tilt": 23}` (metres, as printed). A wheel that leans far back is often centred a few cm too far forward; plotting the points around it from the side shows the real centre and tilt.
  - `dial_probe.py` + `dial_fit.py`: live needles on a converted car's own dials (`CarSkin.DIAL_NEEDLES`). Probe a render pixel to find the dial texture, read the hub, two or three labels and the painted needle in texture pixels, then fit: it prints the table entry and paints the old needle out of the texture (the car then needs a new Import 3D). Check by drawing needles at 0 and at the top in a render.
  - `dial_looks.py` (run from `Games/CityLegends`): each needle car's dial design, copied from its real cluster (colours, numbers, red zone, needle, logos, second km/h scale, screens), written to `src/client/DialLooks.lua`, with preview PNGs in `build/dials`. CarSkin draws them over the car's own dials. To check one, put the preview PNG on a plane at the dial in Blender and render from the driver's eye next to the real dial.
  - `brand_marks/` (see its README): where the real makers' badges, logos and name plates are on each converted car, measured in Blender and written to `src/client/BrandMarks.lua`. CarSkin hides badge parts, covers printed logos and plates with patches in the colour round them, covers wheel caps and the steering hub, and puts our fictional emblems (BNW, Mercer, Lexis) where those makers' badges were. Cars built in Roblox lose parts and decals named badge, logo or emblem.
  - `pack_cars.py out.fbx id=car.blend ...`: several converted cars in one FBX, one group per car id, for a single Import 3D. Packs for the owner go in `imports/new_cars/` (owner, 2026-10-13: new cars in their own folder); it holds only what is still to be imported, so clear it once the cars are in `CarModels.rbxm`.
  - `take_cars.luau <place> <ids...>` (Lune, from `Games/CityLegends`): copies imported cars from the owner's saved place into `assets/CarModels.rbxm`. It takes off Blender's `.001` name endings and makes the windows two-sided.

## Build and check

These tools are not in the repo; install them first (e.g. with aftman or foreman, or from their GitHub releases): rojo, luau-lsp (plus the Roblox `globalTypes.d.luau`), and lune.

```
rojo build default.project.json -o CityLegends.rbxlx
rojo sourcemap default.project.json -o sourcemap.json
luau-lsp analyze --definitions=globalTypes.d.luau --sourcemap=sourcemap.json --no-strict-dm-types src
```

Keep `luau-lsp analyze` free of errors. Nothing can be run in real Roblox from a cloud session, so say what has and hasn't been tested.

## How the cars work

`CarSkin.apply(model, destroyReplaced, lite)` chooses the body for each car, in this order:

1. **Imported model:** `ReplicatedStorage.CarModels/<car id>` (searched recursively).
   - With `Mark_Origin` / `Mark_RefX` / `Mark_RefZ` marker parts, it is one of our exported `.glb` files. Layers are named Paint, Glass and so on, with one wheel.
   - Otherwise it is any model (Toolbox, Creator Store, bought). The generic adapter finds which way it faces from its VehicleSeat or PrimaryPart, finds the wheels from a `Wheels` folder with FL/FR/RL/RR or from wheel-like names, scales it to our wheelbase, and copies only the looks of visible parts. A `Reverse` attribute flips a model that comes in backwards.
2. **Runtime meshes:** `CarMesh.build` turned into EditableMesh parts. This needs Game Settings → Security → "Allow Mesh / Image APIs".
3. **Fallback:** the old part-built body.

- `assets/CarModels.rbxm` holds the owner's imported cars (exported from their place with Lune; Rojo puts it in `ReplicatedStorage.CarModels`). When they send a new place, re-export it: Lune can't read new Studio files directly, so first strip the `Tags` PROP chunks (bad type) from the binary. Build with Rojo 7.6.1 or newer: older Rojo drops the new MeshContent/TextureContent values and every car turns into a plain cube.
- Real size: `CarBuilder.REAL_WB` holds each car's real wheelbase in metres, at `STUDS_PER_METRE = 3`. An imported model is scaled to that wheelbase and its own wheel radius becomes the physics wheel radius.
- Imported models bring their own cabin, so ours (dash, seats, wheel, driver, arms) is hidden (`OwnInterior` attribute). Their steering wheel (an `SW` group or anything named "steering wheel") turns on our `SteerMotor`. The first-person eye sits above their `DriveSeat` at 80% of the roof height; an `EyeHeight` number attribute on the model nudges it in studs.

Traffic uses the "lite" runtime meshes first. The owner thinks the procedural cars look bad. Their plan is to insert real Creator Store car models in Studio themselves, delete the scripts inside, and put them in `ReplicatedStorage/CarModels` named after car ids.

## Rules and decisions

- **No auto-loading of Creator Store models.** Do not make the game download Creator Store assets at runtime (InsertService with hard-coded asset ids). It was blocked as integrating unvetted third-party content. Models go in by hand, after the owner has checked them.
- **Assets can't be downloaded from here.** `assetdelivery.roblox.com` needs a login (never use the owner's). The owner allowed `apis.roblox.com` in the environment (2026-10-10): search with `toolbox-service/v1/marketplace/10?keyword=...` and details with `toolbox-service/v1/items/details?assetIds=...`, then give the owner ids to insert by hand.
- **Money from the console:** `game.Players.NAME:SetAttribute("SetCash", n)` or `"AddCash"` on the server side (Studio command bar in Server mode, or the F9 server console).
- **Saving:** needs "Enable Studio Access to API Services" or a published place.
- **Git:** commit and push to `master` of ProjectOne (the vault syncs from it). Run all commands from `Games/CityLegends`. The old `ClaudeOne` repo is retired for this game (moved 2026-10-10). No pull requests unless asked.

## Open or paused

- **Sounds:** making all sounds "high quality and accurate" was paused; ask the owner before resuming. There is no real rain sound yet; it uses a filtered built-in wind. `Config.Sounds.Rain` takes an id.
- **Untested in Roblox:**
  - the new HUD (level/XP bar, analog rev counter, side buttons, daily gift card);
  - rain and splashes;
  - exhaust flames;
  - the model import and the generic adapter.
- **XP and reward numbers** in `Config.Progression` and `Config.Daily` are first guesses.
