# Lighting and Atmosphere for Stylised Underwater / Ocean Roblox Games (Nov 2026, phone-first)

Scope note: I ran about 20 searches and fetches. Roblox engine facts and real ocean optics are well sourced. Breakdowns for specific games (Abzu, Hungry Shark World, Sea of Thieves, Endless Ocean, top Roblox ocean games) were thin: the 80.lv Abzu page was only a video embed. All exact numeric Roblox values below are my own starting points, marked under Inferences. No source gave "recommended underwater values"; Roblox docs only give example values.

**Critical finding for the whole bible:** `Lighting.Technology` (Voxel/ShadowMap/Future) is now **superseded**. Roblox replaced it with **Unified Lighting**, controlled by `Lighting.LightingStyle` (Realistic / Soft) and `Lighting.PrioritizeLightingQuality` (bool). Any spec that says "set Technology = Future" is out of date. Use `LightingStyle = Realistic` instead. — [Technology enum docs](https://create.roblox.com/docs/reference/engine/enums/Technology.md); [LightingStyle enum](https://create.roblox.com/docs/reference/engine/enums/LightingStyle.md); [Unified Lighting DevForum thread, Jan 2025](https://devforum.roblox.com/t/let-there-be-unified-light-unified-lighting-enters-studio-beta/3401512/43)

## Q1: Recommended Roblox Lighting/Atmosphere values for a bright readable reef, a deep blue open sea, a dark red trench, and the surface/beach

### Takeaway
Real water removes red first, then the rest of the spectrum, leaving blue. Over 50% of visible light is gone within 10 m, and about 1% reaches 100 m. A zone script should therefore get darker and narrow toward blue/teal as depth increases. Subnautica's main lesson is to break that physics near the player so nearby things keep their colour. In Roblox, build each zone from Atmosphere (Density/Offset/Color/Decay/Glare/Haze), Lighting ambients, Brightness and ExposureCompensation, plus a ColorCorrection, then tween between zone presets on the client.

### Cited Findings
**Real ocean optics**
- Red (~650 nm) is absorbed most readily; red fish look nearly black at 20 m. By 40 m, saltwater has absorbed nearly all red light while blue still gets through. — [Univ. of Hawaii, Exploring Our Fluid Earth](https://manoa.hawaii.edu/exploringourfluidearth/physical/ocean-depths/light-ocean)
- Water absorbs over 50% of visible light within the first 10 m. Only about 1% of visible light, mostly blue, reaches 100 m in clear tropical water. — [same](https://manoa.hawaii.edu/exploringourfluidearth/physical/ocean-depths/light-ocean)
- Zones: the euphotic zone reaches ~80 m in clear tropical water (under 10 m near the poles, centimetres in turbid water); the disphotic zone has dim blue light and reaches ~800 m in clear water; the aphotic zone has no sunlight and holds most of the ocean's water. — [same](https://manoa.hawaii.edu/exploringourfluidearth/physical/ocean-depths/light-ocean)
- A diver without a torch sees only shades of blue. A white light shone on an object brings back its full colour range. This is the physical basis for a "headlamp / bioluminescent reveal" mechanic. — [same](https://manoa.hawaii.edu/exploringourfluidearth/physical/ocean-depths/light-ocean)

**How Subnautica handled it (stylised readability over physics)**
- Sunlight attenuates with depth, and water/lighting parameters vary across world space. Earlier versions used constant on-screen values with timed fades between areas. — [Game Developer: How Subnautica plunges deeper into rendering realistic water](https://www.gamedeveloper.com/design/how-i-subnautica-i-plunges-deeper-into-rendering-realistic-water)
- They **removed the blue cast near the player** by decoupling how fast water attenuates sunlight from how fast reflected light attenuates on its way to the eye, "to match how divers perceive water, not physical accuracy." — [same](https://www.gamedeveloper.com/design/how-i-subnautica-i-plunges-deeper-into-rendering-realistic-water)
- Removing outside ambient light in deep cave recesses made gradual transitions from clear shallows to the deep greens of kelp areas. Designers were given control over as many lighting and water parameters as possible. — [same](https://www.gamedeveloper.com/design/how-i-subnautica-i-plunges-deeper-into-rendering-realistic-water)
- Light sources (bioluminescence, lamps) become more necessary the deeper you go. — [same](https://www.gamedeveloper.com/design/how-i-subnautica-i-plunges-deeper-into-rendering-realistic-water)

**Roblox Atmosphere (the only official definitions)**
- **Density**: how many particles fill the air; higher values hide more objects and terrain. It affects objects and terrain only, but changes how much skybox shows through them. Doc examples: 0 and 0.35. — [Roblox Atmospheric effects](https://create.roblox.com/docs/en-us/environment/atmosphere.md)
- **Offset**: higher values create a horizon silhouette; lower values blend distant objects into the sky (open-world feel). Balance it with Density, because low Offset can expose the skybox through terrain. Examples: 0 and 1. — [same](https://create.roblox.com/docs/en-us/environment/atmosphere.md)
- **Haze**: haziness above the horizon and into the distance. Examples: 1 and 2.8. **Color**: tints the atmosphere and is stronger with high Haze. Examples: [255,255,255], [255,200,255]. — [same](https://create.roblox.com/docs/en-us/environment/atmosphere.md)
- **Glare**: glare around the sun, visible only when Haze > 0. **Decay**: hue away from the sun, visible only when both Glare and Haze > 0. Example Decay: [255,90,80]. The docs give no min/max ranges. — [same](https://create.roblox.com/docs/en-us/environment/atmosphere.md)

**Roblox Lighting properties**
- **Ambient** tints the whole game, indoors and out. **OutdoorAmbient** tints outdoor areas only (the docs suggest warm for morning/late afternoon and cool for evening; examples [255,150,50], [0,175,255]). **Brightness** examples: 0.5, 1.5, 3.75; higher values increase contrast between lit areas and shadows. **ExposureCompensation** examples: -1, 0, 1.25. **ShadowSoftness** ranges 0–1 and applies only with LightingStyle = Realistic. **EnvironmentDiffuseScale / EnvironmentSpecularScale**: 0–1; values near 1 make smooth or metal objects reflect their surroundings. — [Roblox Lighting docs](https://create.roblox.com/docs/environment/lighting.md)
- **LightingStyle**: `Realistic` = "the most advanced and realistic lighting and shadows Roblox can deliver"; `Soft` = "a flat, retro-Roblox look with softer lights and shadows." — [LightingStyle enum](https://create.roblox.com/docs/reference/engine/enums/LightingStyle.md)
- **PrioritizeLightingQuality**: when true, advanced shadows and high-quality shaders are kept at closer distances as rendering quality drops; when false, view distance is kept instead. — [Roblox Lighting docs](https://create.roblox.com/docs/environment/lighting.md)
- A creator reports that the old voxel look can still be had with Style = Soft and Prioritize quality = off. — [DevForum Unified Lighting thread #43](https://devforum.roblox.com/t/let-there-be-unified-light-unified-lighting-enters-studio-beta/3401512/43)

**Terrain water and time of day**
- Underwater lighting follows the conditions above the water. WaterColor intensity scales with Lighting.TimeOfDay, which fixed water being "overly bright at night." Underwater, **Ambient sets how dark night can get**, so raise Ambient if night is too dark. Roblox suggests a PointLight on the diver for an eerie night effect. — [DevForum: Upcoming Underwater Lighting Improvements](https://devforum.roblox.com/t/upcoming-underwater-lighting-improvements/865915)
- Community complaints in that thread: skybox colours bleed into water at dawn and dusk with no control over it; WaterTransparency caps visibility; people asked for post-process volumes. — [same](https://devforum.roblox.com/t/upcoming-underwater-lighting-improvements/865915)

**Post-processing objects**
- ColorCorrectionEffect has Brightness, Contrast, Saturation and TintColor. ColorGradingEffect has TonemapperPreset (Default = vivid, high contrast; Retro = pre-2019 look). Bloom makes light-coloured parts glow. DepthOfField blurs out-of-focus areas. SunRays makes a halo and rays around the sun that move with ClockTime, shaped by objects between the camera and the sun. Effects parented to **Camera** show only to that player; effects in **Lighting** show to everyone. — [Roblox post-processing docs](https://create.roblox.com/docs/en-us/environment/post-processing-effects.md)

### Inferences
These are untested starting values from my own reasoning, to be tuned in Studio on a real phone. All colours are RGB 0–255. I use the terrain WaterColor plus a client-side preset for each zone. The underwater view is mainly shaped by Terrain.WaterColor / WaterTransparency and Lighting ambients, while Atmosphere mostly affects the above-water view and distance. If the game uses an "air-filled" ocean (no terrain water, the player swims in air), Atmosphere becomes the main underwater fog tool, and this is the more controllable approach for a stylised game. Pick one model early.

| Zone | Atmosphere (Density / Offset / Color / Decay / Glare / Haze) | Lighting (Ambient / OutdoorAmbient / Brightness / Exposure / ClockTime) | ColorCorrection (Bright / Contrast / Sat / Tint) | Bloom (Int / Size / Thresh) |
|---|---|---|---|---|
| Surface / beach (day) | 0.30 / 0.25 / (199,226,255) / (255,214,170) / 0.6 / 1.2 | (110,120,135) / (150,160,175) / 3 / 0.2 / 13.5 | 0.02 / 0.12 / 0.15 / (255,250,240) | 0.6 / 24 / 1.6 |
| Bright reef (0–20 m feel) | 0.38 / 0 / (90,200,215) / (40,120,170) / 0 / 0 | (95,140,150) / (110,170,185) / 2.5 / 0.3 | 0.03 / 0.18 / 0.25 / (230,255,250) | 0.7 / 20 / 1.4 |
| Open sea (deep blue) | 0.50 / 0 / (25,95,170) / (10,40,90) / 0 / 0 | (45,75,115) / (55,95,140) / 1.8 / 0 | 0 / 0.15 / 0.05 / (200,225,255) | 0.5 / 24 / 1.5 |
| Deep sea | 0.62 / 0 / (10,35,80) / (5,15,40) / 0 / 0 | (20,35,65) / (25,40,70) / 1 / -0.3 | -0.03 / 0.2 / -0.1 / (170,200,255) | 0.9 / 30 / 1.1 (lets bioluminescence glow) |
| Red trench | 0.70 / 0 / (60,12,18) / (20,4,8) / 0 / 0 | (40,14,18) / (45,15,20) / 0.6 / -0.5 | -0.05 / 0.28 / -0.05 / (255,200,200) | 1.0 / 32 / 1.0 |
| Night (any zone) | Keep the zone's Density +0.05; Color toward (15,25,60) | ClockTime 0–2; Ambient no lower than (30,35,60) so phones stay readable | Sat -0.1, Tint (190,205,255) | Raise intensity so neon and emissives read |

- The red trench is **stylised, not physical**: real red is gone by about 40 m. Justify it with lava vents or red bioluminescence as the light source. Keep the fog dark maroon with a high-contrast grade, and keep the player's shark lit by a cool rim (see Q3) so it doesn't merge into the red.
- **Avoid the flat blue haze.** It comes from Density too high, saturation too low, and the same value everywhere. The fixes: (1) keep near-field colour by putting fewer fog particles close to the player, the Subnautica principle; (2) put warm accents (coral orange and pink, yellow fish) in the reef, so complementary colours carry it; (3) give every zone one light value and one dark value (sand floor bright, rock overhang dark); (4) give silhouettes rim light; (5) use Contrast in ColorCorrection rather than lowering Brightness.
- Per-zone "value key": surface brightest, reef mid-high, open sea mid, deep low, trench lowest but with saturated accent lights. Each zone should look distinct in a greyscale screenshot.
- Start with `LightingStyle = Realistic` and `PrioritizeLightingQuality = false`, so phones keep view distance in an open ocean. Revisit if close-up shadows matter more than distance.

### Gaps
- No official or community source gave tested numeric underwater presets. The table above is my own starting point.
- I could not confirm whether Atmosphere Density renders underwater with terrain water, or only above it. The docs don't say, so test it.
- No primary art breakdown found for Hungry Shark World, Sea of Thieves, Endless Ocean or the top Roblox ocean games. The Abzu GDC 2017 talk ([80.lv](https://80.lv/articles/gdc-2017-creating-the-art-of-abzu); [GDC Vault](https://gdcvault.com/play/1024409/Creating-the-Art-of-ABZ)) is video only and I didn't get a transcript.

## Q2: How to make caustics and god rays on Roblox terrain

### Takeaway
Beams, BillboardGuis, SurfaceGuis and slightly transparent parts **do not render behind terrain Water or Glass**. That kills the usual "Beam god ray" approach when viewed from inside terrain water. Caustics are most reliable as a scrolling, tileable `Texture` on floor parts (OffsetStudsU/V tween), or as a two-crossed-beam plane in non-terrain or air-filled oceans. For god rays, Roblox SunRays and Atmosphere Glare are screen and sky effects, so underwater shafts need beams or meshes in an air-filled setup.

### Cited Findings
- Beams, BillboardGuis and SurfaceGuis don't render behind Glass or Water; slightly transparent parts and their textures fail the same way. Workarounds: use a `Texture` and tween its `OffsetStudsU` / `OffsetStudsV` to fake moving caustics; put the caustic texture directly on the floor part (a part can hold several textures); use a single floor block or a tileable texture for modular floors; untested idea of a mesh with a transparent top face. — [DevForum: Beams invisible under water](https://devforum.roblox.com/t/beams-invisible-under-water/3028094)
- Caustics recipe from the community: a black-and-white caustic texture made transparent (Screen blending in Photoshop), applied to **two perpendicular beams stacked on top of each other**, with Width0/Width1 widened so each reads as a flat plane, then the beams' texture speed and stretch tuned to taste. Same settings on both. — [DevForum: Water Caustics creation and tutorial](https://devforum.roblox.com/t/water-caustics-creation-and-tutorial/2842131)
- In Subnautica, caustics and light shafts both follow the actual water-surface model, so they move together. — [Game Developer](https://www.gamedeveloper.com/design/how-i-subnautica-i-plunges-deeper-into-rendering-realistic-water)
- SunRaysEffect makes rays around the sun that move with ClockTime and are shaped by objects between the camera and the sun. — [Roblox post-processing docs](https://create.roblox.com/docs/en-us/environment/post-processing-effects.md)
- There is a long-standing feature request for native underwater light rays on terrain water. — [DevForum: Underwater light rays for terrain water](https://devforum.roblox.com/t/lighting-underwater-light-rays-for-terrain-water/703035) (search result only, not fetched)

### Inferences
- **Caustics method A (terrain-water friendly):** on floor parts or flat meshes over the terrain floor, add one or two `Texture`s holding a tileable caustic image (white lines on transparent), with StudsPerTileU/V around 24–40. Scroll the two layers in different directions at different speeds, for example layer 1 at +2 studs/s on U and layer 2 at -1.3 studs/s on V. Two layers make it look like it shimmers rather than slides. Use Color3 tint pale cyan and Transparency 0.5–0.75, and fade them out (Transparency to 1) below about the reef depth. Drive the scrolling from one client loop, not one tween per part.
- **Caustics method B (flipbook):** swap Texture.Texture through 16–32 frames of a caustic flipbook from ChatGPT art (per the user's art pipeline). It looks richer than scrolling but means more uploads and changes. Scrolling two layers is cheaper and usually good enough.
- For terrain itself, textures can't attach to voxels. Lay thin, CanCollide = false, CastShadow = false caustic "decal plates" over reef floors only (hero areas), not the whole map.
- **God rays:** (1) above-water and surface: SunRays (Intensity about 0.05–0.15, Spread about 0.6–0.9) plus Atmosphere Glare and Haze; (2) underwater in an air-filled ocean, or a part-based water volume: Beams with a soft vertical gradient texture, LightEmission 1, LightInfluence 0, and Transparency NumberSequence fading 1 → 0.7 → 1 along length, slowly swaying via the attachments; (3) with terrain water: thin `Neon`-free MeshParts (cone or blade meshes with a gradient SurfaceAppearance or Decal), but these also suffer the transparency-behind-water issue, so test before committing.
- Because of the terrain-water limits (beams and transparent parts invisible, skybox bleed, visibility cap), I recommend an **air-filled "fake water" ocean** for a stylised shark game: full control over fog via Atmosphere, beams, caustics and particles. Use custom swim physics, surface plane meshes, and a ColorCorrection when "underwater." Confirm with the movement/physics researcher.

### Gaps
- No measured performance numbers for animated textures or beams on phones.
- I didn't find a public, maintained Roblox caustics flipbook asset I could cite.

## Q3: How to light characters so they pop from the background

### Takeaway
Underwater scenes have low value contrast and one dominant hue, so characters need a separation tool: rim light, a value or hue contrast against the fog, or an outline. In Roblox the cheapest reliable tools are a Highlight (outline only), a small attached PointLight or SurfaceLight ("diver lamp"), emissive or Neon accents, and keeping body textures in a value range the fog never reaches.

### Cited Findings
- The Highlight instance has FillColor/FillTransparency, OutlineColor/OutlineTransparency, and DepthMode (AlwaysOnTop shows through walls; Occluded doesn't). The client shows **at most 255 Highlights at once**; extra ones are silently ignored, and disabled ones still use a slot. — [Roblox Highlight docs](https://create.roblox.com/docs/reference/engine/classes/Highlight.md)
- Roblox suggests a PointLight on the diver for night or underwater scenes; Ambient sets how dark the underwater view can get. — [DevForum: Underwater Lighting Improvements](https://devforum.roblox.com/t/upcoming-underwater-lighting-improvements/865915)
- A white light on an object underwater restores full colour, which is how real divers see colour at depth. — [Univ. of Hawaii](https://manoa.hawaii.edu/exploringourfluidearth/physical/ocean-depths/light-ocean)
- Subnautica removed the blue cast near the player so nearby objects keep their colour. — [Game Developer](https://www.gamedeveloper.com/design/how-i-subnautica-i-plunges-deeper-into-rendering-realistic-water)
- Higher Lighting.Brightness raises contrast between lit areas and shadows. — [Roblox Lighting docs](https://create.roblox.com/docs/environment/lighting.md)

### Inferences
- **Rim-light recipe (local player shark):** a Highlight with FillTransparency 1 and OutlineTransparency 0.6–0.8, OutlineColor pale cyan (170,235,255) in warm or red zones and warm white (255,235,200) in blue zones, so the rim contrasts with the zone's hue. DepthMode Occluded. Use it on the local player and key enemies or boss sharks only, to save Highlight slots.
- **Key light:** a PointLight on the shark's head (Range 12–18, Brightness 0.8–1.5, Shadows false) in deep, trench and night zones, ramped up as you descend. It doubles as a "flashlight reveal" that restores colour nearby, which is physically motivated.
- **Value design:** give the shark a light belly and dark back (real countershading) so it reads against both light (looking up) and dark (looking down) backgrounds. Keep albedo out of the zone's fog value band.
- **Hero lighting for cutscenes:** for evolution reveals or boss intros, parent to the client Camera a temporary preset: DepthOfField (FocusDistance on the shark, InFocusRadius about 10–20, FarIntensity 0.4–0.6), a ColorCorrection Contrast boost of +0.1, a three-point setup of SpotLights on invisible anchor parts (warm key 45° above, cool rim from behind, faint fill), and Bloom up briefly. Tween back afterwards. Camera-parented effects affect only that player. — based on the [post-processing docs](https://create.roblox.com/docs/en-us/environment/post-processing-effects.md)
- **Bioluminescence:** use Neon material or emissive SurfaceAppearance plus Bloom (lower Threshold in deep zones so only emissives bloom). Real bioluminescence is mostly blue-green, but I didn't verify that with a source, so check it. A stylised palette can add magenta and yellow for collectables. Use PointLights sparingly: a few big ones on hero props such as giant jellyfish, never one per tiny fish.

### Gaps
- No source on real local-light limits or costs on phones under Unified Lighting. The announcement post was unreachable (DevForum redirected to maintenance).
- No source found confirming bioluminescence colour distribution, so mark it as needing a check before quoting it.

## Q4: Zone transition techniques

### Takeaway
Roblox has no built-in post-process volumes, which the community has asked for. Transitions are done in a client script that detects the zone (by depth/Y or region parts) and tweens Lighting, Atmosphere, ColorCorrection, Bloom and the water colour toward the new preset. Subnautica moved from timed fades to parameters that vary across the world, which is the model to copy: blend continuously by depth and position, not with hard switches.

### Cited Findings
- Subnautica moved from constant-per-area values with timed fades to parameters that vary across the world, and used ambient removal in caves for gradual shallow-to-kelp transitions. — [Game Developer](https://www.gamedeveloper.com/design/how-i-subnautica-i-plunges-deeper-into-rendering-realistic-water)
- Developers asked for post-processing volumes and water-specific colour correction because of skybox bleed at dawn and dusk. — [DevForum: Underwater Lighting Improvements](https://devforum.roblox.com/t/upcoming-underwater-lighting-improvements/865915)
- Camera-parented effects apply to one player only, which lets a client-side transition run per player. — [Roblox post-processing docs](https://create.roblox.com/docs/en-us/environment/post-processing-effects.md)

### Inferences
- **Depth-lerp model:** compute `t = clamp((surfaceY - camY) / zoneDepthRange, 0, 1)` every frame (or every 0.1 s on phones) and lerp Color3 and number properties between the two nearest preset rows from the table. That avoids pops when sharks dive fast.
- **Region overrides:** invisible zone parts (or `workspace:GetPartBoundsInBox` checks every 0.25 s) for special biomes such as the trench and kelp. Use TweenService for 1.5–3 s blends with Sine InOut easing, and cancel any running tween before starting a new one.
- **Surface crossing:** a hard, fast switch (0.15–0.25 s) plus a splash VFX and audio low-pass is better than a slow fade. It sells the "breaking the surface" moment. Toggle a camera-parented underwater ColorCorrection and Blur (Size 2–4 for 0.3 s).
- **Mood beats:** going down into the trench, slow the blend (4–6 s), drop exposure, add a deep audio drone, and flash bioluminescent props in sequence. Arrival feels like a reveal, not a fade.
- Run all transitions on the client so that each player can be in a different zone.

### Gaps
- No public Roblox module found to cite for zone lighting blending (several are known in the community, but none were fetched or verified).
- No measured phone frame costs for tweening many Lighting properties every frame. Expect it to be cheap, but profile it.

## Phone performance (applies to all questions)

### Takeaway
Under Unified Lighting, Roblox scales lighting quality per device automatically. `PrioritizeLightingQuality` lets you choose whether shadow and shader quality or view distance drops first. Budget with that in mind: hero lights only, Neon and Bloom instead of many PointLights, textures instead of beams under terrain water.

### Cited Findings
- PrioritizeLightingQuality: true keeps shadows and shaders at closer distances as quality drops; false keeps view distance. — [Roblox Lighting docs](https://create.roblox.com/docs/environment/lighting.md)
- Some post-processing effects may not appear depending on quality settings; set Studio's Editor Quality Level to max to preview them. — [Roblox post-processing docs](https://create.roblox.com/docs/en-us/environment/post-processing-effects.md)
- There are reports of lighting issues on Apple mobile devices. — [DevForum](https://devforum.roblox.com/t/lighting-issues-on-apple-mobile-devices/3682732) (search result only, not fetched)
- Highlight limit: 255 per client. — [Highlight docs](https://create.roblox.com/docs/reference/engine/classes/Highlight.md)

### Inferences
- Test every zone on the lowest graphics quality level on a mid-range Android phone: fog and ambient must still give readable silhouettes when shadows and some effects are dropped. Readability should never depend on DepthOfField or SunRays.
- Set CastShadow = false on all caustic plates, god-ray meshes, particles and small fish.
- Prefer one Bloom and one ColorCorrection object whose properties change, rather than adding and removing effect instances.

### Gaps
- Unified Lighting's full announcement (device scaling details, light caps) couldn't be read because DevForum redirected to a maintenance page during research. Re-check it: https://devforum.roblox.com/t/let-there-be-unified-light-unified-lighting-is-fully-live/3401512
