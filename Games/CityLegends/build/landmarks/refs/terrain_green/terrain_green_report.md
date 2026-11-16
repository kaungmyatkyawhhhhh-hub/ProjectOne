# Yangon terrain, water and greenery: accuracy report (16 Nov 2026)

Map box: lon 96.095-96.235, lat 16.75-16.89. No code was changed. Files next to this report:

| File | What it is |
|---|---|
| `elev_profiles_A-E.png`, `elev_profiles.json` | five profile lines: SRTM (today) vs Copernicus GLO-30 raw vs GLO-30 bare-earth approximation |
| `canopy_map_whole_box.png` | tree-canopy share per 11 m cell over the whole box (blue = OSM water) |
| `sample_*.jpg` (11) | Esri z18 photo with notes (left) and the classifier's classes (right), 100 m scale bar |
| `cover_stats.json` | canopy and ground cover per OSM area type, named place, district and lakeside band |
| `road_trees.json` | street-tree survey per named road (32 roads, 330 km of OSM ways) |
| `extra.json` | crown sizes, measured colours (trees, grass, dry grass, lake water, river), OSM tree statistics |

**Imagery:** Esri World Imagery = Vantor "Vivid Advanced", **11 Feb 2026**, 0.34 m native (Esri metadata service), so it shows the **dry season**. z17 (1.14 m/px) covered the whole box (2,808 tiles). z18 (0.57 m/px) covered the 11 sample tiles.

**Classifier:** normalised excess green, 4 m texture and hue.
- Trees: green and textured, or dark green.
- Green grass: green and smooth.
- Dry grass / bare earth: yellow-brown and smooth.
- OSM buildings and water are masked out.

**Accuracy:**
- Green areas: about ±5 points against a strict colour-only count (parks 52-68% either way).
- Dense built areas: the classifier reads building-shadow edges as canopy and **over-reads by 10-15 points**. The strict count gives downtown 10% and the shophouse blocks 6%, where the classifier says 25%. Use the corrected values in the table below.
- Green lake water (algae) reads as "tree". Lakes are masked with OSM, but small unmapped ponds inflate "wetland / scrub".

---

## 1. Elevation

### Profiles (metres above sea level; `elev_profiles_A-E.png`)

**Bare** is GLO-30 after a 270 m grey opening and 45 m blur, the method proposed in the earlier `build/terrain_study`. It removes trees and buildings. SRTM−GLO is measured along each profile.

| Profile | SRTM min-max | GLO-30 raw | Bare | SRTM−GLO mean / rms | Steepest bare slope |
|---|---|---|---|---|---|
| A W-E 16.7982: People's Park, Shwedagon, Kandawgyi | 4-70 | 5-65 | 4-53 | +4.2 / 5.5 | 11.6% |
| B N-S 96.1493: Sule side, Shwedagon, Golden Valley, Inya | 12-68 | 10-64 | 7-53 | +3.7 / 4.5 | 9.8% |
| C N-S 96.157: Bahan ridge, Chaukhtatgyi, Yankin | 14-50 | 11-48 | 11-31 | +3.4 / 4.6 | 3.2% |
| D W-E 16.830: Hlaing River, University, Inya, Yankin | 0-36 | 1.5-30 | 1.5-26.5 | +3.1 / 4.2 | 4.0% |
| E W-E 16.775: Ahlone, downtown, Pazundaung | 0-26 | 0.5-26 | 0.5-10 | +1.0 / 4.0 | 4.5% |
| Whole box | max 71 | max 65 | | mean +1.8, p95 +6.1 | |

### Key points

| Place | SRTM | GLO-30 raw | Bare | Today's `ground.py` (earlier study) |
|---|---|---|---|---|
| Shwedagon platform | 67.1 | 63.1 (includes stupa and halls) | **52.9** | 47.4 (over-smoothed) |
| People's Park, foot of Singuttara Hill | 27.0 | 26.2 | 23.9 | 28.1 |
| Maha Wizaya | 50.2 | 41.3 | 41.3 | 40.9 |
| Univ. Convocation Hall | 28.0 | 26.8 | 23.9 | ~28.7 |
| Kaba Aye | 30.6 | 28.5 | 25.0 | 26.7 |
| Strand (river front) | 22.0 | 21.4 (warehouses) | 7.9 | 11.4 |
| **Inya Lake water** | 16.0 | **13.5** (flat, hydro-edited) | 13.5 | **20.5** (batch 0.5 floor 17.5) |
| **Kandawgyi water** | 16.0 | **12.0** | 12.0 | **16.1** |

