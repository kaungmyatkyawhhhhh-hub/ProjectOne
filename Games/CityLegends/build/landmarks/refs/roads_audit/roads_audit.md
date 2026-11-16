# Yangon roads: accuracy audit for the 1:1 rebuild (16 Nov 2026)

Scope: lon 96.095-96.235, lat 16.75-16.89. The target is 3 studs per metre with 12-stud (4 m) lanes, the owner's choice.

The real roads were checked against:
- OpenStreetMap: `build/osm_ygn` (Geofabrik 2026-11-12) plus a fresh Overpass pull with every tag (16 Nov).
- Esri World Imagery at z19 (0.286 m per pixel).

They were compared with the generators:
- `city/roadnet.py`, `roadmesh.py`, `network.py`, `details.py`, `heights.py`
- `d7_flyovers.py`, `d23_lanes_v5.py`, `YangonRoads.luau`
- the data: `ygn_roads_v5.json`, `details_*.json`, `roads_*_stats.json`

No code was edited.

## What is in this folder

| File | What |
|---|---|
| `road_NN_<road>.jpg` (44) | Every main road over 1.5 km, 1-2 sites each, from OSM's longest ways. **Yellow ruler** across the road: ticks every 1 m, orange every 5 m, labels every 10 m, centred on the carriageway (the midline for divided pairs). **Cyan rings** = the edges the game's lane rule would build at 12-stud lanes. |
| `street_NN_<township - street>.jpg` (25) and `sheet_streets_0..6.jpg` | One sample street per township (25 townships), with a ±20 m ruler. |
| `junc_NN_*.jpg` (18) | Junctions, roundabouts, flyovers and footbridges at 1000 px (286 m). |
| `annot_hanthawaddy_real_vs_game.jpg` | The real roundabout (green) against today's game ring (red). |
| `annot_sule_markings.jpg`, `zoom_*.jpg` | Close-ups of the paint. |
| `busstops_6.jpg` | Six sheltered YBS stops, for the bus-bay check. |
| `data/main_roads.json` | Per road: km, class, OSM lanes, the game rule's lanes, one-way km, surface, turn:lanes, bridges, batch. |
| `data/*_sites.json`, `data/fb_road.json` | The sites, and the 18 OSM footbridges that cross a main road. |
| `scripts/` | Tile fetch, annotation and analysis scripts (re-runnable). |
| `tiles/` | Cached Esri z19 tiles (not committed). |

Widths read off the ruler are about ±1 m. Esri imagery sits 3-10 m off OSM in parts of downtown (Lanmadaw, Pabedan), so widths were read from the image, not from the OSM line.

## Measured cross-sections

Columns:
- **Real** = kerb to kerb, read from the image.
- **Game @12** = what `roadnet.cross_section` gives at 4 m lanes.

