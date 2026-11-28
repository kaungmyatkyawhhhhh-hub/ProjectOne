---
tags: [city-legends, yangon, landmark, the-central]
created: 2026-11-28
---
# The Central: real layout and plan (28 Nov 2026, night)

Owner (28 Nov, paused list): "The Central is wrong in its entirety." Rule: current dated photos only.

**State: research only. Nothing was changed in the game.** On this PC the 1:1 map's buildings are only drawn when the game runs, and Play runs out of memory here (16 GB), so I could not see what is there now or check a rebuild. This note is the plan for the PC that can.

## What the real place is (satellite + OpenStreetMap, north up)
![[2026-11-28 The Central - satellite with OSM outlines.jpg]]

Corner of **Kabar Aye Pagoda Road** (west side, Inya Lake across it) and **Kanbe Road** (south side). Developer: Marga Landmark. Launched 2017.

| Piece | Where (game X, Z) | What |
|---|---|---|
| Site outline (OSM way 1537086751 "The Central") | about X 34940-35390, Z 24990-25560 | the whole block |
| **The Central Boulevard** (OSM way 1537086760) | X 34950-35050, Z 25050-25470 | two rows of **2-storey retail shophouses** along Kabar Aye Pagoda Road: a north group (about 16 units) and a south group (about 14 units). A long glass-roofed strip runs behind them. |
| Round plaza | about X 34975, Z 25520 | a circle (fountain) at the south-west corner, where the two roads meet |
| **Towers** | X 35090-35300, Z 25060-25330 | **five towers**: one of 39 floors (west), four of 30 floors (OSM levels). Two stand at a slant on the north-east. A podium between them with a triangular pool. |
| Car park | X 35250-35390, Z 25150-25400 | a big surface car park on the east side |
| Still a building site | X 35100-35250, Z 25380-25480 | the south part by Kanbe Road |
| Gallery showroom (OSM way 1538365713) | X 35042, Z 24838 | a small flat building with a green roof, north of the towers, its own car park |

## Facts with dates
- Irrawaddy, **2 Oct 2026**: buyers gathered at the sales office after waiting six years for their apartments. So the towers are up but the project is **not finished** (the satellite shows the south part still under construction).
- Developer pages: "retail promenade", residential towers, a boutique mall, grade-A offices.
- No dated ground-level photos saved yet: the Google Maps photo galleries (they carry dates) still have to be gone through for the towers' facade, the shophouse fronts, the plaza and the showroom.

## What the game has there now (read from the place in Edit)
- `Parks.TheCentral` (73 parts: a forecourt and plaza) and `Parks.TheCentralCarPark` (307 parts), `Landmarks.IrlBuild21Nov.TheCentralPavilion` (a round pavilion at 35068, 25307), the THE CENTRAL letters on a plinth (34978, 25265).
- 55 building shells from the ordinary building kit, up to 400 studs tall (the towers stand on the OSM outlines).
- **The 21 Nov pavilion and forecourt were a guess** ("the central point" was read as this place; built with no photos). The real corner has a round fountain plaza and two shophouse rows, not a pavilion on a lawn; the real car park is on the east side, not behind a shop row.

## Plan (for the PC that can run Play)
1. Dated ground photos first: Google Maps galleries for "The Central" and "The Central Boulevard" (2023-2026 only). Save with dates in `build/landmarks/central/refs/`.
2. Take out the guessed pavilion, forecourt and car park (move to ServerStorage, do not delete).
3. Build as one landmark tool, like `tools/yangon/Novotel.luau`: the two shophouse rows (repeat one 2-storey unit), the glass strip, the round fountain plaza, the five towers on their OSM outlines with the real facade from the photos, the podium and pool, the east car park, the showroom.
4. Hide the kit's buildings inside the site outline.
5. Side-by-side sheets against the photos, then a Play check.

Working files: `Games/CityLegends/build/landmarks/central/` (`osm_sat.py` makes the satellite + outline picture for any box; `central_osm.json` is the map data).
