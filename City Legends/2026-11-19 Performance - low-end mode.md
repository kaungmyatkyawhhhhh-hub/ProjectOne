# 2026-11-19 Performance: low-end mode for cheap phones

Owner goal (19 Nov): the game must run well on cheap Android phones. About 93% of players will be on phones in Myanmar, typically with 3-4 GB RAM and old Mali / Adreno GPUs.

## How it was measured
- Studio main place, Play on the test save (`CityLegends_test`), `PreviewPhone` on.
- Same camera at three spots:
  - P1: Myanmar Plaza, the spawn
  - P3: Sule
  - a flyover at (32712, 128, 36162)
- Streaming focus moved there on the Server.
- Normal = before any change (phone defaults: Medium render distance). Low-end = workspace attribute `TestLowEnd`.
- **Studio caveat:** in Studio the client, server and editor share one process. `GetTotalMemoryUsageMb` (~10.4 GB) and the memory tags (Instances, LuaHeap, GraphicsTexture) are the whole Studio, so they barely move. The client-only numbers are the part, light and instance counts, plus FPS. **Real phone memory must be read on a phone** (checklist below).

## Budget: what costs most (client, normal, before)

| Item | P1 spawn | P3 Sule | Flyover | Note |
|---|---|---|---|---|
| FPS (Studio PC, everything open) | 15 | 15 | 15 | worst frame 70-83 ms |
| Parts in the client's Workspace | 10,765 | 11,666 | 9,943 | streaming keeps 150k place parts down to ~10k |
| Workspace instances | 16,298 | 14,906 | 13,124 | |
| Kit-stream detail parts (`YgnKitNear`) | 1,433 | 3,903 | 2,383 | |
| **Lights on** | **346** | **352** | **344** | 284 = Persistent landmarks (Bogyoke Market 112, Myanmar Centre 144), 60 = Legends chips. Only 2 were distance-managed. 205 of them were over 400 studs away. **Biggest waste.** |
| Light shadows | 0 | 0 | 0 | already off |
| Beams (cables) | 186 | 16 | 16 | street kit power lines + LookFog |
| SurfaceGuis | 52 | 39 | 39 | landmark signs |
| Unique meshes loaded | 1,210 | 1,117 | 914 | |
| Traffic cars | 28 | 28 | 28 | |
| Street-life parts (parked cars, people) | 296 | 296 | 0 | |
| Script time (profiler, flyover) | | | Traffic.update 78 ms/s, findSpot 26 ms/s, BulkMoveTo 34 ms/s, HUD reconciler 24 ms/s | traffic is the top script |
| GraphicsTexture tag | 262 MB | 267 MB | 295 MB | whole Studio; read on a phone |

Place-wide (Edit):
- 150,757 parts, 38,505 MeshParts, 3,003 unique meshes, 330 lights.
- **24,115 roof `Texture`s on the shells**, all the same picture.
- 90 MaterialVariants with 285 unique maps of 512-1024 px.
- 13 Persistent landmark models (5,556 parts, always loaded on every client).
- Streaming: target 640, min 64, Opportunistic: right for phones, left as it is.

## After (low-end forced)

| Item | P1 | P3 | Flyover |
|---|---|---|---|
| FPS (same PC) | **60** (worst 27 ms) | **60** (38 ms) | **60** (31 ms) |
| Parts | 9,488 | 9,061 | 8,664 |
| Workspace instances | 14,207 | 11,929 | 11,420 |
| Kit detail parts | 499 | 1,595 | 1,265 |
| Lights on | **0** | **3** | **0** |
| Beams | 69 | 0 | 0 |
| Unique meshes | 1,040 | 860 | 755 |
| Traffic cars | 14 | 14 | 14 |
| Street-life parts | 160 | 160 | 0 |
| Roof Textures drawn | 0 | 0 | 0 |
| Traffic script (flyover) | 53 ms/s at 4x the frames (0.9 ms a frame, was 5.2) | | |

## What low-end mode does (`src/client/LowEnd.lua`)
- **Settings > Graphics > "Performance": AUTO / LOW-END / NORMAL**, saved as `Settings.Performance` (checked in `PlayerData.setSettings`). The row uses the existing `choices(row(...))` style.
- **AUTO:**
  - Phones (touch, no keyboard) start in low-end, because loading is the moment a 3 GB phone runs out of memory.
  - After 25 s in the world, a phone that holds about 55 fps under 1,800 MB goes back to normal.
  - Any device under 28 fps goes low-end.
  - The result prints as `[LowEnd] auto: ...`.
- **When on:**
  - `WorldFx.qualityScale()` is capped at 0.5. That gives 14 traffic cars (Main's clamp is now 0.5), fewer pedestrians and street life, shorter light ranges, no light shadows, fewer particles, marks and rain drops, and no own-headlamp shadows or haze.
  - The Graphics Low look (no global shadows, glow, sun rays or fog; low reflections). Bloom, SunRays, depth of field and motion blur are off.
  - Render distance Low (x0.5 on the kit stream and the light LodRange).
  - Terrain decoration off.
  - The shells' roof Textures are hidden (`LocalTransparencyModifier`).
- **Good PCs:** unchanged. Checked on the `CityLegends_v1` Play: no low-end, render distance 1, Bloom and shadows on.
- **Studio:** set workspace attribute `TestLowEnd` true in Edit before Play (forced from the start), or set the player attribute `TestLowEnd` true / false in Play (live switch, tested both ways).

## Waste fixed for everyone
- `WorldFx` now manages the landmark lights by distance (`LodRange` 320) and the Legends chip lights (160). Before, about 344 lights were on from anywhere on the map.

## Not done / not proven
- **Texture memory:** the MaterialVariants (285 maps) and GraphicsTexture could not be split from the editor in Studio. They are not swapped to plain materials. Read GraphicsTexture on a phone first. If it is over ~300 MB, the next step is plain materials on low-end.
- Traffic counts change only on the next join. A live switch changes the look, lights, render distance, roofs and effects at once.
- The Settings row was not screenshotted. The Return key in Play opened Goals instead, and MCP clicks don't reach the game. The row is built by the same `choices(row())` code as Quality.
- A real cheap-phone test is still needed after publishing (checklist below).

## Owner's phone test (after publishing)
1. Open the game on the cheapest Android phone you can get. Wait on the menu for 40 seconds, then drive from the spawn to Sule.
2. Open Settings > Graphics. Check that **Performance** says AUTO. In the dev console's Log tab (step 3), the line `[LowEnd] auto:` shows whether it chose low-end.
3. Open the dev console: type `/console` in chat, or press F9 on a keyboard (Shift+F5 shows FPS on PC). Go to the **Memory** tab, **Client**. Write down **Total**, then **GraphicsTexture**, **GraphicsMeshParts**, **Instances** and **LuaHeap**.
4. At the spawn, at Sule and on a flyover: note the FPS and whether it stutters. Then switch Performance to NORMAL and note the FPS again at one spot.
5. Send back the numbers from steps 3-4 (or screenshots of the Memory tab), the phone's name and RAM, and anything that looks broken in low-end mode.

## Shots
- `2026-11-19 Performance - P1 Myanmar Plaza - normal.jpg` / `- low-end.jpg`
- `2026-11-19 Performance - P3 Sule - normal.jpg` / `- low-end.jpg`
- `2026-11-19 Performance - flyover - normal.jpg` / `- low-end.jpg`

Saved in Studio (version 1498); not published.
