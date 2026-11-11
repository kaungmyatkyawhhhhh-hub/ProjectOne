# Making 3D creature models look premium inside Roblox (mobile-first, Nov 2026)

Scope: MEGA BITE shark game. FBX skinned meshes from Blender. Researched 9 Nov 2026. Dates are given for each source. Where only a search-result title was seen (not the full page), this is marked "(title only)".

## 1. SurfaceAppearance vs MeshPart TextureID vs vertex colours

### Takeaway
SurfaceAppearance is the only way to get full PBR on a creature: colour, OpenGL normal, roughness, metalness and (now) an emissive mask with strength/tint. It also has AlphaMode options and a free tint multiplier. Top creature games (Creatures of Sonaria, Ecos: La Brea) say PBR SurfaceAppearance plus emission maps is what moved their creatures to the next level of quality. Vertex colours import from FBX/glTF and can be kept or ignored for each mesh.

### Cited Findings
- SurfaceAppearance supports five PBR map types: colour (albedo), normal, roughness, metalness and emissive mask. Studio uses only the metalness workflow. Roughness 0 is glossy and 1 is matte. Metalness should be 0 or 1. — [Roblox Docs: PBR textures](https://create.roblox.com/docs/art/modeling/surface-appearance)
- Emissive properties are `EmissiveMaskContent` (a grayscale mask), `EmissiveStrength` and `EmissiveTint`. Marketplace items must keep EmissiveStrength between 0 and 40. — [Roblox Docs: PBR textures](https://create.roblox.com/docs/art/modeling/surface-appearance); property list in [SurfaceAppearance API](https://create.roblox.com/docs/reference/engine/classes/SurfaceAppearance)
- Only OpenGL-format tangent-space normal maps are supported. A flat normal is [127,127,255]. — [Roblox Docs: PBR textures](https://create.roblox.com/docs/art/modeling/surface-appearance). A community fix for inverted-looking normals is "try inverting the green channel" (DirectX to OpenGL) — [DevForum SurfaceAppearance beta thread p.16](https://devforum.roblox.com/t/surfaceappearance-studio-beta/663449?page=16) (title/snippet only)
- AlphaMode options:
  - Overlay (default): shows MeshPart.Color where the map is transparent.
  - Transparency: real see-through cutout.
  - TintMask: applies SurfaceAppearance.Color only where the alpha is opaque.
  - Opaque: ignores alpha. This one is still a beta feature.
  — [Roblox Docs: PBR textures](https://create.roblox.com/docs/art/modeling/surface-appearance)
- Transparency rules:
  - For hard-edged cutouts (e.g. fin edges, frills), keep MeshPart.Transparency = 0. This keeps proper depth occlusion and works with DOF, refraction and reflection.
  - For soft semi-transparent gradients, set MeshPart.Transparency ≥ 0.02. Not every effect supports this.
  — [Roblox Docs: PBR textures](https://create.roblox.com/docs/art/modeling/surface-appearance)
- `SurfaceAppearance.Color` multiplies the ColorMap at no performance cost. One near-white/grayscale map can be reused with many tints, which saves memory. — [Roblox Docs: PBR textures](https://create.roblox.com/docs/art/modeling/surface-appearance)
- Scripts generally can't change SurfaceAppearance properties while the game runs. The map ContentIds are Plugin Security. — [Roblox Docs: PBR textures](https://create.roblox.com/docs/art/modeling/surface-appearance); [SurfaceAppearance API](https://create.roblox.com/docs/reference/engine/classes/SurfaceAppearance)
- FBX and glTF imports carry vertex colours. The importer has an "Ignore Vertex Colors" setting for each child mesh. — [Roblox Docs: 3D Importer](https://create.roblox.com/docs/art/modeling/3d-importer)
- Creatures of Sonaria (top creature game) uses SurfaceAppearance for materials. It also keeps per-mesh Color/Material instead of textures in places, so players can recolour creatures. Ecos: La Brea said PBR made fur and bark "so much more photorealistic". Fluorlite and Twin Atlas say emission maps "significantly upgraded" their visuals. — [Roblox Newsroom, 1 Jul 2026](https://about.roblox.com/newsroom/2026/07/roblox-studio-fidelity-creator-interviews-twin-atlas-fluorlite-maximillian-ecos)
- Fisch is solo-built by WoozyNate. Fish variety comes from procedural hue/tint/shiny/sparkle variants, about 25 mutations per fish. The Color Adjust plugin recolours fish and Moon Animator does the animation. — [DevForum Creator Spotlight, 22 Nov 2024](https://devforum.roblox.com/t/creator-spotlight-woozynate-makes-a-splash-with-fisch/3269481)

### Inferences
- For the player shark, use SurfaceAppearance with a ColorMap, an OpenGL NormalMap (bake gill slits, scars and skin detail from a high-poly model), and a RoughnessMap for wet-skin sheen. Add an EmissiveMask for glowing evolutions (eyes, bioluminescent stripes). Set metalness to 0.
- For skins and mutations, author a near-white ColorMap and drive variants with SurfaceAppearance.Color or AlphaMode TintMask. The tint is free and the texture is shared. This copies Fisch's mutation approach (tint/hue variants) cheaply.
- Because SurfaceAppearance can't be edited at runtime, prepare the variant SurfaceAppearances in advance (cloned from ReplicatedStorage) instead of changing maps live.
- For small schooling fish, plain vertex colours or a small ColorMap are probably enough.

### Gaps
- No official per-device mobile cost figures were found for SurfaceAppearance vs TextureID. I also found no official statement on whether normal/roughness maps are dropped at low graphics quality levels.
- I found no first-party source on Fisch's lighting or material setup (the spotlight doesn't cover graphics).

## 2. Lighting tech on phones, underwater readability, outlines

### Takeaway
The old `Lighting.Technology` property is now marked deprecated. Lighting is controlled through `LightingStyle` (Realistic/Soft), `PrioritizeLightingQuality`, `ShadowSoftness` and environment diffuse/specular scales. Future lighting reaches Android (Oct 2024), but low and mid phones get reduced lighting quality automatically. So creatures must read well without local shadows and specular. Highlight outlines cost one draw call per highlighted object plus a full-screen post-process. The limit was raised to 255 in Nov 2025.

### Cited Findings
- `Lighting.Technology` is listed as Deprecated on the Lighting class page (2026 docs). The Technology enum still lists Voxel, Compatibility, ShadowMap and Future, with Legacy and Unified deprecated. — [Lighting API](https://create.roblox.com/docs/reference/engine/classes/Lighting); [Technology enum](https://create.roblox.com/docs/reference/engine/enums/Technology)
- Current lighting controls:
  - `LightingStyle` = Realistic (most advanced lighting and shadows) or Soft (flatter, retro).
  - `ShadowSoftness` 0–1 (only with Realistic).
  - `PrioritizeLightingQuality`: true keeps advanced shadows and high-quality shaders at closer distances as quality drops; false prioritises view distance.
  - `EnvironmentDiffuseScale` and `EnvironmentSpecularScale` 0–1. Specular near 1 lets smooth objects reflect the environment.
  — [Roblox Docs: Lighting](https://create.roblox.com/docs/environment/lighting)
- A "Unified Lighting" Studio Beta thread exists. The page redirected to maintenance when fetched, so its content wasn't verified. — [DevForum: Unified Lighting Studio Beta](https://devforum.roblox.com/t/let-there-be-unified-light-unified-lighting-enters-studio-beta/3401512) (title only)
- Future lighting on Android (29 Oct 2024):
  - It was 100% rolled out to Android as a Client Beta.
  - It is "costly in performance". Lower-end and mid-range devices may not see Future because the engine reduces lighting quality for framerate, and creators had no control yet.
  - Before the rollout, Android players saw ShadowMap.
  — [DevForum: Future is Bright on Android fully rolled out](https://devforum.roblox.com/t/future-is-bright-on-android-is-fully-rolled-out-client-beta/3235808)
- Highlight limit raised to 255 instances on 10 Nov 2025 (was 31). Roblox's Rendering team: "Each highlighted object is drawn individually, which incurs a drawcall cost". If any highlight is visible there is a post-processing cost. — [DevForum: Lights, Camera, More Highlights](https://devforum.roblox.com/t/lights-camera-more-highlights/4061534)
- Highlight outlines on mobile were added as a client beta in 2024. — [DevForum: Highlights now support Outlines on Mobile](https://devforum.roblox.com/t/highlights-now-support-outlines-on-mobile-client-beta/3059061) (title only)
- Highlight properties: Adornee, DepthMode, FillColor, FillTransparency, OutlineColor, OutlineTransparency, Enabled. — [Highlight API](https://create.roblox.com/docs/reference/engine/classes/Highlight)
- Emissive masks give self-lit glow independent of scene lights. — [Roblox Docs: PBR textures](https://create.roblox.com/docs/art/modeling/surface-appearance)

### Inferences
- Design shark readability for the worst case: no shadows and weak specular on low phones.
  - Use strong albedo value contrast (dark back, pale belly, i.e. countershading).
  - Add emissive eyes and markings.
  - Optionally use a single Highlight on the player shark or boss only, with a low-alpha fill or outline. Don't put one on every fish: each adds a draw call, and the post-process is paid once any is visible.
- Set `PrioritizeLightingQuality = true` if near-creature shading matters more than view distance. Underwater, fog hides distance anyway.
- Roblox has no rim/fresnel shader. Fake rim light by baking it into the ColorMap/emissive mask, or with a subtle Highlight fill.
- Underwater mood (Atmosphere density/colour, ColorCorrection tint, Bloom for emissive glow) is standard practice. This wasn't verified against Fisch specifically.

### Gaps
- No source found on how Fisch or other top ocean games light their underwater scenes.
- No primary doc found on Terrain water behaviour when the camera is submerged, or on Atmosphere/Bloom mobile costs.
- iOS Future lighting status isn't stated in the Android post.

## 3. Texture resolution actually used on phones

### Takeaway
Since Dec 2025 to Mar 2026, Roblox streams texture mips per object based on distance, screen-space size and a memory budget. 4K is renderable from Jan 2026, but it's disabled on low-end Android under 3.5 GB. A player shark seen at 10–30 studs on a phone screen rarely justifies more than 1K–2K. Mobile downscaling has had bugs in 2026.

### Cited Findings
- Texture Streaming (announced 12 Dec 2025; client rollout across platforms began 23 Mar 2026):
  - Baseline textures load first, then quality rises up to the device's available memory.
  - Mip level is chosen from object importance (distance from camera, screen-space size). A "Harmony" per-frame budget is set from device memory.
  - It covers MeshPart, SurfaceAppearance, Texture, Decal and MaterialVariant.
  - Recommendations: prefer unique textures over atlases (a whole atlas streams at the highest needed mip), and keep texel density uniform.
  — [DevForum: Introducing Texture Streaming](https://devforum.roblox.com/t/introducing-texture-streaming/4144855)
- In that post's support table, low-end Android devices under 3.5 GB have 4K textures disabled. — [DevForum: Introducing Texture Streaming](https://devforum.roblox.com/t/introducing-texture-streaming/4144855)
- 4K texture rendering went live on 30 Jan 2026 for MeshPart, SurfaceAppearance, Texture, Decal and MaterialVariant.
  - Images up to 8K are stored at original quality and transcoded down to 4K.
  - Devices that can't handle it get a lower resolution that fits their budget.
  — [DevForum: 4k Texture Rendering](https://devforum.roblox.com/t/4k-texture-rendering/4316229)
- Bug report (22 Mar 2026): SurfaceAppearance textures were downscaled on mobile even on an iPhone 16 Pro Max, and recovered only after a rejoin. The developer linked it to texture streaming and a D1 retention drop. Staff said the team was "taking a look", with no explanation. Roblox hasn't documented minimum texture resolutions. — [DevForum report](https://devforum.roblox.com/t/surface-appearance-loads-inconsistently-on-mobile-and-often-displays-at-very-low-quality-even-if-the-phone-allows-it/4530853)
- Earlier (2025): materials and textures were very blurry on 2 GB-RAM phones. — [DevForum report](https://devforum.roblox.com/t/all-materials-and-many-textures-and-decals-very-blurry-on-2-gb-ram-mobile-devices-even-in-a-baseplate-game/3414955) (title only)
- Fluorlite applies 4K textures to nearly everything. — [Roblox Newsroom, Jul 2026](https://about.roblox.com/newsroom/2026/07/roblox-studio-fidelity-creator-interviews-twin-atlas-fluorlite-maximillian-ecos)

### Inferences
- Player shark: author at 2048 (up to 4K from Blender is fine because streaming downsizes it). Expect phones to show about 512–1024 at 10–30 studs.
- Use one unique texture set per shark rather than a big atlas, so the set streams independently.
- NPC fish: 256–512. Many fish species can share one tinted map.
- Test on a real low-RAM Android.

### Gaps
- No published table of mip by distance by device.

## 4. Skinned meshes: limits, NPC performance, animation import

### Takeaway
Use a maximum of 4 bone influences per vertex, no weights on the root bone, frozen transforms, and one animation per FBX export. Skinned meshes get no automatic LOD (staff, 2022). Many skinned NPCs on mobile are often limited by scripts and network ownership rather than rendering.

### Cited Findings
- Rigging specs:
  - Up to 4 bone influences per vertex.
  - Don't weight the root bone.
  - Root at 0,0,0. Freeze bone transforms (scale 1, rotation 0).
  - Mesh limit is 20,000 triangles.
  - Only one animation track per exported mesh, so use one export per animation.
  — [Roblox Docs: Modeling specifications](https://create.roblox.com/docs/art/modeling/specifications)
- Blender FBX export settings:
  - Apply Scalings = "FBX Unit Scale".
  - Path Mode Copy and Embed Textures on.
  - Add Leaf Bones off.
  - Bake Animation off unless the model has keyframe animation.
  — [Roblox Docs: Export requirements](https://create.roblox.com/docs/art/modeling/export-requirements)
- Importer settings:
  - Rig Type R15/Custom/No Rig.
  - "Keep Zero Influence Bones" is off by default, so non-deforming bones are stripped. Enable it if a script needs those bones.
  - Anchored is disabled for rigged meshes.
  - Make Double Sided costs more performance.
  — [Roblox Docs: 3D Importer](https://create.roblox.com/docs/art/modeling/3d-importer)
- Staff (28 Mar 2022): "LOD has never worked with skinned meshes, it's a known limitation." — [DevForum](https://devforum.roblox.com/t/skinned-mesh-rig-cannot-generate-lod-on-any-fidelity/1731085)
- Case study (Oct 2023):
  - Setup: about 30 on-screen skinned NPCs (≤1,500 tris each) lagged on a Pixel 7 Pro, and RenderFidelity had no effect.
  - Real causes: setting NetworkOwner to the targeted player, and the default Animate scripts. Hundreds of script-less NPCs showed no noticeable lag.
  — [DevForum](https://devforum.roblox.com/t/game-with-skinned-meshes-has-poor-performance-on-mobile-renderfidelity-doing-nothing/2649641)
- Fisch animates with Moon Animator. — [Creator Spotlight, Nov 2024](https://devforum.roblox.com/t/creator-spotlight-woozynate-makes-a-splash-with-fisch/3269481)
- Bone scaling/deformation is still a feature request. — [DevForum feature request](https://devforum.roblox.com/t/feature-request-bone-scaling-deformation-support/4761420) (title only)

### Inferences
- Shark rig: a spine chain of about 6–10 bones plus jaw and fins, 4 influences, smooth weights.
- For NPC fish: run animation on the client, keep them server-owned or client-only visuals, skip the Animate scripts, and swap to static far meshes yourself. Bones can be driven by script for cheap tail sway.

### Gaps
- No official bone count limit or GPU-vs-CPU skinning cost data.
- I didn't verify whether animation clips are created by the importer.

## 5. Mesh import gotchas and LOD

### Takeaway
DoubleSided costs extra performance and is for single-sided cards. Automatic LOD (250 and 500 stud switches, from 2019) doesn't apply to skinned meshes. Distant fish need manual LOD.

### Cited Findings
- DoubleSided property (10 Nov 2020) is recommended only for single-sided cards like leaves, hair and cloth. — [DevForum: MeshPart DoubleSided](https://devforum.roblox.com/t/meshpart-doublesided/864664)
- Geometry must be watertight, with no zero thickness, quads preferred and no N-gons. — [Modeling specifications](https://create.roblox.com/docs/art/modeling/specifications)
- The importer has "Invert Negative Faces" (fixes flipped normals). — [3D Importer](https://create.roblox.com/docs/art/modeling/3d-importer); flipped-normal report [DevForum](https://devforum.roblox.com/t/roblox-sees-imported-fbx-as-if-its-normals-are-flipped/2429420) (title only)
- Mesh LOD (16 May 2019):
  - 3 levels, each about half the triangles of the one above.
  - Switches at 250 and 500 studs.
  - Only with RenderFidelity Automatic, which can't be set by script.
  - Works best untextured.
  — [DevForum: Levels of Detail for Mesh Parts](https://devforum.roblox.com/t/levels-of-detail-for-mesh-parts/280769)
- The Terrain Early Access Program (Jul 2026) adds LOD improvements for large worlds. — [Roblox Newsroom](https://about.roblox.com/newsroom/2026/07/roblox-studio-fidelity-creator-interviews-twin-atlas-fluorlite-maximillian-ecos)
- Creatures of Sonaria uses simplified hulls for collision, and instance streaming. — [Roblox Newsroom](https://about.roblox.com/newsroom/2026/07/roblox-studio-fidelity-creator-interviews-twin-atlas-fluorlite-maximillian-ecos)

### Inferences
- Fins: model them with thickness, or use DoubleSided only for the thin fin meshes.
- Set CollisionFidelity to Box/Hull and use a simple invisible hitbox part for bites.
- Bake custom normals in Blender (apply Auto Smooth/Weighted Normal before export).
- Since skinned meshes get no auto LOD, swap distant fish to unskinned low-poly meshes (or hide them) by distance in a client script.

### Gaps
- No primary doc found on texture compression banding or gamma for SurfaceAppearance.
- No documented behaviour for transparency sort order of overlapping semi-transparent fins.
