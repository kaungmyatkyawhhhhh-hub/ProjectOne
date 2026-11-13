# MEGA BITE - World map v2: the whole world painted, zoom and pan (13 Nov 2026, 12:45-13:05)

Owner 12:43: "also the titan area is not showing in map". Owner 12:44: "also make it so that u can zoom in map".
Status: built and tested in Play in Studio, **not published**.

## What was wrong
The map picture (v1) stopped at the old wall, r 1780. The Titan Sea (r 1800-2480) was only a plain gold ring around it.

## What the player gets now
- **The Titan Sea is on the map**: gold sand, turquoise meadows, rocks, columns and gardens where they really are (drawn from the live terrain and props). The Red Trench band now reaches r 1800. The Kraken's pit shows as a dark hole in the west.
- **Zoom**: mouse wheel, pinch, or the **+** and **-** buttons in the corners under the map. Up to 5x.
- **Pan**: drag the map while zoomed in.
- The first press of **+** zooms to where you are. A zoomed map re-opens on you.
- A press that does not move still drops the pin; a drag never does.
- The minimap uses the same new picture (it shows the Titan Sea under you).
- The landmark list now has room for 6 rows plus REMOVE PIN on its own line (rows 35 apart, was 40).

## How it is built
- Picture v2: 2040 x 2040 px for r 0..2480, cut into **four 1024 px tiles** that overlap by 8 px (one 1024 picture would be blurry when zoomed).
- `MB_WorldMap`: `MAP_TILES`, `seaTiles(parent, z)`; the open map's picture is a frame of 4 tiles; `zoom`, `viewC` (view centre in world x, z), `toDisc(p)` places everything; `relayout()`, `setZoom(z, around)`, `screenToWorld(sp)`.
- `GameConfig.World.MapImgR` 1780 -> 2480.
- Backups: `ServerStorage.MB_WorldMap_preZoom_13Nov`, `GameConfig_preMapV2_13Nov`.

## Asset ids (all Approved before use)
| Tile | Id |
|---|---|
| top-left (00) | 72299681106987 |
| top-right (01) | 79071428136074 |
| bottom-left (10) | 100164755844413 |
| bottom-right (11) | 96950682784089 |

## Files: `MEGA BITE/UI/map_art/v2/`
- `worldmap_render_v2.py` (the painter), `decode_ring.py`, `ring.b64` (terrain height + material of r 1690-2530 on a 36-stud grid, exported from Studio), `clusters_v2.json` (what stands where: 1,050 prop clusters from the live map, 731 drawn), the 4 tiles, `preview_v2.png`, `zoom_titan.png`.
- It also needs `h150.npy` from the v1 folder (inner sea heights).
- **Redraw and re-upload when the map changes.** The Studio exports are two short scripts (heights by raycast on the terrain; props binned in 150-stud cells by kind); their text came back through the tool output.

## Tested (Play, Megalodon)
- Open map: whole world shown, Titan Sea painted, 6 rows fit.
- + twice, drag, wheel twice: zoomed and panned, names and landmark icons move with the map, no pin dropped by the buttons or the drag.
- Click on the zoomed map: the pin lands under the cursor, REMOVE PIN shows under the rows.
- Minimap in the reef and in the Titan Sea (2040, 30, near a tile seam): picture correct, no seam seen.
- Titan Sea zone message seen in gold: "TITAN SEA · x3 EXP · no PvP".
- 0 script errors or warnings.

## Not tested
- Pinch zoom on a real phone (code path only).
- The map window at phone size with the new + and - buttons.