| Site (image) | Real | Real lanes and median | OSM tag | Game @12 |
|---|---|---|---|---|
| Pyay Rd, 9 Mile (`road_00`) | ~31 m with kerb parking | 3+3 + parking, ~0.6 m white barrier | 1w 3 pair | 26 m, 2 m grass median |
| Pyay Rd, Inya Lake (`road_01`) | 2 x ~11.5 m | 3+3, **12-14 m planted median with big trees** | 1w 3, pair 23.8 m apart | 26 m, median collapsed to 2 m |
| Kabar Aye Pagoda Rd, 16.8406 (`road_04`) | **~19.5 m** | 3+3 at ~3.1 m, ~1 m barrier | 1w 3 pair | **26 m** |
| Insein Rd, 16.841 (`road_11`) | **~18 m** | 3+3 at ~3 m, thin barrier, bus queue | 1w 3 pair | **26 m** |
| Waizayandar Rd (`road_08`) | 2 x ~10 m | 2-3 a side, **5-6 m planted median** | 1w 3 pair | 26 m, 2 m median |
| Strand Rd, 16.7713 (`road_13`) | 2 x ~13 m | 3-4 a side, **4-5 m tree median** | 1w 3 / 6 | 26 m |
| Kyimyindine Kannar Rd (`road_18`) | ~30 m | 4+4, narrow median | 1w 4 pair | 26 m (capped at 3+3) |
| Bayint Naung Rd (`road_02`) | ~20 m | 2+2 + parking, thin median | 1w, no lanes tag | 18 m |
| Bogyoke Aung San Rd (`road_30`) | ~20 m | 2+2 + parking, painted centre | 1w 2 / 4 | 18 m |
| Maha Bandula Rd, Lanmadaw (`road_31`) | ~22 m | two-way 2+2 + parking, painted centre | 1w 4 pair 5.9 m apart | 26 m |
| Anawrahta Rd, one-way (`road_17`) | **~20 m** | 5 incl. parking, no median | 1w 5 | **12 m** (halved to 3) |
| Upper Pazundaung Rd (`road_37`) | **~15 m, concrete** | 2+2, solid white centre | 2w **6** | **24 m** |
| Tabin Shwe Htee Rd (`road_38`) | **~16.5 m, concrete slabs** | 2+2 | tertiary, no lanes tag | **8 m (1+1)** |
| Than Thu Mar Rd (`road_06`) | ~22.5 m, **concrete slabs** | 2+2 / 3+3 | secondary, no tag | 16 m |
| Hledan flyover deck (`junc_00`) | ~15.7 m | 2+2, solid centre | bridge, 860 m | ~16.7 m (OK) |
| Kabar Aye flyover by Myanmar Plaza (`junc_06`) | ~17 m | 2+2. **Ground lane on the east side only** (one lane) | bridge | deck OK, side lanes wrong |
| Shwegondaing flyover (`junc_04`) | ~17 m | 2+2. Ground lane on the west only, for part of it | bridge, 858 m | side lanes wrong |
| Myaynigone overpass (`junc_03`) | ~21 m | 2+2 + shoulders + barrier. One narrow ground lane each side | 697 m | - |
| Downtown one-way streets: 36th St, 20th St, Latha (`sheet_streets_3/4`) | 9-12 m | 2 moving lanes + kerb parking both sides | residential 1w | **4 m (1 lane)** |
| Suburban streets: N Dagon, N Okkalapa, Thaketa, Kamaryut (`sheet_streets_0/3/4/5`) | 4-6 m, often concrete or earth edges | 1+1, no raised pavement | residential | 8 m (1+1) |

Real lanes are 3.0-3.3 m. Real medians come in three kinds:
- a barrier or kerb 0.5-1 m wide;
- planted, 4-14 m wide, with trees;
- painted.

## OSM facts used

| Fact | Number |
|---|---|
| Main-road ways (trunk to tertiary + links) in the box | 642 km |
| No `lanes` tag | 272 km (tertiary 101, secondary 87, primary 70) |
| One-way `lanes=4` (the rule caps it at 3) | 42 km |
| One-way `lanes>=5` (the rule halves it) | 24.5 km |
| `turn:lanes*` tags (arrows) | 50 km |
| Main roads tagged `surface=concrete` | 41 km (+ 39 km of residential) |
| Footbridges (`bridge` footway / path) | 88 clusters; **18 cross a main road** (0.5: 2, batch 1: 4, batch 2: 12) |
| Traffic signal nodes | 501 in 216 junctions (0.5: 22, batch 1: 40, batch 2: 74, batch 3: 33) |
| Bus stops | 1,055 (0.5: 62, batch 1: 194, batch 2: 168, batch 3: 206) |
| Bus lanes (`lanes:bus`, `busway`, `bus:lanes`) | **none** |
| Roundabouts | Hanthawaddy, Sule, U Htaung Bo, U Wisara, Thaketa, plus 1 mini |
| Main-road bridges and flyovers | 37 km tagged `bridge`. Flyovers: Hledan (Pyay Rd, 860 m), Shwegondaing (Kabar Aye, 858 m), Kabar Aye by Myanmar Plaza (~850 m), Myaynigone (697 m), Bayint Naung pass-over (435 m), Thamaing pass-over (746 m, layer 2), Waizayandar (several short spans), Hledan pass-over (192 m) |

## Mismatches, ranked by how visible they are

Each fix is marked **[data]**, **[rule]** or **[generator]**.

### 1. Main-road corridors are 25-60% wider than the real road

- **Real:** lanes are 3.0-3.3 m.
  - Kabar Aye Pagoda Rd 3+3 is ~19.5 m kerb to kerb.
  - Insein Rd 3+3 is ~18 m.
  - Upper Pazundaung Rd 2+2 is ~15 m.
- **Game (12-stud lanes on OSM lane counts):**
  - 26 m for every divided 3+3 and 24 m for an undivided 3+3, plus 2 m pavements.
  - The kerb line lands 3-4 m into the real front building row on each side of every main road. Plots, lots and the OSM building outlines then have to be clipped or pushed back, which breaks the 1:1 street wall.
  - 12 studs is the owner's choice (fun weaving).
