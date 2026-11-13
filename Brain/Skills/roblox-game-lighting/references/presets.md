# Lighting presets

Every preset is a full set: Lighting properties, Atmosphere, Bloom, SunRays, ColorCorrection, DepthOfField, Sky hints. Colours are RGB 0–255. `scripts/apply_preset.luau` has the same tables in code (keep them in sync when you add one).

**Status:**
- **[video]** means the values are read off the tutorial's Properties panel frame by frame.
- **[live]** means the values come from a shipped game.
- **[start]** means a tuned starting point: apply it, screenshot it, then adjust by eye.

## How to adapt any preset in 60 seconds
1. Time of day first (`ClockTime`): 6–7 sunrise, 9–11 clean morning, 13 noon (flat, short shadows), 16.5–17.5 golden hour, 18–18.5 sunset, 0–4 night.
2. Move `Ambient` toward the sky colour of that time, darker. Move `OutdoorAmbient` toward the light colour.
3. Atmosphere `Color` = horizon haze colour (near white by day, orange at sunset, deep blue at night). `Decay` = the far colour, a little darker and more saturated.
4. ColorCorrection `TintColor` pushes everything slightly toward the mood colour. Keep it close to white: a channel below ~215 is a heavy filter.

---

## 1. Stylized day: "Make your game look 10x better" (Develuper) [video]
A clean, crisp, slightly blue morning with sharp shadows and punchy contrast. Best for obbies, stud-style maps, adventure games and simulators with a bright art style. The before/after in the video goes from the default grey baseplate to an "RTX ON" look.

| Object | Property | Value |
|---|---|---|
| Lighting | LightingStyle | Realistic |
| | PrioritizeLightingQuality | true |
| | Brightness | 3 |
| | Ambient | 84, 107, 156 |
| | OutdoorAmbient | 117, 120, 145 |
| | ClockTime | 9.6 |
| | GeographicLatitude | 7 |
| | ShadowSoftness | 0.2 |
| | EnvironmentDiffuseScale / EnvironmentSpecularScale | 1 / 1 |
| | GlobalShadows | true |
| Atmosphere | Density / Offset | 0.34 / 0 |
| | Color / Decay | 199,199,199 / 106,112,125 |
| | Glare / Haze | 2.86 / 1.27 |
| Bloom | Intensity / Size / Threshold | 1 / 56 / 2 |
| SunRays | Intensity / Spread | 0.048 / 0.895 |
| ColorCorrection | Brightness / Contrast / Saturation | 0 / 0.3 / 0.5 |
| | TintColor | 226, 238, 255 |
| Sky | | a bright cartoon-cloud skybox from the toolbox |
| Baseplate (optional) | | Studs MaterialVariant, or a Studs `Texture` at Transparency 0.775, StudsPerTile 8 |

Extras from the same video:
- **Random textures** on map parts: Transparency 0.675, StudsPerTile 7, all 6 faces. Texture IDs from the video: `rbxassetid://10044626935`, `10025439383`, `10024249523`, `10025395487`. Tone steps on the part colour: −0.12, −0.05, +0.05, +0.175. See `scripts/random_textures.luau`.
- **Highlight on players** for a retro, 2D-ish look ("people said it looked like Block Tales"). Set `DepthMode = Occluded` so it does not show through walls. See `scripts/retro_highlight.luau`.

Why it works:
- Bloom Threshold 2 means only really bright things glow (sun glints, neon), so white parts don't smear.
- The Atmosphere gives depth without a grey wall.
- The blue-ish Ambient colours the shadows.
- Contrast 0.3 is what makes it "sharp".

## 2. Kid simulator / cartoon noon [start]
Bright, saturated and soft. Shadows are there but gentle. Best for pet sims, clickers and tycoons where UI and pickups must read on any phone.

| Object | Values |
|---|---|
| Lighting | LightingStyle Soft, Brightness 2.6, Ambient 110,125,160, OutdoorAmbient 140,140,150, ClockTime 12.5, GeographicLatitude 20, ShadowSoftness 0.5, EnvDiffuse 1, EnvSpecular 0.6 |
| Atmosphere | Density 0.28, Offset 0, Color 215,230,255, Decay 120,150,200, Glare 0.4, Haze 0.8 |
| Bloom | 0.6 / 30 / 1.6 |
| SunRays | 0.06 / 0.7 |
| ColorCorrection | Brightness 0.02, Contrast 0.18, Saturation 0.35, Tint 245,250,255 |

## 3. Golden hour [start]
Long warm shadows and an orange haze. Best for lobbies, menus, emotional moments and "chill" games.

| Object | Values |
|---|---|
| Lighting | LightingStyle Realistic, Brightness 2.4, Ambient 95,85,120, OutdoorAmbient 150,120,110, ClockTime 17.2, GeographicLatitude 25, ShadowSoftness 0.25, EnvDiffuse 1, EnvSpecular 1 |
| Atmosphere | Density 0.36, Offset 0, Color 255,200,160, Decay 150,95,110, Glare 3, Haze 1.6 |
| Bloom | 0.9 / 40 / 1.7 |
| SunRays | 0.12 / 0.6 |
| ColorCorrection | Brightness 0, Contrast 0.22, Saturation 0.3, Tint 255,240,225 |

## 4. Overcast / calm [start]
Flat soft light with no harsh shadows. Best for rainy maps, cozy towns and puzzle games where shadows confuse the player.