### Findings

- **The relief is real and small.**
  - The only true hill is Singuttara (Shwedagon): bare top about 53 m, about 25-30 m above People's Park and Kandawgyi. Its slopes reach 10-12% on the south and east sides.
  - The **Bahan ridge** is a broad low spine at 25-31 m running north from Shwedagon through Golden Valley to the University and Kaba Aye, with grades under 4%.
  - East (Tamwe, Thingangyun) and south (downtown) the land falls to 4-10 m, and to 1-5 m at the Hlaing, Yangon and Pazundaung banks.
  - Published figures for the hilltop (about 51-58 m) agree with the bare value. They are not checked here.
- **SRTM vs GLO-30:**
  - SRTM reads 3-4 m higher on average along every profile (rms 4-5.5 m), up to +9 m over dense canopy.
  - SRTM is also 2.5-4 m too high on both lakes. GLO-30 water is flattened, which gives clean lake levels.
  - GLO-30 is still a surface model (trees and roofs: GLO raw minus bare averages 2-4 m).
  - Inya (13.5) is above Kandawgyi (12.0), which fits Kandawgyi being fed from Inya by pipe.
- **FABDEM (bare earth, built from GLO-30):**
  - Licence: **CC BY-NC-SA 4.0, non-commercial only**, with a paid commercial licence from Fathom (fabdem@fathom.global).
  - A free Roblox game with Robux purchases earns money. Whether that counts as "commercial" is **unclear**, and Fathom has not defined it.
  - It is not usable without written permission. It was not downloaded (a 10x10 degree zip, about 1.1 GB for N10E090-N20E100).
- **Copernicus GLO-30:** free worldwide, redistribution allowed. Changed data must carry the credit "produced using Copernicus WorldDEM-30 © DLR e.V. 2010-2014 and © Airbus Defence and Space GmbH 2014-2018 provided under COPERNICUS by the European Union and ESA; all rights reserved". The tile is already in `build/terrain_study/dl/`.

**Recommendation: Copernicus GLO-30**, made bare-earth with the opening filter.
- Settings: 270 m opening + 45 m blur, as in the earlier study's option C.
- Lake levels: Inya 13.5 m, Kandawgyi 12.0 m.
- Two extra fixes:
  - Keep the Shwedagon platform as a flat plateau at **53 m**, about 300 x 300 m, with the four covered stairways climbing 25 m.
  - Clamp the river fronts (Strand) to the bare value of 6-8 m, not the warehouse roofs.
- Add the credit line to `Config.Credits`.

---

## 2. Water

### Lakes (OSM + Overpass, 16 Nov)

| | Inya Lake | Kandawgyi Lake |
|---|---|---|
| Outline | relation 2641584: 1 outer, **13 inner (islands)** | relation 423 |
| Area (outer) | 268 ha (the often-quoted 388 ha is wrong) | 51.9 ha (Wikipedia says 61) |
| Islands | 13; 10.9 ha total; largest 3.2, 2.6, 1.5, 1.0, 1.0 ha; 10 over 0.1 ha. Islets on the S/SE arms and one round wooded islet 150 m off the Pyay Road bund (96.1356, 16.8362) | 7 `place=islet/island` ways, wooded (at 96.1709/16.7963, 96.1680/16.7944, 96.1661/16.7936, 96.1672/16.7977, 96.1585/16.7926, 96.1558/16.7961, 96.1486/16.7939) |
| Water level (GLO-30) | 13.5 m | 12.0 m |
| Depth (published) | not found | 0.5-1.1 m, average ~1.15 m |
| Water colour (measured, Feb, sRGB) | median **(45, 72, 48)** open water; (33, 57, 36) in the shaded east arms: dark olive green | median **(52, 84, 39)**: olive-pea green, with lighter mats of weed / hyacinth near the boardwalk |

### Bank types (from the z18 tiles, see the samples)

