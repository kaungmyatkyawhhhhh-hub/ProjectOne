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
- Testers can own every car from the same server console: `game.Players.NAME:SetAttribute("UnlockAllCars", true)` (2026-10-22).
- Unlock everything (2026-10-23, owner): `game.Players.NAME:SetAttribute("UnlockEverything", true)` gives every car, the level every car needs (20), every penthouse and hotel suite, both island house types, every chauffeur contract, the Black VIP card and every flex item. Cash stays as it is (use SetCash).
- Driver hands (2026-10-22): in the in-car camera the forearms and hands stay on the wheel (only the part near the camera is cut off); if the avatar can't load, plain default arms are used.
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
- **Future Ford cars:** use this video as the reference for Ford dashboard and interior: https://www.youtube.com/watch?v=HMKEusrwO6w (Claude can watch it with the watch plugin through Gemini, from 2026-10-16; screenshots still help for exact details).
- **Dash clusters (2026-10-10):** Lamborghini cars get a round rev-counter cluster, all others a Toyota-style screen with an analog speedometer.
- **Unique dashboards (2026-10-11):** every car should get its own dashboard, like a real one: working needles, screens, glowing colours, and a start-up sweep when the car starts. First one: Ferrari 458 (`ferrara_458`), built from the owner's reference (yellow rev counter, temperature + fuel screen left, speed + clock screen right). The owner will add the 458 model and describe the other dashboards later.
- **Aventador LP700-4 (`lambrini_lp700`) reference:** https://www.youtube.com/watch?v=F-UK1tSbwvg ("Lamborghini Aventador LP700-4 SPRINT 0 - 353 km/h TOP SPEED", real car). In-game top speed is already 217 mph (~350 km/h).
  - **Cluster in the video (Gemini watched it, 2026-10-16):** round digital rev counter 1-9 (x1000 rpm) with a red needle, redline past 8,500; big red gear number with italic digital km/h speed under it, lower right inside the dial; centre of the dial shows warnings, drive mode "Corsa" and the odometer; left screen: clock, date, outside temperature; right screen: temperature bars and fuel range; angular matte-black hood. Clear from 0:00 to 0:56.

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
  - F start / stop the engine (no ignition key: the owner said not to add one), Q / E shift down / up, Left Shift clutch, P handbrake (on / off; Space still works while held), T traction control, L lights, Z / X / C left blinker / hazards / right blinker.
  - The camera moved from C to V, because C is now the right blinker.
  - Keyboard players start each drive with the engine off (press F). Touch and gamepad players start running. The dash is always on.
  - Gearbox: the first Q / E switches to manual (7 gears, a rev limiter, engine braking, and a launch when the clutch is dropped at high revs). Settings has Auto / Manual.
  - Traction control off lets the rear slide under power. Mouse shift-lock is turned off so Left Shift is free.
  - Blinkers and lights are seen by every player: the driver's client sends them (`CarSignals` remote), the server puts them on the car as `Blinker` / `Lights` attributes, and other clients flash corner lights and switch the headlights.
  - Settings → Speed: MPH / KM/H. It changes the HUD and every cluster (dial numbers, needles, digital readouts). Units and gearbox are saved with the profile.
  - Warning lights under the HUD speedometer: blinker arrows, ENGINE OFF, (P), TC OFF, LIGHTS. The gear tag shows AT / MT.
- **Driving feel (2026-10-13, owner: "jerk feeling", "slide don't slip", no redline at top speed, feel like a real car):**
  - 7 gears with a torque curve. Every shift cuts the drive for 0.2 s (0.1 s for a manual shift) and it comes back with a kick: the body rocks and the driver's head is pushed back.
  - The automatic shifts near the limiter flat out, early when cruising, and kicks down when you floor it.
  - Each car's power is worked out so its 0-60 mph matches its real time. Its own air drag makes it reach its real top speed in 7th gear at 88% of the revs, so it never hits the limiter there. (Before, cars topped out at about 75-80% of their listed top speed.)
  - No more running burnouts: with traction control on the tyres just bite. Wheelspin smoke only comes for a moment on a real launch (traction control off and flooring it from a stop, or a clutch drop). Sliding in turns and drifting are unchanged.
  - The brakes bite in over a moment. The body sits on springs (dives, squats, leans and settles). In the cockpit the driver's head moves with the g-forces.
  - Sound (owner): a loud tyre screech pulling away hard (first ~12% of top speed, quieter with traction control on), on a launch, and a short chirp when a hard 1st-3rd gear shift kicks in. It's sound only, with no smoke. Wind noise for your own car starts at walking pace and roars at speed.
  - Launch control (automatic): hold the brake and floor it at a stop, the revs hold at about 60%, then let go of the brake to launch.
  - Starting the engine (F) switches on the dash (with its needle sweep) and the headlights. Stopping it switches them off. Before the first start, the dash and lights are dark. L still toggles the lights while running.
- **Gears, EVs, reverse (2026-10-13, owner: revs climbed too fast in 3rd-5th, EVs one gear and silent, reverse too slow):**
  - Real gearbox spacing. Each gear reaches 30/45/58/69/79/89/100% of top speed (at 88% of the revs). Each higher gear pulls less, by its ratio, so acceleration falls off with speed like a real car. Checked in a simulation against the real LP750 SV: 0-124 mph 8.4 s (real 8.6). Every car reaches its full top speed in 7th at 88% of the revs, held there by a top speed limit.
  - Electric cars (`Electric = true` in Cars: Dolphin, EV6, Seal, SU7, U8): one gear "D", full pull up to about 35% of top speed then fading, no shifts, no engine sound (wind and tyres only), no exhaust pops. F switches them on silently. Q / E do nothing on them.
  - Reverse: up to a third of top speed (35 mph at most), with a brisker pull.
  - Cars still without a real model: BYT Seal EV, Toyoka Land Cruzer 300, Dodger SRT, Bentlee Continental GT, Bentlee Bentayga, Rolls Royal Phantom.
