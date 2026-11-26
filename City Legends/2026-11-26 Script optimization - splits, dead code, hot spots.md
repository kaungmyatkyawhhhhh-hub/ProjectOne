# Script optimization - splits, dead code, hot spots (26 Nov 2026)

Owner asked: "optimize the scripts". Method: `Roblox Playbook/2026-11-26 Research - Script optimization (Roblox + Luau).md`. Saved in Studio (Team Create), not published.

## 1. Script size limit (Studio caps a script at 200,000 characters)

| Script | Before | After |
|---|---|---|
| `shared/Config.lua` | 198,832 | 118,313 + `ConfigFeel` 22,236 + `ConfigSounds` 60,605 |
| `client/Driving.lua` | 195,893 | `Driving/init.lua` 117,572 + `Step` 53,578 + `Render` 32,060 |
| `client/DashGauges.lua` | 195,801 | `DashGauges/init.lua` 101,454 + `Clusters` 98,860 |

(characters with CR removed)

- Config: same table for every caller. `ConfigFeel` (Camera, DrivingFeel) and `ConfigSounds` (Sounds, all exhaust sets) are sibling modules that fill the table at their old spot, so the load order is the same. Offline Lune tests that load Config without `script` now load `ConfigFeel` themselves (`care_test`, `carlevels_test`, `pi_table`, `physics_test`; `luxe_test` got the two paths).
- Driving and DashGauges are now Rojo folders (`init.lua` + child ModuleScripts under the same name in Studio). `Driving.step`, `Driving.render` and the 16 design / live clusters moved whole. Each child gets the parent's locals once; the ones the parent changes later (state, curP, keyThrottle, blur, windDof, nitroFill, KMH) are read through getters, so they see the live value as before. No require cycles (children only get values passed in).
- Other scripts over 150,000: `client/CarSkin.lua` 159,286 (code, next to split if it grows). Data, left alone: `YangonStreetLife` 184,977, `YangonStreetLife2` 185,096, `YangonStreetLife3` 185,044, `RivieraLanes` 174,259, and 22 of the `YangonLanes1to1_*` files (151k to 161k).

## 2. Dead code removed

- `MainMenu.lua`: the old CARS page `buildCars` (360 lines; the CARS tab opens the HUD garage since 26 Nov), `carsRefresh`, the favourites loader (`favs`, `loadFavs`: only the old page read them), `spotById`, and the requires only that page used (`CarStats`, `CarCare`, `TrailerClient`, `CareClient`; all still loaded by Main.client and DealerMenu). MainMenu 122,109 -> 105,825.
- Scan of every top-level local function in `src`: no other function is unreferenced. `shared/CrateRules.lua` is required by nothing, but it is the owner-approved crate data waiting for the crate code: kept.
- Seen in Studio, not changed: `Client` holds two `SVJClusterArt` ModuleScripts (same size). Rojo makes one.

## 3. Runtime hot spots

How: `ScriptProfilerService:ClientStart(player, 1000)` from execute_luau in Play (its TotalDuration is in seconds), 20 s of full throttle from the spawn on the straight avenue, after the car starts rolling. The client's scripts are about 5-6 ms of an 18-20 ms frame in Studio; the rest is render and physics.

Before (one 20 s run, ms per frame): Traffic.update 1.89, Driving.step 0.51, YangonKitStream 0.35 (tile building, time-budgeted at 3 ms), Driving.render 0.33, YangonStreetLife 0.28, WorldFx light LOD 0.25, LookFx fog 0.18, YangonRoadside 0.16, Challenges 0.11, PedHits 0.09, LangUI 0.08, Minimap 0.06. 53.4 FPS.

Whole runs are not comparable: a second run moved 1,583 studs instead of 1,072, built twice as many tiles (KitStream 0.72) and met racers (48.3 FPS). So the fixes were measured A/B in one Play: the new code with a switch, on and off every 2 s for 24 s of driving, timed with `os.clock`:

| System | Off (old) | On (new) | Change |
|---|---|---|---|
| Traffic.update | 2.144 ms | 1.884 ms | -0.26 ms (-12%) |
| ... of which BulkMoveTo | 1.179 ms | 0.919 ms | -0.26 ms (-22%) |
| YangonStreetLife walkers | 0.320 ms | 0.254 ms | -0.07 ms (-21%) |
| FPS in Studio | 53.1 | 54.2 | +1.1 (noisy) |

Fixes:
- **Traffic:** `BulkMoveTo` was over half of `Traffic.update` (about 40 microseconds per car moved; ~25 cars within 380 studs, only ~8 of them in front of the camera). A car behind the camera and more than 40 studs away now gets its transform every 3rd frame, like a far car. Its driving logic still runs every frame (cut-ups, gaps unchanged).
- **Walkers:** a walker behind the camera and more than 20 studs away is posed at the far rate (0.25 s).
- **Raycast filters:** Driving step (ground ray), Driving render (camera ray) and Challenges (air ray) set `FilterDescendantsInstances` only when the car or character changes, not every frame. Too small to measure alone.
- Server per-frame loops (Main income, Activities, Care, Doors) already run every 0.1-0.5 s; MallMovers / Hotel only loop during a move. Nothing to fix.
- Not changed (owner's call): KitStream builds tiles up to 3 ms a frame while driving (`FRAME_MS`); a lower budget on `LowEnd.on` would help cheap phones but makes buildings appear later. LookFx (0.18-0.27 ms: one 1,400-stud ray and the fog holder every frame) could probe every 2nd frame.
- Not done: `--!optimize 2` / `--!native` (not measured; native only helps on the server and Android).

## Checks in Play (test store `CityLegends_test`, put back on `CityLegends_v1` before saving)

No script errors. Main menu opens, CARS opens the garage, drive, gauges (DashGauges.Clusters runs), F out of the car, sprint on foot (WalkSpeed 16 -> 25.6). Studio scripts match the repo (length and hash).
