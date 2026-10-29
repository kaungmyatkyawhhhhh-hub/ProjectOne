# Prompt: neon only at sunset and night, plus a more realistic environment and lighting

_For Claude Code on the PC, with Roblox Studio connected (MCP). Read all of this first, then do it in parts. Owner: talk short and simple (caveman mode, see `Preferences.md`)._

## Before you start
- Read `CLAUDE.md`, `Games/CityLegends/CLAUDE.md` and `City Legends/City Legends.md`. Pay attention to "Map baked into the place", "Map ownership" and the lighting / day cycle notes.
- **The map is baked.** `CityLegends.rbxl` is the master. Never `rojo build` over it. The owner asked for this, so you may edit the baked `Workspace.City` in the open Studio place (tags, materials, lights).
- **Back up first.** In Studio, save a copy as `CityLegends_before_lighting.rbxl`. Never save over `CityLegendsCars.rbxl`.
- Owner taste:
  - realistic, not "cyberpunk" (they said the neon was too much before);
  - no logos.
- Work one part at a time. After each part:
  1. In Studio, set the time to **noon, 18:30 (sunset) and 23:00 (night)**.
  2. Take screenshots from the same 3 spots (Downtown street, the city centre, the beach) and show the owner.
  3. Run the Lune tests and `luau-lsp analyze`.
  4. Commit and push to `master`.
  5. Save the place.

## What exists now
- `src/client/DayCycle.lua`:
  - a 24-minute day with lighting keyframes;
  - `DayCycle.night(hour)` ramps 0 → 1 from 17.8 to 19.9 and back down at dawn (5.6 → 7.6);
  - it calls `BuildingSkin.setNight(n)` (lit windows) and `WorldFx.setDaylight(1 - n)`.
- `src/client/WorldFx.lua`: lights tagged **`DayOff`** (street lamps) switch off by day. **Everything else that glows (neon signs, neon strips, billboards, underlights, building trims) stays on all day.** That is what the owner wants changed.
- `src/client/Weather.lua`: rain mood on top.
- `CityBuilder.setupLighting`: the base Lighting setup.
- Other tags in use: `LOD`, `LODLight`, `TrafficLamp`, `Blink`.

## Part 1: city neon only at sunset and night
1. **Find every city glow.** Look through the baked `Workspace.City` and the venues built at start (hotel, casino, gem showcase, towers, bank, dealership, customs, challenges, plazas, billboards) for:
   - `Neon` material parts;
   - SurfaceGuis / BillboardGuis with bright signs;
   - Point / Spot / SurfaceLights on signs and trims;
   - Beams, ParticleEmitters and the like.
2. **Tag them `NightNeon`.** Do this in the baked map, and in the venue build code so venues tag their own neon. For each part, store its night look as attributes: `NeonColor` and the original `Material`.
3. **Keep these out of it** (they stay as they work now):
   - traffic lights (`TrafficLamp`);
   - car lights;
   - police lights;
   - speed camera flashes;
   - challenge gantry timers;
   - UI;
   - interior lights inside penthouses / the hotel / houses;
   - aircraft warning `Blink` lights on masts and towers.
4. **The day look:**
   - a neon part becomes `SmoothPlastic` or `Glass` in a dull, darker version of its colour, so it looks like an unlit tube or sign;
   - lights are off (`Enabled = false`);
   - sign GUIs dim to about 30% brightness, or their `LightInfluence` goes up so they look printed, not glowing.
5. **Sunset and night:**
   - neon fades in from **17.5** (start of sunset) to full by **19.5**;
   - it fades out at dawn, between **6.0 and 7.0**;
   - random small delays per sign (0–40 seconds of game time) so the city lights up bit by bit, not all at once;
   - add a `DayCycle.neon(hour)` ramp for this; don't reuse `night()`.
6. **Keep it cheap:**
   - update only when the ramp value changes by about 0.05;
   - spread the changes over several frames (a batch per frame);
   - skip parts beyond about 1,500 studs, which update when you come near;
   - no per-frame loop over all parts.
