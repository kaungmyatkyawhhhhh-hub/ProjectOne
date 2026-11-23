---
tags: [research, video-watch, environment, underwater, roblox, unreal]
date: 2026-11-23
skill: "[[Skills/underwater-environment-build/SKILL|underwater-environment-build]]"
---
# 2026-11-23 Research - Underwater environment videos (DatBoiEle Roblox + Lunar9 UE5)

The owner pasted a "master instruction" asking for both videos to be studied in depth, then turned into a knowledge base and a reusable skill. The skill is **underwater-environment-build** (Brain/Skills).

**How they were watched (23 Nov 2026, Claude in Chrome, nothing downloaded):**
- Video 1 has no speech, only music. YouTube's auto captions are only "[Music]". All of its teaching is the burned-in caption text on screen.
- Video 1: frames read every 5 to 8 s for the whole 8:33. Every Properties panel was read at full 1080p size: terrain colours, Lighting, Atmosphere (start and end values), ColorCorrection, Bloom, and the Brushtool plugin panel.
- Video 2: the full YouTube transcript was read (one gap at 1:10–1:18, which is about project migration). Frames were read at about 40 s steps, plus full-size frames of the Outliner, the landscape paint layers and the PCG graph.
- Sound was not analysed. Video 1 is background music only, and video 2 is a voice-over.

**Honesty notes:**
- Neither video shows any written code. Video 1 is all Studio properties, plugins and hand placement. Video 2 shows Unreal's node graphs (a landscape material and a PCG graph), which are visual graphs, not code.
- Every Luau script in the skill is **Claude's own recommendation**, written to reproduce the techniques in Roblox. None of it was demonstrated in the videos.

---

## A. Video analysis

### Video 1: "How To make a Realistic Underwater Build (Tutorial) {ROBLOX STUDIO}"
- **Details:** DatBoiEle, uploaded 26 Sep 2021, 8:33 long, about 68K views.
- **Link:** https://www.youtube.com/watch?v=kvEf3pzKOqQ
- **Assets:** the creator's free "Underwater Pack" model, https://roblox.com/library/7573545989.
- **Format:** music only. A black intro card ("This video I'm showing how I built my underwater speedbuild", plus a pointer to his speedbuild video). After that it's a screen recording of Studio with a white caption bar for each step. He uses the F3X building tools plugin to move things.

| Time | Step (from the on-screen captions) | What it shows / exact values |
|---|---|---|
| 0:27 | "I've left a model of all the assets in the description" | The pack has coral-rock clusters, a dark dappled "shadow" plate, a bright caustic plate and light-beam parts |
| 0:31–1:00 | View → Terrain Editor → Region → Select an area the size of the sand → "Sand" → Fill | A flat sand slab is the whole seabed |
| 1:10–1:50 | Explorer → Terrain → Properties → "Click to expand" MaterialColors → darken Sand | **Sand = [52, 48, 32]**, a very dark olive-brown. Water settings visible on screen (Roblox defaults): WaterColor [12,84,92], Reflectance 1, Transparency 0.3, WaveSize 0.15, WaveSpeed 10 |
| 1:56–2:15 | Toolbox → search "Underwater Sky" → choose any | The skybox is a real underwater photo (reef silhouettes and a blue gradient). The sky does most of the background work |
| 2:15–2:30 | Lighting → Properties: "copy my lighting settings" | **Ambient [57,122,162]**, **Brightness 3.5**, ColorShift_Bottom/Top [0,0,0], EnvironmentDiffuseScale 1, EnvironmentSpecularScale 1, **GlobalShadows on**, OutdoorAmbient [70,70,70], **ShadowSoftness 0.2**, **Technology Future**, **ClockTime 14.5**, **ExposureCompensation 0**, Fog [192,192,192], FogEnd 100000, FogStart 0 (fog is left off; Atmosphere does that job) |
| 2:40–3:00 | "+" next to Lighting → Atmosphere: "copy my Atmosphere settings" | First values: **Density 0.7**, Offset 0, Color [57,138,162], Decay [64,101,115], Glare 0, Haze 0 |
| 3:00 | "And there you go" | The sand disappears into a thick blue-green haze. Visible range is short |
| 3:05–3:20 | "+" → ColorCorrection: "copy my settings" | **Brightness 0.05, Contrast 0.5, Saturation 0.5**, TintColor [255,255,255] |
| 3:19 | "Now it should be more vibrant!" | Contrast 0.5 and Saturation 0.5 are very strong. That strength is what makes it look "realistic" |
| 3:25 | Drag **Atmosphere into ServerStorage** | A build trick: with the haze off you can see what you're placing. It goes back into Lighting at the end |
| 3:35–4:00 | "Build anything with the 2 assets" | Coral-rock meshes in loose clusters on a green base plate |
| 3:50–4:30 | "Duplicate it on the entire ground" + "Put this on top of your build. You're basically putting a **custom shadow** onto your build" | A **dark dappled plate** (a black square with a leafy shadow texture) is tiled over the whole build, just above the ground. It fakes the dappled light-and-shadow you get underwater. "You can only click on it from the end": it's very thin, so you select it by its edge |
| 4:30–5:00 | "Now get this asset, and do the same. Duplicate it on top of the build" | A second plate, **bright cyan with a caustic (water-light) texture**, tiled above the build. "I know it looks weird right now. But trust me" |
| 5:00–5:20 | "+" next to Lighting → **Bloom**: copy settings | **Intensity 1, Size 60, Threshold 2** (bloom only catches the brightest bits: the beams and caustics) |
| 5:20–5:50 | Atmosphere to ServerStorage again → "Select the final asset" → "Duplicate it around anywhere" | **Light-shaft parts**: thin vertical bright beams, duplicated at random spots and angles |
| 6:10 | "Drag Atmosphere back into Lighting" → "make any adjustments" | |
| 6:28 | "For me, I want to make the tint color and both atmosphere colours a bit greener" | Final Atmosphere: **Color [57,157,162], Decay [64,106,115], Glare 0.8, Haze 2.15**, Density 0.7. ColorCorrection TintColor was seen being edited towards [0,255,255]. That reading is mid-edit, so it's uncertain |
| 6:45–7:30 | "Add small details using the **Brushtool plugin**" | Brush "Short seaweed": **Radius 1, Spacing 2, Rotation Random −360..360, Scale Random factor about 1..2**, Wobble off, Orientation Normal. Seaweed is painted into the gaps between rocks |
| 7:40–8:10 | "And all done!" / "If you have any questions…" | Final look: bright cyan water at the top fading to deep blue, god-ray beams, rocks covered in caustic light patches, seaweed tufts, an arch in the haze |

