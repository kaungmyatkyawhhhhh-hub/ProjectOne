# Prompt: fix buildings that turn black or white depending on where you look from

_For Claude Code with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras._

## The problem (owner, 2026-11-03)
Some buildings' colours glitch: from one spot a wall looks **black**, then from another angle it looks **white**. The owner hates it. **Find every cause and fix it everywhere, with no bugs left.**

## Before you start
- Read `CLAUDE.md`, `Games/CityLegends/CLAUDE.md` (notes on stand-ins, far buildings, building skins, the facade textures) and `City Legends/City Legends.md`.
- Call `list_roblox_studios` and use the Studio named **City Legends** only. Save a backup first.
- **Reproduce it first:** find the spots in Riviera Bay where it happens (drive / walk round, day and night, near and far, PC and phone-size, all graphics levels). Take screenshot pairs (the same wall from two angles). List each case with its position and the building / part.

## Likely causes: check every one
1. **Z-fighting:** two faces in the same place (e.g. the building "skin" panels sitting exactly on the dark core behind them, a window panel on the wall, duplicate parts). The renderer flips between them depending on the angle, so the wall flickers dark / light. **Fix:** move the outer layer out a little (about 0.02–0.05 studs), delete duplicate overlapping parts, and never let two surfaces share a plane.
2. **Reflections / shininess:** parts with high `Reflectance`, `Glass`, `SmoothPlastic` or `Foil`, or SurfaceAppearance with a high metalness or a low roughness, mirror the sky. At some angles they reflect the dark sky or ground (black); at others the bright sky (white). **Fix:** walls get non-reflective materials (plaster / concrete / stone MaterialVariants, metalness 0, roughness about 0.7–0.9); only real glass windows reflect, and they reflect softly.
3. **Wrong normals on imported meshes:** faces pointing inward or a negative scale make a side render black (or see-through) from one direction. **Fix:** recalculate normals in Blender (or flip the bad faces), remove negative scales, set `DoubleSided` only where really needed, and re-import.
4. **Far-building stand-ins / LOD:** the `City.Standins` copies and the streaming LOD switch between the real building and a stand-in, which can show black shapes or a different colour when the angle / distance changes (this happened before with `StreamingMesh`). **Fix:** stand-ins use the same colours and materials as the real building; the switch distance is the same in every direction; no black stand-ins; no double drawing (real + stand-in both visible).
5. **Lighting leaks / shadows:** big flat walls inside each other, or a part inside a wall, can cast wrong shadows that appear and disappear with the camera. Inside-out or very thin parts can catch odd light. **Fix:** remove hidden parts inside walls, `CastShadow = false` on small or hidden detail (already done for many), and check walls at day and night.
6. **Textures:** Texture / Decal objects on a face with transparency or the wrong face, facade textures (BuildingSkin) failing on some clients, or the "emissive" (lit windows) applying in daylight. **Fix:** every texture on the right face, no half-transparent wall textures, lit-window glow only at night.
7. **Lighting settings:** `EnvironmentSpecularScale` / `EnvironmentDiffuseScale`, the sky and the colour correction can make shiny walls swing between black and white. Tune them so walls stay stable from every angle.

## Fix it everywhere
- Fix the cause in the **building tools** (`tools/riviera/Buildings.luau`, `FarCity.luau`, the stand-ins tool, `BuildingSkin`, the Toolbox / imported building pieces), not just by hand, so new buildings don't get it, and rebuild / update the affected buildings in the place.
- Go through **every building** in Riviera Bay (and the venues), not just the ones the owner saw.
- Don't make buildings look worse: they keep their colours, materials and night windows.

## Check before you say done
- The same screenshot pairs as before, now **matching from every angle** (before / after), day and night, near and far.
- Drive a full loop of the map in Play and watch for any flicker, black or white flashing, or colour changes. Do it on PC and phone-size, at low and high graphics.
- An automatic check where possible: scan every part for overlapping coplanar faces, high reflectance on walls, negative scales and inverted meshes; the list must be empty.
- FPS before and after (no slower).
- Save the place, commit and push the tools; note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- what caused it;
- what you fixed;
- before / after screenshots;
- anything still to check.
