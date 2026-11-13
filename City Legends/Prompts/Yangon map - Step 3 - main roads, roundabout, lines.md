# Yangon map – Step 3: main roads, roundabout, lines

Game: City Legends (`Games/CityLegends`). Yangon replaces the Monaco map. Owner, 13 Nov 2026: "lets use claude code", so the build steps now run in Claude Code from prompts like this one.
Do this step only (step 3 of [[Yangon map - Build steps (Claude builds it)]]), then STOP and report. No flyovers, no streets, no traffic lanes, no buildings.

## If this runs with ultracode
Ultracode plans a workflow of parallel subagents. Studio is one place on one main thread, so:
- **One agent only writes to Studio and to the tool files** (`Roads.luau`, `RoadLines.luau`, `YangonRoads.luau`, the road data), in the order of this prompt. Never two builds, saves or `execute_luau` writes at the same time.
- Subagents may do the work that only reads: the Yangon photo research, reviewing the builder changes before they run, the measured checks, and looking at the pictures. A check that fails goes back to the one writing agent.
- One save at the start and one at the end, by the writing agent.

## Read first
1. `Brain/00 BRAIN.md`, then `Brain/Knowledge/K06` (lighting) and `K07` (performance).
2. `City Legends/Yangon map - Build steps (Claude builds it).md`: the rules, the log and its two **Trap** lines.
3. `City Legends/2026-11-13 Yangon map - Step 2 road design.md`: widths, roundabout, flyovers.
4. `Games/CityLegends/CLAUDE.md`: the flicker rule (2026-11-03) and the road tool notes (2026-11-04, 2026-11-06).

## Studio
- Two Studios are open. Pick **"City Legends (placeId: 121430381830562)"** by name with `list_roblox_studios`. Never touch "Stomp Evolution".
- Edit mode only. `Workspace.Riviera` (Monaco) is not touched. Count its descendants before you start and after you finish: the two numbers must match.
- **Save first**, before any change, with the note "Yangon step 2: ground and Inya Lake" (step 2 has no labelled version yet). "Target is not reachable" means try again. Write the version number in the build steps note.
- Checked on 13 Nov, 12:40: `ServerStorage.YangonData` holds `Terrain`, `Roads_1` to `Roads_3`, `Design` and `Tools.YangonTerrain`; `ServerStorage.ClaudeTools.Roads` and `.RoadLines` are there; `Workspace.Yangon` does not exist yet. `Workspace` also holds a loose `ZProbe` and `Part`: look at them and remove them only if they are leftover probes of ours.
- Road data: join the three `Roads_n` strings and `JSONDecode` them: 33 roads (3 `route`, 30 `street`), 8,746 samples 6.4 studs apart, format `[x, y, z, dirX, dirZ, tunnel, halfLeft, halfRight]`.

