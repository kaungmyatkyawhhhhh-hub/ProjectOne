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
