# City Legends

A Roblox night-city driving game. The code is in this vault, folder `Games/CityLegends`; its `CLAUDE.md` has the full technical notes.

## Features so far
- **City:** a big night city with traffic that stops at red lights, and a tunnel intro cutscene ("CITY LEGENDS").
- **Driving and money:** you earn money by driving and by cutting up traffic, with combos. You buy cars in the garage.
- **Cars:** 55 cars in 3 tiers (Starter, Mid, High), remade 2026-10-10 from the owner's list of real cars. Names are close look-alikes (e.g. "BNW M3 F80", "Toyoka Land Cruzer 200", "Lambrini Urus"). Free starter: Suzaki Swiff (`suzaki_swift`).
- **HUD:** a Highway Legends-style HUD with level/XP bar, rev counter, cash, side buttons and a daily gift.
- **Weather:** a rain cycle with wet roads, plus blue exhaust flames.
- **Sounds and lighting:** a full soundscape and night lighting.

## Decisions
- Car names stay fictional but close enough to recognise (no real brands or badges).
- The cars Claude generated from code didn't look good enough. Plan: use real car models from the Creator Store, inserted by hand in Studio. Delete their scripts and put them in `ReplicatedStorage/CarModels`, named after the car id.
- No automatic downloading of Creator Store models by the game.
- Money can be set from the server console: `game.Players.NAME:SetAttribute("SetCash", amount)` (or `"AddCash"`). Use the Studio command bar in Server mode, or the F9 server console.
- Claude sends the game as a place file (`CityLegends.rbxlx`) after each change.
- Never share Roblox or alt account logins or cookies with Claude (offered once, declined).
- Car looks can be inspired by real cars, but names and badges stay fictional.

## How cars are picked (in order)
1. A model in `ReplicatedStorage/CarModels/<car id>` (any Creator Store model works; add a `Reverse` attribute if it faces backwards).
2. Built-in 3D meshes. Needs Game Settings → Security → "Allow Mesh / Image APIs".
3. The old block-built car.

## Good to know
- Saving progress in Studio needs "Enable Studio Access to API Services" (or a published game).
- Claude can't download Roblox models or test in real Roblox from a cloud session. It can search the Creator Store.
- There is no real rain sound yet (it uses filtered wind). A sound id can go in `Config.Sounds.Rain`.

## To do / open
- Insert and test real car models for each car.
- Test in Studio: new HUD, rain, exhaust flames, model import.
- Sound quality upgrade (paused: Claude asks before resuming).
- Find a real rain sound.
- Balance the XP and reward numbers.

## Car fixes (2026-10-10)
- Cars are now real-world size (real wheelbase, 1 m = 3 studs).
- Imported cars use their own interior and steering wheel; the script's dash, wheel and driver are hidden.
- First-person camera sits at the model's driver seat. To nudge one car's camera: select the model in `CarModels`, add a Number attribute `EyeHeight` (e.g. `0.3` up, `-0.3` down).
- A model's steering wheel only turns if it's in a group named `SW` or has "steering wheel" in its name.
- Imported cars are saved in the game code (`Games/CityLegends/assets/CarModels.rbxm`).

## Later (owner will say when)
- **Future Ford cars:** use this video as the reference for Ford dashboard and interior: https://www.youtube.com/watch?v=HMKEusrwO6w (Claude can't open YouTube; ask for screenshots when starting).
- **Dash clusters (2026-10-10):** Lamborghini cars get a round rev-counter cluster, all others a Toyota-style screen with an analog speedometer.
- **Unique dashboards (2026-10-11):** every car should get its own dashboard, like a real one: working needles, screens, glowing colours, and a start-up sweep when the car starts. First one: Ferrari 458 (`ferrara_458`), built from the owner's reference (yellow rev counter, temperature + fuel screen left, speed + clock screen right). The owner will add the 458 model and describe the other dashboards later.
- **Aventador LP700-4 (`lambrini_lp700`) reference:** https://www.youtube.com/watch?v=F-UK1tSbwvg ("Lamborghini Aventador LP700-4 SPRINT 0 - 353 km/h TOP SPEED", real car). Claude can't watch videos; ask for dashboard screenshots. In-game top speed is already 217 mph (~350 km/h).