- **Roster (2026-10-13):** 62 cars.
  - BYT Dolphin EV removed; owners lose it from their saves.
  - Mercer GT63 S renamed "Dodger SRT". It keeps the id `bentz_gt63s` so owners keep it, and takes Charger SRT Hellcat-like stats: 196 mph, 0-60 in 3.6 s, wheelbase 3.052 m.
  - Rolls Royal Cullinan renamed "Rolls Royal Phantom". It keeps the id `rolls_cullinan`, becomes a Sedan, 0-60 in 5.1 s. Wheelbase 3.772 m, because the owner's model is the Phantom Extended.
- **New cars (2026-10-13, owner: "New car SL65 amg and M4"):** 65 cars.
  - Mercer SL65 Black Series (`bentz_sl65bs`, High, $700,000, 199 mph, 0-60 in 3.8 s) and BNW M4 F82 (`bnw_m4_f82`, Mid, $100,000, 174 mph, 4.1 s).
  - Nisun Skyline R34 GT-R (`nisun_r34`, Mid, $180,000, 165 mph, 4.9 s): its model came in the same push, so it was added as a new car too.
  - Real models for 6 more cars from the same push: Dodger SRT (a Charger Hellcat), Bentlee Bentayga, Rolls Royal Phantom, Rolls Royal Wraith, BYT Seal and Toyoka Land Cruzer 300. Still without a real model: Bentlee Continental GT.
  - Cluster looks, taken from the real cars until the owner sends photos:

    | Cluster style | Cars |
    |---|---|
    | AMG twin dials | SL65 |
    | BMW classic | M4 |
    | GT-R | R34 |
    | Aston-style twin dials | SRT, Bentayga |
    | Maybach chrome dials | Phantom, Wraith |
    | U8 wide screen | Seal |
    | Toyota | Land Cruzer |
- **Lighting (2026-10-13, owner: "Make all of the game lighting way better"):** a rainy neon night look, like Highway Legends.
  - The base light is now a dimmer, bluer moonlight, so street lamps, neon and headlights carry the scene. The moon sits a little off overhead, so buildings cast long, crisp shadows.
  - Glossy paint and wet roads reflect the city more.
  - Bright things get a wider glow (bloom): lamps, neon and lights, but not paint.
  - The colour grade has more contrast and colour, with cool shadows. The far city fades into a deep blue haze, and faint moon rays shine through the towers.
  - Street lamps are warmer and about twice as bright, with a wider pool of light on the road. Lamps within ~170 studs of the camera cast real shadows (poles, cars, players), but not on low graphics or on phones.
  - Headlights reach further (80 studs) and are a little brighter.
  - Rain still blends its darker, greyer mood on top of all this.

- **Own clusters with live needles (2026-10-13, owner: "remove the digital cluster over it and just use the original and just add a needle", for every car that has needles; numbers readable; fix upside-down ones):**
  - Cars whose own model has needle dials now show their own cluster. Our screen over it is gone, and a lit red needle with a dark hub turns on each speedometer and rev counter (`CarSkin.DIAL_NEEDLES`).
  - The needles sweep when the engine starts and glow while it runs. A small light in front of each dial makes its numbers readable at night.
  - The old painted or modelled needles were taken out of the car files. Those cars need a new Import 3D before the old needles disappear.
  - Where a cluster had a fixed digital speed, it now shows the live speed: RX-8, LP700 and Land Cruzer 300.
  - Converted cars with needles (16):

    | Car | Note |
    |---|---|
    | R34 | |
    | SL65 | |
    | Bentayga | |
    | Dodger SRT | |
    | Land Cruzer 300 | |
    | CLS 63 S | |
    | SLS | |
    | GT-R | |
    | RX-8 | rev counter |
    | Boxster | |
    | 530i | blurry, estimated |
    | GLE coupe | blurry, estimated |
    | Brabus G63 | screen dials |
    | LP700 | screen rev counter |
    | 2015 G63 | |
    | 599 | |

    The 2015 G63 and 599 clusters had been built from the owner's photos; their own clusters look the same.
  - Roblox-built cars with their own needle parts now use them instead of our screen: M3 E92, M5 E60, M6, E300, E400, LP640, Alphard. These were already on their own needles: Camaro, Challenger, RX-7, 350Z, Panamera (and GT3), Belta. Their dial pictures can't be seen from here, so needle sweeps there are a general 240 degrees.
  - Part needles turned the wrong way (counter-clockwise); fixed.
  - Kept as they were: digital clusters (330i, M8, X6, X7, 540i, S65, LX700, LFA, SU7, U8, Seal, LP750, Urus, Maybach, Phantom, Wraith), cars whose model has no needles to work with (458, F430, CLA 45, Supra, Camry, Crown, LC200, Gallardo, EV6, Vantage, C7), and the C6 and DB9, whose needle parts aren't named as needles yet.
  - No converted car's cluster renders upside down (all checked). Ask which car if the owner still sees one.