**What actually sells the look (in order of impact):**
1. A photographic underwater **Sky**.
2. **Atmosphere** at Density 0.7 with blue-green Color/Decay, plus **Haze 2.15 and Glare 0.8**.
3. **ColorCorrection** with strong contrast and saturation.
4. **Projected light layers** (dark dapple plate + bright caustic plate) that make light patterns on everything.
5. **Light shafts plus Bloom**, so the beams glow.
6. Dark sand, so the lit things stand out.
7. Small **scattered seaweed** to break up the gaps.

The geometry itself is just a flat slab with rock clusters. The look comes almost entirely from light and post-processing.

### Video 2: "Underwater Environment & Landscape | Unreal Engine 5 Underwater Game"
- **Details:** Lunar9, uploaded 8 Nov 2025, 21:06 long, about 900 views.
- **Link:** https://www.youtube.com/watch?v=HECwGXgGu50
- **Format:** a voice-over, informal ("enough is enough for today"), with some trial and error on screen. It's part of a series about his game "LunarDepths". He uses Subnautica as the reference and shows a Google image search of Subnautica biomes at about 13:50.

| Time | Step |
|---|---|
| 0:05–1:42 | Gets "Underwater Blueprint" by Kim (free version, about 2.5 GB) from Fab/Marketplace. The game is fully underwater: you can't go above the surface, there are no waves, and "we don't copy Subnautica" |
| 1:53–4:09 | **Migrate** the blueprint project's map and assets into his own project: Assets → Migrate → Content. He makes a new empty level "M_MainMap", then Window → Env. Light Mixer → creates SkyLight, DirectionalLight, SkyAtmosphere and ExponentialHeightFog (no clouds) |
| 4:26–4:50 | Landscape → Create, size "120 … choose 63". It "gives a shadowy look … warmer" |
| 4:50–5:31 | The underwater volume's settings: sun, **fog colour, fog distance, subsurface scatter, fog opacity**, post-process **blur, tint (green/purple), temperature (a bit cooler)**, **exposure lowered to 8** "to look cinematic" |
| 5:38–6:05 | Water-surface material: changes the colour, and too dark reads as night-time |
| 6:21–6:36 | **"The further you go down, the darker and foggier it gets."** Depth alone drives the mood |
| 6:44–7:11 | Alternative: Unreal's own **Water plugin** if migrating doesn't work |
| 7:11–7:53 | Sculpt: hills with a small brush, low strength, then **smooth** |
| 7:53–11:20 | Landscape material: **Landscape Layer Blend** with 3 layers (Sand, Rock 1, Rock 2), each with base colour + normal, **Roughness 1**. Megascans "rippled sand" plus 2 rock textures, imported at High quality |
| 11:20–11:52 | Landscape Paint → create layer info (Weight-Blended) → paint |
| 12:05–13:15 | **Fixing visible tiling**: LandscapeCoords → UVs with mapping scale 30, then tried 100 ("too giant"), settled on **50**. Bigger scale = less visible repetition but blurrier detail |
| 13:15–14:47 | Paint rock layers on the slopes and **smooth the edges so the materials blend**. "Everything is painted manually" |
| 14:47–15:25 | **Design principle:** in the reference game the landscape and every biome are **hand-placed**. Only the interactable entities (ores, creatures) are spawned by systems |
| 15:30–16:48 | The migrated rocks and sponges are too small. Modeling mode → Transform → **Bake Transform** at x2 (rocks) and x5 (sponges), so the bigger size is baked into the mesh |
| 16:56–17:22 | **PCG only for small stuff.** He advises against PCG for big underwater features like caves, because "it's not going to look good" |
| 17:22–20:53 | PCG plugin → graph "PCG_SimpleAlge" from the "simple forest" template. **Surface Sampler** (Points per m² 0.1, **Point Extents 200**, Looseness 1, seeded) → **Transform Points** (random rotation, random scale min/max, offset) → **Static Mesh Spawner** (several sponge/algae meshes, random pick). Extents 2000 = sparse clumps, 200 = an even grid look, 250 = his pick. "Debug" shows the points as cubes |
| 20:53 | Next episode: swim feel (camera shake, bubbles), since the player currently "just collides" |