## Driving feel (2026-10-11, to match Highway Legends)
- Body leans outward in turns, nose dips on braking, squats on acceleration.
- Steering a little slower than before.
- Less grip, closer to real life; slightly slippery on hard launches.
- Outside camera shakes a little; first-person view stays steady (only crashes jolt it).
- **Dashboards built (2026-10-11):** LP700 Aventador (Sport screen), Ferrari 458, 330i (BMW digital Live Cockpit), M3 E92 (classic BMW like M5/M6), CLA 45 (AMG twin dials + PRNDM screen), Supra MK4 (TRD triple), Toyota (Camry, Crown, Land Cruiser, Alphard: power meter + km/h speedo). Other cars use their own needles or the generic dashboard.
- **Roster changes (2026-10-11):** E-Class W212 removed; W213 renamed to plain E200 / E300 / E400 (`bentz_e200/300/400`). Rolls Phantom replaced by Cullinan (`rolls_cullinan`, SUV). LP570 shares the LP560 model and interior (`CarBuilder.MODEL_ALIAS`). EVs changed to what the store has: BYT Dolphin EV (`byt_dolphin`), Kio EV6 (`kio_ev6`), BYT Seal EV (`byt_seal`). 52 cars now. Added 9 (2026-10-11, RX-7 in Starter): S63 W222, Maybach S680, Boxster 718, Murcielago LP640, RX-7, AMG GT63 S, Corvette C7, Corvette C6, Camaro SS: 61 cars.
- **Cars with models (2026-10-11):** 29: the first 16 plus CLS 63 S, Challenger, LX570, Panamera, LP570 (own model now), F430, R8, 12C, SLS, 911 GT3, Urus, Brabus G63, Wraith.
- **Cars with models (2026-10-12):** 46. Added G63, Corvette C7/C6, X6, Camaro, E200/E300/E400, Kio EV6, RX-7, new Brabus G63, GT-R, DB9, Vantage, LP750 SV, Murcielago LP640, LFA, Maybach. The owner sends places by pushing them into `Games/CityLegends` with Obsidian Git (Git user name/email had to be set on the PC first).
- **Interiors and clusters (2026-10-12):**
  - The G63 (`bentz_g63`) must look like the older 2015 G63 (W463). Don't give it the Brabus G63 interior: the Brabus is the newer model. It gets its interior from a 2015-era G63/G65 store model (candidates to insert).
  - The E200 and E300 are W212. They need a real W212 interior and cluster, not the CLS (W218) one. W212 cluster built: five round chrome dials (temperature, rev counter, big speedometer with screen, clock, fuel). Interior: from a W212 store model (candidates to insert).
  - Interior swaps: 911 GT3 ← Panamera Turbo S, X6 M Sport ← M5 E60 (same BMW classic cluster), LP560 ← LP570.
  - New clusters: Gallardo seven-dial for LP560 and LP570, W213 digital widescreen for the E400, AMG needles with "V8 BITURBO" for the CLS 63 S (and the G63). The EV6 and 330i clusters sit higher.
  - The E400's Mercedes steering wheel seems fused into a bigger interior mesh, so it can't turn by itself. The owner was asked to check in Studio and rename it `SW` if it is a separate part.
