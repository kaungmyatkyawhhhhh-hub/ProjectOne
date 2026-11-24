# roads05 handover (18 Nov 2026, thirty-third pass: J37, BUILDER agent; YangonRoads.kerbSeal + Studio 17 spots)

## REBUILD (owner decision 18 Nov: the game road rebuild starts right after J37, whatever the counts)
- **Build from:** commit 4edc2d9c ("City Legends roads05 J37", master; builder unchanged after it) (`git log --grep "roads05 J37"`), data
  `build/city_1to1/roads05_P1_P2_P3_P4_P5_P6_P7_P8_P9_P10_P11_P12/roads.json` md5 c34a1111..., `paint.json` md5 b6c2ba15...
  (J35 data, unchanged since; pipeline re-run J37 = same md5s, logs `J37_*.log`). Builder: `tools/yangon/YangonRoads.luau`
  179,431 chars (Studio checksum 1843759058), `tools/yangon/YangonRoadsChecks.luau` 27,754 (1841289662), `tools/riviera/Roads.luau`
  55,521 (1407280218). Studio's main place ClaudeTools holds exactly these (saved version 1384).
- **Pack:** test asset 133014134133489 (`roads05_studiotest.py` -> `imports/sync/roads05_studiotest.rbxmx` -> Open Cloud PATCH,
  `model/x-rbxm`; `LoadAsset`, `T.install(m)`); rev 208 = J37 builder. The game build uses the full net / subset modules
  (`roads05_subset.py <net> <sub> <districts>`, `pack_tools.py` -> same asset id -> `YangonSync`); check the printed checksums.