| Object | Values |
|---|---|
| Lighting | LightingStyle Soft, Brightness 1.6, Ambient 120,128,140, OutdoorAmbient 150,155,165, ClockTime 13, ShadowSoftness 0.9, EnvDiffuse 1, EnvSpecular 0.4 |
| Atmosphere | Density 0.42, Offset 0, Color 200,205,212, Decay 120,128,140, Glare 0, Haze 2 |
| Bloom | 0.3 / 24 / 1.8 |
| SunRays | off (Enabled false) |
| ColorCorrection | Brightness 0, Contrast 0.12, Saturation 0.05, Tint 240,245,250 |

## 5. Readable night [start]
Moonlit blue with warm lamps. It's dark in mood but still playable on a phone.

| Object | Values |
|---|---|
| Lighting | LightingStyle Realistic, Brightness 1.2, Ambient 45,55,90, OutdoorAmbient 70,80,125, ClockTime 0.5, GeographicLatitude 30, ShadowSoftness 0.4, EnvDiffuse 1, EnvSpecular 1 |
| Atmosphere | Density 0.38, Offset 0, Color 70,90,140, Decay 25,30,60, Glare 0, Haze 1.4 |
| Bloom | 1 / 36 / 1.2 (lamps and neon glow) |
| SunRays | off |
| ColorCorrection | Brightness 0.03, Contrast 0.2, Saturation 0.1, Tint 225,232,255 |
| Sky | stars on (StarCount 3000+), moon visible |

Add PointLights (Brightness 1–2, Range 16–24, warm 255,190,120) along paths. Night without light sources reads as a broken map.

## 6. Horror [start]
Cold, desaturated and foggy close-in, with a sickly tint. Contrast comes from flashlights and lamps.

| Object | Values |
|---|---|
| Lighting | LightingStyle Realistic, Brightness 0.8, Ambient 30,32,40, OutdoorAmbient 45,50,60, ClockTime 2, ShadowSoftness 0.3, EnvDiffuse 0.6, EnvSpecular 0.6 |
| Atmosphere | Density 0.55, Offset 0.1, Color 90,100,95, Decay 20,25,25, Glare 0, Haze 2.5 |
| Bloom | 0.5 / 24 / 1.4 |
| SunRays | off |
| ColorCorrection | Brightness −0.02, Contrast 0.25, Saturation −0.35, Tint 225,240,230 |
| DepthOfField | optional, FarIntensity 0.15, FocusDistance 30, InFocusRadius 30 |

Horror is the one genre where Density over 0.5 is right: what you can't see is the point. Still give the player a light (a flashlight SpotLight on the character).

## 7. Neon / sci-fi [start]
Dark base with glowing parts. Neon material and lights do the work.

| Object | Values |
|---|---|
| Lighting | LightingStyle Realistic, Brightness 1, Ambient 40,30,70, OutdoorAmbient 60,50,110, ClockTime 22, ShadowSoftness 0.3, EnvDiffuse 1, EnvSpecular 1 |
| Atmosphere | Density 0.35, Offset 0, Color 120,80,200, Decay 40,20,90, Glare 0.5, Haze 1.5 |
| Bloom | 1.2 / 40 / 0.95 (Neon parts glow; keep white parts off Neon) |
| SunRays | off |
| ColorCorrection | Brightness 0, Contrast 0.25, Saturation 0.4, Tint 235,225,255 |

## 8. Underwater reef: MEGA BITE base look [live, 14 Nov 2026]
An ocean game where the whole map is under water. The look comes from a teal Atmosphere with a deep-blue Decay (the far water) and a cool tint. There's no visible sun; SunRays is kept low and reads as light from above. `MB_BiomeMood` blends per-biome changes on top of this base at runtime (kelp green, golden kingdom, misty graveyard, violet glow gardens, red trench), and the owner's rule is "lighting never dark".

| Object | Values |
|---|---|
| Lighting | LightingStyle Soft, Brightness 1.9, Ambient 70,95,125, OutdoorAmbient 95,125,160, ClockTime 13, GeographicLatitude 0, ShadowSoftness 0.6, EnvDiffuse 0.85, EnvSpecular 0.45, ExposureCompensation −0.1, ColorShift_Top 190,225,255 (a cool blue on sun-lit tops = light from the surface) |
| Atmosphere | Density 0.40, Offset 0.18, Color 46,150,196, Decay 10,38,98, Glare 0.15, Haze 1.9 |
| Bloom | 0.75 / 28 / 1.05 |
| SunRays | 0.13 / 0.5 |
| ColorCorrection (`MB_ColorCorrection`) | Brightness 0, Contrast 0.26, Saturation 0.38, Tint 236,248,255 |
| DepthOfField | FarIntensity 0.18, FocusDistance 70, InFocusRadius 90, NearIntensity 0 (only far water blurs = murky distance; the play area stays sharp) |
| Sky | CelestialBodiesShown false, StarCount 0 |

Underwater rules:
- No sun disc and no stars.
- A higher Offset (0.15–0.2) lifts the haze toward the surface.
- Density 0.35–0.45.
- The Decay is much darker and bluer than the Color.
- Biome moods change the Atmosphere Color/Decay/Density and ColorCorrection Tint/Saturation by small amounts (Density ±0.03, Saturation ±0.06).
- Deeper or further = darker Decay and +Density, but never so dark the owner's "never dark" rule breaks.

---

## Zone / biome moods (any game)
Keep one base preset and store each zone as **deltas** from it, in a table a client script blends between (lerp over ~1.5 s as the player crosses a border):
- Change: Atmosphere Color, Decay, Density (±0.05); ColorCorrection TintColor, Saturation (±0.1), Brightness (±0.03).
- Don't change per zone: LightingStyle, ShadowSoftness, Bloom Size (switching them looks like a glitch).
- The script must cache the base on start and always blend from the base, never from the current value (or moods drift).
- Cutscenes and hit flashes get their own ColorCorrection object, so they don't fight the zone script.