- **More clusters (2026-10-12):** needle clusters replace the digital one on the DB9 and Vantage (Aston: speedometer clockwise, rev counter counter-clockwise), the SLS (AMG twin dials, 220 mph) and the C6 (speedo, rev counter, four small gauges). New: Urus (built from the owner's real-Urus photo: round rev counter, STRADA, big gear letter), Murciélago LP640 (rev counter left, speedo right, four small gauges), C7 (Sport-theme screen with a round rev counter, analog speedo left, fuel and temperature right).
  - Urus hands fix: its steering wheel was read as small and sideways, so the hands gripped near the centre.
  - The SLS interior is part of its low-quality body mesh, so it needs a donor. The Lexus LFA will be replaced with a better store model. Candidates go into ServerStorage › InteriorDonors with the same Command Bar insert as the W212 and G63 ones.
- **Sketchfab models (2026-10-12):** the owner pushes the downloaded `.glb` into `Games/CityLegends/imports`. Claude shrinks it with Blender (running on Claude's side, `tools/shrink_model.py`) and pushes back a `_roblox.fbx` for Studio's Import 3D. A small model after import is fine: the game scales cars to real size.
- **G63 cluster (2026-10-12, owner's photo of the real 2015 G63):** speedometer left, rev counter right (red from 6, AMG), small fuel and temperature dials inside them, thin needles (white speed, red revs), P R N D + green C strip, trip screen, clock and outside temperature.
- **New G63 model (2026-10-12):** shown in game as "Mercer G63" (the "2019" was removed from its name). the owner sent a Sketchfab GLB of a 2017 G 63 AMG (the old W463 body and interior, the same as 2015). Claude converted it to `imports/2015_g63_roblox.fbx`:
  - 24 parts, about 94,000 triangles;
  - the steering wheel cut out of the interior so it turns;
  - the wheels as FL/FR/RL/RR in a "Wheels" group;
  - windows named `SeeThrough_*` so the game keeps them see-through.
  - The GLB was tiny in Studio because of a stray sphere in it. It replaces the whole `bentz_g63` once the owner imports it in Studio.
- **Ferrari 599 GTO (2026-10-12):** the owner sent a Sketchfab GLB. It is converted to `imports/2010_ferrari_599_roblox.fbx`:
  - colours kept (red with a black roof);
  - the steering wheel turns;
  - 23 parts.
  - The cluster is "Ferrari599", from the owner's photo of the real one: a screen on the left with the speed in big digits (mph, km/h under it), the big yellow rev counter in the middle, the black 20–220 mph speedometer on the right, thin red needles, carbon surround.
  - Cars with no seat in the model now put the driver's eye about 63 cm behind their own steering wheel.
- **Cockpit FOV (2026-10-12):** the owner asked to fix the FOV. The interior view is now 64 (it was 74), and it only widens a little with speed, so the cabin no longer looks stretched. The chase camera is unchanged.
- **599 and F430 (2026-10-12):**
  - The F430 gets the same 599 cluster.
  - Both clusters are moved down over the car's own cluster: per-car `CLUSTER_NUDGE` in Driving. The 599 value is from the owner's screenshot; the F430 value is estimated from its gauge face and not yet checked.
  - The 599 uses the F430's steering wheel (`CarSkin.STEER_DONOR`).
- **BMW clusters (2026-10-12):**
  - The M5, M6 and X6 cluster panel is grey instead of black (style `BMWClassicGrey`); the M3 stays black.
  - The M5 cluster is 25% bigger.
- **Don't save over CityLegends.rbxl (2026-10-12):** the owner saved their place over it, and that undid a new build (older scripts). Their imported 599 is now in `assets/CarModels.rbxm`, so it is in every build. Their own places go in as `CityLegendsCars.rbxl` (or any other name), and Claude copies new cars from there.
- **Roster and clusters (2026-10-12):**
  - Removed, at the owner's request: Gallardo LP560-4, CLS 550, CLS 55 and E200. That leaves 57 cars. Saved games simply drop them.
  - The new 2015 G63 is in CarModels, from the owner's CityLegendsCars.
  - Cockpit FOV is a fixed 64 in every car at every speed.
  - Cluster line-ups:
    - 599: on the eye line to its own cluster, from its 3D file;
    - F430: up 0.14 studs and 1.2x bigger;
    - LP570: up 0.15 studs and 1.25x bigger.
  - Open: the G63 shows a dark red screen in first person. Its model looks right from that eye position, so the cause is not found yet.
- **Same camera height and fixes (2026-10-12):**
  - Every car with its own steering wheel puts the first-person eye 0.8 studs above the wheel centre (owner: every car the same height).
  - The hidden part-built body's red `TailGlow` light is turned off under imported models. It lit the cabins red (pink mirrors and wheels), and is the likely cause of the G63's red screen.
  - The windows of converted Sketchfab cars (`SeeThrough_*`) are two-sided (MeshPart.DoubleSided set in CarModels.rbxm), so the windscreen shows from inside.
  - The F430 cluster is 1.8x bigger to cover the gap down to the hub.
- **Roster update (2026-10-12):** 63 cars.
  - Added:
    - Mazdo RX-8 (Starter);
    - BNW M8 Gran Coupe, BNW X7, Xiaomo SU7 (Mid);
    - Lexis LX700 and Mercer GLE 53, in the G63's grade (Mid, about $245–250k next to the G63);
    - BYT Yangwong U8 (Mid, next to them).
  - The Maybach S680 became the Maybech 57S. Same id `bentz_maybach`, so owners keep it; the S680 model was removed.
  - Removed: LX570 and its model.
  - The new cars have no imported models yet and use the generated bodies. The owner can send Sketchfab GLBs to `imports`.
- **Sketchfab batch (2026-10-12):** the owner sent 24 GLBs. `tools/auto_car.py` converts them without a hand-made layout file. It finds the wheels, the steering wheel (a ring about 37 cm across with no twin across the car, dashboard just ahead and empty space behind), the front, and the steering tilt. Renders of each car are checked from outside and from the driver's seat.
  - Which file goes to which car:
    - Maybach 57S → `bentz_maybach`; GLE 63 Coupe (2016) → `bentz_gle53`; S65 W222 → `bentz_s63`, renamed "Mercer S65 W222"; Brabus G700 → `brabos_g63` (owner: "the new g63 is for brabus");
    - SLS and CLS 63 → their cars; LFA, Aventador (LP700), LP750 SV and Urus replace the old models;
    - BMW 330i, 530i (G30), 540i (M5 CS file), M3 (F80 slot), M8 Gran Coupe, X6 (2020) and X7 go to their cars;
    - 718 Cayman → `porsha_boxster`;
    - LX700, U8, SU7, RX-8 (right-hand drive) and GT-R (2013 Black Edition) go to their cars.
  - Not added: BYD Sealion 7 (owner: "dont add sealion"). Not used: the second GT-R file.
  - `tools/pack_cars.py` puts several cars in one FBX (one group per car id) for one Import 3D. `tools/take_cars.luau` copies them from the owner's saved place into `assets/CarModels.rbxm`: Blender's ".001" name endings come off and windows are made two-sided.
  - Steering tilt: Studio's importer keeps a part's own turn in its pivot, so CarSkin turns a `SteeringWheel` about its pivot's axis. That fixes the 599 and G63 too. New cars also carry it in the name (`SteeringWheel_t21`).
  - Wheelbases match the files: GLE coupe 2.915 m, X6 (G06) 2.975 m.
  - Clusters for the new cars (2026-10-13), from the real cars, until the owner corrects any:
    - new designs: Maybach 57 S (two chrome-ringed dials, screen between), SU7 and U8 (wide EV screen: big digital speed, P R N D, power bar, battery and range), RX-8 (big rev counter in the middle with digital speed, fuel and temperature either side), LFA (one big rev counter, 0-10, speed and gear inside), LX700 (the same Lexus look, 0-8), 718 Cayman (rev counter in the middle, speedometer left, round screen right), GT-R (rev counter in the middle, speedometer right, fuel and temperature left);
    - existing designs: GLE 53 = AMG Biturbo; S65 and Brabus G700 = W213 wide screen; M8, X7, 530i, 540i, X6 = BMW Live; M3 = BMW Classic.
    - LP750 SV: its own cluster from the owner's photo (2026-10-13): yellow middle with a wide rev arc (2-10, red from 6), big gear letter, R 1234567 A strip, blue speed and rpm digits under it, STRADA and odometer, small yellow screens either side with bar gauges.
  - The new X6 uses its own modern cabin (owner, 2026-10-13); the M5 interior swap is gone.
  - The owner allowed deleting the original GLB files in `imports` once the cars are in the game.
- **Sketchfab cars in the game (2026-10-13):** the owner imported the six FBX files and saved `CityLegendsCars.rbxl`. All 23 cars are now in `assets/CarModels.rbxm` (56 models).
  - Cars packed several to a file came in with Blender's `.001` name endings, so the game said "couldn't find 4 wheels". The car reader now takes those endings off.
  - Studio dropped 19 tinted colours (LFA paint parts, some Urus and 540i panels, Cayman calipers). `take_cars.luau --colours` put them back from the converted files, and `auto_car.py` now bakes such colours.
  - A part named `SteeringWheel_t<tilt>` is the whole wheel. Other parts with "steering wheel" in their names (the column left in the dash on the S65, X6 and X7) stay put.
  - Steering tilt set by hand: X6 23° (same wheel as the X7), LX700 20°.
  - The original GLB files in `imports` were deleted (about 450 MB), as the owner allowed. The six `cars_*.fbx` files are kept.
- **Interiors and colours (2026-10-13):**
  - Studio's importer left every converted car's MeshParts on RenderFidelity "Automatic", which swaps in rough low-detail meshes. All car parts in CarModels are now "Precise" (it can be set in the file, not by game scripts).
  - The racing-game rips (Urus, LFA, 540i/M5 CS, Cayman) tint some parts by game-set colours that aren't in the file. They are set by hand to match the renders: Urus body-colour trim yellow, LFA paint white, base plastic black, seat belts dark, Cayman calipers red.
  - G63 (2015) black first-person screen: its whole-cabin `Interior` part was double-sided around the camera, so it now draws one side only. This is the likely cause of the earlier red screen too. Not tested in Roblox yet.
- **Car controls and units (2026-10-13, owner's list):**
  - J ignition, F start / stop the engine, Q / E shift down / up, Left Shift clutch, P handbrake (on / off; Space still works while held), T traction control, L lights, Z / X / C left blinker / hazards / right blinker.
  - The camera moved from C to V, because C is now the right blinker.
  - Keyboard players start each drive with the engine off: J, then F. Touch and gamepad players start running (they have no such keys).
  - Gearbox: the first Q / E switches to manual (7 gears, a rev limiter, engine braking, and a launch when the clutch is dropped at high revs). Settings has Auto / Manual.
  - Traction control off lets the rear slide under power. Mouse shift-lock is turned off so Left Shift is free.
  - Blinkers and lights are seen by every player: the driver's client sends them (`CarSignals` remote), the server puts them on the car as `Blinker` / `Lights` attributes, and other clients flash corner lights and switch the headlights.
  - Settings → Speed: MPH / KM/H. It changes the HUD and every cluster (dial numbers, needles, digital readouts). Units and gearbox are saved with the profile.
  - Warning lights under the HUD speedometer: blinker arrows, ENGINE OFF, (P), TC OFF, LIGHTS. The gear tag shows AT / MT.
