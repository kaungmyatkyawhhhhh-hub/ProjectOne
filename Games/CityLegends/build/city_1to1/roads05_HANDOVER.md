# roads05 handover (17 Nov 2026, after commit 89441f83)

Owner rule: NO full rebuild / swap in Studio until the owner approves the overlays. Studio is clean (no Roads05_* modules,
no scratch folders), saved v1155, lock released. Old P1-P3 road meshes still in place (119 Cell_ meshes, 36,844 Collide).

## State
- Network: `build/city_1to1/roads05_P1_P2_P3_P4_P5_P6_P7_P8_P9_P10_P11_P12/` (call it NET). Made by
  `YANGON_SCALE=1to1 python roads05.py P1 P2 P3 P4 P5 P6 P7 P8 P9 P10 P11 P12` (~10 min; slip roads kept, MERGE_TOL),
  then `roads05_fix.py NET` (~30 s). `roads_unfixed.json` = before the fix (copy it back over roads.json before
  re-running the fix). Run everything from `tools/yangon/city` with `YANGON_SCALE=1to1`.
- `roads05_paint.py NET` on the fixed data was KILLED (exit 143, after >30 min; no paint.json exists for NET now).
  Run it again in the background (log `NET/paint.log`); it is slow on 12 districts. Paint QA = `roads05_qa.py NET` (with paint).
- Junction QA without paint (7 min): `python roads05_qa.py NET NET/roads.json <empty paint json {"items":[]}>`.
  Last counts (spots in `NET/qa_junctions.json`): mouth_short 81, mouth_over 35, mouth_edge 25, kerb_cross 522,
  median_cross 3, zero_width 0, overlap 12, rank_dup 0. Faster loop: run the QA on a subset dir (see roads05_subset.py)
  or add a bbox filter.
- Overlays: `road_overlay.py NET P<n>` and close-ups `road_overlay.py NET "Close-up <name>" 19 lon0 lat0 lon1 lat1`
  (University Ave x Kabar Aye 96.1513 16.8213 96.1563 16.8253; Hanthawaddy 96.1320 16.8114 96.1370 16.8154;
  Pyay x University 96.1283 16.8245 96.1333 16.8285; Sule x Bogyoke 96.1565 16.7773 96.1615 16.7813).

## Next, in the coordinator's order (target 0 or a listed reason each)
1. Roads ending on a SIDE lane (Insein Road, Hledan Road #3, University Avenue Road on `Pyay Road #11`): YangonRoads
   fails "an edge of X never meets Pyay Road #11". `roads05_fix.py` skips `kind == 'side'` for the road itself only;
   decide: let the end run on to the MAIN road past the side lane (cut it through the side lane), or extend it onto
   the side lane edge. Check YangonRoads.buildMouth (~line 753): B = the big road's edge polyline on the facing side
   within +-60 samples of m.bigI, cut samples excluded.
2. End-to-end pieces (e.g. Hanthawaddy Road #2 on Hanthawaddy Road): the builder makes a mouth for them. Either chain
   them in roads05.py (`join_roads`, JOIN = 12 m, same name) or set `startsOnEnd` / `endsOnEnd` like side lanes
   (see YangonRoads load: `startsOnEnd = r.startsOnEnd, endsOnEnd = r.endsOnEnd`). roads05_fix / QA skip ends within
   40 studs of the other road's end (so QA hides these; the builder still fails).
3. overlap 12 (e.g. Maha Bandula Road #2 / #5, Bogyoke Aung San Road / #2): doubled pieces of one road.
4. kerb_cross 522: rule in roads05_qa.junction_checks (a road's kerb + pavement strip over another carriageway where
   neither ends on the other nor crosses it). Look at a sample first; some may be parallel roads closer than their
   pavements (OSM side by side) = real, or the rule may still be too loose.
5. mouth_short / mouth_over / mouth_edge.
6. Paint + paint QA.
Then the Studio test (lock protocol: `mkdir build/studio.lock` + owner.txt): pack `YangonRoads.luau` + the subset's
Roads05_* (`roads05_J3` dir shows how: roads within 700 of each junction), upload Model (group 33151111),
`InsertService:LoadAsset`, `Y.load()`, `Y.stepCell({x-350,z-350,x+350,z+350}, root)` per junction (returns a log with
"MOUTH FAILED ..."), `root:PivotTo(+400 y)`, `screen_capture` from (x, 1000, z+5) at (x, 440, z). Junctions (world):
Univ x Kabar Aye (34426, 28891), Hanthawaddy (28251, 32193), Pyay x Univ (27066, 27859) + one more roundabout + one
slip-road triangle. Pass = 0 failed joins, 0 grass scraps, 0 diagonal kerbs. Delete the scratch + modules, save,
check "Saved new changes" in the newest %LOCALAPPDATA%/Roblox/logs Studio log, remove the lock.

## Also kept for the P1-P3 rebuild later
- `roads05_subset.py NET S123 P1 P2 P3` -> Studio subset; `roads05_bake.py` clips parts to subset.json boxes.
- 9 cells of OLD-network pages in `build/city_1to1/roads05_S123/pages` are STALE now (network changed): re-export.
- Page export: ~600 tokens a page in a subagent's context; ~85 pages per subagent; the gather script idea: scan the
  session tool-results folder for files whose head has `@Q<cell>_<kk>@` newer than the export start.
- Studio HttpService to localhost is blocked ("not in the Assistant HTTP allowlist"): pages must go through MCP results.
