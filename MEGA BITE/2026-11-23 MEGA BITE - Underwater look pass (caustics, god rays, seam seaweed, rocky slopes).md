---
tags: [mega-bite, build-log, environment, lighting, underwater]
date: 2026-11-23
---
# 2026-11-23 MEGA BITE - Underwater look pass (caustics, god rays, seam seaweed, rocky slopes)

At 23:18 the owner said "do them rn": the four gaps from [[2026-11-23 Research - Underwater environment videos (DatBoiEle Roblox + Lunar9 UE5)]].
- Method: skill [[Skills/underwater-environment-build/SKILL|underwater-environment-build]].
- Built in Studio. Play-tested (0 script errors) and **saved as place version 397**. **Not published**; the owner tests and publishes.

## What was there before
- **Caustics were off.** `MB_Caustics` returns early because the `SandFloor` part was removed on 11 Nov, when the reef became terrain.
- **God rays only over the spawn reef:** 14 beams on `MB_Map.FX.ShaftAnchor`.
- **No small scatter** between cluster pieces.
- **Rock only on faces steeper than about 46°** (`MB_WorldGen`, slope > 1.05).

## 1. Seabed caustics + dapple (`StarterPlayerScripts.MB_SeabedLight`, new)
- **Our own seamless textures** (generated in Python; vault `MEGA BITE/Art/Light/`), uploaded to group 33151111, all Approved:
  - caustic web **132177715793201**
  - dapple shade **109396474578040**
  - god-ray strip **93060609067860** (spare)
- **Why tiles:** V1 lays big plates over a flat build, but our seabed is hilly. So a grid of small flat tiles follows a point a little ahead of the camera, and each tile is raycast onto the terrain and tilted to the slope.
  - 17×17 tiles (13 on medium quality, 11 on low).
  - Tile size 10, 16 or 26 studs, depending on the camera's height above the floor (big sharks see further).
- **Three textures per tile:**
  - Caustic at 26 studs per tile.
  - Caustic at 41 studs, drifting the other way (the shimmer).
  - Very soft dapple at 70 studs (never dark).
  - Offsets are world-aligned, so the pattern runs on across tiles with no seams.
- **Fades:**
  - Round fade at the edge of the grid.
  - Less with depth (FULL_DEPTH 260 below the ceiling at 170).
  - Off on slopes steeper than about 50°.
  - Off when the camera is far above the floor, or during a cutscene grade.
  - Animated at 24 Hz.
- Tuned from an edit-time preview at the spawn reef: caustic 0.85 and 0.5 of full strength (0.62 read too faint on the pale sand).

## 2. God rays everywhere (`StarterPlayerScripts.MB_GodRays`, new)
- A pool of 12 shafts (7 on low quality) in the **reef shafts' exact style** (cloned beam: texture, colours, widths, LightEmission).
  - Each lives 14–26 s and fades in and out over 3 s.
  - They spawn 70–320 studs out, mostly in front of the camera, drift slowly, and tilt the same way as the reef's sun.
- Sun weight:
  - 0 on the reef (it keeps its own 14).
  - ×0.35 in the Red Trench.
  - ×1.15 in the Titan Sea.
  - 0 during a cutscene grade.
- **Two lessons, found in the edit-time preview:**
  1. A beam with **Segments = 1 only uses the two END values** of its Transparency curve. A curve that fades at both ends (1 → 0.44 → 1) made the beams invisible. The pool uses **Segments 16**.
  2. Beam parts more transparent than about 0.55 hardly show. The reef curve (0.45 top → 1 bottom) only reads near the top, which showed as **hard square tops** with the rays ending in mid-water.
  - The pool's curve is 1 → 0.44 (at 24%) → 0.46 (62%) → 0.7 (90%) → 1, with the top at y 290. The tops are soft and the rays reach the floor (V1's look).
- Bloom left as it is (Intensity 0.75, Size 28, Threshold 1.05, owner-tuned). The shafts already glow through it.

## 3. Seaweed in the cluster seams (`ServerStorage.MB_SeamScatter`, new module, re-runnable, seeded)
- V1's Brushtool "Short seaweed" (random rotation, scale ×1–2, painted into the gaps) plus V2's "procedural only for small clutter, never caves".
- **Where:** every Open Sea and Titan Sea cluster folder with 4+ pieces (337 clusters) gets a child folder `Seams`.
  - Pieces sit just outside a host piece's footprint, never inside another piece.
  - Flat ground only (normal.Y > 0.8), at least 3.2 studs apart.
  - Sunk 8–15% into the ground, with a slight random lean.
- **What:** the game's own approved reef meshes:
  - Kelp as tufts of 2–3 blades (50%)
  - TubeSponge (18%)
  - Starfish (17%)
  - Anemone (15%)
  - Each at ×0.4–0.95 size, ×2.4 in the Titan Sea.
- **How many:**
  - 3–6 spots per cluster, **2,036 pieces** in total.
  - The first runs gave 2,834 and 3,605, which was too many, so the count was cut.
  - Cheap flags: no collision, query, touch or shadow. They sit inside MB_Map, so MB_Cull fades them by distance and pixel size.
- Run: `require(game.ServerStorage.MB_SeamScatter:Clone())()`. Remove: `...("remove")`.

## 4. Rock on the slopes (`ServerStorage.MB_SlopePaint`, new module)
- **What it does:** V2's rock layer painted on the hill sides with soft blended edges. Between slope 0.47 (about 25°) and 1.05, rock creeps in, dithered and more of it the steeper it gets. Each biome keeps its own palette:
  - N meadows → Slate
  - E sandstone → Rock
  - S limestone/salt → Slate
  - W slate → Rock
  - Titan Sea gold sand and meadow → Rock
- **Safety:** it changes **materials only**. Occupancy is written back unchanged, so the Kraken pit, eel burrow and every hand-dug spot are untouched.
  - It skips the reef plate (r < 384), the arenas, and the trench's Basalt/Ground/CrackedLava.
  - 1,584 chunks, **190,398 voxels changed**, about 30 s.
- **Undo:** `task.spawn(require(game.ServerStorage.MB_SlopePaint:Clone()).run, true)`.
- **Colours lifted (never-dark rule):**
  - Rock 70,46,66 → **106,80,102**
  - Slate 72,64,122 → **96,90,152**
  - Also written into `MB_WorldGen.G.colours()`, with a note there: re-run MB_SlopePaint after any `G.write`.
- No re-bake needed: heights didn't change.

## Checks
- Play (Studio, Leviathan test account at the reef):
  - 0 errors from game scripts (only core-UI and plugin noise).
  - Seabed tiles active (221 lit).
  - 12 shafts at 16 segments.
- Frame rate: about 40 fps with the new layers vs about 42 without (Studio, Heartbeat count over 4 s).
- Edit-time screenshots are in `MEGA BITE/Art/Light/`.

## Not done / not checked
- **Phones:** not tested.
- **Shark-height look in Play:** god rays and caustics were judged in edit-time previews, because the test shark can't be moved by script (the swim controller pins it back), so the in-Play view wasn't checked at shark height in the Open Sea.
- **Quality-nerd kid sim:** not re-run.
- **Old script:** `MB_Caustics` is now dead code (it returns at once) and was left in place.