**What video 2 teaches beyond video 1:**
- Shape the terrain (hills, then smoothing) instead of using a flat slab.
- **Blend 3 seabed materials** by painting rock onto the slopes and sand into the hollows.
- **Hide tiling** with a texture scale.
- **Get darker and foggier with depth.**
- **Hand-place the hero features, procedurally scatter the small clutter.**
- Bake prop scale.
- A **seeded scatter with spacing, random rotation, random scale and several meshes**.

---

## B. Landscaping handbook (combined; R = Roblox, UE = Unreal)

1. **Silhouette first, detail last.**
   - V1 skips this step (a flat slab), and V2's hills are basic.
   - My rule: the big shapes (hills, ridges, a cliff or arch, a hollow) are hand-made and readable through the haze. Clutter only fills in.
2. **Layer the seabed material by slope and height.** Sand in the hollows and flats, rock on the slopes and ridges, and a third material in patches.
   - UE: paint layers and smooth the edges.
   - R: Terrain materials (Sand / Rock / Slate / Ground / LeafyGrass) plus **MaterialColors**.
   - V1: darken the sand so the lit objects pop.
3. **Fight tiling.**
   - UE: texture scale around 50.
   - R: terrain textures repeat by themselves. Break them up with material patches, scattered props and the caustic/dapple layers, never one material over a big area.
4. **Composition: hero → clusters → breathers.**
   - Video 1 groups rocks into **clusters with sand gaps** and puts seaweed in the seams.
   - Video 2 hand-places the biomes and scatters only the small things.
   - This matches the MEGA BITE plan (landmarks, dense kit around them, open sand "breathers" in between).
5. **Haze is the depth tool.** Distance turns into blue-green.
   - R: Atmosphere Density about 0.7 with blue-green Color/Decay, with Haze and Glare for the scattering light.
   - UE: fog distance and opacity.
   - Shapes further away read as flat silhouettes, which gives the sense of scale. Big landmarks have to be tall and simple to read through it.
6. **Light patterns sell "underwater".** You need **caustics** (moving bright webs), **dappled shadow** and **god-ray shafts**.
   - V1 fakes all three with textured plates and beam parts, and lets bloom make the bright ones glow.
7. **Colour harmony:** one hue family (cyan → teal → deep blue) plus warm accents (coral, sand) used sparingly. V1 nudges everything a bit greener at the end, and V2 tints green or purple and goes cooler.
8. **Depth gradient (V2).** Deeper = darker and foggier.
   - **MEGA BITE rule: lighting must never be dark.** So deeper = denser and more saturated haze, never black. MB_BiomeMood already blends by zone, and the Titan Sea is the brightest zone.
9. **Density:** dense at the landmarks and cluster edges, sparse in the open. The small scatter is seeded (repeatable) and varied: ≥3 meshes, random yaw −180..180, scale ×1–2 (V1) or a min/max range (V2).
10. **Environmental storytelling:** in video 2's reference game, biomes are themed areas with their own palette (the Subnautica reference). MEGA BITE does the same: 4 Open Sea biomes plus the Titan Sea, each with its own light, sound and hero landmark.

## C. Asset creation handbook
- **What the videos show:**
  - V1 uses ready-made pack assets: textured rock meshes, plates with a decal/texture, beam parts and Brushtool brushes.
  - V2 uses a marketplace blueprint plus Megascans surfaces, and **bakes the scale** into meshes instead of scaling every copy.