| Where | Type |
|---|---|
| **Inya west, Pyay Road (96.136, 16.833-16.843)** | **straight reservoir bund**, about 1.1 km. Sequence: road, then a 12-18 m grass strip with a few trees, then a walkway (the "Inya Lake Pyay Road Bank" park, 4.2 ha, 29% green grass), then a low wall / railing straight down to the water. Trees stand mostly on the **land** side of Pyay Road. |
| Inya south-west, Inya Lake Park / University side (96.137-96.142, 16.832-16.836) | grass slope and paths with tree rows, a short pier (OSM `man_made=pier` at 96.1407, 16.8352) |
| **Inya east, Kabar Aye Pagoda Road / Inya Lake Hotel (96.146-96.156, 16.840-16.848)** | **natural banks**: trees and scrub to the water's edge, weed mats along the edge, the hotel on a peninsula with a pool, no wall |
| Inya north and the inner arms (Parami side, the islands) | natural and private compounds: trees to the water, small private jetties |
| **Kandawgyi south and west** | **wooden boardwalk** on posts 20-60 m out from the bank (OSM `highway=footway`, `bridge=yes`): pieces of 1,314 m (east / south), 376 m (west) and 92 m (`surface=wood`), plus many short links. About **2.1-2.3 km** in all, matching a state report's 7,307 ft. Piers: 160 m (96.1644, 16.7956), 148 m (96.1546, 16.7995), 34 m. A round viewing deck on the south shore (96.163, 16.7925). |
| Kandawgyi east (Karaweik, Kandawgyi Park) | lawns sloping to the water, closed tree canopy on the zoo / park side, Karaweik on the east shore |

### Rivers and channels in the box

- **Yangon River (Hlaing below Ahlone):** about **930 m wide at Sule**, about 1,070 m at Botataung, about 470-560 m at Kemmendine and Hlaing (OSM water, N-S / E-W transects). Muddy brown, measured median **(155, 140, 100)**. Tidal mud banks, wharves along the Strand.
- **Pazundaung Creek:** about **110-150 m** near Botataung / Pazundaung (sample tile; the bend makes the E-W transect read 214 m). It narrows upstream as Nga Moe Yeik Creek (~60-90 m, estimated from the z16 overview, not measured). Houses reach the water's edge and there are few trees. A 20 m side creek runs west at 96.172-96.174, 16.783.
- **OSM waterway lines:** rivers 118.7 km (57 ways), streams 66.0 km (101; Kyaik Ka San Chaung and others), drains **8.1 km** (38), canals 3.2 km (15).
- **Data gap:** the extract's water *areas* miss the Bago / Yangon confluence east of ~96.20, 16.77 and part of the Hlaing north of ~16.86 (pale in `canopy_map_whole_box.png`). `ground.py`'s per-body water level will have no polygon there, so add them from Overpass.
- **Street drains** (published, YCDC / UR slide): downtown drains are **0.45-0.6 m wide** (old) to **1.2 m** (new). They run along the kerb under a 1.2 m (4 ft) raised pavement, covered with concrete slabs, and many slabs are missing. In the suburbs there are open concrete channels by the road.
  - Game rule: a 0.6 m slab-covered gutter on every street; in suburbs, an open 0.8-1.2 m channel with a 0.4-0.8 m drop and a gap slab every 6-10 m.

---

## 3. Ground cover (Feb 2026 imagery)

**Canopy %** = share of land (buildings included) under tree crowns. **Open ground** = the non-building, non-water ground: tree / green grass / dry grass or bare / paved. Corrected values put the dense-area over-read back in.

