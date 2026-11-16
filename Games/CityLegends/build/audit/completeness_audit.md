# Yangon map: completeness audit (2026-11-16, read-only)

> Owner: "there are missing buildings and places and features too", and "also missing decorations, borders, walls, like EVERYTHING".

**Scope.** The OSM box is lon 96.095-96.235, lat 16.75-16.89 (227 km² of land and water in townships). Every tagged OSM object in the box was read again from `build/osm_extract/myanmar-261112.osm.pbf`, with all its tags. The processed `build/osm_ygn/*.json` was not used for counting, because `tools/yangon/e0_extract.py` keeps only a fixed list of keys (see section 6).

That data was compared with what the generators make:
- `build/city/plots_{05,1,2,3}.json` (plots.py)
- `build/city/details_{05,1,2,3}.json` (details.py)
- `tools/yangon/city/landmarks.json` plus the landmark models
- terrain, roads and green per batch

No code was edited.

**Files.**
- This note.
- `build/audit/missing_features.json`: 5,448 missing features with name, category, lon/lat, OSM id, township, whether the spot is inside the built map, and a visibility score.
  - Boundaries and decorations are listed whether or not they have a name. So are stations, level crossings, rail, canals, utilities, fuel and water-edge items.
  - Other categories are listed only when they have a name.
  - It also holds 434 large named OSM buildings that have no game plot.

**How "the game has it" was decided** (per feature):
- Plot-type features (schools, hotels and the like): a game plot lies within 8 m of the feature, or the same OSM outline was used.
- Detail-type features (worship, sport, pool, parking, bus stop, gate, wall, footbridge, shop sign): a detail item of the matching kind lies within 15-60 m.
- Water, roads and bridges: the spot is inside a built batch (terrain.py and roads.py build these batch by batch).
- Anything within 120-150 m of a landmarks.json entry counts as covered.

Two cautions:
- "Has a plot at the spot" usually means a **generic** kit building stands there, not a station, a school or a cinema.
- Compound features (universities, hospitals) are judged at one point inside the compound, so they can show as missing when part of the compound is built.

---

## 0. The headline

1. **The game builds 86 km² of the 227 km² box (38%).** These townships have nothing at all:
   - North Dagon, South Dagon, East Dagon
   - Dala, Insein, North Okkalapa
   - Seikgyikanaungto, Twantay, Thanlyin

   Thaketa, Dawbon and most of Mayangone are 1-4% built. That puts about half of all the missing named places (Meilamu Pagoda, Insein, the golf courses, YTU, Pazundaung Market, Dala) outside the built area.
2. **Inside the built area, only 44% of real buildings have a game building on their spot.**
   - 98,477 real footprints lie inside the batches; 42,937 of them have a plot there.
   - 80% of the 116,058 game plots are invented infill (92,924).
   - The footprint blueprint already covers the fix.
3. **Whole feature systems are not built anywhere:**
   - railways: 161 km of track, 92 level crossings in the built area, platforms
   - ferries, ships and boats
   - fuel stations: 55 in the built area, 0 built
   - cemeteries: 6
   - golf courses and stadium stands
   - shrines, statues, fountains and ceremonial arches
   - steps and stairs: 119 in the built area
   - utilities: power plants, substations, masts, water towers
   - bus terminals and construction sites
4. **Pagodas are thin.**
   - 158 of the 193 pagodas and stupas inside the built area have no worship item near them.
   - `details.worship()` only looks at `amenity=place_of_worship` / `monastery`, so the 153 `man_made=stupa` outlines are never read.
   - Points inside a building plot are skipped by design.
5. **The landmarks.json position of Nga Htat Gyi is off.**
   - It is at 96.1645, 16.8104.
   - The real temple (w314121257) is at 96.16256, 16.80834, about 300 m away, so its site reads as missing.
   - The landmarks catalogue already lists this kind of error ("What is wrong in landmarks.json").

---

## 1. Coverage per township (buildings)

The real footprints are `build/footprints/ygn_footprints.json`: 224,831 outlines, OSM plus Microsoft. A footprint counts as covered when a game plot covers its representative point.

| Township | km2 in box | km2 built (batches) | Real footprints | in built batches | with a game plot at the spot | % | OSM outlines | OSM outline used as-is | Game plots (of which invented infill) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| North Dagon | 17.39 | 0.04 | 25,137 | 17 | 0 | 0% | 5,639 | 0 | 3 (3) |
| Mayangone | 24.59 | 6.9 | 20,895 | 2,642 | 901 | 4% | 1,320 | 458 | 5,073 (4,615) |
| Thaketa | 16.35 | 0.93 | 19,100 | 521 | 201 | 1% | 6,237 | 41 | 614 (573) |
| Thingangyun | 13.16 | 11.62 | 16,044 | 14,609 | 5,527 | 34% | 2,031 | 1,814 | 18,006 (16,192) |
| South Okkalapa | 8.12 | 7.4 | 15,550 | 14,625 | 5,547 | 36% | 726 | 656 | 13,030 (12,374) |
| South Dagon | 13.9 | 0.03 | 14,671 | 3 | 2 | 0% | 7,230 | 0 | 4 (4) |
| Dala | 12.44 | 0.0 | 13,535 | 0 | 0 | 0% | 3,980 | 0 | 0 (0) |
| Hlaing | 9.97 | 8.29 | 10,054 | 8,768 | 3,270 | 33% | 1,877 | 1,467 | 13,360 (11,893) |
| Insein | 7.76 | 0.0 | 8,765 | 0 | 0 | 0% | 639 | 0 | 0 (0) |
| Bahan | 8.45 | 8.45 | 8,662 | 8,662 | 3,265 | 38% | 2,367 | 1,972 | 10,971 (8,999) |
| Tamwe | 4.85 | 4.85 | 7,502 | 7,502 | 3,374 | 45% | 1,592 | 1,483 | 7,852 (6,369) |
| Kyeemyindaing | 6.82 | 1.82 | 6,572 | 3,341 | 1,941 | 30% | 2,036 | 1,784 | 2,771 (987) |
| Yankin | 4.83 | 4.83 | 6,309 | 6,309 | 2,229 | 35% | 858 | 801 | 6,891 (6,090) |
| Kamaryut | 6.73 | 6.25 | 5,661 | 5,597 | 2,517 | 44% | 2,007 | 1,712 | 6,932 (5,220) |
| Mingala Taungnyunt | 5.32 | 4.46 | 5,320 | 4,897 | 2,319 | 44% | 1,792 | 1,520 | 6,071 (4,551) |
| East Dagon | 4.84 | 0.0 | 5,146 | 0 | 0 | 0% | 384 | 0 | 0 (0) |
| Sanchaung | 2.39 | 2.39 | 4,539 | 4,539 | 2,699 | 59% | 2,859 | 2,526 | 3,869 (1,343) |
| North Okkalapa | 2.16 | 0.0 | 4,521 | 0 | 0 | 0% | 1,877 | 0 | 0 (0) |
| Dawbon | 4.22 | 0.41 | 4,381 | 115 | 27 | 1% | 16 | 2 | 197 (195) |
| Ahlone | 4.63 | 4.09 | 3,502 | 3,502 | 1,684 | 48% | 1,217 | 1,079 | 4,964 (3,885) |
| Seikgyikanaungto | 10.41 | 0.02 | 3,082 | 0 | 0 | 0% | 22 | 0 | 0 (0) |
| Dagon | 4.88 | 4.88 | 3,049 | 3,049 | 1,304 | 43% | 973 | 619 | 6,148 (5,529) |
| Lanmadaw | 2.79 | 2.66 | 2,547 | 2,547 | 1,589 | 62% | 1,681 | 1,353 | 2,392 (1,039) |
| Botahtaung | 5.76 | 3.33 | 2,504 | 2,059 | 1,116 | 45% | 899 | 755 | 2,340 (1,585) |
| Pazundaung | 1.22 | 0.66 | 2,088 | 1,677 | 688 | 33% | 471 | 365 | 1,003 (638) |
| Pabedan | 0.61 | 0.61 | 1,315 | 1,315 | 924 | 70% | 896 | 858 | 1,261 (401) |
| Latha | 0.6 | 0.6 | 1,275 | 1,275 | 1,106 | 87% | 1,242 | 1,187 | 1,501 (314) |
| Hlaingtharya (East) | 4.15 | 0.01 | 953 | 0 | 0 | 0% | 14 | 0 | 15 (15) |
| Twantay | 7.35 | 0.0 | 923 | 0 | 0 | 0% | 23 | 0 | 0 (0) |
| Kyauktada | 0.69 | 0.69 | 906 | 906 | 707 | 78% | 749 | 680 | 790 (110) |
| Thanlyin | 9.38 | 0.0 | 286 | 0 | 0 | 0% | 60 | 0 | 0 (0) |
| Dagon Seikkan | 0.01 | 0.0 | 32 | 0 | 0 | 0% | 23 | 0 | 0 (0) |
| **Total** | 227 | 86 | 224,826 | 98,477 | 42,937 | 19% | 53,737 | 23,132 | 116,058 (92,924) |