- **200k limit:** Studio refuses a Source over 200,000 chars. YangonRoads is 179,431 (about 20k left); the checks / stepCell
  live in `YangonRoadsChecks` (a ModuleScript in ClaudeTools that YangonRoads' last line requires with its file locals): ship and
  install BOTH (`T.install` moves it; `pack_tools.py` packs it). Next split candidate: buildIslands or buildCorners.
- **Kerb raise caveat (J36 scrub) and the seal (J37):** both probe only the parts in the build root (`M.folder()` = the cell's
  root in stepCell). A kerb next to another cell's asphalt is not raised / sealed when that asphalt is not built in this cell:
  stepCell builds every road within 140 of the box, so inside the box this holds; the bake must clip each cell to its box
  (it does: roads05_bake.py clips to the subset's boxes) so the margins (unsealed) are never kept. kerbSeal runs ~10-40 s a cell.
- **Steps (from the 16 Nov rebuild, vault `City Legends/2026-11-16 Yangon rescale plan - 1 to 1 at player scale.md` "Roads05
  step 2" and "Not done yet"):** per 3072 cell `YangonRoads.stepCell(box, root)` (no-terrain copy for tests only; the real build
  writes terrain) -> `RoadBake05.collect` -> `@Q` pages (kept in `ServerStorage.R05Pages`) -> wipe the cell; offline
  `roads05_bake.py <tag> collect <pages>` then `bake` (scrap filters: drop_scraps, paint_steep) -> glbs (<= 1536-stud cells) +
  `Collide05_*` pages -> Open Cloud upload -> swap `Workspace.Yangon1to1.Roads.Meshes.Cell_*` and `Roads.Collide` (collision boxes
  carry attribute `RoadBox` "R" carriageway / "P" pavement: EntranceRamp and the pavement tools read it) -> delete data modules ->
  save; lanes `roads05_lanes.py <tag> --install` (one-way directions changed since the last lanes); then checkMouths, LaneCheck,
  flicker check, drive test, after shots.
- **Known look faults the rebuild will carry (J37 counts 14 / 84 / 36 / 77 / 0 / 94, arrow_missing 10):** open road edges
  (Bahan Road (35388, 38010)), deck feet vs pavements, the Lane #3308 strip nose under the Banyar Dala deck (shot in the J37 note),
  pavement steps between roads, the univ_kabaraye side-lane road steps.

## OVERLAPS FIX (24 Nov, OVERLAPS FIX agent): roads through Bogyoke / Holy Trinity / Strand / 7 lots; vault `City Legends/2026-11-24 P1-P3 map bug fixes.md` ("Roads through buildings and lots"); state `rebuild_progress.json` "overlaps_24nov"
- **Data:** `tools/yangon/city/roads05_drop_lanes.py <roads.json>...` (idempotent, `test`): DROP the 8 Bogyoke service lanes (Lane #19, #3804-#3810) + their crossings; CUT Lane #4266 where its carriageway + walk reach the Holy Trinity nave / tower box -> `Lane #4266` + `Lane #4266b` (new rank = net max + 1 = 8566: split pieces need their own rank or YangonRoads.load fails "two roads share rank"). Applied to the net roads.json (backup `roads_before_droplanes.json`), `roads05_LP1to10/roads.json` (same backup name) and the new subset `roads05_RB3o` (= RB3 + drop; data pack asset 95173135242351, 34 modules, `pack_checksums.txt`). Streets only, so traffic lanes unchanged (roads05_lanes uses route / side).
- **Cells 22x27 + 22x28 rebuilt whole:** one stepCell box {33792, 41472, 35328, 44544} (RebuildCell `_G.RBXJob`, 85,349 parts, 0 MOUTH FAILED) -> slices printed to the log as P8SM lines of **900 chars** (the log cuts lines at ~1,020: 4,000-char lines broke the base64) -> `roads05_loggrab.py RB3o` (19 pages) -> bake R05_ONLY=22x27,22x28 (22 meshes, 1,446 boxes) -> glbs 75691345510725 139602856215690 76543932010012, collide 81285422132367 (`roads05_RB3o/upload_ids_OVL24.txt`) -> PREP / SWAPGO tag OVL24. HoleFill boxes put back from the backup when within 2 of a new box and not in a hall / church box (468 kept, 100 dropped). New meshes CollisionFidelity Box + CastShadow false (the place's meshes have it off; YangonRoadMeshes leaves it on). Backup deleted (place size).
- **Upload folder:** Open Cloud refuses files outside the approved `imports/` folder: `roads05_bake.py` now takes `R05_GLB_DIR` (write the glbs straight into `imports/sync/<tag>_glb`).
- **Terrain after a dropped road:** the old beds stay carved (2-9 stud trenches). Filled along the 492 dropped samples to the lower lateral ground at +-(half + walk + 10) (`roads05_RB3o/dropped_samples.txt`, x,y,z,dx,dz,half+walk), then cleared terrain over R / P boxes in the 2 cells.
- **Strand Hotel** model moved (0, +1, -30) (attribute `MovedBy24Nov`); lobby / porch terrain cleared, forecourt terrain Pavement. **Lots** moved with `tools/yangon/LotFinder.luau` + `VenueLots1to1.prepare` (table in the vault note); Legends Service model moved by the lot transform, Config.Service Bay / Arrive by the same transform, its Drive ramps re-laid (`legends_service.Drives24Nov`).
- **Saves:** v1906 (Strand + lots + Config sync), v1908 (cells swapped), v1911 (terrain fill, store v1). Play-tested.
- **Not done:** the Kaba Aye Pagoda lane-mouth raised kerb end (builder fault, spot not located from the shot).

## P1-P3 MAP BUGS 2 (24 Nov, MAP BUGS agent): kerbs, grounds, props; vault `City Legends/2026-11-24 P1-P3 map bug fixes.md`; state `rebuild_progress.json` "mapbugs_24nov"
- **Kerb fix in the bake:** `tools/yangon/city/roads05_kerb_fix.py` (self-check `python roads05_kerb_fix.py test`), called by `roads05_bake.bake` right
  after drop_scraps (R05_ONLY limits it): drops leaning kerb pieces (the 6.04-deep axis > 15 deg off vertical), resolves kerb_cross pairs on the smaller
  piece (box cut back / dropped if a sliver or reaching > 1.5 out of the other; else both kept, smaller lifted 0.06 when tops are level). bake_stats has `kerb_fix`.
- **Cell owners (which build each P1-P3 cell is in the place):** `owners()` in the vault note's method = RB12 (P1/P2 middle), RB4 (x18), RB4M (18x19),
  RB6 (18x21, 19x21, 19x26-28), RB7 (20-22 x21 / x26), RBM (22x17, 22x18), RB9 (x24 z10-16), RB3x (21x27, 21x28), RB3v (19-21x29), RB8 (23x21, 23-27x26:
  laptop, NOT re-baked), RB3 (rest of P3). Checked by R/D/M/W box counts per cell = place (only HoleFill boxes differ).
- **Done:** 88 cells re-baked (R05_ONLY lists in `roads05_<tag>/r05_only_mb24.txt`, logs `bake_mb24.log`, glb ids `upload_ids_MB24.txt`), one collide pack
  asset 102846355842608 (modules RColRB_MB24<tag>_k), swapped keeping the 4,773 `HoleFill` R boxes; 13 P boxes over decks removed after; new meshes
  CollisionFidelity Box (place was over the save limit; Box = 3.5 KB vs 25 KB a mesh). Kit KitOnRoad P1-P3 (1,182 records), Green / Parks parts on R (76),
  6 lot plates trimmed. Saved v1885 / v1899 / v1901 (store v1). Old meshes / boxes not kept (place size).
- **Next:** re-bake the 6 RB8 cells on the laptop (the bake now has the fix); the old road meshes elsewhere are still CollisionFidelity Default
  (~25 KB each): setting Box on all of them frees ~20 MB of place size if needed (~0.4 s a mesh).

## REBUILD P10 + P5 IN (24 Nov, DISTRICT REBUILD agent, HOME PC): state `rebuild_progress.json` "P10", "P5"; P1-P10 now all in
- **P10 DONE, saved v1875; P5 DONE, saved v1883** (both Play-tested, store back to v1). Same Studio chain as P9 (below), with these changes:
- **Overlap:** P5's district move and road export ran in Studio while P10 baked offline; then P5 baked while P10 was swapped / cleaned. Never two bakes at once (one bake left 1.4 GB RAM free).
- **Log marker:** the Studio log is one file per session and P10's labels (14x5..14x8) collide with P9's: print `RB10START` / `RB5START` (and `LH10START` / `LH5START` for LaneHeights) before the job and run `roads05_loggrab.py <tag> <copy of the log after the marker>`.
- **P10 step boxes** 14x5..17x8 (1536 col x 44544..46080 + 3072 cols to 55296; rows z 15360/18432/21504/24576..26112); bake R05_ONLY 1536 x29..35 z10..16 (49 cells), 47 glbs / 19,038 boxes. **P5 step boxes** cols 15360..18432 (5), 18432..21504 (6), 21504..23040 (14 = P4 seam) x rows 16896..19968 (11), 19968..23040 (13), 23040..26112 (15), 26112..27648 (17); bake R05_ONLY 1536 x10..14 z11..17, 19 glbs / 7,932 boxes (33 cells: 10x12, 10x17 have no roads).
- **PREP trap:** `_G.PREP`'s `LoadAsset` died with "HTTP 502" at glb 24 of 47 (fresh uploads). Used an inline PREP with a retrying loader (6 tries, 5 s x try); RebuildCell.luau itself is unchanged (load it once for `_G.SWAPGO`).
- **Lanes:** tags `LP1to4P6to10` (after P10) and `LP1to10` (after P5; current: 1,322 lanes / 3,080 links / 0 dead ends, 26 modules, lane_heights 1,771 rows). Raw install -> QuickSync -> LaneHeights -> merge -> install -> QuickSync -> require 26/26.
- **Minimap:** FULL now P1-P10. Adding P5 moved the detail grid's x0 (22667 -> 16273): every d_ tile changed (81 + o_0_0 / o_0_1 uploaded). YangonMapArt 6729 / 1630412133 synced.
- **Left:** P11, P12 (not in the game); P11 lets the U Chit Maung deck (P8 note) get a surface.

## REBUILD P9 IN + P10 / P5 offline (24 Nov, DISTRICT REBUILD agent, HOME PC): state `rebuild_progress.json` "P9", "P10", "P5"
- **P9 DONE, saved v1853** (Play-tested, store back to v1): DistrictPlace (4 packs + night a/b, Far_keep merge 336 cells / 7 dups, old 2 pagodas
  -> RB_OldP9.Temps) -> 12 step boxes 12x5..14x8 in ONE queued spawn (`stepCell` + `RoadBake05.collect`, slices printed as `P8SM` log lines,
  ResetWaypoints per box; 0 MOUTH FAILED) -> `roads05_loggrab.py RB9` -> bake R05_ONLY 1536 x24..29 z10..16 (41 glbs, 16,513 boxes) -> PREP / SWAPGO
  tag `P9swap` (SWAPGO's backup folder is `RB_Old<tag>`: `RB_OldP9` already held the pagodas) -> MapBugScan / KitOnRoad copies from `ServerStorage.P8Tools`
  with AREAS / X0..Z1 gsubbed in the Source -> RoadVerge05 fill + trim per 3072 tile (one queued spawn) -> lanes L12346789 (LaneHeights rows printed
  as `LHR` log lines; old 1,698 rows kept, 55 new) -> minimap FULL += P9 (grid re-laid 5x14: 73 tiles) -> DeckFeetCheck on the RB9 subset decks.
- **Uploads by helper subagents** (41 glbs, 73 tiles); POSTing 4 at a time worked with one "Target is not reachable" retry each.
- **Play kit (client):** claim the starter on a fresh test store (`ClaimStarter`), Return, then attributes `TestDrive`, `TestEngine` = true,
  `TestGearbox` "Auto" (without the engine the throttle does nothing), `TestTeleport` then `TestThrottle` 0.6 and rays onto Roads.Collide every 0.25 s.
- **Studio open trap:** the place open failed after 20 min (`StreamingWaiterFailure`, Start page, MCP unreachable); the coordinator relaunched it.
- **P10 / P5 offline DONE:** `district_files.sh P10|P5 --no-roads buildings` (old outputs `_pre_rebuild_P10` / `_P5`), roads05_RB10 (clip P10+P9) and
  roads05_RB5 (clip P5+P4) with data packs in imports/sync; nothing uploaded. Studio chain = P9's; boxes / swap cells in each entry's "plan".

## REBUILD Road #25 valley + P8 deck end (23 Nov, DISTRICT REBUILD agent, HOME PC): state `rebuild_progress.json` "road25", "P8", "P9"
- **Valley data fix:** `tools/yangon/city/roads05_valley_fix.py <roads.json>...` (idempotent, finds the apex by position, so lane subsets with
  trimmed samples work): Road #25's hairpin samples 223..227 pulled 19.5 south onto Aung Yadana St's centre line, decks shortened by 6
  samples each (#2 14..219, Road Flyover 231..458, last 10 deck samples eased to the ground), cut = inner deck samples, crossing
  `[Road #25, 226, Aung Yadana Street, 195]` (1-based) so `YangonRoads.crossMouths` drops #25's slab on AY and cuts AY's kerbs. Applied to
  the net roads.json, `roads05_L1234678/roads.json` (backups `roads_before_valleyfix.json`) and subset `roads05_RB3v` (= RB3x + fix; paint =
  RB3x paint with AY / #25 items within 70 of (31525,45672) from a fresh subset paint run, old centre line kept).
- 19x29 box rebuilt (139k parts, 0 MOUTH FAILED; slices out through the Studio LOG: `_G.RBXPRINT(label)` prints `P8SM` lines, then
  `roads05_loggrab.py <tag>`), bake 36 meshes / 4,122 boxes, swapped (old in `SS.RB_OldR25C` with `Roads.CollideFix_Road25Valley` and 3 P boxes
  that stood 0.7-1.7 over the #2 deck). DeckFeetCheck: Road #25 feet flush; only U Chit Maung BAD. Play-driven both feet (no step). Saved v1828-1831.
- **Lanes on this PC:** `roads05_L1234678/lane_heights.txt` now exists here (fresh LaneHeights, 1,698 rows); LaneHeights rows printed into the
  Studio log (`LHR ` lines) instead of a big MCP result. Result = the laptop's except Road #25 / Bo Min Gaung Street.
- **U Chit Maung deck = P11, not a laptop file:** the deck north of the Banyar Dala junction lies in P11 (P8 box starts z 32653), so the P8
  bake had no mesh for it (collision kept = invisible deck ending in the air at z 32256). It can only get a surface when P11 is built. Barrier
  kept; `roads05_lanesubset.py` `NO_LANES` takes that deck out of the lane data (no NPC through the barrier).
- **P9 offline DONE here (23 Nov):** district files (15,622 buildings, packs in `imports/sync/ygn1to1_p9`, night glb split a/b) + `roads05_RB9`; Studio steps next ("P9" resume in the progress file). P10 and P5 offline not started (inputs present on this PC).
- **Traps:** Obsidian Git commits work in progress every few minutes (compare lanes with the commit BEFORE your session); `roads05_subset`
  chunks give more modules after a json re-dump (42 vs 31: same data); a TestTeleport beside (not under) a deck keeps the car on the ground.

## REBUILD Road #25 + P6 (19 Nov, DISTRICT REBUILD agent 4): state `rebuild_progress.json` "road25", "P6"
- **Road #25 second cause:** after the alignJunctions guard the rebuilt ramps still rose to the Dala flyover (D tops 39.6-40.2 for ~80 studs
  at both feet). `Roads.luau`'s EDGE PIN (each edge point on a bigger road takes its surface, ~line 715) had no height guard: now
  `|dy| > 8` = a crossing (56,415 chars / 1235852328, asset 122752884486605, Studio ClaudeTools.Roads replaced). Found by running
  `Roads.build` of just the 3 decks (asset 130928365314305 = their data) in the COPY Studio: a fast repro that leaves the main place alone.
  Deck pairs that cross within reach at > 8 studs apart (python scan of RB6 / RB8): only Road #25 x Dala, so builds made before the fix elsewhere are fine.
- 19x29..21x29 rebuilt (RB3w), swapped, saved. DeckFeetCheck 57 ok / 2 BAD = the valley foot itself: the two decks meet ON THE NORTH EDGE of
  the ground road (kerb box 1.5 high across the Road Flyover mouth; ~7-stud gap before #2's first deck box). Needs a data fix (feet onto the carriageway).
- **Invisible kerbs on decks (map-wide):** 34 P boxes standing 0.3-3 over a deck top inside the deck's footprint (Road Flyover #2 start 30139/30196 x 44965,
  Pyay #6 deck, Kabar Aye, 36.9k x 43.5-44.1k) + 6 steep slabs at the valley -> `ServerStorage.RB_PBoxOnDeck`. Other steep boxes listed in
  `steep_boxes_19nov.txt` (not changed). The bake's `roads05_pbox_clip` should drop P slices over decks (not done).
- **Studio traps:** `require` caches a ModuleScript even after its Source changes (DeckFeetCheck gave old results): require a `:Clone()`.
  `ChangeHistoryService:ResetWaypoints()` after a build: 18 -> 15 GB. A long MCP-blocking build: print a marker from Studio and wait on it from bash
  with `grep` on `%LOCALAPPDATA%/Roblox/logs/*Studio*_last.log` (no polling calls).
- **P6:** district moved (v1595, Data_P6 + P6G, Far_keep merge 16 name dups renamed `_old`, 0 parts within 3 studs); roads: 15 step boxes
  7x10..9x14 exported (0 MOUTH FAILED), bake R05_ONLY = 1536 x14..19 z21..29 minus 19x29 (it stays the Road #25 build: Road Flyover #2's mid is
  in 20x29, so P6's build of 19x29 has no deck).

## LANES vs BUILT ROADS (19 Nov, LAG+BRIDGE agent): run after every road swap
- `roads05_lanes.py <tag> --install` now applies EVERY deck of a road, joins lanes only within 6 studs of height, and reads
  `roads05_<tag>/lane_heights.txt` (built surface). Make that file in Edit with `tools/yangon/LaneHeights.luau` (ClaudeTools.LaneHeights:
  `start`, `status`, `page`) on the installed lanes, re-run the lanes, sync, require-test all modules. Keep the FIRST run's rows when merging.
- Open: 32 deck lane points where the data deck is longer than the built deck (Pyay Road #6 deck end, Kabar Aye flyover south end, Road #25
  ramp, Lanmadaw (being rebuilt)); list in the vault note `City Legends/2026-11-19 Lag spikes and bridge traffic - fixed.md`.

## MAP BUG FIXES (19 Nov, MAP BUGS agent): owner's drive of P1-P3 after the J37 rebuild; state `mapbugs_progress.json`
- **(c) Invisible kerbs = pavement collision over bare asphalt.** `roads05_bake.collision` laid each P box (top = road + 0.5) along
  the road's whole length from the DATA; where the builder cut the pavement (junction mouths, driveways, side lanes beside decks,
  gores) the box stood over the visible asphalt. `tools/yangon/city/roads05_pbox_check.py` counted 4,203 of 11,905 P1-P3 P boxes
  with such points. Root fix: `roads05_pbox_clip.py` (called at the end of `collision()`, so every new bake is clipped): each P box
  is kept only over 1-stud x 1/3-width slices that a built pavement / kerb / median part covers (bridge parts only within +-1 of
  the box top; the bake's `drop_scraps` first). In the place: the same clip applied to the swapped rows (`mapbugs/pbox_*.txt`,
  "-" old row / "+" pieces; Studio swap code in `tools/yangon/MapBugScan.luau` `S.pboxSwap`): 5,625 P boxes -> 8,770 pieces,
  P boxes now 14,587 (saved v1471, Play-tested). Self-check `roads05_pbox_clip_test.py`. A future rebuild's bake does this itself.
  Other invisible collidables over R boxes: only landmark collision under landmark grounds (MC plaza, Sedona lawn, Bogyoke market,
  Strand, YCC, Sule, Holy Trinity, a pagoda base) = visible surfaces, kept. Roads.Collide had no boxes outside the new mesh cells.
- **(b) Kit props on the road (client data):** footprint test (poles r 0.45 at the base, trees r 0.8, walls / stalls / drains: the
  whole base, > 25% on an R box; name plates `splate` + T labels: ray 12 down): 396 records in 194 tiles removed (Data_P1S 120 incl.
  13 plates + 26 labels at University Ave x Kabar Aye etc., WCOL wall collision 79, compound walls ...). Repo copies patched by
  `tools/yangon/city/kit_tile_patch.py` (JSON `kit_place_P123/data_place_18nov.json`, old `*.before_19nov`).
- **(a) Terrain:** 39 R boxes had terrain over them (Shwedagon side 32.2-32.9k x 40.3-40.8k, 30.4k x 33.5k, MC 34.9k x 28.3k):
  FillBlock Air over each box. Near the decks (every 4-stud column within 60 of a D box with a road / pavement box within 24):
  3,791 voxels over (lowest road top + 4) or floating, in 1,748 columns (Kabar Aye flyover park 34.4k x 28.6k, P3 river bridge
  approach 31.5k x 45.6k): cleared above G + 3. No kit record or far tree stood on them.
- **(d) Kerb overlaps:** `roads05_kerb_cross.py <tag>` (kerb pieces crossing > 25 deg, >= 30% overlap, after drop_scraps) lists
  clusters; not fixed in the builder this pass (see vault note).

## REBUILD P3 deck feet + failed mouths (19 Nov, DISTRICT REBUILD agent 3): state `rebuild_progress.json` "P3_feet", "mouths"
- **Single-cell rebuild recipe (works, ~15 min a cell):** subset (`R05_GROW=1700 roads05_subset.py <net> <tag> <district>` or copy an
  existing subset's roads/paint/subset.json into `roads05_<tag>`) -> pack + POST a NEW Model -> `LoadAsset`, modules into YangonData,
  `require(YangonRoads:Clone()).load()`, delete the modules -> Studio `_G.RBXJob(label, box)` (stepCell into a folder in RoadsBuildRB,
  `RoadBake05.collect`, zstd+base64 slices of 98,000 padded to 99k, parts cleared) -> `_G.RBXZ(label, k)` one per call ->
  `roads05_grab.py <tag> <first file>` -> `roads05_bake.py <tag> collect <pages>` + `R05_ONLY=<cells> ... bake` -> POST each glb
  (`model/gltf-binary`) + `roads05_pack_collide.py <P> <tag>` rbxmx -> `_G.PREP(tag, glbIds, collideId)` (place + collide into
  ServerStorage folders) -> `_G.SWAPGO(tag, cells, ...)` (old Cell_ + boxes by box centre to `ServerStorage.RB_Old<tag>`). The helpers are
  `tools/yangon/RebuildCell.luau` (paste into execute_luau once per Studio session; they live in `_G`).
- **Built-surface deck-feet check:** `python tools/yangon/city/roads05_deckfeet_points.py > pts` -> `ClaudeTools.DeckFeetCheck(pts)`
  (repo `tools/yangon/DeckFeetCheck.luau`): rays onto Roads.Collide at each deck end + 8/16/32 studs in. The +1 over the data 8-32 in
  is the fixed builder's eased ramp (Hledan was driven: no bump). `roads05_deckfeet_check.py` is only a mirror of the old bug: in the
  place the two Khayaypin feet (19x27) were already flush.
- **Mouth fix (YangonRoads.buildMouth chain, 179,871 chars, checksum 1084283452):** a CROSSING mouth whose bigger road turns a corner
  on it (Lane #7606 turns 64 deg on Lane #1255) walked its edge back past the crossing and errored ("never meets"), so the arm's slab
  was skipped AND no mouth laid = a hole. Now it closes at the crossing sample like a shallow merge (nearest B point within MOUTH_SNAP).
  `roads05_mouthsim.py` does not simulate crossings (it reported 0 for both cells).
- **Road #25 "Road Flyover" (P3 19x29..21x29), cause found:** its valley foot (31522,45702) lies 4 studs from the Yangon-Dala
  Bridge Flyover centre line 30 studs above, so `Roads.alignJunctions` took the flyover as a junction and lifted the whole ramp
  ~20 studs (built D tops 42-44 vs data 22-31; nothing at the valley). Fixed in `tools/riviera/Roads.luau` (a bigger road > 8 studs
  above / below is a crossing; 56,123 / 1931436212, Studio synced). The cells are NOT rebuilt with the fix yet: steps in
  `rebuild_progress.json` "road25". "Road Flyover #2" foot (30112,44964): a P box +1.7 over the deck (check after that rebuild).
- **Lanes after a swap (coordinator rule):** LaneHeights -> merge into `roads05_L12347/lane_heights.txt` -> `roads05_lanes.py L12347
  --install` -> pack_sync + QuickSync -> require-test. Done after these swaps ("lanes_rerun"). Trap: a big `LH.page` result came back
  inline (not in a file): pad it or read it from the session transcript.
- **P6 and P8 offline steps are DONE** (re-clear, packs, roads data, P6 lanes L123467 built): ids in `rebuild_progress.json` "P6" / "P8"
  and `districts_assets.txt`. Studio steps not started (memory 14.4 GB at stop).

## REBUILD P4 (19 Nov, DISTRICT REBUILD agent 2): Hledan / Kamayut IN (district, J37 roads, lanes L12347, minimap, verge), Play-tested, saved v1566
State: `rebuild_progress.json` "P4". Same order as P7 (below); what differed:
1. **Re-clear:** `district_files.sh P4 --no-roads buildings` (21 min): 11,209 buildings (805 dropped / 3,843 clipped), shells 14,113, roofs 6,410;
   old files `_pre_rebuild_P4`. **4 place packs** (P4 is big) and the night glb `cells_1.glb` was 23 MB (> 20 MB upload cap): split by mesh
   with `tools/yangon/city/glb_split.py <glb> 2` into `cells_1_a/b.glb`; `M.kit(nil, a, b)` takes both.
2. **Swap range** 1536 x14..18 z11..21 (x18 = P1/P2 seam, clip P4+P1+P2). Step boxes: x 21504/24576/27648(1536 wide) x z 16896(1536 tall)
   + 3072 rows to 33792, labels 7..9 x 5..10 (18 boxes, ~50 min, 2.7 M parts). Edge cells with P5 (x14) and P6 (z21) hold P4 roads only:
   P5 / P6 rebuilds re-bake them whole. 9x9 log: MOUTH FAILED Lane #1255 on Lane #7606 (not fixed).
3. Bake already pavement-box clips (5,659 rows). 476 meshes / 50 glbs / 23,906 boxes; old 11 cells (x18) + 4,305 boxes to RB_OldP4.
4. **Lanes trap:** `roads05_lanes.py` wrote road names with `json.dumps` = JSON u-escapes; a Burmese name in P4 made
   `YangonLanes1to1_14` fail to load ("malformed escape sequence") and stopped the client's Main (no menu, no traffic). Fixed
   (`ensure_ascii=False`); **require-test every generated module in Studio before saving.**
5. **Deck feet in the air (owner ref):** `tools/riviera/Roads.luau` kept `finalEdges` (module-level) from the cell's ground build while
   the deck build's `alignJunctions` ran, so a deck that butts a bigger deck took a ground road's heights: Hledan Road Flyover feet
   built +1.4 / +3.9 over the ground road. Fixed (reset before alignJunctions, Roads 55,792 / 1214386504); check any subset with
   `tools/yangon/city/roads05_deckfeet_check.py <subset roads.json>`. P3 has the same fault (Khayaypin x2 cell 19x27, Lanmadaw deck ~24
   low cells 21x27 / 21x28): rebuild those cells with the fixed builder.
6. Minimap: FULL += P4 re-lays the whole detail grid (41 tiles): all re-uploaded as Image (`ids_P4_images.txt`).
7. Lock etiquette (coordinator): release `studio.lock` after every saved batch, wait ~10 min, retake (`until mkdir ...`).

## REBUILD P7 (19 Nov, DISTRICT REBUILD agent): Shwedagon / Maha Wizaya / People's Park / Bahan IN, Play-tested, saved v1479
State: `rebuild_progress.json` "P7". Order used (it works; copy it for P4, P6, P8):
1. **District re-clear vs J37:** `district_files.sh P7 --no-roads buildings` (buildings 3,573, 159 dropped / 905 clipped by roads; old files
   `build/city_1to1/_pre_rebuild_P7`) -> POST the 3 place packs + night cells as NEW Models (ids in `districts_assets.txt` "P7J").
2. **Move first, roads after** (stepCell writes the road beds over the district terrain): `DistrictPlace` (load, kit(nil, cells), terrain,
   green with `Green.Far` renamed Far_keep and merged back, shells, pagodas, cleanup). Delete `Shwedagon_Hill_TEMP`, `MahaWizayaPlate_TEMP`
   and the district's old pagodas first. **Trap:** Studio's `ClaudeTools.PagodaPlace` is the landmarks3d one; the rows tool DistrictPlace
   needs is now `ClaudeTools.PagodaPlaceRows` (rename it to PagodaPlace for the `pagodas()` call, then back).
3. **Seam cells rebuilt whole:** `R05_GROW=1700 roads05_subset.py <net> RB7 P7` (1,279 roads), then subset.json boxes = P7 + P1 + P3 so the
   1536 rows shared with P1 (z21) and P3 (z26) bake complete; step boxes: 3072 columns x9..11, rows z 32256..33792 / z11 / z12 /
   39936..41472 (labels <x>x10 .. <x>x13). Swap = every Cell_ and box (by centre) in 1536 x19..23 z21..26.
4. **Don't PATCH 133014134133489 for data:** another agent's script sync replaced it between my PATCH and LoadAsset. POST a new Model per pack.
5. **Slice grabbing (180 calls) and asset uploads went to helper subagents** (keeps the main context free).
6. After the swap: `roads05_pbox_clip.py RB7 <collide> <out>` (1,011 -> 970 P boxes; MAP BUGS rule), MapBugScan copy with AREAS = the
   district (80 R boxes with terrain over, near-deck strays), RoadVerge05 + trim per 3072 tile, KF on Data_P7G, wall records of the
   compact Data_P7 (expanded with KD.expand: 18 removed).
7. **Studio's YangonKitData was the old 14,306-char decoder** (no FORMAT=2): compact districts (P4-P12) show no building detail without
   git's 33,827 one: synced (69121963).
8. Lanes `roads05_lanesubset.py <net> L1237 P1 P2 P3 P7` -> `roads05_lanes.py L1237 --install` (797 lanes, 0 dead ends, 12 modules).
   **ChauffeurRoute.graph timed out with them** (no spawn): now yields on time (30 ms).
9. Minimap: FULL += P7, only the tiles over P7 re-uploaded, as **Image** (a Decal id fails: "Asset type does not match").
10. Play test: player attribute `TestDrive` = true is needed for TestThrottle; the car is held ~3.5 s after a TestTeleport.

## REBUILD progress 3 (18 Nov night, ROAD REBUILD agent 3): P3 SWAPPED, cleaned, Play-tested; verge P1-P3; kit data synced
State: `build/city_1to1/rebuild_progress.json` ("P3", "props_cleanup", "ycc_ramp", "verge", "kit_sync").
- **Export:** 13x13 / 13x14 / 13x15 slices pulled from `_G.RB3` (34 / 29 / 22 pages): all 15 P3 cells on disk. `roads05_grab.py` now
  reads several `@Z` slices per file, but a result over 100k is CUT (2 slices in one call lost the second): one slice per call.
- **Bake:** `roads05_bake.py RB3 collect roads05_RB3/pages` (1,548,970 parts) + `R05_ONLY=<1536 x19..27 z26..31> bake` (21 min):
  461 meshes, 44 glbs, 25,094 boxes (`roads05_RB3/bake_stats_P3.json`). Uploads: `roads05_RB3/upload_ids_P3.txt` (44 Models,
  group 33151111; ops in `upload_ops_P3.txt`); collide = `roads05_pack_collide.py P3 RB3` (now takes the build tag) ->
  `imports/sync/rebuild_P3_collide.rbxmx` -> asset 133014134133489 rev 215 (12 modules RColRB_P3_k).
- **Swap (version 1419):** old 47 Cell_ + 18,323 boxes (box centre in 1536 x19..27 z26..31) out, new 51 Cell_ (461 meshes) +
  25,094 boxes (RoadBox P/R/M/D/W) in, in one spawned task (~5 s). Trees: 140 Green.Far meshes (OKA/OKB_ot1) on new R boxes
  removed; props: `_G.KF(Data_P3G)` 857 tree records, `_G.KW(Data_P3)` 752 wall records, 0 left (version 1420).
- **Play test PASS** (store CityLegends_test -> v1, read back on the Server in Play): Bogyoke 449 studs through Sule Pagoda jn,
  Strand 440, Sule Pagoda #2, Sule ring tangents: gap 1.8-2.1 on R boxes; 3 YCC ramps up onto the plate; 4 junction lane-gap points
  driven (no drop; Sule Pagoda Road (36092, 43529) has a box hole under the car centre for one sample); 28/28 NPC moving; 53
  EntranceRamps; 7/7 y1_ fast-travel spots on R boxes; no script errors. Lane check P3: 460 of 34,826 points without a box (1.3%,
  was 6.6% on the old meshes). Test kit: client `TestEngine` + `TestCar` + `TestTeleport` (a client PivotTo is overwritten).
- **YCC ramp "dark thing":** the 1-stud triangles' undersides hung beside the plate wall: all 12 thickened to 5 downward (top
  unchanged, attribute OldThick = 1), version 1423. Old-road backup deleted, saved 1424.
- **Shots:** vault `City Legends/2026-11-18 rebuild P3 - <Sule roundabout | Bogyoke x Sule Pagoda | Strand Road> - <before|after>.jpg`
  (before = the old cells swapped back in for the shot only, then out again).
- **Verge (done, saved 1434):** `RoadVerge05` run + trim per 3072 tile over P3, P1, P2 (37 tiles, ~1.5 min each): 414k cells
  filled, 790k carved. Edge check (68,640 points 0.5 in from every P box edge): 123 still have terrain over the pavement (0.18%), mostly
  the builder's asphalt / rock road-bed terrain poking through junction meshes (worst +1.36 at (35682, 24.6, 45097), Sule ring west
  arm; 1536 cells 23x29, 20x29, 23x28), not grass. Next: carve terrain over R and P boxes at those junctions.
- **Kit data sync:** the place's Data_P1/P2/P3, P1G/P2G/P3G, P1S, P1P, P2P (all tiles, zstd+base64, 74 slices) written into
  `imports/sync/ygn1to1_p1|p2|p3/ygnkit_*.rbxmx`, `ygn1to1_green/green_p1|p2|p3.rbxmx`, `ygn1to1_street/ygnstreet_p1.rbxmx`,
  `places_P1|P2/ygnplaces_*.rbxmx` (old files kept as `*.before_18nov`; whole JSON in `build/city_1to1/kit_place_P123/`). Each file
  verified tile by tile against Studio's hashes. Data_P1 / P2 / P2G in the repo were stale before the filter (nearly every tile
  differed). A regenerate (buildings_1to1 / green_1to1 / street_1to1 / places_1to1) still reads the OLD roads: re-run KF / KW after.
- **Open:** terrain road bed through P3 junction meshes (above); the Sule Pagoda Road junction box hole; P4+ districts; CollisionFidelity on road meshes (Default, harmless).

## MC basement ramps (18 Nov, after P3): ramp mouths kept open by data; cells 22x17 + 22x18 re-swapped
- `build/city_1to1/ramp_mouths.json` -> `tools/yangon/city/roads05_ramps.py` (called by roads05_fix.py before its checks;
  standalone on a fixed net in place, backups `*_preramps.json`): drops Lane #4080 / #4081 (basement aisles), cuts roads
  on a ramp's footprint to their far end (Lane #4082), adds driveways kind `ramp`. The net roads.json is now md5 f1332665...
  (paint unchanged in content). YangonRoads.sideZone: kind `ramp` drops the pavement too (179,623 chars, checksum
  221012820; Studio ClaudeTools has it). roads05_bake.py `ramp_gaps` splits P collision boxes at a ramp mouth.
- Rebuild of only two 1536 cells: `roads05_jsubset.py` with a grid of points (`roads05_RBM`), one `stepCell` over the
  1536 x 3072 box (cells may be any box; pages labelled 22x17), `R05_ONLY=22x17,22x18` bake, swap by box centre cell.
- After any rebuild of those cells: run `ClaudeTools.MCRampAprons` (the slope from the J37 carriageway, ~1.4 under the
  site plane, to each ramp top) and clear the trenches (MCBasement.terrain + up to the coping: a road bed filled them).

## REBUILD progress 2 (18 Nov evening, ROAD REBUILD agent 2): P3 built, 12/15 cells exported; YCC ramps + P1/P2 props done
State: `build/city_1to1/rebuild_progress.json` ("P3", "props_cleanup", "ycc_ramp", "verge", "lane_gaps").
- **P3 data:** `roads05_subset.py P1_..._P12 RB3 P3` (clip = P3 box only: no P6-P8 roads in the game; 901 roads, 34 modules,
  asset rev 213, checksums `roads05_RB3/pack_checksums.txt`), loaded into `_G.RY`, modules deleted. Builder checksums as J37.
- **Build job `_G.RB3`** (Studio _G, lost on restart): per 3072 cell x9..13 z13..15 `stepCell` -> `RoadBake05.collect` ->
  zstd+base64 slices of 99,000 in `_G.RB3.slices[cell].sl`, parts cleared. `_G.RB3Z(cell, k)` returns slice k as
  `@Z<cell>_01_<k>_<n>@...@END@` padded to 99k (lands in a tool-results file). `roads05_grab.py` now takes `<tag> <first file>`.
  12 cells are on disk (`roads05_RB3/pages`, page counts match the build log); 13x13 / 13x14 / 13x15 were building when the
  agent stopped. Cells 10x14 (Sule) and 11x14 are the biggest (222k / 203k parts, ~3.5 min each).
- **Not done for P3:** bake, upload, swap, Play test, after shots, P3 props filter, verge run, lane-gap check (steps in the json).
- **Props on the moved roads (P1 + P2 done, in the place):** `_G.KF(folder, apply)` / `_G.KW(...)` (Studio): each record of a
  `ReplicatedStorage.YgnKit.Data_*` tile is ray-tested 3 up / 8 down against `Roads.Collide`; a hit on RoadBox "R" removes it.
  Removed: P1S 636, P1P 30, P2P 99, P1G 814, P2G 924, compound walls in Data_P1 918 / Data_P2 1,021 (incl. 563 invisible WCOL
  wall collisions standing on the new carriageways). P3 (Data_P3G, Data_P3) after its swap. Repo sources of those Data folders
  are now older than the place.
- **YCC car park:** 3 driveway ramps (12 WedgeParts, `Landmarks.YangonConventionCentre.DriveRamps`, 8.5% from road + 0.06 up to
  the plate top 54.82; two triangles each because the drives meet the plate's diagonal edge at an angle). Roads that run along /
  under the plate's edge (not drives) were left.
- **Lane gaps:** NPC traffic is kinematic (no raycast): NPC cars cannot drop at the 1.5% junction gaps. Player-car check open.
- **Memory:** Studio was at 18-19 GB during the build; nothing of this run left in ServerStorage / Workspace (RoadsBuildRB empty).
  Restart Studio after the P3 swap (undo history).

## REBUILD progress (18 Nov, ROAD REBUILD agent): P1 + P2 swapped and saved, P3 not started
State file: `build/city_1to1/rebuild_progress.json` (cells exported / baked / uploaded / swapped, Play tests). Vault note:
`City Legends/2026-11-18 Road rebuild P1 P2 (J37 into the game).md`.
- **Data:** `roads05_subset.py <net> RB12 P1 P2` (clip = P1 + P2 boxes, 1,783 roads) -> 50 `Roads05_*` modules (pack
  `imports/sync/rebuild_RB12_data.rbxmx`, asset rev 209; checksums in `roads05_RB12/pack_checksums.txt`), `Y.load()` once,
  then the modules were DELETED from the place (the loaded `_G.RY` kept building). Builder = J37 (checksums as above).
- **Build:** real `YangonRoads.stepCell` (terrain writes as the builder does) per 3072 cell into
  `Workspace.Yangon1to1.RoadsBuildRB`, `RoadBake05.collect`, pages out as zstd + base64 slices (`@Z<cell>_<first>_<k>_<n>@`,
  EncodingService) -> `tools/yangon/city/roads05_grab.py` (only files newer than this run's first page!) ->
  `roads05_RB12/pages/` as normal `@Q` pages. P1 = 3072 cells x9-11 z8-10 (985,207 parts); P2 = x9-12 z5-7 + 12x8.
- **Bake:** `roads05_bake.py RB12 collect pages` then `R05_ONLY=<swap cells> ... bake`. P1 swap cells = 1536 cells x18-23
  z16-21 (276 meshes, 26 glbs, 14,479 boxes); P2 = x18-24 z10-15 + 24x16 (304 meshes, 26 glbs, 11,516 boxes). A district's
  edge does not fall on a 1536 cell: the cells are swapped whole, with the neighbour strip built from the same subset.
- **Swap:** glbs -> Open Cloud Models (ids `roads05_RB12/upload_ids_P1.json`, `_P2.json`), collide pages as
  `RColRB_<P>_k` modules (asset 133014134133489 rev 210 / 212) -> `YangonRoadMeshes.place` + `RoadBake05.collide` into
  ServerStorage, then old cells + their boxes (by box centre cell) to `ServerStorage.RB_Old<P>`, new in, save, Play test,
  backup deleted, save. Studio's `YangonRoadMeshes.LOOK` had no `LZ`: added in Studio (zebras).
- **Trees:** 147 (P1) + 99 (P2) far-tree / bank-tree parts stood on the new carriageways: removed (ray to `RoadBox` R).
- **Lanes:** `roads05_lanesubset.py <net> L123 P1 P2 P3` (roads cut to the districts) -> `roads05_lanes.py L123 --install`:
  630 lanes, 1,447 links, 0 dead ends, Studio Shared synced (checksums equal). **P3 uses them on its OLD meshes: 6.6% of P3
  lane points miss the old boxes** (P1 1.4%, P2 1.6% on the new ones): rebuild P3 next.
- **Play tests (store CityLegends_test, put back, checked on the Server):** P1 and P2 PASS: cars on the new boxes (gap
  1.3-2.0, Hledan deck, Pyay Road #7, YCC arrive spot), 28/28 NPC cars moving over road boxes, 53 EntranceRamps, 7/7 y1_
  fast-travel spots on ground, no script errors.
- **Open:** P3 (15 cells x9-13 z13-15; subset with P3 + neighbours); the client kit data (street props `Data_P*S`, kit trees
  `Data_P*G`, walls) was made from the OLD road layout and can stand on the moved roads: regenerate from the J37 roads;
  CollisionFidelity Box does not stick on road meshes (all 892 Default, harmless: no collision / query); the YCC lot
  driveways now meet the raised YCC car-park plate at a step (YCC after shot); RoadVerge05 not re-run (grass edges).

## J37 -- built-surface totals, T.qa, J36 -> J37, 17 spots: 16 / 161 / 36 / 77 / 0 (pave_gap 95) -> 14 / 84 / 36 / 77 / 0 (pave_gap 94)
Note + table + shot: vault `City Legends/2026-11-18 roads05 J37 studio check.md`. No data change. Nothing rose at any spot.
- **Kept (`YangonRoads.kerbSeal`, after scrub in stepCell and step5):** every Pavement part's top triangle / face is read back
  (WedgePart: the side face whose normal points up; flat Part: its top), each edge walked every 0.4: lower asphalt (Road or Paint,
  0.15+ under) 0.2 outside -> a kerb along the run (0.9 out, less where anything starts first; back over the pavement to an own
  kerb within 1.5); nothing 0.2 outside but lower asphalt within 2 -> the slot is filled (kerb edge: kerb runs on; pavement edge:
  pavement runs on + a kerb). Kerb top = max(pavement + 0.1, asphalt + CURB_UP + 0.1). Runs re-probed just before laying.
- **Tried + changed:** v1 without the asphalt floor: buried 0 -> 3 (pyay_univ Lane #588, univ_kabaraye); v1 had no slot fill.
- **Not reached (in order):** road edge next to nothing (seal from Road edges like endKerbs, but only where the road has a walk);
  deck foot vs pavement (0.13 apart, under the 0.15 threshold); pave_step 77 (idea: a weld pass, smaller road's pavement + kerb
  vertices moved by a field dh * (1 - d / 8) from each contact with a bigger road's pavement, clamped so the pavement stays 0.2+
  over its own asphalt; same-road steps Lane #588 / Maha Bandula #2 / Lane #4239 need their own look); pave_gap fill rule; road_step
  (pyay_univ Hledan #3 / Pyay #9 joint, univ_kabaraye Lane #1256 / #1257); box_hole 14; arrow_missing 10 (paint QA: chain dashes).
- **Kit (Studio _G, lost on restart):** as J36 (`_G.P`, `_G.RL`, `_G.GO`, `_G.ST`, `_G.FX`); the pack must be installed first
  (`T.clean` removes the data modules: LoadAsset + `T.install` again).

# roads05 handover (18 Nov 2026, thirty-second pass: J36, BUILDER agent; YangonRoads.scrub kerb lifts + Studio 17 spots)

## J36 -- built-surface totals, T.qa (QA's kerbBetween check, asset rev 206), J35 -> J36, 17 spots: 16 / 161 / 36 / 77 / 9 (pave_gap 95) -> 16 / 161 / 36 / 77 / 0 (pave_gap 95)
Note + table + shot: vault `City Legends/2026-11-18 roads05 J36 studio check.md`. No data change (roads c34a1111, paint b6c2ba15).
Studio: main "City Legends", ClaudeTools.YangonRoads 661359068 (173,337 chars, ~26.6k left under 200k) = repo; test asset re-packed with it
after the commit. Scratch cleaned, saved as version 1377, lock released.
- **Kept (scrub, top):** a kerb Part a deck's Road lies over, < 0.35 under its top, is raised to deck + 0.35 (EHRC Road #3's deck-side kerb
  under the Bridge Flyover foot: double_junction buried 3 -> 0).
- **Kept (scrub, end):** a kerb whose OWN road's asphalt (probes 0.5 / 0.85 / 1.2 out, 8 directions) lies within 0.33 under its top is
  raised to that + 0.33; the same probe runs from each stray patch (nose slivers hide the patch from the kerb's probe). slip_triangle
  Lane #15 3, pyay_univ Lane #588 2, kunchan Lane #3414 nose 1 -> 0.
- **Kept (scrub, stray patch):** a patch never rises (`math.max(0, ...)`): one went 1.7 UP onto earlier patches (spike at (36354.5, 42408)).
- **Tried + reverted:** patch at the lowest asphalt round it (univ road_step +1). Paint QA dash projection along the road heading / dash
  axis for the new arrow_missing (Banyar Dala #3 (39994, 32900): paint has 2 arrows for 2 lanes, QA splits one drifting dash line into
  two): 10 -> 16 / 17. Next: chain dashes into lane lines before clustering (paint QA, `roads05_paint_qa.py` ~line 212).
- **Not reached (in order):** pave_step 77 (QA: 40% two roads' pavements back to back 0.2-0.7 apart, 30% 0.2 steps inside one road /
  island), road_step 36, box_hole 16, kerb_gap 161 (QA audit patterns, `City Legends/2026-11-18 roads05 fault audit.md`), pave_gap fill
  rule, Road #18 square end, arrow_missing 10.
- **Kit (Studio _G, lost on restart):** `_G.P(mod, find, repl)` (unique plain replace on ClaudeTools[mod], returns T.sum), `_G.RL()`
  (no-terrain copy + load + DECK_TOUCH into _G.RT.Y), `_G.GO(names)` / `_G.ST()` (run + qa + hash, faults kept in `_G.F[name]`),
  `_G.FX(spot, kind)` (fault rows with both cells). A full 17-spot run takes ~12 min.

# roads05 handover (18 Nov 2026, thirty-first pass: J35, BUILDER agent; YangonRoads split + roads05_fix / chain + Studio 17 spots)

## J35 -- built-surface totals, T.qa, J34 (rev 204) -> J35 (rev 205), 17 spots: 18 / 177 / 37 / 77 / 11 (pave_gap 97) -> 16 / 177 / 36 / 77 / 9 (pave_gap 95)
Note + table + shot: vault `City Legends/2026-11-18 roads05 J35 studio check.md`. Only double_junction moved (3/24/1/0/5/18 -> 1/24/0/0/3/16).
Studio: main "City Legends", rev 205 = J35 data (roads c34a1111, paint b6c2ba15) + split builder. Scratch cleaned, saved as version 1358, lock released.
- **Kept (split):** `tools/yangon/YangonRoadsChecks.luau` = the old checks section (checkBumps .. stepCell). YangonRoads (169,545 chars, sum
  348673078) ends with `require(SS.ClaudeTools.YangonRoadsChecks:Clone())(M, { file locals })`. Runner `T.install` moves it to ClaudeTools,
  `roads05_studiotest.py` + `pack_tools.py` ship it. Main place ClaudeTools has both now. Byte-identical on roundabout4 / univ_kabaraye / deck_run.
  ~30k chars free. Next split candidate if needed: buildIslands (2215-2561) or buildCorners.
- **Kept (roads05_fix.deck_foot_ends):** an OSM "(Bridge)" road's end at ground under ANOTHER deck is cut back to that deck's footprint edge
  (East Horse Race Course Road (Bridge): 5 samples under the Banyar Dala Road deck, on Road #18). The start-cut now shifts the road's own deck
  (`_shift_idx`; before only `cut` moved). Road #18's start: repair "square end under the deck" (was "run on 32" into the Bridge).
- **Kept (roads05_chain):** TURN_SHARP 100 / NEAR_END 15: no join through a turn sharper than 100 deg when another road's end lies within 15
  of the node (5 joins skipped). Dhobi Street 3 #2's U-turn split -> Lane #2914; Lane #544 starts on it. QA mouth_short real 2 -> 0.
- Pipeline J35a (fix -> mouthsim -> paint -> QA -> paint QA): mouthsim 0 failed of 11570; paint QA arrow_missing 9 -> 10, edge 178; QA = J34 except mouth_short real 0, dead_end 4451,
  signals 243. Backups `roads_J34.json` / `paint_J34.json`.
- **Tried + reverted:** Pazundaung Y round corner (Bogyoke Aung San Road #2 ~2 mouth on Upper Pazundaung Road #3 bigI 1): lost at findCorners
  noCorner (`if not px` ~line 1388; J34's "not noCorner" was wrong; found by logging every `continue` in findCorners in a Studio copy).
  The kerb window stops at Upper #3's sample 1; the kerb runs on along Lower Pazundaung (continuation). Extending the window along
  `contsOf(B)` built both corners (r 30) but pazundaung_y kg 3 -> 29 (Y nose 13 + Lake Kan x U Shwe Gwun 14, though no other corner changed);
  plain corner size: 25. Next: find why kerbs at Lake Kan (200 studs away) break when this mouth gets corners (sideZone / scrub of
  Bogyoke #2 ~2 past P?).
- **Buried left (double_junction 3):** Lane #3308's road 0.8 over its own / Banyar Dala #3's kerb (39984, 32911; also in cornerInRoadList);
  Bridge flyover foot vs East Horse Race Course Road #3's kerb (39996, 32701).
- **Not reached:** bahan NE island strip, Y east nose, kerb_gap (U Wisara #5, Gyophyu Flyover, Lane #1256 notch, Sule Pagoda Rd curve cracks,
  Maha Bandula #2 / Lane #3357 island), buried rest, pave_gap fill rule (< 2 studs = one surface), pyay_univ road steps, univ / kunchan.
- **Kit (Studio _G, lost on restart):** `_G.P(find, repl)` plain replace on ClaudeTools.YangonRoads.Source (asserts one match, returns T.sum),
  `_G.RL()` = no-terrain copy + Y.load + DECK_TOUCH into _G.RT.Y. The J34 kit (`_G.FL`, `_G.GN` ...) still works.

# roads05 handover (18 Nov 2026, thirtieth pass: J34, BUILDER agent; YangonRoads + roads05_fix + Studio 17 spots)

## J34 -- built-surface totals, T.qa, J33 real-data baseline (rev 203) -> J34 (rev 204), 17 spots: 18 / 191 / 37 / 77 / 11 (pave_gap 104) -> 18 / 177 / 37 / 77 / 11 (pave_gap 97)
Note + table + shot: vault `City Legends/2026-11-18 roads05 J34 studio check.md`. J33's reported 17 / 193 / 107 used injected data; the real J33
data (991fe6e6) measures 18 / 191 / 104 (pazundaung_y 1 / 3 / 0 / 0 / 0 / 3). Studio: main "City Legends", rev 204 = J34 data + repo builder
(ClaudeTools.YangonRoads 1649579739, 196,364 chars: ~3.6k left under 200k; a helper module is next if more goes in). Scratch cleaned,
saved as version 1347, lock released. Data backups `roads_J33.json` / `paint_J33.json`.
- **Kept (YangonRoads.inCorner `armNear`):** a ring corner's zone stops at its arm's centre line (the ring branch skipped inCornerPoly, so the
  wedge alone reached across narrow Lane #3357 and took its far kerb + pavement). roundabout4 kg 38 -> 25, pave_gap 21 -> 14 (Lane #3357, #115).
- **Kept (YangonRoads.scrub `mOn`):** a non-ring mouth road's data past its mouth no longer scrubs its host's kerb / pavement (Kabar Aye #6's
  east kerb by Lane #1256: univ_kabaraye kg 31 -> 29). With ring mouths included roundabout4 went 25 -> 30: ring mouths keep the old rule.
  deck_run kg 9 -> 10 = one U Wisara #2 / #3 cell moved half a stud.
- **Kept (roads05_fix, pipeline J34a):** `edge_ends` (ends within 3 of the district outline are map-edge ends: Insein Road + 4), mouth run-on
  also tests the end's centre (Lane #5161), `osm_joins2` after fork_trim (Lane #35, Tha Yat Taw 4 Street cut back). roads.json ca2aa236,
  paint.json 1d4e6c10, mouthsim 0 failed of 11571, QA mouth_short real 4 -> 2, the rest + paint QA = J33. Version line written.
- **Tried + reverted:** Pazundaung Y west corner: continuations of the bigger road not counted as "a third road" under P: no change (the
  corner is lost elsewhere: not overlapDropped, not noCorner; next: log every `continue` in findCorners for that mouth, i0 79 on Upper #3 bigI 1).
- **Bridge / Road #18 (OSM decided, not coded):** OSM: the Bridge (463191695) is layer 1, one-way, leaving the Banyar Dala bridge (= our Bo Min
  Gaung Street deck, 60.6 high); Road #18 (478882258 -> 617123000 -> 685773003 ...) is the real GROUND road, one-way south. At the crossing the
  ground carriageway is Road #18. Our Bridge samples 0-19 sit at ground (30.0) under the deck between Banyar Dala #2 / #3 and flare to half 35
  (the Thamein Ba Yan junction): road on road with Road #18 for ~70 studs. A ramp off the deck would be 19% (60.6 -> 29.8 in ~160 studs).
  Proposal: drop the Bridge's samples 0..~9 (inside the flare / under the deck) and start it as a continuation or mouth off the junction's
  ground asphalt, with Road #18 kept whole; check rank order (a road that ends on another must be the smaller one).
- **Lane #544 (mouth_short 8.5):** roads05_chain joins Dhobi Street 3 #2 through a ~140 deg U-turn node (TURN_ALONE 150; the OSM node is a
  4-way with Lane #544's link 12.6 away, outside NODE 8), so the link never exists. Fix in chain: no join where another road's end lies
  within ~15 of the node, then re-run the fix.
- **Seen, not fixed:** univ_kabaraye Lane #1256 merge-nose notch (34433-34436, 28990); roundabout4 Sule Pagoda Road kerb cracks on the curve
  (44927, 44912, 44895-44899: pavement shows through kerb-piece joins); Maha Bandula #2 / Lane #3357 / 32nd St island mess (35795-35823,
  45072-45099); univ_kabaraye side lanes #1247 / #1248 / #1257 onto Kabar Aye #5 / #6.
- **Not reached:** bahan NE island strip, Y east nose, deck_run U Wisara #5, kunchan Gyophyu Flyover, buried 11, pave_gap fill rule, pyay_univ
  road steps, univ / kunchan regressions.
- **Kit (Studio _G, lost on restart):** `_G.PATCH(find, repl)`, `_G.RELOAD()`, `_G.ONE(names)` (= T.runAll), `_G.SHOW()` (vs `_G.BASE`),
  `_G.GN(x0, z0, x1, z1, step)` ray map (upper = road, lower = pavement, # kerb, + other), `_G.FL(spot, kind, box)` faults with both cells.
  Calls over ~3 s of wait get cut ("Target is not reachable"): poll with task.wait(2-3).

# roads05 handover (18 Nov 2026, twenty-ninth pass: J33, BUILDER agent; YangonRoads + roads05_fix + Studio 17 spots)

## J33 -- built-surface totals, T.qa (runner rev 202), J32 -> J33 (17 spots): 19 / 214 / 37 / 77 / 11 (pave_gap 105) -> 17 / 193 / 37 / 77 / 11 (pave_gap 107)
Note + table + 2 shots: vault `City Legends/2026-11-18 roads05 J33 studio check.md`. Studio: main "City Legends", rev 202 installed with the repo
builder; ClaudeTools.YangonRoads = repo 419443297 (195,605 chars), Roads unchanged. The DATA changes were tested by replacing records after
`Y.load()` (8 island records; Lower Pazundaung s1-5 and Upper Pazundaung #3 s1932-1936 from the new butt_match). Scratch cleaned, saved, lock released.
- **bahan_ring Kan Yeiktha island (kerb_gap 37 -> 26):** roads05_fix `islands` took the hole from `roads05_qa.quads()`, which DROPS a bow-tie
  quad; Roads.build lays that bend (its inner edge point waits, Roads.luau ~641). New `built_quads()` copies the wait; a hole pinched to a
  < 1 stud neck is split (open 0.5 mitre). Whole net: 79 island records change, 316 -> 318.
- **pazundaung_y gore (kerb_gap 15 -> 5, box_hole 2 -> 0):** buildMouth's B (bigger road's edge) stopped at Upper Pazundaung #3's end; it now
  runs on along a continuation's same-side edge (`contsOf`; buildRoads keeps those edges too). `butt_match`'s median check is now within
  MORPH + 8 studs (was s[:8] = 65 studs: Lower Pazundaung's median starts at 57).
- **Left (seen):** bahan NE island strip by Kan Yeiktha Road's s1 cap (pave_gap +1); pazundaung_y west corner Bogyoke x Upper (no round corner)
  and the east nose kerb ends (41038-41042, 43411-43416).
- **Bridge vs Road #18 (looked, not coded):** the Bridge flares from half 24.5 to 31.7 over its first 6 samples and Road #18 (one-way, half 10.5)
  starts inside that flare and crosses it at z ~32850: road on road. A join must first decide which carriageway is real there (OSM).
- **Not reached:** remaining kerb_gap clusters (roundabout4 Lane #3357 / #115, univ_kabaraye Lane #1256, deck_run U Wisara #5, kunchan Gyophyu
  Flyover), buried 11, pave_gap fill rule, pyay_univ road steps, univ / kunchan regressions.
- **Pipeline (`sh roads05_pipeline.sh J33 skip`):** roads.json md5 991fe6e6 (backup roads_J32.json = J29 data), paint.json 0e0fcb1c (backup
  paint_J32.json), mouthsim 0 failed of 11570, QA + paint QA = J30. Only Lower Pazundaung's samples and the island records changed. The real
  taper of Lower Pazundaung is gentler than the one injected in Studio (width_taper smooths it over ~55 studs: 31.5, 30.3, 29.0 ... 22.9), and
  the injected Upper Pazundaung #3 s1932-1936 change is NOT in the data (its end there is unchanged). **First step next pass:** re-pack the test
  asset with this data (`roads05_studiotest.py` -> PATCH 133014134133489) and re-measure the 17 spots as the J33 baseline.
- **Kit (Studio _G, lost on restart):** `_G.ONE(names)` build + qa + copy faults, `_G.SHOW()`, `_G.GN(spot, x0, z0, x1, z1, step)` ray map by
  road/part name, `_G.PATCH(find, repl)`, `_G.RELOAD` (+ `_G.ISLDIFF` / `_G.SPATCH` data overrides after load).

# roads05 handover (18 Nov 2026, twenty-eighth pass: J32, BUILDER agent; YangonRoads only + Studio 17 spots)

## J32 -- built-surface totals, T.qa (runner rev 202), J31 -> J32 (17 spots): 19 / 253 / 37 / 77 / 11 (pave_gap 105) -> 19 / 214 / 37 / 77 / 11 (pave_gap 105)
Note + table + 2 shots: vault `City Legends/2026-11-18 roads05 J32 studio check.md`. Studio: main "City Legends", rev 202 installed with the repo
builder swapped into the pack before `T.install`; patches by find / replace: ClaudeTools.YangonRoads 1688280175 (= repo, 194,095 chars), Roads
1407280218 (unchanged). Baseline re-measured = J31 exactly. Scratch cleaned, saved as version 1327. Commit 2787ab27.
- **What the double_junction gore faults really were (ray map + the piece's triangle corners):** NOT the straight pavement (its sideZone there
  already said drop). They were buildCorners' extras at each lane's corner onto Banyar Dala Road #2: the J20 TAPER (short arc keeps the wider
  7.5 walk, the lane's 3-4 walk tapered back over 20 studs, laid with no zone) and the J17 CHIP (theta 32-33, r 0.5-3).
- **Kept:** (1) no chip when theta <= 60 deg (a gore nose; slip_triangle kg 25 -> 15 alone); (2) the taper is cut by `onOther(own, x, z)` (another
  road's carriageway + kerb, not cut) with `Roads.clipPieces` (double_junction kg 35 -> 24, slip_triangle 15 -> 10). Full run: deck_run 10 -> 9,
  pyay_univ 17 -> 13, roundabout4 40 -> 38, univ_kabaraye 37 -> 31; nothing went up.
- **Seen, not fixed:** bahan_ring Kan Yeiktha island (35407-35420, 38138-38153): the island fill has a 2-4 stud spike south into the asphalt and
  no kerb on its road sides (data islands outline or buildIslands' ray kerb test); pazundaung_y (40981-40990, 43397-43412): a gore between
  Bogyoke Aung San Road #2 ~2 / Upper Pazundaung #3 / Lower Pazundaung with nothing built (road next to empty ground).
- **Not reached (in order):** those two; other kerb_gap clusters by close-up (roundabout4 Lane #3357 / Maha Bandula #2 and Lane #115,
  univ_kabaraye Lane #1256, deck_run U Wisara #5, kunchan Gyophyu Flyover / Kun Chan #4); buried 11; Bridge start join to Road #18
  (roads05_fix + builder road-end join; Road #18 starts at (39975.75, 32865.79), 14.9 east of the Bridge start, both running SW: a parallel
  pair, so the fix's backward ray never meets it); pave_gap 105 fill; pyay_univ road_step; univ / kunchan regressions.
- **Kit (in Studio _G, lost on restart):** `_G.PATCH(find, repl)` (unique find/replace on ClaudeTools.YangonRoads, prints length + checksum),
  `_G.RELOAD2(after)`, `_G.GO(names)`, `_G.SHOW()` (base -> now per spot), `_G.GRID(spot, x0, z0, x1, z1, step, {folder = upper})` ray map.
  To install rev 202 with the repo builder: LoadAsset, set `YangonToolsIn.YangonRoads.Source` to the current one, then `T.install(m)`.

# roads05 handover (18 Nov 2026, twenty-seventh pass: J31, BUILDER agent; YangonRoads only + Studio 17 spots; stopped: context)

## J31 -- built-surface totals, T.qa (QA's J30 open-ground rule, runner re-packed = asset rev 202), J30 -> J31 (17 spots): 20 / 253 / 37 / 76 / 11 (pave_gap 105) -> 19 / 253 / 37 / 77 / 11 (pave_gap 105)
Note + table: vault `City Legends/2026-11-18 roads05 J31 studio check.md`. Studio: main "City Legends", pack rev 202 (J29 data + J30 builder +
QA's runner), builder by text patch: ClaudeTools.YangonRoads 1234869083 (= repo, 193,294 chars), Roads 1407280218 (unchanged). Fixed order, fresh load.
- **Baseline on rev 202 (before any change):** 20 / 253 / 37 / 76 / 11, pave_gap 105 (= QA's census refresh; part hashes = J30's where checked, e.g. roundabout4 290473333).
- **Kept (sideZone, bigger-road branch):** in a bigger road's kerb band my KERB stays where that road's kerb is not built (its kerb cut by my
  carriageway: one recursive `sideZone(o, foot + oh + KERB_W/2, "Kerb")`, depth bounded by rank). pyay_univ 2/18 -> 1/17 (bh / kg);
  univ_kabaraye kerb_gap +1 / pave_step +1 at the known three-pavement island (34396, 28831). Aimed at the merging links Lane #7108 into
  Lane #5482 (double_junction (39896-39908, 32865-32892), 12 cells): NO change there.
- **Tried + reverted:** the same rule for a corner owner's kerb band (ownedBy branch): no change at double_junction / slip_triangle.
- **What the double_junction "corner" cells really are (close-up):** the two links MERGE into one end point; past the gore's kerb nose,
  pavement wedges of both roads run on 2-10 studs over the other's asphalt with no kerb (each road's pavement next to the other's road,
  both directions). Fix belongs in the gore nose: a pavement piece must end where its own kerb ends (the nose), not at the sideZone line.
- **Not reached (in order for the next pass):** (1) gore-nose pavement past the kerb nose (above; also the census "junction corner" cells at
  slip_triangle Lane #17 / #15 / #16 with r 1.9-2.0 corners: look at one close-up first); (2) buried: Bridge Flyover foot over East Horse Race
  Course Road #3's kerb (39995-39997, 32698-32702), double_junction Lane #3308 x Banyar Dala #3 (39984, 32911), slip_triangle Lane #15, pyay_univ
  Lane #588 (27036, 27670; kerb under its own road), Kun Chan Lane #3414 nose; (3) Bridge start (roads05_fix.py): the start (39962.8, 32873.2) lies
  between Banyar Dala Road #2 (west, its edge ~1 stud short of the Bridge's west edge) and #3 (east, covers the east edge); the fix's host
  search wants ONE bigger road within 12 of the centre and finds none (Bo Min Gaung Street samples 601-699 cut). A union host (both side
  lanes) would run it on ~15 studs north, but YangonRoads.buildMouth needs one host too: decide the join (or make Road #18 / one side lane the
  host) before coding it; (4) pave_gap 105 merge rule (walk is per road side in the data, so "merge pavements under 2 apart" has to be a
  builder fill); (5) Hledan #3 under Insein / Pyay: Roads.luau already lowers the inner eighths PIN_UNDER in a junction; the pyay_univ
  road_step cells left are Hledan #3 / Pyay #9's continuation joint (0.2, (27036, 27888)) and Lane #588; (6) kunchan / univ regressions not traced.
- **Debug kit (scratchpad, not committed):** `mkpatch.py` (CR-stripped difflib hunks -> find / replace Luau on ClaudeTools.<name>.Source, prints
  the repo checksum), `_G.RELOAD(after)` (fresh no-terrain copy + Y.load + DECK_TOUCH, then `after`). `T.faults` is overwritten per run: copy it.

# roads05 handover (18 Nov 2026, twenty-sixth pass: J30, BUILDER agent; YangonRoads only + Studio 17 spots)

## J30 -- built-surface totals, T.qa, J29 -> J30 (17 spots): 20 / 256 / 36 / 76 / 10 -> 20 / 253 / 37 / 76 / 11 (pave_gap 231 -> 188)
Note + table + shot: vault `City Legends/2026-11-18 roads05 J30 studio check.md`. Studio: main "City Legends", pack = rev 201 (J29 data, unchanged),
builder by text patch: ClaudeTools.YangonRoads 2122460250 / Roads 1407280218 (= repo), scratch cleaned, version 1304, lock released.
Fixed run order (alphabetical), fresh `Y.load()` first. No data change: the pipeline re-run is a check only.
- **pave_gap root (sideZone):** `onBuilt(o, k, x, z)` = is the point on o's BUILT surface (Roads.debugEdges edge points + o's walk on that
  side, the same quads Roads lays). Used for my PAVEMENT against a bigger road and against a corner's owner road (the owner zone ran past the
  owner's pavement: Lane #3186 x Sule 0.5 slot). nil (old polyDist reach) near o's ends (k < 4 or > n - 3: the round cap covers a
  continuation joint; without it deck_run kerb_gap 10 -> 13 at U Wisara #2 / #5) and on o's cut stretches (decks, ring).
- **Corner zone:** `inCorner` = wedge (0 .. rout) + `pastInner` (the corner pavement's inner chords, buildCorners' own bands), not rin =
  r - w - 0.3 (a 0.3 slot to the next pavement). roundabout4 pave_gap 49 -> 27 for both.
- **State leak (QA):** bisected by reloading one module before bahan_ring: fresh YangonRoads + load = equal; fresh Roads copy only = equal.
  The leak is in the Roads module copy (not found inside it: maxDh / maxW / finalEdges / debugEdges are all reset per build). `stepCell` now
  takes `M.Roads = require(ClaudeTools.Roads:Clone())` and `M.useRing(nil)` per cell; `buildMouth` uses `m.ringR` for a ring outline.
- **Studio 200k limit:** Source over 200,000 chars cannot be set; YangonRoads was 199,8xx. `qaBuilt` removed (T.qa replaced it): 192,796.
- **QA (census refresh, bc4cc89d):** same totals and parts twice; new T.qa open-ground rule: pave_gap 188 -> 105 (re-pack the runner). Pipeline = J29 (no data change).
- **Next (in order):** (1) pave_gap 188: mostly the narrow ends of open ground between two pavements (block interiors, islands), not
  two-road slots: needs a QA + builder rule ("ground under X between pavements is paved"); (2) kerb_gap 253 (not reached; seen: Lane #3357
  south kerb missing by its ring corner, roundabout4 (35812-35830, 45048-45063)); (3) buried 11 + the Bridge start: East Horse Race Course
  Road (Bridge) starts under the Banyar Dala (bridge) Flyover where Bo Min Gaung Street samples 601-699 are cut (its host is gone, so the
  fix's run-on never sees it): join it to Banyar Dala #2 / #3 or Road #18 in roads05_fix; double_junction deck foot over East Horse Race
  Course Road #3's kerb; (4) Hledan #3 under Insein / Pyay (lower 0.06 idea not tried); (5) kunchan Lane #3414 / Kun Chan #3 nose (36355,
  42408) road_step +1 / buried +1 this pass; (6) the Roads.luau leak itself (which upvalue).

# roads05 handover (18 Nov 2026, twenty-fifth pass: J29, BUILDER agent; YangonRoads + roads05.py + roads05_fix.py + Studio 17 spots)

## J29 -- built-surface totals, QA's final T.qa, J28 -> J29 (17 spots): 26 / 308 / 36 / 99 / 7 -> 20 / 256 / 36 / 76 / 10 (pave_gap 233 -> 231)
Note + table + shot: vault `City Legends/2026-11-18 roads05 J29 studio check.md`. Census (QA): `City Legends/2026-11-18 roads05 fault census.md`.
Studio: main "City Legends", test re-packed (asset 133014134133489 revision 201 = J29 data + builder + QA's final runner), ClaudeTools.YangonRoads
2108652449 / Roads 1407280218 (= repo), scratch cleaned, saved version 1294, lock released. Measure with `T.runAll(names)` in the runner's fixed order (state leak below).
- **DECK_TOUCH (YangonRoads.buildDecks):** a test spot built a deck only when its middle sample was in the box (double_junction's East Horse
  Race Course Road (Bridge) Flyover never built: 45 "deck foot" kerb gaps were the test). Flag on in T.install only; the bake keeps one owner cell.
- **Side-lane gore (roads05.py):** gore = deck half + side width + SIDE_INNER_WALK (the sides' deck-side walk + kerb lay under the deck foot).
- **deck_foot_ends (roads05_fix.py, after deck_feet):** a road end at grade inside a deck footprint (half + 0.5, flat ends) is cut back to its
  edge (6 roads, Lane #3309 at double_junction). Continuation ends skipped.
- **Island kerbs (buildIslands):** every 0.5 of each outline side tested for a kerb, kerb laid on open runs only (bahan_ring kerb_gap 50 -> 40 with the rest).
- **Tried + reverted:** (a) Roads.luau `underBig`: strips of a smaller road wholly under a bigger road's face not laid -> holes where Pyay (Prome)
  ENDS (bigSurface's reach runs past end lines): pyay_univ kerb_gap 21 -> 42. Needs a built-face or end-line test. (b) inner pins not raised within
  2.5 of an unpinned edge: no effect, slip_triangle Lane #15's R edge is pinned (19.13-19.23) and its kerb / pavement stand 0.1 over it.
- **Pipeline (`sh roads05_pipeline.sh J29`):** roads.json md5 95dfb789, paint.json 84b94130; J28 backups roads_J28.json / paint_J28.json /
  roads_unfixed_J28.json. mouthsim 0 failed of 11,570. QA: mouth_short real 3 -> 4 (East Horse Race Course Road (Bridge) start (39963, 32873)
  5.3 short: the wider gore reaches it), mouth_over 1 -> 0; paint QA unchanged. Version line written.
- **Next (in order):** (1) buried 10 (3 new = double_junction (39995-39997, 32698-32702): East Horse Race Course Road #3's deck-side kerb 30.55 under the Bridge Flyover's foot surface 30.47-30.56, the deck foot still laps the side lane; double_junction Banyar Dala #3 x Lane #3308 5 at (39984, 32907): Lane #3308 runs under the Banyar Dala deck
  beside Banyar Dala #3, a 1-stud road strip between two kerbs; slip_triangle Lane #15 3; pyay_univ Lane #588 2); (2) the Bridge start mouth_short;
  (3) census patterns 1-3 (junction corners, mouth ends, roundabout gores; e.g. the Pazundaung Y wedge (40983-40990, 43398-43414) between Bogyoke
  #2 ~2's end and Upper Pazundaung #3's start: no corner, open triangle); (4) Hledan #3 under Insein / Pyay with a built-face test; (5) builder state
  leak between stepCell calls (QA: bahan_ring after ycentral vs after long_median, 199 parts, Lane #3789 kerbs 0.004-0.007); (6) not reached:
  Yawmingyi corner wedge, Kun Chan #3 kerb pairs, flicker probe at other junctions, Bahan pave_gap strip, univ_kabaraye three-pavement island.

# roads05 handover (18 Nov 2026, twenty-fourth pass: J28, GEOMETRY agent; BUILDER (Roads.luau, Yangon path) + DATA (fix deck_feet) + Studio 17 spots)

## J28 -- built-surface totals J27 -> J28 (17 spots): 63 / 385 / 58 / 102 / 7 -> 57 / 364 / 40 / 101 / 7
Note + table + 2 shots: vault `City Legends/2026-11-18 roads05 J28 studio check.md`. Studio: main "City Legends", test re-packed FIRST
(asset 133014134133489 revision 200 = J28 roads.json + current builder), ClaudeTools.Roads 1407280218 / YangonRoads 1416678337 (= repo),
scratch cleaned, version 1274, lock released to the QA agent. **Owner decision (coordinator): "0 everywhere"**: the game roads are rebuilt
only when every built-surface count at all 17 spots and every QA rule is 0.
- **Inner cross-section pins (item 1, Roads.luau, `finalEdges` = edgeSurface only, Monaco unchanged):** a cross-section with a pinned edge
  or in a junction (`inJunction`) pins its 7 inner eighths to `bigSurface(..., HALF - 0.5, wide)` minus `PIN_UNDER` 0.06 (the bigger
  road's face shows, never two faces in one plane); strips = 8 there; `finalEdges[ri].C` keeps the SHOWN heights and bigSurface's
  `across` reads them. pyay_univ road_step 27 -> 8 (Insein Road's start over Pyay (Prome) end / Pyay Road #9 / Hledan Road #3).
  Tried + changed: exact pins (no PIN_UNDER) raised Hledan #3 to Insein's straight line and added coplanar cells (6,430 -> 7,263);
  with PIN_UNDER + inJunction: 5,781 (different-road coplanar cells within 45 of (27020, 27855), probe = second cast excluding the hit).
- **deck_feet (item 2, roads05_fix.py, after deck_fair):** the road's cut stretch takes its deck's plan (x, z, dir; heights kept): deck_smooth
  / deck_fair had moved Gyophyu Road Flyover up to 1.3 here (5 max), so the crossing arm by the ramp foot stood 1-1.5 off the ramp wall.
  3,776 samples moved, mouthsim 0 failed of 11,569. kunchan_gyophyu 3 / 42 -> 1 / 28. Studio test: patching Y.data in memory does NOT
  reach the arm mouths (crossMouths / findCorners run in Y.load): data changes need the fix + re-pack.
- **Deterministic check (owner):** `qaBuilt` takes every top within 0.01 of the first hit (exclude-and-recast, up to 3) and keeps one by
  TOP_ORDER Kerb < Pavement < Road < other. The ±1-3 noise was the engine returning either of two coplanar parts. Same build twice:
  kunchan_gyophyu 3/42/2/15/0 twice, double_junction 12/86/1/23/2 twice. The QA agent owns the census now (`T.qa` in Roads05StudioTest).
- **Pipeline:** `J28a_fix.log` / `J28a_mouthsim.log` (0 failed), `J28_paint.log` (83,914 items) / `J28_qa.log` / `J28_paint_qa.log` = J27 exactly. roads.json md5 7c84f19f, paint.json b2536f41; roads_J27.json = backup. Version line written.
- **Next (in order, findings in the note):** (3) double_junction kerb_gap 86 / box_hole 12: corner-arc kerb chords leave 1-stud slits
  against the next road's edge ((39930, 32838), (39941, 32839)); (5) Bahan: 15 "None between pavements" slots ((35387, 37898), (35406,
  38080), (35470, 38138)), not counted by qaBuilt; (6) overlaps: Yawmingyi corner wedge on a straight block (34552, 42646); Hledan Road #3
  (smaller) laid through the Insein / Pyay junction within 0.05 of them (should have no slab there, like a crossing arm); Kun Chan #3
  kerb pairs not re-traced; (7) slip_triangle buried 3 (Lane #15's kerb edge unpinned, carriageway 1 in pinned 0.25 higher to
  Waizayandar), univ_kabaraye pave_step 6 (island (34396-34402, 28831-28837): Lane #1248 / Hledan #3 / Islands pavements 0.2-0.3 apart).

# roads05 handover (18 Nov 2026, twenty-third pass: J27, GEOMETRY agent; BUILDER (Roads.luau, Yangon path) + paint QA + Studio 17 spots)

## J27 -- built-surface totals J26 -> J27 (17 spots): 67 / 394 / 107 / 110 / 5 -> 63 / 385 / 58 / 102 / 7
Note + table + 5 shots: vault `City Legends/2026-11-18 roads05 J27 studio check.md`. Studio: main "City Legends", ClaudeTools.Roads = repo
(915171076), YangonRoads unchanged (1585396069), scratch cleaned, version 1263, lock released. Asset 133014134133489 = the J27 test pack
(J26 builder + data J23; the Roads.luau change went in by text patch: re-pack before the next test).
- **Edge pins (item 1, Roads.luau, `wide` = opts.edgeSurface only, Monaco path unchanged):** `otherNear(..., wide)` takes a bigger road
  whose SAMPLE side width (wl / wr on the point's side) + (radius - HALF) reaches the point, keyed by depth past its edge (d - side
  width), not the nearest centre line; `bigSurface(..., wide)` searches its nearest sample over the widest side (2 cells missed Bahan
  Road's 78-wide side: best stayed sample 1, Lane #3790 pinned 1.1 low). Lane #118 / Hledan Road #3 mouth step gone, slip_triangle
  road_step 31 -> 3, bahan_ring 9 -> 0. Tried + dropped: "on the carriageway only" (+0.5): slip_triangle stayed 21.
- **lanes_unmarked (item 6, roads05_paint_qa.py):** a zebra or another road's carriageway within the reach is a break: 3 -> 0.
- **Pipeline (full, `sh roads05_pipeline.sh J27`, ~55 min):** roads.json / paint.json byte-identical to J23 / J25; mouthsim 0 failed of
  11,569; `J27_qa.log` = J26's; `J27_paint_qa.log` lanes_unmarked 0, the rest unchanged. Version line written.
- **Debug kit (scratchpad, not committed):** `mkpatch.py` (difflib grouped hunks -> Luau find/replace on ClaudeTools.<name>.Source,
  prints the repo checksum), `_G.RELOAD` (no-terrain YangonRoads copy re-required, Roads.build wrapped to keep the edgeSurface call's
  debugEdges in `_G.DE`: later builds of decks reset Roads.debugEdges), `_G.RUNALL(list)` / `_G.SHOWTAB()`, `_G.COL` (height + part
  columns), `_G.ZF(x, z, R)` (coplanar-top probe: second cast excluding the first hit, < 0.05 apart = overlap).
- **Next (in order):** (1) pyay_univ road_step 27: Insein Road's first cross-section spans Hledan #3 (48.2) / Pyay (Prome) (48.4) / the
  Pyay Road #9 ramp (48.6-49.2) as one straight line (16 cells along z 27852-27859): end strip with points pinned per road, or a mouth;
  (2) Gyophyu ramp foot west: ground Gyophyu Road ends 2-4 short of the deck foot (hole (36180, 42610), a 32.16 dip at (36174, 42620)),
  no kerb at x ~36172 z 42610-42620; (3) rounded kerb noses (double_junction kerb_gap 86); (4) double_junction 12 hole cells; (5) Bahan
  hole strip (open slot between two pavement blocks, shot); (6) overlaps from the flicker probe: Kun Chan Road #3 kerb pairs (36351,
  42414), (36360, 42419), pavement (36378, 42421); Yawmingyi Street pavement pairs (34535 / 34552, 42645); (7) slip_triangle buried
  1 -> 3 (Lane #15 kerb (43464, 29305)), univ_kabaraye pave_step 3 -> 6, slip_triangle pavement slot by the kerb (shot).

# roads05 handover (18 Nov 2026, twenty-second pass: J26, GEOMETRY agent; BUILDER + Studio 17 spots; data J23 / paint J25 unchanged)

## J26 -- built-surface totals J25 -> J26 (17 spots): 66 / 446 / 107 / 143 / 5 -> 67 / 394 / 107 / 110 / 5
Note + table + 3 shots: vault `City Legends/2026-11-18 roads05 J26 studio check.md`. Studio: main "City Legends", ClaudeTools.YangonRoads /
Roads = repo (1585396069 / 1519410308), scratch cleaned, version 1249, lock released. Asset 133014134133489 still = the J23 pack (the test
data); the runner's `install` puts ITS YangonRoads over ClaudeTools: re-pack (`roads05_studiotest.py`) before the next Studio test.
- **Corner pavement height rule (item 1):** `buildCorners` `hAt(x, z, u)` = (1 - u) A's + u B's straight-pavement height at the point's foot
  on each road's kept edge (`edgeAt`, now above `sideZone`); used by the arc pavement's inner points and the chip (kerb-side points keep yA..yB).
  Roads.luau `opts.paveY(name, v)` (Yangon only): a cut pavement vertex on a zone edge (sideZone true within 0.2, not a corner zone, 1.5+ off
  my kerb) takes the nearest bigger road's pavement height there. deck_run pave_step 23 -> 13 (left: Lane #4611's 30-wide walk vs Lane #4610's
  side -1 corner, two corners 45 studs apart overlapping on Yawmingyi).
- **Gore kerb (items 2 / 5):** `sideZone`: past another road's corner (ownedBy) my KERB stays where the owner's carriageway + kerb band are not;
  a bigger road's pavement now also stops at a smaller road's kerb band where that kerb is built (recursive sideZone of the smaller road).
- **Gyophyu ramp foot (item 5):** `crossMouths` stops an arm at its first cut sample (it ran through 32 cut deck samples to k = 1: a 100-stud
  sliver along the ramp wall). k = the LAST uncut sample failed (MOUTH FAILED: its cross-section still lies on Kun Chan Road #4).
- **qaBuilt:** `M.qaLast[kind].all` = every fault spot (cluster them by hand).
- **Studio debug kit used (scratchpad, not committed):** an incremental patch (difflib hunks vs the last sent copy) applied to the stored
  Source, `Y.load()`, `T.Y = Y`: a builder change in Studio in ~5 s with no repack. Bahan / deck spots take ~25-60 s each; ALL 17 ~9 min.
- **Next (in order):** (1) deck-foot road_step: Hledan Road #3's kept edge heights jump 0.7 in 3 studs at Lane #118's mouth (pyay_univ
  (27180, 27819)); find which edge pass (pin / mouth_level / deck foot) makes it; (2) Gyophyu ramp foot west side: noSlab samples 34-37 have
  no west kerb and the mouth ends 1.5 short of the ramp wall (Kun Chan (36192, 42592), (36178, 42612)); (3) rounded noses at the other dropped
  corners (double_junction kerb_gap 86); (4) double_junction 12 box-hole cells; (5) Bahan Kan Yeiktha hole strip (bahan_ring box_hole 5 -> 6,
  road_step 8 -> 9 this pass: untraced); (6) lanes_unmarked 3 = a zebra zone (Strand) and two shallow mouths: a QA exemption, not paint.

# roads05 handover (18 Nov 2026, twenty-first pass: J25, GEOMETRY agent; PAINT + QA + Studio 17 spots; builder unchanged)

## J25 -- owner paint "median road dead end, missing lanes" 1 + 2, data J23 unchanged
- **The spot:** Sule Pagoda Road's north arm at Bogyoke Aung San Road (the J24 `sule_shangrila` shot, cropped by the owner).
  The "dead end" was the Studio TEST box (half 220, top z 43253): the arm's full-width flyover ramp ("Sule Pagoda Road
  Flyover", 93 wide, z 43266 -> 42836, y 33 -> 48) starts 13 studs inside the box edge, then curves NW onto Alan Pya
  Pagoda Road (the owner's red curve). OSM: both one-way carriageways run on (ground to z 42990, bridge layer 1 to 42835).
  Data was right. New spot `sule_north` (36090, 43080, half 300) shows the arm, the ramp and the curve.
- **QA (geometry) `dual_dead_end`** (roads05_qa.py): a dead_end row of a divided road (median within 60 of the end)
  whose end cross-section (kerb to kerb) touches no road / deck / ring, not outside / within 12 of the districts'
  outline, where a kept OSM way reaches 30+ past it. J25: 0 (the centre-point first try flagged 9: splits, merges, edges).
- **QA (paint) `lanes_unmarked`** (roads05_paint_qa.py): 30+ studs of a carriageway with 2+ lanes a direction
  (`neff`) and no lane dash of that road within 14 studs. 30 -> 3 (paint: `wide` streets now get lane dividers + centre
  line; yellow kerb lines / boxes / zebras / stops stay main-road only). Left: Strand Road (34042, 45943) 56 studs, Min
  Nandar Road #2 (47657, 35072) 31, Shwe Gone Dine Road #2 (34501, 34915) 32 (routes: mouth / fold clipping, not traced).
  All other paint rules unchanged.
- **roads05_studiotest.py:** driver camera stepped out of every real ring (r_out + 12, the ring's own centre).
- **NOT done (context):** items 2-7 (corner pavement height rule, rounded kerb noses, deck-foot road_step, double
  junction box holes, Kun Chan seam, Bahan hole strip): unchanged from the J24 "Next" list below.

# roads05 handover (18 Nov 2026, twentieth pass: J24, GEOMETRY agent; Studio 16 spots + 32 shots; NO code / data change kept)

## J24 -- built-surface totals J23 -> J24 (16 spots): unchanged, 66 / 446 / 107 / 143 / 5 (same code repeats exactly)
Note + table + 32 shots: vault `City Legends/2026-11-18 roads05 J24 studio check.md`. Data = J23 (pipeline not re-run: nothing
changed; `J23_qa.log` stands). Studio: main "City Legends", scratch cleaned, saved version 1237, lock released; asset 133014134133489 =
the J23 pack again (YangonRoads checksum 1649648240).
- **Item 1 deck_run pave_step 23 is NOT a J23 builder regression:** square ends / T clip / cut-sample change each turned off in a
  Studio test copy -> still 23; data heights the same as J22. J23's QA (side faces = edge) made it countable. Cause: Lane #4610
  (walk 30) x Yawmingyi (York) Street (walk 18), corner r 15.9 < walk -> `buildCorners` chip reaches ~30 studs along Yawmingyi at the
  corner END heights yA..yB, 0.24-0.27 under Yawmingyi's straight pavement (street climbs ~1%) along its back line (z 42636,
  x 34542-34556). Tried + reverted: Roads.luau `opts.paveSnap` raycast snap of cut pieces (23), snap of arc / taper / chip vertices
  reach 2 (32), chip vertices = nearer road's edge height (26), only bigger-road-side chip vertices (23, step moved inside).
  **Next for it:** ONE height rule for every pavement piece of a corner (straight band ends near T, arc pavement fan to O, chip,
  taper), e.g. the nearer road's straight-pavement height at the point, set together in buildCorners.
- **Debug tools that worked (Studio, test copy):** patch `ClaudeTools.YangonRoads.Source` with gsub, clone, `require`, `Y.load()`,
  set `T.Y` -> A/B a builder change without a repack; wrap `Y.Roads.triangle` and log `debug.traceback` for triangles in a fault box
  to find which function made a part. A full repack + PATCH + LoadAsset is ~2 min; LoadAsset sometimes answers HTTP 502: retry.
- Driver cameras at bahan_ring / hanthawaddy / roundabout4 sit inside the island mound (grass shots): fix in roads05_studiotest.py.
- **Next (in order, unchanged from J23):** corner pavement height rule (item 1); rounded kerb noses at the 6 dropped corners; deck-foot
  road_step pyay_univ 37 / slip 32; double_junction box_hole 12 (single cells round the box, not one patch: (39906-39940,
  32838-32898), (39972-39988, 32914-32944)); Kun Chan seam + Gyophyu ramp-foot strip (36150, 42666); Bahan Kan Yeiktha hole strip;
  kerb_gap patterns biggest first. Plan is NOT ready for owner approval.

# roads05 handover (18 Nov 2026, nineteenth pass: J23, GEOMETRY agent; DATA + BUILDER + QA + Studio 16 spots + 32 shots)

## J23 geometry -- built-surface totals J22 -> J23 (16 spots): box_hole 77 -> 66, kerb_gap 639 -> 446, road_step 148 -> 107, pave_step 308 -> 143, buried 14 -> 5
Per spot + shots: vault `City Legends/2026-11-18 roads05 J23 studio check.md`. Python QA (`J23_qa.log`): seam_step 3 -> 0, pave_step 3 -> 0, kerb_cross 0,
mouthsim 0 failed of 11,569, deck_grade 7. Backups `roads_J22final.json`, `qa_J22.json`.
- **qaBuilt:** keeps only up-facing hits; a cell with only side faces = "Edge" (no fault): the J22 retry had taken pavement side
  faces for "pavements 4.7 lower" (the deck-spot pave_step rise was QA, not the builder). Asphalt next to nothing at a free (OSM
  dead) end is not a kerb_gap.
- **polyDist (builder + kerbsim):** cut samples and a lone uncut sample between cuts are no road; road ends are square (no round
  cap). **sideZone:** a smaller road is clipped 1 stud on my side of my centre (T ending 0.1 past it took my far kerb).
- **buildIslands:** an outline side with no band kerb just inside it (ray, not bounding box) gets its own kerb, fill moved in 0.85.
  **endKerbs** (new, after islands, in stepCell and step3): a non-mouth, non-continuation, non-dead end gets a kerb where nothing is
  built just past it.
- **roads05_fix:** islands / fills computed last (after kiss_clear); `mouth_level`: one host per run, skips continuation joints,
  "on" while any of the cross-section lies on the host, two runs blend linearly, abutting runs leave 3 samples for the climb,
  the fade ends by the far end.
- **roads05_studiotest.py:** driver camera within 0.55 of the half box and never inside a ring island.
- **Next (in order):** (1) deck_run pave_step 0 -> 23 (Lane #4610 / #4611 x Yawmingyi (York) Street wide pavements, 0.27-0.38:
  builder, data unchanged): find which J23 builder change; (2) double_junction water south of the box (East Horse Race Course Road
  (Bridge)'s ground start under the Bo Min Gaung bridge: data); (3) rounded noses at the 6 dropped corners + Kun Chan Gyophyu ramp
  foot strip (kerb_gap 30 at (36150, 42666)); (4) deck-foot road_step pyay_univ 37 / slip 32; (5) Bahan Kan Yeiktha split (two
  island pieces, hole strip, START-line kerb); (6) a lane wider than its host (Lane #1256 on Kabar Aye Pagoda Road #6).
- Studio: main "City Legends", scratch cleaned, saved version 1229, lock released; ClaudeTools.YangonRoads = repo file (checksum
  1649648240); asset 133014134133489 = the J23 pack. Plan is NOT ready for owner approval.

# roads05 handover (18 Nov 2026, eighteenth pass: J22, GEOMETRY agent; DATA + BUILDER + QA + Studio 16 spots; stopped: context)

## J22 geometry -- built-surface totals J21 -> J22 (16 spots): box_hole 234 -> 77, kerb_gap 937 -> 639, road_step 168 -> 148, pave_step 211 -> 308 (UP), buried 15 -> 14
Per spot: vault `City Legends/2026-11-18 roads05 J22 studio check.md`. Python QA (`J22_qa.log`): kerb_cross 0, mouthsim 0 failed of
11,569, deck_grade 7, NEW seam_step 0 -> 3 and pave_step 0 -> 3 (most likely mouth_level: look first). Backups `roads_J21final.json`.
- **qaBuilt:** a miss is cast again 0.003 / 0.006 off (rays down two wedges' shared edge: Roundabout 4's 48 holes were mostly that).
- **YangonRoads.sideHalf** (half on the spot's side) replaces halfAt (the wider) in ownedBy, findCorners' on-road test, crossMouths,
  the mouth tests and the deck piers' onRoad (Sule Pagoda Road 64 / 33 owned Lane #3352's kerb band: Roundabout 4 kerb_gap).
- **buildIslands:** outline sides cut into 4-stud pieces, each on the built edge height (edgeY now interpolates along edge segments):
  fills no longer stand over the kerbs.
- **roads05_fix.downtown_walks:** a side with a building line is limited 1 stud + the other road's walk before another ground
  carriageway (Lane #7793 walk 24.6 over 32nd Street -> 4); a road alone never widens a walk.
- **roads05_fix.mouth_level** (after butt_match): a road end on a bigger road (side half + 0.5, within 2.5 studs height) sits at the
  host's height, the step faded 3% (20-120 studs): 1,043 ends. univ_kabaraye road_step 50 -> 28 only: Lane #1256 / #1257 / #1248
  (flyover side lanes onto Hledan Road #3) still crease: check their samples in the J22 roads.json (Lane #1256 was 0.9 over).
- **Next:** (1) pave_step rise at the deck spots (univ_kabaraye, hledan_flyover, slip_triangle, pyay_univ): probe with the
  character map (`_G.MAP` idea: 0.5-stud grid, folder letter, `#` kerb, lower case pavement) and the hit stack, some are pavement
  pieces 4.7 lower on Hledan Road #3's deck side; (2) the Python seam_step / pave_step 3; (3) bahan_ring island between Kan Yeiktha
  Road / Lane #8112 / Kan Yeiktha: data island overlaps the built carriageway (scrub "Islands on Kan Yeiktha Road 17") and no kerb on
  Kan Yeiktha Road's side; (4) dropped corners -> rounded noses (double_junction water south of the box, Kun Chan cluster
  36180-36196 / 42584-42608); (5) shots: only roundabout4 overview + driver, bahan_ring overview this pass (29 left).
- Studio: main "City Legends" (reopened after the power cut), scratch cleaned, saved, lock released; asset 133014134133489 = the J22 pack.

# roads05 handover (18 Nov 2026, seventeenth pass: J21, GEOMETRY agent; DATA + BUILDER + QA + Studio 16 spots)

## J21 geometry -- counts J20 -> J21 (full net, `J21_qa.log`; backups `qa_J20.json`, `qa_J21a.json`, `roads_J20b.json`)
kerb_cross 2 -> 0, deck_grade 8 -> 7 (Road Flyover 8.1% -> 7.8%; the 7 left are the old junction-blocked `short` ones),
mouthsim 0 failed of 11,569; deck_clear / deck_wobble / width_wobble / pave_width_jump / overlap / median_cross 0,
centre_fold 1, mouth_short 35 / mouth_over 37 (real 1), stack_paint 8, paint_off_centre 68 (paint): unchanged.
Built check (Studio, all 16 spots, table in vault `City Legends/2026-11-18 roads05 J21 studio check.md`).
- **Item 1 pavement steps:** NOT a builder step. Every "thin wedge 0.29-0.41 lower" checked has a flat top at the right height:
  qaBuilt's ray ran down the WedgePart's vertical slanted face. qaBuilt now casts again a hair off when the hit normal is
  not up (Kun Chan +-220: pave_step 64 -> 17, road_step 50 -> 13). Also done (the handover's suspect, kept: correct and
  harmless): `Roads.build` `opts.edgeSurface` (YangonRoads.buildRoads sets it): roads built bigger first, a mouth's
  pinned edge takes the bigger road's FINAL edge / cross-section height (`finalEdges`), not its centre line. Roads.luau
  is now packed into the Studio test (Roads05StudioTest installs it into ClaudeTools).
- **Item 2 dropped corners:** `findCorners` tries a corner that lies on a road again with T x 0.7 (up to 8 times) before
  dropping it (`M.cornerInRoadShort`; Kun Chan pack: 15 tightened, 6 still dropped incl. Gyophyu x Kun Chan #4 at
  (36276, 42539)). Scrub: a stray kerb / pavement with nothing under its middle leaves its own shape as asphalt at the
  asphalt height round it (`M.strayPatched`, 130 in the Kun Chan cell). Kun Chan box_hole 8 -> 8 (NOT closed: the
  holes at (36196, 42584), (36244, 42510), (36334-36397, 42418-42494) remain); kerb_gap cluster at (36180-36196,
  42584-42608) still there (the corner there stays dropped).
- **Item 3 gore cracks:** NOT fixed. A thin dark seam still crosses the Kun Chan box (shot `... kunchan_gyophyu - driver`).
- **Item 4 kerb_cross:** `fork_trim` re-ranks after trimming (a trimmed fork that ENDS inside its sibling outranked it:
  Lane #679 on Bo Min Gaung Street, no mouth); new `kiss_clear` (after crossings): a kerb kerbsim still finds at most
  KISS_MAX 4 inside another carriageway is a graze: the road is pushed off (depth + 1 + kerb, tapering 0.15 / stud),
  4 passes (Lane #2945 at the Bayint Naung Road #11 flyover foot).
  QA kerb_cross 2 -> 0.
- **Item 5 Road Flyover:** its ramp was regraded at 7.8% on the plan before deck_fair / unfold / deck_joints moved the
  samples (spacing 7.85 -> 7.59): 8.1%. New `deck_recap` runs after the LAST plan change (before check): a non-chain deck
  over 8% is re-profiled by _deck_try on the final plan (same crest / clearances), kept only within DECK_MAX.
  Road Flyover is a chain deck (an end on another deck's): capped at DECK_MAX from both ends, ends and the 31.29 top
  kept: 8.1% -> 7.8% (Road Flyover #2 too). Pinlon 7.8%, top 26.0 unchanged.
  Pinlon Road Flyover on the satellite (`City Legends/Road plan - Close-up Pinlon Road Flyover overlay.png`): a real twin
  bridge over the creek; the crest over the water is right.
- **Item 6 Studio:** all 16 spots built + qaBuilt (QA now skips 20 studs at the test box edge and subset deck ends: they
  are the test's own cuts). Clean: downtown_straight, lane_taper (all 0). Worst: roundabout4 / bahan_ring (box_hole 48 /
  43, kerb_gap 166 / 160), double_junction (holes in the box between the triangle islands: real), deck feet road_step
  (univ_kabaraye 50, pyay_univ 35, slip_triangle 35). Shots: 5 spots overview + driver (`City Legends/2026-11-18 roads05
  J21 test - <spot> - <view>.jpg`); the other 11 QA only. Studio: main "City Legends", scratch cleaned, saved version
  1208, lock released; asset 133014134133489 rev 175 = the J21 test pack (data from the first J21 run).
- **Next:** box holes / kerb gaps at the roundabouts and the double junction (look at each cluster with the probe: part,
  normal, corners); deck-foot road_step; the Kun Chan seam (gore crack) and the 6 corners still dropped (try rounded
  noses on the square kerb ends); shots for the other 11 spots.

# roads05 handover (18 Nov 2026, sixteenth pass: J20, GEOMETRY agent; DATA + BUILDER + QA + Studio; stopped: context)

## J20 geometry -- counts J19 -> J20 (full net, `J20_qa.log`; backup `qa_J19.json`, `roads_J19.json`, data `roads_J20.json`)
kerb_cross 12 -> 2, deck_clear 1 -> 0, deck_grade 7 -> 8 (new: "Road Flyover" 8.1% at (31584, 45624), just over 8%),
mouthsim 0 failed of 11,568 (+4 mouths: the trimmed forks); width_wobble / pave_width_jump / pave_step / seam_step /
overlap / median_cross 0, centre_fold 1, mouth_short real 3, mouth_over real 1, stack_paint 8 (paint): unchanged.
Builder QA (Studio, new `YangonRoads.qaBuilt`, Kun Chan box +-170, 0.5 grid): box_hole 8, kerb_gap 54, road_step 28,
pave_step 48, buried 4; corner_in_road: 21 corners dropped over the test pack's 474 roads, 0 built in a road.
- **Item 1 Kun Chan x Gyophyu:** `roads05_fix.fork_trim` (before the mouths): records joining one host end within its
  half + 3 = a fork; the widest carries on, a record lying inside it is cut back to its last sample 2 inside it and
  starts as a MOUTH on it. 5 forks: Lane #3414 on Kun Chan Road #3 (3 samples), Lane #679, #1428, #274, #2956.
  `roads05_qa.cont_pairs` ties go to the wider record. Gore cracks / pavement steps: NOT fixed. What qaBuilt shows
  there: pave_step = single thin pavement wedges 0.29-0.41 under their neighbours (e.g. Kun Chan Road #4 (36194, 42585)
  top 34.01 vs 34.30; Gyophyu (36256, 42477) 33.42 vs 33.83): clipped zone pieces whose edge points are pinned to the
  bigger road's surface (Roads.luau edge pin / relax), not corner pieces. `pave_step` network-wide in Python still
  measures record joints only (0); the built check exists only in Studio (qaBuilt) per test spot: run it on all 16.
- **Item 2 taper (builder):** a corner arc shorter than `TAPER_MIN` 20 keeps the wider walk on the whole arc and lays
  a taper strip behind the narrower straight pavement from the arc's walk down to its own over 20 studs (`buildCorners`,
  corner `wA0` / `wB0`). Not seen in a shot (no short-arc walk change in the Kun Chan box).
- **Item 3 downtown walks:** walk_match first widens a joint to the wider walk where the narrower record's building
  line (downtown_walks' 10th percentile, `data._room`) allows it, then narrows as before: widened 0, narrowed 98. The
  98 wider downtown sides did NOT survive; their building lines are closer than the wider walk on nearly every one
  (e.g. Seik Kan Tha Street (Middle Block) L 22.5 room 5.3), the narrow partners are mostly lanes with no building data.
- **Item 4 kerb_cross 12 -> 2:** kerbsim now knows the crossing boxes (J19 crossMouths: no kerb of either road on the
  other inside max halves + 16 of a crossing): 10 were crossings already done. Left: Lane #2945 on Bayint Naung Road #11
  (a loop lane "kissing" the road at the Bayint Naung Road Flyover's foot, (52601, 18639): the crossing step rejects it
  because the touch is on the cut / deck foot); Lane #679 on Bo Min Gaung Street (now a mouth after fork_trim).
- **Item 5 block 2:** rules exist only as `qaBuilt` (built surface, per Studio spot): box_hole, kerb_gap (= fillet_no_kerb
  / flare_kerb_gap / corner_pave_gap / road_gap edges), road_step, pave_step, buried. Not 0. kerb_gap at
  (36180-36196, 42584-42608) is where the Gyophyu x Kun Chan #4 crossing corner was dropped (its arc lay on Gyophyu).
- **Item 6 Pinlon Road Flyover:** `roads05_fix.water_cc`: a water / rail AREA asks its clearance at the middle of each
  run of deck samples over it (deck_regrade and QA deck_clear); the soft top goes over the highest need. Pinlon now
  regrades (7.8%, not "short / kept"), deck_clear 0. NOT checked on the satellite.
- **ADD (owner, "random pavements in the middle", ref `Owner ref - random pavement in junction by Yangon Central.webp`):**
  `findCorners` drops a corner whose kerb arc / pavement (4 radii x 15 steps) is 0.5 inside any carriageway (the
  corner's own two roads: 2 inside; roads > 4 studs above / below skipped) or in a gore fill (`M.cornerInRoad`, list
  `M.cornerInRoadList`). Scrub second pass: probes from a wedge's triangle centroid; a kerb / pavement within 1.5 of a
  fill goes; tiny cut-off triangles (< 0.3 sq studs) with no whole piece of their kind within 1.5 go (the island tip
  by the zebra). Studio: the floating arc and the tip are gone; a box_hole (36276, 42538) opens where the tip stood.
  Dropping a corner leaves its two kerb ends square (kerb_gap): next, close them with a plain asphalt fillet.
- Shots: `City Legends/2026-11-18 roads05 J20 geo - Kun Chan x Gyophyu overview.jpg`, `... close-up.jpg`, `... driver.jpg`,
  `... driver (before stub scrub).jpg`. Studio: main "City Legends", scratch cleaned, saved (version 1202), lock
  released; asset 133014134133489 = the J20 test pack.
- **Next:** root of the pavement steps (pinned edges vs clipped pieces); kerb_gap where corners are dropped; qaBuilt over
  all 16 spots (and a network-wide built pave_step); kerb_cross 2; Road Flyover grade 8.1%; Pinlon on the satellite.

# roads05 handover (18 Nov 2026, fifteenth pass: J19, GEOMETRY agent; DATA + BUILDER + QA + Studio; stopped: context)

## J19 geometry -- counts J18 -> J19 (full net, `J19_qa.log`; `J19a_qa.log` = item 1 alone)
width_wobble 14 -> 0, kerb_cross 13 -> 12, pave_width_jump (new) 200 -> 0, pave_step (new) 0 -> 0, centre_fold 1 -> 1,
mouthsim 0 failed of 11,564; overlap / median_cross / zero_width / rank_dup / seam_step / deck_wobble 0; deck_clear 1,
deck_grade 7, mouth_short real 3, mouth_over real 1, stack_paint 8 (paint): unchanged. Backup `qa_J18.json`.
- **Item 1 width_wobble 14 -> 0 (commit 2bbf686f):** `width_taper` runs again right after `unfold` (dropped samples
  shortened chords: Pyay #6 / #2, Min Nandar #2, Parami, Hledan #3, Kun Chan); `deck_joints` no longer cuts the joint
  sample in one step: walking away from the deck each ground sample is capped at WIDTH_RATE per stud (Kabar Aye 53 -> 24
  over ~200 studs, Bayint Naung Bridge 2, Pansodan, Nga Moe Yeik, E Horse Race Course, Lay Daungkan #2, Shwedagon,
  Bo Min Gaung). centre_fold stays 1, mouthsim 0 failed.
- **Item 2 seams (Studio-measured, Kun Chan x Gyophyu):** a ray grid (0.5 studs, jump beyond the local slope) showed the
  lines were STEPS, not gaps: Kun Chan x Gyophyu is a CROSSING (Gyophyu x Kun Chan Road #4) and both carriageways ran
  through the box 0.05 apart (crossing line + z-fight). Fix (YangonRoads): a crossing's smaller road lays no slab on the
  bigger one (`noSlab` from its crossing sample to k each way) and `buildRoads` lays its two arms as mouths cut on the
  bigger road's kerb line (`M.crossings`). Gyophyu|Kun Chan #4 seam points 26 -> 3. Fills: no "flatten" on fill
  triangles any more (it stepped them). **Left:** Lane #3414 lies on Kun Chan Road #3 within 0.05 for ~40 studs (both
  start on Kun Chan Road's end: a fork; z-fight arcs in the box); single-sample cracks between wedge triangles (rays fall
  through, 6 spots in Fills, a few in Gyophyu): the fills' outline heights jump (0.5 over 6 studs) and steep triangles are
  skipped by `Roads.sliver`. Next: grade-clamp fill outline heights; fork overlap = drop the smaller fork record's slab
  where it lies on the bigger one (or absorb the fork in data).
- **Item 3 crossing corners (new builder feature):** `roads05_fix.crossings` -> `data.crossings` [[small, i, big, j, x, z]]
  (1-based; at-grade, both run on past the other's kerb by 16, no cut / deck / ring): 1,726. `YangonRoads.crossMouths`
  makes two mouth-like records per crossing (each way from the crossing sample to its first sample off the bigger road);
  `findCorners` treats them like mouths (four corners: kerb arc, asphalt fillet, pavement arc; cornerR 30 = 10 m where
  both roads carry it, else CORNER_T; the 2T+4 clamp skips the same crossing's corners across the road). Studio: Sule
  Pagoda Rd x Bogyoke r 30 / 30 / 30 / 15.6 (the SW one is clamped by Sule Pagoda Road #5's slip corner); Lake Kan Road x
  U Shwe Gwun Street 4 corners r 14-17; 221 crossings / 420 crossing corners in the 16 test spots, no mouth failures.
  Street radii are CORNER_T (r ~16 at 90 deg), NOT measured per corner on the satellite.
- **ADD (owner, "pavements not smoothly connected", ref `Owner ref - pavements not smoothly connected (new build).webp`
  = Kun Chan x Gyophyu):** cause: `downtown_walks` gives each record its own walk, so a road split into records changed
  pavement width in one step (Kun Chan Road walkR 28.7 = the raised grey slab top right; Lane #3414 4.0 beside 7.5).
  `roads05_fix.walk_match` (after downtown_walks): both records of every continuation joint take the NARROWER walk per
  side until stable (forks: only the straightest record pairs); 98 sides changed. New QA `pave_width_jump` (joint walk
  differs > 0.5) and `pave_step` (joint height > 0.1) via `roads05_qa.cont_pairs`. Studio (Kun Chan, after): the slab
  is gone; pavement steps left: the crossing's corner pavement vs Kun Chan Road #4's straight pavement 0.11-0.13 (corner
  yB vs the straight band's height) and one 0.54 inside Kun Chan Road #4 (not traced). The green block bottom right is a
  building roof, not a road part. Corner arcs shorter than 20 studs still change walk wA -> wB over the arc.
- **NOT done:** item 4 kerb_cross (12 left, list in qa.json), item 5 block 2 rules (road_gap, kerb_gap, box_hole,
  fillet_no_kerb, flare_kerb_gap, corner_pave_gap, buried edges), item 6 Pinlon Road Flyover top over Pazundaung Creek
  (`deck_regrade` has no "top at the water line" input yet: add one, then check on the satellite).
- Shots: `City Legends/2026-11-18 roads05 J19 geo - Sule Shangri-La crossroads.jpg`, `... - Lake Kan Road x U Shwe Gwun
  Street crossroads.jpg`, `... - Kun Chan x Gyophyu (seams).jpg` (after walk_match). Studio: main "City Legends", scratch
  cleaned, saved (version 1199), lock released; asset 133014134133489 rev 168 = the J19 test pack.

# roads05 handover (18 Nov 2026, fourteenth pass: J18, GEOMETRY agent; DATA + BUILDER + QA; stopped: context)

## J18 geometry -- counts J17 -> J18 (full net, `J18_qa.log`; mouthsim 0 failed of 11,564)
kerb_cross 17 -> 13, centre_fold (new) 71 -> 1, mouth_short real 2 -> 3, mouth_over real 1 -> 1, deck_clear 1 -> 1,
deck_grade 7 -> 7, overlap / median_cross / zero_width / rank_dup / seam_step 0, stack_paint 7 -> 8 (paint),
**width_wobble 0 -> 14 (NEW REGRESSION, not fixed)**: the 14 roads are the fold-back roads (Pyay Road #6 / #2, Kabar Aye,
Hledan #3, Min Nandar #2, Bo Min Gaung, Parami, Kun Chan ...) + decks (Bayint Naung Bridge 2, Pansodan, Nga Moe Yeik,
Shwedagon, East Horse Race Course Bridge): suspect `unfold` (dropped samples -> a width step over a shorter chord) and
`deck_joints` (the joint sample's flare cut to the deck's half). Look at qa.json width_wobble rows first.
Backups: `roads_J16.json` (J17 = J16 data), `qa_J17.json`. Version: `roads05_NETWORK_VERSION.txt` (created; force-add it).
- **Item 1 Bahan / Roundabout 1 (done, Studio-checked):** `roads05_absorb` MERGE: a one-way route / street of class
  motorway .. tertiary (+ links) whose END lies on the bigger road and >= 15% of its area on it is paired; near samples
  (gore < NOSE_MIN 6) running on from the alongside run go too and the road widens over them; PARALLEL_MERGE 0.85
  (0.75 in a second pass `merge_into` = roads widened by a merge, for slips that ended on the absorbed road). Bahan Road #2
  absorbed whole (Bahan widens to 90 on its east side at the ring), Lane #8112 absorbed 14 samples, mouths onto Bahan at
  ~37 deg (corner r 62 / 3.9). Pass 1: 89 absorbs (81 merges), pass 2: 43. Shot `... J18 geo - Bahan Road at Roundabout 1.jpg`.
- **Item 2 double junction (done, Studio-checked):** `roads05_fix.side_clear` (after ring_clear): a lane (street, hw
  service / residential / unclassified / living_street / track) running >= 6 samples parallel beside a bigger road closer
  than walk + walk is pushed out until the pavements meet, taper 0.15 / stud, ends fixed (an end may sit in the taper
  only where the lane leaves square). 47 lanes, max 12 studs; Lane #7108 8.1. ~3 min (the slow step).
- **Item 3 seams:** Shwedagon landing: `deck_joints` (last before check()): a deck end on its own ground road takes the
  road sample's direction (they differed up to 3.5 deg: the wedge), the road sample takes the deck's height, and a
  road flare on the joint sample is cut to the deck's half. 46 deck ends changed. Studio: the crease line and dark
  wedge are gone (`... J18 geo - Shwedagon deck landing.jpg`). **Junction-box dark seam lines NOT fixed:** likely
  T-junction cracks between mouth triangles (YangonRoads.buildMouth earClip, vertices on the bigger road's boundary) and
  the bigger road's quads, or skipped `Roads.sliver` triangles; showing the void in the lifted no-terrain test. Next:
  raycast down along a seam in the test build (gap or step?) before changing the builder.
- **Item 4 corner radii (partly):** `roads05_fix.corner_radii`: downtown (P3) roads of class trunk .. tertiary and their
  links carry `cornerR` 30 (10 m, the middle of the 8-12 m the brief gives; NOT measured per corner on the satellite);
  `YangonRoads.buildCorners`: T = max(T, min(cornerR / tan(theta/2), CORNER_T_MAX)) when both roads carry it;
  `YangonRoads.load` now copies cornerR (it copied named fields only). Sule Shangri-La: the 45-deg corners of Sule Pagoda
  Road #5 went 6.6 -> 9.4 (clamped by the 0.45 x gap rule). **The owner's drawn corners at Sule Pagoda Rd x Bogyoke are
  a CROSSING (no road ends there): buildCorners only rounds mouths, so those 4 corners stay square** (shot
  `... J18 geo - Sule Shangri-La corner.jpg`). Next: corners at crossings (a builder feature) or split the crossing.
- **Item 5:** kerbsim skips kerbs the builder's scrub removes (`scrubbed`: 8 probes SCRUB_R 1.6 all on a carriageway or
  ring). kerb_cross 13 left: Hanthawaddy Road on Hledan #3, Kun Chan Road #4 on Gyophyu, Lane #2945 x2, #679, #6775,
  Kabar Aye #8 on Pearl St #3, #5208, #2693, #3486, #2939 ~2, Lane #3 x2 (lanes at a shallow crossing; see qa.json).
  Block 2 (road_gap, kerb_gap, box_hole, fillet_no_kerb, flare_kerb_gap, corner_pave_gap, buried edges): NOT started.
  Pinlon Road Flyover (deck_clear 1): it crosses Pazundaung Creek (OSM river, 365 studs wide on the deck) ~767 studs from
  its start, but its OSM-profile peak sits ~200 studs BEFORE the river (deck 17-20 over the water, ground 15). Not
  satellite-checked. Fix idea: regrade with the top over the river line (deck_regrade needs the water crossing as the top).
- **ADD (paint agent) fold-backs:** `roads05_fix.unfold` (before deck_joints): a sample that steps back
  (`roads05_qa.folds`, the paint agent's rule) is dropped; protected (end / cut / deck) ones take their neighbours'
  direction. 103 dropped, 1 left: Road #25 i 225 (protected). QA `centre_fold`.
- Studio: main "City Legends", scratch cleaned, saved (version 1193), lock released; asset 133014134133489 rev 165 =
  the J18 test pack (YangonRoads sum 1918405911). The double junction shot shows a hole at the spot box's edge (box clip,
  not checked).

# roads05 handover (18 Nov 2026, thirteenth pass: J17, GEOMETRY agent; BUILDER CODE only, data = J16 bd770808; stopped: context)

## J17 geometry -- done (YangonRoads.luau, Studio-checked lifted, no terrain)
1. **Corner pavement (commit 766ad367).** `buildCorners`: corner asphalt now runs 0.3 under the kerb (arc points at r - 0.3) and
   kerb bands are <= 20 degrees (no slit between kerb chords); when r < walk a back-corner "chip" (`c.chip`) paves the tip of
   the sharp L where the two straight pavements' back lines meet: the back edge = the kerb arc moved by P' - P (one curve
   parallel to the kerb). `verge`: the corner grass starts 4 studs UNDER the pavement at the corner's built edge heights
   (c.yA / c.yB; it ended at the back edge at centre-line heights = the owner's voxel "staircase"); straight verges use each
   side's own walk (walkL / walkR) instead of M.WALK. NOT verifiable in the no-terrain test: check the steps in a real build.
2. **Strays (commit 270191d2).** `scrub` second pass on the BUILT parts: a Kerb / Pavement with asphalt ("Road") under all 8
   probes 1.6 out (rays look through kerbs and pavers) goes; a Pavement with no asphalt within 1.5 x its road's walk + 4
   (16 directions, rings of 4) goes. Kun Chan x Gyophyu: 892 stray pieces removed (the buried kerb lines + the stubs; shot
   before / after). Double junction: 116 removed. The 250-stud loose strip W of the double junction is NOT in J16 data any
   more (it came from J15 data). Left there: Lane #7108 lies along Shwe Gone Dine Road's north edge (centre 3-9 studs past
   its kerb): its kerb + Shwe's kerb run side by side with a sliver gap: a data job (absorb / drop the lane alongside).
- Shots: `City Legends/2026-11-18 roads05 J17 geo - Kun Chan x Gyophyu (before scrub).jpg`, `... - Kun Chan x Gyophyu.jpg`,
  `... - Double junction.jpg`, `... - Bahan Road at Roundabout 1 (not fixed).jpg`, `... - Sule Shangri-La round corners.jpg`.
  Studio: scratch cleaned, saved (version 1191), lock released; ClaudeTools.YangonRoads = the repo file (sum 1648252319).

## NOT done (next pass, in order)
3. **Bahan / Roundabout 1.** Lane #4701 is now **Lane #8112** (starts on Kan Yeiktha, ends at (35321, 37933) ON Bahan Road #2's
   centre line). Cause of the regression: J13/J14 absorbed **Bahan Road #2** (one-way ring arm, 7 samples) into Bahan Road;
   since J15 it is 25 samples, half 21, edge-to-edge beside Bahan Road (half 48.6 symmetric at its start), so absorb no
   longer pairs it (no overlap area). Lane #8112 converges into Bahan Road #2 at a shallow angle (gore 5 -> 0 studs from
   z 38011 to 37987): the thin nose with two kerbs and a sawtooth pavement (shot). Fix idea: absorb pairs roads that
   ABUT (edge gap < 1) and are parallel (Bahan Road #2 into Bahan Road), and a gore narrower than 2 kerbs + 2 between a
   merging lane and its road becomes asphalt (fills) up to where it is wide enough for a kerbed nose. No holes seen in J17's run.
4. Seams (Shwedagon landing crease + wedge, thin dark slab joints in boxes: visible in the Kun Chan shot).
5. Corner radii from the satellite (Sule Shangri-La / DBS first): CORNER_T 16 -> r ~16 at 90 deg; downtown wants 24-36.
6. kerb_cross 17, block 2 QA rules, Pinlon Road Flyover clearance (satellite).
- roads05_kerbsim does not model the new scrub pass: QA kerb_cross may now over-count what the builder leaves.

# roads05 handover (18 Nov 2026, twelfth pass: J16, GEOMETRY agent; DATA + QA, no builder change, no Studio)

## J16 geometry -- counts J15 -> J16 (full net, `J16_qa.log`; mouthsim 0 failed of 11,592)
deck_wobble 24 -> 0, deck_clear (new) 5 -> 1, deck_grade 8 -> 7, deck_foot 0 -> 0, median_cross 3 -> 0, overlap 1 -> 0,
kerb_cross 17 -> 17, mouth_short real 2, mouth_over real 1. paint_off_centre 1 -> 68 and stack_paint 0 -> 7 come with the
paint agent's newer roads05_paint.py (not checked by me). Backups: `roads_J15.json`, `qa_J15.json`, `qa_J16a.json`.
- **Bridge heights (`roads05_fix._deck_chains`, `_rail_water`, `_deck_try`):** the low bridges were ONE structure cut
  into named decks (Thaketa Bridge -> Set Yone St, Lanmadaw Rd -> Myoma Kyaung St, Sule Pagoda Rd -> Gyophyu / Alan Pya
  Pagoda Rd, also U Chit Maung -> Banyar Dala, Hledan x3, Bayint Naung Bridge 2 -> Thamaing Station Rd, Khayaypin x3),
  each pinned to the ground at the joint, next to the railway. Deck ends within max(6, the end's width) are a joint; the
  two that run on straightest are one chain, regraded as one deck (its own chainage: no sideways jump across a fork);
  other decks there are fork branches, their joint foot held at the chain's height. Hard needs now: CLEAR_RAIL 13.5
  (4.5 m) over every OSM railway=rail, CLEAR_WATER 9 (3 m) over river / canal / water areas, ground = the road's own
  sample heights; away from DECK_FLAT + 10 of the outer feet. Too short: the chain's / branch's FREE feet grow (shared
  `grow` with the single-deck path, DECK_EXT 48); only when a junction blocks it, the least steeper grade that clears
  (steep mode no longer chases the old top: that gave 0.27). Results: Lanmadaw / Myoma top 63.1 (grew 4, 7.8%), Sule /
  Alan Pya 54.4 (7.8%), Gyophyu branch 7.8%, Thaketa / Set Yone 49.1 but 10.8% (Thaketa's foot is at a junction:
  could grow 1 sample only). QA `deck_clear` (roads05_qa): 1 left = Pinlon Road Flyover over water (short by 8.1; its
  deck is `kept`: no profile clears the water within 7.8% even grown 48; real bridge? check the satellite).
  deck_foot skips joints (another deck's end within the width at the same height).
- **deck_wobble (`roads05_fix.deck_fair`, after deck_regrade):** lateral + vertical Laplacian fairing (ends + 2 kept)
  only while the QA measure is over 0.15 / 0.14; plan moves ~0.3-2.7 studs.
- **median_cross 3 -> 0:** step 2 of fix clears a median MED_GAP before a deck segment that is AT GRADE (|y| < 3) unless it
  is the road's own deck carrying a median; QA median_cross counts a deck only at grade (a median under a deck is fine).
  `roads05_qa.deck_segs` / `AT_GRADE` shared.
- **overlap 1 -> 0 (`roads05_absorb`, BESIDE_GAP 3):** Bogyoke Aung San Road #2's middle (0-1 stud beside the road, its
  ends absorbed) is absorbed too; the road widens over it. Tried and turned off: ALONG_SHARE (pair any road with 25% of
  its area on another): kerb_cross 17 -> 23.
- **Deck_grade 7 left (all `short`, blocked by junctions):** Set Yone / Thaketa 0.108, Shwedagon Pagoda Rd 0.088,
  Thamaing Station Rd #2 0.119, Baho Rd 0.139, Parami Rd 0.088, Pansodan Bridge 0.098 (side lanes: never grows).
- **Studio test J16 (fc5f8868) builder bugs, geometry side, NOT done:** (1) Bahan / Roundabout 1 regression (holes at
  Lane #4701 x the ring arm, sawtooth nose, two kerbs): suspects ring_level / osm_joins / absorb near (35390, 37990);
  (2) kerb stubs inside the Kun Chan x Gyophyu box and a kerb scrap at the double junction (kerb_cross does not list
  them: kerbsim misses them; check scrub); (3) a 250-stud pavement strip with no road W of the double junction;
  (4) deck seams: the Sule fork joint (heights should now match: chain regrade) and the Shwedagon landing, slab joints in
  boxes; (5) Sule Pagoda Rd deck 93 wide = OSM: two one-ways tagged lanes 3 and 4 (x 10.5) + median; the deck takes 4 a
  side (should be 3 + 4 = ~84). deck_butt's fork widening is NOT what makes it wide (the raw deck is 41 / 52).
- **Block 2 builder items and corner radii (task items 3, 4) NOT started:** road_gap, kerb_gap, box_hole, fillet_no_kerb,
  flare_kerb_gap, corner_pave_gap, buried edges, open ends, corner pavement as one curved piece (YangonRoads.buildCorners:
  with r < walk the pavement's back edge collapses to the corner centre (math.max(r - w, 0)); the straight pavements are
  trimmed by inCorner piece by piece -> staircase / notch), bigger corner radii from the satellite (Sule Shangri-La / DBS
  first; CORNER_T 16 gives r = T tan(theta / 2), ~16 at 90 degrees: downtown wants 24-36 studs = 8-12 m).
- kerb_cross 17: mostly lanes at a shallow crossing with a route that outranks them by "ends on" rank, or lying a few
  studs along it (Lane #5208, #1426, #3486, #2693, #3130); see `qa.json`. Not fixed.

# Paint (PAINT agent): rules, QA counts, previews and what is left are in `roads05_HANDOVER_paint.md`.

# Studio test harness (J16, 18 Nov 2026, STUDIO TEST agent)
- Committed tool, no transcripts needed: `tools/yangon/city/roads05_studiotest.py [net dir] [paint.json]` (spots + cameras in its
  `SPOTS` / `CLOSE`, roads via roads05_jsubset, paint triangles clipped to each box, pack -> `imports/sync/roads05_studiotest.rbxmx`)
  + `tools/yangon/city/Roads05StudioTest.luau` (install / run / layPaint / cam / pick / clean; steps in its header). PATCH asset
  133014134133489, LoadAsset, `T.install(m)`, `T.run(spot)` one spot at a time (lifted 400, terrain fills to a no-op), `T.clean()`.
- J16 results, faults and builder bugs: `City Legends/2026-11-18 roads05 J16 studio test.md` (Bahan regression: 2 holes + side-by-side
  kerbs at Lane #4701; stray kerb stubs at Kun Chan and the double junction; deck fork / landing creases; Pazundaung Y sparse paint).

# roads05 handover (18 Nov 2026, eleventh pass: J15, GEOMETRY agent; DATA + BUILDER CODE, no Studio test: context)

## J15 geometry (this pass) -- counts J14 -> J15: see the table at the end of this section (`J15_qa.log`)
- Backups: `roads_unfixed_J14.json` (roads05.py output of J14), `qa_J14.json`.
- Deck grade (`roads05_fix`): WHY it jumped 7 -> 24 in J14: `deck_regrade` ran BEFORE `deck_smooth`, and the plan
  smoothing padded each deck end by repeating its end point, which bunched the samples next to it (same heights over
  a shorter run = steeper; all rows were at deck ends, grade 0.083 / step 0.62). Now: order deck_butt -> deck_smooth ->
  deck_regrade; the smoothing pads by point reflection (each end sample stays exact, spacing even), 3 passes, its
  3-stud cap itself smoothed, no ease back to OSM at the ends (that ease was a kink: lateral deck_wobble).
  `deck_regrade` rewritten: ramps at `DECK_G` 7% (raised to `DECK_MAX` 7.8% only for a crossing's clearance or the
  old top), the profile rounded by `_vcurve` (two 60-stud box filters on a 2-stud grid = vertical curves, no kink),
  the old top kept within 1 stud where 7.8% allows (rail / water bridges), clearance DECK_CLEAR over every ground road
  it crosses. A simple bridge (no side lanes) too short for that GROWS along its road (4 samples an end at a time, up
  to `DECK_EXT` 48) where no other road ends or crosses within its half + 12; the road's cut list grows with it. Still
  too short: the least grade over 7.8% that keeps the clearance, rounded (listed as `short` in fix.json chain.deck_regrade).
- Shwedagon Pagoda Road (`roads05.py` + `roads05_absorb.py`): OSM tags its southbound carriageway `lanes=4` (the whole
  road's count) and the northbound `lanes=2`, so the merged pair was 22.5 / 43.5 and the Phaya Lan bridge (own width)
  43.5 a side. A merged pair whose one side has >= 2x the other's lanes takes the smaller count both ways. absorb now
  picks the bigger road by OSM class first (rank only between equals): Shwedagon (primary) went INTO Lane #427
  (service) by "ends on" rank in J14; now the lane's alongside samples go into Shwedagon (service never widens).
- Block 2 (data side): `drop_stubs` (QA stub_in_grass: a road < 30 studs with an end on nothing goes; deck roads /
  side lanes kept), `width_taper` run again at the end (mouths / butts / repair changed widths after the first run).
  NOT done: road_gap, kerb_gap, box_hole, fillet_no_kerb, flare_kerb_gap, corner_pave_gap, seam_step, median_broken,
  buried-edge rule, kerb_cross 14 / median_cross 2 / overlap 1 / open ends, corner pavement as one curved piece.
- Flyovers (`YangonRoads.luau`): a pier is tested only on its own footprint (12 x 5 + 1 stud), not across the whole
  deck width (that found the ground side lanes under the deck edges and skipped piers over every median), and
  `onRoad` treats a spot on a divided road's median (s[9]) as not a lane: piers stand on medians, never in a lane.
  Ground junctions under flyovers: with v3 data only the deck's own road samples are cut (no 70-stud corridor), so the
  side lanes x crossing roads are ordinary junctions already; NOT checked in Studio.
- Downtown P3 (`roads05_fix.downtown_walks`, `median_styles`; builder `M.medianLook.paved / barrier / rail`): each P3
  road side's pavement runs to the building line (40th percentile of the kerb -> OSM building distance, rays 45 studs,
  kept <= 30 studs = 10 m; sides with buildings on < half the samples keep their walk). P3 medians: built half <= 2.25
  -> `medianStyle = "barrier"` (white concrete barrier 2.4 over the kerb top on a paved fill, a railing bar + a post
  per piece), < 6 -> `"paved"` (terrazzo-grey Concrete fill, paved noses), >= 6 stays grass. shortcut: by width, not by
  the satellite's colour. NOT done: bigger corner radii at Sule Shangri-La / DBS (builder corners).
- Traffic lights (`roads05_fix.signals`, last step): `data.junctions` = every junction (a road end on another road, or
  two centre lines crossing) within 25 m (75 studs) of an OSM highway=traffic_signals node, points within 40 studs one
  junction, >= 3 arms: `{x, z, signals: true, arms: [{road, i, dir}]}` (arm = sample i leaving the junction + unit
  direction away). Count: fix.json `signals`. Heads / phases not built yet (street_kit SGL poles at each arm's stop line).
- NOT run: the Studio J15 test (none of the brief's junction list, no shots), so the builder changes (median styles,
  piers, wide downtown pavements) are UNTESTED in Studio. The test harness (J7load / J7run / J7queue / J7pick) lives
  only in earlier transcripts: next pass, rebuild it into `tools/yangon/RoadsTest.luau` first.

- QA (`roads05_qa.py`): new `seam_step` (a continuation's joint vs its host's end: height > 0.1), `median_broken`
  (a median gone 1-3 samples away from any junction / cut), `signals` (a count of data.junctions).
- Counts J14 -> J15 (full net P1-P12, `J15_qa.log`; mouthsim 0 failed of 11,594): deck_grade 24 -> 8, deck_wobble
  29 -> 24, stub_in_grass 9 -> 0 (10 stubs dropped), width_wobble 3 -> 0, kerb_cross 14 -> 17, median_cross 2 -> 3,
  overlap 1 -> 1, paint_off_centre 2 -> 1, mouth_short real 2, mouth_over real 1, seam_step 0, median_broken 0,
  signalled junctions 247 (291 OSM signal nodes, 1,038 arms), downtown pavement sides widened 354, P3 medians barrier
  6 / paved 2. Shwedagon Pagoda Road: 21 / 21 two-way, 27 / 27 on the divided stretch and on the Phaya Lan bridge (was
  22.5 / 43.5), no absorb into Lane #427.
- Left in deck_grade 8 (all `short`, smoothed steep profile kept for clearance): Bayint Naung Bridge 2 (0.088, grew
  48 at one end), Shwedagon Pagoda Road (0.088, could not grow: junctions at both feet), Thamaing Station Road #2
  (0.138), Baho Road (0.169), Parami Road (0.088), Pansodan Bridge (0.098, has side lanes: never grows), Khayaypin
  Road (0.128), Hledan Pass Over Bridge (0.098). deck_wobble 24: now mostly LATERAL 0.2-0.6 a few samples in from a
  deck end (the plan smoothing's 3-stud cap + OSM corners); vertical rows only 0.15-0.153 (threshold 0.15).
- PROBLEM found after the run, NOT fixed (code tried and reverted, untested): where 7.8% cannot keep a bridge's old
  top, deck_regrade now LOWERS it (Thaketa Bridge -17.8, Myoma Kyaung -13.4, Lanmadaw -13.2, Set Yone -10.8, Alan Pya
  -10.3, Gyophyu -9.9, Sule Pagoda -7.7; no road under them). Over rail / water that may be too low: next pass, grow
  those decks too (treat "top kept" as a need that triggers growth, fall back to the lowered top only when growth is
  blocked), and check the railway clearance with the rail job.
- kerb_cross +3 / median_cross +1: not looked at (suspects: the wider downtown pavements, the Shwedagon re-pairing).

## Next (in order) -- plan is NOT ready for owner approval
1. Studio J15 test (main "City Legends" 121430381830562, no-terrain builder copy, lifted, scratch folder): the
   handover junctions + Yangon Central, Kun Chan x Gyophyu, a double junction, Sule Shangri-La corner, a downtown
   straight (barrier median + pavement to the facades), 2 under-flyover junctions (piers on medians), a deck run
   (Shwedagon at Phaya Lan: one width over the railway); overview / close-up / driver's-eye each.
2. Block 2 QA rules (list above) + corner pavement as one curved piece; Sule corner radii.
3. The decks still `short` (fix.json): longer decks need the ground profile fixed (Arzani's feet differ ~53 studs).

# roads05 handover (18 Nov 2026, tenth pass: J14, DATA + QA RULES ONLY: no Studio test this pass, context ran out)

## J14 (this pass) -- counts: see `J14_qa.log` (filled in below); backup of the J13 data: `roads_J13.json`, `qa_J13.json`
- Pipeline in one script now: `tools/yangon/city/roads05_pipeline.sh <label> [skip]` (skip = start at roads05_fix).
- Coverage (`roads05.keep_way` + `drive_link`): every service way but parking_aisle / drive-through (unnamed too),
  private and access=no compound / campus roads (motor_vehicle=no stays out), paved tracks (surface tag only:
  shortcut, the satellite was not checked; 73 untagged tracks stay out), driveways >= 180 studs (60 m) whose both ends
  are nodes of kept roads. Yangon Central station streets (186939494/5, 525722124, 614704889) are in.
  Dropped-ways overlays: `tools/yangon/city/dropped_overlay.py` -> `City Legends/2026-11-18 roads05 J14 dropped ways -
  P1..P12.png` + `- Yangon Central.png` (grey built before, green added, red still out). Added per district: P1 463,
  P2 438, P3 439, P4 537, P5 152, P6 515, P7 420, P8 462, P9 108, P10 157, P11 362, P12 194. Red left: parking aisles,
  short driveways, drive-throughs, untagged tracks. The owner's "big hall" and "lake" drawings were NOT located on the
  overlays (no coordinates in the vault): next pass, find them and check they are green.
- `roadnet.cross_section_1to1`: a narrow (alley / living / service / track) carriageway is at least 10.5 one-way, 16.5
  two-way. QA `carriageway_too_narrow` (per sample: one-way when its lanes fill its width; tapers left out).
- `roads05_absorb`: a service / track way alongside a road never widens it (its strip stays verge; owner ref `road
  width jumps`).
- `roads05_fix.width_taper` (WIDTH_RATE 0.15: a kerb offset changes <= 6 studs over 40) + QA `width_wobble`.
- Decks (`roads05.deck_crosses`): a raised run is a deck only when >= 75 studs (25 m) and its reach (run +- 150, 30
  wide) meets another road, a railway (rail / tram / disused / light_rail / subway) or a river / canal / lake; else it
  is ground road (stats.json `decks_dropped`). A deck with NO ground side lanes (a simple bridge: Shwedagon Pagoda Rd
  over the Circular railway at Phaya Lan) carries its road's own per-sample width / lanes / median (capped at lanes x
  laneW + median), no gore widening; flyovers (deck + side lanes) are unchanged (checked: 0 of the flyovers changed).
  The Circular railway itself is a LATER job: decks over it must leave room for the line underneath (DECK_CLEAR).
- `roads05_fix.deck_smooth`: deck plan line moving average (7 each side, ends + 3 samples fixed, <= 3 studs = 1 m from
  OSM), directions recomputed. Profile NOT smoothed (it broke deck_regrade). QA `deck_wobble` (lateral 2nd difference
  over 0.2 against a 4-sample chord, vertical over 0.15).
- Paint (`roads05_paint`): an undivided two-way road's centre line on the carriageway's middle ((wr - wl) / 2, not the
  data centre line); lane lines spread evenly over each direction's real half; `neff`: more lane lines where a
  direction holds more 12-stud lanes (no bare strip). QA `paint_off_centre`, `unmarked_strip`.
- Zebras: owner decided YELLOW faded ochre (230, 190, 110): paint kind `LZ` (roads05_paint, roads05_bake,
  YangonRoadMeshes). Noted in the Playbook research note.

## Next (in order) -- plan is NOT ready for owner approval
1. Shwedagon Pagoda Road: raw roads05 makes 137 samples (22.5 / 43.5, 4 lanes, mb 1.5): a one-sided pair merge, and
   roads05_absorb then absorbs Shwedagon Pagoda Road INTO Lane #427 (rank inverted). Its bridge deck is 43.5 a side.
   Owner: one constant width along it, verge strips green. Same family: QA width_wobble rows, paint_off_centre rows.
2. Owner ADDs not started (coordinator, 18 Nov):
   - Sule Shangri-La / DBS junction (refs `Owner ref - Sule Shangri-La corner (...)`): big sweeping corner radii
     (OSM kerb / turn radius, else satellite: 8-12 m downtown), side street flaring, kerbed triangle island (red / white
     kerb, red paving), wide tiled forecourt to the building; no loose slab / kerb scraps. Add to the Studio test with a
     driver's-eye shot next to real 1.
   - Downtown (P3 and wherever the satellite is grey to the facade): pave kerb -> building line (grey / white tiles,
     trees in pits at the kerb), no grass verges.
   - Ground junctions UNDER flyovers (Univ x Kabar Aye, Hledan, Bayint Naung, Pyay Rd): a full ground junction
     (box, corners, kerbs, pavements, zebras, stops) from ground roads only; a deck removes only its pier footprints and
     ramp walls; no ground paint / kerb / pavement inside a ramp footprint; piers on medians / between carriageways,
     never in a lane. Studio test: + Hledan or Pyay Rd flyover, a low shot under the deck + overview with deck hidden.
   - Decks: parapet follows the deck edge at constant height; QA `paint_snake` (not written yet); a driver's-eye shot
     along each test deck. Deck pieces join with no gaps; a split deck splits cleanly.
   - All of the original block 2-6 list (task brief): road_gap, kerb_gap, box_hole, fillet_no_kerb, flare_kerb_gap,
     corner_pave_gap, seam_step, median_broken, buried edges; arrow_missing, stopline_wrong_side, dash_jog,
     dash_side_by_side, paint_in_median, zebras inside a double junction; downtown barrier / terrazzo medians, yellow
     kerb edge lines; 7 steep decks (now see deck_grade), open ends, kerb_cross 14, median_cross, 4 merged
     different-named pairs; traffic signals in roads.json; Studio test + shots; overlays (road_overlay.py).
3. J14 counts (J13 -> J14, full net, `J14_qa.log`): roads 5,589 -> 8,565, mouths 7,934 -> 11,582 (mouthsim 0 failed),
   carriageway_too_narrow (new) 0 (570 under the first, wrong rule; real narrow alleys fixed in roadnet),
   paint_off_centre (new) 2, unmarked_strip (new) 0, width_wobble (new) 3, deck_wobble (new) 29 (plan smoothed; the
   rows are mostly VERTICAL: the profile is per-sample; with the profile smoothed it was 7 but deck_grade went to 26),
   deck_grade 7 -> 24 (NOT the smoothing: the rows have grade 0.089 / step 0.98 at deck ends; check deck_regrade with
   the new deck set / own-width bridges FIRST), deck_foot 0, kerb_cross 14 -> 14, median_cross 1 -> 2, overlap 0 -> 1
   (Bogyoke Aung San Road x Bogyoke Aung San Road #2 ~2), mouth_short real 2 -> 2, mouth_over real 1 -> 1,
   stub_in_grass 7 -> 9, street_no_pave 0. Decks 53 -> 52: 5 flyovers (deck + side lanes, unchanged) + 47 simple
   bridges; dropped as ground road: Thamaing Station Road (95-stud hump, no road / rail / water within reach).

# (J13 pass below)
# roads05 handover (18 Nov 2026, ninth pass: J13, DATA ONLY: no Studio test this pass, context ran out)

## J13 (this pass)
- `roads05_fix.py` (backup of the J12 data: `roads_J12.json`, `qa_J12.json`):
  - `osm_joins` (after ring_level): an end OSM joins to another way (an OSM join node within 12, or our end inside an
    OSM way) that stops 0.9-12 beside a carriageway is bent onto that road's centre line (smoothstep over
    max(40, 4 x move); a wide road: own half + 2 inside its edge), an end running past a bigger road is cut back to
    where it crosses that road's centre line, an end on a smaller road's centre line in its cut gap runs across it.
    41 ends (21 cut back, 20 bent). University x Kabar Aye: Lane #1013 / #1008 / #1014 / #961 cut back onto Kabar
    Aye #5 / #6 (now mouths). 9 stubs left wholly on another road went (check(): duplicates_dropped).
  - `ring_level` rewritten: flat at c.y to r_out + 4 + RING_FLAT, then scale-easing with the change spread evenly
    along each road between PINNED samples (flat ones, junction samples shared with another road, ramp end): shared
    samples keep one height. Ramp per ring 100 -> 300 until the easing adds no segment over RING_GRADE 5% (unless
    the road already was): results R1 5.3% (U Htaung Bo, own 4.3%), R2 ok, Sule 6.7% (32nd Street, own 5.4%), R11
    7.4% (Lane #489, own 6.4%), others 0. So: no eased road over 5% unless the DEM road itself is >= 5.4%, then
    +1.0..1.3% at most. The ring's reach goes to the builder as `roundabouts[].level` (YangonRoads verge air clear).
    `RING_MODE=fade` (per-sample step fade) is kept as an option; it was worse at Sule west (8%).
  - `deck_regrade`: decks re-profiled at <= 7.8% where that is no worse and keeps the old clearance or 4.5 m
    (DECK_CLEAR 13.5) over each road below; feet = their road's height. deck_grade 24 -> 7 (the 7 need longer decks:
    roads05.py deck span; Arzani's feet differ 53 studs), deck_foot 1 -> 0.
  - `deck_butt` (owner ref `broken flyover deck ends (P3)`): deck ends that meet: a continuation fits the host's
    end; a FORK (Sule Pagoda Road's deck -> Alan Pya Pagoda Road's + Gyophyu Road's by Yangon Central) widens the
    host's end to span both branches (taper over 40) and each branch starts exactly on that line.
  - owner overrides (`OWNER_GORES`, `OWNER_MEDIAN_OFF`): Kun Chan Road x Gyophyu Road (36350, 42490) by Yangon
    Central: the gore between the links is one asphalt area (`data.fills`), Kun Chan Road's median cleared within
    140 of its west end (owner drawing `junction wrong shape`).
- `YangonRoads.luau`: `data.fills` = asphalt gores (buildIslands("fills"), folder Fills, no kerb / pavement / corner
  inside: sideZone + findCorners); ring `LEVEL`; ramp walls (owner ref `jagged flyover walls`): a tilted parapet
  band + an upright wall + a WedgePart for the rise, 0.05 inside the band's faces (was one tall tilted block).
  NOT TESTED IN STUDIO (wedge orientation: thin end must be at the LOW end; check first).
- `roads05_kerbsim.py`: a short stub whose OTHER end is its mouth on a road is not "running past" it; an end on
  another road's centre line is no gap (a T on a sharp bend: the quads fold); a far kerb over a mouthing street's
  data run-on is not kept-kerb-on-carriageway (the builder stops that street at the near edge).
- `roads05_qa.py`: `osm` on every mouth row ("dead end" = joined in OSM only to ways roads05 does not build;
  "join"; "off"), `real` counts; new `stub_in_grass` (< 30 studs, an end on nothing), `street_no_pave`.
- QA (full net) J12 -> J13: mouth_short 46 -> 17 (real 32 -> 2: Sagawar 2 street gap 1.0, Lane #4587 gap 2.7; 15 OSM
  dead ends), mouth_over 38 -> 16 (real 19 -> 1: East Horse Race Course Road (Bridge) on Banyar Dala #3, a deck foot;
  15 OSM dead ends), kerb_cross 22 -> 14, median_cross 1 -> 1 (Aung Yadana Street under Baho Road Flyover),
  deck_grade 24 -> 7, deck_foot 1 -> 0, mouthsim 0 failed of 7,934, stub_in_grass 7 (new), street_no_pave 0.
- Yangon Central (owner refs `Alan Pya ...`, `Yangon Central area`): in roads05 Alan Pya Pagoda Road and Gyophyu Road
  (Google: Zoological Garden Road) are already two separate one-way decks over the railway (the merged bridge is the
  OLD game build). OSM around the station: every public way is built; the station / rail-yard streets the owner drew
  are OSM `service` (no name, no access tag: 186939494/5, 525722124-7, 614715535-42, 614704889 east of the road):
  not built by the rule then in force; the coordinator's later "any road the owner draws is real" + "widen keep_way"
  items (below) cover them. The railway (owner's yellow) is not ours: the bridges must span a railway cut later.
- absorb merges 4 different-named pairs side by side (Thamaing Station Road -> Bayint Naung Bridge 2, Kyimyindaing
  Strand -> Kyimyindine Kannar #5, No. 2 Main Road -> Lay Daungkan #2, Lane #88 -> Road #14): un-merging needs them
  narrowed to sit side by side (else overlap / flicker): NOT done.
- Overlays NOT regenerated this pass (road_overlay.py, see J12 command in overlay_J12.log's pass).

## Next (in order) -- plan is NOT ready for owner approval
1. Studio J13 test (harness: J12 transcript calls #14-#20, #164-#169; `roads05_J7/junctions_J13.json` adds
   `ycentral` (36120, 42950), J7Rad 560: covers junction 8 (Alan Pya / Gyophyu fork + decks climbing, running,
   landing) and junction 9 (Kun Chan gore, 36330, 42480)). Check: wedge walls, deck fork, Kun Chan fill, Univ x Kabar
   Aye (island-7 1-stud hole: data changed round it; look again).
2. Coordinator ADD list (owner refs in `City Legends/Owner ref - *`), none done yet:
   - paint/QA rules: arrow_missing, stopline_wrong_side (+ one junction box for roads < 40 apart crossing one road:
     no zebras / stops inside, ref `double junction zebras`), dash_jog, dash_side_by_side, corner_pave_gap,
     flare_kerb_gap, fillet_no_kerb, kerb_gap, box_hole, road_gap, median_broken, paint_in_median, width_wobble,
     seam_step, carriageway_too_narrow (ref `lane with no carriageway`: find the root), buried edges = kerb_cross
     truly 0 + Studio raycast grid + driver's-eye shot per junction, zebra orientation.
   - keep_way widening (residential / unclassified / living_street / service except parking_aisle and drive-through,
     long driveways joining two roads, paved tracks) + a dropped-ways overlay per district (refs `missing streets by
     big hall`, `missing lanes by the lake`, `stub road and kerb gaps`); any road the owner draws is real.
   - median style per area (downtown: white concrete barrier + railing, yellow edge lines; ref `Sule Square road`),
     width smoothing (ref `wavy road edges`), corner pavement as one curved piece (ref `jagged corner pavement`).
   - test junctions 10 (double junction), the big hall block, the lake lanes, a taper, a bell mouth, a crossroads, a
     downtown straight, a long straight median.
   - ref `median nose at Sule Shangri-La`: downtown / wide medians PAVED (terrazzo-pattern MaterialVariant, plain grey
     kerb, no extra parts) where the satellite is grey, grass only where green; zebra colour: check 5+ real 2019-2026
     photos (downtown, Pyay Rd, Kabar Aye) and note it in `Roblox Playbook/2026-11-13 Research - Yangon road look.md`;
     the median-end lamp poles belong to the street-detail layer.
3. Remaining J13 rows above, the 7 decks, the 4 different-named absorbs.
4. Traffic lights (owner: "we need traffic lights too"), the step right after the road rebuild: mark each junction
   with an OSM highway=traffic_signals / crossing=traffic_signals node within ~25 m of its box as `signals: true` with
   its arms in roads.json (roads05_paint.py already finds them: "signals 291" in its log, P1-P12), heads at each
   approach's stop line from `city/street_kit.py` SGL poles, phases as the old map's (`CityLayout` phases,
   `Traffic.lua` red-light stops). Not recorded in roads.json yet.

# (J12 pass below)


## J12 (this pass)
- `YangonRoads.luau`:
  - `findCorners`: a road-on-road corner whose arc leaves either kerb polyline's pavement side by > 0.3 is made again
    with T x 0.75 (up to 8 times, `M.crossShort`). A radius cap (r <= 30) was tried and REVERTED: in a shallow merge
    both straight kerbs are cut round P anyway, and only the long arc covers that stretch (a 30-stud kerb gap).
  - `buildCorners`: `ebY(j)`: a cut sample's edge height = the nearest uncut edge + the change of the data's centre
    height (bPts can hold cut samples via cutPair: Bahan's corner pavement was ~4 low). Used for yB and the asphalt.
  - `scrub`: a kerb / pavement piece inside one of its own road's corners (inCornerPoly, tol 1.2) is not scrubbed
    against that corner's big road. The big road's built edge runs in chords between samples, onCarriageway uses the
    true width: Lane #4701's merge arc on Kan Yeiktha (68 wide, bending) lost its last kerb pieces = the Bahan notch.
  - `RING_RAMP` 104 -> 144 (verge air clear follows ring_level).
- `roads05_fix.py` `ring_level`: flat at c.y out to r_out + 4 + `RING_FLAT` 40, then the 100 ramp (Sule max change
  4.99 -> 6.55). Sule's "seam" was a crease: 32nd Street crosses Maha Bandula #2 ~30 off the ring at +1.3, the
  builder's junction height held Maha Bandula 0.7 over the ring until 4 studs from its edge. The two dark wedges on
  32nd Street went with it.
- Tried and reverted in roads05_fix: running OSM-joined unreached ends on along their own direction (34 ends): no
  QA row went (they meet the road side-on), +2 rows.
- QA (full net, after fix / mouthsim / paint / QA): mouthsim 0 failed of 7,926; mouth_short 46, mouth_over 38,
  kerb_cross 22, median_cross 1, deck_grade 24, deck_foot 1 (unchanged). Paint rows all 0.
  `qa_J12_osm.json` = every mouth row vs OSM (nearest OSM way end within 3 studs; shared node = join):
  mouth_short 14 OSM dead ends (real, explained) + 30 OSM joins + 2 not at an OSM end; mouth_over 19 OSM dead-end
  stubs past a road (real) + 19 OSM joins. The OSM-join rows are the work left: mostly a street ending beside or
  across a merged dual carriageway (it joins the FAR carriageway in OSM, or meets a frontage road side-on), and
  rank-inverted Ts (Independence Street r4373 on Bayint Naung r4702: the builder only mouths a smaller road on a
  bigger). University x Kabar Aye's Lane #1013 / #1008 / #1014 / #961: OSM joins them to Kabar Aye's carriageways
  (2 secondaries share the end node); in our data they end 6-7 studs beside the frontage side lanes #5 / #6 and the
  end direction runs along them (no run-on reaches): needs a merge taper (bend the last ~40 studs onto the frontage).
  kerb_cross 22, median_cross 1, deck_grade 24, deck_foot 1: not worked on.
- Overlays regenerated (`overlay_J12.log`), paint regenerated.
- Studio J12 (no-terrain copy, lifted 400, bahan_ring +-300; saved v1181, "Saved new changes" 02:00:02Z, lock
  released, no data modules / scratch / scraps / YangonRoadsJ7 left; ClaudeTools.YangonRoads = repo, checksum
  1343122940). Shots `City Legends/2026-11-18 roads05 J12 test - *.jpg` (final build only). 0 MOUTH FAILED everywhere.
  - PASS: Bahan (kerb continuous through the merge, pavement level), Sule (seam + wedges gone), Hanthawaddy,
    Waizayandar slips, Bogyoke x Pazundaung Y (a ~1-stud pavement notch on the NW corner's back edge, as in J11).
  - Pyay x University: the SE "gap" is the open gore between Pyay (Prome) Road's and Pyay Road #9's pavements as they
    diverge (4 studs, opening to the south): the verge (terrain, skipped in the test) fills it with grass in the game.
    Left: a ~1-stud notch on the north pavement's back edge (by the grass).
  - University x Kabar Aye: NOT clean: a 1-stud hole between Lane #1013's kerb (0..0.9) and the west island's fill
    (starts ~1.5-2 in, 0.5 under the kerb top) along island 7's SW edge (islandOutlines[7] runs ON the kerb line, so
    the gap comes after the outline: earClip / loop cut / heights? check the Islands parts there), plus the lane ends
    by the deck (above). The same marks are in the J11 shot that was called a pass.

## Next (in order)
1. University x Kabar Aye island-7 hole (buildIslands); then the merge taper for the 4 Kabar Aye lanes in roads05_fix
   (OSM join beside the road: bend the end onto the frontage, then mouthsim / repair).
2. The other OSM-join mouth rows (qa_J12_osm.json), kerb_cross 22, median_cross 1, deck_grade 24, deck_foot 1.
3. Studio again (same 7). Plan is NOT ready for owner approval.

# (J11 pass below)


## J11 (this pass; YangonRoads + kerbsim only, no data change: roads.json / qa.json are the J9 ones)
- `YangonRoads.luau`:
  - `findCorners`: (a) an edge that never meets the big road's uncut kerb tries again with the cut samples next to an
    uncut one (2 into the cut; `M.cutPair[road|big]`): Lane #4701's nose on Bahan Road. (b) corners are collected
    first; two corners of one road side from different mouths whose runs P..TA overlap: the bigger one is made again
    with T halved (`corner.rebuild`) until clear, else dropped (`M.overlapShort` / `M.overlapDropped`): Lane #470
    (Insein -> Hledan slip at Pyay) had an r 96 arc running back over its Insein corner (the two kerbs side by side).
    (c) a road-on-road corner whose P lies inside a ring (RING_V) is dropped (Hanthawaddy Road #2: kerb speck on the ring).
  - `sideZone`: the other road's half on THIS spot's side (s[7] / s[8]; halfAt = the wider: Maha Bandula #2 is
    39.6 / 21 at Sule); skip test `max(72, half + 12)` (Bahan Road is 76 wide at Roundabout 1: 72 skipped it);
    `M.inIsland` (data.islands kerb-line outlines): no band PAVEMENT inside an island; with cutPair the big road's plain
    centre line counts behind its cut end.
  - `buildIslands`: one fill to the kerb line (straight vertices not moved in; at a corner kerb point -> inner arc
    -> kerb point, or kerb -> O where the walk is wider than r). The bands' own pavements overlapped there at their
    roads' different heights (dark streaks, steps, sliver holes in the Waizayandar and Pyay islands).
  - `ownedBy`: never inside one of the road's own mouth spans (noSlab), never on a bigger road's carriageway + kerb
    (Lane #470's Insein corner owned its band 60 studs on into Hledan: pavement teeth + the kerb speck; Maha Bandula
    #2's ring corner owned 32nd Street's kerb away at Sule).
  - `onCarriageway` (scrub): own-side half too (it deleted Lane #17's corner kerb on Lay Daungkan #2's narrow side:
    the sawtooth pavement break at the slip triangle).
  - `buildMouth`: a mouth whose edge has to snap retries with B taken 2 samples into the big road's cut.
- `roads05_kerbsim.py` side_zone: same own-side half and skip test. Full net: kerb_cross 22, mouth_short 46,
  mouth_over 38 (unchanged).
- mouth_short at University x Kabar Aye (Lane #1013 / #1008 / #1014 / #961): kerbsim AGREES with the builder: the
  builder has no mouth there either (Kabar Aye Pagoda Road is not in `near` there; the lanes end 6-7 studs from the
  frontage roads #5 / #6). The junction looked fine because those ends sit by the University Ave deck. Data question,
  not a kerbsim bug: should those lanes join the frontage roads (OSM)? Not changed.
- Test harness (J7load / J7run / J7queue / J7pick) is in this pass's transcript; J7run now takes `_G.J7Rad[name]`
  (bahan_ring 300): at +-260 Lane #4701's Kan Yeiktha mouth (its end sample at z 38177.8) was outside the test box,
  so its slab was never laid: the "hole" by the slip end was a test-box artifact.
- Studio J11 (no-terrain copy, lifted 400, `Roads05Test`; saved v1175, "Saved new changes" 01:32:23Z, lock released,
  no data modules / scratch / scraps / YangonRoadsJ7 left; ClaudeTools.YangonRoads = repo, checksum 743589837).
  Shots `City Legends/2026-11-18 roads05 J11 test - *.jpg`. 0 MOUTH FAILED everywhere; overlap corners 6 shortened,
  1 dropped (test subset); cut-sample corners 3.
  - PASS (close-ups too): University Ave x Kabar Aye, Hanthawaddy (ring speck from J11's own run fixed), Bogyoke x
    Pazundaung Y, Waizayandar slips (island marks + NE sawtooth break gone).
  - Pyay x University: NW kerbs side by side, island streak and kerb speck GONE. Left: a tiny blue gap between the
    south-east island and the deck's side wall (islands close-up, lower right), a small kerb step on the north pavement.
  - Bahan: nose rounded, the loose nose piece and the west-arm notch gone. Left: where Lane #4701's r 101 merge corner
    meets Kan Yeiktha's kerb (slip end close-up, lower right): 16 corner pieces scrubbed (the arc dips onto Kan
    Yeiktha's carriageway near TB) and the corner pavement there sits ~4 studs low (yB from Kan Yeiktha's edge
    height at bPts j 6-7, next to its ring cut: check `bY`). Idea: cap a corner's r (T = R_MAX / tan(theta / 2))
    on shallow merges, and take yB from the ring-levelled edge.
  - Sule west: the island's 32nd Street kerb is back. Left: a straight seam between Maha Bandula #2's slab and the
    ring's (west close-up, x ~645 px), 32nd Street's west pavement has two small dark wedges north of Maha Bandula.
  - University x Kabar Aye close-up: a thin dark sliver along the west island's deck side: check it was there in J10.
- QA counts (no data change): mouth_short 46, mouth_over 38, kerb_cross 22, median_cross 1, deck_grade 24, deck_foot 1.
  Plan is NOT ready for owner approval.

## Next (in order)
1. Bahan merge corner near TB (above), Sule seam + 32nd Street wedges, Pyay deck-side gap.
2. QA rows: mouth_short (the Kabar Aye lanes are a data question, see above), mouth_over, kerb_cross, median_cross,
   deck_grade / deck_foot. kerbsim still does not model corners / islands / cutPair.
3. Then Studio again (same 7, bahan_ring at +-300).

# (J10 pass below)


## J10 (this pass; YangonRoads only, no data change: roads.json / qa.json are the J9 ones)
- `YangonRoads.luau`:
  - `inCorner`: the wedge test (rin .. rout = |P-O| + margin) reached across a narrow joining street onto its FAR
    kerb (Lane #468 at Hledan: a 9-stud kerb + pavement gap on the slip). Now also inside the polygon O, TA .. P .. TB
    (the corner's kerb chain, `kerbChain` / `M.inCornerPoly`) or within 1 stud of the chain (ring corners as before).
  - `ownedBy`: the "past the corner this road owns its band" width used M.WALK 7.5 for a 4-stud street: it deleted
    3.5 studs of the other road's band at an island tip (a hole). Uses the road's own walkL / walkR now.
  - `buildIslands`: a kerb-line vertex between T and P (on that corner's own kerb chain) is the corner's (a mitre point
    on the corner pavement folded the outline: the square hole); where a walk is wider than r the outline goes on past
    O to the straight band's inner corner (Q); fill heights = the builder's kerb-line heights (`debugEdges`) and the
    corner's yA..yB (were the sample's centre y: 0.2 steps); loops where two bands' inner edges cross before a corner
    are cut at the crossing (island 5 at Pyay was hollow); tiny triangles standing on edge are flattened.
    `M.islandOutlines[i]` keeps each fill outline (debug).
  - `verge`: within r_out + RING_RAMP + 8 of a ring the straight verge also clears the air above it (as the corners
    do): ring_level lowered Sule's west arms up to 4.4 studs, the ground beside them stood over the pavement.
- ring_level vs terrain (check 5): 135 moved samples raycast against the main place's terrain: road - terrain is 1 to 6
  studs (main place terrain was carved for the OLD roads, ~3 under them). Raised samples (up to +5, Sule east) sit
  within the verge fill's reach (10 studs under the road top - 1.7): no float. Lowered samples (up to -4.4, Sule west,
  Bahan -2.4) had ground standing over the pavement: fixed by the verge air clear above. Not checked in a real build.
- Studio J10 (same harness as J9: `_G.J7load/J7run/J7queue`, code in the J9 subagent transcript; no-terrain copy,
  lifted 400). Shots `City Legends/2026-11-18 roads05 J10 test - *.jpg`. 0 MOUTH FAILED everywhere.
  - Pyay x University: the slip pavement gap, the square hole and both tip holes are gone, all 5 islands paved.
    LEFT (close-up `... J10 test - Pyay west close-up.jpg`): Lane #470's corner kerb meets Hledan's straight kerb with
    a notch and the two kerbs run side by side for a few studs (north-west corner); a dark streak inside island 4
    (a steep fill triangle?); a white kerb speck on the asphalt west of island 4; faint seam lines in island fills.
  - Waizayandar slips, Sule, Bahan: see the shots. Not worked on in close-up this pass except as below.
- Diagnosed, not fixed:
  - Bahan nose: Lane #4701's side -1 edge crosses Bahan Road's right edge between Bahan samples 7 and 8 (Bahan 1-7 are
    the ring cut; its right half is 76 there, the absorbed second carriageway), slip samples 28-29. findCorners only
    takes uncut big-road samples into bPts, so that side has no corner and the slip's kerb runs across Bahan
    (QA kerb_cross row "Lane #4701 on Bahan Road side -1 (35358, 38004)"). debugEdges exist for cut samples, so
    letting bPts take the one cut sample next to an uncut one is possible, but TB then lies inside the ring's zone:
    needs the ring's kerb as the corner's B side there (or end the slip before the ring cut in roads05_fix).
  - Sule west (OSM close-up `Road plan - Close-up Sule Roundabout (Roundabout 4) overlay.png`): 32nd Street really
    runs ~30 studs west of the ring with two real diagonal links (Lane #2533, Lane #4568) and Maha Bandula from the
    west; the satellite shows two small kerbed green triangles there. So the islands are real; the scrub moved
    153 + 264 pieces of those links' kerbs off 32nd Street / Maha Bandula #2 (their bands cross the other roads).
  - QA mouth_short: 4 of the 46 rows (Lane #1013 / #1008 / #1014 / #961) are at University x Kabar Aye, which PASSES in
    Studio: kerbsim's no-join rule disagrees with the builder there (MOUTH_SNAP?). Check kerbsim against Y.mouths before
    "fixing" the data.
- QA counts unchanged (no data change): mouth_short 46, mouth_over 38, kerb_cross 22, median_cross 1, deck_grade 24,
  deck_foot 1. Plan is NOT ready for owner approval.

## Next (in order)
1. Pyay north-west corner (Lane #470 on Hledan: two kerbs side by side + notch), island 4 streak, the kerb speck.
2. Slip triangle and the other shots' marks (list them with `_G.J7pick(campos, target, {{px,py}...}, folder)`:
   it turns screenshot pixels into world points + the part hit: define it again, it is in this pass's transcript).
3. Bahan nose (above), Sule west links' bands.
4. kerbsim vs builder on mouth_short; then the QA rows, deck_grade / deck_foot.

# (J9 pass below)


## J9 (this pass)
- `YangonRoads.luau`:
  - `sectors()`: two arms overlapping at the ring (Hanthawaddy Road + Road #2, one-way, 8 studs on top of each other)
    gave a stretch b0 < a0 that the old wrap turned into 352 degrees of ring kerb / pavement over every arm (scrub
    hid most of it: the "kerb points"). Each end is now taken next to its own arm's centre; overlapping arms = empty.
  - corners: a corner whose P lies on a third road's carriageway is dropped (that wedge is asphalt); a mouth keeps
    the corner on its good side when the other side's edge never meets the kerb (was: both dropped); cornerSpan per
    side (missing side = the arm's own edge angle); ring corners get r >= `CORNER_R_MIN` 3 by a longer T (<= 48).
  - corner pavement tapers from this road's walk at TA to the other road's at TB (streets are 4, the arc was 7.5).
  - `buildIslands()` (stepCell + step 5, after buildCorners): paves `data.islands` exactly inside the bands and
    the corners' inner curves (folder `Islands`).
- `roads05_fix.py`: `ring_level` (every sample within r_out + 4 + 100 eases to the ring's height: Sule's arms were
  up to 4.99 studs off, R1 2.4, R2 2.7, Hanthawaddy 1.7, R11 2.0: steps at the ring edge) and `islands` (181 small
  holes in the carriageway union, < 2,500 studs^2, that the bands leave open: kerb-line outline + each edge's walk).
  `roads05_jsubset.py` copies the islands near the junctions. Backup of the J8 data: `roads_J8.json`, `qa_J8.json`.
  mouthsim 0 failed (218 joins in the test subset, 0 network-wide after repair).
- Studio J9 (same 7 junctions, no-terrain copy, lifted 400; saved v1166, "Saved new changes" 00:08:44Z, lock released,
  no data modules / scratch / scraps left; ClaudeTools.YangonRoads = repo, checksum 412598751).
  Shots `City Legends/2026-11-18 roads05 J9 test - *.jpg`. 0 MOUTH FAILED everywhere.
  - PASS: University Ave x Kabar Aye (3 islands paved); Hanthawaddy (points gone); Bogyoke x Pazundaung Y.
  - Pyay x University: islands paved; LEFT: a pavement gap where a slip's corner (Lane #468 on Hledan #3, r 6.2)
    meets the straight band, a small square hole in an island fill near its kerb, faint step lines inside fills
    (fill height = the sample's y; bands follow the builder's edge heights).
  - Waizayandar x Lay Daungkan: islands paved but with holes / dark marks (same causes).
  - Sule: west side (32nd Street runs 12-20 studs off the ring; Maha Bandula #2, Lane #2533, Lane #4568 join the
    ring there): a kerbed scrap island and broken slips. Not looked at after ring_level in close-up.
  - Bahan at Roundabout 1: island nose still notched: Lane #4701's gore edge meets Bahan Road only inside Bahan's
    ring cut (samples 1-7), so that side gets no corner; it needs a nose against the ring / a gore cap.
- NOT done: QA rows (kerb_cross 22, mouth_short 46, mouth_over 38, median_cross 1), deck_grade 24, deck_foot 1.
  Plan is NOT ready for owner approval.

## Next (in order)
1. Pyay / slip triangle: the band gap at a slip corner (why does Lane #468's band stop short of TA? the band's
   pieces are cut by sideZone into hundreds of 0.2-stud bits there); fill heights from the builder's edge heights
   (`M.Roads.debugEdges`) instead of the sample y; find what makes the square hole (an island vertex that cornerOf
   misses, so its mitre point lands on the corner pavement).
2. Bahan nose: a gore cap where a slip's edge meets the big road only in its ring cut.
3. Sule west: close-up after ring_level; 32nd Street vs the ring band.
4. QA rows, deck_grade / deck_foot (untouched since J7).

# (J8 pass below)

## J8 (this pass)
- `roads05_fix.py`: `ring_clear` (Lane #4701 pushed out 6.7 studs at most by Roundabout 1, so its inner kerb clears the ring's
  pavement: the sawtooth is gone) and `butt_match` (after repair; 20 single continuations start on their host's full end
  cross-section, tapering back over 40 studs: the Bogyoke x Pazundaung Y has asphalt in the gore now). Backup of the J7
  data: `roads05_P1.._P12/roads_J7.json`, `qa_J7.json`. mouthsim: 0 failed of 7,926. QA counts unchanged (QA does not
  count either fault): mouth_short 46, mouth_over 38, kerb_cross 22, median_cross 1, deck_grade 24, deck_foot 1, the rest 0.
- Studio J8 (same 7 junctions, no-terrain copy, lifted 400, saved v1163, "Saved new changes" 23:23:32Z, lock released,
  no data modules left). Shots `City Legends/2026-11-17 roads05 J8 test - *.jpg`. 0 MOUTH FAILED everywhere.
  - PASS: University Ave x Kabar Aye; Bogyoke x Pazundaung Y (gore filled).
  - Bahan Road at Roundabout 1: sawtooth gone; the island NOSE where Lane #4701 splits off is still notched (a stepped
    pavement end, the slip's inner kerb starts late). Needs a round nose (a corner between two diverging roads).
  - Hanthawaddy / Sule: ring corner points unchanged (not worked on). Diagnosis: Hanthawaddy Road #2 side -1 has a corner
    of r 1.64 (an arm meeting the ring at ~8.5 degrees: T 22 x tan(theta/2)); the arc kerb wraps a 1.6-stud nose.
  - Pyay x University, slip triangle: island insides unpaved + small pavement breaks (not worked on). Satellite: the
    Pyay x University islands are paved concrete (zebras run onto them) -> fill islands with pavement.
- NOT done this pass (in order): ring corner points (try a minimum corner r ~3 by raising T on sharp wedges); island
  fill + pavement breaks; diverging nose; QA rows; deck_grade / deck_foot. Plan is NOT ready for owner approval.

## Third pass (J7)

Owner rule: NO full rebuild / swap in Studio until the owner approves the overlays. Studio is clean (no Roads05_* data
modules, no Roads05Test, no YangonScraps, no YangonRoadsJ7), saved v1161 ("Saved new changes" 22:39:33Z in the Studio
log), lock released. ClaudeTools.YangonRoads in Studio = the repo file (129,443 chars, checksum 449780513).

## Pipeline now (run from `tools/yangon/city`, `YANGON_SCALE=1to1`, NET = roads05_P1_..._P12)
1. `roads05.py P1 .. P12` (~10 min) -> NET/roads.json. One deck per raised run now (`DECK_GAP` 400: Lay Daungkan's two
   real bridges 12 km apart had made ONE 12 km deck over every ground junction between them; Kabar Aye the same).
   After a new roads05.py run delete NET/roads_unfixed.json (roads05_fix moves roads.json there only when it is absent).
2. `roads05_fix.py <tag>` (~2 min), in order: chain -> continuations (reach 12 -> 40; the trim is `roads05_chain.butt`)
   -> `roads05_absorb.py` (doubled carriageways: the smaller road's alongside samples go, the bigger road widens to its
   outer edge, leftovers of 8+ samples stay; also a one-way route lying half on another) -> drop_dups (roads the builder
   would drop as lying wholly on a bigger one, and the continuation flags naming them) -> mouth run-on ->
   `roads05_repair.py` (each join mouthsim still fails gets the smallest edit the builder's own edge walk accepts: corner
   run-on of the bigger road, run on, pull back, butt continuation, "square end under the deck") -> medians -> `check()`
   (what YangonRoads.load needs: unique names / ranks, decks / cuts in range, every ring arm reaching past R_OUT + 12; a
   3-sample ring stub made Y.load error "attempt to index nil with number").
3. `roads05_mouthsim.py NET` (SNAP 50 = `YangonRoads.MOUTH_SNAP` 50 now).
4. `roads05_paint.py` (~90 s) ends with `tidy()`: every polygon clipped to its own surface (ground / deck), off the
   medians, never on a polygon laid before it (ORDER: stop, zebra ... arrow).
5. `roads05_qa.py <tag>` (~10 min): mouth_short / mouth_over / mouth_edge / kerb_cross now come from
   `roads05_kerbsim.py` (YangonRoads.sideZone + findMouths in Python); `--old` = the first approximations;
   `--paint-only` = the paint checks alone (qa_paint.json).
6. `road_overlay.py` (12 districts + 7 close-ups at zoom 19, boxes = junction +-260 studs via geo.lonlat).
7. Junction test data: `roads05_jsubset.py NET <out> junctions.json` (roads within 800; also writes roads.json there).

## Counts
- mouthsim failed joins 20 -> 0, dropped 4 -> 0. Two joins are "square end under the deck" on purpose: Road #20 under
  the U Chit Maung bridge (Bo Min Gaung Street) and Thamaing Station Road under Bayint Naung Bridge 2 (the bigger
  road's ground is cut there; its deck passes over). U Htaung Bo Road #2 (7 samples, wholly inside Roundabout 2) and
  4 duplicates (Maha Bandula Road on Strand Road, Bogyoke #2 pieces, Lane #4714) left the data: the builder dropped them anyway.
- QA, first rules -> builder-true rules (kerbsim): mouth_short 89 -> 46, mouth_over 50 -> 38, mouth_edge 27 -> 0,
  kerb_cross 552 -> 22, median_cross 3 -> 1, overlap 10 -> 0, zero_width 0, rank_dup 0. (The same data under the new
  rules before this pass: kerb_cross 63, mouth_short 51, mouth_over 42, mouth_edge 20.) Left: mostly small streets.
- Paint QA: paint_off 438 -> 0, zebra_median 129 -> 0, stack_paint 89 -> 0, median_box 0. deck_grade 24 / deck_foot 1 not touched.

## Studio test J7 (`build/city_1to1/roads05_J7`, asset 133014134133489). The test ran a copy of YangonRoads whose
`workspace.Terrain:Fill*` calls go to a no-op (7,029 terrain writes skipped), so the main place's terrain was not
touched; roads lifted +400, 520-stud box per junction. All 7: 0 MOUTH FAILED. Shots `City Legends/2026-11-17 roads05 J7 test - *.jpg`.
- University Ave x Kabar Aye: PASS.
- Hanthawaddy Roundabout: FAIL (minor): the kerb point where each arm's round corner meets the ring kerb is still there
  (close-up shot). The ring kerb no longer runs under corners at other rings (the cornerSpan centre bug).
- Pyay x University Ave: hole gone (the deck now runs over the junction), no seams seen; small pavement breaks where two
  corner pavements meet and island insides unpaved (ground shows in a lifted test). FAIL (minor).
- Sule roundabout (Roundabout 4): loose kerbs on the ring gone (no arm kerb on the ring carriageway; Maha Bandula #5
  absorbed into #2). Tiny pavement points at the arms remain. FAIL (minor).
- Slip triangle (Waizayandar x Lay Daungkan): slips reach the main roads (no fake deck there any more). Island insides
  unpaved, a few pavement breaks. FAIL (minor).
- NEW Bahan Road at Roundabout 1: Bahan Road clean after absorbing Bahan Road #2. FAIL: sawtooth kerb / pavement where
  Lane #4701 runs along the ring arm.
- NEW Bogyoke x Pazundaung Y: joins fine; the Y gore between Lower Pazundaung Road and Bogyoke #2 ~5 (both butted
  continuations of Upper Pazundaung #3's end) has no slab: grass shows, no kerb on its host side. FAIL (minor).
Terrain: grass FillBlocks left by the J3/J5 tests outside the built map (Pyay x Univ, slip triangle: 76,583 Grass voxels,
nothing else there) were removed.

## Next (in order)
1. Ring corner points (YangonRoads.buildCorners, ring corners near TB: the arc's last kerb / pavement bands vs the ring's
   square sector end; a first try clipping the arc at the ring band left a 0.9 step, reverted).
2. Pavement breaks where two round-corner pavements meet, and unpaved small islands (fill an island under ~2 x WALK).
3. Bahan / Lane #4701: a slip running along a ring arm (absorb into the arm, or end it with a mouth before the arm).
4. Y gore of two butted continuations: a gore island (kerb + pavement) on the host's end line.
5. QA rows not 0: mouth_short 46 / mouth_over 38 (streets, check against Studio: kerbsim said Lane #1013 / #1008 / #1014
   by Kabar Aye have no mouth, Studio built corners for them), kerb_cross 22, median_cross 1 (Aung Yadana St under the
   Baho Road deck); deck_grade 24, deck_foot 1.
6. Then Studio again (same 7 junctions), then owner approval of the overlays.