| Area type (OSM) | ha | Canopy % (classifier) | **Use** | Open ground: tree / green / dry-bare / paved |
|---|---|---|---|---|
| Whole box (land) | 21,710 | 39 | **~33** | 40 / 8 / 31 / 14 (includes the brown paddies of Dala / Twante) |
| Parks / gardens | 279 | 60 | **55-60** | 61 / 14 / 12 / 6 |
| Golf courses | 232 | 38 | **40** | 38 / 29 / 18 / 5 (fairways olive, greens bright) |
| Universities / colleges | 261 | 51 | **48** | 54 / 9 / 17 / 10 |
| University of Yangon main campus | 60 | 54 | **50** | 60 / 12 / 15 / 7 |
| Military / cantonment | 159 | 40 | **40** | 41 / 16 / 29 / 6 |
| Cantonment N of Inya (golf + ponds) | 62 | 49 | **47** | 50 / 20 / 15 / 5 |
| Schools | 196 | 51 | **45** | 54 / 9 / 17 / 10 |
| Religious compounds | 164 | 44 | **38** | 47 / 5 / 19 / 19 |
| Shwedagon platform compound | 5.9 | 17 | **5** (the platform is paved; trees are on the slopes) | 16 / 5 / 17 / 62 |
| Residential (all) | 8,351 | 46 | **38** | 48 / 5 / 19 / 20 |
| Golden Valley / Bahan villas | 216 | 50 | **45** | 53 / 7 / 17 / 16 |
| Mayangone / 8-mile | 261 | 49 | **42** | |
| Kamayut / Hledan | 166 | 40 | **32** | |
| Thingangyun / S Okkalapa | 472 | 41 | **32** | |
| Tamwe / Pazundaung | 334 | 37 | **25** | |
| Sanchaung | 154 | 36 | **25** | |
| **Downtown grid** | 417 | 28 | **12** (shophouse blocks **5**; colonial compounds 40-50) | |
| Industrial | 1,601 | 32 | **25** | 35 / 7 / 34 / 17 |
| Commercial / retail | 204 | 32 | **20** | |
| Pitches / sports grounds | 96 | 19 | **15** | 19 / 16 / **45** / 10 (bare red-brown earth in Feb) |
| People's Park | 66 | 55 | **55** | 57 / **18** / 15 / 7 |
| Kandawgyi Park (land) | 51 | 64 | **62** | 67 / 13 / 9 / 4 |
| Thein Gottara Park | 40 | 60 | **58** | |
| National Races Village | 56 | 67 | **62** | |
| Inya Lake Pyay Road Bank | 4.2 | 57 | **45** | 57 / **29** / 7 / 6 |

### Lakeside bands (land only)

| Band | Inya canopy | Inya open ground: tree / green / dry / paved | Kandawgyi canopy | Kandawgyi open ground: tree / green / dry / paved |
|---|---|---|---|---|
| 0-15 m | **65%** | 65 / 19 / 7 / 3 | **66%** | 67 / 15 / 6 / 4 |
| 15-50 m | **56%** | 57 / 15 / 16 / 7 | **61%** | |
| 50-150 m | **47%** | 49 / 10 / 22 / 13 | **50%** | |

**Under trees in compounds and on campus the ground is dry grass, leaf litter and bare red-brown earth, not lawn.** Green lawn is limited to watered places: People's Park, the Inya bank strip, golf greens and fairways, the stadium, and Maha Bandula Park.

---

## 4. Trees

### Street trees

Method: z17 classes, a band 1-10 m outside the carriageway each side, sampled every 2 m. **"Kerb cover"** = share of road length with at least 40% crowns in that band.
- For a dual carriageway, L = outer kerb, R = median side.
- Trees per 100 m = canopy runs split into 12 m crowns. With rain-tree crowns of 20-25 m the count is about **0.5-0.6x** this.
- The downtown roads' cover is over-read (building shadows) by about 10 points.

| Road | km of ways | Kerb cover L % | R % | Carriageway shaded % | Trees /100 m per kerb (12 m crowns) | Real spacing estimate |
|---|---|---|---|---|---|---|
| U Wisara Rd | 9.8 | 72 | 69 | 46 | 6.0 | big trees every 15-25 m |
| Kan Yeiktha Rd (Inya Lake Park) | 1.9 | 72 | 70 | **66** | 5.9 | closed tunnel |
| Natmauk Rd (Kandawgyi) | 3.8 | 69 | 69 | **62** | 5.8 | closed tunnel |
| New University Ave | 1.4 | 52 | 77 | **68** | 5.7 | closed tunnel |
| Ahlone Rd | 3.7 | 57 | 72 | 58 | 5.7 | |
| **Inya Rd** | 3.8 | 69 | 73 | 46 | 6.0 | rain trees ~20 m apart, crowns meet |
| **University Ave** | 2.9 | 65 | 52 | 40 | 5.3 | 15-25 m |
| Zoological Garden Rd | 2.1 | 74 | 50 | 42 | 5.4 | |
| Shwe Gone Dine Rd | 6.4 | 60 | 51 | 46 | 5.0 | |
| Upper Pansodan Rd | 2.3 | 56 | 57 | 51 | 5.0 | |
| Kabar Aye Pagoda Rd | 20.8 | 63 | 41 | 40 | 4.7 | |
| Shwedagon Pagoda Rd | 3.4 | 53 | 48 | 36 | 4.5 | |
| **Pyay Rd** | 30.2 | 64 | **29** | 31 | 4.2 | outer kerbs well treed, median mostly bare; the lake side at the bund has few trees |
| Waizayandar Rd | 15.7 | 53 | 38 | 26 | 4.1 | |
| Insein Rd | 14.2 | 50 | 32 | 32 | 3.9 | |
| Bogyoke Aung San Rd | 6.1 | 47 | 38 | 28 | 3.9 | |
| Parami Rd | 8.4 | 63 | 35 | 28 | 4.5 | one side only |
| Anawrahta Rd | 12.0 | 37 | 38 | 22 | 3.5 (real ~2) | |
| Strand Rd | 12.5 | 42 | 30 | 24 | 3.4 | |
| Maha Bandula Rd | 6.9 | 34 | 25 | 24 | 2.9 (real ~1.5) | gaps of 50-100 m |
| Bayint Naung Rd | 19.5 | 45 | 13 | 18 | 2.7 | |
| Pyi Htaung Su Rd | 5.9 | 25 | 16 | 12 | 2.2 | |
| Downtown numbered streets (eye count, sample) | | | | | **~0-1** | almost none |

