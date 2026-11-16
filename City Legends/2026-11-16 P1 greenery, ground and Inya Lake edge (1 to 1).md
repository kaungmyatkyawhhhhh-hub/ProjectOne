---
tags: [city-legends, yangon, 1to1, greenery, terrain, trees, inya]
created: 2026-11-16
---
# P1 greenery, ground and Inya Lake edge (1 to 1)

Pilot district P1 (lon 96.133-96.159, lat 16.810-16.834). In Studio under `Workspace.Yangon1to1` + `ReplicatedStorage.YgnKit`. **Not saved** (the coordinator saves).

## What is in Studio now (version 2, after the owner's feedback)
- **Ground:** the game's own terrain Grass everywhere (the old map's look), clean concrete (terrain Concrete) only on real forecourts and parking, and only where the ground is flat. No Ygn ground overrides (undone), no dirt / earth / gravel patches.
- **Trees:** the old map's tree kit (`ServerStorage.YangonData.GreenKit`: Monaco Tree, Palm, PalmA) at real 1:1 sizes, as streamer templates `OKA/OKB_ot1`, `OKA-C_op1`, `OKA-C_op2` in `ReplicatedStorage.YgnKit.Templates`.
  - Broadleaf trees: crown 6-25 m (rain trees 15-25 m). Palms: 10-15 m tall.
  - 27,594 trees as data (`ReplicatedStorage.YgnKit.Data_P1G`, 990 tiles, 745 k chars), built on each client within 1,000 studs by `YangonKitStream` (same streamer as the building detail).
  - Far look: 2,363 big crowns (16 m and up) as the same Tree mesh in `Workspace.Yangon1to1.Green.Far` (4,726 parts, no shadows, attribute `T`: hidden where the real trees are built).
- **Inya Lake edge:** a bund along the straight shore beside Kabar Aye Pagoda Road (820 m, x 34,200-34,800, z 25,300-28,500): concrete wall into the water, white steel railing (2 rails, a post every 2.5 m), 3 m slab walkway, the grass strip behind it. 732 parts in `Workspace.Yangon1to1.Green.LakeEdge`. Terrain cleared above each walkway piece and filled under it. Elsewhere natural banks: grass and trees to the water.
  - The Pyay Road bund of the research lies west of P1 (lon 96.136, lat 16.833+): not in this district.
- **Placement rules:** canopy target per land use (research section 3), avenue rain trees every 18-25 m (Inya Rd 202, University Ave 155, Kabar Aye 60, Pyay Rd 43, U Wisara 30 ...). No tree on a building, road corridor, flyover deck, landmark site or the walkway; trunks 1.2 m off compound walls; a crown may hang over a roof only when the roof is at least 1 m under its lowest leaves.

| Measure | Result |
|---|---|
| Canopy (land) | 36% (research P1 mix ~33%) |
| Canopy by area | campus 51% (48), villas 41% (45), houses 34% (36), walk-ups 21% (16), parks 62% (58) |
| Lake bank 0-15 / 15-50 / 50-150 m | 65 / 59 / 43% (research 65 / 56 / 47) |
| Crowns | p10 6.8 m, median 8.4 m, p90 15.4 m |
| Ground | 92% grass, 8% concrete |