- **Fix [data + rule]:**
  - Make a per-way **kerb-to-kerb width table** from the imagery: `data/road_widths.json`, sampled every 100 m along each main way. Start from the 44 sites here.
  - `roadnet.cross_section` takes the real width first and puts lanes in it:
    - `n = max(1, floor(w / 4 m))` at 12 studs where they fit;
    - otherwise the real lane count at `w / n` (never under 10 studs).
  - The kerb then stays on the real line, and most 2+2 roads with kerb parking still get 12-stud lanes.
  - Ask the owner only if he wants 12 studs everywhere at the cost of moving every front building.

### 2. One median for every divided road; wide planted medians disappear and carriageways move

- **Real median kinds:**
  - a thin barrier 0.5-1 m: Kabar Aye, Insein, Pyay Rd at 9 Mile (white barrier);
  - **planted, 4-14 m, with rain trees:**
    - Pyay Rd along Inya Lake: 23.8 m between the two OSM lines, ~12-14 m of trees;
    - Waizayandar Rd: 5-6 m;
    - Strand Rd: 4-5 m;
  - painted only: Maha Bandula, Bogyoke Aung San.
- **Game:**
  - `roadnet` merges any two one-way ways of a road up to `PAIR_MAX` apart (45 studs now = 28 m; the plan says 72 = 24 m).
  - Each carriageway is put at `MED` = 3 studs half from the midline, with one kerbed grass median (`MG`) and red-white kerbs.
  - Pyay Rd at Inya Lake becomes one 26 m road with a 2 m median. Each carriageway moves ~10 m off its real line (into the lake park on one side, the houses on the other).
- **Fix [rule + generator]:**
  - In `roadnet` pairing, keep both carriageways on their own OSM lines (or on the measured kerb lines) and set the median to the real gap.
  - Median kind by gap:
    - < 1.5 m: barrier (concrete or steel fence part kind);
    - 1.5-4 m: kerbed hedge strip;
    - > 4 m: planted median.
  - `roadmesh` builds the median polygon at its real width. `green.py` plants the >4 m medians with the lake-side rain trees.

### 3. Junction paint is white; in Yangon it is yellow

- **Real:** imagery from 2020 or later shows **yellow zebra crossings**:
  - Hledan junction under the flyover (`junc_00`);
  - all round Sule (`junc_02`, `annot_sule_markings.jpg`);
  - Pyay Rd at 9 Mile;
  - Bogyoke Aung San Rd.
- Also yellow:
  - the hatched splitter triangles and chevrons at Hanthawaddy and U Htaung Bo;
  - a box junction (yellow box with a cross) on Sule's east approach;
  - solid lines along median edges (Pyay Rd at Myaynigone, `busstops_6.jpg`; Sule).
- Lane dashes, stop lines and parking bays are white.
- **Game:** every paint polygon is one white kind `L` (232, 232, 226). `roadmesh._zebra_at` makes white bars 8 studs long (2.7 m). Real crossings are ~4 m long.
- **Fix [generator]:**
  - Add a yellow paint kind `LY` in `roadmesh.COL` (for example 228, 182, 40, to be checked with `look_calib.albedo` on a midday crop).
  - Zebras: `LY`, 12 studs long, 1.6-stud bars on a 3.2-stud pitch (pitch and bar width already match).
  - Add median-side edge lines in `LY`.
- The 13 Nov road-look note's "zebra colour not settled" is now settled: yellow.

### 4. The lane-count rule misreads OSM on ~340 km

`roadnet.cross_section` (and `d23` / `network.py`):
- caps at 3 lanes a side: **42 km** of one-way `lanes=4` (Kyimyindine Kannar, Waizayandar, Thitsar, Ayeyar Wun, Kyaik Waing, Maha Bandula) lose a lane;
- halves one-way `lanes>=5` (**24.5 km**): Anawrahta Rd (real ~20 m, 5 lanes with parking) becomes 3 lanes;
- uses defaults on **272 km** with no tag:
  - every untagged tertiary is 1+1 (Tabin Shwe Htee is a real 2+2, 16.5 m, and the game makes 8 m; Bogyoke Rd, Industrial Zone Rd, Bandoola Rd, Bo Min Yaung Rd are the same kind);
  - untagged primary one-ways are 2 (Bayint Naung Rd 15.7 km).
