# Lighting API: what each property really does

Checked live in Roblox Studio through the Studio MCP on 14 Nov 2026. "Default" is what `Instance.new` gives (a new effect object). The Lighting service values in a new place differ by template.

## Lighting service

| Property | Range that's useful | What it does |
|---|---|---|
| `LightingStyle` (Enum.LightingStyle) | `Realistic` / `Soft` | Realistic = crisp sun shadows and stronger light contrast (the Develuper pick). Soft = gentler, more cartoon/flat. |
| `PrioritizeLightingQuality` (bool) | true for showcase maps | Asks the engine to keep lighting quality over other things on weaker devices. |
| `Technology` (Enum.Technology) | Future / ShadowMap / Voxel / Compatibility / Legacy / Unified | **Not readable or writable from the Studio plugin** ("lacking capability"). Set it in the Properties panel and say so. Future = per-light shadows and specular (best), ShadowMap = sun shadows only, Voxel = old soft blocky light. |
| `Brightness` | 1–3 (night 0.8–1.2) | Sun/moon strength. Above ~3.5, white parts clip. |
| `Ambient` | colour | **Shadow tone**: the colour where the sun doesn't reach (indoors, under things). Give it a blue/purple tint; never pure black. |
| `OutdoorAmbient` | colour | The fill on the outdoor lit side (sky light). Warmer or neutral. |
| `ClockTime` | 0–24 | Sun position. 9–11 = clean, readable shadows; 12–13 = flat; 16.5–18 = golden. |
| `GeographicLatitude` | 0–60 | Tilts the sun's path. Low (≈7) = sun more overhead in the morning; higher = longer shadows. |
| `ShadowSoftness` | 0.1–0.9 | Sun shadow edge blur. 0.2 = crisp (stylized), 0.6+ = soft (cozy/underwater). |
| `EnvironmentDiffuseScale` | 0–1 | How much the sky lights surfaces. 1 = richer colour in the shade. |
| `EnvironmentSpecularScale` | 0–1 | Sky reflections on smooth/metal materials. 1 = shiny metal looks right; lower if plastic looks wet. |
| `ExposureCompensation` | −0.5…+0.5 | Moves everything. Use it for small final trims only. |
| `GlobalShadows` | true | Off kills all depth. |
| `FogEnd` / `FogStart` / `FogColor` | — | **Ignored while an Atmosphere exists.** Use the Atmosphere instead. |
| `ColorShift_Top` / `ColorShift_Bottom` | colour | Tints the sun-lit top and bottom faces. Rarely needed; leave black. |

## Atmosphere (child of Lighting)
Defaults (Instance.new): Density 0.395, Offset 0, Color (199,170,107), Decay (92,60,13), Glare 0, Haze 0.

| Property | Useful | What it does |
|---|---|---|
| `Density` | 0.28–0.45 land, 0.35–0.45 underwater, 0.5+ horror | How thick the air is: the distance fade. |
| `Offset` | 0 land, 0.1–0.2 underwater | Pushes the haze toward the horizon or up. 0 keeps the near world clear. |
| `Color` | near-white by day | The colour of the near haze and the light scattering. |
| `Decay` | darker, more saturated | The colour things fade to far away. |
| `Glare` | 0–3 | The glow around the sun. A little = warm, airy. |
| `Haze` | 0–2.5 | Haziness at the horizon; mixes Decay in. A little darker haze gives depth. |

## Post effects (children of Lighting, or of the Camera for one player only)

| Effect | Defaults | Useful | Notes |
|---|---|---|---|
| `BloomEffect` | Intensity 0.4, Size 24, Threshold 0.95 | Intensity 0.5–1.2, Size 24–56, Threshold 1.2–2 | Threshold is the brightness a pixel needs before it glows. Below 1 = white parts and white UI-coloured parts glow. Raise it to keep sand/snow clean. |
| `SunRaysEffect` | Intensity 0.25, Spread 1 | Intensity 0.03–0.15, Spread 0.5–0.9 | Only shows when the sun is on screen. Strongest look at sunrise/sunset. 0.25 (default) is too strong for most games. |
| `ColorCorrectionEffect` | 0 / 0 / 0, Tint white | Contrast 0.12–0.3, Saturation 0.05–0.5, Brightness −0.03…0.05, Tint ≥ 215 per channel | The "grade". Contrast first. Name it, because runtime scripts tween it. |
| `DepthOfFieldEffect` | Far 0.75, FocusDistance 0.05, InFocusRadius 10, Near 0.75 | Gameplay: FarIntensity ≤ 0.2, NearIntensity 0 | The defaults blur almost everything. Strong DOF is for menus, cutscenes and photo modes. |
| `BlurEffect` | Size 24 | 0 in play; 8–16 behind windows | UI backdrops. Turn it off when a 3D-in-front-of-camera card is shown, or the card blurs too. |

## Sky
Defaults: SunAngularSize 21, MoonAngularSize 11, StarCount 3000, CelestialBodiesShown true, SkyboxOrientation (0,0,0).
- Six `Skybox*` textures, from the toolbox ("don't overthink it": pick one that matches the time of day).
- `CelestialBodiesShown = false` for underwater, indoor-only or "no sun" looks.
- `SkyboxOrientation` rotates the sky so the sun in the sky art lines up with the real sun direction.

## Clouds (child of Terrain)
Defaults: Cover 0.5, Density 0.7. Real 3D clouds that move. Cover 0.3–0.6 for a nice day. Phones render them cheaper.

## Highlight
Defaults: DepthMode AlwaysOnTop, FillTransparency 0.5, OutlineTransparency 0, OutlineColor white, FillColor red.
- For a retro outline: `DepthMode = Occluded` (not through walls), `FillTransparency = 1`, a dark `OutlineColor` (20,20,30).
- **At most 31 Highlights render at the same time** in one client. Use them for players or a few important objects, not every NPC.
- Parent a Highlight to the character (its `Adornee` defaults to the parent).

## Textures and MaterialVariants
- `Texture` (unlike `Decal`) tiles: `StudsPerTileU/V`, `Face`, `Transparency`, `Color3`. One per face, so 6 for a full part.
- **MaterialVariant** (in MaterialService) replaces the look of a base material everywhere it's used, or per part via `MaterialVariant`. It's better than thousands of Textures for a whole-map change.
- Every Texture costs draw time. The random-texture trick is for map parts (hundreds), not for thousands of tiny props.

## Lights
- `PointLight` / `SpotLight` / `SurfaceLight`: Brightness 0.5–3, Range 8–30, `Shadows` true only on the few that matter (each shadowed light costs a lot on Future).
- Neon material + Bloom gives "lights" for free, with no light objects.
- Phones show far fewer shadowed lights. Design so the scene still reads without the light's shadows.