### OSM tree data

- **3,839 `natural=tree` nodes**, none with species (176 tagged broadleaved / evergreen).
- 92% sit in four 0.01 degree cells round Shwedagon, People's Park, Thein Gottara and Kandawgyi: 2,132 inside parks, 1,666 on streets near them.
- People's Park: **1,447 trees on 68 ha = 21 trees/ha**. Thein Gottara: **17/ha**. Nearest-neighbour spacing: median **11.5 m** (p25 8.9, p75 14.8).
- With People's Park's 55% canopy that gives a **mean crown of ~260 m² (~18 m across)**.
- **116 `natural=tree_row` ways, 11.45 km**, median 66 m, in the same area (Shwedagon / People's Park / Kandawgyi). They are absent from the extract's lines.json (its tag filter dropped `natural`), so `green.py` never sees them.
- Use the trees where mapped. Everywhere else they are incomplete, so the generator must fill.

### Crown sizes (z18, isolated crowns, 9,890 blobs)

- Diameter: p25 4.1 m, median 5.7 m, p75 9.0 m, **p90 15 m, p98 30 m**.
- Small blobs include crown fragments, so the real distribution leans larger.
- Big rain trees and banyans on Inya Road, University Ave and the campus read **20-30 m** across.

### Species and sizes

There is no Yangon street-tree inventory with numbers (YCDC or academic; searched). The mix below is an **estimate** from literature (post-Nargis reports name rain trees, mahogany, banyan and padauk as the street and park trees) and from the imagery (big umbrella crowns on avenues, palms by houses).

| Species (Burmese) | Where | Mature height / crown | Share to use |
|---|---|---|---|
| **Rain tree** *Samanea saman* (kokko) | avenues (Inya Rd, University Ave, U Wisara, Natmauk, Kan Yeiktha, Pyay Rd outer kerb), parks, campus | 15-25 m tall / **20-35 m** umbrella, trunk 1-1.5 m, low wide limbs | avenues 60%, parks 25%, compounds 15% |
| Mahogany *Swietenia* | avenues, campus | 20-25 / 10-15, dense dark oval | avenues 10%, campus 15% |
| Padauk *Pterocarpus indicus* (the roadside padauk; *P. macrocarpus* is the forest tree) | streets, compounds | 15-25 / 12-18; flowers yellow in April | streets 10%, compounds 10% |
| Tamarind *Tamarindus* (magyi) | old streets, monasteries | 12-20 / 10-15, feathery | 5-10% |
| Banyan / peepal *Ficus benghalensis / religiosa* | pagodas, monasteries, old junctions | 15-20 / **20-40**, aerial roots | religious 30%, else 3% |
| Gold mohur *Delonix regia* | parks, compounds | 9-12 / 12-15, flat top, red in Apr-May | parks 10% |
| Mango *Mangifera* | house gardens | 10-20 / 10-15, dense round dark | residential 25% |
| **Coconut palm** | house gardens, Inya / Kandawgyi banks, golf | 15-25 / 6-8 | residential 15%, lakeside 10% |
| **Toddy palm** *Borassus* | edges, the outer suburbs, fields | 15-30 / 5-7, fan leaves | suburbs and farmland 10% |
| Eugenia, Cassia, Lagerstroemia (pyinma), Mesua and others | | 8-15 / 6-10 | fill |

**Season:** in the February imagery several crowns are olive-brown or thin. Padauk, teak-like trees and some rain trees lose leaves late in the dry season. In Nov-Dec (now) everything is full.

---

## 5. Grass colour

| Measured (Feb, midday, sRGB median, z18) | RGB |
|---|---|
| Tree canopy | **(51, 71, 41)**, p25-p75 (37, 55, 29)-(69, 87, 56) |
| Green (watered) grass | **(83, 104, 60)**, (72, 94, 52)-(96, 118, 74) |
| Dry grass / bare earth | **(122, 114, 89)**, (99, 93, 68)-(155, 141, 108); playing fields red-brown earth |

- In February only watered lawns are green. Compound and campus ground under trees is straw and bare earth.
- After the monsoon (Jul-Dec) lawns are fully green. No dated monsoon pixels were measured, so that colour is an estimate: a brighter, more saturated green, about (70, 115, 45) on the satellite.
- **Use the post-monsoon look (Oct-Dec, also the present date):**
  - lawns and verges green, near (78, 112, 52) as a photo target. Run it through `look_calib.py` for the part colour.
  - Keep **bare red-brown earth** (about (150, 110, 75)) on pitches, paths and under dense compound trees, plus **leaf litter / dry patches on 15-20%** of open ground.
  - That keeps it lush and real.
- Do **not** use a uniform bright lawn green, and do not use the dry straw everywhere (today's screenshots).

---

## Recommended generator rules (metres; ×3 for studs at the new scale)

1. **Ground:** GLO-30 bare (opening 270 m + blur 45 m). Shwedagon plateau 53 m. Lakes: Inya **13.5**, Kandawgyi **12.0**. Rivers 0.5-1 m. Land within 15 m of a lake is 0.8-1.5 m above the water (bund 2 m at Pyay Road).
2. **Canopy target per area:** use the "Use" column above and place trees until the crowns cover it. Parks 55-60%, lakeside 0-50 m 60-65%, campus / villas 45-50%, residential 35-40%, dense flats 25%, downtown shophouse blocks ≤5%, Shwedagon platform 0.
3. **Tree density in parks:** 17-21 trees/ha, 9-15 m nearest neighbour. Big crowns (18 m mean) over lawn. Clumps, not a grid.
4. **Street trees by road:**
   - Avenues (Inya Rd, University Ave, U Wisara, Natmauk, Kan Yeiktha, Ahlone, New University Ave, Zoological Garden, Shwe Gone Dine): rain trees every **18-25 m on both kerbs**, crowns 22-30 m, meeting over the road (40-65% of the carriageway shaded).
   - Main roads (Pyay, Kabar Aye, Insein, Waizayandar, Bayint Naung): outer kerbs every 20-30 m, the median mostly open (low shrubs).
   - Downtown: trees only on Bogyoke, Sule and the compound frontages; numbered streets none.
   - Residential lanes: no street trees; garden trees overhang from plots instead.
5. **Compounds and campus:** trees 25-40 m apart in clumps. Ground under them is dry grass + bare earth, not lawn.
6. **Species by area:** use the share column. Banyan / peepal at every pagoda and monastery. Palms (coconut) in 15% of house gardens and along the Inya / Kandawgyi banks. Toddy palms in the outer north-east and Dala.
7. **Size spread:** crown diameter from a skewed spread: 40% at 6-10 m, 35% at 10-18 m, 20% at 18-28 m, 5% at 28-35 m (rain trees and banyans only). Height ≈ 0.7x crown for rain trees, 1.2x for mahogany / padauk.
8. **Banks:**
   - Inya Pyay Road side: the straight bund (concrete edge + railing + 3 m walkway + 12-18 m grass strip with a few trees).
   - Inya east and north: natural banks (trees to the water, no wall, weed mats).
   - Inya islands: 13 wooded islands from the OSM inner rings.
   - Kandawgyi: the 2.2 km boardwalk on posts from the OSM footway-bridge ways + 3 piers, 7 wooded islets, lawn slopes on the east.
   - Water colours: Inya (45, 72, 48), Kandawgyi (52, 84, 39), rivers (155, 140, 100).
9. **Drains:** a 0.6 m slab-covered gutter on every street (downtown 0.45-0.6 m, new 1.2 m), open channels in the suburbs. Use the 8.1 km of OSM `waterway=drain` and the 66 km of streams as channels.
10. **Grass:** post-monsoon green on lawns, verges, golf and parks. Bare red-brown on pitches and paths. Dry / litter patches on 15-20% of compound ground.
