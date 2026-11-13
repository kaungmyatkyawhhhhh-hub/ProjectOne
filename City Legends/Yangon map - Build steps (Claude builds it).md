---
tags: [city-legends, yangon-map, build-steps]
created: 2026-11-13
---
# Yangon map – build steps (Claude builds it)

**Owner, 13 Nov 2026, 12:32: "lets use claude code".** From step 3 on, each step is run in Claude Code from a prompt in `City Legends/Prompts/` (one prompt = one step + a report). This replaces the earlier rule of the same day ("no prompts for claude code, u ARE the claude code"), under which steps 0 to 2 were built by Claude in chat.
The place is City Legends, placeId 121430381830562. One step per run. Each run starts by reading [[2026-11-13 Yangon map - Step 2 road design]] and this note, and ends by ticking its step here and writing what it did.

Rules for every step:
- Owner's road rules: main roads 2+2 with traffic; streets 1+1 with no traffic; traffic only on main roads.
- Monaco (`Workspace.Riviera`) is not touched until step 11. Yangon is built beside it in `Workspace.Yangon`.
- Save the place with a version note at the end of each step. Write the version number here.
- Lighting is never dark. Models stay light on triangles. Check on phone size.
- Studio tools go in `ServerStorage.ClaudeTools` as ModuleScripts; `require` a `:Clone()`.
- **Blender is allowed (owner, 13 Nov 2026, 13:40):** "u can model with blender and not build in roblox studio if it saves lag and time". Map pieces may be made in Blender and brought in as meshes when that means fewer parts or less time. First place it pays: step 6, the road meshes.

## Steps
- [x] **0. Street plan and road design** (13 Nov). Roblox version at the time: 688.
- [x] **1. Backup and setup** (13 Nov, version 708). Save the live place with the note "Monaco backup before Yangon". Check what sits near X 30000 and fix the map's place in the world. Get `ygn_roads.json` and the ground grid into Studio (the repo is public: Studio can fetch committed files from GitHub by commit id).
- [x] **2. Ground** (13 Nov, version 711). Terrain from the smoothed ground grid in 4-stud cells: land, Inya Lake's water at 16 m, the lake bed.
- [x] **3. Main roads** (13 Nov, version 722). The Yangon Loop, New Road and University Avenue, the Hanthawaddy Roundabout and the lines are built. Prompt: [[Yangon map - Step 3 - main roads, roundabout, lines]]. What was done: the log entry "13 Nov 2026, step 3" below.
- [x] **3b. Round corners, kerbs in shade** (13 Nov, version 741). Owner: "dark asphalt is okay. fix sharp corners and kerbs in shade until theyre right". Log entry "13 Nov 2026, step 3b" below.
- [x] **4. Flyovers** (13 Nov, version 744). Decks, ramps, piers, parapets and side lanes for the Pyay Road Flyover and the Kabar Aye Flyover, and the junctions underneath. Log entry "13 Nov 2026, step 4" below.
- [x] **5. Streets** (13 Nov, version 750). The 30 streets, their junction mouths and round corners, and barriers at the 16 map-edge road ends. Log entry "13 Nov 2026, step 5" below.
- [ ] **6. Smooth pass.** Kerbs on bends, surface check (no steps, holes or flicker), then road meshes.
- [ ] **7. Traffic lanes.** Lanes for main roads, side lanes and the roundabout only. Lane checker at 0 problems. Traffic runs on main roads only.
- [ ] **8. Buildings and landmarks.** Yangon-style blocks along the roads, Novotel, Optima and MM Plaza, far-city backdrop at the map edge.
- [ ] **9. Move in the game.** Venues, houses, gas stations, spawn at Optima, fast travel spots, minimap.
- [ ] **10. Night lights.** Street lamps on main roads, lit buildings, never dark.
- [ ] **11. Switch over.** Move Monaco to ServerStorage (kept, not deleted), playtest, phone performance check.

## Log
- 13 Nov 2026: step 0 done in chat. Data and pictures in `Games/CityLegends/imports/refs/map/`.
- 13 Nov 2026, start of step 1:
  - The box Yangon will fill (X 27840 to 33520, Z -6512 to 1888) holds no parts. Monaco (`Workspace.Riviera`) sits at X 9645 to 17591, Z -2887 to 1555. So X = 30000 + x × 1.6 stays.
  - First try at the labelled save failed (Studio did not answer).
