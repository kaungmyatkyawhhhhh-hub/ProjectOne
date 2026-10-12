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
