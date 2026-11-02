---
date: 2026-11-03
tags: [galaxy, lighting, progress]
status: built and tested in Studio; not published
---
# Galaxy Incremental - lighting pass (3 Nov, Claude Code)

Prompt / look: [[2026-11-02 Galaxy Incremental - Lighting pass]].
Place "Galaxy Incremental" (111654682859982, P&L Studios XP). GYM ARC was not touched.

Screenshots: `Map\screens\lighting_pass\`.
- 1-4: before / after (spawn, wide from the centre, island from the bridge, phone 667x375 on the low-end setting).
- 5-7: the tries that didn't work.

## One table: `MapConfig.Lighting`
Every lighting value lives there. `GalaxyLighting.Apply()` puts it on the game: the new `GalaxyLightingService` runs it at server start, and the map builder runs it after a rebuild. Change a number in the table and press Play to tune it.

| | Prompt | Final | Why it differs |
|---|---|---|---|
| Sun | from the Core's side, low | ClockTime 16.21, Latitude 3.25 = 25° up, from the Core toward island 1 | There is one sun for the whole map, so it comes from the Core only for island 1 (the first player's island). The Core light and each island's star light carry the "light from the centre" feel everywhere else. |
| Brightness | ~2 | **1.5** | At 2, with the Core light and the star lights, the cream floor burnt out |
| ColorShift_Top | slightly gold | (255,236,208) | The warm grade and the star lights add more gold |
| Shadows | on, softness ~0.3 | on, 0.3 | |
| Ambient / Outdoor | (45,35,70) / (85,70,120) | the same | |
| Env diffuse / specular | 0.6 / 0.8 | the same | |
| Atmosphere | density 0.25, (60,40,90), decay (25,15,45), haze 0.5 | density 0.25, colour **(96,56,140)**, decay **(40,20,70)**, **haze 0** | Haze 0.5 drew a flat dark band over the galaxy sky behind the islands (shot 5). With haze 0 the sky shows down to the horizon and far islands still fade into violet. |
| Bloom | 0.4 / 24 / 1.8 | the same | |
| Grade | contrast 0.15, sat 0.15, warm | the same, tint (255,244,228) | |
| Sun rays / DoF | none | switched off if present | |
| Core light | gold, range 60, brightness 2 | range 60, **brightness 1** | 2 blew the plaza out white (shot 7). The client's pulse adds ±18%, and a Supernova still bursts it to 8. |
| Island star light | range 20 → 32 by tier | the same, the star's colour, brightness 0.7, 14 studs above the island, no shadows | |

- **Lights in a full server:** the Core, the Core's rim spotlight, the black hole gate and 8 island stars = **11**. The boards light themselves with their neon (no lights added).
- **Brass:** #D9A441, reflectance 0.15, SmoothPlastic. Metal was tried in the map pass and showed orange-brown against the dark sky.
  - The 422 brass parts already in the saved map (old #C9902E) and 2 brass UI strokes were recoloured.
  - New pieces (islands, boards) take the new colour from MapConfig.
- **Stone:** warm cream (#E8DCC8) is unchanged.
- **Kit meshes:** checked by material and colour. Brass is SmoothPlastic, stone SmoothPlastic cream, glows Neon. Nothing was wrong.
- **Spawn:** moved to island x 4 (21 studs in front of the pair). Roblox's real starting camera still cut the titles off at x 8.5.

## Low-end devices (`GalaxyLightingClient`)
- **Who:** phones (touch, no keyboard), Roblox graphics level 1-3, or under 40 FPS over 8 s after loading. Studio switch: Workspace `TestLowEnd`.
- **What turns off:** bloom, shadows and the island star lights.
- **The fix it needed:** without shadows nothing was sun-lit, so the floor went flat grey-pink (shot 6). Low-end now uses a warmer OutdoorAmbient (150,128,120), so the stone stays cream (shot 4).

## FPS (Studio, 8 islands owned by the test owners + me)
- **Before:** 60 at the wide view, 60 at the spawn (Studio's cap).
- **After:** the first reading was 60. Later readings were **15 for every setting**, including the old lighting put back and every new piece switched off one at a time, while physics stayed at 60.
- So the drop is Studio holding its window back (it renders at 15 when not in front), not the lighting. It needs one check on a real device.
- **Not measured:** 8 real players. Studio here has one player; the other 7 islands were test owners, so all 8 islands, boards and star lights were built.

## Code
- **New:**
  - `ReplicatedStorage.Galaxy.GalaxyLighting` (ModuleScript)
  - `ServerScriptService.GalaxyLightingService`
  - `StarterPlayerScripts.GalaxyLightingClient`
- **Changed:**
  - MapConfig (Lighting, brass, spawn)
  - GalaxyMapBuilder (uses Lighting)
  - GalaxyMapClient (star lights)
- **Vault copies:** `Code\map\` (GalaxyLighting.lua, LightingService.lua, LightingClient.lua new), checked identical to Studio.

## Owner to-do
- File > Save / publish.
- In a live server, check FPS on your phone and on PC (F3 / Shift+F5) with friends in.