## Performance
| | Before | After |
|---|---|---|
| Parts in `Workspace.Yangon1to1` | 34,238 | 39,696 (+4,726 far trees, +732 lake edge) |
| Client parts near the camera | buildings only | + about 1,300 trees (2-3 parts each) within 1,000 studs |
| Data | - | `Data_P1G` 0.75 MB of text; lake edge and far trees about 0.4 MB |
| Unique meshes | - | 0 new (the old map's tree meshes) |
| Studio memory (Edit) | 7.59 GB | 7.61 GB |
- Triangles of the old tree meshes can't be read (not our assets). Roblox's own mesh LOD thins them at distance.

## Screenshots (Studio, PlayLight 13; `C:/Users/kaung/.claude/projects/D--ObsidianOne-Claude-Obsidian/8dbf212d-129a-4909-ba7d-ab448f73c052/tool-results/`)
- Before: residential `mcp-Roblox_Studio-blob-1794815790386-2afvy3.jpg`, Kabar Aye `...1794815799626-5wrvuw.jpg`, lake `...1794815821371-p5ts4u.jpg`, aerial `...1794815840066-x4f5vi.jpg`.
- Version 1 (rejected by the owner): residential `...1794816168274-yu8227.jpg`, lake `...1794816193521-z17g5x.jpg`, aerial `...1794816202451-wlo8xs.jpg`.
- Old map tree vs 1:1 tree side by side (old map tree, 20 m rain tree, 13 m palm, 10 m tree, 1.8 m red figures): `...1794816681436-7j6gdm.jpg`.
- Version 2: residential `...1794816913700-9eehj8.jpg`, lake edge walkway `...1794816829326-t9jupe.jpg`, aerial `...1794816894419-qsaspg.jpg`; old map aerial for comparison `...1794816904091-sc5gqc.jpg`.

## How to run
- `YANGON_SCALE=1to1 python green_1to1.py P1` (`Games/CityLegends/tools/yangon/city`, 25 s) -> `build/city_1to1/green_P1/` (Ground / Far / Edge pages, stats, preview) + `imports/sync/ygn1to1_green/green_p1.rbxmx` (holding Folder: Data_P1G, pages, the tool). `STYLE = "clean"` (version 2) or `"patchy"` (version 1: Ygn ground variants + `tree_kit.py` meshes).
- Studio: PATCH the rbxmx as a new version of asset 133014134133489, `LoadAsset`, then `tools/yangon/YangonGreen1to1.luau`: `oldTemplates()`, `data(h)`, `farOld(h)`, `edge(h)`, `paint(h)`; Edit look of the trees: `preview(centre, radius)` / `unpreview()`. Delete the holding after.
- Code changes: `src/shared/YangonKitData.lua` (template attribute `R` = a piece's own rotation), `src/client/YangonKitStream.client.lua` (also hides `Green.Far` by tile). Both patched into Studio's scripts by find / replace.

## Version 1 (rejected, kept in the tools)
- Ground from land use in Ygn materials (lawn, dry grass, packed dirt, red earth, gravel, mud, concrete, slabs) with noise patches; trees from `tree_kit.py` (own meshes, uploads 134796129290094 / 134153006293268).
- Owner: "this vibe feels dirty and the trees are so ugly ... the first version grass looked better". Lesson: for this map, clean game-style grass and the proven old tree kit beat "realistic" mottled ground and home-made low-poly trees. Show a side-by-side of a new prop against the old one before placing it everywhere.

## Traps
- **Terrain material colour tints a MaterialVariant override** (Ground's default 132,114,86 turned YgnDirtPacked orange). `Salt` and `Pebble` can't be coloured ("Invalid terrain material").
- **The scratchpad folder is shared between agents:** another agent overwrote this job's `lock.sh` while it waited, so the lock was taken with the other agent's name in `owner.txt` (fixed by hand). Keep lock scripts in a folder named after the job.
- A walkway Part level with a 4-stud terrain voxel top gets grass through it: clear the terrain from 3.5 studs under the walkway top and make the walkway 4 studs deep.
- Edit screenshots can show a coarse terrain bank over a street (looked like sloped concrete); retake after the 4 s wait.

## Not done / differs from real
- The old Tree mesh is an acacia-like umbrella: fine for rain trees, less so for mango / padauk / mahogany (one shape for all broadleaf trees).
- No shrubs, hedges, bougainvillea or banana clumps (dropped with the owner's feedback).
- No trunk collision (players and cars pass through trunks).
- Studio's `ClaudeTools.YangonGreen1to1` is the earlier copy (no `farOld`); the repo file is current.
- Studio's ground is from the data before the flat-only concrete filter (about 2,300 columns differ).