- **M3 and M4 cabins (2026-10-13, owner: "Put the M3 E92 interior into the BMW M4 and M3"):** the M3 F80 and M4 F82 take the M3 E92's cabin, with its dash and needles (`INTERIOR_DONOR`).
- **Where new cars go (2026-10-13, owner):** converted cars to bring in with Import 3D are pushed to `Games/CityLegends/imports/new_cars/`. The folder holds only what is still to be imported, and is emptied once those cars are in the game.
- **DB9 slot gets a Vanquish (2026-10-13, owner):** the owner will send a Vanquish model for the DB9 (`astin_db9`). More new cars are coming too.
- **E400 model (2026-10-13, owner: "No new E63 S, the E63 S will be E400"):** the E63 S W213 file is the model for the Mercer E400 (`bentz_e400`). No separate E63 S car.
- **Third batch (2026-10-13):** 69 cars.
  - DB9 renamed "Astin Marlin Vanquish" (Vanquish model, 201 mph).
  - Camaro renamed "Chevo Camaro ZL1" (ZL1 model).
  - The V12 Vantage model replaces the Vantage's model.
  - The E63 S model is the E400's model.
  - New cars:

    | Car | Price |
    |---|---|
    | BNW 750Li | $150,000 |
    | Mercer GLS | $160,000 |
    | Mercer Maybech S680 | $1,600,000 |
    | Lambrini Countach LP400S | $2,500,000 |
  - Live needles on the Vanquish, Vantage (Aston rev counters turn counter-clockwise) and Countach.
  - Packs: `imports/new_cars/cars_13_astin.fbx`, `cars_14_luxury.fbx`.
  - Old, already-imported packs were deleted from `imports` (owner OK).
- **Dial glow (2026-10-13, owner: clusters glow too much, speed hard to read):** the dial light is now a tenth as strong (0.2) and spread wider, and the needles sit below the bloom. The old needles still show until the owner's re-imported cars (new_cars packs) are pushed in `CityLegendsCars.rbxl` and copied into `CarModels.rbxm`.
- **Our own dials over the car's dials (2026-10-13, owner: "create your own cluster and replace and remove that old cluster"):** every `DIAL_NEEDLES` car now gets our own solid round dial drawn at each of its dial spots: dark face, silver ring, white ticks and numbers on the car's own scale (red zone on the rev counter), unit text, and the red needle. It covers the old dial and its needle, so no re-import is needed for that; the speed read-outs get a dark plate. The dial light is gone (the numbers glow by themselves while the engine runs).
- **Dials copied from the real cars (2026-10-13, owner: "I want the custom cluster to look exactly like the real car"):** each of the 19 needle cars gets its own dial design (`DialLooks`), checked in renders next to the real one.
  - What is copied: face colours, rings, number positions and fonts, red/yellow zones, needle colours, logos and texts. That includes the Charger's maroon dials, the 599's yellow rev counter, the R34's white faces with orange numbers, the Brabus red rings, the SLS grey centres, AMG / BRABUS / V12 BITURBO / GTS / Lamborghini texts, and the Bentayga and G63 sub-dials.
  - Aston Vanquish and V12 Vantage: km/h round the outside and mph inside, and the Aston rev counter running backwards from the bottom, as on the real cars.
  - Numbers shrink to fit so they never overlap.
- **Mercedes G63 (2015) blue first-person screen (2026-10-13):** reported by the owner. The model's cabin renders fine from the computed driver's eye in Blender (one-sided faces), and nothing blue is in the model. It is probably the same problem as the earlier black and red screens: the camera seeing open sky, which is now blue with the new lighting. Waiting for a screenshot.
- **Third batch in the game (2026-10-13):** the owner imported `cars_13` and `cars_14`, and they are now in `CarModels` (60 models): Vanquish (DB9 slot), V12 Vantage, Camaro ZL1, Countach, E400 (E63 S model, W213 widescreen cluster), GLS, S680, 750Li. Their `.glb` files and the packs were removed from `imports`.
  - The dial-only packs `cars_10` to `cars_12` were removed too: the drawn dials cover the old needles, so those re-imports aren't needed.
  - Still to import: `cars_7_new`, `cars_8_luxury` and `cars_9_other` (SL65, M4, R34, Phantom, Wraith, Bentayga, SRT, Seal, Land Cruzer 300).
