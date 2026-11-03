# Prompt: make every road as smooth as possible (especially on curves)

_For Claude Code with Roblox Studio connected (MCP) and Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras._

## The problem (owner, 2026-11-03: "the roads aren't smooth, especially on curves, and I really hate it")
The Riviera roads are built from many **straight block parts** (`tools/riviera/Roads.luau`: one slab per run of samples, plus separate pavement, kerb and line parts). A curve made of straight blocks is never truly smooth:
- the outer edge of a bend shows **steps / saw teeth**, and the inner edge **overlaps**;
- kerbs, pavements and white lines are **zig-zag** on curves and don't line up;
- slope changes make small **kinks / bumps** (about 360 spots over 0.3 studs were found, mostly on inner lanes of tight bends and junction corners);
- junction corners are rough.

## The fix: real curved road meshes
Build the roads as **continuous meshes** that follow the curve exactly, instead of blocks:
1. **Generate the road surface in Blender** from the same road data (`build/riviera/roads.json`, `tools/map_plan/network.py` / `export_roads.py`):
   - a smooth **ribbon** for each road: points every 1–2 studs on curves (denser on tight bends, fewer on straights), heights from the solved road profile, smoothed so slopes change gently (no kinks);
   - one ribbon per road chunk (each under ~10–15k triangles so Roblox imports it), with the chunks' ends sharing exactly the same vertices, so there's no seam or step between them;
   - **junctions** as one shaped mesh each (a smooth fill between the roads, with rounded corners), joined vertex-to-vertex with the road ribbons;
   - **kerbs** as a curved extruded profile (a small rounded bevel) following the road edge; **pavements** as curved ribbons beside them; both continuous on curves.
2. **White lines:** either drawn into the asphalt texture along the ribbon (UV along the road, so dashes stay evenly spaced and curve smoothly), or thin curved line meshes just above the surface (no z-fighting). Zebra crossings at junctions as before.
3. **Materials:** a tiling asphalt texture (PBR: colour, normal, roughness) mapped along the road so it doesn't stretch on curves, with slight wear; pavements and kerbs keep their current colours / patterns (`RivPaveBasket`, `RivPaveHerring`, `RivCobble`, the red-pink pavers, the stone kerbs).
4. **Import** the meshes into the place (pack them for Import 3D, or the MCP); put them under `Workspace.Riviera.Roads` replacing the block roads. Keep a backup of the old block roads in `ServerStorage` until the owner approves.
5. **Collision (very important, so cars never bump):**
   - the drivable surface must be **perfectly smooth for the car's physics**. Give the road meshes `CollisionFidelity = PreciseConvexDecomposition` and check, **or** (better) make a separate invisible collision ribbon from many thin **wedge pairs** that follow the same smooth surface exactly (each triangle = one wedge), with the visible mesh set to `CanCollide = false`;
   - no gaps, no tiny steps at chunk ends or junctions.
6. **Banking and slopes:** gentle camber on bends where it looks natural; slopes and crests smoothed so cars don't jump or scrape at speed.
7. **Keep the rest working:** the traffic lane graph (`src/shared/RivieraLanes.lua`, `export_lanes.py`) follows the same smoothed curves; road islands, curve walls, speed bumps (only where they're meant to be), the bump checker, minimap drawing, races and chauffeur routes.
8. **Performance:** fewer parts than now (one mesh replaces many blocks): report the part / triangle count and FPS before and after. Streaming and LOD still work (chunk the roads so far chunks can stream out).

## Check before you say done
- Run the **bump checker** (`Roads.check`) on every lane: **zero steps over 0.05 studs**, on straights, curves, hairpins and junctions.
- Drive every road in Studio at low and high speed, with a light hatch and a hypercar: no bumps, no jolts, no shaking on curves, nothing catching the wheels.
- Close-up screenshots of tight bends and junctions **before / after** (road edge, kerb, lines, pavement): no saw teeth, no zig-zags, no overlaps, no flicker.
- Traffic drives the new roads without problems.
- FPS / part counts before and after (PC + phone size).
- Save the place, commit and push the tools; note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- what changed;
- before / after screenshots of curves and junctions;
- the bump checker result;
- FPS before and after.
