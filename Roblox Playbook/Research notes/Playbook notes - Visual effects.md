# Roblox VFX for Kids' Simulator Games on Cheap Phones (2025-2026)

Scope note: Research done on 2026-10-28. Primary sources are Roblox Creator Hub docs (current versions fetched) and DevForum posts. The docs left many reference fields blank, so they give **no defaults** for most ParticleEmitter properties. Where I give a "recommended value" with no citation, it is listed under Inferences as general practice, not a sourced fact.

---

## 1. Roblox VFX tools: properties and costs

### Takeaway
ParticleEmitter is the main tool. Flipbooks (out of beta October 2022), Squash, Orientation modes, LightEmission (blend mode), ZOffset, Drag, TimeScale and `Emit(n)` bursts cover nearly every simulator effect. The main costs are particle rate, particle size (fill-rate and overdraw), texture memory and draw calls. The Highlight limit went from about 31 to **255** in November 2025. The first visible Highlight costs up to about 1 ms of GPU time on mobile.

### Cited Findings

**ParticleEmitter: core properties (current reference docs)**
- **LightEmission** is a float. 0 gives normal blending and 1 gives additive blending, so overlapping particles get brighter. It does **not** light the world; use a PointLight for that. — [ParticleEmitter API (.md)](https://create.roblox.com/docs/en-us/reference/engine/classes/ParticleEmitter.md)
- **LightInfluence** (0–1): at 0, particles keep full brightness; at 1, they take world lighting and turn black in full darkness. **Gotcha:** the default is 1 when an emitter is inserted through Studio tools but 0 when created with `Instance.new()`. — [ParticleEmitter API](https://create.roblox.com/docs/en-us/reference/engine/classes/ParticleEmitter.md)
- **Brightness** scales emitted light when LightInfluence is 0. — [ParticleEmitter API](https://create.roblox.com/docs/en-us/reference/engine/classes/ParticleEmitter.md)
- **ZOffset** moves particles forward or back in render order, in studs, without changing their on-screen size. Positive values move them toward the camera. Fractional values work. Large negative values can hide particles inside their parent part. — [ParticleEmitter API](https://create.roblox.com/docs/en-us/reference/engine/classes/ParticleEmitter.md). A community example layers fire at ZOffset 1 over smoke at ZOffset 0. — [VisuallyFX, "Introduction to VFX: Particles", DevForum, 1 Dec 2022](https://devforum.roblox.com/t/introduction-to-vfx-particles/2068650)
- **Squash** (NumberSequence over lifetime): values above 0 shrink a particle horizontally and grow it vertically; values below 0 do the reverse. It is useful for stretched sparks and "squash and stretch" on pops. — [ParticleEmitter API](https://create.roblox.com/docs/en-us/reference/engine/classes/ParticleEmitter.md)
- **Orientation** (ParticleOrientation): FacingCamera (the default), FacingCameraWorldUp (turns only around world Y, good for ground-ish or vertical effects), VelocityParallel (aligned to the direction of motion, good for streaks and speed lines) and VelocityPerpendicular (faces along the direction of motion, good for flat rings and shockwaves). — [ParticleEmitter API](https://create.roblox.com/docs/en-us/reference/engine/classes/ParticleEmitter.md)
- **Rate** is particles per second while Enabled; Rate 5 emits one particle every 0.2 s. Changes don't affect particles already alive. — [ParticleEmitter API](https://create.roblox.com/docs/en-us/reference/engine/classes/ParticleEmitter.md). A code-sample comment gives: "Number of particles = Rate * Lifetime." — [ParticleEmitter class page](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter)
- **`Emit(particleCount)`** emits that many particles at once; the default count is **16**. It is not thread-safe. This is the burst tool for coin pops and impacts: keep the emitter Disabled or at Rate 0 and call Emit. — [ParticleEmitter API](https://create.roblox.com/docs/en-us/reference/engine/classes/ParticleEmitter.md)
- **Lifetime** (NumberRange) is picked randomly per particle; 0 means nothing is emitted. — [ParticleEmitter API](https://create.roblox.com/docs/en-us/reference/engine/classes/ParticleEmitter.md). Values above 20 s are capped at 20. — [Particle emitters guide](https://create.roblox.com/docs/effects/particle-emitters)
- **Drag** is the time in seconds for a particle to lose half its speed (exponential decay). Negative values make particles speed up exponentially. **WindAffectsDrag** makes particles follow `Workspace.GlobalWind` and only works when Drag > 0. — [ParticleEmitter API](https://create.roblox.com/docs/en-us/reference/engine/classes/ParticleEmitter.md)
- **TimeScale** (0–1): 1 is normal speed, 0.5 is half speed and 0 freezes the effect. This makes a native hit-stop or slow-mo possible on particles. — [ParticleEmitter API](https://create.roblox.com/docs/en-us/reference/engine/classes/ParticleEmitter.md)
- Changing **Speed** does not affect particles already alive; use Acceleration, Drag or VelocityInheritance to change motion. — [Particle emitters guide](https://create.roblox.com/docs/effects/particle-emitters)
- **Shape**: Box, Sphere, Cylinder or Disc, plus ShapeStyle (Volume or Surface), ShapeInOut (Outward, Inward or both) and ShapePartial (top-radius ratio for a cylinder, inner-radius ratio for a disc, emission angle for a sphere). — [ParticleEmitter API](https://create.roblox.com/docs/en-us/reference/engine/classes/ParticleEmitter.md). Sphere and Cylinder shapes **don't display correctly on Attachments**; use them only on BaseParts. — [Particle emitters guide](https://create.roblox.com/docs/effects/particle-emitters)
- **LocalTransparencyModifier** (hidden, client-only) multiplies Transparency; at 1, particles are invisible to that client. It can fade an effect locally without replication. — [ParticleEmitter API](https://create.roblox.com/docs/en-us/reference/engine/classes/ParticleEmitter.md)

**Flipbooks**
- Flipbooks came out of beta on **21 October 2022**. Supported textures are square and power-of-two, **from 8×8 up to 1024×1024**. Layout enum values were renamed to `Grid2x2`, `Grid4x4` and `Grid8x8`. Roblox still recommends a little spacing around each frame to avoid bleeding artifacts. — [Particles' Flipbook Release, DevForum](https://devforum.roblox.com/t/particles’-flipbook-release/2029388)
- Layouts: Grid2x2 (4 frames), Grid4x4 (16), Grid8x8 (64), or Custom using FlipbookSizeX and FlipbookSizeY. Example: a 1024×1024 sheet with Grid8x8 gives 64 frames. **FlipbookFramerate tops out at 30 fps.** — [Particle emitters guide](https://create.roblox.com/docs/effects/particle-emitters)
- FlipbookMode: **Loop**; **OneShot** (plays once over the particle's lifetime and ignores FlipbookFramerate, so frame rate = lifetime ÷ frame count; best for explosions and puffs); **PingPong**; **Random** (random frames with crossfading). `FlipbookIncompatible` reports an error when the texture size isn't an exact multiple of the layout. — [ParticleEmitter API](https://create.roblox.com/docs/en-us/reference/engine/classes/ParticleEmitter.md)
- **Clients automatically turn off flipbooks when memory is low, which is likely on older phones.** To save memory, use fewer unique animated effects, use smaller textures and reuse textures. — [Particle emitters guide](https://create.roblox.com/docs/effects/particle-emitters)
- Texture format: .png with a transparent background. For grayscale textures with no alpha, set LightEmission = 1 so dark areas disappear (additive blending). — [Particle emitters guide](https://create.roblox.com/docs/effects/particle-emitters)

**Beam**
- Properties: Texture; Color (constant or ColorSequence); Transparency (NumberSequence); Width0 and Width1 in studs; TextureLength and TextureMode; FaceCamera; CurveSize0 and CurveSize1 (Bézier control points); Attachment0 and Attachment1, which are required. TextureMode **Wrap/Static** repeats the texture length ÷ TextureLength times; **Stretch** repeats it TextureLength times across the whole beam. The doc example tapers with Width0 = 0.5 and Width1 = 3. Beam quality changes with the player's graphics setting. — [Beams guide](https://create.roblox.com/docs/effects/beams)
- (The fetched Beams page didn't cover Segments, TextureSpeed or Trail; see Gaps.)

**Highlight**
- Highlight limit raised **to 255** on **10 Nov 2025** ("Lights, Camera, More Highlights!", Rendering Team). Forum replies cite an older cap of 31 or 32. Each highlighted object is drawn separately, adding draw calls, and a post-processing cost applies whenever any highlight is on screen. — [DevForum announcement](https://devforum.roblox.com/t/lights-camera-more-highlights/4061534)
- Up to 255 Highlights display at once; any beyond that are silently ignored. **A disabled Highlight still uses one of the 255 slots**, so delete Highlights you'll never re-enable. Adding or removing a Highlight can trigger a geometry rebuild, causing spikes and extra draw calls. **The first highlight carries most of the cost, up to 1 ms of GPU time on mobile**, and later ones add little. On mobile, cost rises with the screen area a highlight covers. Disabled or fully transparent highlights cost nothing when off screen. Change a highlight's properties rather than destroying and recreating it. Avoid nesting objects that have Highlights. DepthMode is AlwaysOnTop or Occluded. — [Highlighting objects guide](https://create.roblox.com/docs/effects/highlighting)
- The Highlight class page lists Adornee, DepthMode, Enabled, FillColor, FillTransparency, OutlineColor and OutlineTransparency. — [Highlight API](https://create.roblox.com/docs/reference/engine/classes/Highlight)

**Post-processing, Lighting and Sky**
- Post-processing effects can go under Lighting (all players) or Camera (one player): BloomEffect, BlurEffect, ColorCorrectionEffect (Brightness, Contrast, Saturation, TintColor), DepthOfFieldEffect, SunRaysEffect (moves with ClockTime) and the newer **ColorGradingEffect** (TonemapperPreset: Default = vivid, high contrast; Retro = pre-2019 look). Some effects may not appear depending on quality settings, so preview at the highest Editor Quality Level. — [Post-processing effects guide](https://create.roblox.com/docs/environment/post-processing-effects)
- `Lighting.Technology` values: Legacy, Voxel (4×4×4 voxel lighting), Compatibility (deprecated; use Voxel plus ColorGrading Retro instead), ShadowMap, Future and Unified. The docs say Technology has been **superseded by `LightingStyle`** (artistic intent) and **`PrioritizeLightingQuality`** (whether lighting quality or view distance scales down first). — [Technology enum](https://create.roblox.com/docs/reference/engine/enums/Technology.md)
- Shadow quality drops automatically at lower graphics levels and **shadows are off entirely below quality level 4**. Set `Light.Shadows = false` on lights that don't need shadows. Limit light Range and Angle, use fewer lights, and turn off lights outside the current area. — [Improve performance](https://create.roblox.com/docs/performance-optimization/improve)

**UI effects**
- Example of a UIGradient "shine" (open-source GUI Shine Module, 17 Aug 2026): it creates a temporary child Frame, tweens a UIGradient across it at a default **Rotation of 45**, and clones any UICorner so the shine stays inside rounded borders. It has DEFAULT, SOFT and SHARP presets and fades out over 0.3 s on stop. — [DevForum: GUI Shine Module](https://devforum.roblox.com/t/open-source-gui-shine-module/4816664). UIGradient reference: [UIGradient API](https://create.roblox.com/docs/reference/engine/classes/UIGradient.md)
- ViewportFrames: a 2024 community thread says VFX "don't work well" in viewports, Highlights lose the object's colour there, and animated avatars in viewports drop FPS. Parenting a Sky to a ViewportFrame reportedly sets its skybox. — [DevForum: Improvements to ViewportFrames (feature request, 31 Mar 2024)](https://devforum.roblox.com/t/improvements-to-viewportframes/2897582). Older thread on particles in viewports: [DevForum](https://devforum.roblox.com/t/particles-in-viewport-frames/263785)

### Inferences
- For a coin burst or impact, use a Disabled emitter plus `:Emit(n)`. It is cheaper and more predictable than toggling Enabled with a high Rate.
- LightEmission 1 (additive) on a black-background texture is the fastest way to a "glowy, premium" look without Bloom. That matters because Bloom is a full-screen pass and may be missing on low-end settings (see Gaps).
- Because of the Instance.new LightInfluence default (0) versus the Studio default (1), effects made in code can look brighter than those made in Studio. Set it explicitly every time.
- Since the first Highlight costs up to 1 ms on mobile, use a Highlight only for focused moments (selected pet, hovered egg). Never use one per coin or per pickup.
- ViewportFrame hatch screens should get their sparkle from UI elements (ImageLabels and UIGradients) layered over the viewport, not from 3D particles inside it.

### Gaps
- No sourced numbers for Beam `Segments`, `TextureSpeed`, Trail properties (`Lifetime`, `MinLength`, `WidthScale`, `FaceCamera`) or their cost. The fetched pages didn't cover them.
- No official per-PointLight or SpotLight GPU cost or light-count limit was found. The docs only say "use fewer lights" and limit range.
- No official doc says whether Bloom, SunRays or DepthOfField are turned off at low graphics quality on mobile.
- EditableImage and EditableMesh were not researched (call budget). The person writing the report should treat them as advanced and memory-heavy, and verify before recommending them.
- No official Neon-material cost note was found.

---

## 2. Performance: budgets, overdraw, quality scaling, pooling, culling

### Takeaway
The hard numbers from official docs are: **max 400 particles/sec per emitter (100 on mobile)**; Lifetime capped at 20 s; flipbooks auto-off on low memory; texture memory grows with pixel count (1024² = 4× the memory of 512²); shadows off below quality 4; particles and decals "don't batch well". Overdraw from large, overlapping transparent particles is the main GPU cost.

### Cited Findings
- Rate: "up to 400 particles per second per emitter, or 100 on mobile"; keep it as low as possible. Larger particles cost more GPU fill-rate, and many overlapping transparent layers increase GPU cost (overdraw). Test at the lowest and highest Editor Quality Level. — [Particle emitters guide](https://create.roblox.com/docs/effects/particle-emitters)
- Partially transparent objects near each other force the same pixels to be drawn several times. Property changes on ParticleEmitters "can have a dramatic impact on performance". Decals, textures and particles "don't batch well and introduce additional draw calls". — [Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- Texture memory depends on pixel count, not file size. A 1024×1024 texture uses 4× the memory of a 512×512 one. Images "usually need at most 512x512", and "most minor images should be smaller than 256x256". Removing alpha or compressing doesn't cut GPU memory. Use sprite sheets with `ImageRectOffset` and `ImageRectSize` for UI. — [Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- Shadows are turned off below graphics quality level 4. Disable CastShadow on small or moving parts. — [Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- Profiling: draw calls show under Render Stats (Shift+F2 in client). In the MicroProfiler, particle updates appear under `Perform/Scene/UpdateView` and post-processing under `Perform/Scene/RenderView`. — [Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- By default the engine culls objects outside the view frustum and objects hidden behind others. — [Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- A former Roblox employee's 2023 post, quoted in a June 2026 feature-request thread, says the single graphics-quality slider ties render distance to other effects: real-time shadow distance drops below level 9, and ambient occlusion appears only at level 10. Players are asking for a separate particle-quality setting (feature request, not shipped). — [DevForum: More Advanced Graphics options (community, Jun 2026)](https://devforum.roblox.com/t/more-advanced-graphics-options/4670101)
- Clients turn off flipbooks automatically under memory pressure. — [Particle emitters guide](https://create.roblox.com/docs/effects/particle-emitters)

### Inferences (practical budget, not official)
- For a cheap-phone simulator, a sensible starting budget is: a coin pop of 8–16 particles, a level-up of about 30–60 total across 2–3 emitters, an aura of about 10–20 alive at once (for example Rate 10 × Lifetime 1.5), and roughly 300 or fewer alive particles on screen in total. Shrink particle Size before cutting count, since fill-rate is the mobile bottleneck.
- Read `UserSettings():GetService("UserGameSettings").SavedQualityLevel` on the client to scale your own effects. Cut `Emit` counts and turn off secondary layers (such as smoke and glow sprites) below roughly level 4. This value is engine-side and should be verified in testing.
- Pooling: keep one pre-built emitter set per effect type parented to Attachments, move the Attachment and call `Emit`. Don't Clone and Destroy per event, since property and instance changes cause rebuild costs, as the Highlight docs show for that class.
- Turn off persistent emitters (auras, ambient sparkles) when the owner is far from the camera, using a distance check every 0.25–0.5 s on the client. The engine culls emitters out of view, but off-screen emitters may still simulate (unverified).
- Use 256×256 for single sprites and 512×512 (or at most 1024) for flipbooks. Reuse one white grayscale sprite tinted with `Color` instead of uploading coloured variants.

### Gaps
- Roblox doesn't publish exactly how much particle emission drops at each quality level. The docs only say to test at the lowest and highest levels.
- No official guidance on whether particles keep simulating when off-screen.

---

## 3. Craft: principles, textures, recipes, camera effects and accessibility

### Takeaway
Roblox's own docs teach the tools but not the craft. The craft principles below (anticipation, impact, dissipation; contrast; readability) are standard real-time VFX practice and are written as **inferences**. The concrete Roblox hooks for them are TimeScale (hit-stop), Squash (stretch), OneShot flipbooks (dissipation) and `GuiService.ReducedMotionEnabled` (accessibility).

### Cited Findings
- Accessibility: the Roblox Reduce Motion toggle maps to **`GuiService.ReducedMotionEnabled`**; true means the player wants motion effects reduced or removed. The doc example sets TweenInfo time to 0 so the UI snaps into place, or uses a CanvasGroup GroupTransparency fade instead. Background transparency maps to `GuiService.PreferredTransparency` (multiply your BackgroundTransparency by it). The page doesn't cover camera shake or flashing. — [Accessibility guidelines](https://create.roblox.com/docs/en-us/production/publishing/accessibility)
- TimeScale 0 freezes particles, which can be used for hit-stop. — [ParticleEmitter API](https://create.roblox.com/docs/en-us/reference/engine/classes/ParticleEmitter.md)
- Basic workflow tips (Color sequences, Size sequences, Squash, Rotation/RotSpeed ranges, EmissionDirection, SpreadAngle, ZOffset layering): VisuallyFX's "Introduction to VFX: Particles" (1 Dec 2022, older but still accurate for the basics). — [DevForum](https://devforum.roblox.com/t/introduction-to-vfx-particles/2068650)
- Roblox's official beginner course "Intro to VFX art" (laser blast and explosion in the Mansion of Wonder template). — [Creator Hub curriculum](https://create.roblox.com/docs/tutorials/curriculums/artist); [Work with particle emitters chapter](https://create.roblox.com/docs/tutorials/curriculums/artist/work-with-particle-emitters)
- Egg-hatch and pet-hatch community references: [Pet Hatching Framework Part 1](https://devforum.roblox.com/t/pet-hatching-framework-part-1/1480291); [Egg Hatching Animation? thread](https://devforum.roblox.com/t/egg-hatching-animation/2542547); UI particle approaches in [How can I make particles in GUI](https://devforum.roblox.com/t/how-can-i-make-particles-in-gui/1673765) (not fetched; titles only).

### Inferences (craft guidance; general VFX practice, unsourced here)
- **Three-phase timing:** anticipation (about 0.1–0.3 s: a charge-up glow, a small inward Shape with ShapeInOut = Inward), then impact (1–3 frames: a bright additive flash with high LightEmission and big Size that fades very fast), then dissipation (0.4–1.0 s: slower, darker or smoke particles with Drag about 0.3–1 and Transparency rising to 1). Kids' games read best with a big, punchy impact and a short tail.
- **Shape language:** circles and stars mean reward and friendliness (coins, sparkles); sharp shards mean impact or danger. Keep rewards round and soft.
- **Value and colour contrast:** a bright core with a saturated rim, set against the scene's mid-values. Rarity colours (grey, green, blue, purple, gold, rainbow) must be readable at a glance and should be paired with shape or size changes for colour-blind players.
- **Textures:** paint in grayscale white-on-black or white-on-transparent and tint in-engine with ColorSequence. Free or cheap tools include Krita, GIMP, Photopea, Blender (rendering flipbooks), EmberGen (paid) and Aseprite for pixel style. Leave 2–4 px of padding per flipbook cell.
- **Recipes:**
  - *Coin burst:* Disabled emitter; Emit 10–16; Sphere shape with Speed 15–25; Acceleration (0, −60, 0); Drag 0.5; Lifetime 0.6–0.9; spinning coin flipbook (Grid4x4, Loop); Size NumberSequence that pops up then shrinks. Pair it with a UI "+N" tween.
  - *Level up:* a vertical ring (Orientation VelocityPerpendicular, emitted upward), a column Beam that fades out, and a sparkle Emit of about 20. Add a short FOV punch of +5–8° for 0.15 s, skipped if ReducedMotionEnabled.
  - *Rarity reveal / hatch:* a shake that builds in intensity (anticipation), then a white flash frame (a UI Frame fading from 0 to 1 transparency over 0.2 s), then rarity-coloured rays (a rotating ImageLabel with UIGradient) and a confetti Emit. Give higher rarities longer anticipation and more layers.
  - *Aura:* 1 emitter, Rate 8–15, LockedToPart true, LightEmission 1, low Size, FacingCameraWorldUp, plus an optional slow ring Beam. Turn it off at a distance.
  - *Speed lines:* VelocityParallel orientation with Squash > 0, or a camera-attached emitter with a few long thin sprites; Trail on the feet.
  - *Shockwave:* a flat ring texture with Orientation VelocityPerpendicular, Size growing from 0 to 10+, Transparency going to 1, Lifetime 0.3–0.5. Or a MeshPart ring tweened in scale, cheaper than many particles.
  - *Sparkle/shine:* 2–4 star particles Random-flipbook twinkling, plus a UIGradient sweep on UI cards.
  - *Smash/debris:* a few small Parts or MeshParts with an impulse, a dust OneShot flipbook and a brief TimeScale freeze for hit-stop (about 0.05–0.08 s).
- **Camera:** shake amplitude 0.1–0.5 studs that decays within 0.2–0.4 s; FOV punch ±5–10°; hit-stop of 40–80 ms. Wrap all three behind a check of `GuiService.ReducedMotionEnabled` plus an in-game "Screen shake" toggle. Avoid full-screen white flashes faster than about 3 per second (a photosensitivity guideline).

### Gaps
- No primary source fetched for Roblox-specific camera-shake values or a hit-stop implementation. The values above are craft heuristics.
- Didn't fetch GDC or realtimevfx.com material (call budget). Respected general resources to point to without verification: realtimevfx.com community, and GDC talks by Riot and Blizzard VFX artists.

---

## 4. What top Roblox games' VFX look like and which resources are respected

### Takeaway
Little primary evidence was gathered for this question. The respected entry points that were confirmed are Roblox's official VFX curriculum, the Particle emitters, Beams and Highlighting docs, the flipbook release post, and DevForum community tutorials such as VisuallyFX's. Claims about which named games or artists lead are unverified.

### Cited Findings
- Official: [Particle emitters](https://create.roblox.com/docs/effects/particle-emitters), [Beams](https://create.roblox.com/docs/effects/beams), [Highlighting](https://create.roblox.com/docs/effects/highlighting), [Post-processing](https://create.roblox.com/docs/environment/post-processing-effects), [Improve performance](https://create.roblox.com/docs/performance-optimization/improve), [Intro to VFX art curriculum](https://create.roblox.com/docs/tutorials/curriculums/artist).
- Community: [Introduction to VFX: Particles, VisuallyFX](https://devforum.roblox.com/t/introduction-to-vfx-particles/2068650); [How can I learn VFX? thread](https://devforum.roblox.com/t/how-can-i-learn-vfx/2805022) (titles only, not fetched).

### Inferences
- Top simulators (pet- and egg-hatch style) lean heavily on UI-layer VFX: rays, flashes, UIGradient shines and bouncing tweens. These are cheap on phones and render above everything. 3D effects are mostly short bursts.

### Gaps
- No verified analysis of specific top games' VFX (for example, which games use which techniques) and no named, verified VFX artists. No RDC 2024/2025 VFX talk was found or fetched.
- Many search results for "Roblox VFX guide" were SEO-spam domains (for example, "How-to Master VFX in Roblox" on unrelated hosts) and were excluded.