- 13 Nov 2026, step 1 (owner: "ok start doing it"):
  - **Monaco backup saved: Roblox version 708**, note "Monaco backup before Yangon". This is the restore point.
  - Studio's `execute_luau` cannot fetch from the web here: every domain (GitHub, localhost) is refused by the Assistant HTTP allowlist. So data does not come in by HttpService.
  - **How data gets into Studio:** pack it as ModuleScripts in one `.rbxmx` (JSON in `return [==[ ... ]==]`, under 190,000 characters each), save it in `Games/CityLegends/imports/sync/`, upload it as a Model to group 33151111 with `open_cloud_invoke` (POST `/assets/v1/assets`), then `insert_asset` into ServerStorage. `tools/yangon/mk_rbxmx.py` builds the file.
  - First pack: `imports/sync/yangon_data_1.rbxmx` = `YangonData` (Terrain, Roads_1 to Roads_3, Design, Tools/YangonTerrain). The ground builder's source is `tools/yangon/YangonTerrain.luau` (782 tiles of 256 studs, ground 1 stud under road height, lake water at 25.6 studs).
  - The owner approved `D:\ObsidianOne\Claude+Obsidian\Games\CityLegends\imports` for uploads (Studio > Assistant Settings > MCP Permissions).
- 13 Nov 2026, step 2 (ground) done:
  - Data pack 2 uploaded (`imports/sync/yangon_data_2.rbxmx`, asset 85224774084372; pack 1 was 114024008709031) and put in **`ServerStorage.YangonData`**: `Terrain`, `Roads_1` to `Roads_3`, `Design` (JSON strings) and `Tools.YangonTerrain`. `insert_asset` brings it in as a package: delete the PackageLink.
  - Ground written with `YangonTerrain` (`T.prepare()`, `T.run(1, 400)`, `T.run(401, 400)`, about 10 s each): 782 tiles of 256 studs over X 27648 to 33536, Z -6656 to 2048, Y 0 to 64. Grass on land, Inya Lake and 9 ponds as water at 25.6 studs, sand bed 10 studs down.
  - Checked: 3,000 random spots, the water matches the data at 2,999; the land surface sits exactly 1 stud under the road height (median difference 0.00, 5% to 95% 0.00). Water is 13.9% of the box (2.8 km²).
  - **Trap:** smooth solid terrain shows 2 studs (half a voxel) above "voxel bottom + occupancy × 4". Water does not. The builder takes 2 off for land and sand (`SOLID_LIFT`).
  - **Trap:** Studio sometimes answers "Target is not reachable" to `execute_luau` or `save_place`. A second try usually works. The save after step 2 failed 4 times in a row, so **step 2 has no labelled version yet**: save first thing in step 3 (note "Yangon step 2: ground and Inya Lake"). The place is in Team Create, so the ground is already in the live place.
