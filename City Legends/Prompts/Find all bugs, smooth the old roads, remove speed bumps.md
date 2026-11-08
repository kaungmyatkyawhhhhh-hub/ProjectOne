# Prompt: find and fix every bug, make the old roads as smooth as the new ones, remove all speed bumps

_For Claude Code on the PC, with Roblox Studio connected (MCP). Read all of this first, plus `Games/CityLegends/CLAUDE.md` (the road tools and traps) and `Smooth roads.md`. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. **No errors:** if something can't be fixed cleanly, leave it as it was and write it at the top of the notes._

## What the owner wants (2026-11-08)
"Find all bugs and make all the roads smooth like the hairpin, because I see some roads which are bad, and remove all speed bumps." Then: "**The new roads, like the highway and some of the curves, are good. The old ones are bad.**"

The owner allows map edits for this job: edit the baked map in the open Studio place (Edit mode), **never** `rojo build` over the place. Backups first (`ServerStorage`, dated), and every tool's `undo` kept.

## Part 1: remove all speed bumps
- Every speed bump made by `tools/riviera/SpeedBumps.luau` (tag `"SpeedBump"`, in `Workspace.Riviera.Dressing` or wherever they are; search the whole place for the tag and for parts named like bumps) goes to `ServerStorage.SpeedBumpsRemoved` (a backup, not deleted).
- Fill / smooth the road where each one stood if anything is left (a dip, a seam, a line gap): the road must be flat and smooth there.
- Traffic: remove the slow-down for bumps (or leave it doing nothing with no bumps); traffic must not slow at the old bump spots.
- Don't add any new speed bumps (the tool stays in `tools/` but isn't run).
- Check: drive every old bump spot: no bump, no jolt.

## Part 2: make the OLD roads as smooth as the NEW ones
**The good ones (keep them, use them as the standard):** the Riviera Highway, the Summit Pass, the north roads (Corniche Highway, Serpent Road and links), the Loop link, the Straight link, the Grand Hairpin, and any road already rebuilt as smooth meshes (`tools/road_mesh`, `RoadMeshes.luau`).

**The bad ones (rebuild):** the **older Riviera roads**: the original streets and routes built from triangle parts (the first `Roads.build` of the Monaco map), their junctions, kerbs, pavements and lines.

### Find them
- Drive **every old road** in Play (both directions, slow and fast, in a hatch, an SUV and a supercar) and look from straight above too. List each bad spot with a screenshot: steps, bumps, kinks, saw-tooth edges, sharp corners in curves, seams between pieces, holes, flicker, kerbs out of line, lines off the road, junction bumps, places the car jolts or the camera shakes, ground poking through.
- Run the checkers on **all lanes**: `tools/riviera/LaneCheck.luau` (holes, things in the lane, kinks), `SurfaceCheck.luau` (overlapping faces), and the world / graph tests.

### Rebuild them like the new roads
- Use the methods that made the good roads: smooth **road meshes** (`tools/road_mesh/`: `collect.py` → `build.py` → `export_fbx.py` → upload through Open Cloud → `RoadMeshes.luau` `place` / `hide`, with `undo`), smooth centrelines with gentle grades (as in `highway.py` / `looplink_design.py`), curves with a proper radius (no kinks), banking where sensible, and the junction mouth method (`Reshape.apply`, `HoleFill`).
- After each area: `SmoothKerbs.run`, `PaveOverlap.run`, `SurfaceFix.run(roads, { onlyUp = true })`, `RoadLines`, then `LaneCheck` (**0 problems**), and traffic driving through for a few minutes without getting stuck.
- Kerbs, pavements, lines and walls follow the new smooth road; red-and-white kerbs on sharp bends; guard rails / walls where there's a drop; nothing in the lanes.
- Keep the old parts' collision where the notes say to (Transparency 1 road parts still collide), unless the new meshes fully replace it and it's tested.
- Keep the map's look (Monaco style, materials, the 1+1 streets / 2+2 routes rule).
- Do it **area by area** (one district at a time), saving, committing and pushing after each, with before / after screenshots (from the road and from above).

## Part 3: find and fix all bugs (the whole game)
- **Play the whole game** as a **new player** and as a **high-level player**, on **PC** and **phone size (667 × 375)**, with **2 players**:
  - the first 3 minutes, the starter pick, driving, traffic, police, races, drift / speed traps / jumps;
  - delivery jobs, the chauffeur, the bank;
  - the dealer, the Workshop / Part Shop, Customs, car levels and classes, the repair shop, fuel and gas stations, damage, trailers, doors;
  - houses, the hotel, the towers, Legends Rewards, the main menu, fast travel, settings, saves (rejoin).
- **Check the console** (server and client) the whole time: every error and warning is a bug.
- Write **every bug** in a list in the notes, worst first: what, where, how to make it happen, screenshot. Include stuck spots, things floating or clipping, grey parts, see-through walls, UI that overlaps or doesn't fit on phone, buttons that do nothing, wrong prices, lag spikes.
- **Fix them all** that can be fixed safely, one at a time, re-testing each fix. For any you can't fix safely, write why at the top of the notes.
- Measure FPS at the 3 usual spots before and after (it must not get worse).

## Check before you say done
- Speed bumps: none left anywhere; their spots are smooth; traffic doesn't slow there.
- Roads: the list of bad spots, each fixed with before / after screenshots; `LaneCheck` 0 problems on every lane; traffic runs for 5 minutes with no stuck cars; a drive round the whole map in a supercar at speed with no jolts.
- Bugs: the list, with each one fixed or explained.
- No console errors; Lune tests and `luau-lsp analyze` clean; FPS not worse.
- Save the place, commit, push; note it in `City Legends/City Legends.md`.

## When done (top of the notes, short)
- speed bumps removed (how many);
- roads rebuilt (which areas), with screenshots;
- bugs found and fixed (count + the worst 10), and any left with why;
- FPS before / after.