- **G63 blue screen:** gone (owner, 2026-10-13), with the drawn-dial build.
- **Clusters, Panamera, EVs (2026-10-13, owner's screenshots):**
  - **M3 E92, M3 F80, M4 F82:** they had no cluster (the E92 cabin's blank white dials). All three now get the F80 M3 cluster from the owner's photo: dark dials in chrome rings, white numbers, red needles, orange and red shift lights, small fuel and oil temperature dials, M stripes, digital speed, gear and drive modes. It sits on the E92 cabin's cluster hood.
  - **330i, 530i, 540i, X6, X7, M8 GC:** new "BMW Live Cockpit" copied from the owner's photo: black screen, two open dials glowing red that light up as they sweep, red needles, big digital speed and gear inside, clock and temperature, the M stripes with red road lines, odometers, SPORT. Each one sits exactly on the car's own cluster screen (`CarSkin.CLUSTER_RECT`, measured on each model).
  - **LX700:** new LX 700h digital meter: a big ringed rev counter with a blue sweep, digital speed and gear inside, the hybrid system indicator and fuel on the left, clock, lane picture and READY on the right. It sits on the car's own screen. From reviews: the LX 700h has a 12.3-inch digital cluster; no detailed photo of its layout was found, so the layout follows Lexus's usual meter.
  - **Panamera:** takes the 718 Boxster's cockpit (dash, wheel, seats, and its drawn dials). The GT3 still uses the Panamera's own cabin.
  - **EVs:** 0-60 in 70% of their listed time (EV6 6.6 s, Seal 5.1 s, SU7 2.0 s, U8 2.5 s), full pull to a quarter of top speed, then it fades fast. Getting near top speed takes 25-55 s.
- **Second batch in the game (2026-10-13):** the owner imported `cars_7` to `cars_9`; SL65, M4, R34, Phantom, Wraith, Bentayga, Dodger SRT, Seal and Land Cruzer 300 are now in `CarModels` (68 models). Their packs and `.glb` files were removed from `imports`; `cars_10` to `cars_12` (old needles painted out) stay in `new_cars`, optional.
  - The owner's save went over `CityLegends.rbxl` too (with older scripts); it was rebuilt with the newest scripts and all cars.
- **458 Speciale cabin (2026-10-13, owner: "I want the current 458 to have the 458 Speciale interior"):** the owner's 458 Speciale `.glb` was converted as a cabin donor `ferrara_458s` (not a roster car), packed as `imports/new_cars/cars_15_458_speciale.fbx`. The Ferrara 458 Italia keeps its body and takes the Speciale's dash, steering wheel and seats (`INTERIOR_DONOR`); its own Ferrari cluster design stays. Takes effect once the owner imports the pack and it is copied into `CarModels`.
- **458 Speciale cabin in the game (2026-10-16):** the owner imported `cars_15`; `ferrara_458s` is in `CarModels` (69 models) as a cabin donor only. The Ferrara 458 now has the Speciale's dash, steering wheel, carbon trim and seats. Checked outside Roblox: the swap runs, and a render of the pieces that carry over shows the whole cabin. The `.glb` and the pack were removed from `imports`.
- **GT3 cockpit (2026-10-16, owner):** the 911 GT3 takes the 718 Boxster's cockpit too (was the Panamera's), with the Boxster's drawn dials.
- **Watching videos (2026-10-16):** the owner pointed to `bradautomates/claude-video` (a "watch" skill: frames + transcript from a video). YouTube can't be fetched from the cloud session: the network proxy blocks YouTube's video hosts (403), and YouTube asks to sign in as a bot check, which would need the owner's account cookies (never used). Video files work: push a short `.mp4` (under 100 MB) into `Games/CityLegends/imports` and Claude pulls frames out with ffmpeg. At the owner's request the `watch` plugin is installed in the cloud session (local engine, tested on a file). It is set up again for each new cloud session. YouTube links could work through its Gemini engine if the owner adds a free `GEMINI_API_KEY` as an environment variable in the cloud environment settings (never pasted into chat).
  - **Gemini connected (2026-10-16):** the cloud environment now passes a Gemini key (Claude never sees it). YouTube links go through watch's Gemini engine: Google watches the video, not the cloud session. Tested on the Aventador video: works.
  - **Installed every session (2026-10-16, owner's OK):** `.claude/hooks/install-watch.sh` runs at the start of each cloud session (like RTK). It installs `watch@claude-video` pinned to v0.3.2 (no silent updates), installs `yt-dlp`, and writes `~/.config/watch/.env` set to Gemini with model `gemini-3.8-flash` (the default `gemini-3.7-flash` was overloaded; `gemini-2.5-flash` is closed to new users). The key in that file is a placeholder: the network proxy adds the real one. A first try without the owner's clear OK was blocked by the session's safety check.
  - **How Claude uses it:** `python3 ~/.claude/plugins/cache/claude-video/watch/0.3.2/skills/watch/scripts/watch.py "<link or file>" --question "<question>"`. Use this if the `/watch` skill isn't listed in the session. If Gemini says "high demand" (503), retry later or with `WATCH_GEMINI_MODEL=gemini-3.7-flash`.
  - **Other sites (checked 2026-10-17):** the network blocks Vimeo, TikTok, Google Drive, Dropbox, Streamable, Twitch, Dailymotion, Imgur and Reddit video. YouTube links (through Gemini) and video files pushed to the repo work.
- **No brand marks on the clusters (2026-10-17, owner, urgent: "remove the logos and badge and name"):** removed from every drawn cluster and dial: the M stripes and letter (F80 and Live Cockpit), AMG, V8 / V12 BITURBO, BRABUS, TRD, GTS and the Lamborghini script. Drive-mode words (STRADA, SPORT) stay. Real logos printed in the car models' own textures (steering-wheel badges and so on) are not touched yet.
- **LP700 cockpit and cluster (2026-10-17, owner):** the LP700 now uses the LP750's cockpit (its own looked off and blocky) and its own new cluster, `AventadorLP700`, copied from an LP700-4 0-353 km/h video: grey angular side panels, a big round rev counter (silver ring, white 0-9, red from 8.5, cyan ring, navy face), a white needle with a glowing red tip that climbs with the revs and snaps down on each upshift, slanted digital speed, a big red gear, a lime CORSA badge, clock, bars and range. No maker's name on it. The LP750 keeps its own SV cluster.
- **No real badges on the cars (2026-10-17, owner: "remove from every car in the game but for brands like bmw, mercedes, lexus make a similar but not too close but still recognizable logo"):**
  - All 41 converted cars were checked in Blender. Badge parts are hidden. Logos and names printed on the paint, name plates, wheel centre caps and the steering wheel hub are covered with patches in the colour round them.
  - BNW (BMW), Mercer (Mercedes, Maybach, Brabus) and Lexis (Lexus) cars get our own look-alike emblems where the badges were: BNW is a black roundel quartered blue and white on the diagonal, Mercer is a silver ring round a star standing on one point, Lexis is a silver oval round a mirrored slanted L. Our own steering wheel on Mercer cars has the upside-down star too.
  - The 28 cars built in Roblox lose every part, group and decal named badge, logo or emblem. Logos inside their decal images can't be checked from here (Roblox asset downloads need a login), so some may still show.
  - Data: `src/client/BrandMarks.lua`, tools in `tools/brand_marks/`.
- **Round of fixes and the bigger map (2026-10-17, owner's list):**
  - **First person:** the driver's arms are hidden in first person (they came past the camera as big grey slabs), the cabin light is much dimmer, the dashboards and dials sit below the glow (bloom threshold 1.45, screens 1.1), and the night is a little brighter (Brightness 2.3, more ambient, exposure 0.75).
  - **Tail lights on every car:** each car's own lamp parts get a red glowing copy (converted cars: measured in Blender; Roblox-built cars: lamp names, A-Chassis brake glow meshes or small red parts at the back), plus a red glow on the road. They brighten when braking and go off with the lights. 11 Roblox-built cars have their lamps only in their textures, so they get just the red glow: Camry, Crown, CLA 45, Swift, Belta, 458 (Roblox model), LP570, GT3, E300, 599, G63 (2015).
  - **"Press F to start up"** pops up when you get in with the engine off, until it starts.
  - **Traffic lights:** new far-side mast arms, a head over each lane plus one low on the pole, black backplates with a yellow border, visors, tinted lenses, a coloured glow, street-name signs and pedestrian boxes.
  - **Legends Loop:** a 6-lane highway ring round the city and the harbour (about 8 km a lap, long gentle corners, median barrier, rails, lights, signs). The east highway (through the tunnel) now joins it on its east side instead of ending at the plaza (removed). NPC traffic drives the highway too, faster than in town; only right turns at the junction.
  - **Mainland:** rocky shore with lamps, suburbs with lit houses along a street, a container port with cranes, forest, hills, wind turbines and radio masts with blinking lights, billboards along the loop and a mountain range on the horizon. The far-shore skyline moved onto the land.
  - **Grey parts:** the monorail concrete and the new median barrier are darker. Waiting for the owner to point at any other grey parts.
  - Not tested in Roblox yet.
- **Brabus Maybach removed (2026-10-18, owner):** the Maybach 57S Brabus (`bentz_maybach`) is out of the game: roster, model, and its data. Players who owned it lose it (saves skip unknown cars).
- **New cars and new models (2026-10-18, owner's "Adding new cars" folder, 14 `.glb` files):**
  - Converted with `auto_car.py` and checked in Blender renders (outside and the driver's seat). Packed as `imports/new_cars/cars_17.fbx` to `cars_20.fbx`; they work once the owner imports them and the cars are copied into `CarModels`.
  - **New models for cars already in the game:** Lambrini Murcielago LP640 and McLaran MP4-12C (were Roblox models), BNW 750Li (now the G12 750Li xDrive, real wheelbase 3.21 m) and the Mercer GLS, which is now the **Mercer Maybech GLS 600** (High tier, $1.2M).
  - **New cars (9):** Chevo Malibo LS (Starter, $18k), Toyoka Chasor Tourer V ($55k), Mercer 190E Evo II ($80k), Mercer S65 W221 ($140k), Maseroti Levanto GTS ($190k), Lexis LC500 ($240k), Astin Marlin DBX ($450k), Ferrara Californa ($650k) and Bugotti Veyrun 16.4 (Hypercar, $5M, 253 mph). Roster: 77 cars.
  - **C63 AMG coupe (2017):** not a car. Its cockpit (`bentz_c63c`, a cabin donor like the 458 Speciale) goes into the Mercer CLA 45 and the Mercer GLE 53, with the AMG cluster drawn on.
  - **In the game (2026-10-18):** the owner imported `cars_17` to `cars_20`; all 14 models are in `CarModels` (78 models). Open: the owner says most cars' wheels need fixing and most interiors are grey (screenshots asked for); the Malibu's dash came out crumpled from thinning; the C63 file has cabin and body merged by material, so only a few cabin pieces carry over to the CLA 45 and GLE until its cabin is split out.
  - Owner confirmed (2026-10-18): the LP640, 12C, 750Li and GLS 600 replace the old models of those cars. The S-Class W221 is a new car next to the S65 W222.
  - **No real badges on them either:** badge parts hidden, printed logos and name plates covered, BNW / Mercer / Lexis emblems where those badges were, wheel caps and steering-wheel hubs covered (checked in Blender renders). The S-Class turned out to be an S63, so it is named **Mercer S63 W221**.
  - **Tail lights:** each new model's own red lamp parts glow (or lamp spots picked on its rear for the Murcielago, 190E, GLS 600 and LC500, whose lamps are painted or part of a whole-car piece).
  - Converter fixes: wheels must sit out at the car's sides (the Murcielago's seats were taken for wheels), and the car is measured before its quick thinning (the Malibu's shrank into a 10 m wide car). The GLS 600's front bumper came out with a torn piece hanging down; it was cut off.
- **Big update plan (2026-10-22, owner):** fix the car models (wheels, grey interiors, C63 cockpit), an immersive camera that feels faster, getting out of the car and walking, AI police with speed cameras (limit 120 km/h) and chases, a bank to rob, towers with penthouses (GTA 5 style apartments, plus a DJ booth and party mode; no alcohol anywhere), a car stock market that looks like the owner's Flip Rush market (screenshot: live news ticker, Requests / Stalls / Flip-off, offer banner with PASS / SELL, Listings with BUY and hold-to-lowball, Stash with fees, hype and sparklines), and more GTA-style things to do (no clubs). Flip Rush is a website (`fliprush.site`); the cloud session's network blocks it, so the screenshot is the reference.
  - **Wheel problem found:** each converted wheel (tyre, rim, disc...) has several materials, but Studio makes it one part with one texture, so wheels came out painted with a single texture; the steering wheel too. The wheel meshes also took in calipers, arch liners, suspension and body bits, which spun with the wheel.
  - **Immersive camera (V cycles Immersive / Chase / Interior; Immersive is the default):** low and close behind the car, the view widens with speed (74 to 112 FOV), thrown back on launch and forward under braking, swings into turns, road buzz at speed, blur and speed lines from the screen edges. Tuning in `Config.Camera.Immersive`.
  - **Walking:** Y (or the GET OUT / GET IN button) gets out when the car is nearly stopped and back in beside it; the car stays parked. Your own Roblox avatar; dying on foot puts you back beside your car. A car from the garage puts you straight in it.
  - Not tested in Roblox yet.
  - **Police and speed cameras:** speed cameras (pole, yellow box, a 120 sign) stand along the city avenues and both shoulders of the Legends Loop. Passing one above 123 km/h: white flash, shutter, a fine ($500 + $25 per km/h over) and 1 star. Patrol cars (black Crowne Athlete with a light bar and POLICE on the doors) drive the streets and call you in if you speed past them. Wanted: 1 + stars units hunt you, following the roads from far away and driving straight at you when close and in sight, sirens and light bars on, red/blue glow at the screen edges. Stopped next to a police car for 3 s: BUSTED (6% of your cash, $500-$150k). Out of sight and 300 studs away for 9-18 s: ESCAPED (bounty $1.5k-$20k and XP). Ramming a police car adds a star; a 75 s chase adds one (up to 3). Tuning in `Config.Police`.
  - **Exhaust sounds:** the owner will add exhaust sounds per car with one sound per RPM band; Claude blends them by RPM once the owner sends the asset ids.
  - **Car stock market (styled after the Flip Rush market screenshot):** open with K or the MARKET side button. Cars trade as stock in four conditions (Barn find, Driven, Clean, Showroom) with live server prices that move every 15 s and jump on brand or class news ("Lambrini ▲ ..."). Listings: tap BUY, or hold to lowball. Stash: up to 32 units with profit and a price chart; sell to the market for value minus a fee (14%, lower with hype), or to a buyer's timed offer (no fee). Three daily requests pay 1.4-1.8x for a car in a condition or better. Hype (0-10) rises with good flips: better offers, lower fees, more lowballs land. Flip-off: 3 minutes to out-earn Slick Vinny for a cash prize. A Showroom unit can be delivered to your garage as the real car. Saved in the profile. Tuning in `Config.Market`; logic test `tools/market_test.luau`.
  - **Bank robbery:** the Legends Reserve Bank stands on city block (1, 2): steps, six columns, a marble hall with chandeliers and teller counters, and a round steel vault door at the back. On foot, hold E at the vault door for 8 s: the alarm rings, red lights flash, the door swings open for 90 s and you get 4 stars. Cash carts in the vault: hold E (2.5 s) to stuff your bag ($6k-$11k a grab, more with level, up to $60k). The loot rides with you on foot or in your car; an arrow points to the drop-off (a green beam at the corner of block (5, 0)). Lose the police, then reach the drop-off to cash in (plus 400 XP). Busted: the loot is gone. The vault then stays locked for 5 minutes. Tuning in `Config.Bank`.
  - **Car models fixed:** wheels and steering wheels came into Studio as one part with one texture (blank grey). Now one part per material. Calipers steer without spinning; arch liners and body bits stay on the body. Tiled and second-UV textures, see-through texture spots and metal maps fixed (the cause of many grey interiors). The C63 cabin is split out so the CLA 45 and GLE get its whole cockpit. Malibu dash reconverted with more detail. All 52 converted cars repacked as `imports/new_cars/cars_21` to `cars_34`; the owner must re-import all 14, then Claude copies them into `CarModels`.
  - **Luxury towers:** Aurum Residences (block 2,3; $750K, $12K a day rent), Skyline One (4,1; $3M, $45K) and The Crown (1,4; $12M, $160K). Walk-in lobby with a revolving door, concierge, sales desk (hold to buy), elevators (lobby / penthouse / roof). Penthouse at the top with real city views: TV lounge, kitchen, bedroom ("Set as home"), wardrobe, wall safe (daily rent), car showcase turntable, DJ booth with party mode, confetti popper. Roof: sky pool, telescope, helipad with a helicopter city tour. Anyone can visit; owners get the safe, a home spawn and their name on the plaque. No alcohol. Tuning in `Config.Towers`.
  - **Things to do:** 4 time-trial races (Downtown Sprint, City Ring, Zigzag, Crosstown): stop in an orange ring to start, 3-2-1-GO, checkpoints at every junction, gold / silver / bronze by average speed ($9k / $5k / $2.5k), best times saved. Delivery jobs: stop in a blue ring (Dockside or Uptown Dispatch), drive to a drop point across town before the clock runs out (pay by distance plus time left). 25 Legends chips: spinning gold chips on the sidewalks, $2,500 each and $100,000 for all of them. Tuning in `Config.Activities`.
  - Flip Rush market note: the owner sent a screenshot of the Flip Rush market (fliprush.site) as the look for the car stock market.
- **Exhaust sounds per car (2026-10-22, owner; redline changed to 15989284563 the same day):** first test on the Aventador SV LP750-4 with the owner's uploads: start-up, idle, mid rpm, high rpm, launch control, crackle, redline. Idle / mid / high are loops crossfaded by rpm (pitch follows the revs), the start-up plays on F and the idle fades in after it, launch control plays while brake + throttle are held at a stop, crackles pop on lift-off at high revs and on upshifts, and the redline loop plays on the rev limiter. Ids live in `Config.Sounds` as `Exhaust_<car id>_<Start | Idle | Mid | High | Launch | Crackle | Redline>`; any car with them uses its own exhaust. Other players hear it from your car too.
- **Car series and how you get cars (2026-10-22, owner; replaces the earlier trim idea):**
  - The garage groups cars into series (e.g. BNW 5 SERIES: 530i, 540i, M5 E60, M5 F10, M5 F90; BNW 3 & 4 SERIES: 330i, M3 E92, M3 F80, M4 F82; MERCER E SERIES: E300, E400, E63 S). The first car of a series is open from the start; each next one needs 5 more levels (level 5, 10, 15, 20). Locked cars show a lock and "LVL n".
  - From the Ferrara F430 up ($600k and over) cars are market-only: find a Showroom unit on the car market (K) and take delivery; a car later in a series needs the one before it owned (e.g. the Aventador SV needs the LP700-4). About 1 in 5 market listings is a market-only car you could unlock next, often in Showroom condition; prices run under and over value.
  - New cars: BNW M5 F10 ($145k) and M5 F90 ($165k) on the G30 5 Series model for now, Mercer E63 S ($175k) on the E-Class model (which is an E63 S). They need their own models later if the owner wants. Named "Mercer E63 S" (no AMG, the brand mark rule).
  - Series and rules live in `Cars.Series`, `Cars.MarketFromPrice`, `Cars.requiredLevel`, `Cars.previous`; the dealer and the market check them on the server.

- **High cars harder to get, garage by brand (2026-10-22, owner: "make the high cars harder to get in the market and also fit each car into the brands"):**
  - Market-only cars ($600k and up) show up less: about 1 in 12 listings is a car you could unlock next (was 1 in 5), and only about 15% of those are Showroom (the only condition that can be delivered). Other listings of market-only cars are rarely Showroom, and their asking prices run from 95% to 160% of value (mostly over).
  - The garage lists brands (BNW, MERCER, TOYOKA, LAMBRINI ...), each with its series under it. The brand is the make in the car's name (`Series.Brand` in `Cars`).
- **M5 E60 and M6 needles (2026-10-22, owner screenshot):** the red needles reached past the dials; they're now two-thirds as long (`CarSkin.NEEDLE_LENGTH`).

- **Fix list (2026-10-22, owner):**
  - Alfard: it gets the Land Cruzer 200's cluster design, placed over its own dials, and the Land Cruzer 300's steering wheel (its own has the maker's logo printed on it).
  - Land Cruzer 200: its cluster now sits over the model's own dial panel ("bring it down and match it exactly"), not above the dash.
  - The Chevo Malibo is gone from the game (roster, garage, model). Saves that owned it just lose it. Pack `cars_21` still holds it: skip it when copying cars in.
  - X6: it takes the 7 Series' (750Li) steering wheel. The fixed X6 and 750Li models are in packs `cars_30` and `cars_31`, still to be imported.
  - No logos anywhere (2026-10-22, owner: "remove all of the logo in the game"): the fictional BNW / Mercer / Lexis emblems are off too; badge spots get plain covers. On Roblox-built cars, a small logo piece in the middle of the steering wheel is taken off. Replaces the 2026-10-17 emblem decision.
  - 330i steering wheel: its own wheel came in as one part with one texture, so parts of it don't show. The fixed 330i is in pack `cars_28`, still to be imported.
  - Police: getting caught takes 10% of the cash you have, with no cap (was 6%, $500 to $150k).
  - Wider roads: lanes 16 studs (were 12). Every road, the highway and the loop are a third wider; blocks are a little smaller.

- **The west, Downtown and the islands (2026-10-22, owner: Miami / New York downtown, coastal highway over a river on a suspension bridge, private islands, casino and gem showcase, chauffeur, hotel with valets and per-minute penthouses, houses with car garages, pedestrians, time of day):**
  - **Getting there:** leave the city west (Legends Blvd, the middle road). The coastal highway climbs onto a viaduct over the harbour, the suburbs and the Legends Loop, drops into the countryside, runs through a canyon in the mountains and crosses the river on the **Legends Bridge** (lit towers, necklace lights on the cables) into **Downtown**.
  - **Downtown:** its own 6 x 6 street grid with traffic lights and traffic, glass skyscrapers, palms on every sidewalk, a skyline ring, a riverside park with a big DOWNTOWN sign. Along the beach, **Ocean Drive**: pastel art deco hotels with neon names, cafes, the promenade, the beach (lifeguard towers, parasols) and the sea.
  - **Islands:** the causeway from Ocean Drive goes to **Legends Key** (ring road, fountain, helipad), with bridges on to **Palm Isle** and **Coral Cay**.
  - **Legends Grand Hotel** (Ocean Drive, by the boulevard): valets (stop in the yellow VALET box, press Y; get the car back at the VALET stand with E), lobby, roof. Suites pay every full minute you're in the game: Skyline $2M ($2,000/min), Ocean $6M ($6,500/min), Royal $12M ($14,000/min), Presidential $25M ($30,000/min).
  - **High-Rollers Casino** (across the boulevard): scenery-only gaming floor (Roblox bans playable gambling, even with fake money), VIP cards Gold $250k / Platinum $2.5M / Black $25M (title over your head, VIP lounge, gem discount), and a vault heist (security panel, vault door, trolleys, 5 stars, up to $400k, cashed in at the bank's drop-off). `Config.Luxe.GamingFloorDecor = false` swaps the slot machines for lounge seating if the age rating needs it.
  - **Legends Gem Showcase** (on the boulevard): 19 wearable flex pieces in 6 slots (necklaces, watches, rings, earrings, shades, crowns), $15k up to the $40M Midnight Star; everyone sees what you wear. Smash-and-grab: cases (3 stars) and the Legends Heart dome ($75k, 4 stars).
  - **Chauffeur:** H (or the CHAUFFEUR button) on foot, or a gold stand. A contract per car is bought once (the owner's fleet prices: DBX $450k up to the Phantom $2.5M); rides are free after that. Pick a place; the car drives you there on the roads; SKIP RIDE / STOP HERE.
  - **Island houses:** 12 Island Villas ($4M, 4-car glass garage) on Palm Isle / Coral Cay, 6 Legends Key Mansions ($15M, 6-car garage). Hold E at the FOR SALE sign; pick which owned cars stand in the bays (E at the garage screen); E on a bay car drives it out.
  - **Pedestrians** walk the city and Downtown sidewalks, cross on red, stroll the promenade (fewer on phones).
  - **Time of day:** one full day every 24 minutes, the same for everyone: night, pink dawn, morning, day, gold sunset, violet evening (`Config.DayCycle`).
  - **StreamingEnabled stays off** (the skyline would vanish, the menu and tours move the camera far away, several systems read the world once). Distance hiding (LOD groups) and pooled pedestrians keep it lighter instead. The map is about 164,000 parts.
  - Built and checked in a Roblox emulator (Lune): the whole map builds without errors, every lane has road under it and nothing solid in it, and every chauffeur route between places is found. Not yet run in real Roblox.

- **Fixes and additions (2026-10-23, owner):**
  - Police: at most 3 cars chase you (2 patrols when you're not wanted). Every chase has a timer under the stars ("POLICE GIVE UP IN 0:40": 40 s at 1 star up to 80 s at 5); when it runs out, or you lose them, you get a small bounty ($400 to $4,000). Getting caught still takes 10% of your cash.
  - Despawn: the DESPAWN side button or the Delete key puts your car away (you get out first); G brings one back.
  - LP750: our drawn cluster is gone; the model's own cluster shows as it is (`CarSkin.KEEP_OWN_CLUSTER`). Replaces the earlier "AventadorSV" design drawn from the owner's photo.
  - Penthouse and hotel suite turntables: residents press E "Change car" and pick which of their cars is on show (saved per penthouse, `Showcase` in the save). The island houses already had this (Garage setup).
  - Less neon ("too cyberpunk"): signs mostly warm white and amber, all neon a little less saturated and bright, fewer lit roof outlines, white or warm crowns, a calmer glow, natural colour grading (no boosted saturation), a less blue night.
  - Water: deeper sea colour, a little see-through, real swell; its colour follows the time of day.
  - Mini map (bottom left, turns with the camera, zooms with speed): roads, landmarks, police, race and delivery targets. N hides it; on a phone tap it to make it bigger.
  - Driving feel: the car's turn builds up instead of snapping, grip falls off in a slide, power oversteer with traction control off, downforce on supercars, slower steering at speed, bumps on kerbs. At speed the view widens, the screen edges darken, wind and road roar rise; launches, flat-out shifts and close passes kick the screen. The cabin view gets only a light version.
  - Lighter map: about 151,000 parts (was 164,000; simpler traffic light visors).
  - Car colours (Maybach S680 interior, grey interiors, tyres, LFA steering wheel, 330i / X6 wheels): the fixed models are in the import packs `imports/new_cars/cars_21` to `cars_34`, still to be imported by the owner. The game can't change those textures; only a new Import 3D can.
  - LFA cluster (owner's photo, 2026-10-23): the real LFA screen: a white rev ring with black numbers 0-10 (squeezed below 4000, red zone 8,750-9,900), a red needle that follows the revs, the speed, unit, gear and SPORT in the middle, coolant / fuel arcs and 180°F on the left, oil temperature / pressure arcs and the clock on the right (`DashGauges` `lfa`).
  - **Legends Motors dealership (2026-10-23, owner: "add a dealership, a real location", SHOP renamed CARS showing only your cars):** a glass showroom on city block {4,2}, east of the centre, facing the city, with 8 brand zones and spinning cars, a sales desk and a DRIVE OUT bay. Press E at the desk or a car's stand to browse and buy (level locks and MARKET ONLY as before); new cars can only be bought there (within 260 studs). The CARS button (or G) lists only your own cars. Legends Motors is a chauffeur and minimap place.
- **Environment quality pass (2026-10-23, owner: "improve the quality of the environment"):** tower windows are dark glass by day and only glow at night; street, park, shore and beach lamps switch off in the morning and back on at dusk; clouds white by day; natural grass, trees, hills, grey rock mountains, concrete sidewalks and kerbs; a sandstone canyon; fuller palms with fewer parts; the far skyline is blue-grey glass. About 3,900 fewer parts.
- **Free-roam challenges (2026-10-23):** drift scoring (slide at 30+ mph; the multiplier climbs to x5 while you link the drift; straighten up to bank it as cash and XP; a crash loses it). Six speed traps (yellow-and-chrome gantries: Harbour Run, Legends Loop, Harbour Viaduct, Canyon Pass, Legends Bridge, Ocean Drive): bronze 100 / silver 140 / gold 180 mph, each new medal pays once ($750 / $2,000 / $5,000), bests saved, gantry shows the server record; they never call the police. Four jump ramps (two on the beach, the riverside park, Legends Key) pay for air time and distance. Leaderboard (top speed, best drift) on the city-centre corner, or press B. Yellow minimap blips.
