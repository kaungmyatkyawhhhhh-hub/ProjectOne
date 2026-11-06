# Prompt: make the lighting and the cars look like the two Ghost Driver videos

_For Claude Code on the PC, with Roblox Studio connected (MCP) and Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras._

## What the owner wants (2026-11-06)
The owner: "check how good their car quality and lighting quality looks, it's actually crazy, can u copy that". Two videos from another Roblox game (Ghost Driver):
- `Games/CityLegends/imports/ghostdriver_lighting_1.mp4.mp4`: a white supercar close up (car quality).
- `Games/CityLegends/imports/ghostdriver_lighting_2.mp4.mp4`: driving a green supercar on a highway at sunset, then their graphics and weather settings (a "graphics tutorial").
- Key frames: `Games/CityLegends/imports/refs/lighting/ghostdriver/` (`drive_sunset_*.jpg`, `car_*.jpg`, `settings_graphics.jpg`, `settings_weather.jpg`).

**Copy the look, not their stuff:** lighting values, colours and the feel are fine to match. Don't take their models, skybox images, UI art, plates or names. Everything we use is ours or from the Toolbox (cleaned: scripts removed, no logos).

Watch both videos yourself (frames with ffmpeg, every 0.5 s) before starting.

## What makes their game look so good (from the frames)
### Lighting (sunset driving)
- A **dramatic sunset sky**: big soft clouds lit pink, orange and purple from below, blue sky above, the sun low behind the city.
- **Strong horizon haze:** far buildings fade into a pale, warm, slightly pink mist; near things stay sharp. That depth is most of the "crazy" look.
- A **low fog layer** (their setting: "Fog Layer: THICK (VOLUMETRIC)") hugging the ground in the distance.
- **Soft, slightly low-saturation colour grade:** their sliders show Brightness 0.63, **Contrast 0.16, Saturation -0.07** (a filmic, not cartoon, look). Highlights glow a little (bloom), the sun gives light rays.
- **Soft but dark contact shadows:** each car sits in a deep soft shadow; nothing floats.
- Reflections HIGH, ambient light HIGH, shadows ON, sun rays ON, depth of field OFF.
- Their time slider was at **17.3** (5:18 pm) for this look.
- At speed the edges of the screen streak (motion blur feel) while the car stays sharp.

### Car quality (the white supercar)
- **Paint:** clean satin-to-gloss clear coat. Soft, wide reflections of the sky; the body shape reads from the light gradients; no flat or plastic look. A matte / satin finish looks great in white.
- **Carbon / black parts:** wing, diffuser, splitter, skirts and vents in dark carbon that's darker and less shiny than the paint, so they stand out.
- **Smooth shapes:** no visible triangles or faceting on the body, smooth shading, sharp panel lines, deep vents and gaps you can see into.
- **Wheels:** dark multi-spoke rims with depth, real tyre sidewalls, the brake disc and caliper behind.
- **Lights:** tail lights and headlights with depth (lens over a dark housing), glowing softly.
- **Interior** visible through the glass: real seats, wheel and dash (ours already have this).
- **Ground:** a detailed asphalt texture (fine grain, slightly worn) under the car; the car's shadow is dark and soft on it.