7. **Rain:** on a dark rainy day (heavy rain before 17.5), allow the neon at about 40% so the streets don't look dead. Keep this small.
8. **Check:**
   - at noon, no glow anywhere in the city;
   - at 18:30, neon coming on;
   - at 23:00, all lit.
   - Frame time with the switch running is no worse than before.

## Part 2: more realistic lighting
- **Lighting settings** (in `setupLighting` and the DayCycle keyframes):
  - `Technology = Future`, with a fallback that still looks right on low graphics;
  - real-looking `EnvironmentDiffuseScale` / `EnvironmentSpecularScale` (about 1);
  - soft shadows (`ShadowSoftness` about 0.2);
  - less colour saturation;
  - no strong tint.
- **Day:** bright, clean and slightly warm. Proper shadows under cars and trees. A light haze on far towers only.
- **Sunset:** a gold low sun, long shadows, an orange sky near the horizon, glass towers reflecting the sunset. Sun rays only when looking at the sun.
- **Night:**
  - a real dark blue night sky with stars and the moon;
  - not black, but not bright either;
  - lights come from street lamps, windows and neon, not from the whole sky.
- **Street lamps:** warm, realistic pools of light on the road (SpotLights pointing down). A soft glow at the lamp head, no big neon bulbs. Every other lamp casts a shadow if performance allows.
- **Windows at night:** a random mix of lit and dark windows (about 30–55% lit), with warm white, cool white and a few TV blue ones. Some windows switch on and off over time.
- **Bloom and exposure:** small bloom, only on real lights. No glow on white walls.

## Part 3: a more realistic environment
1. **Wet roads after rain:**
   - roads get darker and shinier while it rains and for a few game minutes after (less `Roughness` / more reflectance, or a wet decal layer);
   - add puddles that reflect the lights;
   - car tyre spray in rain.
2. **Sky and weather:**
   - clouds that move slowly and change over the day;
   - sometimes fog in the early morning over the sea and river;
   - lightning flashes far away in heavy rain, with no damage.
3. **Water:**
   - the sea has small waves and foam where it meets the beach and rocks;
   - the river flows;
   - a sun and moon glitter path on the water;
   - boats drifting far out as scenery.
4. **Trees and plants:**
   - trees and palms sway a little in the wind, more in rain;
   - a few leaves blow across roads in parks.
5. **Life:**
   - birds fly over the city by day and seagulls at the beach;
   - steam rises from a few street vents at night;
   - planes cross the sky with blinking lights;
   - city pigeons in the plazas.
6. **Ground detail:** road wear and patches, manhole covers, drain grates, crosswalk paint wear, kerb dirt, fallen leaves near trees. These are small decals; keep them light.
7. **Ambient sound, by area and time:**
   - city hum and distant traffic;
   - birds in the morning;
   - crickets at night in parks and on the island;
   - waves at the beach;
   - wind on the mountain or bridge;
   - rain on the ground;
   - it changes smoothly as you drive between areas.
   - Use Roblox's own free audio only, and check that each sound plays.
8. **Distance:**
   - far buildings stay visible, with haze, not popping in;
   - the skyline lights up at night.
   - Check LOD distances so things don't pop near the camera.

## Part 4: performance and settings
- Everything new respects the graphics quality: low graphics has fewer particles, fewer lights and no swaying.
- Add a **Graphics** option in settings (Low / Medium / High / Ultra) that the player can pick. It sets shadows, light count, particles and LOD range.
- **Measure:**
  - FPS and part count before and after, in Downtown at night with rain;
  - say the numbers.
  - It must not be slower than before on Medium.

## Checks before you say done
- No neon glows at noon. Neon comes on at sunset and is full at night. Traffic lights, car lights and police lights work as before at all times.
- Day, sunset, night and rain all look realistic, not cyberpunk: show the owner the 3-spot screenshots at noon / 18:30 / 23:00 / rainy night.
- Every Lune test passes. `luau-lsp analyze` is clean. The place is saved.
- Write the changes into `City Legends/City Legends.md` and `Games/CityLegends/CLAUDE.md`. Commit and push.

## When done, tell the owner (short)
- what changed;
- how to see it: what time, or how to set the time in Studio;
- FPS before and after;
- anything still untested.