How to read it:
- Downtown is the best part of the map: Latha 87%, Kyauktada 78%, Pabedan 70%, Lanmadaw 62%. There OSM is dense and was used as-is.
- The township belt is the worst built part: Thingangyun, South Okkalapa, Hlaing, Yankin and Bahan sit at 33-38%. There the game has more plots than real buildings, but on invented spots.
- Fix: [[2026-11-16 Research - Real building footprints for Yangon]] (replace the infill with the 224,831 real outlines). It also covers the 9 townships that are not built at all.

**Large named buildings the game lacks.** 434 named OSM buildings have no plot. 122 of them are inside the built area. All are in the JSON (`category: building`). The biggest ones:

| Building | OSM | lon, lat | m² | Township | In built area |
|---|---|---|---:|---|---|
| Insein Railway Engine Factory | w449144625 | 96.10685, 16.88263 | 19,801 | Insein | no |
| City Mall | w389561794 | 96.19916, 16.85872 | 16,235 | North Dagon | no |
| Pro One | w702246058 | 96.22782, 16.87707 | 16,226 | East Dagon | no |
| Muditar Condo 1 | w542026945 | 96.11645, 16.86419 | 12,206 | Mayangone | no |
| Pin Lon Hospital | w5822816 | 96.20892, 16.86083 | 9,170 | North Dagon | no |
| Buddha Tooth Pagoda | w379875332 | 96.14938, 16.87530 | 9,097 | Mayangone | no |
| Yangon Command | w1274955958 | 96.14490, 16.86241 | 8,954 | Mayangone | no |
| NOVOTEL YANGON MAX | w471327865 | 96.13171, 16.81986 | 8,048 | Kamaryut | **yes** |
| Capital Hypermarket | w400578781 | 96.19548, 16.80275 | 6,828 | Dawbon | no |
| Myanmar Culture Valley | w374382807 | 96.14513, 16.79845 | 5,992 | Dagon | **yes** |
| Maha Pasana Guha (cave hall) | w288610692 | 96.15369, 16.85908 | 5,521 | Mayangone | no (next to Kaba Aye) |
| Gandama Wholesale | w253370679 | 96.15995, 16.86246 | 5,429 | Mayangone | no |
| Mya Nandar Housing | w565250734 | 96.11601, 16.85383 | 5,225 | Hlaing | **yes** |
| Myanmar Conference Center | w372940253 | 96.12917, 16.87522 | 5,114 | Mayangone | no |
| Aung Zaya / Thirimin Galar housing | w564570153, w564001142 | 96.1238, 16.7888 | 2,638 / 2,622 | Ahlone | **yes** |
| Jivitadana Sangha Hospital | w319506033 | 96.15600, 16.80326 | 2,414 | Bahan | **yes** |
| Customs House | w379864843 | 96.16063, 16.76981 | 1,972 | Kyauktada | **yes** (blueprint: catalogue #12) |
| Vintage Luxury Yacht Hotel (a ship) | w396572634 | 96.17528, 16.76574 | 1,827 | Botahtaung | **yes** |
| Practising High School, YIOE | w541658774 | 96.13344, 16.81803 | 1,800 | Kamaryut | **yes** |
| Sein Gay Har Shopping Center | w116292183 | 96.12878, 16.82633 | 1,757 | Kamaryut | **yes** |

Shwedagon, City Hall, Myanmar Plaza and the Meliá also show "no plot", but they are landmark models or the Myanmar Centre site. They are not missing.

---

## 2. Feature inventory (every category, the real count, and what the game does)

Notes on the columns:
- "Real count" is everything in the box; "built area" is the part inside batches 0.5 / 1 / 2 / 3.
- Blueprint links:
  - LC = [[2026-11-16 Research - Yangon landmarks catalogue]]
  - SF = [[2026-11-16 Research - Yangon street furniture and traffic life]]
  - SD = [[2026-11-16 Research - Real Yangon street detail survey]]
  - TW = [[2026-11-16 Research - Yangon terrain, water and trees]]
  - FP = [[2026-11-16 Research - Real building footprints for Yangon]]
  - SA = [[2026-11-16 Audit - Yangon sites 1 to 1]]
  - RD = [[2026-11-16 Audit - Yangon roads 1 to 1]]

### 2.1 Railways

**Yangon Circle Railway track**
- Real count: 346 ways, 161 km. Main line 99 km, of which 67.7 km is in the built area; yards 32 km; sidings 13.7 km.
- The game builds: **nothing**. heights.py only uses the rail lines for bridge clearance (17 studs over a rail).
- Blueprint: no.
- Missing:
  - the whole line, inside the built area too: ballast, two tracks, sleepers, the cutting / embankment, the fences beside it
  - the main line to Central
  - the Insein yards

**Stations and halts**
- Real count: 39 named stations (61 objects). Examples: Central, Pagoda Road, Pyay Road, Shan Road, Ahlone Road, Panhlaing, Kyeemyindaing, Hanthawaddy, Hledan, Kamayut, Thiri Myaing, Okkyin, Insein, Gyogone, Thamine, Yegu, Kanbe, Parami, Bauktaw, Tamwe, Myittar Nyunt, Mahlwagon, Pazundaung, Thingangyun, Nga Moe Yeik, Togyaunggalay, Tadagale, Kyauk Yay Twin, Hninzigon.
- The game builds: a **generic plot** on most station-building outlines (`same OSM outline`). Central is a plot styled by `plots.py` OVERRIDE, and the `central_station` landmark has no model.
- Blueprint: Central only (LC #11; SA).
- Missing:
  - platforms (60 platform areas, 0 built), canopies, footbridges over the tracks, the station signs
  - 21 stations with no plot at all: Hanthawaddy (96.12616, 16.81682) is inside the built area; Insein, Gyogone, Thamine, Yegu, Tadagale and Kyauk Yay Twin are outside it

**Level crossings**
- Real count: 148 (92 in the built area). The most are in Tamwe (26), Mingala Taungnyunt (16), Botahtaung (12), Thingangyun (10) and Pazundaung (10).
- The game builds: nothing.
- Blueprint: no.
- Missing: the crossings themselves (barrier arms, the gate-keeper hut, rail in the road, the bump), e.g. Ye Kyaw Level Crossing (96.17149, 16.78044).

**Rail yards and depots**
- Real count: 111 objects: yard tracks, the roundhouse, the turntable, `landuse=railway` (3).
- The game builds: nothing.
- Blueprint: no.
- Missing: the Central yards east of the station, and Insein yards plus the engine factory (outside).

**Railway bridges**
- Real count: 64 ways, 3.6 km (37 in the built area).
- The game builds: nothing.
- Blueprint: Pansodan Bridge over the station (LC #70) is a road bridge.
- Missing: all of them.

**Old tram lines and crossings**
- Real count: 9 disused or tram ways (9.4 km), and 56 tram crossings and stops on Strand Road.
- The game builds: nothing.
- Blueprint: no.
- Missing: the Strand Road tram rails left in the road.

**Airport**
- Real count: 0 in the box. Yangon International is at about 16.907, 96.133, about 2 km north of the box edge.
- The game builds: nothing.
- Missing: at most the approach path, or a far-view silhouette from the north edge.

### 2.2 River, port, water

**Ferry terminals and jetties**
- Real count: 18. The 6 that matter in the built area:
  - Nan Thida (Pansodan) ferry station (96.16167, 16.76825)
  - Botahtaung Terminal (96.17328, 16.76601)
  - Lan Thit Jetty (96.14189, 16.77244)
  - Kyee Myin Daing Terminal (96.12103, 16.80916)
  - Shwe Taung Tan Jetty No. 1 (96.14541, 16.77209)
  - No. 4 pier Wardan (96.13774, 16.77354)

  Outside the built area: Dala Ferry Station and jetty (96.15601, 16.76182), Pun Hlaing Jetty, Hlaing Terminal, Bayint Naung.
- The game builds: piers only as **flat concrete terrain** (terrain.py, batch 2: 60 of the 76 pier objects in the built area). No terminal building, no pontoon, no ramp, no boats.
- Blueprint: no. LC #54 (Inland Water Transport HQ) is a building only.
- Missing: the terminal halls, covered gangways, floating pontoons and ticket booths.

**Ferry routes**
- Real count: 3: Pansodan to Dala (762 m), Lanmadaw to Dala (669 m), and a 17 km river route.
- The game builds: nothing.
- Missing: moving ferries (the double-deck Dala ferries), the sampan rowing boats across to Dala, and cargo ships at the wharves.

**Ships and boats** (OSM does not map them)
- Real count, from general knowledge:
  - 3-6 Dala ferries in service
  - dozens of sampans at the Pansodan / Botahtaung steps
  - cargo ships and barges along the Strand Road wharves, Botahtaung and Ahlone
  - the Vintage Luxury Yacht Hotel moored at Botahtaung (96.17528, 16.76574)
  - Karaweik on Kandawgyi (built)
- The game builds: Karaweik only.
- Missing: everything else.

**Quays, wharves, port**
- Real count: 7: the Sule / Botahtaung / Lanmadaw / Ahlone wharf lines (3.7 km) and Thilawa-side quay areas (17.9 ha, outside).
- The game builds: the riverfront edge as "concrete quay edge" terrain (terrain.py codes c/k) in batch 2.
- Missing: the quay walls, bollards, cranes (3 mapped cranes), warehouses on the wharves and container stacks.

**Docks and boatyards**
- Real count: 19 (34.5 ha): Simmalaik Dockyard, Dala Boatyard (22.6 ha), the Dawbon docks and the Navy docks.
- The game builds: docks are river water in batch 2 (4 in the built area).
- Missing: the dry docks, slipways and boat hulls.

**Rivers and creeks**
- Real count: 168 ways, 160 km: the Yangon / Hlaing / Pazundaung rivers and their creeks.
- The game builds: water per batch (terrain.py, ground.py), 66 in the built area.
- Blueprint: TW.
- Missing: the parts outside the batches (Pazundaung creek north, Hlaing River west bank).

**Canals, drains, ditches**
- Real count: 58 ways, 12.7 km (25 in the built area). Plus 24 culverts (tunnel=culvert).
- The game builds: water where they are polygons. Line-only drains are **not** turned into channels.
- Blueprint: TW (in part).
- Missing: concrete-lined channels with parapets, culverts under roads, and the open drains beside lanes.

**Lakes and ponds**
- Real count: 689 water areas (3,529 ha including the rivers). 27 are named, e.g. Aung Mingalar Lake and Kan Thar Yar Lake (outside).
- The game builds: built inside the batches (101). Inya and Kandawgyi have embankments (green.py).
- Blueprint: TW.
- Missing: the ones outside the batches.

**Wetland**
- Real count: 89 areas (94 ha), mostly at the box edges.
- The game builds: nothing.
- Missing: marsh ground and reeds.

**Dams, locks, lock gates**
- Real count: 6.
- The game builds: nothing.
- Missing: the sluice gates on the creeks.

**Lighthouse and sea marks**
- Real count: 4: a lighthouse at Seikgyi (96.13086, 16.76906) and buoys.
- The game builds: nothing.
- Missing: everything (low priority).

### 2.3 Commerce

**Markets**
- Real count: 67 (47 areas, 38 ha). In the built area: Bogyoke, Theingyi, Nyaung Pin Lay and the township wet markets.
- The game builds: generic plots on 33 of them. Bogyoke is a plots.py OVERRIDE, and the landmark has no model.
- Blueprint: Bogyoke (LC #10; interiors).
- Missing:
  - the market look: long roofed halls, stall rows, tarps, the goods spill (SD 1G)
  - outside the built area: Pazundaung Market (96.17567, 16.78234), Insein Market, 7 Zay Market and No. 3 Market (Thaketa)

**Shopping centres and department stores**
- Real count: 99 OSM objects (shop=mall 56, department_store 43); 71 after dedup.
- The game builds: generic plots (48). Myanmar Plaza is mc3d. Junction City has no model.
- Blueprint: LC #14, #66; SA (Myanmar Plaza).
- Missing: City Mall St John, Ocean, Capital Hypermarket and Junction 8 (outside the built area), and every mall's real shape.

**Supermarkets**
- Real count: 228.
- The game builds: shop signs (145 have one within 25 m).
- Missing: 82 with no sign. City Mart is the most common chain.

**Hotels, guest houses, hostels**
- Real count: 466 (441 named).
- The game builds: plots (277). Sedona and the Meliá are sites.
- Blueprint: LC #65; SA.
- Missing:
  - 177 named with no plot
  - in the built area: Novotel Max (96.13171, 16.81986), Vintage Luxury Yacht Hotel, Pegu Club (96.14285, 16.78698)

**Cinemas and theatres**
- Real count: 39.
- The game builds: plots (25). No cinema facade.
- Blueprint: National Theatre (LC #36).
- Missing: Sanpya Cinema (96.14466, 16.77755), Mega Ace / Shwe Baho (96.17621, 16.81081), Nawaday Cinema, and the Thamada / Junction cineplex fronts.

**Billboards**
- Real count: **0 in OSM** (`advertising` is never used in Yangon). SD measured 0.5-2 per 100 m at main-road junctions, 10 × 4 m on columns or on rooftops.
- The game builds: nothing. The owner's rule is no invented boards, and mc3d dropped them.
- Blueprint: SD (density).
- Missing: only from real photos (Hledan, Myaynigone and Sule junctions). The owner must allow real ads first.

### 2.4 Education and health

**Schools and kindergartens**
- Real count: 546 (235 grounds, 193 ha).
- The game builds: plots.py gives school land 25% cover and a school style; details puts compound walls on the street side.
- Blueprint: no.
- Missing:
  - 219 named schools with no plot at their point; the biggest are in the built area: B.E.H.S (1) Lanmadaw (96.13727, 16.78416, 6.7 ha), High School No. 4 Ahlone, St Philomena's (Sanchaung)
  - the school look: the long 2-3 floor block with an open corridor, the green and white paint, the flagpole, the playground

**Universities and colleges**
- Real count: 55 (264 ha).
- The game builds: plots (35 at the point), at 15% cover.
- Blueprint: the Convocation Hall (LC #33); Judson Church (LC #61).
- Missing:
  - the University of Yangon campus (r16215806, 59 ha) is only partly built
  - YTU (Insein, 53 ha), the National University of Arts and Culture (South Dagon) and Myanmar Institute of Theology are outside the built area

**Hospitals**
- Real count: 132 (88 ha).
- The game builds: plots at 35% cover.
- Blueprint: Yangon General Hospital (LC #37).
- Missing:
  - in the built area: East Yangon General Hospital (96.17456, 16.77308, 3.4 ha), the ENT Hospital in Tamwe (96.17312, 16.80773, 5.2 ha), Grand Hantha (96.12287, 16.82050), Parami General (96.15624, 16.84975)
  - outside: Pinlon, Victoria, South Dagon, Thaketa General

**Clinics, doctors, dentists**
- Real count: 382.
- The game builds: shop signs (107).
- Missing: 259 with no sign. The fix is the sign data, not new buildings.

### 2.5 Religion

**Pagodas and stupas**
- Real count: **224** (187 areas, 32 ha); 193 are in the built area. The 217 figure in SF is the same set, before named `place_of_worship` pagodas are added.
- The game builds: `details.worship()` makes zedi items. It reads only `amenity=place_of_worship` / `monastery` and `landuse=religious`, and skips points inside a plot. Of all 224, 36 have a worship item near them.
- Blueprint: Shwedagon, Sule, Botataung, Maha Wizaya and Kaba Aye (models); Ngahtatgyi (LC #38).
- Missing:
  - **158 in the built area**, including Naung Taw Gyi (96.14981, 16.79961, on the Shwedagon hill), the Original Kabar Aye Pagoda (96.14989, 16.80255), Arr Nan Dar (96.19575, 16.83973), Shwe Nar Pan (96.18292, 16.82485), Sein Yaung Chi (96.15391, 16.78525) and Thein Pon Zedi (Sanchaung)
  - outside: Meilamu (96.15634, 16.88384), Thuwunna Myo Oo, Ywar Ma Zedi, Kyitewaing, Buddha Tooth Pagoda

**Monasteries and nunneries**
- Real count: 145.
- The game builds: monastery halls from worship() (35 have one near them).
- Blueprint: no.
- Missing: 85 in the built area. The Thayet Taw monasteries compound (96.14638, 16.77880, 4.9 ha) is the biggest.

**Other Buddhist places of worship**
- Real count: 386, mostly halls in compounds.
- The game builds: worship (95).
- Missing: 115 named, e.g. Koe Htut Gyi (Sanchaung).

**Mosques**
- Real count: 36.
- The game builds: worship() mosque (5).
- Blueprint: Surti Sunni (LC #49).
- Missing (26 named):
  - Surti Sunni Jamae (96.15556, 16.77414) and Mogul Shia (96.15659, 16.77411) in Pabedan
  - Muhammad Jann (Bahan, 96.17063, 16.80995)
  - Ta Chan Ped, Raunaq, the 52nd Street Masjid
  - the Zafar Shah dargah (96.15000, 16.78966)

**Churches and cathedrals**
- Real count: 56.
- The game builds: worship() church (15).
- Blueprint: St Mary's, Holy Trinity, Immanuel, Judson (LC #29-31, #61).
- Missing (24 named): **St Mary's Cathedral** (96.16554, 16.77847), St Anthony's, the Siyin Baptist church, St John's, St Francis, St Augustine's, U Naw Church and others.

**Hindu temples**
- Real count: 16.
- The game builds: worship() Hindu (5).
- Blueprint: Sri Kaali Amman (LC #50).
- Missing: Sri Kaali Amman (96.15467, 16.77734), Maha Vishnu (96.17137, 16.77669), and the Thingangyun temples.

**Chinese temples, synagogue, Chabad**
- Real count: 9.
- The game builds: the Chinese temple builder (3).
- Blueprint: Kheng Hock Keong and the synagogue (LC #51, #52).
- Missing: Kheng Hock Keong (96.14868, 16.77259), the Guanyin Gumiao temple, the Musmeah Yeshua synagogue (96.15385, 16.77424).

**Shrines** (building=shrine, wayside)
- Real count: 64, 62 of them in the built area (mostly the tazaungs on the Shwedagon platform and in big compounds).
- The game builds: nothing as an item. Shwedagon has its own shrines.
- Blueprint: Shwedagon (in part).
- Missing: nat shrines and spirit houses (see 7.2).

**Religious compounds** (landuse=religious)
- Real count: 52 (72 ha).
- The game builds: the cover rule (plots.py 15%) and compound walls.
- Missing: the compound look (see 7).

### 2.6 Civic

**Cemeteries**
- Real count: 6 (8.5 ha), all in the built area:
  - Kandawlay Sunni (96.16643, 16.78248, 2.5 ha)
  - Kandawlay Shia (96.16592, 16.78416)
  - Tamwe Muslim (96.17017, 16.81031, 2.1 ha)
  - the "War Memorial" cemetery in Sanchaung (96.13318, 16.81126, 1.5 ha)
  - Martyrs' Mausoleum (96.14767, 16.80239)
- The game builds: **nothing**. They are green land in plots.py (no buildings), with no graves, walls or trees.
- Blueprint: Martyrs' Mausoleum (LC #20).
- Missing: all of them.

**Police stations**
- Real count: 52.
- The game builds: plots (18).
- Blueprint: SF 2.8 (traffic booths).
- Missing: 25 named, and the junction police booths (not mapped; SF).

**Fire stations**
- Real count: 25.
- The game builds: plots (8).
- Missing: 16 named (Mayangone and the Fire Force HQ are outside). No red engine bays or tower.

**Government, courts, town halls, post offices**
- Real count: 292.
- The game builds: plots (180).
- Blueprint: Secretariat, High Court, City Hall, GPO, Telegraph, Divisional Court (LC).
- Missing: 102 named, e.g. the Traffic Control Center (96.14322, 16.79426).

**Embassies**
- Real count: 50, almost all in Bahan and Kamayut.
- The game builds: plots (44).
- Missing: the Korean Embassy compound (96.14625, 16.82380) and the Thai, Swiss and Australian points; their walls and flags.

**Military areas** (build as walls only)
- Real count: 18 (161 ha): Yangon Command (68 ha, 96.14761, 16.86218), Monkey Point Navy (32 ha, 96.19324, 16.76934), the Bayint Naung bridge guard area.
- The game builds: plots.py 12% cover; all three are outside the built area.
- Missing: perimeter walls with barbed wire, guard posts and gates. Do not build the inside.

### 2.7 Green and sport

**Parks and gardens**
- Real count: 85 (353 ha).
- The game builds: green.py puts park trees (P) in the built area. Kandawgyi and Inya have embankments, benches and lamps.
- Blueprint: TW; People's Park (LC #35).
- Missing:
  - park paths, lawns as their own material, park fences and gates, pavilions, playgrounds
  - outside the built area: the National Races Village (53 ha, 96.23154, 16.80245) and South Dagon Park

**Grass and flower beds** (landuse)
- Real count: 99 + 3.
- The game builds: nothing (only the median grass on roads).
- Missing: the roundabout gardens (U Htaung Bo and U Wisara roundabouts).

**Woods and scrub**
- Real count: 63 (194 ha).
- The game builds: trees in the built area (14).
- Missing: the rest.

**Playgrounds**
- Real count: 37.
- The game builds: **nothing**.
- Missing: Bo Sein Hman (Bahan, 96.16904, 16.81236), Mya Kyun Tha (Inya), the People's Park roller coaster point (96.1403, 16.7992).

**Pitches and courts**
- Real count: 131 (56 ha).
- The game builds: `details.sports()` (90).
- Missing: 6 named; the outside ones.

**Sports centres and tracks**
- Real count: 25.
- The game builds: sports (12).
- Missing: the Equestrian Club (North Dagon), the National Swimming Pool, the Badminton Federation.

**Stadiums and grandstands**
- Real count: 23 (18 ha).
- The game builds: plots on the stand outlines only. No pitch bowl, no floodlights.
- Blueprint: Aung San Stadium and Thuwunna (LC #58, #59).
- Missing:
  - **Thuwunna Stadium** (96.18680, 16.82140)
  - **Bogyoke Aung San Stadium** (96.16062, 16.78384)
  - Sa Lin Stadium (96.12537, 16.81262)
  - No. 2 National Indoor Stadium (96.13078, 16.85202)
  - South Dagon Football Stadium (outside)

**Golf courses**
- Real count: 8 (301 ha): Okkala (75 ha, 96.16610, 16.86021), the Military Golf Course (34 ha), the north golf course (92 ha, 96.14265, 16.88574), Pun Hlaing (51 ha), the Kyaikkasan driving range (in the built area, 96.16661, 16.82033).
- The game builds: **nothing**.
- Missing: all of them.

**Swimming pools and water parks**
- Real count: 66.
- The game builds: `details.pools()` (47).
- Missing: Yangon Waterboom (9.2 ha, Dawbon, outside), the Navy pool, Ko Kine pool.

**Zoo**
- Real count: 3.
- The game builds: the Yangon Zoo is a listed landmark with no model, and its ground is excluded from clutter.
- Blueprint: LC #71.
- Missing: the zoo itself (enclosures, the elephant and tiger houses, the gate), the Thaketa crocodile farm (outside) and the Hlawga-style animal park point at Kaba Aye.

**Botanical garden**
- Real count: 1 point: Botanical Garden at the University (96.13712, 16.83128).
- The game builds: nothing.
- Missing: everything.

### 2.8 Roads, parking, transport

**Fuel stations**
- Real count: **100** (27 forecourts); 55 in the built area.
- The game builds: **none of the real ones**. YangonSites builds one game fuel station (the `fuel_yangon` venue lot).
- Blueprint: no.
- Missing: canopies with the brand colours (Max Energy, Denko, MMTM, PT Power), pumps, the kiosk. E.g. Denko Botahtaung (96.17846, 16.77323) and Max Thingangyun (96.20110, 16.81959).

**Car parks**
- Real count: 207.
- The game builds: `details.parking()` surface lots (111).
- Missing: multi-storey car parks are skipped on purpose; the outside ones.

**Bus terminals**
- Real count: 46 (39 points). In the built area: the Shwe Man Thu highway terminal (96.16967, 16.85588, 2.1 ha) and Bandula Transportation (1.2 ha) in South Okkalapa, and the 59 bus terminal (Ahlone). Outside: the Dala bus terminal by the ferry.
- The game builds: **nothing**.
- Missing: all of them. Aung Mingalar (the big highway terminal) is outside the box.

**Bus stops**
- Real count: 1,056 (631 in the built area).
- The game builds: `details.bus_stops()` (383 have a shelter near them).
- Blueprint: SF 2.1.
- Missing: 248 in the built area with no shelter, and 425 outside.

**Toll booths**
- Real count: 7.
- The game builds: nothing.
- Missing: the Ahlone toll gate (96.12277, 16.78756) and the Thanlyin bridge tolls.

**Car service, car wash, dealers**
- Real count: 276.
- The game builds: shop signs (175).
- Missing: 85; the big showrooms (Sakura Auto Centre, Friendship Auto).

**Road bridges and flyovers**
- Real count: 243 ways (37.8 km).
- The game builds: roads.py and heights.py build every bridge and flyover in the built area (126).
- Blueprint: RD; LC #39-42, #69.
- Missing, outside the built area: Yangon-Dala Bridge (2.4 km, 96.14295, 16.76278), Thanlyin Bridges 1 and 3, Bayint Naung Bridges, and the creek bridges in Dawbon and Thaketa.

**Footbridges**
- Real count: 179 deck and stair ways (80 sites, SF).
- The game builds: `details.footbridges()` (18 placed).
- Blueprint: SF 2.17.
- Missing: 130 of the 179 ways have no footbridge item within 60 m.

**Bridge outlines** (man_made=bridge)
- Real count: 20.
- The game builds: via roads.
- Missing: the 11 outside the built area.

### 2.9 Land use

**Construction sites**
- Real count: 24 (36 ha). In the built area:
  - Myanmar Centre phase 2 (w463189672, 96.15638, 16.82665, 3.2 ha), **right beside the pilot district**
  - Old Myeinigon Bazaar (96.14067, 16.80650)
  - w626083678 (96.15368, 16.81475, 2.8 ha)
  - w470110528 (96.15364, 16.83033, 2 ha)
  - Kyeikkasan Housing
- The game builds: nothing. They are free land in plots.py and get infill buildings.
- Missing: hoardings, cranes, rebar frames, site huts. Note they are infilled with fake buildings now.

**Vacant land, farmland, landfill**
- Real count: 65 (91 ha), almost all outside the built area.
- The game builds: nothing.
- Missing: rough ground and field edges.

**Industrial zones**
- Real count: 132 areas (1,670 ha). Mostly outside the built area: the Thaketa, South Dagon, Hlaing Tharyar and Dawbon industrial zones.
- The game builds: plots.py at 45% cover (60 in the built area).
- Missing: the sheds, yards and walls of the industrial zones outside.

**Warehouses and works**
- Real count: 173.
- The game builds: plots (53).
- Missing: the Yuzana palm oil plant (10.5 ha, Thaketa), the Army Textile Factory, the Tissue Factory.

### 2.10 Utilities

**Power plants and substations**
- Real count: 31 (46 ha):
  - Ahlone power plants (r15863710 and 4 units, 96.1295, 16.7769, **in the built area**)
  - Thaketa gas plants (3 plants, 96.2246-96.2280, 16.811-16.817)
  - 18 substations
- The game builds: **nothing** (a plot on the Ahlone land only).
- Missing: turbine halls, stacks, switchyards and their fences.

**HV lines and pylons**
- Real count: 14 lines (21 km) and 69 towers or portals, mostly in Seikgyi and Ahlone.
- The game builds: nothing.
- Missing: the 230 kV line Hlaing Tharyar to Ahlone.

**Generators**
- Real count: 228 points, almost all rooftop solar.
- The game builds: nothing.
- Missing: rooftop panels (minor).

**Water towers, tanks, sewage works**
- Real count: 79: 64 storage tanks, 2 water towers, the Botahtaung sewage plant (2.3 ha, in the built area).
- The game builds: nothing as structures. Rooftop tanks are in shells.py.
- Missing: the ground tanks and towers, and the sewage plant.

**Telecom masts and towers**
- Real count: 42:
  - the TV Tower (96.13275, 16.81510, in the built area)
  - the MPT communication tower (Pazundaung)
  - Myanmar Radio (49 ha, Mayangone)
  - 19 masts
- The game builds: **nothing**.
- Missing: lattice masts. These are skyline items.

**Chimneys, cooling towers, cranes**
- Real count: 78 (47 chimneys, 28 cooling towers, 3 cranes).
- The game builds: nothing.
- Missing: everything (skyline items).

### 2.11 Map-wide gaps

**Townships not built at all**
- 9 townships: 0% of their buildings (section 1).
- The game builds: nothing.
- Blueprint: FP plus the rescale plan.
- Missing: everything.

---

## 3. Ranked: the 30 most visible missing items

Ranked by how much a player sees the gap, inside the playable map first. "Built area" means inside batches 0.5 / 1 / 2 / 3. LC#, SF and SA refer to the blueprints in section 2.

| # | Missing item | Category | lon, lat | OSM | Built area | Blueprint |
|---:|---|---|---|---|---|---|
| 1 | **Yangon Circle Railway track** (67.7 km of main line, 28 km of yard in the map; to Central) | railway | Central 96.16128, 16.78161 | 346 ways | yes | no |
| 2 | **Level crossings** on the Circle Line (92 in the map), e.g. Ye Kyaw | railway | 96.17149, 16.78044 | n3247399266 | yes | no |
| 3 | **Circle Line stations with platforms**: 39 stations, 60 platforms; Hanthawaddy has no building at all | railway | 96.12616, 16.81682 | n4460856838 | yes | no |
| 4 | **Thuwunna Stadium** (bowl, stands, floodlights) | stadium | 96.18680, 16.82140 | w15059554 | yes | LC #59 |
| 5 | **Bogyoke Aung San Stadium** | stadium | 96.16062, 16.78384 | w613396987 | yes | LC #58 |
| 6 | **Nan Thida (Pansodan) ferry terminal** plus the Dala ferries and sampans | ferry | 96.16167, 16.76825 | w102670179 | yes | no |
| 7 | **Botahtaung ferry terminal** and its jetties | ferry | 96.17328, 16.76601 | n3979430541 | yes | no |
| 8 | **158 pagodas and stupas** in the map with nothing on them, e.g. Naung Taw Gyi on Shwedagon hill | stupa | 96.14981, 16.79961 | w117389465 | yes | no |
| 9 | **Ngahtatgyi Buddha Temple** (its landmarks.json spot is 300 m off) | temple | 96.16256, 16.80834 | w314121257 | yes | LC #38 |
| 10 | **St Mary's Cathedral** (twin spires) | church | 96.16554, 16.77847 | w395657539 | yes | LC #29 |
| 11 | **Surti Sunni Jamae Mosque** and **Mogul Shia Mosque** (Pabedan) | mosque | 96.15556, 16.77414 / 96.15659, 16.77411 | w439628149, w481856406 | yes | LC #49 (Surti) |
| 12 | **Fuel stations**: 55 in the map, none built (e.g. Denko Botahtaung) | fuel | 96.17846, 16.77323 | w1416120293 | yes | no |
| 13 | **Kandawlay Muslim cemeteries** (Sunni and Shia, 4.2 ha) | cemetery | 96.16643, 16.78248 | w265631203, w265631204 | yes | no |
| 14 | **Martyrs' Mausoleum** and the **Memorial to the Fallen Heroes** | memorial | 96.14767, 16.80239 / 96.14877, 16.80315 | w431832281, w984908043 | yes | LC #20 |
| 15 | **Original Kabar Aye Pagoda** (Bahan) | stupa | 96.14989, 16.80255 | w923283762 | yes | no |
| 16 | **Kheng Hock Keong** Chinese temple | temple | 96.14868, 16.77259 | w471718493 | yes | LC #51 |
| 17 | **Shwedagon ceremonial gate arches** (5 arches on the approach roads) | arch | 96.15111, 16.79401 | w1553055047 (+4) | yes | Shwedagon blueprint (in part) |
| 18 | **Ahlone power plants** (4 units: turbine halls, stacks) | power | 96.12948, 16.77691 | r15863710 | yes | no |
| 19 | **Shwe Man Thu highway bus terminal** and Bandula Transportation (South Okkalapa) | bus terminal | 96.16967, 16.85588 | w565727209, w685027148 | yes | no |
| 20 | **East Yangon General Hospital** compound (3.4 ha) | hospital | 96.17456, 16.77308 | w395467037 | yes | no |
| 21 | **Tamwe Muslim Cemetery** (2.1 ha) | cemetery | 96.17017, 16.81031 | w265630616 | yes | no |
| 22 | **Sa Lin Stadium** (Kyimyindaing) | stadium | 96.12537, 16.81262 | w463340150 | yes | no |
| 23 | **TV Tower** (Kamayut; a skyline mast) | telecom | 96.13275, 16.81510 | n3218772648 | yes | no |
| 24 | **Thayet Taw monasteries compound** (4.9 ha) | monastery | 96.14638, 16.77880 | w480039814 | yes | no |
| 25 | **Sri Kaali Amman Temple** (gopuram) | Hindu | 96.15467, 16.77734 | n3201820744 | yes | LC #50 |
| 26 | **Myanmar Centre phase 2 construction site** (next to the pilot district, now invented infill) | construction | 96.15638, 16.82665 | w463189672 | yes | no |
| 27 | **Railway bridges** (37 in the map) | railway | e.g. over the Pazundaung creek | 64 ways | yes | no |
| 28 | **Dala ferry terminal and jetty** (the south end of the Pansodan ferry) | ferry | 96.15601, 16.76182 | w1298131273 | no (Dala) | no |
| 29 | **Yangon-Dala Bridge** (2.4 km, opened 2026) | bridge | 96.14295, 16.76278 | w1219935185 | no | LC #19 |
| 30 | **Meilamu Pagoda** (4 ha, North Okkalapa) | stupa | 96.15634, 16.88384 | w399545334 | no | no |

Next in line:
- Okkala Golf Course (r2517812, 96.16610, 16.86021)
- Military Golf Course (w309212008)
- Pazundaung Market (w396277593, 96.17567, 16.78234)
- Yangon Technological University (w389511639, 96.11979, 16.87631)
- Thanlyin Bridge (w24940017, 96.22870, 16.79750)
- Yangon Command walls (w1274955959)
- Monkey Point Navy walls (w395054733)
- the zoo's real enclosures (w377827695)
- No. 2 National Indoor Stadium (w1211078327)

---

## 4. Blueprints that already cover parts of this (link, do not redo)

- Railways, ferries, boats, fuel stations, cemeteries, stadium bowls, utilities and bus terminals have **no blueprint yet**. These are the new research jobs.
- Single landmark buildings (stations' Central, the stadiums, the churches, mosques and temples listed above, the bridges):
  - [[2026-11-16 Research - Yangon landmarks catalogue]]
  - [[2026-11-16 Audit - Yangon sites 1 to 1]]
  - [[2026-11-16 Research - Shwedagon 1 to 1 blueprint]]
- Buildings: [[2026-11-16 Research - Real building footprints for Yangon]], [[2026-11-16 Research - Yangon building kit references]], [[2026-11-16 Critique - Yangon kit vs real photos]].
- Street furniture, bus stops, signals, footbridges, police booths, median fences: [[2026-11-16 Research - Yangon street furniture and traffic life]], [[2026-11-16 Research - Real Yangon street detail survey]].
- Water, lake edges, trees: [[2026-11-16 Research - Yangon terrain, water and trees]].
- Roads, bridges, flyovers: [[2026-11-16 Audit - Yangon roads 1 to 1]].

---

## 5. Missing generator work (what to add, by tool)

| Tool | Add |
|---|---|
| new `rail.py` (+ Studio placer) | track on ballast (1,000 mm metre gauge, double on the Circle Line), sleepers as a texture, platforms from `railway=platform`, station canopies, level crossings (barrier arms, hut, rails flush in the road), rail fences, rail bridges (girders), the Central yards. roads.py already keeps 17 studs over rail. |
| new `river.py` | ferry terminals (hall, covered gangway, pontoon), jetty steps (ghats), sampans, Dala ferries on the 3 routes, moored ships and barges at the wharves, quay bollards and cranes, the dry docks |
| details.py `worship()` | read `man_made=stupa`, `building=pagoda` and named pagodas (`ဘုရား`, `စေတီ`, `zedi`, `paya`) too. Build the stupa on its real outline even inside a plot (replace the plot). Add Shwedagon-style arches (`man_made=ceremonial_gate`) and chinthe pairs at each pagoda gate. |
| details.py new kinds | `fuel` (canopy, pumps, kiosk, brand colour from `brand` / `name`), `cemetery` (low graves in rows, wall, trees), `playground`, `golf` (fairway grass, bunkers, flags, a clubhouse), `stadium` (bowl, stands, floodlight masts), `busterminal` (bays, sheds, ticket offices), `construction` (hoarding, crane, frame), `military` (wall, wire, guard post), `power` (switchyard fence, transformers, stacks), `mast` (lattice tower), `tank`, `shrine`, `statue`, `fountain`, `flagpole`, `steps` |
| plots.py | stop infilling `landuse=construction` land and cemeteries. Stadiums, markets, malls and stations need their own styles, not generic `mass`. |
| landmarks.json | fix `nga_htat_gyi` (96.16256, 16.80834). Add Thuwunna, Aung San Stadium, St Mary's, Surti mosque, Kheng Hock Keong and Martyrs' Mausoleum (all already in the LC blueprint). |
| e0_extract.py | see section 6: it drops the tags most of these features need |

---

## 6. Why the processed OSM files hide features

`tools/yangon/e0_extract.py` → `build/osm_ygn/*.json` is what every generator reads. It loses these:

- **points.json keeps one key / value per point**, and only these:
  - `power` pole / tower
  - `natural=tree`
  - `highway` bus_stop / traffic_signals / street_lamp
  - `amenity` place_of_worship / fuel / restaurant / cafe / bank / marketplace
  - `shop`
  - `man_made=water_tower`
  - `barrier=gate`

  So these points never reach the generators:
  - railway stations (31), level crossings (148), ferry terminals (15)
  - statues (134), memorials, fountains (19), flagpoles, planters
  - police, fire, schools, hospitals and clinics as points
  - masts, toll booths, bollards, playgrounds (26 points)
- **areas.json** keeps only `landuse, leisure, natural, water, waterway, amenity, man_made, place, aeroway, parking, historic, tourism, sport, golf`. These are dropped:
  - `power` (substations, plants)
  - `railway` (platforms, roundhouse)
  - `military`, `public_transport`, `shop` (malls, supermarkets), `barrier` areas, `office`, `government`, `healthcare`
- **lines.json** keeps `waterway, railway, barrier, power`. It keeps no `highway=steps` (that is in roads.json, but nothing builds it) and no `route=ferry`.

The fix is to extract all tags, as this audit did with pyosmium (`scratchpad audit_cmp/extract.py`, 160,325 tagged objects in the box).

---

## 7. Small built features and decorations (owner: "decorations, borders, walls, like EVERYTHING")

How to read the counts:
- The OSM count is for the whole box, with the built-area share in brackets.
- "Density" is the real rate where OSM does not tag the item, from [[2026-11-16 Research - Real Yangon street detail survey]] (SD) and [[2026-11-16 Research - Yangon street furniture and traffic life]] (SF). [est] = from photos and general knowledge, not measured.
- Game numbers are the items in `details_{05,1,2,3}.json`.

### 7.1 Boundaries

**Compound walls round every compound**
- OSM: `barrier=wall` 66 ways, 10.4 km (56 in the built area); `retaining_wall` 6.
- Real density where not tagged:
  - Every school, monastery, pagoda, hospital, embassy and villa has a wall on all sides. The street side is usually 1.8-2.4 m: rendered brick, a coping, often painted.
  - Township streets run 60-90% wall frontage [est, SD 1C / 1E].
- The game now: `details.compound_walls()` (6,158 pieces), **street side only**, plus `osm_walls()` (80 pieces). 36 OSM walls in the built area are not built (cut by plots and roads).
- Fix:
  - wall all sides of every compound plot (school, monastery, embassy, hospital, religious and military land)
  - real colours per type: pagoda walls white with gold or red bands; school green / white
  - keep the OSM walls that a plot cuts by moving them, not dropping them

**Fences and railings**
- OSM: 16 (`fence` 15 ways, 2.7 km; `cable_barrier` 1).
- Real density [est]:
  - chain-link round pitches and the rail line
  - steel railings along both lakes and the canals
  - SF 2.9: median pedestrian fences on main roads at bus stops and junctions, 50-200 m long
- The game now:
  - sport fences round courts (`sportfence`)
  - OSM fences (33 pieces)
  - **no lake or canal railings** (green.py's embankment line format S/P/T/B/L has no railing)
  - **no median fences**
- Fix:
  - a railing line along every embankment segment (S lines) and canal edge
  - median fences from the SF rule
  - rail-side fences with the rail tool

**Hedges**
- OSM: 7 (all in the built area).
- Real density [est]: clipped hedges at villas, embassies and Inya Road compounds, inside the wall.
- The game now: osm_walls builds hedges (3 matched).
- Fix: add hedges inside villa and embassy walls.

**Gates and gate pillars**
- OSM: 612 (603 points, 498 in the built area). There are also 37 lift gates, 2 toll gates and 1 sliding gate among them.
- Real density: 2-4 gates per 100 m of compound wall (SD), 3-5 m wide.
- The game now: `gate` items (3,308), steel sliding gates between two pillars. **214 OSM gates in the built area have no gate within 15 m.**
- Fix:
  - snap the missing OSM gates to the nearest wall
  - add lift-gate arms (car parks, compounds)
  - add pagoda gate arches with chinthe in place of the sliding gate on religious land

**Bollards, blocks, jersey barriers**
- OSM: 15 (all in the built area) plus 1 jersey barrier.
- Real density [est]: 4-8 concrete bollards at every pagoda, hospital and mall entrance; blocks at closed lanes; jersey barriers at embassy fronts and some medians.
- The game now: nothing.
- Fix: a `bollard` kind at compound gates of religious / civic / mall land and at the OSM points.

**Kerb stones**
- OSM: 28 `barrier=kerb` areas.
- Real: every main road and downtown street; red and white or black and white paint at junctions and bus stops (SF 2.7).
- The game now: roadmesh.py kerb faces KR / KW / KG with paint.
- Fix: done on mapped roads. The rescale needs the real 15-20 cm kerb height (RD).

**Guard rails and median barriers**
- OSM: 1 cable barrier.
- Real [est]: W-beam guard rails on the flyover ramps (Hledan, Shwegondaing, Bayint Naung) and the bridge approaches.
- The game now: deck parapets (W boxes) only.
- Fix: guard rails on the ramp sides from heights.py's ramp spans.

**Steps and stairs**
- OSM: `highway=steps` 214 ways in all; 139 not on a footbridge (121 in the built area). Among them: the Shwedagon stairways (W 204 m, N, E ×2) and the Chaukhtatgyi stairs.
- Real [est]: 3-6 steps up to almost every shophouse plinth, monastery and school block; flights up the pagoda hills.
- The game now: Shwedagon's covered stairways (landmarks.py). Other steps: **nothing** (2 matched).
- Fix: a `steps` item on each OSM steps line; a plinth step strip on every shophouse ground floor (shells.py).

**Footpaths**
- OSM: 1,450 ways (118 km), 1,031 in the built area.
- Real: park paths, campus paths, lake walks.
- The game now: nothing, apart from the Kandawgyi boardwalk and the Inya embankment walk in green.py.
- Fix: paved path strips in parks and campuses.

**Traffic islands**
- OSM: 20.
- Real: black and white painted noses (SF 2.18).
- The game now: 1 matched.
- Fix: concrete island noses at the mapped points and at channelised junctions.

### 7.2 Decorations

**Statues and artworks** (chinthe pairs, Bogyoke statues)
- OSM: 136 (`tourism=artwork` 134, statue 37), 113 in the built area.
- Real density [est]:
  - one chinthe pair at every pagoda and monastery gate (about 1-4 pairs a pagoda)
  - Bogyoke Aung San statues (Bogyoke Park, LC #57)
  - roundabout statues
- The game now: chinthe only on the landmark models (`landmarks.chinthe()`). 96 OSM artworks in the built area are not built.
- Fix:
  - a `statue` kind (plinth + figure) at the OSM points
  - chinthe pairs at every pagoda gate (worship items)

**Roadside shrines and nat shrines**
- OSM: 64 `building=shrine`, 1 wayside shrine and 1 nat shrine (Dawbon, n14175619602).
- Real density [est]: 1 spirit house or Buddha shelf per 100-200 m of township street, at big trees and junctions; one in most compounds (SF 2.18).
- The game now: nothing.
- Fix: a `shrine` kind (a small gabled house on a post, flowers, a red or gold roof) at big street trees and lane mouths.

**Fountains**
- OSM: 31 (19 points, 12 basins), 28 in the built area. Examples: the Elephant Fountain in People's Park (96.14193, 16.79616) and Maha Bandula Park.
- The game now: only those inside landmark grounds (Independence Monument). 19 named or unnamed are missing.
- Fix: a `fountain` kind (round basin, jet).

**Flagpoles**
- OSM: 6.
- Real density [est]: one per school, government office, hospital, embassy and military gate (about 300 in the built area); the national flag.
- The game now: nothing.
- Fix: a flagpole at the front gate of every school / civic / embassy compound.

**Archways and gateway arches**
- OSM: `man_made=ceremonial_gate` 6, all on the Shwedagon approaches (96.1466-96.1511, 16.7883-16.7955).
- Real [est]:
  - pagoda entrance arches over the road at every big pagoda
  - ward welcome arches ("... ရပ်ကွက်") on many township streets, about 1 per ward entrance
- The game now: nothing.
- Fix: a `gatearch` kind, with real Burmese text only from photos.

**Plaques, clock towers**
- OSM: clocks 0 tagged.
- Real: the clock towers are part of their buildings (Bogyoke Market, High Court, Custom House, Port Authority, the Convocation Hall).
- The game now: those buildings have no models.
- Fix: build them with their building blueprints (LC).

**Planters and flower beds**
- OSM: 15 planters and 3 flower beds (the Hanthawaddy roundabout floral sculpture, w180602884).
- Real [est]: concrete planters along downtown pavements and mall fronts; roundabout flower beds.
- The game now: nothing (only median grass).
- Fix: planters on mall and hotel frontages; beds in the roundabouts.

**Street banners, bunting, Buddhist flags**
- OSM: not mapped.
- Real [est]:
  - Buddhist flags on poles at every monastery and pagoda gate (2-6 a gate)
  - bunting across lanes at festivals (Thingyan in April, Thadingyut in October)
  - vinyl banners on fences
- The game now: nothing.
- Fix: flags at religious gates all year; bunting as a seasonal event layer.

**Signage gantries and overhead direction signs**
- OSM: not mapped.
- Real: SF 2.6. 1-2 regulatory or direction signs per 100 m on main roads; gantries before the flyovers.
- The game now: nothing.
- Fix: SF design, using only real text.

**Objects on display**
- OSM: 8. The Fokker F27 in People's Park (96.14423, 16.79453), the M4 Sherman (96.17030, 16.79331), the M351, and the Dhammazedi inscription.
- The game now: 1 matched.
- Fix: model the airliner in People's Park and the tank.

**CCTV and speed cameras**
- OSM: 35 (13 speed cameras).
- Real: on poles at main junctions.
- The game now: nothing.
- Fix: a camera on the signal pole at the mapped points.

**Benches, bins, toilets, telephones, post boxes**
- OSM: 117 (benches 18, toilets 53, post boxes 17).
- Real: SF 2.18. Orange YCDC wheelie bins at bus stops, about 1 per stop and 0.5 per 100 m downtown.
- The game now: benches on the lake walks only.
- Fix: bins at bus stops, post boxes at the mapped points, park benches.

**Tree rows and single trees**
- OSM: 116 tree rows (11.4 km) and 3,839 trees.
- The game now: built in the built area (green.py).
- Fix: done.

### 7.3 Ground details

**Paving patterns and tiled forecourts**
- OSM: not mapped (`surface` tags only on roads).
- Real [est]:
  - pagoda platforms and forecourts in white and terracotta tiles
  - mall and hotel forecourts in stone pavers
  - shophouse plinths in tiles
  - downtown pavements in concrete slabs and pavers
- The game now: the Myanmar Centre plinth paving (mc3d); the street pavement material.
- Fix: a forecourt pad (paver texture) in front of every hotel, mall, bank and pagoda plot.

**Drains and gutters**
- OSM: 42 `waterway=drain` (lines).
- Real (SD): slab-covered drains along both kerbs of every downtown and township street (slabs 0.5 × 1 m, broken gaps); open drains on lanes; 3-5 grates per 100 m on main roads.
- The game now: nothing.
- Fix: a drain-slab strip mesh along the pavement edge (roadmesh.py), open drains beside the lanes (`lane` class).

**Manholes**
- OSM: 0.
- Real [est]: 2-4 per 100 m of road.
- The game now: nothing.
- Fix: decals on the R mesh.

**Culverts**
- OSM: 24 (`tunnel=culvert` on drains, streams and canals).
- The game now: nothing; the road just crosses.
- Fix: a parapet and headwall where a road crosses a mapped drain.

**Steps up to buildings, ramps, raised plinths**
- OSM: not mapped.
- Real (SD): shophouse ground floors 0.3-0.6 m above the pavement, with 2-4 steps; ramps at hospitals and malls.
- The game now: shells.py has no plinth.
- Fix: a plinth and step strip on the shop front edge (shells.py front edge).

**Car-park markings**
- OSM: 207 car parks.
- The game now: `details.parking()` white bay lines (111 lots).
- Fix: done for the built area.

**Potholes and patches**
- OSM: not mapped.
- The game now: `patch` items (2,087, on the traffic lanes).
- Fix: add potholes and puddles on the lanes [est 1-3 per 100 m].

### 7.4 Building details

**Awnings**
- The game now: shells.py has a tarp awning on shop fronts. kit.py (pilot) has `awning()`.
- Missing: awnings on upper-floor windows (kit only).

**Balconies**
- The game now: shells.py has grilled balcony cages on walk-up fronts.
- Missing: open colonial balconies and verandas (downtown).

**AC units**
- The game now: kit.py `ac_unit()` (pilot only).
- Missing: **not in shells.py** (the live generator).

**Water tanks**
- The game now: shells.py makes 1-3 rooftop tanks a building.
- Missing: done.

**Satellite dishes**
- The game now: kit.py `small_dish()` (pilot).
- Missing: not in shells.py.

**Laundry**
- The game now: kit.py `laundry()` (pilot).
- Missing: not in shells.py.

**Roof clutter** (sheds, stair rooms, aerials)
- The game now: shells.py has a stair room and tanks; kit.py `roof_clutter()`.
- Missing: aerials, rooftop sheds and solar panels (228 OSM generators).

**Drainpipes, weeds, wires on facades**
- The game now: kit.py has `drainpipe`, `weeds` and `street_wires` (pilot); details.py has power poles with wires.
- Missing: not in shells.py.

**Signs**
- The game now: shells.py sign boards; details `shopsign` with the OSM names.
- Missing: done (no invented text).

The kit pilot already has most of these. The gap is that the live `shells.py` / d24_bmesh path never got them.

### 7.5 Water edges

**Jetties and piers**
- OSM: 168 `man_made=pier` (105 areas, 63 lines; 76 in the built area).
- The game now: flat concrete terrain (batch 2).
- Fix: deck, piles, pontoon, rail.

**Steps to the water (ghats)**
- OSM: not mapped.
- Real [est]: concrete steps at every ferry jetty and at Botahtaung / Pansodan, where the sampans land.
- The game now: nothing.
- Fix: steps at each ferry terminal.

**Lake walls**
- The game now: green.py embankments (Inya near main roads, all round Kandawgyi).
- Real: TW bank types. Inya's west and north shores are natural banks.
- Fix: the wall face and railing (see 7.1).

**Boardwalks**
- The game now: Kandawgyi boardwalk (green.py: benches and lamps every 44).
- Fix: deck planks and posts (the real boardwalk is a teak deck on piles).

**Lily pads and lotus**
- OSM: not mapped.
- Real [est]: patches along the Kandawgyi and Inya edges and in the township ponds.
- The game now: nothing.
- Fix: floating pad clusters near shore segments.

**Quay walls, wharf bollards, cranes**
- OSM: 7 quays and 3 cranes.
- The game now: the quay edge terrain.
- Fix: see 2.2.

---

## 8. Method and limits

- All counts are from OSM (©OpenStreetMap contributors, ODbL), the 12 Nov 2026 Geofabrik extract. It was cropped to the box and read with pyosmium.
- Areas are clipped to the box. A closed way with an area is counted once. Townships are the OSM `admin_level=7` boundaries.
- OSM under-maps Yangon:
  - shrines, flagpoles, bollards, lamps, billboards and drains are almost absent
  - only about 24% of the buildings have an OSM outline (53,738 of 224,831)

  "Real count" for those items is a floor. The densities in section 7 are the better guide.
- Game checks are by distance (8-60 m), so a near miss counts as built and an offset one counts as missing. Spot-check before acting on a single item.
- Scripts (not part of the repo), in the session scratchpad `audit_cmp/`:
  - crop and extract: `crop.py`, `crop2.py`, `extract.py`
  - categorise and match: `analyse.py`
  - buildings and townships: `fpcov.py`, `bcov.py`
  - the JSON: `mkjson.py`
