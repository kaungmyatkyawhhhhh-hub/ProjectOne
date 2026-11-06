---
date: 2026-11-02
tags: [galaxy, lighting, prompt]
status: todo (Claude Code)
---

> **REPLACED 7 Nov (launch day):** the owner found the game "mostly dark". The values are now in [[2026-11-07 Galaxy Incremental - Launch-day fixes]] (section 3): a bright daytime play space, the space mood in the sky only.

# Galaxy Incremental - lighting pass (2 Nov)

Studio check (Edit, 2 Nov): Brightness 1.7, ClockTime 10.5 (daytime sun), Ambient (70,58,80), OutdoorAmbient (112,100,112), EnvDiffuse 0.35, EnvSpec 1.0, GlobalShadows on; Sky = galaxy skybox (group); Bloom 0.32/18/2.1; ColorCorrection "GalaxyGrade" contrast 0.10 sat 0.10 warm tint; Atmosphere density 0.18; 3 lights in the map.
Only small fixes were done so far (bloom lowered, warm grade, fewer lights). No real lighting design yet.

## Look we want (space, concept v3)
- The CORE is the sun of the scene: warm gold light comes from the centre; islands get a warm side facing the Core and a violet/blue rim on the far side.
- Space ambient = dark violet, not grey; shadows soft violet, not black.
- Brass reads as metal (shiny), stone warm cream; neon only on interactive things (boards, gates).
- Each island's own star lights its island a little (feel: "my star lights my island"), getting stronger with the tier.
- Far distance fades into violet space (no white haze).

```text
GALAXY INCREMENTAL (P&L Studios XP, never GYM ARC): LIGHTING PASS. Read Celestial Incremental\2026-11-02 Galaxy Incremental - Lighting pass.md. Put every value in MapConfig.Lighting (one table, applied by a script so it can be tuned).
1) Sun direction: set ClockTime/GeographicLatitude so the sun comes roughly FROM the Core's side at a low angle (warm key light), Brightness ~2, sun colour warm (Lighting.ColorShift_Top slightly gold). GlobalShadows on, ShadowSoftness ~0.3.
2) Ambient: Ambient ~(45,35,70), OutdoorAmbient ~(85,70,120) (violet, shadows never black). EnvironmentDiffuseScale 0.6, EnvironmentSpecularScale 0.8 so brass/metal pick up the galaxy sky.
3) Atmosphere: Density ~0.25, Color dark violet (60,40,90), Decay (25,15,45), Glare 0, Haze 0.5 -> far islands fade into violet, not white.
4) Post: Bloom Intensity 0.4, Size 24, Threshold 1.8 (only neon/Core glow, no blown-out centre); ColorCorrection Contrast 0.15, Saturation 0.15, slight warm tint; no SunRays, no DepthOfField.
5) Lights (keep it cheap): Core PointLight warm gold range 60 brightness 2; each island's star a PointLight range 20 -> 32 by tier (warm/ the star's colour), Shadows off; boards light themselves with their neon (no extra lights). Max ~12 lights in a full server.
6) Materials: brass = Metal or SmoothPlastic with Reflectance 0.15 + gold colour (#D9A441); stone warm cream; check the kit meshes use the right materials.
7) Low-end devices (phones / slow PCs): Bloom off, island star lights off, shadows off.
8) Screenshots before/after: spawn view, wide view from the centre, an island from the bridge, phone. FPS with 8 players. Progress note.
```