- **Modular kit:** a small set of strong, reusable pieces (rock clusters, sponges, seaweed tufts, light plates, beams) placed in many arrangements. Both videos build whole scenes from 2–6 asset types.
- **MEGA BITE's own rules still win:**
  - Models are made with roblox-3d-model-from-sheet (sheets, then trace, then gates). No Creator Store assets.
  - About 7K triangles per landmark, low-poly props, Fisch-level quality.
  - A texture atlas cut from the sheet.
- **Light plates:** a flat Part (Transparency 1, CanCollide false, CastShadow false) carrying a tiled **Texture** (StudsPerTileU/V) or a SurfaceAppearance. One with a dark dapple pattern (Transparency about 0.6–0.8), one with a bright cyan caustic pattern (Transparency about 0.5–0.7). For animated caustics, scroll OffsetStudsU/V on the client.
- **Naming and organisation:**
  - V2 uses Core/Maps, Core/Materials and Core/PCG folders, and LayerInfo assets per paint layer.
  - In Roblox: Workspace.Map/<Biome>/{Landmarks, Clusters, Scatter, LightFX}, with kit masters in ServerStorage.
- **Performance:**
  - Scatter parts: Anchored, CanCollide false, CanQuery false, CanTouch false, CastShadow false.
  - Combine where possible, and stream by biome (MEGA BITE already uses MB_Cull and streaming).

## D. Coding handbook
- **Demonstrated:** none as code.
  - V1 is all properties and plugins (Terrain Editor Region/Fill, F3X, Brushtool).
  - V2 is node graphs: the Landscape Layer Blend material (LandscapeCoords → UVs, mapping scale) and PCG (Surface Sampler → Transform Points → Static Mesh Spawner).
- **Claude's Roblox equivalents** (full code in the skill's `scripts/`):
  1. `apply_underwater_v1.luau`: applies video 1's exact Lighting, Atmosphere, ColorCorrection, Bloom and sand-colour settings, with a backup folder first.
  2. `scatter.luau`: PCG-style seeded scatter. Surface sample (raycast onto terrain/parts) → filter by slope → keep minimum spacing → random yaw/tilt/scale → clone from several kit models. Seeded, so it's repeatable, and it clears and rebuilds its own folder.
  3. `light_plates.luau`: tiles dapple and caustic plates over a region and scrolls the caustics on the client.
  4. `depth_mood.client.luau`: blends Atmosphere/ColorCorrection by camera depth, with a brightness floor (the never-dark rule).

## E. Complete workflow
1. **Reference:** collect 6–10 real or game references per biome (V2 searched Subnautica). Write down the palette, the hero shape and the mood.
2. **Plan:** a zone map with each hero landmark, cluster areas and breathers, plus a triangle and part budget per biome.
3. **Light first:** apply the base look (Sky, Atmosphere, ColorCorrection, Bloom) before building, so placement is judged in the real light. Turn the haze off while placing (V1's trick: Atmosphere into ServerStorage).
4. **Terrain:** sculpt the big forms, then smooth, then paint the materials by slope and height and dim the sand colour.
5. **Hero pieces by hand:** landmarks and big rock formations.
6. **Clusters:** rock and coral groups around the heroes, with gaps left as breathers.
7. **Scatter the small clutter:** seeded scatter or Brushtool for seaweed, sponges and pebbles.
8. **Light layers:** dapple and caustic plates, then beams, then bloom.
9. **Final grade:** nudge the hue (V1 went greener), check that nothing reads dark (MEGA BITE rule).
10. **Optimise:** collision and shadow flags, streaming, and a phone test.
11. **Check:** screenshots from player height in every biome, then run the quality-nerd kid sim.

## How this applies to MEGA BITE (Claude's notes)
- MEGA BITE already has most of the structure video 2 recommends: a hand-placed world (MB_WorldGen terrain), seeded kit clusters (MB_WorldDress / MB_TitanDress), biome moods (MB_BiomeMood) and landmarks.
- **What the videos add that MEGA BITE doesn't have yet:**
  1. **Projected caustic and dapple light layers** over the reef and landmarks (V1's biggest visual trick, and cheap).
  2. **God-ray beam parts plus Bloom tuned to catch only them** (Threshold about 2).
  3. **A small seeded seaweed/sponge scatter** in cluster seams (Brushtool-style).
  4. **Blending terrain materials by slope**, so slopes read as rock and flats as sand.
- **Conflicts to keep:**
  - V1's dark sand and V2's "deeper = darker" go against the owner's never-dark lighting rule. Use the contrast between them, not the darkness.
  - V1 uses Toolbox/pack assets. MEGA BITE models must be our own.