## Five things in the data and the builder that will go wrong if left alone
Fix each one, and say in the report how.
1. **Rank is the wrong way round.** `Roads.luau` treats the LOWER rank as the bigger road (Monaco's rank is 0 = biggest). `ygn_roads.json` gives the main roads 5 and the streets 4, 3, 2, so every street would beat the main roads, and the three main roads tie. Wanted order: Yangon Loop, then New Road, then University Avenue, then the streets from big to small. Fix `tools/yangon/d6_export.py` for the future, and patch the ranks in `ygn_roads.json` and in `ServerStorage.YangonData` so all three agree. Do not re-run the design chain (d1 to d5) unless its `.pkl` files are still in `imports/refs/map`: the approved design must not move.
2. **Half widths.** `HALF = 32` is one constant used for the carriageway, the junction reach, the pavement offset and the lane lines, and an edge narrower than `HALF - 0.5` is read as a hairpin leg (stone `LegWall`, no pavement). The streets carry half 16. Give `Roads.luau` and `RoadLines.luau` a half width per road, so a street is a true 1+1 road with kerbs and pavements and a street mouth on a main road is as wide as the street, not as wide as a main road. With no half given the code must behave exactly as before (Monaco still uses it): keep every new branch behind the per-road value.
3. **Kind `route` gets grey `Shoulder` strips, not pavements.** Only `street` and two Monaco names get kerbs and pavements. Yangon's main roads need a 10-stud pavement and a kerb each side (84 studs in all). Add an option for it.
4. **Monaco colours.** `PAVER` is Monaco's red-pink and `PATTERNS` are Monaco streets. Add a palette option for Yangon. Before picking it, look at 3 or more street-level photos of Pyay Road, Kabar Aye Pagoda Road and University Avenue Road and write down what the pavement, the kerb (plain or painted bands) and the lines look like. Save that as `Roblox Playbook/2026-11-13 Research - Yangon road look.md`. If the photos do not settle it, use plain grey concrete pavers and a light concrete kerb.
5. **The loop starts and ends at the roundabout's centre** (29072, 47.3, 1173), not at its edge. And open road ends get a `TurningCircle`. See "What to leave out" below.

Put the changed tools in the repo (`tools/riviera/Roads.luau`, `RoadLines.luau`; Yangon-only code in a new `tools/yangon/YangonRoads.luau`) and in `ServerStorage.ClaudeTools`, and `require` a `:Clone()`. The repo file and the Studio copy must end up the same.

## What to build
All of it in `Workspace.Yangon` (a Model) > `Roads` (a Folder, one folder per road, like `Workspace.Riviera.Roads`).
1. **The three main roads:** Yangon Loop, New Road, University Avenue. 64-stud carriageway (4 lanes of 16), 10-stud pavement and kerb each side, no middle strip. Load all 33 roads so the junction mouths are right, but build only these three (`opts.only`). At each street mouth the main road's pavement and kerb leave a gap as wide as the street; the street itself comes in step 5.
2. **Hanthawaddy Roundabout:** centre X 29072, Z 1172.8, road height 47.27. Island radius 60, ring 48 wide (3 lanes of 16), outer radius 108, traffic anticlockwise. Flat. Kerb round the island and round the outside, pavement outside with gaps at the 4 arms (bearings 114 and 340: the loop; 171: Pyay Road South; 262: Hanthawaddy Road). The island is a low kerbed grass mound, light on triangles, nothing tall that hides the cars across the ring. The two street arms get their gap only.
3. **Lines** (`RoadLines.build` after `Roads.build(..., { noLines = true })`): main roads get a centre line, a lane line each side and solid edge lines; the ring gets two dashed lane circles and solid edges; a give-way line across each loop arm where it meets the ring. No line may run across a junction mouth or over another road.

## What to leave out (step 4 builds it)
- **Inside the roundabout:** no loop slab, pavement or line closer than 108 studs to the centre. The loop's two ends are cut where they meet the ring, level with it.
- **Flyover corridors:** each flyover (`Design.flyovers`: the loop from 10,742 m to 11,934 m; New Road from 2,289 m to its end at 2,729 m) has a corridor 70 studs either side of the deck's centre line. Build nothing of any road inside a corridor. Measured on the data on 13 Nov, this cuts:
  - the loop from 10,742 m to 11,934 m (its own deck and ramps);
  - the loop from about 3,164 m to 3,488 m (82 samples, where it runs under New Road's deck; New Road lands on the loop at 3,452 m);
  - New Road from 2,289 m to its end;
  - University Avenue's first 11 samples (its west end meets the loop at 11,284 m, 14 studs under the deck).
  - Streets with samples in a corridor, for step 5 to know: Hledan Road, Nar Nat Taw Road, New University Avenue Road.
  Check these numbers against your own count and list every cut end in the report.
- Deck samples sit 14 studs above the ground. They must not count as a junction for a road passing underneath, or that road's end is lifted onto the deck.
- Every cut end is square across the road, with no `TurningCircle`, no kerb wrapped round it and no drop: step 4 butts up to it.
- Not in this step: `SmoothKerbs`, `PaveOverlap`, road meshes (step 6), lanes and `LaneCheck` (step 7), zebra crossings, lamps.

## Rules
- Heights come from the samples. The ground is already 1 stud under the road height; the builder clears the terrain above the road. After the build no grass may show through a road and no road may float: check 200 random points on the main roads.
- Flicker rule: no two visible faces closer than 0.05 studs (paint 0.08 over the road, kerb top 0.1 over the pavers).
- `CastShadow` off on flat road parts, as the builder does now. Heavy loops in chunks with `task.wait()`, each chunk parented on its own.
- Lighting stays bright. Do not change Lighting in this step.

## Checks (all measured, numbers in the report)
1. `Roads.check` on the three main roads with `parent = Workspace.Yangon.Roads`: 0 bumps. Give it the per-road lanes.
2. Junctions: at each of the 28 main-road junctions in `Design.junctions` that lies outside the corridors, the mouth gap is there, the heights match within 0.05 and no pavement, kerb or line crosses the mouth.
3. Main road against main road (New Road's start on the loop at 772 m; University Avenue's east end on the loop at 2,160 m): one slab only where they overlap, the loop's, and the heights match (51.4 and 42.0).
4. `SurfaceCheck` at 10 spots (4 straights, 3 bends, the roundabout, 2 junctions): no doubled faces.
5. Part count of `Workspace.Yangon.Roads` by name (slab, Pavement, Kerb, Line). `Workspace.Riviera` descendants unchanged.
6. Pictures with `screen_capture`, daytime, saved as jpg in the vault's `City Legends` folder with names like `Yangon main roads - roundabout from above.jpg`: the roundabout from above and from a driver's eye, a straight on Pyay Road, the tightest bend, a street mouth, New Road joining the loop, both cut ends at the Pyay Road Flyover, Inya Lake beside the road, and one at phone size (667 x 375). Look at each picture yourself before you report: wrong colours, gaps, grass through the road or crossed lines mean fix and shoot again.

## Finish
- Save the place with the note "Yangon step 3: main roads and roundabout". Write the version number in the build steps note.
- In `Yangon map - Build steps (Claude builds it).md`: tick step 3 and add a log entry (what was built, the numbers, new traps, what step 4 must know: where the cut ends are and how to call the builder).
- Add a short "Yangon roads" line to `Games/CityLegends/CLAUDE.md` under "Rules and decisions": the new builder options and the rank rule.
- Report to the owner in plain words: what is built, the check numbers, the pictures, anything that is not right yet. Then stop. Step 4 (flyovers) waits for the owner.
