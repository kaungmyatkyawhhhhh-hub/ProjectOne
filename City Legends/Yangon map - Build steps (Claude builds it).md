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

## Batches (owner, 14 Nov 2026: "here i labeled what batches we are doing. first batch is 1 and 2nd is 2 and 3rd is 3")
![[Yangon map - batches (owner, 14 Nov).webp]]
- **Batch 1 (west):** from Lotte Hotel and the Pyay Road / Kabar Aye Pagoda Road junction in the north, down Kabar Aye Pagoda Road on the east, to Shwedagon Pagoda and Chaukhtatgyi in the south, and west to the Hlaing River. Inya Lake is in it.
- **Batch 2 (south):** downtown: Yangon Zoo, Chinatown, Pazundaung, down to the river.
- **Batch 3 (east):** the area east of Kabar Aye Pagoda Road, out to the Thaketa industrial zone.
- **Batch 0.5 (owner, 14 Nov 2026: "this is batch 0.5"):** the area built in steps 0 to 11 (Inya Lake, Hledan, University Avenue, Myanmar Plaza, the Kabar Aye flyover).
- **Owner's verdict on batch 0.5 (14 Nov 2026):**
  - It doesn't look like Google Maps.
  - Use Google Earth in 3D to see even the smallest details of Yangon.
  - The buildings are not accurate. Some real ones are tall and round; in the game they are short squares.
  - Inya Lake has borders (its banks and walls) and a park in real life.
  - The industrial road is 2 lanes in real life; in the game it is 1.
  - Pictures: `Yangon batch 0.5 - game top view (owner, 14 Nov).webp` and `Yangon batch 0.5 - Google Maps (owner, 14 Nov).png`.
- **What the built map covers (steps 0 to 11):** about 96.128 to 96.161 E and 16.810 to 16.857 N: Inya Lake, Hledan, University Avenue, Myanmar Plaza and the Kabar Aye flyover. That is the middle of batch 1.
- **Batch 1 still needs:** the strip west to the river (Kamayut, the riverside, Lotte Hotel), the north edge up to the Pyay / Kabar Aye junction, and the south part down to Shwedagon and Chaukhtatgyi. Shwedagon is only a far-city backdrop today.

## Steps
- [x] **0. Street plan and road design** (13 Nov). Roblox version at the time: 688.
- [x] **1. Backup and setup** (13 Nov, version 708). Save the live place with the note "Monaco backup before Yangon". Check what sits near X 30000 and fix the map's place in the world. Get `ygn_roads.json` and the ground grid into Studio (the repo is public: Studio can fetch committed files from GitHub by commit id).
- [x] **2. Ground** (13 Nov, version 711). Terrain from the smoothed ground grid in 4-stud cells: land, Inya Lake's water at 16 m, the lake bed.
- [x] **3. Main roads** (13 Nov, version 722). The Yangon Loop, New Road and University Avenue, the Hanthawaddy Roundabout and the lines are built. Prompt: [[Yangon map - Step 3 - main roads, roundabout, lines]]. What was done: the log entry "13 Nov 2026, step 3" below.
- [x] **3b. Round corners, kerbs in shade** (13 Nov, version 741). Owner: "dark asphalt is okay. fix sharp corners and kerbs in shade until theyre right". Log entry "13 Nov 2026, step 3b" below.
- [x] **4. Flyovers** (13 Nov, version 744). Decks, ramps, piers, parapets and side lanes for the Pyay Road Flyover and the Kabar Aye Flyover, and the junctions underneath. Log entry "13 Nov 2026, step 4" below.
- [x] **5. Streets** (13 Nov, version 750). The 30 streets, their junction mouths and round corners, and barriers at the 16 map-edge road ends. Log entry "13 Nov 2026, step 5" below.
- [ ] **6. Smooth pass.** Kerbs on bends, surface check (no steps, holes or flicker), then road meshes. **6a done** (13 Nov, version 752): grass up to the pavements near junctions, dashed middle line on the one-way side lanes. Still to do: road meshes (part count).
- [x] **7. Traffic lanes** (13 Nov, version 758). Lanes for main roads, side lanes, decks and the roundabout only; lane check clean (7 single-ray spots, all seams or paint). Tested in Play the same day: traffic drives the loop, both flyovers, the side lanes and the roundabout.
- [x] **8. Buildings and landmarks** (13 Nov, version 764). 1,267 Yangon-style buildings along every road, Optima Werkz, Novotel and Myanmar Plaza, the far city with Shwedagon on the horizon. Log entry "13 Nov 2026, step 8" below.
- [x] **9. Move in the game** (14 Nov, the essentials). Players start by Optima Werkz; Legends Motors, Legends Customs and a gas station in Yangon; fast travel spots; the Yangon minimap and world map. Then (owner: "Move more venues") every venue moved: bank, heist drop-off, gem showcase, Legends Rewards, the hotel, the three towers, Legends Realty (version 781). Then (owner: "Move houses and races") house lots, races, the Racing Hub, delivery jobs and chips moved too (version 784). Legends Service, speed traps and the leaderboard stay in Monaco for now. Log entries "14 Nov 2026, step 9", "step 9b" and "step 9c" below.
- [x] **10. Night lights** (14 Nov, version 786). 678 white street lamps (main roads both sides, streets, flyover parapets, the roundabout), every building's windows lit at night, the far city's windows too. Log entry "14 Nov 2026, step 10" below.
- [x] **11. Switch over** (14 Nov, version 788). Monaco is in ServerStorage (kept whole), Yangon is the only map; Legends Service built in Yangon; playtest clean. The real phone check is still the owner's (see the log). Log entry "14 Nov 2026, step 11" below.
- [x] **12. Batch 0.5 accuracy pass** (14 Nov, version 799). Owner: "it dont look like the google maps one". Roads at real lane counts (16 roads now 2 + 2, No.1 Industrial among them), 3,249 real buildings from OpenStreetMap (round towers too), Inya Lake embankments, parks and 7,100 trees, lots refit, minimap redrawn, playtest clean. Log entry "14 Nov 2026, batch 0.5 accuracy pass" below.

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
- 13 Nov 2026, step 6a (owner: "continue", rushing for the car meet). Version **752** = "Yangon step 6a: grass up to pavements, dashed side lanes".
  - **Grass up to the pavement** (`Y.edgeFill`, now part of `Y.step5`):
    - Every 6.4-stud piece of pavement edge is tested on its own. Where the ground just outside is more than 0.8 under the pavement's top and nothing of another road lies there, it fills grass from 2 under the pavement to 6 past it.
    - 163 of 17,041 pieces needed it.
    - Pavement standing more than 1.5 over whatever is beside it: 16 of 8,156 edges (worst 2.8), all tight against junction corners.
    - Measure with parts counted: another road's pavement beside it is no gap. Counting terrain only gave 161.
  - **Side lanes are one-way:** their middle line is dashed. `Y.buildLines` draws them in a second `RoadLines` call with `centre = {}`.
  - **Checks after the rebuild (266 s):**
    - 53 mouths, 0 with kerb or pavement on the joining road.
    - 400 points: 0 grass through the road, 0 floating, 0 wrong height.
    - The scrub moved the same 10 specks.
  - **Road meshes (the rest of step 6) are not done:** 184,874 road parts plus 2,899 deck parts.
    - With StreamingEnabled a player only loads what is near, so the game runs. The meshes are for memory and phones.
    - The Riviera mesh pipeline (`tools/road_mesh/`) exports parts from Studio a page at a time, about 80 pages for this many parts. A Blender build from the road data would be faster, but means porting the kerb and mouth rules.
    - Left for after the car-meet steps (7 traffic, 8 buildings, 9 move-in, 10 lights, 11 switch-over).
  - Pictures: `Yangon 6a - ...jpg` in this folder.