## What to do
### 1. Lighting to match (the default look)
In `Lighting` and the `DayCycle` / `Weather` system (don't break the day cycle):
- `Technology = Future`, `EnvironmentDiffuseScale` and `EnvironmentSpecularScale` = 1, shadows on, `ShadowSoftness` low enough for dark contact shadows.
- **Atmosphere** per time of day: sunset = warm pink / peach haze, higher `Haze` and `Glare`, `Density` and `Offset` so the city fades into mist at distance but the road ahead stays clear. Keep the cold misty morning from the overnight prompt (Step 4) for mornings; this sunset look is for late afternoon / sunset.
- **Sky:** a high-quality sunset skybox with big dramatic clouds (our own or a cleaned Toolbox one), blended with the day cycle (day sky, sunset sky, night sky); plus Roblox `Clouds` tinted by time of day if it helps.
- **Ground fog layer:** a low fog band in the distance (layered transparent sheets / particles, cheap, faded near the camera), thicker at sunset and morning, never in the driver's way.
- **ColorCorrection:** contrast about +0.16, saturation about -0.07, a slight warm tint at sunset; tune by eye against the frames. **Bloom:** soft (highlights only, no blown-out white). **SunRays:** soft. Depth of field: off by default.
- **No neon** (owner rule): bloom is a soft glow on lights and the sun only.
- Make the **default time and the main menu backdrop** around 17:00–17:30 so the first thing players see is this look; the day cycle still runs.

### 2. Cars to match
**Only the newly imported models** (owner, 2026-11-06: "for the cars don't do it to old import models, only do it to newly imported models"):
- **Yes:** the cars converted with the new-model routine: the Aventador SVJ / SVJ 63, the 6 Bugattis, the 9 Lamborghinis from `Lamborghini imports.md` (LP700, SV, Gallardo LP570 SL, LP560 Spyder, Huracan EVO / Performante / STO / Sterrato, Revuelto), the cars from `New imports - Murcielago, Urus Performante, Ferraris.md`, and every car imported from now on.
- **No:** every older model. Don't change their paint, carbon, meshes, shadows or Customs options. If a shared material is used by old cars too, make a **separate copy** for the new models so the old cars look exactly the same as before.
- Not sure if a car counts as new? Check the import notes in `City Legends/City Legends.md`; if it's not listed there as a new-model-routine import, leave it alone.

For those new models:
- **Paint:** retune the paint `SurfaceAppearance` / material (new models only) so it reads like their clear coat: roughness about 0.15–0.3 for gloss, wider soft reflections, correct metalness (0 for paint); add a **satin / matte finish** to Customs for these new models if it isn't there.
- **Carbon:** the shared carbon set darker and slightly less glossy than the paint, with the weave visible up close.
- **Smoothness:** `RenderFidelity = Precise` on body meshes (keep collisions simple, `Box` / `Hull`); fix faceted bodies in Blender (smooth shading / weighted normals) when re-packing.
- **Contact shadow:** every new model gets a soft dark shadow under it (a blurred dark decal / plane under the body, faded at the edges) on top of the real shadow, so they never look like they float.
- **Lights, wheels, tyres:** lenses over dark housings, rims with depth, tyre sidewalls, discs and calipers (Part 2b of `Better car models and clean interiors.md`).
- **Road:** a detailed asphalt texture (grain, slight wear, normal + roughness maps) on the main roads so the shadow and the car sit on something real.

### 3. Settings (like their graphics tutorial)
Add to the game's existing settings menu, in our own UI style (same as our other menus, not a copy of theirs):
- **Graphics:** Shadows on / off; Reflections Low / High; Ambient Light Low / High; Glow (bloom) on / off; Sun Rays on / off; Depth of Field on / off; sliders for **Brightness**, **Contrast**, **Saturation** (defaults = the look above).
- **Weather:** Weather (Clear / Rain if it exists); Sky (Day / Sunset / Night style); Sun & Clouds shown / hidden; Horizon Haze on / off; Fog Layer Off / Light / Thick; a **Time** slider for this player only (client side), with "Follow server time" as the default.
- Settings save per player; phones default to a cheaper preset (fog layer light, sun rays off).
- Each option really changes the cost (`Low/Medium/High/Ultra` presets still work and set these).

### 4. Speed feel
At high speed, a subtle streak / blur at the screen edges only (the car stays sharp), plus the FOV kick we already have. Off in the settings for players who don't like it.

## Check before you say done
- **Side-by-side screenshots:** our game vs each frame in `refs/lighting/ghostdriver/` (same time of day, similar camera): the highway at sunset, a new-model car close up from the side and the rear 3/4; plus one old car before / after to prove it didn't change. Put them in `City Legends/City Legends.md`.
- Every time of day still looks good (morning mist, midday, sunset, night warm and golden).
- FPS not worse than before on PC High and on phone-size Low (measure the 3 usual spots); the fog and sky cost little.
- No console errors; Lune tests and `luau-lsp analyze` clean; save the place, commit, push; note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- the side-by-side screenshots;
- the settings added;
- FPS before / after.
