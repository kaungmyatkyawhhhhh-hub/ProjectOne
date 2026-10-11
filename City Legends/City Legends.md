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
- **Roster changes (2026-10-11):** E-Class W212 removed; W213 renamed to plain E200 / E300 / E400 (`bentz_e200/300/400`). Rolls Phantom replaced by Cullinan (`rolls_cullinan`, SUV). LP570 shares the LP560 model and interior (`CarBuilder.MODEL_ALIAS`). EVs changed to what the store has: BYT Dolphin EV (`byt_dolphin`), Kio EV6 (`kio_ev6`), BYT Seal EV (`byt_seal`). 52 cars now. Added 9 (2026-10-11): S63 W222, Maybach S680, Boxster 718, Murcielago LP640, RX-7, AMG GT63 S, Corvette C7, Corvette C6, Camaro SS: 61 cars.
