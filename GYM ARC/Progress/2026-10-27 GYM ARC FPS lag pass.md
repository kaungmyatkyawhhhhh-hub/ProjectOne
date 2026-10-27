---
date: 2026-10-27
tags: [gymarc, progress]
status: done
---
# FPS lag pass (prompt 78)

Back to [[00 GYM ARC Home|GYM ARC Home]]. Prompt: [[2026-10-27 GYM ARC Prompt - 78 FPS lag check]].

## How it was measured
- Frame times per spot, a spike log, Roblox's ScriptProfilerService on the client (`ClientStart(player, 1000)`, `ClientRequestData(player)`, `OnNewData`), and A/B switching kinds of objects off on the client from a fixed camera.
- Scripts: ~2.7 ms a frame on this PC (heartbeat ~2 ms, physics ~1 ms). Looking at the empty sky = 59 FPS, so the frame rate is limited by **drawing the world** (render), not scripts. Studio numbers on this PC swing a lot between runs (the same beach view 30 vs 53), so there's no clean before/after number.
- A/B at the beach (base ~30): no NPCs 55, no see-through parts 46, no particles 40, no SurfaceGuis 39, no lights 37, no shadows 35.

## Fixed
- **Far NPCs not drawn** (`NpcCullingClient`): beyond 110 studs an NPC is fully see-through on this client (LocalTransparencyModifier, also new pieces), back when closer; distance only. The far-tier effects sweep only on a tier change (it walked every far NPC every 2 s).
- **MachineClient**: the per-frame loop only visits machines in use / posed / yours (list rebuilt 4x a second; it walked all 132 machines every frame); the prompt text refresh caches each machine's prompts and writes only changed text (it walked 36,287 machine parts every 2 s, an ~11 ms hitch).
- **BlobShadowClient**: no ray for a body that hasn't moved.
- **MuscleRig**: other bodies further than 45 studs refresh their stage meshes at 2 Hz (was 10).
- **SurfaceGuis**: 91 with no distance limit capped at 250 studs (MaxDistance).
- Checked: own lifting still animates (bar travels its full range); NPC lifters on screen animate (off-screen ones stay still by design).

## Left for the owner (visual choices)
- See-through parts: window glass on the far city buildings and the Powerlifting front, the Pro gym's light beam parts (Lights58), skate park glass.
- 301 lights, 1,036 Glass parts, Lighting.EnvironmentSpecularScale 0.7.
- Part of the profile was the Studio plugin "Superbullet AI Game Builder" (not in the real game).
- (owner: "make the far city and powerlifting windows swap glass for a cheaper material") Glass -> SmoothPlastic: far city (`Backdrops`, 500), Powerlifting front (45) and shell (14). Panes at 0.1-0.3 transparency made solid, the clearer 0.5 ones keep a little see-through; reflectance at least 0.15 so they still read as windows. Each part keeps `WasGlass` / `WasTransparency` attributes (one Ctrl+Z step "Perf: glass windows to SmoothPlastic"). Looks the same from the street.
- Correction: the Pro gym "light beam parts" (ProGym.Lights58) are its big tinted window panes (FrontGlassUpper x2, EastGlass 85 studs long; SmoothPlastic, 82% see-through), not light beams.
- (owner: "change the windows on the townbuildings to smoothplastic and their color to be same as the original") `Town.Buildings`: 424 Glass parts -> SmoothPlastic, colour / transparency / reflectance unchanged (checked: 0 colours changed), `WasGlass` attribute, one Ctrl+Z step. 69 Glass parts left in the whole game. Done in the Studio opened from GABACKUP2.rbxl (owner's account rongstrix).
- (owner: "do npc count by area except for the quest npcs like coral, dante") `NpcCullingClient`: a gym regular (attribute Gym) is drawn only while you're in its area (Starter / Pro / Powerlifting / Strongman / Beach, the music areas; from the town the beach regulars still show), or within 35 studs of you. Always shown: the rivals from `Config/Rivals` (Benny, Coral, Dante), Coach Dex, the cat (the 110-stud far hide still applies). Walking into another area re-checks everyone at once (beach regulars appeared 0.09 s after arriving). Tested: Starter shows Benny, Dex, Dante, Jun, Maya, Rosa, Theo (14 hidden); Pro shows Dante, Ivy, Kira, Marcus (17 hidden); town shows the rivals + Dex (18 hidden); beach shows its regulars.
- (owner: "turn every glass into smoothplastic while keeping the original color's look by transparency and color. only turn on lights for the area ur in. connect area for pro gym and starter gym since they're able to see each other")
  - **No Glass left in the world:** the last 69 (Pump Shop 29, gym roofs 20, Starter gym 6, ...) + 48 in the far-city template `ReplicatedStorage.Backdrops.ProGymFarCity` -> SmoothPlastic, colour / transparency / reflectance kept, `WasGlass` attribute. Backups in ServerStorage left as they are.
  - **Shared areas:** `Config/Town.AreaOf(pos)` + `Town.AreaGroup` (Starter + Pro = "Gyms"); NpcCullingClient and MuscleClient use them (Starter and Pro regulars count as one area now).
  - **Lights by area** (`LightAreaClient`, new): every light in Gym / ProGym / PowerliftingGym / Town / Backdrops belongs to its area; on this client only your area's lights are on. What the server wants (NightLightService at dusk / dawn) is remembered per light: on = server wants it AND it's your area. No character (menu) = as the server has it. Studio: Workspace attribute `LightAreaStats` prints per area. Tested: in Starter or Pro 198 / 202 gym lights on, every other area 0; at the beach / town the gyms' lights off.
- **Short freezes: load during the loading screen** (owner: "how about u load while its in loading screen for textures, meshes, sounds, inventory, coach dex, store and others"; "make it so that u can only skip loading after 10 seconds"; "even if player skips the loading screen, dont stop loading the stuff")
  - New `Shared/Preload`: `Assets` = every distinct mesh + texture in the world (839), decals / particle images, every sound effect from `Config/Sounds` (not music), alter skin maps + variant maps / emblems, alter backgrounds, item art, court effects (about 1,030 items, loaded 40 at a time). `Windows` = `Kit.PrewarmAll`.
  - `Kit.Modals` registry: every Kit.Modal is listed; a window's script sets `modal.prewarm` (its refresh): Inventory (TitlesClient), Pump Shop, Store, Physique (StatsClient), Trainers, Settings. PrewarmAll builds each one and draws it for 2 frames behind the loading screen (order 100 is above every window).
  - LoadingScreen: after the body stages, LOADING THE WORLD (assets, at most `TIMING.World` = 10 s, the bar 90 -> 98%), SETTING UP (windows, at most 3 s), then LET'S LIFT. Whatever isn't done by then keeps downloading behind the game. SKIP now shows after 10 s (was 5). After a SKIP, `preloadAll` still runs once the menu is ready: every asset (no time limit), then the windows built only (never drawn over the game), one per frame.
  - Tested: the loading screen now takes about 16 s of game time in Studio (+ ~5 s before the game clock starts) on a first load: the world step uses its full 10 s downloading. Once cached each 40-item batch takes 0.06 s. SKIP: download queue busy ~12 s after skipping then 0, no window flashed, no errors. First Inventory open: worst frame 88 ms (reopen 43 ms; Studio idle worst 24 ms): the rest is Inventory refreshing on every open.
- (owner: "in physique, for the muscle ranks, use the premium font for like A,B,C,D,E") StatsClient: the six muscle rows' rank letters use `UIFonts.Display` (KeepFont). The GENES tab's grades are unchanged.