- 13 Nov 2026, step 7 (owner: "Yes, step 7"). Version **758** = "Yangon step 7: traffic lanes".
  - **Lanes** (`tools/yangon/d9_lanes.py` -> `src/shared/YangonLanes.lua`, in Studio as `ReplicatedStorage.Shared.YangonLanes`):
    - The same format as `RivieraLanes`. 28 lanes numbered 189..216 (after Monaco's 144 + 44), 47 links, 4,881 points, 118k characters.
    - Right-hand traffic. Main roads 2+2 (lanes 8 and 24 right of the middle). Side lanes are one-way, 2 lanes at half their width from their middle (the Kabar Aye lanes start exactly on the loop's own lanes).
    - Decks carry 2+2. The roundabout has 2 closed lanes (radius 76 and 96) running anticlockwise.
    - **No street lanes** (owner's rule: traffic on main roads only).
    - The loop is two runs: A (roundabout to the Kabar Aye split) and B (where it resumes, over the Pyay deck, back to the roundabout).
    - Junction links stop 18 studs clear of a junction: University Avenue and New Road at the loop, University Avenue across the Pyay east lanes, University Avenue at the west lane. Left turns use the inner lane, right turns the outer.
    - The side lanes leave and rejoin the loop's outer lanes as lane changes over its widened ends.
    - No dead ends: the script checks it. Plots at junctions: `--plot outdir`.
  - **Game code:**
    - `RivieraTraffic.build` appends `YangonLanes` like `RivieraLanesHighway` (guarded by `first == #lanes + 1`).
    - `Traffic.lua` now turns the lane graph on when `workspace.Riviera` **or** `workspace.Yangon` is there.
    - The graph builds in Edit: 4,823 live Yangon lane pieces and 45 turns. The 28 pruned pieces are the game's own merge rule (an outer lane that leads where the inner one does changes lane about 9 points before its end).
  - **Lane check** (`ClaudeTools.LaneCheck`, `roads = workspace.Yangon`): 113,731 points, 0 edge, 0 block. 7 spots remain, all single rays:
    - 2 hairline seam holes, 1 to 4 rays in 289 at 0.25-stud spacing.
    - A 6 cm seam at the Kabar Aye split.
    - 4 one-ray kinks on paint (nothing at 3 studs either side).
  - **Fixed because of it:**
    - A side lane's end cross-section must lie exactly on the loop's. `d7_flyovers.py` used the chord's direction and offset along the chord's perpendicular, which is up to 2 degrees off the sample's stored direction (the one Roads.build uses). That left a gap up to a stud wide on the east lane's side of the Kabar Aye split, now within 0.005.
    - Yangon roads now cap how fast an edge may climb from a junction at 5% (`M.EDGE_GRADE`, Monaco used 19%). New Road climbed 1.1 studs in 6 at its fork.
  - **Not done / for step 9 and 11:**
    - **Play test:** the test save claimed its first car (Horizon Z33) through `ClaimStarter`. After the restart, the MCP's `start_stop_play` kept answering "Start play hasn't finished yet" while Studio stayed in Edit and responded. Pressing Play by hand once, or reopening Studio, should clear it. The save store is back on `CityLegends_v1`, checked before the save.
    - `Config.monacoOnly()` keys on `workspace.Riviera`. When step 11 moves Monaco out, the old city's lanes would come back: change it to look for Yangon too.
    - Pedestrians, police lanes, speed cameras, spawn spots and `BusyZones` are still Monaco-only (step 9).
- 13 Nov 2026, step 7 Play test (owner reopened Studio, then pressed Play; test save `CityLegends_test`, put back to `CityLegends_v1` after, checked).
  - All 28 traffic cars moved to Yangon round the player within seconds.
    - Every car was on a lane line (0.0 studs off) with its bottom 0.2 over the road.
    - In 3.5 s samples: 0 cars stuck at Kabar Aye, and 2 slow at the roundabout (one giving way at its entry, one on the ring).
  - Moves seen by driving (not by re-placing):
    - **Kabar Aye:** loop A onto the east side lane, the east side lane merging onto loop B, the west side lane back onto loop A, New Road's deck landing on loop B, loop B onto New Road's deck.
    - **Roundabout:** loop A into it. All 28 angle samples ran anticlockwise.
    - **Pyay:** 10 cars up on the deck at once, the east side lane merging back onto the loop, University Avenue turning onto the west side lane.
  - Traffic drives on the right (oncoming cars on the left).
  - **Not seen yet:** loop B turning onto the Kabar Aye west lane (its link is there).
  - **The minimap is blank in Yangon** (step 9).
  - **MCP trap:**
    - After a Stop, `start_stop_play` times out and stays stuck on "Start play hasn't finished yet". Studio stays in Edit, and its memory shows nothing starting. Pressing Play by hand did not clear it.
    - What works: the owner reopens the place and presses Play; the MCP then drives that session (Client / Server `execute_luau`, keys) and Stop works.
    - Switch the save store to the test one BEFORE the owner presses Play. Right after the reopen, a Play started on the live save. It was stopped within 5 seconds; it loaded the save and changed nothing.
  - Pictures: `Yangon 7 - ...jpg` in this folder.
- 13 Nov 2026, step 8 (owner: "Yes, step 8"). Version **764** = "Yangon step 8: buildings, landmarks, far city".
  - **Reference study first** (Brain method). Research note: [[2026-11-13 Research - Yangon buildings (step 8)]]. Findings:
    - **Optima** is Optima Werkz Yangon, a car tuning workshop on Thanlwin Road. That's a good start point for a car meet.
    - **Novotel** is Novotel Yangon Max: 15 floors, two towers on a podium.
    - **MM Plaza** is Myanmar Plaza: a 5-floor mall with towers behind.
    - **Ordinary buildings** are pastel walk-ups (about 90% of Yangon's flats), shophouses with big signboards, condo towers near the big junctions, and gated villas on the leafy streets.
  - **Plots** (`tools/yangon/d10_plots.py` -> `imports/refs/map/ygn_plots.json`, in Studio `YangonData.Plots`): 1,267 rectangles facing their road, 4.5 studs behind the pavement.
    - Nothing within the road's pavement + 3 of any road, 40 of a deck, the roundabout or water (the OSM lake outlines). They don't overlap, and 12% of frontage is left empty.
    - The three landmarks are placed first, at the design's spots.
    - First run gave 432 plots: a front exactly on the clearance line failed by rounding. The setback is now 1.5 more than the clearance.
  - **Buildings** (`tools/yangon/YangonBuildings.luau` on Monaco's kit `tools/riviera/Buildings.luau`):
    - The kit gives real window recesses, a pane per lit window tagged `Window` (WorldFx lights them at night) and `Detail` tagged LOD.
    - Yangon types: walk-up (pastel, grilled balconies with washing, AC units, black and blue water tanks), shophouse (roller shutters, wide signboard, some rooftop signs that glow at night), condo tower (named crown, only near Hledan, Myanmar Plaza and University Avenue's end), gated villa (hipped red or green roof, wall and steel gate, yard trees).
    - Floors are game scale (12 ground, 9 a floor), not the map's 1.6 studs a metre: at that the buildings would be doll-sized next to the cars.
    - No glass rails (half-transparent parts are banned on phones). Made-up shop names only.
    - **Landmarks:**
      - Optima Werkz: workshop, roller doors, office, pylon, forecourt with attribute `MeetSpot`.
      - Novotel: podium, 15-floor tower and a wing, "NOVOTEL" board on a navy band, canopy.
      - Myanmar Plaza: white mall, dark-glass corner atrium, red pylon, two towers.
      - All three as plain text, no logo artwork.
    - Result: 553 walk-ups, 409 villas, 292 shophouses, 10 towers, 3 landmarks; 137,912 parts (109 a building; Monaco's were 244); built in 41 s.
    - `Unstack` (no faces on one plane): about 0.8 pairs left a building, against 42 in Monaco's finished city.
  - **Far city** (`tools/yangon/YangonFar.luau`, in `Workspace.Yangon.Far`, Persistent, nothing collides):
    - The map had nothing past its edge. The skirt fills grass outward 2,600 studs at each stretch of edge's own height (222 fills).
    - Then a belt of 520 trees 30-360 past the edge, and 431 distant buildings in clusters 420+ out (body, three window strips, cap), taller towards Hledan and downtown.
    - **Shwedagon:** the gold stupa on its hill at its real bearing, about 2 km south, 1.4 times true size so it reads from the streets. It is tagged `LampGlow`, so it glows gold at night.
    - A rebuild measured the ground on the first hill and raised the stupa about 60 studs. It looks fine; to redo it, measure the ground off the hill.
  - **Totals:** Yangon 330,072 parts (roads 185k, buildings 138k). Monaco unchanged (388,029) until step 11.
  - **Not done:**
    - The middles of the big blocks between roads are empty grass (fine from the street, sparse from above).
    - No street dressing yet (power poles, rain trees, lamps: step 10).
    - Optima's look is a guess: the research found no photo of the real workshop.
    - Quality-nerd kid check and phone-size pictures: with the Play test in step 11.
  - **Owner, 13 Nov 2026: "Keep real names".** Novotel, Myanmar Plaza and Optima Werkz keep their real names on the buildings, as plain text (no logo artwork). The filler shops keep made-up names.
  - Pictures: `Yangon 8 - ...jpg` in this folder.
- 14 Nov 2026, step 9 (owner: "Rush Yangon", then "Try again" for the Play test). Saved in Studio (Team Create).
  - **Map switch:** `Config.activeMap()` is "Yangon" when `Workspace.Yangon` is in the place, else "Riviera". `Config.monacoOnly()` is now true with either map, so taking Monaco out in step 11 no longer brings the old city back.
  - **Venues:** `Config.YangonVenues.Sites` (same format as Monaco's). A venue named there is built in Yangon; the rest stay in Monaco. Now: Legends Motors on the loop 176 studs from Optima, Legends Customs 188 studs away (lots from `tools/yangon/d11_sites.py`).
  - **Lots:** `tools/yangon/YangonSites.luau` (`prepare`, `undo`, `fuel`) takes the Yangon buildings off each lot (kept in `ServerStorage.YangonSiteHidden`), levels the ground and lays a pad in `Workspace.Yangon.Sites`. 11 buildings moved for 3 lots.
  - **Gas station:** Legends Fuel Yangon on New Road, 257 studs from Optima: Monaco's station (`tools/riviera/CareVenues.luau`, which can now build on any map and with any brand), pumps and chargers in `Config.Fuel.Stations`. Fuel works in Play (the FUEL button shows at the pump).
  - **Start:** the first car comes out on the Yangon Loop's outer lane within 260 studs of Optima (`Config.Spawn.YangonRoads / YangonNear / YangonRadius`). In Yangon the casino garden start is off: players start in their car. The menu circles Optima; the loading shots are over Optima, along the loop and across to Shwedagon; Backspace reset finds the Yangon lanes.
  - **Fast travel:** Optima Werkz, Novotel, Myanmar Plaza, Hanthawaddy Roundabout, New Road, University Avenue (on the outer lane beside each), plus Legends Motors, Legends Customs and Legends Fuel Yangon.
  - **Minimap:** `tools/yangon/d12_minimap.py` draws Yangon in Monaco's night style (lake, every building, roads, flyovers, roundabout): 27 picture tiles in `src/client/YangonMapArt.lua`. The minimap and the menu's world map draw it beside Monaco.
  - **Play test (test save):** the car came out on the loop by Optima, the Yangon map showed in the menu and minimap, Legends Motors and Customs were built in Yangon, fast travel to the gas station and Novotel landed right.
  - **Not done yet:** the bank, hotel, towers, Legends Rewards, gem showcase, houses, races, jobs and Legends Service are still in Monaco (fast travel takes players there). Backspace reset only knows the main roads' lanes (on a street it goes to the nearest main road). The big pad round the gas station is plain concrete.
  - Pictures: `Yangon 9 - ...jpg` in this folder.
- 14 Nov 2026, step 9b (owner: "Move more venues"). Version **781**.
  - **Code check first:** a workflow read each venue's code for Monaco ties, and a second reader re-checked each list. It found:
    - The bank, the heist drop-off and the gem showcase have to move together, because gem loot is cashed in at the bank's drop-off.
    - The hotel and the towers are built square to the world axes, so they need lots that are too.
    - Legends Rewards' car courts make it 304 wide.
    - Drive-in ramps (`EntranceRamp`) looked for kerbs only in Monaco's roads.
    - Smaller ones: the realty size was read from Monaco's table, the tower telescope aimed at the old city, the Myanmar Plaza spot used the gem icon, and a chauffeur booked across the two cities said "No road there yet".
    - All fixed. `WestLayout.siteData`. The ramp now picks the roads of the map it stands on. The chauffeur says "That's in the other city: use fast travel". The client police lanes also start for Yangon.
  - **Lots:**
    - `tools/yangon/d13_more_sites.py` finds the lots left over, plus lots square to the axes facing north (for the towers).
    - `tools/yangon/d14_wide_lot.py` finds a wide lot on a straight stretch (for Rewards).
    - No two lots overlap (checked with an 8-stud margin). `YangonSites.prepare` takes a width `w`.
    - Every lot's height matches the pavement within 0.05. 34 Yangon buildings were moved to `ServerStorage.YangonSiteHidden`.
  - **Where they are:**
    - The bank and the gem showcase are on the loop south of Optima.
    - Legends Rewards is on the loop 316 studs from Optima.
    - The hotel is on the loop's south-west side.
    - Tower Aurum, Tower Skyline and Tower Crown stand in a row along New Road and the loop.
    - Legends Realty is by the loop west of Optima.
    - The heist drop-off is by Myanmar Plaza.
  - **Play test (test save):**
    - Every venue was built in Yangon, with no script errors in the Output.
    - The drop-off marker is at its Yangon lot.
    - Seen from above, the venues sit flat on their lots. The hotel front from the street looks right.
  - **Not tested yet:** a full bank heist or gem run to the drop-off, a penthouse visit, the hotel's valet and ramps.
  - **Still in Monaco:** houses (lots and the realty catalogue's house plots), races, delivery jobs, chips, Legends Service, the Racing Hub.
  - Pictures: `Yangon 9b - ...jpg` in this folder.
- 14 Nov 2026, step 9c (owner: "Move houses and races"). Version **784**.
  - **Code check first:** a workflow read how houses, races, jobs and chips work. In Monaco they all come from one generated file, `RivieraWorld.lua`.
  - **New data file:** `src/shared/YangonWorld.lua` has the same shape. `ActivityData` and `IsleLayout` load it when Yangon is the active map, and warn in the Output if it fails to load (before, a failed load quietly brought back the old city's races).
  - **The generator:** `tools/yangon/d15_world.py`.
    - It runs in two passes, because the heights must be the ones Studio built.
    - `probe` writes the points to measure. The probe tool goes to Studio as a module (the points as one string; a 4,800-row table didn't load).
    - `build` reads the measured heights and writes the file, the lot pads (`build/yangon_world/pads.json`) and a plan picture.
  - **House lots (45, as many as Monaco):**
    - 10 high (120 x 130), 13 mid (104 x 100) and 22 low (60 x 72).
    - They're on the streets south of the loop near Optima Werkz, the big ones on the leafy streets.
    - Each faces its street 3 studs behind the pavement, at the pavement's measured height. They're clear of roads, decks, water, landmarks, venues and each other (with the pad's margin).
    - `YangonSites.prepare` levelled them as `lot_<id>` pads. 102 Yangon buildings were moved to `ServerStorage.YangonSiteHidden`.
    - At start the game builds 45 FOR SALE signs and drive-in ramps. `Houses.cutPlate` now finds Yangon plates, so the underground garages work there.
  - **Saved houses:** a player whose house was on a Monaco lot keeps the house (design, bays). On joining they're told "Your old lot is gone but your house is safe: claim any FOR SALE lot", and they claim a Yangon lot. Nothing is lost or refunded.
  - **Races (4, on the main roads' traffic lanes):**
    - Optima Run: 4,836 studs, from the roundabout past Optima Werkz.
    - New Road Flyover: 4,366 studs, over the Kabar Aye deck.
    - University Avenue: 2,312 studs.
    - Pyay Road Flyover: 5,200 studs, the west loop over the Pyay deck to the roundabout.
    - Checkpoints are every 180 studs. No start or finish is next to a flyover or in the roundabout.
    - Monaco's highway race isn't in the Yangon list.
  - **Racing Hub:**
    - A lot on New Road about 530 studs from Optima, with a ring per race (`YangonWorld.hub`).
    - The fast travel "Racing Hub" goes there. Stopping in a ring forms the lobby, then the race takes you to its start line.
  - **Jobs and chips:**
    - 2 dispatches (by Optima Werkz and by Myanmar Plaza).
    - 12 drop points with made-up names. Each is at least 900 from both dispatches, with no lake between (job times are straight-line).
    - 25 chips on pavements.
    - Yangon chips are saved from number 1001 on (`ActivityData.chipBase`), so Monaco pickups don't count and the all-chips bonus counts only this map's chips.
  - **Play test (test save):**
    - Lots, signs and ramps loaded with no errors.
    - Fast travel to the hub. Stopping in the Optima Run ring formed the lobby ("RACE FORMING · OPTIMA RUN · 15 s"), and after it the car was taken to the start line by the roundabout.
    - Driving forward passed checkpoint 2 of 27 (gold 0:47).
    - From above, the house street showed flat lots, signs and ramps.
  - **Not tested yet:** claiming a lot and placing a house, an underground garage on a Yangon High lot, a full race to the finish, a delivery job, picking up a chip, a duel.
  - **Still in Monaco:** Legends Service (the repair shop), the speed traps and the leaderboard board (Challenges), the old Monaco hub's dressing.
  - **The Yangon hub is a plain pad with rings:** Monaco's `RacingHub.luau` dressing (arch, flags, signs) has fixed heights and would need changing to dress it.
  - Pictures: `Yangon 9c - ...` in this folder.
- 14 Nov 2026, step 10 (owner: "Step 10 night lights"). Version **786**.
  - **How night works (WorldFx, nothing new in code):**
    - Lamp heads tagged `LampGlow` glow at night.
    - Lights tagged `LODLight` / `DayOff` switch on within about 300 studs of the camera (the phone limit Monaco uses; it applies east of x 9000, so Yangon too).
    - Parts tagged `Window` light up at night, about 4 in 10, shops more.
    - Yangon's buildings already had their window panes tagged (step 8), so they light up on their own.
  - **Street lamps:**
    - `tools/yangon/d16_lamps.py` picks the spots: main roads both sides every 96 studs (staggered), streets one side every 120 (the side swaps every 600), both flyover parapets every 96, round the roundabout's outer pavement every 20 degrees.
    - It keeps lamps out of junctions, cut road, flyover footprints, venue / hub / house-lot fronts (their drive-ins) and away from race starts, job rings and chips.
    - It writes the spots as one string, packed as `ClaudeTools.YangonLampSpots`.
    - `tools/yangon/YangonLamps.luau` clones the lamp kit onto each spot after a ray proves the ground (pavement, or a deck parapet; a pavement miss is tried 1 and 2 studs further out). 678 lamps placed (7 spots skipped), in `Workspace.Yangon.Lamps`. No pole touches a building, pad or barrier.
    - The kit is a copy of Monaco's StreetLamp, kept in `ServerStorage.YangonData.LampKit` so the lamps can be rebuilt after Monaco moves out.
  - **Owner, 14 Nov 2026: "yangon lights are white, not dimmed lights".** Yangon's lamps are white LED: head (236, 244, 255), SpotLight (232, 240, 255), brightness 7, where Monaco's are amber. Applied to the kit and all 678 lamps (the tool makes new kits white).
  - **Far city:** its window bands (`FarBand`) now carry `Window` + `FarWindow`, so they light at night (1,293 bands).
  - **Play test at night (test save, `PreviewHour` 22):** the loop by Optima Werkz has white pools of light on the road and lit shop and flat windows. From high above, streets further than ~300 studs look dark (lights switch off with distance, as in Monaco).
  - **Not done:** power poles and rain trees (street dressing), coloured lights on the decks, a phone-size night check (step 11).
  - Pictures: `Yangon 10 - ...jpg` in this folder.
- 14 Nov 2026, step 11 (owner: "Yes, step 11"). Version **788**.
  - **Code check first:** a workflow read every script for code that breaks without `Workspace.Riviera`. Fixed:
    - The chauffeur's road graph only had Yangon's lanes while Monaco was there ("Walk to a road first" everywhere). It now keys on `Config.activeMap()`.
    - Fast travel and the world map offered 4 Monaco places and 6 Monaco gas stations, which would drop players into empty space. They now show only while Monaco is in the place. The minimap's gas-station icons follow the same rule.
    - The leaderboard board would have stood alone in the old city's empty space. It's now in the Racing Hub's lot.
    - The first car's spawn could, on a busy server, fall back to the old city's start block. It now walks every Yangon start spot and never falls back.
    - Knock-over lamps now include Yangon's.
    - The hotel's and Rewards' palms are still copied from Monaco's, now in ServerStorage.
    - `WestLayout.siteData` no longer returns Monaco sites without Monaco.
    - The old-city chauffeur stand icons are off.
    - The Config comments now say where Monaco is.
  - **Legends Service (the repair shop) in Yangon:**
    - On New Road beside the Racing Hub (lot from `tools/yangon/d17_service_lot.py`, levelled by `YangonSites.prepare`).
    - Built by Monaco's builder (`CareVenues.service` with `root` = Yangon).
    - `Config.Service.Bay` / `Arrive` point at it.
    - The street lamps were re-run so none stands at its drive-ins (676 lamps).
  - **The move:** `Workspace.Riviera` is now `ServerStorage.Riviera`, and `ReplicatedStorage.RivieraFar` is now `ServerStorage.RivieraFar` (so it no longer goes to every phone). Both are kept whole; moving them back brings Monaco back. It took 4 seconds.
  - **Monaco's terrain** is still in `Workspace.Terrain`. Streaming only sends what's near the player, so phones in Yangon don't load it.
  - **Playtest (test save):**
    - Active map Yangon, no script errors.
    - All 13 venues built in Yangon.
    - The leaderboard sits at the hub.
    - All 21 fast-travel spots are in Yangon.
    - 28 knock-over props round the start.
    - The car came out on the loop by Optima Werkz.
  - **Phone check (what Studio can measure):**
    - 60 fps on the PC.
    - About 34,000 parts streamed in round the start (streaming radius 640).
    - 234 lights on by day and 255 at night, 47 of them casting shadows.
    - Most of those lights are the venues' own (showroom, Rewards palace, Customs, bank, gems, the repair shop). All the venues now stand close together round Optima, so they're all near the start at once, where Monaco spread them out.
    - Studio can't show a phone's speed. **The owner should open the game on a real phone** (after publishing) and drive from Optima round the loop. If it stutters, the first fix is to switch venue lights off with distance, like the street lamps.
  - **Still to do:** a real phone test, the Monaco ties that only matter if speed cameras come back (`Police.cameraSpots`), pedestrians for Yangon (none yet), dressing for the Yangon Racing Hub.
  - Pictures: `Yangon 11 - Legends Service.jpg`.
- 14 Nov 2026, step 11 follow-up: venue lights by distance (owner: "Yes, do it").
  - **Change in `src/client/WorldFx.lua`:**
    - Every light inside the venues (`Workspace.City`) and the fuel / repair forecourts (`Yangon.CarCare`) now switches off past 160 studs (128 on a phone), the same way the street lamps switch off past 300.
    - These lights cast shadows only within 80 studs. On phones and low graphics there are no shadows at all, street lamps included (before, a lamp built with shadows kept them on phones).
    - Exterior floods and lamps (tag `DayOff`) keep 300.
    - A light with attribute `NoLod` is left as built.
    - Display / showcase cars' lights are left alone (CarSkin switches their TailGlow off).
    - The light ranges now follow the menu's Graphics choice (before, they were fixed when the game started).
    - Lights that stream out are dropped from the list (it grew all session before).
  - **Checked by a review workflow** (correctness + phone performance readers, a skeptic per finding). It caught that most venue lights were already on the 300 rule, so the first version missed them, and the display-car tail glow problem. Both are fixed.
  - **Play test at the start point (test save):**

    | | before | after |
    |---|---|---|
    | lights on by day | 234 | 77 |
    | lights on at night | 255 | 89 |
    | lights casting shadows | 47 | 0 by day, 5 at night |

    Scripts 1.2 ms a frame. The night street still looks lit (white lamps, lit windows).
  - **Still the owner's:** the real phone test after publishing.
  - Picture: `Yangon 11 - night after venue light LOD.jpg`.
- 14 Nov 2026, batch 0.5 accuracy pass (owner: "this is batch 0.5 also it dont look like the google maps one ...", then "do everything, im going now so dont ask me any more questions"). Plan and reference study: [[2026-11-14 Yangon batch 0.5 - reference study and accuracy plan]]. **Saved: Roblox version 799** (restore point before it: version 791).
  - **Roads at real lane counts** (`tools/yangon/d18_widen.py` -> `ygn_roads_v4.json`): 16 roads that are 2 + 2 in real life are now main roads (half 32, like the loop): Saya San, Insein, New University Avenue, **No.1 Industrial** (the owner's "its 2 lane in real life"), Kanbe, Pyay Road North / South, Parami Road West / East, Hledan, Kabar Aye Pagoda Road South / North, Inya Road (all three pieces), Hanthawaddy. Roads rebuilt (143k road parts, 10 scraps moved out). They are one wide carriageway with a centre line, not two carriageways with a divider.
  - **Traffic lanes** (`d9_lanes.py` on v4): 92 lanes, 145 links, no errors. The widened roads have traffic now; a lane end that would climb (New University Avenue's T at the loop's ramp) turns round instead. Play: all 28 traffic cars moving.
  - **Real buildings** (`d19_buildings.py` from OpenStreetMap, ODbL; `YangonRealBuildings.luau`): 3,249 buildings on their real outlines: 2,833 houses / blocks, 281 walk-ups, 83 shophouse rows, 33 towers, 13 villas, **3 round towers**, the 3 landmarks. Floors from OSM where given, else an estimate. 65,900 parts (the made-up step 8 buildings had 138,000; they are kept in `ServerStorage.YangonBuildings_step8`).
  - **Inya Lake embankments and parks** (`d20_green.py`, `YangonGreen.luau`): concrete edge + parapet + light walkway along the shore where it runs beside the main roads (145 pieces), 87 benches facing the water, 87 white walkway lamps, 242 trees by the lake and in the parks, 6,865 trees in the city (rain trees, mango trees, palms). **Playtest found every walkway buried** under the grass fill (terrain is 4-stud cells): each walkway is now raised just over the ground with its parapet and edge, benches stood back on it (the tool does this itself now: `M.lift`).
  - **Lamps** re-run on the new roads: 786.
  - **Venues and lots refit** (`d21_refit.py`): 35 house lots pushed back from the wider roads (24 on Inya Road, about 16 studs), 8 job / chip points moved off the carriageway; lots re-laid in Studio. The venues themselves did not move to new sites.
  - **Minimap** redrawn from the real roads, buildings and trees (27 new tiles).
  - **Playtest (test save, put back to `CityLegends_v1`):** start by Optima on the 2 + 2 road; all 21 fast-travel spots land on road / forecourt; all 4 races' 93 checkpoints on road; traffic all moving; white walkway lamps at night; no new script errors.
  - **Side by side:** `Yangon 0.5 - Google, before, after (top view).jpg` (Google, the owner's top view, now). The built area now reads like the Google picture: the Hledan / Kamayut house blocks, the university's big buildings, trees everywhere.
  - **Not done / still rough:**
    - Real divided carriageways (two roads with a median) are not built: the 2 + 2 roads are single wide roads.
    - Buildings are boxes (and a few cylinders) from parts, not Blender meshes; roof colours are not the real ones.
    - The Boat Club pier and the islands' paths are not built.
    - The night road between Rewards and Customs is darker (the lamps keep off the venues' fronts; the venues light it).
    - The venue lot plates show as big grey squares from above.
    - The far north (past the lake) is still batch 1.
  - Pictures: `Yangon 0.5 - start, 2+2 road and real buildings.jpg`, `Yangon 0.5 - lake embankment and trees (before the walkway fix).jpg`, `Yangon 0.5 - embankment lamp at night.jpg`, `Yangon 0.5 - Rewards and Customs at night.jpg`, `Yangon 0.5 - Google, before, after (top view).jpg`.
- 14 Nov 2026, batch 0.5 to real density (owner: "yes do all that until its 1:1 like real yangon", "too clean ... in real life its compact", "check the roads too ... some are 4 lane and 6 lane and 2 lane", "the overhead bridges are too low", "wheres the fusan basketball court, u need to add EVERY single detail"). Plan: [[2026-11-14 Whole Yangon map - master plan]].
  - **Main roads v5:** real lanes each way from OSM (Pyay, Kabar Aye, Insein 3 + 3 divided; No.1 Industrial, New University Avenue 2 + 2 divided; the rest 2 + 2), raised red-white medians (10,944 parts), traffic lanes with lane 3. Both flyovers raised: clearance 17.8 / 18.5 / 19.5 studs (was 9.5); the Kabar Aye ramp lengthened (lands at loop sample 866). A first rebuild lost most of the loop's pavements (road-level half = widest section); fixed and rebuilt (pavements 16,273 on the loop, mouths clean).
  - **Buildings at real density:** 19,098 (3,260 real OSM outlines + 15,838 infill by land use), built-up land 13.7% -> 36.6%, as 1,877 mesh pieces in 626 cells + 19,537 invisible collision boxes; old part buildings in `ServerStorage.YangonBuildings_realparts`. Named places keep their kind and name (221: schools, hospitals, halls; Fusan Basketball Court a grey metal-roofed hall; Lotte Hotel 23 floors). Night windows switch with the lamps.
  - **The missing streets:** 1,263 real streets (about 130 km) as meshes + 43,812 collision boxes.
  - **Detail layer:** 6,590 items (41 pitches and courts with markings, 22 pools, 60 bus stops, 36 signals, 985 compound walls, 656 gates, 3,178 power poles with 5,559 wires and 1,589 pole lamps, 214 tea-shop sets, 70 trishaws, 312 shop signs, 3 footbridges at 18 studs clearance, 17 stupas / monasteries / a church).
  - Green re-run (4,548 city trees, lake walkways lifted over the grass), 787 street lamps on v5, minimap redrawn with every street.
  - **Playtest (test save, put back):** spawn by Optima fine, traffic moving, Hledan side street dense and lived-in, night windows on, Fusan court on Kabar Aye. Studio uses 15.3 GB in Play (4.7 GB free of 32): the memory budget is the risk for batches 1-3.
  - **Still to do in 0.5:** parked cars and people on the side streets, the Boat Club pier, Burmese-script signs, the grey venue lot plates.
  - Pictures: `Yangon 0.5b - ...jpg` (start, Hledan side street day and night, Fusan court, Google / before / now top view).
- 14 Nov 2026, batch 1 in the cloud place (owner: "Redo the missing batch 1 pieces in the cloud place"). After a Studio crash the auto-recovery file was newer than the cloud place: the cloud saves had been failing with "could not upload place. File too large". Batch 1's 946 building cells, 9,914 detail items, 855 lamps and 5,605 trees were placed again in the cloud place; 21 MB of temporary data modules (probe points, terrain tiles, collision / detail data) were deleted, then it saved (**version 842**). Then the improved building collision (boxes split to follow U / L shapes, no invisible walls over roads) replaced the old boxes: BuildingCollideB1 33,767, BuildingCollide (0.5) 20,537. Still open from the seam agent (stopped by the crash): Shwedagon's hill, Nar Nat Taw's cliff, Inya Road / Kan Road gaps, U Wisara / Kabar Aye / Insein joints, floating carriageways. **Batches 2-3 need room in the place file:** the old ServerStorage backups (Monaco 373k parts, the old map 169k) are the owner's call.
- 14 Nov 2026, room for batches 2-3 (owner: "i only want the monaco map to be saved, not the old map"): the owner saved Monaco to `D:\RobloxStudioGameFiles\Riviera.rbxm` and `RivieraFar.rbxm`; the old pre-Monaco map was deleted for good, Monaco and its build backups taken out of the place, Monaco's palm kept in `ServerStorage.MonacoKit` for the hotel and Rewards casino. **Version 845**, Studio memory 20 -> 11 GB.
- 14 Nov 2026, owner verdict on batches 1-2 and the parked state (owner: roads from batch 1 on "so bad ... broken", "the map system is broken, sometimes some part of the map doesnt load", buildings "just some blocks with windows", "the terrains and everything is wrong too"). Cause of the missing pieces: 15,537 unique building meshes, so Roblox throttled the asset loads (HTTP 429 / 503 / 504) and parts of the map never arrived. Batch 1 / 2 meshes were parked in `ServerStorage.YangonBatchesParked` (**version 868**) so batch 0.5 loads cleanly. New rule: buildings come from a reused kit, never one unique mesh per cell. Approach v2: real models of named places from photos, a Blender kit for ordinary buildings, terrain from real data (Copernicus GLO-30: report in `Games/CityLegends/build/terrain_study/`), batch 1-3 roads rebuilt the batch 0.5 way; one district at a time, each shown to the owner first.
- 14 Nov 2026, **Myanmar Centre pilot** (the first real landmark of approach v2: Myanmar Plaza mall, the two 27-floor office towers, Melia Yangon, The Lake Suites, the MYANMAR CENTRE plinth at the Kabar Aye Pagoda Road / No.1 Industrial Road corner).
  - **References:** Wikimedia Commons photos of the corner, the west entrance and the towers; Esri satellite at zoom 19 (it leans: each tower's west wall shows as a dark band, so roofs sit ~0.29 m east per metre of height; bases moved back by that); OSM outlines; Wikipedia's tallest-buildings list (Myanmar Plaza I / II 27 floors). Google Earth 3D for Yangon is too smeared to measure towers from.
  - **Fit to the game roads:** the roads are car-scale wide, so they cut 13-23 studs into the real outlines. `tools/yangon/city/landmark_mc_fit.py` clips the podium to the free lot (Studio raycasts), slides tower A 28 studs onto the clipped Industrial Road edge, and fits the plinth as a long shallow arc (radius 40, 104 degrees, 63-stud chord) in the corner wedge; 70% of the podium kept.
  - **Model:** `landmark_mc_blend.py` (Blender 3.6, headless) + `landmark_atlas.py` (one 1024 picture: champagne office bands, beige granite podium, shopfronts, LED screen with orange bars, three made-up billboards, maroon granite, names as plain text) -> `landmark_mc_glb.py` (F / R / G meshes in the YangonBuildingMeshes format, night windows included, ground pieces on the pavements' slope) -> 3 meshes, ~10,600 triangles, 108 collision boxes. Before the first Studio placement a panel of 5 critics compared renders with the photos (massing, facades, street corner, "looks cheap", Roblox tech) and ~20 fixes went in (LED wall size and orange bars, the tilted roof canopy on white V struts, tower A rising from the street with its stepped end, tower B's bowed face and end slots, the plinth's granite / band ratio and names, a base under the Melia, closed roofs, below-ground skirts).
  - **In Studio:** `Workspace.Yangon.LandmarkMeshes.MyanmarCentre_mc` (Persistent) + `Yangon.LandmarkCollide`; assets: model 102943814771844, atlas 89781913419584 (v3, darker for the map's bright lighting: exposure 0.75), mask 113037985174510. The 28 generated buildings on the site and the old part-built landmark are parked in `ServerStorage.YangonReplaced_MC` (attribute HiddenFrom); cells 126xn5 / 127xn5 / 127xn6 rebuilt without them (asset 108402197209968). Terrain cleared under the plaza.
  - **Trap:** in Blender 3.6, adding a colour layer after a UV layer moves the UV layer's memory; writing through the old reference crashed Blender (twice). Make every layer first, then look them up again by name.
- 14 Nov 2026, **Myanmar Centre and Sedona in real 3D** (owner: "make myanmar plaza 3d, not with textures and decals, make interior of myanmar plaza too and also sedona"). The textured pilot was replaced.
  - **How it is built now:** no picture atlas. Every face belongs to a material group (`tools/yangon/city/landmark_glb3d.py` GROUPS: glass, metal spandrels, sandstone, white frames, lobby glass, neon light panels ...). In Studio each group becomes MeshParts with a Roblox Material and Color (`tools/yangon/LandmarkPlace3D.luau`). Facades are geometry: bands standing out of a recessed glass skin, real mullion fins, solid crowns. The names are 3D letters made with Blender (`text3d_blend.py`; bent round the plinth arc). Pictures stay only where the real thing is a screen or a billboard (parts with SurfaceGui pictures).
  - **Myanmar Centre** (`mc3d.py`, ~40k triangles): tower A with champagne metal bands from the street (stepped ends), tower B bowed silver glass with end slots, the podium in sandstone bands over dark glass, the corner front (LED wall and boards, the entrance canopy on columns, the tilted roof canopy on white V struts), the west entrance with MYANMAR PLAZA standing on the canopy, the white oval roof over the atrium, the Melia and its terraces (pool), The Lake Suites with balconies, the plinth (maroon wall, MYANMAR CENTRE in orange 3D letters, the four names), paving, lamps with red banners.
  - **The mall inside (walkable)** from the real atrium photos: GF-3F open round an oval atrium under a closed grid ceiling with big round lights and a wood cove; frameless glass balustrades with steel posts; a side-by-side escalator pair GF-1F and single runs crossing the void after that (brown cladding); cream floors with a caramel border; charcoal columns; 39 shop units with glass fronts, doors, white fascias with lit names (made-up shop names), partitions and goods; the double-height lobby behind the Kabar Aye Pagoda Road entrance with a three-ring light; 958 collision boxes (floors, stairs under the escalators, railings, shop fronts) and warm lights.
  - **Sedona Hotel** (`sedona3d.py`, ~28k triangles): the Garden Wing's three white arms (ribbon windows, sill ledges, terracotta hip roofs with dark eaves), the central pavilion two floors higher with the bow window and a Burmese tiered spire, the Inya Wing as three interlocking slabs (staggered blue windows in cream portal frames with a pergola crown and SEDONA in white letters; the tallest narrow slab with a dark glass strip; a finned slab), the connector with the pool deck (pool and jacuzzi), the tennis courts, the entrance loop and oval garden, the SEDONA sign board, the white fence on Kaba Aye Pagoda Road; the whole site follows the pavements' slope.
  - 78 generated buildings on the two sites are parked in `ServerStorage.YangonReplaced_MC` / `_SD`; 7 cells rebuilt without them. Saved (Team Create).
  - Pictures: `Yangon landmarks - Myanmar Centre 3D vs real (corner).jpg`, `... mall interior vs real (atrium).jpg`, `... Sedona 3D vs real (Kaba Aye Pagoda Rd).jpg`, `... Myanmar Centre and Sedona 3D (aerial).jpg`.
  - **Not done yet:** shoppers and fuller shop interiors; the night look (a check after the lights and Neon tone); the Sedona north gate; not tested in Play (walking in, escalators).

## 2026-11-14 (evening): paused by the owner, resume Monday 16 Nov, 3:30

Working on the owner's "Fix these first" list and "the materials, textures, looks, colors, designs, lighting is not same as the real life myanmar plaza".

Done so far (in the repo, not yet in Studio):
- **Colour measurement.** `tools/yangon/PlayLight.luau` (also `ServerStorage.ClaudeTools.PlayLight`) sets Studio's edit lighting to what players see in Yangon at an hour (`apply(13)`, `restore()`). Swatch panels (8 materials x 10 greys) were measured at 13:00 into `build/landmarks/look_swatches_13h.json`; `tools/yangon/city/look_calib.py` gives the part colour that renders as a photo colour.
- **Finding:** Yangon's daylight in the game is strongly blue (white plastic in sun renders (216, 228, 244), in shade (182, 208, 233)). To render a cream like the photos, a part needs an orange-ish colour, which would look wrong at sunset. The lighting itself (DayCycle's keys used for Yangon, made for Monaco) is the bigger lever: ask the owner before changing the whole game's daylight.
- **Shop fit-outs** in `mc3d.py` (`shop_fit`): racks with clothes and mannequins, shoe walls, phone tables with a screen wall, food counters with menu boards and tables, a supermarket with aisles, glass counters, shelves. Product colour groups PRA-PRF are in `landmark_glb3d.py`. 53k triangles. Small or odd-shaped shops get only a kiosk.

Next (in order):
1. Read the look-bible results (workflow `wyvmpzs4o`, into `build/landmarks/look/`) and set the group colours and materials (part colour from look_calib, partly).
2. Night windows (FacadeNight) and lit signs.
3. Shoppers: `client/Pedestrians.lua` only walks Monaco's pavements. Add walk paths for Yangon (mall galleries).
4. Sedona north gate.
5. Rebuild, upload and re-place both landmarks, then a Play test and a day and night check against the photos.
