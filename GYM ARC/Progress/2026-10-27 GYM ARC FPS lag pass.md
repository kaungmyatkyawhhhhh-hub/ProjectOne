---
date: 2026-10-27
tags: [gymarc, progress]
status: done
---
# FPS lag pass (prompt 78)

Back to [[00 GYM ARC Home|GYM ARC Home]]. Prompt: [[2026-10-27 GYM ARC Prompt - 78 FPS lag check]].

## How it was measured
- Frame times per spot, a spike log, Roblox's ScriptProfilerService on the client (`ClientStart(player, 1000)`, `ClientRequestData(player)`, `OnNewData`), and A/B switching kinds of objects off on the client from a fixed camera.
- Scripts: ~2.7 ms a frame on this PC (heartbeat ~2 ms, physics ~1 ms). Looking at the empty sky = 59 FPS, so the frame rate is limited by **drawing the world** (render), not scripts. Studio numbers on this PC swing a lot between runs (the same beach view 30 vs 53), so there's no clean before/after number.
- A/B at the beach (base ~30): no NPCs 55, no see-through parts 46, no particles 40, no SurfaceGuis 39, no lights 37, no shadows 35.

## Fixed
- **Far NPCs not drawn** (`NpcCullingClient`): beyond 110 studs an NPC is fully see-through on this client (LocalTransparencyModifier, also new pieces), back when closer; distance only. The far-tier effects sweep only on a tier change (it walked every far NPC every 2 s).
- **MachineClient**: the per-frame loop only visits machines in use / posed / yours (list rebuilt 4x a second; it walked all 132 machines every frame); the prompt text refresh caches each machine's prompts and writes only changed text (it walked 36,287 machine parts every 2 s, an ~11 ms hitch).
- **BlobShadowClient**: no ray for a body that hasn't moved.
- **MuscleRig**: other bodies further than 45 studs refresh their stage meshes at 2 Hz (was 10).
- **SurfaceGuis**: 91 with no distance limit capped at 250 studs (MaxDistance).
- Checked: own lifting still animates (bar travels its full range); NPC lifters on screen animate (off-screen ones stay still by design).

## Left for the owner (visual choices)
- See-through parts: window glass on the far city buildings and the Powerlifting front, the Pro gym's light beam parts (Lights58), skate park glass.
- 301 lights, 1,036 Glass parts, Lighting.EnvironmentSpecularScale 0.7.
- Part of the profile was the Studio plugin "Superbullet AI Game Builder" (not in the real game).
- (owner: "make the far city and powerlifting windows swap glass for a cheaper material") Glass -> SmoothPlastic: far city (`Backdrops`, 500), Powerlifting front (45) and shell (14). Panes at 0.1-0.3 transparency made solid, the clearer 0.5 ones keep a little see-through; reflectance at least 0.15 so they still read as windows. Each part keeps `WasGlass` / `WasTransparency` attributes (one Ctrl+Z step "Perf: glass windows to SmoothPlastic"). Looks the same from the street.
- Correction: the Pro gym "light beam parts" (ProGym.Lights58) are its big tinted window panes (FrontGlassUpper x2, EastGlass 85 studs long; SmoothPlastic, 82% see-through), not light beams.
- (owner: "change the windows on the townbuildings to smoothplastic and their color to be same as the original") `Town.Buildings`: 424 Glass parts -> SmoothPlastic, colour / transparency / reflectance unchanged (checked: 0 colours changed), `WasGlass` attribute, one Ctrl+Z step. 69 Glass parts left in the whole game. Done in the Studio opened from GABACKUP2.rbxl (owner's account rongstrix).