- Some tags are wrong: Upper Pazundaung Rd `lanes=6`, but it is a real 15 m 2+2.

**Fix [data + rule]:** the width table (item 1) decides. Then:
- allow 4 a side;
- halve `lanes>=5` only when the way has no one-way partner;
- make untagged tertiary roads in the downtown grid and in industrial zones 2+2 when the measured width is over 12 m.

### 5. Downtown one-way streets are 4 m; the real ones are 9-12 m with parked cars

- **Real:** the numbered streets (Latha, Lanmadaw, Pabedan, Kyauktada, Botahtaung, Mingala Taungnyunt and Tamwe one-ways) are 9-12 m between kerbs. Cars park on both kerbs and two lanes move.
- **Game:** a one-way residential street is 1 lane (16 studs now, 12 at the new scale) = 4 m.
- **Fix:**
  - **[rule]** One-way residential streets inside the downtown and Tamwe / MTN grids get 2 lanes plus a parking strip each side (about 33 studs kerb to kerb), or the measured width.
  - **[generator]** Add a parked-car layer on those strips (static traffic models, as in `Parking`).

### 6. Invented roads, and a Hanthawaddy roundabout at twice its size

- **Real (`annot_hanthawaddy_real_vs_game.jpg`):**
  - island Ø ~48 m, outer Ø ~76 m;
  - a 3-lane ring ~14 m wide;
  - **5 arms**, including U Wisara Rd;
  - painted yellow hatched splitters (no kerbed splitter islands);
  - a grass island with a radial pattern and a gold urn.
- **Game today (batch 0.5):**
  - island r 60 / outer r 108 studs = 37.5 m / 67.5 m at 1.6. The game's island is as big as the whole real roundabout, and its ring is 30 m wide.
  - It has a **made-up arm** (the 1.1 km "loop link") and leaves out U Wisara Rd.
  - The 1.5 km made-up leg of "New Road" also exists only in the game (step 1 report).
- **Fix:**
  - **[data]** Rebuild batch 0.5's roads from OSM through `roadnet`, as the rescale plan says. Do not write a new exporter from `ygn_road_design.json`, which keeps the invented roads.
  - **[generator]** Port Hanthawaddy into `roadmesh` at its real size: island r 72 studs, outer r 114 studs, 3 lanes, 5 arms.
  - Dropping the two invented roads is the owner's call: they were his lines on 13 Nov. The 16 Nov "nothing invented" rule says drop them.

### 7. Concrete roads are built as asphalt

- **Real:** jointed concrete slabs on Than Thu Mar Rd, Tabin Shwe Htee Rd, Upper Pazundaung Rd, Pinlon Rd, Kyaik Waing Pagoda Rd and Ayeyar Wun Rd (41 km of main roads tagged concrete), and on many township streets: Hlaing, Insein (`concrete:lanes`), North Dagon. Slabs are about 4.5-6 m long and show as light grey with dark joints.
- **Game:** `roadmesh` R and the `streets.py` SR kind are asphalt everywhere.
- **Fix [generator + data]:**
  - Add a surface kind `RC` (concrete, light grey, joint lines every ~15 studs) chosen from `surface=concrete*`.
  - Make an imagery class list for untagged roads in the outer townships (Thingangyun, South / North Okkalapa, Dagon, Thaketa, Dawbon).

### 8. Flyover side lanes are made up

- **Real:**
  - Kabar Aye flyover by Myanmar Plaza: one ground lane on the east side only.
  - Shwegondaing: a ground lane on the west, for part of the length.
  - Myaynigone: one narrow ground lane each side.
  - Hledan: ground roads only round the junction.
- **Game:** `d7_flyovers.py` gives a 2-lane, 24-wide one-way side lane on **both** sides for the whole length (centre 48 from the deck), and `d23` widens the loop to 60 for the gores.
- Deck widths are right (real 2+2, 15.7-17 m; game deck 2 x 24 + parapets ≈ 17 m).
- **Fix [generator]:**
  - Drop d7's made-up side lanes. The ground ways come from OSM in `roadnet` (they are there as separate ways).
  - Keep `CLEAR` 17 (5.7 m).
  - Decks: 2+2 at 12 studs + 1 m parapets.

### 9. White edge lines everywhere; yellow median lines missing

