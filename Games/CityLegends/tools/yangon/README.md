# Yangon street plan tools (13 Nov 2026)

These scripts made `imports/refs/map/ygn_street_plan.png` and `ygn_junctions_sheet.png`.
Run them from `imports/refs/map` (they read the files there by name). They need Python with numpy, scipy and matplotlib.

1. `plan.py`: reads `ygn 3 map project.kml` and `ygn_osm_roads.json`, works out which parts of each drawn main road lie on a real road, writes `main.pkl`.
2. `make_plan.py`: draws `ygn_street_plan.png`.
3. `make_sheet.py`: draws `ygn_junctions_sheet.png` (close-up spots in `jlist.py`, captions in `caps.json`).

`render.py` holds the shared drawing code and `common.py` the loaders. Positions are in metres east and north of lon 96.14, lat 16.82.

## Road design (Step 2, 13 Nov 2026)
Run after `plan.py`, in this order, from `imports/refs/map`:

4. `d1_main.py`: smooth centre lines of the 3 main roads (middle of the real road, bends of 60 m or more) -> `centre.pkl`.
5. `d3_streets.py 200`: cuts the loop at the roundabout, runs New Road over the Kabar Aye junction, picks the real streets to build (`d2_net.py` holds the shared parts) -> `net2.pkl`.
6. `d5_design.py`: names, street ends, heights from the smoothed ground (`d4_heights.py`), junctions -> `design.pkl`.
7. `d6_export.py`: flyovers, roundabout, landmarks -> `ygn_road_design.json` (plan metres) and `ygn_roads.json` (world studs, the format `tools/riviera/Roads.luau` reads; streets carry half width 16).
8. `make_design.py`: draws `ygn_road_design.png`.

## Building the roads in Studio (Step 3, 13 Nov 2026)
- `patch_ranks.py`: puts the build ranks (0 = Yangon Loop, the LOWER rank is the bigger road, no two alike) and each road's `half` into `ygn_roads.json`. `d6_export.py` writes them itself from now on. Plain Python.
- `YangonRoads.luau`: the Yangon road tool for Studio (`ServerStorage.ClaudeTools.YangonRoads`). Cuts (flyover corridors, the roundabout), the Hanthawaddy Roundabout, the mouths where a road ends on a bigger one, the bank where water reaches under a pavement, and the checks. It drives `tools/riviera/Roads.luau` and `RoadLines.luau`. `Y.load()` then `Y.spawn("step 3", Y.step3)` builds the three main roads, the roundabout and the lines in about 25 s.
- `pack_tools.py` + `YangonSync.luau`: how tool code gets into Studio (Studio cannot fetch from the web here). Pack the `.luau` files into `imports/sync/yangon_tools_1.rbxmx`, upload it as a new version of Model asset 133014134133489 (`open_cloud_invoke` PATCH `/assets/v1/assets/133014134133489`, the file with content type `model/x-rbxm`), `insert_asset` it into ServerStorage, then `require(ServerStorage.ClaudeTools.YangonSync:Clone())()`. The lengths and checksums it returns must equal what `pack_tools.py` printed.
