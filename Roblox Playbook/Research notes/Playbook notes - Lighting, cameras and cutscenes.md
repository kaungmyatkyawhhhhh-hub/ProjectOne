# Lighting, Cameras and Cutscenes for Roblox Simulator Games (2025-2026)

Scope: implementation-level notes for a solo developer of kids' simulator games played mostly on phones. Research date: 2026-10-28. Official docs at create.roblox.com often leave out defaults and ranges. Where a value is not in a cited source, it appears under Inferences or Gaps, not as a cited fact.

## Lighting: LightingStyle, PrioritizeLightingQuality, Lighting properties, atmosphere, post-processing, light objects, mobile behaviour

### Takeaway
`Lighting.Technology` (Voxel/ShadowMap/Future) is deprecated. Two properties replace it. `LightingStyle` sets the look: Realistic gives the most advanced lighting, and Soft gives a flat, retro-Roblox look. `PrioritizeLightingQuality` decides whether lighting quality or view distance gets cut first when a device lowers its quality level. For phone-first kids' simulators, keep local lights few and unshadowed, preferring narrow SpotLights. Let Atmosphere and ColorCorrection/Bloom do most of the "pretty" work, and always set `Camera.Focus` in scripted cameras, because lighting and material detail now follow Focus.

### Cited Findings
**The new lighting model**
- `Lighting.Technology` is deprecated and superseded by two properties. **LightingStyle** sets "the artistic intent behind lighting". **PrioritizeLightingQuality** controls "whether lighting/shading quality or view distance is scaled down first". The old `Compatibility` value should be replaced by Voxel plus a ColorGradingEffect with the Retro preset. — [Technology enum docs](https://create.roblox.com/docs/reference/engine/enums/Technology.md)
- The LightingStyle enum has two values. **Realistic (0)** uses "the most advanced lighting and shadows Roblox can deliver". **Soft (1)** gives "a flat, retro‑Roblox look with softer lights and shadows". — [LightingStyle enum](https://create.roblox.com/docs/reference/engine/enums/LightingStyle.md); [Lighting guide](https://create.roblox.com/docs/environment/lighting)
- PrioritizeLightingQuality = true "prioritizes features such as advanced shadows and high‑quality shaders at closer distances", and false "prioritizes view distance". The docs advise true "If lighting and shadows are very important to the artistic feel of your game". This applies "As the rendering quality level reduces." — [Lighting guide](https://create.roblox.com/docs/environment/lighting)
- The Lighting class reference also lists Outlines and ShadowColor as deprecated. It lists `ExtendLightRangeTo120` as a non-scriptable RolloutState. — [Lighting class](https://create.roblox.com/docs/en-us/reference/engine/classes/Lighting)
- A third-party tutorial from Oct 2026 also says Technology options (Future, Unified) are replaced by LightingStyle and PrioritizeLightingQuality. It recommends testing on target devices because "A desktop editor view alone cannot establish how the finished game behaves on a smaller or slower device." — [obby.fun tutorial](https://www.obby.fun/blog/roblox-studio-realistic-lighting) (secondary source)

**Global Lighting properties** (the docs give example values, not defaults)
- **ShadowSoftness** runs from 0 (hard edges) to 1 (soft edges) and "is only valid when LightingStyle is set to Realistic". **GlobalShadows** toggles shadows. — [Lighting guide](https://create.roblox.com/docs/environment/lighting)
- **Brightness** example values: 0.5, 1.5, 3.75. **ExposureCompensation** example values: 0, -1, 1.25. Lower values look under-exposed and higher values over-exposed. — [Lighting guide](https://create.roblox.com/docs/environment/lighting)
- **Ambient** tints the whole game, indoor and outdoor. Examples: [0,0,0], [160,80,0], [25,0,125]. **OutdoorAmbient** affects outdoor areas only, and indoor areas don't change with it. Examples: [255,150,50], [200,150,240], [0,175,255]. **ColorShift_Top** examples: [0,100,255], [255,60,0]. **ColorShift_Bottom** examples: [255,0,220], [0,255,190]. — [Lighting guide](https://create.roblox.com/docs/environment/lighting)
- **EnvironmentDiffuseScale** (0–1) sets how much ambient light comes from the environment. **EnvironmentSpecularScale**: "When set near a value of 1, smooth objects better reflect the environment and metal appears more realistic." — [Lighting guide](https://create.roblox.com/docs/environment/lighting)
- **ClockTime** runs 0–24. For example, 6.3 = 06:18:00 and 17 = 17:00:00. ClockTime and TimeOfDay "will not change during a game unless changed through a script". **GeographicLatitude** (degrees) moves the sun and moon without changing ClockTime. ClockTime is flagged Not Replicated. `SetMinutesAfterMidnight()` exists for scripted cycles. — [Lighting guide](https://create.roblox.com/docs/environment/lighting); [Lighting class](https://create.roblox.com/docs/en-us/reference/engine/classes/Lighting)

**Atmosphere** (the docs give example pairs, not defaults)
- **Density** (0 → 0.35): more particles, which hides distant objects. **Offset** (0 → 1): higher values give a horizon silhouette, lower values blend the distance into the sky. **Haze** (1 → 2.8). **Color** ([255,255,255] → [255,200,255]) works best with high Haze. **Glare** (0 → 1) is only visible when Haze > 0. **Decay** ([255,255,255] → [255,90,80]) is only visible when Glare and Haze > 0. — [Atmosphere docs](https://create.roblox.com/docs/environment/atmosphere)

**Post-processing**
- Effects parented to **Lighting** show for everyone. Effects parented to **Camera** show only for that player, for example blurring the world behind a UI menu. — [Post-processing docs](https://create.roblox.com/docs/environment/post-processing-effects.md)
- **ColorGradingEffect** has two TonemapperPresets. **Default** is the post-2019 look, "vivid colors and high contrast". **Retro** is the pre-2019 look with less saturation and contrast. For a full retro look, use Retro and cap all light brightness at 1.0. — [Post-processing docs](https://create.roblox.com/docs/environment/post-processing-effects.md)
- **ColorCorrectionEffect** has Brightness, Contrast, Saturation and TintColor. **Bloom** makes bright parts glow. **SunRays** follow ClockTime, and occluders shape them. The page has Blur and DepthOfField but gives no device or performance guidance. — [Post-processing docs](https://create.roblox.com/docs/environment/post-processing-effects.md)

**Local lights (cost)**
- The "Future is Bright" Phase 3 release says to keep local lights (Spot, Point, Surface) low in number. Per-pixel and shadowed lights are both capped per frame, and shadowed lights cost much more than unshadowed ones. Shadow cost, cheapest first: **SpotLight** (narrow angle, "say below 120 degrees") < **SurfaceLight** (narrow angle; wide angles approach point-light cost) < **PointLight** (most expensive "by a clear margin"). Devices that can't run per-pixel lighting fall back to ShadowMap, then Voxel. — [Future is Bright Phase 3 Released (DevForum, Nov 2020)](https://devforum.roblox.com/t/future-is-bright-phase-3-released/878634)
- SpotLight Angle maxes out at 180. SurfaceLight Angle 0 emits straight out. Brightness is limited by Range, so raising Brightness does not light a larger area. The docs suggest putting a PointLight in an Attachment. — [Light sources docs](https://create.roblox.com/docs/effects/light-sources)

**Mobile quirks and Focus dependence**
- An engine change around May–June 2025 made lighting quality depend on `Camera.Focus` rather than `Camera.CFrame`. Scriptable cameras that only set CFrame can lose shadows on lights and PBR materials when they are far from Focus. Community workaround: set Focus to near the camera position or the subject. Staff marked it a duplicate of an acknowledged issue under investigation. — [DevForum bug report](https://devforum.roblox.com/t/recent-change-causes-lighting-quality-to-be-dependent-on-camera-focus-rather-than-cframe/3709654)
- The Camera docs confirm that with Scriptable, Focus should be updated every frame, because "certain visuals are more detailed depending on how close they are to the focus point." — [Camera docs](https://create.roblox.com/docs/workspace/camera)
- iOS quirk (June 2025): FogColor, FogStart and FogEnd caused black patches on iPhone 12 and iPad but not on Android or PC. The workaround was a client script that changes fog on touch devices. Changing Technology made no difference. No staff reply. — [DevForum thread](https://devforum.roblox.com/t/lighting-issues-on-apple-mobile-devices/3682732)

### Inferences
- **Recommended phone-first baseline for a bright kids' simulator.** These are starting points to tune and are not sourced numbers. LightingStyle = Realistic (Soft if you want the classic toy look). PrioritizeLightingQuality = false, so hub vistas and pet/egg areas stay visible on low-end phones. ClockTime ≈ 13–14. Brightness ≈ 2–3. ExposureCompensation 0 to 0.3. OutdoorAmbient a warm-neutral mid-grey (~[130,130,140]) so shadows aren't black. EnvironmentDiffuseScale ≈ 0.5–1 and EnvironmentSpecularScale ≈ 0.5–1. Atmosphere Density ≈ 0.25–0.35, Haze 0–1, Glare 0. ColorCorrection Saturation +0.1 to +0.25 and Contrast +0.05 to +0.1. Bloom Intensity low (~0.3–0.5) with Threshold ~1.5–2 so only neon and VFX glow. SunRays Intensity low (~0.05–0.1).
- **Per-zone presets.** Store a table of Lighting, Atmosphere and ColorCorrection values per zone (e.g., each world in a simulator). Tween them on the client with TweenService over 1–2 s when the player crosses a zone boundary (CollectionService-tagged region parts, or ZonePlus). Lighting and Atmosphere properties are tweenable numbers and Color3s. Do it client-side so each player sees their own zone.
- **Day/night cycle cost.** Changing ClockTime rerenders sky and shadows. A slow client-side cycle (update every few frames, not via server replication, since ClockTime is Not Replicated) is cheap. For simulators, a fixed bright midday is usually better for readability and thumbnails. If you add a cycle, keep night short and raise OutdoorAmbient at night so kids can still see.
- **Light objects on phones.** Use Neon material plus Bloom for "glow" instead of real lights where possible. Keep Shadows = false on nearly all local lights. Reserve shadowed SpotLights for one hero spot (e.g., an egg reveal pedestal).
- **Interior vs exterior.** Interiors rely on Ambient (which affects indoors) plus a few unshadowed PointLights or SurfaceLights. Exteriors rely on OutdoorAmbient, sun and Atmosphere.

### Gaps
- Official defaults and ranges for Brightness, ExposureCompensation, Atmosphere and Bloom/SunRays were not shown on the fetched doc pages. The researcher's recollection of defaults (e.g., Brightness 2, Bloom Intensity 1/Size 24/Threshold 2) is unverified here.
- The fetched sources do not say how LightingStyle/PrioritizeLightingQuality map to the old Future/ShadowMap per quality level on mobile, or which quality levels get shadows. No official announcement thread for LightingStyle was found in this pass.
- No published, sourced recipes from specific top simulator games (Pet Simulator 99, etc.) were found.

## Cameras: Camera API, follow/OTS/shake/FOV, mobile, motion sickness and Reduced Motion

### Takeaway
Set `CameraType = Scriptable` for full control. Drive `CFrame` from a `RenderStepped`/`BindToRenderStep` callback, and set `Focus` every frame. FieldOfView runs 1–120 (default 70). For shake, use a maintained module with a global strength multiplier (GG Camera Shake, 2026; or the classic EZ Camera Shake / RbxCameraShaker). Scale shake and FOV punches down, or to zero, when `GuiService.ReducedMotionEnabled` is true.

### Cited Findings
- Camera is client-only (`Workspace.CurrentCamera`). Scriptable "gives you full control of the camera". CFrame is the main property. Focus should be updated every frame when Scriptable. FieldOfView range is 1–120, default 70, measured per `FieldOfViewMode`. Mobile camera movement is controlled by `DevTouchCameraMovementMode`, and CameraToggle works on computers only. Player zoom limits are `CameraMaxZoomDistance`/`CameraMinZoomDistance`. — [Camera docs](https://create.roblox.com/docs/workspace/camera)
- **Reduced Motion:** the in-experience "Reduce Motion" setting maps to `GuiService.ReducedMotionEnabled`. The docs pattern is `local TWEEN_TIME = if GuiService.ReducedMotionEnabled then 0 else 0.75`, or fading with a CanvasGroup's GroupTransparency instead of moving. `GuiService.PreferredTransparency` (0–1) should multiply UI background transparency. The page does not mention camera shake specifically. — [Accessibility docs](https://create.roblox.com/docs/en-us/production/publishing/accessibility)
- **GG Camera Shake** (DevForum, 11 Jul 2026; Wally v1.1.x): a port of GasGiant's Unity shake. It has Kick, Perlin and Bounce algorithms, directional/positional falloff (`sourcePosition`, `falloffDegree`), and 3D/2D presets such as `Shaker.Presets.Explosion3D`. `SetStrengthScale()` is a global multiplier meant for accessibility. `forcedEnable` lets gameplay-critical shakes ignore it. — [GG Camera Shake](https://devforum.roblox.com/t/gg-camera-shake-screenshake-that-doesnt-suck/4731267)
- Older or alternative shake modules: [EZ Camera Shake ported to Roblox](https://devforum.roblox.com/t/ez-camera-shake-ported-to-roblox/98482); [Sleitnick/RbxCameraShaker](https://github.com/Sleitnick/RbxCameraShaker); [ShakerService](https://devforum.roblox.com/t/shakerservice-the-sequal-to-camerashaker/3964127); [LugicalDev/CameraService](https://github.com/LugicalDev/CameraService) (a camera-mode module).

### Inferences
- **Follow camera pattern.** Use `RunService:BindToRenderStep("CustomCam", Enum.RenderPriority.Camera.Value + 1, fn)`. Lerp the camera CFrame toward `target * offset` with frame-rate-independent smoothing: `alpha = 1 - math.exp(-k*dt)`, k ≈ 8–12. Set `camera.Focus = CFrame.new(targetPos)`.
- **Over-the-shoulder.** Offset ≈ (2, 2, 8) studs from HumanoidRootPart. Raycast back from the head to the desired position to avoid clipping through walls. On mobile, keep the default thumbstick and drag-to-rotate controls rather than replacing them. For most simulators the default `Custom` camera with tuned zoom limits is best.
- **FOV effects.** A sprint, speed boost or rebirth "punch" of 70 → 80–85 tweened over 0.2–0.4 s feels good. Skip it, or cap at +5, when ReducedMotionEnabled is on. Avoid continuous FOV oscillation.
- **Motion-sickness guardrails.** Shake under ~0.5 s for rewards. No rolling or tilting of the horizon during gameplay. No forced camera control during movement. Gate all shakes through one multiplier tied to ReducedMotionEnabled plus an in-game "Camera Shake" toggle.

### Gaps
- The Camera docs page fetched had no BindToRenderStep, over-the-shoulder or follow code. The patterns above are standard practice, not cited.
- No official Roblox guidance on camera-induced motion sickness was found.

## Cutscenes: building methods, letterbox, skip, sound sync, multiplayer, performance, when and how long

### Takeaway
Cutscenes are client-side camera manipulation (Scriptable camera). There are three practical approaches.
1. **TweenService shot lists:** cheapest, fine for 2–4 shots.
2. **Spline or Bezier paths:** Catmull-Rom or Bezier evaluated per frame, for smooth multi-point paths.
3. **Authored animation:** Moon Animator 2 camera tracks, or a paid plugin like CineCam v3 that exports TweenService scripts with skip, letterbox and fades built in.

Always restore `CameraType = Custom`, always offer a skip after the first viewing, and keep reward reveals to a few seconds.

### Cited Findings
- **TweenService shot-list method:** store shots as {InitialOffset, EndOffset, TweenInfo, Delay} CFrames relative to the HumanoidRootPart. Capture offsets with `ToObjectSpace` from the command bar. At runtime, save the CameraType, set Scriptable, and convert each offset `ToWorldSpace`. Tween and wait for `Completed`, then destroy the tween and restore. It must be a LocalScript because the camera is client-only. Use `ipairs` to keep order. — [How to Create Camera Cutscenes (DevForum)](https://devforum.roblox.com/t/how-to-create-camera-cutscenes/1629318)
- **CutsceneService** (2020) argues that chaining TweenService across more than two points is rough, and uses Bézier curves for smooth multi-point paths. It is old, so check maintenance before use. — [CutsceneService](https://devforum.roblox.com/t/718571)
- **CineCam v3** (DevForum, 2 Jul 2026; $5.99, the author says it will not exceed $9.99) lets you:
  - Set keyframes from the viewport, each storing position and FOV, with duration, 10 easing styles and an optional hard cut.
  - Track a named Part, add shake, and fire a tagged BindableEvent per keyframe, for syncing dialogue, sounds and UI.
  - Use Catmull-Rom smooth paths with a tension control from 0 to 1.
  - Preview without playtesting.
  - Export dependency-free TweenService scripts with triggers: Module, On Touch, On Join, On Die, or Broadcast (synced to all players via a RemoteEvent).
  - Toggle Skip (Space/click), letterbox and fade bookends.

  — [CineCam v3](https://devforum.roblox.com/t/plugin-cinecam-v3-%E2%80%94-build-preview-camera-cutscenes-live-in-studio-no-playtesting-needed/4713811)
- **Moon Animator 2 camera:** add the Camera as an object track and use File > Export Files, which writes the keyframes to a KeyframeSequence. One article then suggests uploading it as an Animation and playing it via an AnimationController. The source itself is unsure this drives the camera. — [Nilo article](https://nilo.io/articles/export-moon-animator-animation-roblox) (secondary, unverified). DevForum questions on attaching the MA2 camera to a part: [thread](https://devforum.roblox.com/t/attaching-camera-to-a-parts-cframe-in-moon-animator-2/4769964); alternatives discussion: [thread](https://devforum.roblox.com/t/any-alternatives-to-ma2-moon-animator-2/4770365).
- **LetterBoxer** module (DevForum, 7 Jan 2026) provides `LetterBoxer.New(player)`, `:Descend(intensity, lifetime)` and `:Ascend()`. Intensity is valid in (0, 0.5]. The default tween is 1.75 s Cubic Out. — [LetterBoxer](https://devforum.roblox.com/t/letterboxer-a-cool-letterboxing-module-for-cinematic-scenes/4224471)
- Skip implementations discussed: [Implementing cutscene skipping](https://devforum.roblox.com/t/implementing-cutscene-skipping/924709); [Cutscene Skip Button](https://devforum.roblox.com/t/cutscene-skip-button/911078).

### Inferences
- **Moon Animator camera at runtime.** The reliable community approach is client-side: export or bake the camera keyframes into CFrame values, then step through them in RenderStepped with lerp. AnimationTracks on server Scripts do not move a client's CurrentCamera. Treat the Nilo server-script snippet as likely wrong.
- **Spline helper.** Evaluate a Catmull-Rom position over control-point Parts, use `CFrame.lookAt(pos, lookTarget)`, and advance `t` by `dt/duration` with an easing curve. Set Focus each frame (see the Lighting Focus finding).
- **Letterbox.** Two black Frames with ScreenGui `IgnoreGuiInset = true`, each ~10–12% of screen height. Tween them in over ~0.4 s. Hide the gameplay HUD (`StarterGui:SetCoreGuiEnabled` plus your own UI) during the cutscene.
- **Skip rules.** Make every cutscene skippable after the first view, and ideally always for kids. Show the skip button after ~1 s, bottom-right, large enough for a thumb. On skip, jump straight to the end state (rewards granted, camera restored). Never gate rewards on watching to the end.
- **Sound sync.** Drive sounds from the same timeline (keyframe events or `task.delay` at known offsets). Do not trust separate waits. Duck music with a SoundGroup volume tween during the cutscene.
- **Multiplayer.** Play cutscenes locally only. The server fires a RemoteEvent to one client, and the client runs the cutscene. Other players keep playing. Make sure the character is anchored or controls are disabled locally (via `PlayerModule:GetControls():Disable()`) and re-enabled on finish or skip, including on death or reset.
- **Performance.** Camera tweens are trivial in cost. The heavy parts are VFX and lights spawned for the scene, so pre-load assets (ContentProvider:PreloadAsync) before a big reveal.
- **When and how long.** Use them for first-join intros (≤10–15 s, skippable), new world/zone unlocks (3–6 s pan to the new area), rare or legendary pet/egg reveals (2–4 s, with an instant mode once the player has seen it many times), and rebirth (3–5 s). Avoid cutscenes on common, repeated actions. In kids' games, attention is short. Unskippable should be limited to a ≤3 s reward beat.

### Gaps
- The Roblox Animation Editor/AnimationClip workflow for animating the camera directly was not confirmed by an official source in this pass.
- No official Roblox guidance on cutscene length or skip policy was found. The length numbers above are judgement, not sourced data.

## Menu flyovers, loading-screen cameras, photo/thumbnail capture, and respected resources

### Takeaway
Main-menu and loading cameras are the same Scriptable camera technique: a slow looping spline or tween over the best-looking area, plus a Blur/DepthOfField parented to the Camera so only that player sees it. For thumbnail shots, use a dedicated "photo" lighting preset (higher saturation, low haze, posed characters) and capture in Studio at maximum Editor Quality Level.

### Cited Findings
- Effects parented to Camera apply only to that player, and the docs' example is blurring the world behind a UI menu. If effects don't appear in Studio, set Studio Settings > Rendering > **Editor Quality Level** to the highest level. — [Post-processing docs](https://create.roblox.com/docs/environment/post-processing-effects.md)
- Loading-screen cutscene discussion: [Cutscene Loading Screen (DevForum)](https://devforum.roblox.com/t/cutscene-loading-screen/811214).
- An open-source in-game camera rig for photo-style shots: [DevForum](https://devforum.roblox.com/t/open-source-in-game-camera-rig/1001900).
- Resource list:
  - Official docs: [Lighting](https://create.roblox.com/docs/environment/lighting), [Atmosphere](https://create.roblox.com/docs/environment/atmosphere), [Post-processing](https://create.roblox.com/docs/environment/post-processing-effects), [Light sources](https://create.roblox.com/docs/effects/light-sources), [Camera](https://create.roblox.com/docs/workspace/camera), [Accessibility](https://create.roblox.com/docs/en-us/production/publishing/accessibility)
  - Shake modules: [GG Camera Shake](https://devforum.roblox.com/t/gg-camera-shake-screenshake-that-doesnt-suck/4731267), [EZ Camera Shake](https://devforum.roblox.com/t/ez-camera-shake-ported-to-roblox/98482)
  - Cutscene tools: [CineCam v3](https://devforum.roblox.com/t/plugin-cinecam-v3-%E2%80%94-build-preview-camera-cutscenes-live-in-studio-no-playtesting-needed/4713811), [CutsceneService](https://devforum.roblox.com/t/718571), [LetterBoxer](https://devforum.roblox.com/t/letterboxer-a-cool-letterboxing-module-for-cinematic-scenes/4224471), [Camera cutscene tutorial](https://devforum.roblox.com/t/how-to-create-camera-cutscenes/1629318)
  - Light performance background: [Future is Bright Phase 3](https://devforum.roblox.com/t/future-is-bright-phase-3-released/878634)

### Inferences
- **Menu flyover recipe.** On join (in ReplicatedFirst or the menu LocalScript), set the camera to Scriptable and loop a 20–40 s Catmull-Rom path through 4–6 points over the hub. Use Linear or Sine easing, at slow speed (≈5–10 studs/s), with FOV 60–70. Add a Camera-parented Blur of size ~6–10 behind the menu UI. On Play, tween to the character's shoulder over ~1 s, then set CameraType = Custom. Under ReducedMotionEnabled, use a static beauty shot instead.
- **Loading screen.** Use ReplicatedFirst + `RemoveDefaultLoadingScreen()`. Show a static camera shot or the flyover only once the place geometry has streamed in. With StreamingEnabled, request the area with `Player:RequestStreamAroundAsync` before panning to it.
- **Thumbnail/icon capture.** Build a separate photo-booth place or area with a ClockTime of golden hour (~16.5–17.5) or bright midday, ColorCorrection Saturation +0.2–0.3, Bloom on, Atmosphere Haze low, and PrioritizeLightingQuality = true. Pose rigs with the Animation Editor, set FOV ~40–50 for less distortion, and capture at high Editor Quality. Keep the in-game look close enough that thumbnails are honest.

### Gaps
- No official Roblox doc on thumbnail capture workflows was retrieved in this pass. RDC talks on lighting and cameras were not found or verified in this pass.
- Moon Animator 2's current price and distribution in 2026 were not verified. Search results mixed paid listings (e.g., a BuiltByBit listing) and "free" claims from low-quality sites.