- **Real:** mostly no outer edge line. White dashes ~3 m on, 5-8 m off. Yellow solid lines along median kerbs. A solid white centre line on undivided roads (Upper Pazundaung).
- **Game:**
  - `roadmesh.line_polys` draws solid white edge lines on every main road;
  - dashes are 6 on / 6 off;
  - all white.
- **Fix [generator]:**
  - Edge line only where the road has no kerb parking (or none at all).
  - Median-side line in `LY`.
  - Dashes 9 on / 18 off (already in the plan).

### 10. No traffic lights at the Hledan junction, and side streets get none

- **Real:** OSM has 12 signal nodes round Hledan, 8 at Bayint Naung, 4 at Sule and 4 at Myaynigone. Heads face every approach (`traffic_signals:direction` is on 265 nodes).
- **Game:** `details.signals()`:
  - skips any junction in `DECK_ZONE` / `RING_ZONE`, so Hledan (the busiest junction in batch 0.5) has none;
  - places heads only for main roads near the cluster.
  - In the built data that is 36 heads for 22 signalised junctions in 0.5, 53 / 40 in batch 1, 181 / 74 in batch 2, 51 / 33 in batch 3: about 1.6-2.4 a junction, where 3-4 approaches are normal.
- **Fix [generator]:**
  - One head per incoming approach (streets too), at the stop line, from the OSM node and its direction tag.
  - Allow ground-level junctions under a deck (test the deck height over the junction, not the zone).
  - Add a median pole on divided roads.

### 11. No stop lines or turn arrows

- **Real:** white stop lines before the yellow zebras at every signalised junction. Turn arrows where `turn:lanes` is tagged (50 km of main road: Strand, Bogyoke Aung San, Anawrahta, Pyay, Kabar Aye, Thein Phyu).
- **Game:** neither exists in `roadmesh`.
- **Fix [generator]:**
  - Stop line: 1.2 studs wide across the approach lanes, 3 studs before the zebra.
  - Arrows: one per lane from `turn:lanes` (left, through, right, merged), as paint polygons in `L`.

### 12. No box junctions, hatched gores or painted splitters

- **Real:** a yellow box with a cross on Sule's east approach. Yellow hatched splitter triangles at Hanthawaddy and U Htaung Bo. Chevron gores at the Hledan and Myaynigone ramps.
- **Game:** none. Splitter islands do not exist, and roundabout arms meet the ring with plain asphalt.
- **Fix:**
  - **[generator]** A junction paint pass in `roadmesh`: hatched `LY` triangles between the entry and exit of each roundabout arm, and chevrons in link and ramp gores.
  - **[data]** A short hand list of box junctions (Sule east, plus any found in a full sweep).

### 13. Slip-lane islands are leftovers

- **Real:** slips (14.7 km of unnamed `primary_link`, for example Hledan, Kamayut, 8 Mile) are split from the main road by small kerbed or painted triangles.
- **Game:** `roadmesh` builds the links as one-lane one-way roads. The triangle between them is whatever is left (ground, or pavement scraps), with no kerb and no paint.
- **Fix [generator]:** detect a closed area under ~600 m² bounded only by carriageways. Make it a kerbed island (red-white kerb, concrete or grass top), or yellow hatch when it is under ~2 m wide.

### 14. Pavement widths

- **Real:**
  - Downtown main roads (Bogyoke Aung San, Anawrahta, Maha Bandula, Sule Pagoda Rd): 3-5 m, often under arcades.
  - Suburban main roads: 1.5-2.5 m over the open drain, often broken.
  - Residential streets: no raised pavement, a concrete drain edge.
- **Game:** `roadnet` walk 6 / 4 / 3 studs (2.0 / 1.3 / 1.0 m). The plan's 8-10 for main roads has not been written in yet. Batch 0.5 uses 10.
- **Fix [rule]:**
  - Walk by district: downtown main 10-15 studs; other main roads 6-8.
  - Residential stays flush (`F`) and gets a drain-edge strip (dark concrete channel, 1-1.5 studs).

### 15. Surface condition and colour

- **Real:** worn, mid-grey asphalt with patches, cracks, pothole repairs and oil staining at bus stops and junctions. It is lighter than the game's (photos give about 95-120 grey). Dust at the kerbs.
- **Game:**
  - uniform dark asphalt (46, 47, 50);
  - `details.py` lays `patch` items only in the middle of lane 1 of each traffic chain (374-602 a batch).
