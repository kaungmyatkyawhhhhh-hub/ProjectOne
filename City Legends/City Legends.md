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