- 13 Nov 2026, 12:40, before step 3 (owner: "lets use claude code"): the step 3 prompt is `Prompts/Yangon map - Step 3 - main roads, roundabout, lines.md`. Nothing was built or changed in Studio. Found while reading the data and `Roads.luau`:
  - Studio state: `ServerStorage.YangonData` and `ClaudeTools.Roads` / `RoadLines` are there, `Workspace.Yangon` does not exist yet, a loose `ZProbe` and `Part` sit in `Workspace`. Two Studios are open (City Legends and Stomp Evolution): pick by name.
  - **Trap: rank is the wrong way round.** `Roads.luau` treats the lower rank as the bigger road (Monaco: 0 = biggest). `ygn_roads.json` has main roads 5 and streets 4, 3, 2, and the three main roads tie. Left alone, every street beats the main roads.
  - **Trap:** kind `route` gets grey `Shoulder` strips, not kerbs and pavements; an edge narrower than `HALF - 0.5` (every street, half 16) is read as a hairpin leg and gets a stone `LegWall`; `PAVER` is Monaco's red-pink.
  - **Trap:** the Yangon Loop starts and ends at the roundabout's centre (29072, 47.3, 1173), so its samples inside 108 studs are left out for the ring. Open ends get a `TurningCircle` unless told not to.
  - **Trap:** flyover samples sit 14 studs up. A road passing under a deck (University Avenue's west end, the loop under New Road) would be lifted onto it by `alignJunctions`. Step 3 builds nothing inside the two flyover corridors (70 studs either side of the deck line); step 4 does.
  - Measured on the road data: New Road starts on the loop at 772 m and lands on it at 3,452 m; University Avenue's east end is on the loop at 2,160 m and its west end at 11,284 m (under the Pyay Road Flyover). The loop has 82 samples (3,164 m to 3,488 m) inside New Road's flyover corridor and 36 samples inside the roundabout. Streets with samples in a flyover corridor: Hledan Road, Nar Nat Taw Road, New University Avenue Road.
  - The design chain's `.pkl` files are not in `imports/refs/map`, so `d6_export.py` cannot simply be re-run: patch the ranks in the json and in Studio.
  - 12:37, owner: "im using ultracode". The prompt now says that one agent only writes to Studio and the tool files; subagents do the reading work (photo research, code review, checks, pictures).
- 13 Nov 2026, step 3 (main roads, roundabout, lines) done in Claude Code with ultracode (agents did the photo research, the code review and the picture review; one agent wrote to Studio):
  - **Saves:** version **711** = "Yangon step 2: ground and Inya Lake" (saved first, before any change). Version **722** = "Yangon step 3: main roads and roundabout".
  - **Built** in `Workspace.Yangon.Roads` (one folder per road): `Yangon Loop`, `New Road`, `University Avenue`, `Hanthawaddy Roundabout`. 66,061 parts: 15,504 road slab wedges, 15,438 pavement, 20,289 kerb, 14,828 line, 2 island. `Workspace.Riviera` has 388,029 descendants before and after. The two loose probes in Workspace (`ZProbe`, `Part`: invisible, 0.1 studs, at Monaco roads) were ours and are gone.
  - **The five traps, how each was fixed:**
    1. Rank: unique build ranks, the lower the bigger (0 Yangon Loop, 1 New Road, 2 University Avenue, 3 to 32 the streets by class, length, name). `d6_export.py` writes them now; `tools/yangon/patch_ranks.py` patched `ygn_roads.json`, and the same header replacements were made in `ServerStorage.YangonData.Roads_1..3`. All agree: 418,581 characters, checksum 1458396754. No sample moved (the `.pkl` files are gone, the design chain was not re-run).
    2. Half widths: each road carries `half` in the data (32 or 16). `Roads.luau` and `RoadLines.luau` use the road's own half; "near another road" uses the other road's half. With no `half` they do what they did (two review agents compared old and new line by line: no difference for Monaco).
    3. Pavements on a `route`: `opts.pave`.
    4. Colours: `opts.palette`. From 43 street photos ([[2026-11-13 Research - Yangon road look]]): plain grey concrete pavement (Sandstone material, 128, 124, 116), red and white kerb bands (3.2 studs; 195, 47, 45 and 242, 240, 232), all lines white, one solid centre line. Asphalt stays the game's dark one (the real one is a lighter warm grey: owner's call).
    5. Loop ends and turning circles: the loop's two arms are flat at the ring's height (47.27) out to 12 studs past the ring, then eased over 128 studs (arm 1 comes down 1.31, arm 2 up 0.25), and their slabs end exactly on the ring's edge. `noTurningCircle`, and a cut end never gets one.
  - **The builder's new parts** (`tools/riviera/Roads.luau`, `RoadLines.luau`, new `tools/yangon/YangonRoads.luau`; options listed in `Games/CityLegends/CLAUDE.md` under "Yangon roads"):
    - Kerb and pavement pieces tile exactly (each piece runs between its two samples' own right vectors), so nothing overlaps on bends and nothing is longer than its slab at a cut end. The pavement starts at the kerb's back face (0.85 out). Where another road's zone begins the pieces are cut on the zone's edge, so a street mouth is exactly as wide as the street, however it slants.
    - Mouths: where New Road and University Avenue end on the loop, and where the loop ends in the ring, the slab is a polygon cut on the bigger road's own edge (one slab in the junction, no overlap, no hole).
    - Lines (`RoadLines` with `clearMouths`): each line piece is tested on its own. It is left out within half a stud of a bigger road's carriageway, or of a smaller road's carriageway on the line's own side of the centre line. So at a street mouth the near side's lane and edge lines stop, the far side's lines run on, and the middle line is never broken by a smaller road. (The old rule stopped every line near a junction: at the New Road fork that left 150 studs of bare asphalt, which all three picture reviewers called unfinished.)
    - Cut ends: `Y.mendCutEnds` puts the ground just past each cut end back to 1 stud under the road (the builder's trench left a dip of 2 studs there).
    - Roundabout: a 96-sided flat ring from radius 60 to 108.06 (so nothing of an arm is nearer than 108), island kerb, grass disc and a low dome (2.9 studs over the road at its middle), outer kerb and pavement with a gap at each of the 4 arms cut on the arms' own edge lines, two dashed lane circles, solid edges (the outer one broken at the arms), 14 give-way dashes across the ENTRY lanes of the two loop arms (traffic keeps right, so the ring runs anticlockwise).
    - Bank: at 85 loop samples (2,270 to 2,320 m, 8,075 to 8,520 m, 12,120 to 12,155 m) a pond or the lake reached under the pavement (step 2 wrote water wherever the map has water; our roads are twice as wide as the real ones). `Y.bank` fills a grass bank there first (124 pieces), out to 12 studs past the pavement.
  - **Cut ends (nothing of any road is built inside a corridor; each end is square, no turning circle, no kerb round it):**

    | Road | Last built sample | At | Position (X, Y, Z) | Cut by |
    |---|---|---|---|---|
    | Yangon Loop | 789 | 3,151.5 m | 32287.6, 35.49, -623.3 | Kabar Aye Flyover (cut runs to 3,491 m) |
    | Yangon Loop | 875 | 3,495.4 m | 32424.7, 29.15, -1132.3 | Kabar Aye Flyover |
    | Yangon Loop | 2686 | 10,738.3 m | 28678.8, 32.15, -1976.4 | Pyay Road Flyover (its own deck, 10,742 to 11,930 m) |
    | Yangon Loop | 2985 | 11,934.2 m | 28694.4, 40.47, -134.4 | Pyay Road Flyover |
    | New Road | 572 | 2,285.2 m | 32532.9, 40.39, -242.5 | Kabar Aye Flyover (cut runs to the road's end) |
    | University Avenue | 13 | 48.0 m | 28510.9, 34.85, -1138.3 | Pyay Road Flyover (its first 12 samples) |

    Streets with samples in a corridor, for step 5: New University Avenue Road (last built sample 80), Hledan Road (64), Nar Nat Taw Road (first built sample 12).
    Against the prompt's numbers: the loop under New Road's deck is cut over 85 samples (3,155 to 3,491 m), not 82, and University Avenue loses 12 samples, not 11, because a sample counts as in the corridor when any of its width (carriageway and pavements) is, not only its middle. **New Road is 2,821 m long in the data, not 2,729 m:** the deck ends at 2,729 m and the road runs 92 m more on the loop's own line. That tail is cut too.
  - **Checks (all measured on the final build):**
    1. `Roads.check` on the three main roads, per-road lanes: **0 bumps** in 89,600 points.
    2. Junctions: 28 on main roads, 3 in a corridor (step 4), **25 checked with 28 mouths: 0 spots of kerb or pavement in a mouth, 0 missing right beside one, 0 lines in a mouth, heights within 0.015**. The two built joins are measured surface against surface. For the streets (not built yet) the height is the one the builder will give them. The streets' raw data is up to 0.77 off at the main road's kerb line (the ground slopes across the main road): `alignJunctions` eases that when they are built.
    3. Main road on main road: New Road on the loop 3,697 spots, University Avenue on the loop 2,742 spots (2-stud grid): **0 spots with two roads' slabs, 0 holes**. Heights 51.46 against 51.47, and 42.02 against 42.02.
    4. Doubled faces at 10 spots (4 straights, 3 bends, the roundabout, 2 junctions): **0 block faces fighting, 0 doubled slab spots** in 45,000 rays (`SurfaceCheck` reads only blocks, so the slab wedges get their own ray test).
    5. 200 random points on the main roads: **0 with ground through the road, 0 with nothing under, 0 floating**. The pavement's top stands 2.3 studs over the ground beside it on average (4.7 at most).
    6. Pictures in the `City Legends` folder: `Yangon main roads - ...jpg` (10 of them, one at 667 x 375). Three review agents looked at the first set: roads, bends, cut ends and roundabout clean; one must-fix (no lines through the New Road fork), fixed with the new line rule; white kerb bands sinking into the pavement (pavement made darker) and a dark ring on the island (dome made as wide as the disc), both fixed. All ten were shot again on the final build.
  - **New traps:**
    - **Pictures:** after a build, or after the camera jumps far, Studio needs 10 to 15 s to draw the parts. Set the real camera first (`CurrentCamera.CFrame` and `.Focus`), wait, then `screen_capture` from the same spot. Otherwise the picture shows grass where the road is.
    - **Rays on seams:** a ray exactly on a sample's cross-section (where two road pieces meet) can slip between them. It made false "holes" in the checks and 49 missing line dashes. Checks and `RoadLines` now look a hair off the seam.
    - **Hair-thin triangles lean:** `Roads.triangle` makes its wedges as thick as the slab along the triangle's own normal, and a triangle under 0.03 studs across has a normal set by rounding. `Roads.sliver` skips them.
    - **"Target is not reachable" can come back after the code ran.** Look at the state before running it again. Long jobs go through `Y.spawn` and are read with `Y.status()` or an attribute on `ServerStorage.YangonData`.
    - **Materials:** Roblox's `Pavement` draws small pavers; `Concrete` is overridden in this place (`RivConcrete2`) and shows each triangle's texture direction. `Sandstone` reads as plain concrete with no seams. `Asphalt` is overridden too (`RivAsphalt`), so Yangon's roads get Monaco's asphalt texture by themselves.
    - **Upload:** an `.rbxmx` needs content type `model/x-rbxm` (without it: "not supported yet"). PATCH on `/assets/v1/assets/133014134133489` makes a new version of the same asset, so tool updates do not pile up as new assets.
    - `ServerStorage.OldRoadLines` holds Monaco's old lines (24,048 parts). `RoadLines.build` makes a folder per road in it; the three empty Yangon ones were removed.
  - **Not right yet / for the owner to judge:**
    - The pavement stands 2 to 3 studs proud of the grass in places (the ground is 1 stud under the road and the builder's trench lowers the edge). Step 8's blocks stand against it; if it looks wrong before then, the verge can be raised.
    - Corners are sharp where the arms meet the ring and where New Road's kerb meets the loop's (no rounded kerb returns): that is step 6 (kerbs on bends).
    - In shade the white kerb bands read pale blue and the pavement's side face teal: that is the place's sky light. Lighting was not touched in this step.
    - Far away the red and white bands break into a speckled strip that may shimmer when driving. Road meshes with a banded texture (step 6) would cure it.
    - The pavement's material (Sandstone) reads a little like rock from very close: no paving joints.
    - The roundabout's kerbs are straight blocks along the ring's 96 sides: a hairline (0.03 studs) can show at the joints from very close.
    - Turn arrows and stop lines are not designed yet. In the New Road fork the mouth-side lane and edge lines stop for about 150 studs (the mouth), the rest runs through.
    - Asphalt colour: kept dark. The photos show a lighter warm grey.
    - 66,061 parts for 17 km of main road. Step 6 (road meshes, Blender allowed) is where that comes down.
  - **What step 4 must know:**
    - Load and rebuild: `local Y = require(game.ServerStorage.ClaudeTools.YangonRoads:Clone()); Y.load(); Y.spawn("step 3", Y.step3)` then `Y.status()` (about 28 s: it clears the three road folders, fills the bank, builds roads and mouths, mends the ground at the cut ends, builds the roundabout and the lines). Checks: `Y.checkBumps()`, `Y.checkPoints(200)`, `Y.checkJunctions()` (slow: spawn it), `Y.checkMainMain()`, `Y.surfaceCheck(spots)`, `Y.partCount()`.
    - `Y.cut[road][sample]` says what is cut and by which flyover; `Y.cutEnds` is the table above with exact positions. `Y.design.flyovers` holds the decks. Deck samples in the data are 14 studs above the ground and are cut, so no road passing under is lifted onto them.
    - The flyovers' own slabs can be built with `Roads.build` and its own `cut` table (the inverse: everything except the deck), or by a new tool. The cut ends are the cross-sections at the samples in the table: butt up to them at the same height.
    - Under the Kabar Aye Flyover the loop is cut from 3,155 to 3,491 m: New Road's ramp comes down on the loop's own line there. Under the Pyay Road Flyover: University Avenue's first 12 samples, Hledan Road's last 12, Nar Nat Taw Road's first 11.
    - `Y.findMouths` handles a road that ENDS on a bigger road or in the ring. A street that CROSSES a main road (Inya Road crosses the loop and University Avenue) needs the same cut on both sides: for step 5.
    - Pyay Road South and Hanthawaddy Road end inside the roundabout: `Y.load()` already eases their heights onto the ring and cuts their samples inside radius 94. The ring's kerb and pavement already have their two gaps.
- 13 Nov 2026, step 3b (owner: "dark asphalt is okay. fix sharp corners and kerbs in shade until theyre right"; then "Rush Yangon" for the car meet next week). Version **741** = "Yangon step 3b: round corners, kerbs in shade (nose fixed)" (731 was the same without the nose fix).
  - **Kerbs in shade:** the blue came from the place's Concrete override (`RivConcrete2`, a blue-grey texture) and the blue shade light (OutdoorAmbient 108, 114, 136). Lighting not touched. Kerbs are now SmoothPlastic, white 255, 228, 192 (reads white in shade, a warm white in sun), red 200, 40, 38. Far away the haze still tints them a little blue.
  - **Round corners** (`YangonRoads.findCorners` / `buildCorners` / `cornerLines`): where a road ends on a bigger road or in the ring, each of its kerb lines meets the other kerb line at P. A circle of radius r = T x tan(theta / 2) fits in the pavement wedge (T = 16 road on road, 22 at the ring), so every curve starts about T studs before P. Asphalt fills between the arc and P, the kerb (3.2-stud bands), pavement and the solid edge line follow the arc. 8 corners: the roundabout's 4 (r 20.7 to 39.5), the New Road fork's nose (r 5) and outer elbow (r 79), University Avenue's T (r 18 and 22).
  - Past a corner the joining road keeps its own kerb and pavement (`ownedBy`): at the slanting fork the loop's pavement band had buried New Road's kerb.
  - **Grass up to the pavement** (`M.verge`): it stood 2 to 3 studs lower, so the pavement's side showed as a tall teal wall. Strips 16 wide beside every pavement, round the ring and inside the curves, top at road - 1.7 (smooth terrain shows ~2 over a fill's top): the grass now sits 0.1 to 1.1 under the pavement's top (mean 0.8 under).
  - **Builder fixes found on the way:** a partly cut kerb or pavement piece is halved (both ways, up to 7 times) and each half cut again (`Roads.clipPieces`: one straight cut across a bent zone edge left V-shaped gaps); a triangle that is thin seen from above, or steep, is skipped (`Roads.sliver`: it stood on edge and its wedges stuck out sideways at the fork's nose); RoadLines shortens an edge-line piece to a corner's edge instead of dropping it (`edgeSkip`).
  - **Checks:** 0 bumps (89,600 points), 0 ground through the road, 0 floating (200 points), 0 doubled slabs and 0 holes at the two main-road joins, 25 junctions with 0 faults, 0 fighting faces at 10 spots incl. all 8 corners. 74,357 parts (finer cuts: +3,600). Monaco unchanged (388,029).
  - **Not right yet:** in the fork's island the loop's pavement and New Road's meet with a small step (New Road falls away from the loop there).
  - Pictures: `Yangon 3b - ...jpg` in this folder.
- 13 Nov 2026, step 4 (owner: "Rush Yangon", then "continue"). Version **744** = "Yangon step 4: flyovers".
  - **Design** (`tools/yangon/d7_flyovers.py` -> `imports/refs/map/ygn_roads_v2.json`, packed into `ServerStorage.YangonData.Roads2_1..3`; `Y.load()` uses them when they are there):
    - The flyovers are no longer corridors. The data has explicit `cut` lists (the deck stretches only) and `decks` (each deck's own samples).
    - **Pyay Road Flyover:** the loop rides the deck (300 samples, 32 to 52 high). Before and after it the loop widens from 32 to 60 each side over 128 studs, and the deck and two side lanes all start square on that wide end (like a real gore). West side lane (rank 1.5) and east side lane, cut in two by University Avenue (East Lane 1 and 2, ranks 2.5 and 2.6). Side lanes: 24 wide, 48 from the deck's middle, 3.5 pavement on the deck side, 10 outside.
    - University Avenue now starts on the west side lane (it runs on along Hledan Road's line) and passes under the deck. Hledan Road ends on the west lane, Nar Nat Taw Road starts from it.
    - **Kabar Aye Flyover:** New Road's deck (109 samples, up to 51.5) lands on the loop. The loop ends 50 samples before the landing and splits into two side lanes (East rank 0.6, West 0.7) that run either side of the ramp and join the loop again, widened, where it resumes.
    - New University Avenue Road (a step 5 street) bends (radius 99) under the deck onto the east side lane.
    - Side lanes ease from the loop's height to the ground's over 64 studs at each end (they had a 0.75-stud step).
  - **Tools:** `Roads.luau`: per-road `walkL` / `walkR` (pavement width per side), `opts.clearHalf` (how wide the terrain is cleared). `YangonRoads.luau`: v2 data, `Y.halfAt` (widened ends), side lanes that start on a road's end are no mouth (`startsOnEnd` / `endsOnEnd`), nothing of a road lies past a cut end (`polyDist`), two side lanes at a split keep their kerbs off each other, verge on the side lanes' outer side only, `Y.buildDecks()`, `Y.deckClearance()`, `Y.step4()` (= step 3 with the 8 roads, then the decks, about 64 s).
  - **Decks** (`Workspace.Yangon.Decks`): the surface is `Roads.build` (surface only) plus `RoadLines`. Parapets 1 wide, 2.6 over the edge. Where the deck is less than 9 over the ground the parapet goes down into the ground (ramp wall); higher, a fascia over the slab, a box girder 3 deep and piers (cap 58 wide, column 12 x 5) every 8 samples, moved along off any road below. Pyay: 33 piers, Kabar Aye: 8.
  - **Grass beside the pavement:** it dipped 1 to 2 studs right at the pavement edge (a 4-stud voxel in the road's cleared trench pulls the surface down). The verge now starts 4 studs under the pavement: 70 spots of 2,764 still more than 0.8 under, all at junction mouths waiting for step 5 streets.
  - **Checks:** clearance under the girders 8.4 (Pyay over University Avenue) to 9.4 studs; 0 ground through the road, 0 floating (200 points); 25 junctions, 0 faults, heights within 0.015; main-road joins 0 doubled slabs, 2 holes (a seam spot at University Avenue's start; the check now looks through decks and not past a road's end); bump check: 8 single points at lane starts, but rays there show a smooth surface (under 0.02 between neighbours), so they are the checker. 90,837 road parts + 2,899 deck parts. Monaco unchanged (388,029).
  - **Not right yet:** the deck is plain light concrete (no colour bands or lamp posts yet: step 10 lamps); pier spacing is uneven where piers moved off University Avenue; the parapet ends stand square at the ramp feet; side lanes have a solid centre line like the main roads (they carry one direction: dashed would be right, step 7); a pavement edge still stands proud near the University Avenue / east lane corners (step 6 smooth pass).
  - Pictures: `Yangon 4 - ...jpg` in this folder.
- 13 Nov 2026, step 5 (owner: "continue"). Version **750** = "Yangon step 5: streets".
  - **Data** (`tools/yangon/d8_streets.py` -> `ygn_roads_v3.json`, in Studio as `YangonData.Roads3_1..3`; `Y.load()` takes the newest):
    - Only one street really crosses a bigger road: Inya Road (the Yangon Loop and University Avenue). It is now three pieces, each ending inside the road it crosses: Inya Road West, Inya Road, Inya Road East (ranks 15, 15.1, 15.2). The other 14 "crossings" in the scan were T-junctions.
    - **Rule:** a road that ends on another must be the smaller one. Two pairs were the wrong way round. Insein Road ends on Hledan Road, so Hledan goes to rank 3.5. Adipati Road ends on Convocation Road, so Convocation goes to 23.5. d8 checks this rule on every road end.
    - U Tun Nyein Street and Lane 1 started at the same point at a 102-degree corner. They are now one street, with the corner rounded at radius 40.
    - 16 map-edge ends are marked `edgeStart` / `edgeEnd`.
  - **Build:** `Y.step5()` = step 4 with every road, then `Y.buildBarriers()`, then `Y.scrub(true)`. It takes about 150 s. Load first: `Y.spawn("step 5", function() Y.load() return Y.step5() end)`.
    - 53 junction mouths, 106 round corners, 16 barriers. Each barrier is a red and white wall of 2.8-stud blocks across the road and both pavements.
    - 184,874 road parts. Step 6 meshes must bring this down.
  - **Fixed on the way:**
    - **A road's own kerb past a round corner did not stop at a smaller road's mouth.** Parami Road West and Parami Road East meet a road right where that road's corner onto the loop starts, and 360 kerb and pavement scraps lay on their carriageways.
    - **The kerb rule used a side lane's nominal 12-stud half width.** At its split the lane is 16 wide, so New University Avenue Road's corner kerb sat on the lane. Edges, mouths and the kerb rule now use each sample's own width (`edgeXZ`, `M.halfAt`).
    - Nothing of a road counts behind one of its cut ends (`polyDist`, and `RoadLines` for the lines: the Kabar Aye side lanes had lost their lines for about 30 studs).
  - **Independent review (8 agents, every finding checked by a second one):** it found 5 real bugs, all fixed:
    - The barrier blocks were turned 90 degrees: a row of fins with car-wide gaps.
    - Two round corners overlapped on a 24-stud kerb at Pyay Road North / Parami Road West. A corner now shrinks when another junction's corner point is closer than 2T + 4.
    - The terrain trench was cut to the full 10-stud pavement width beside a side lane's 3.5-stud walk, leaving a ditch. It is now cut per side.
    - The lines at the Kabar Aye lanes (see above).
    - The polyDist cut-end hole.
  - **The safety net:** `Y.scrub(true)` moves any kerb or pavement piece whose middle lies on another road's carriageway to `ServerStorage.YangonScraps` (kept, not deleted). Last build: 10 specks 0.2 studs across, where the Pyay west lane's inner pavement ends at the loop's widened start.
  - **Checks:**
    - `Y.checkMouths()` (new): 53 mouths, 15,268 spots, 0 with kerb or pavement on the joining road.
    - 400 random points: 0 grass through the road, 0 floating, 0 wrong height.
    - Main-road joins: 0 doubled slabs, 4 holes (seam spots).
    - Junction heights within 0.015. The old junction check still names "Inya Road" and "Lane 1" from the design, so those two show as "no mouth found". `checkMouths` covers them.
    - Bump check: the 16 barriers (the checker drives into them), the lane starts already proven smooth, and rays on seams (exact 2.00 steps).
    - Grass through the pavement: 5 spots of 24,649, 0 of 8,693 on corners.
    - Monaco unchanged (388,029).
  - **Not right yet (step 6):**
    - Near junctions there is no grass verge, so where the ground is lower (the Inya Road crossing) the pavement's side stands up to 1.5 studs proud. `checkPoints` says the highest is 4.5.
    - Side lanes have a solid centre line (they are one-way).
    - The road part count.
  - **Edit-mode trap:** right after a big build, Studio draws roads in pieces and grass over pavement for a minute. Judge by raycast, or wait and take the picture again.
  - Pictures: `Yangon 5 - ...jpg` in this folder.