- **Fix [generator]:**
  - Spread patches across all lanes, more near junctions and bus stops.
  - Add kerb-side grime strips.
  - A lighter asphalt is the owner's call (the 13 Nov road-look note).

### 16. Kerb paint on every main road

- **Real:**
  - Red-and-white bands on Pyay Rd, Kabar Aye, roundabout islands and medians.
  - Plain concrete on most of University Avenue and many secondary roads.
  - Yellow kerb lines round Sule.
  - Black-and-yellow kerbs could not be checked from above. They need street photos (flyover pier bases, median noses).
- **Game:** red and white (`KR` / `KW`, 3.2-stud bands) on every main road and median.
- **Fix [data]:** a kerb-style list per road (red-white / plain / yellow), defaulting to plain for secondary and tertiary roads.

### 17. Footbridges too narrow and too simple

- **Real:**
  - Decks ~3-4.3 m wide (the Sule Pagoda Rd x Anawrahta walkway is a **rectangular elevated loop round all four corners**, `junc_07`).
  - Steel or concrete, often covered.
  - OSM has 18 that cross main roads. More exist in the imagery: the Kabar Aye flyover west side, `junc_06`.
- **Game:** `details.footbridges()` makes a straight 5-stud (1.7 m) deck with YBS-blue side panels. It made 2 / 7 / 9 / 0 bridges in batches 0.5 / 1 / 2 / 3.
- **Fix:**
  - **[generator]** Deck 10-12 studs. Build along the OSM way's full geometry (multi-segment, for loops).
  - **[data]** Add the bridges seen in the imagery to a hand list.
  - Clearance 18 studs (6 m) is fine.

### 18. Generic roundabouts

- **Real:** U Htaung Bo (`junc_09`), Thaketa and U Wisara have:
  - grass islands with kerbs;
  - 2-3 ring lanes;
  - painted splitters.
- **Game:** `roadnet` treats them as one-way rings. Lanes come from the tags (U Htaung Bo's ways say 2 and 4). The island gets no build (ground or plots), and there are no splitters.
- **Fix [generator]:**
  - Ring lane count from the measured width.
  - Island: kerb + grass.
  - Splitters as in item 12.

### 19. Junction corners too tight

- **Real:** kerb radii are 6-10 m at main-road corners (Bogyoke Aung San, Pyay x side roads).
- **Game:** `roadmesh.RC` is 8 studs (2.7 m at 3 studs a metre). `YangonRoads.CORNER_T` is 16.
- **Fix [generator]:** RC 18-30 by road class (already in the rescale plan, not yet in code).

### 20. Bus stops: counts and kerb, no bays

- **Real:**
  - YBS buses stop in the kerb lane. None of 6 sheltered stops on Pyay Rd, Kabar Aye and Waizayandar has an indented bay (`busstops_6.jpg`).
  - No bus lanes in OSM or in the imagery.
- **Game:**
  - Shelters on the pavement, no bays (right).
  - 398 stops built against 630 OSM stops in the built batches. The missing ones are mostly on streets the game does not build.
  - Nothing marks the stop on the road.
- **Fix:**
  - **[generator]** A worn, oil-stained patch in the kerb lane at each stop (item 15).
  - **[data]** Keep the stops whose road is built.

## Checked and matching (no change needed)

- Flyover vertical clearance: `heights.CLEAR` / `d23.DECK_NEED` 17 studs = 5.7 m. Footbridge clearance 18 = 6 m.
- Flyover deck width at 2+2 x 12 studs + parapets ≈ the real 15.7-17 m.
- One-way direction comes straight from OSM `oneway` (151 km of residential one-ways). The downtown grid's directions are carried.
- No bus lanes and no bus bays, in real life or in the game.
- Zebra bar width 1.6 studs and pitch 3.2 studs (0.53 m / 1.07 m) are real. Only the colour and length are wrong (item 3).
- Signal pole height 22.5 studs (7.5 m) and lamp poles are about right (rescale plan table).

## Not settled from above (need street photos)

- Black-and-yellow kerb sections and median noses.
- Signal head design (countdown timers, how many heads per pole).
- Exact ramp grades and lengths of the flyovers. The OSM bridge ways give deck lengths: Hledan 860 m against the game's ~1,190 m with ramps.
- Pavement surface type per township.
- Whether the 2018-2021 white zebras near Hanthawaddy (13 Nov photo note) were repainted yellow everywhere.
