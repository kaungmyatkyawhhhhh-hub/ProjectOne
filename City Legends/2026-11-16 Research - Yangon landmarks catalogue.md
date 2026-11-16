---
tags: [city-legends, research, yangon, landmarks, catalogue, blueprint]
created: 2026-11-16
---
# Research - Yangon landmarks catalogue (71 buildings and structures)

> Every recognisable landmark in the map area: position, real height and floors, midday facade description, references and priority. Photos (150, open licences) and OSM outlines: `Games/CityLegends/build/landmarks/refs/catalogue/<slug>/` (local, ~114 MB; sources.json per folder).
>
> **Errors found in today's landmarks:**
> - The models are about 1.9x too tall for their footprint (1.6 studs/m across, 3 up).
> - Karaweik, Maha Wizaya, Nga Htat Gyi, Convocation Hall and Junction City are placed 230-550 m off.
> - The Secretariat has no dome, Convocation Hall isn't red brick, and Bogyoke Market is white/cream with red roofs.
>
> All of it is fixed in the 1:1 rebuild ([[2026-11-16 Yangon rescale plan - 1 to 1 at player scale]]).


Made 16 Nov 2026. Every building or structure in the map box that people would recognise, beyond the two already modelled from photos (Myanmar Plaza / Myanmar Centre and Sedona).

**How to read it**
- One folder per landmark next to this file: `<slug>/` holds `footprint_osm.geojson` (the OSM outline(s), ODbL, from the Geofabrik extract in `build/osm_ygn/`), the downloaded Wikimedia Commons photos and `sources.json` (title, page, licence, author, time taken, `midday_ok`). Where OSM has no outline, `sat_esri_z*.jpg` + `.json` (Esri World Imagery, reference only, NOT openly licensed) is there to trace one.
- 150 openly licensed photos (CC BY / CC BY-SA / CC0 / PD) across 74 folders (some folders hold only a footprint or a satellite tile). Picked by EXIF time: 10:00-14:00 first, never evening (the colour rule). `midday_ok` = taken 09-15 h. A photo with no time is marked `hour: null`: check its light by eye before taking colours from it. Some folders also hold interior photos (Botataung, Kaba Aye, Chaukhtatgyi, Strand hall, Synagogue, Convocation Hall, Bogyoke Market): they count for the interiors rule (an inside is only built when photos of it exist online).
- Heights: real metres with the source. Wikipedia's tallest list uses Emporis estimates (italic in the article); Skyscraper Center (CTBUH) figures are given where they exist and differ.
- **Priority** = fame x visibility. A = everyone knows it / skyline or main-road landmark; B = known locally, seen from a main road; C = local or niche. **Difficulty** 1 (a box with a good facade) to 5 (organic, ornate, hundreds of parts).
- "In landmarks.json" refers to `tools/yangon/city/landmarks.json`; "model" means a built model in `tools/yangon/city/landmarks.py` (glb in `imports/sync/ygn_landmarks/`, data in `build/landmarks/<id>.json`).

**Scale note for the 9 built models.** They were built for the old plan: horizontal 1.6 studs a metre (the map), vertical 3 studs a metre (the cars). So each one is about 1.9 times too tall for its footprint. The owner's new rule (16 Nov) is 3 studs a metre everywhere, so all 9 need a rebuild (or a horizontal x1.875 stretch, then a re-check). Their coordinates come from OSM and are right; several `lat`/`lon` values written in `landmarks.json` are not (listed per entry).

## Summary table

| # | Landmark | slug | lat, lon | OSM | Real height / floors | landmarks.json | Photos (midday) | Pri | Diff |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Shwedagon Pagoda | shwedagon | 16.79834, 96.14958 | way/117379705, platform way/117388457 | 99 m stupa (112 m to the vane per Wikipedia infobox), on 51 m Singuttara Hill | yes, model `shw` | 2 (2) | A | 5 |
| 2 | Sule Pagoda | sule | 16.77437, 96.15875 | way/477836654, way/131745510 | 44.1 m (144 ft 9.5 in, Wikipedia) | yes, model `sule` | 4 (4) | A | 4 |
| 3 | Yangon City Hall | city_hall | 16.77489, 96.15961 | rel/5677100 | 3 floors (Wikipedia) / 4 (OSM) + central tiered tower | yes, model `ch` | 4 (4) | A | 4 |
| 4 | Independence Monument + Maha Bandula Park | independence_monument | 16.77312, 96.15933 | park way/129485365 | obelisk 46 m (landmarks.json; not in Wikipedia) | yes, model `indep` | 2 (2) | A | 2 |
| 5 | Secretariat (Ministers' Building) | secretariat | 16.77532, 96.16582 | way/264732913 | 2-3 floors, U-plan block, 6.5 ha | yes (no model) | 4 (4) | A | 4 |
| 6 | High Court (former) | high_court | 16.77306, 96.16089 | rel/2409553 | 3 floors + clock tower | no | 4 (4) | A | 4 |
| 7 | The Strand Hotel | strand_hotel | 16.76959, 96.16257 | way/102682120, ballroom way/185858884 | 3 floors | yes (no model) | 4 (1) | A | 3 |
| 8 | Botataung Pagoda | botataung | 16.76846, 96.17198 | way/180605242, way/314136068 | 40.1 m (131 ft 8 in) on a 29.3 m square base | yes, model `bota` | 4 (4) | A | 4 |
| 9 | Karaweik | karaweik | 16.79522, 96.16795 | way/117381678 | 2 decks, 82 x 39 m (Wikipedia) | yes, model `kara` | 2 (2) | A | 5 |
| 10 | Bogyoke Aung San Market | bogyoke_market | 16.78021, 96.15561 | way/23395611 | 2 floors + clock tower | yes (no model) | 4 (4) | A | 4 |
| 11 | Yangon Central Railway Station | central_station | 16.78169, 96.16137 | way/102685394 | 1-2 floors, pyatthat towers | yes (no model) | 4 (4) | A | 4 |
| 12 | Custom House | customs_house | 16.76977, 96.16055 | way/379864843 | 4 floors + clock tower | no | 4 (4) | A | 3 |
| 13 | Myanma Port Authority | port_authority | 16.76967, 96.16173 | way/391905730 | ~5 floors + tall clock tower | no | 4 (4) | A | 3 |
| 14 | Junction City + Pan Pacific | junction_city | 16.77901, 96.15404 | way/481323871 | tower 101 m (CTBUH), Pan Pacific 96 m / 25 fl | yes (no model), plus pan_pacific | 1 (1) | A | 3 |
| 15 | Sule Square | sule_square | 16.77743, 96.15838 | way/461661572 | 92 m (CTBUH), 22 fl (OSM) | no | 0 | A | 3 |
| 16 | Sule Shangri-La | sule_shangrila | 16.77863, 96.15842 | way/182860265 | 80.5 m, 22 fl | yes (no model) | 1 (1) | A | 3 |
| 17 | Sakura Tower | sakura_tower | 16.77903, 96.15937 | way/129485357 | 100 m, 20 fl (Wikipedia; OSM says 23) | yes (no model) | 0 | A | 2 |
| 18 | Centrepoint Towers (office + Pullman) | centrepoint | 16.77274, 96.15833 | way/129485363 (levels=2 is wrong) | office 110 m, hotel 96 m (CTBUH); 25 fl | no | 1 (1) | A | 3 |
| 19 | Dala Bridge (Myanmar-Korea Friendship) | dala_bridge | north landing ~16.76, 96.143 | road way/1219935185 | cable-stayed, opened 6 Feb 2026 | no | 1 (0) | A | 4 |
| 20 | Martyrs' Mausoleum | martyrs_mausoleum | 16.80245, 96.14759 | way/431832281, way/984908043 | low red arch (~10-15 m, unmeasured) | no | 3 (0) | A | 3 |
| 21 | Maha Wizaya Pagoda | maha_wizaya | 16.79491, 96.15222 | way/160698623, tower way/180612556 | not published (model used 40 m) | yes, model `wiz` | 4 (1) | A | 4 |
| 22 | Kaba Aye Pagoda + Maha Pasana Guha | kaba_aye | 16.85681, 96.15447 | way/186911800 | 33.8 m (111 ft) | yes, model `kaba` | 4 (4) | A | 4 |
| 23 | Chaukhtatgyi reclining Buddha | chaukhtatgyi | 16.81171, 96.16390 | way/117384553 | Buddha 66 m long; shed unmeasured | yes, model `chauk` | 4 (4) | A | 4 |
| 24 | Diamond Inya Palace | diamond_inya | 16.84991, 96.15110 | way/522822395 | 122 m est., 34 fl (OSM: 105 m, 33) | no | 0 | A | 3 |
| 25 | Times City (towers + mall) | times_city | 16.81632, 96.12885 | way/793349746/747/748, way/1557960810 | office tower I 105 m / 25 fl; residences 92 m; OSM 27 fl | no | 0 | A | 3 |
| 26 | Golden City (7 towers) | golden_city | ~16.8268, 96.1636 (unverified) | not mapped | 109.7 m, 33 fl each | no | 0 | B | 2 |
| 27 | General Post Office | general_post_office | 16.76946, 96.16385 | way/148773604 | 4 floors | no | 4 (3) | B | 3 |
| 28 | Central Telegraph Office | central_telegraph | 16.77380, 96.16127 | way/383573871 | 4 floors | no | 2 (2) | B | 3 |
| 29 | St Mary's Cathedral | st_marys | 16.77848, 96.16551 | way/395657539 | twin spires; 88.7 x 30.8 m plan | no | 4 (4) | B | 4 |
| 30 | Holy Trinity Cathedral | holy_trinity | 16.78007, 96.15411 | way/186939481 | single spire | no | 4 (2) | B | 4 |
| 31 | Immanuel Baptist Church | immanuel_baptist | 16.77403, 96.16052 | way/182859345 | twin white spires | no | 4 (4) | B | 3 |
| 32 | Yangon Region (Divisional) Court | division_court | 16.77048, 96.15944 | rel/16612695 | 3 floors, red domes | no | 4 (4) | B | 3 |
| 33 | University of Yangon Convocation Hall | convocation_hall | 16.83340, 96.13620 | way/879406697 | ~25-30 m block (unmeasured) | yes (no model) | 4 (4) | B | 2 |
| 34 | Inya Lake Hotel | inya_lake_hotel | 16.84433, 96.15289 | way/1281765358 (probable) | 5 floors | yes (no model) | 2 (0) | B | 2 |
| 35 | People's Park and Square | peoples_park | 16.79809, 96.14262 | way/374243908 | park | yes (no model) | 4 (4) | B | 3 |
| 36 | National Theatre | national_theatre | 16.78386, 96.14928 | way/252656023 | ~4 floors box | no | 3 (2) | B | 2 |
| 37 | Yangon General Hospital | ygh | 16.77817, 96.14979 | way/265735321 | 3 floors + tower | no | 3 (3) | B | 4 |
| 38 | Ngahtatgyi Buddha Temple | ngahtatgyi | 16.80850, 96.16250 | way/314121257 | Buddha 13.9 m on a 9.1 m pedestal | yes (no model) | 4 (4) | B | 4 |
| 39 | Thaketa Bridge (new, cable-stayed) | thaketa_bridge | 16.78530, 96.17922 | way/400623189 | twin pylons | no | 2 (2) | B | 3 |
| 40 | Maha Bandula Bridge | maha_bandula_bridge | ~16.7767, 96.1831 | way/395086043 | cable-stayed, 3 spans | no | 0 | B | 3 |
| 41 | Hledan flyover | hledan_flyover | 16.82654, 96.13078 | Pyay Rd ways 274922221, 514101297 | 1.7 km deck | no | 3 (3) | B | 3 |
| 42 | Other flyovers (Shwegondaing, Myaynigone, U Chit Maung, Bayint Naung, 8 Mile) | other_flyovers | see entry | see entry | decks | no | 0 | B | 2 |
| 43 | Lotte Hotel Yangon | lotte_hotel | 16.84436, 96.13768 | way/1525507325 | 104 m / 29 fl (residences) | no | 0 | B | 3 |
| 44 | M Tower | m_tower | 16.82596, 96.13049 | way/1514269236 | 111.2 m, 27 fl | no | 0 | B | 2 |
| 45 | Crystal Residences | crystal_residences | 16.81765, 96.13019 | way/471327872 ("Crystal Tower") | 90 m, 25 fl | no | 0 | B | 2 |
| 46 | Pearl Condo | pearl_condo | 16.81748, 96.15669 | way/374511963, way/374511964 | Block F 55 m (CTBUH), 20 fl (OSM) | no | 0 | B | 2 |
| 47 | Kaba Aye Executive Residence / The Central / Kanbe Towers | (none) | Kaba Aye Pagoda Rd | not mapped | 97 m / 27 fl; 97 m / 27; 90 m / 25 | no | 0 | C | 2 |
| 48 | Lanthit Yeiktha condominium towers | lanthit_condo | 16.77844, 96.14319 | way/1416073598, way/1416073599 | 111 and 115 m (OSM), 25 fl | no | 0 | C | 2 |
| 49 | Surti Sunni Jamah Mosque | surti_mosque | 16.77408, 96.15566 | way/439628149 | 4 floors + minarets | no | 4 (4) | B | 4 |
| 50 | Sri Kaali Amman Temple | sri_kali | not mapped (Little India, Latha/Pabedan) | none | gopuram ~15 m | no | 2 (2) | C | 4 |
| 51 | Kheng Hock Keong | kheng_hock_keong | 16.77259, 96.14865 | way/471718493 | 1-2 floors | no | 4 (4) | C | 4 |
| 52 | Musmeah Yeshua Synagogue | synagogue | 16.77423, 96.15382 | way/422795412 | 2 floors | no | 4 (2) | C | 3 |
| 53 | Lokanat Galleries (Sofaer's) | lokanat | 16.77138, 96.16182 | way/379864744 | 3 floors | no | 1 (0) | C | 3 |
| 54 | Inland Water Transport (Irrawaddy Flotilla) | inland_water_transport | Pansodan 44-54 | not found | 5-6 floors | no | 1 (0) | C | 2 |
| 55 | Pansodan / Strand banks | pansodan_banks | 16.7705-16.7725, 96.159-96.165 | 7 ways | 3-5 floors | no | 4 (4) | B | 3 |
| 56 | Myanma Railways HQ | railway_hq | 16.77997, 96.15814 | way/217129098 | 3 floors | no | 0 | B | 3 |
| 57 | Bogyoke Aung San statues | bogyoke_statue | Bogyoke Park ~16.796, 96.156 | none | 4-8 m | no | 4 (1) | B | 3 |
| 58 | Bogyoke Aung San Stadium | aung_san_stadium | 16.78381, 96.16052 | way/613396987 | stands ~12 m | no | 2 (1) | B | 3 |
| 59 | Thuwunna Stadium + Indoor Stadium 1 | thuwunna | 16.82137, 96.18676 | way/15059554, way/180596940 | 50,000 seats | no | 2 (1) | B | 3 |
| 60 | National Museum | national_museum | 16.78874, 96.14218 | way/428294069 | 5 floors | no | 1 (1) | C | 2 |
| 61 | Judson Church | judson_church | 16.83080, 96.13417 | way/879735942 | tall square tower | no | 1 (0) | C | 2 |
| 62 | Kyaik Ka San Pagoda | kyaik_ka_san | 16.83710, 96.19080 | way/1528171622 | unknown | no | 0 | C | 3 |
| 63 | Kyauktawgyi (Lawka Chantha) on Mindhamma Hill | lawka_chantha | 16.88460, 96.12318 | way/440018981 | marble Buddha hall | no | 1 (0) | C | 4 |
| 64 | Kandawgyi Palace Hotel (burnt 2017) | kandawgyi_palace | 16.79472, 96.16194 | not mapped | gone | no | 1 (night) | C | - |
| 65 | Hotels: Chatrium, Parkroyal, Governor's Residence | chatrium / parkroyal / governors_residence | see entries | 3 ways | 10 / 8 / 2 fl | no | 0 / 0 / 4 | C | 2 |
| 66 | Malls: Taw Win Centre, Junction Square, Dagon Centre, City Mall St John, Ocean | taw_win_centre / junction_square | see entries | ways | 4-16 fl | no | 0 | C | 2 |
| 67 | Emerald Bay towers | emerald_bay | 16.7837, 96.2078 | way/1000832972, way/1198784269 | 100 m, 32 fl | no | 0 | C | 2 |
| 68 | Inno City towers | inno_city | 16.8546, 96.1673 | 5 ways | 29-30 fl (OSM), 104-109 m | no | 0 | C | 2 |
| 69 | Bayint Naung Bridges (Hlaing River) | bayint_naung_bridge | 16.85617, 96.09763 | rel/13902908 | | no | 0 | C | 3 |
| 70 | Pansodan Bridge (over the station) | pansodan_bridge | 16.78052, 96.16209 | way/408895989 | | no | 2 (0) | C | 2 |
| 71 | Yangon Zoo | (none) | 16.79243, 96.15932 | way/377827695 | park | yes (no model) | 0 | C | 3 |
| - | Mailamu Pagoda | - | north of the box | - | | no | 0 | outside | |
| - | Thanlyin Bridge | - | 16.79, 96.23 (the box's east edge) | way/24940017 | 2.2 km | no | 0 | outside | |

Not found anywhere: Kanthaya Center (92 m, 22 fl, Mingala Taungnyunt; no OSM outline, no free photo), Paragon Residence (way/585502983, 97 m / 27 fl, Ahlon), Kaba Aye Executive Residence, The Central, Kanbe Towers: no openly licensed photos on Commons (Wikipedia's thumbnails for them are no longer on Commons).

## What is wrong in landmarks.json and the built models (checked against the references)

General:
- **Scale:** all 9 models at 1.6 studs/m across and 3 studs/m up (see the note above). Under the 3 studs/m rule they are ~47% too narrow for their height.
- **Wrong positions in landmarks.json** (the builders use OSM, so the models are placed right, but the JSON would mislead anyone reading it): `karaweik` 16.7915, 96.164 (real 16.7952, 96.1680, ~550 m off, and it is on the lake's EAST shore, not the west); `maha_wizaya` 16.7966, 96.1508 (real 16.7949, 96.1522, ~230 m); `nga_htat_gyi` 16.8104, 96.1645 (real 16.8085, 96.1625, ~300 m); `uni_convocation` 16.829, 96.136 (real 16.8334, 96.1362, ~490 m); `junction_city` 16.7808, 96.1555 (real 16.7790, 96.1540, ~250 m).

Per landmark (details in each section):
- `shw`: 98.5 m over the platform. Wikipedia's infobox now gives 99 m height and 112 m to the spire; the platform stands on a 51 m hill (the model's platform is 31 m up). Keep 99 m for the stupa and re-check the hill.
- `sule`: base octagon ~43 m across vs the OSM stupa outline 37 m; height right (44 m).
- `bota`: stupa base ~39 m vs the real 96 x 96 ft (29.3 m) base: a third too wide. Missing the pond on the east side with its covered red-and-white walkway and fountain (photo `Botahtaung_pagoda_pond.jpg`), the most photographed part after the stupa. The stupa was under bamboo scaffolding in the latest photo (renovation).
- `kaba`: five porches is right (Wikipedia: five porches). The porches are cream-white with gold arched pediments and tiered gold roofs; the model's white halls are close. Maha Pasana Guha (the man-made cave hall, 455 x 370 ft outside) is not modelled.
- `chauk`: the Buddha's soles are white in the model; in every photo they are rusty red-brown with gold 108-mark panels and gold toe rings. The shed's roof structure is dark red / maroon steel trusses inside (photos #1, #4), not grey. Figure ~72-78 m long in the model vs 66 m.
- `kara`: the twin hulls stand ~57 m across in the model vs 39 m real (Wikipedia floor area 82 x 39 m): ~45% too wide. Birds and hulls: gold birds, gold upper hull with a red band, green-roofed pavilions and a gold-green tiered spire (photos): matches.
- `ch` (City Hall): 4 floors in the model (OSM 4, Wikipedia 3). Colours right (bright white, pale blue-green trim, white-and-gold tiered roofs). Check the central tower height against photo #3 (the model's tower top is ~40 m).
- `indep`: fine in shape; base is a white drum with a gold rim and inscriptions (photo #4), the model's three white steps are a simplification. Chinthe at the foot: not seen in the photos, verify.
- `wiz`: terrace 87 m square vs the OSM compound 104 m; the stupa base (52 m) matches the OSM tower outline (54 m). Height not published anywhere found; 40 m is a guess.
- `secretariat` facts: "a central dome": **wrong**: the cupola and 8 of the 16 towers were destroyed in the 1930 Bago earthquake (Wikipedia). Today: red brick with yellow-cream bands, square corner towers with small domes.
- `bogyoke_market` facts: "ochre and white with red/green roofs": photos show white / cream walls, terracotta-red tile roofs and a white clock tower with a white dome. No ochre.
- `uni_convocation` facts: "red-brick and white colonial hall with a clock tower": **wrong**. It is a massive dark grey, weathered concrete/stucco block with three tall arched windows (green frames) over a cream ground-floor loggia with green canopies; no clock tower (the tall tower nearby is Judson Church's).
- `inya_lake_hotel` facts: "long low block": it is 5 floors, white Soviet-modernist (1958-62, Andreyev & Kislova) with a big entrance portico and a funnel-like rooftop structure.
- `sakura_tower` 20 floors / 100 m (Wikipedia) but OSM says 23 levels; `pan_pacific` says 23 floors: Wikipedia list 25, CTBUH 96 m.
- `nga_htat_gyi` "14 m seated Buddha inside a tiered-roof hall": the figure is right (45.5 ft), but it sits on a 30 ft pedestal under a steel shed like Chaukhtatgyi's; the five-tiered pagoda is a separate structure.

---

# Sections, by priority

## 1. Shwedagon Pagoda (`shwedagon`): A, difficulty 5
- **Where:** stupa 16.79834, 96.14958 (OSM way/117379705, 115 x 113 m base outline, 10,077 m2); platform way/117388457 (280 x 320 m). OSM also has the tiers as building:parts with heights (88.2 m octagonal dais, 95 m banana bud, 99 m bell/vane parts: ways 539300472-539300485, 780590505-780590520). Seen from everywhere; four stairways: south on Shwedagon Pagoda Rd, west on U Wisara Rd (lift), north (Martyrs' side), east (Bahan).
- **Height:** 99 m (Wikipedia infobox `height_max`), 112 m spire (same infobox); 51 m Singuttara Hill.
- **Facade (midday):** gold leaf from the bell up, the terraces gilded; white-gold small zedis round the base; shrine halls with gold and red tiered pyatthat roofs; marble platform (white with grey veins).
- **Refs:** 2 Commons photos (both midday). Already modelled in detail (`shw`, 128,854 triangles, 43 halls, 24 pavilions, 79 pagodas).
- **In landmarks.json:** yes. See the list above (height note, scale).

## 2. Sule Pagoda (`sule`): A, difficulty 4
- **Where:** 16.77437, 96.15875; the roundabout of Sule Pagoda Rd and Maha Bandula Rd; faces City Hall (NE), Maha Bandula Park (E). OSM stupa way/477836654 (37 x 37 m), grounds way/131745510 (94 x 85 m).
- **Height:** 44.1 m (Wikipedia: 144 ft 9.5 in).
- **Facade:** octagonal gold stupa from base to bell; round it at street level a ring of small shops with signboards; four entrances under gold multi-tier pyatthat porches; small gold zedis and white-gold shrines on the inner terrace (photos 2-4). Midday photos (all four 10 h).
- **Refs:** 4 photos; the fountain photo (#1) shows it from Maha Bandula Park.
- **In landmarks.json:** yes, model `sule`; base a little too wide (above).

## 3. Yangon City Hall (`city_hall`): A, difficulty 4
- **Where:** 16.77489, 96.15961, rel/5677100 (121 x 87 m, 9,397 m2). Front on Maha Bandula Rd facing Maha Bandula Park; west side on Sule Pagoda Rd (faces Sule).
- **Height/floors:** 3 floors (Wikipedia infobox) / 4 (OSM); 1926-36, U Tin (Burmese-revival). Central bay rises a storey higher with a tall white tiered roof.
- **Facade:** bright white stucco, pale blue-green (teal) accents on mouldings and window frames, big round-arched windows on the ground and main floors, Burmese peacock and naga mouldings; white-and-gold pyatthat roofs on the centre and corners (photos 1-4, all midday).
- **Refs:** 4 photos.
- **In landmarks.json:** yes, model `ch` (floors and tower height to check).

## 4. Independence Monument and Maha Bandula Park (`independence_monument`): A, difficulty 2
- **Where:** park way/129485365 (139 x 218 m, 7.5 acres) at 16.77312, 96.15933; bounded by Sule Pagoda Rd (W), Maha Bandula Rd (N), Maha Bandula Garden St (E), Konthe Rd (S). Faces City Hall, High Court, Sule.
- **Height:** 46 m obelisk (landmarks.json; no published figure found).
- **Facade:** white obelisk on a white drum with a gold rim and engraved panels (photo #4), five smaller white pillars round it; lawns, a fountain (seen in Sule photo #1), chinthe-topped gate.
- **Refs:** 2 photos (midday).
- **In landmarks.json:** yes, model `indep`.

## 5. Secretariat / Ministers' Building (`secretariat`): A, difficulty 4
- **Where:** 16.77532, 96.16582, way/264732913 (153 x 174 m). Whole block: Anawrahta Rd (N), Theinbyu Rd (E), Maha Bandula Rd (S), Bo Aung Kyaw St (W).
- **Height:** 2-3 floors; built 1889-1905 (Henry Hoyne-Fox). U-shaped. Cupola and 8 of 16 towers lost in the 1930 earthquake.
- **Facade:** red brick with yellow-cream bands and trim (Victorian "blood and bandage"), long arcaded verandas, square towers with small domes at the centre and corners, red tile roofs; a lawn and avenue in the middle (photos 1, 3, 4, midday).
- **Refs:** 4 photos; daily heritage tours mean interior photos exist online (assassination room, double spiral stair).
- **In landmarks.json:** yes, no model; "central dome" is wrong.

## 6. High Court (former) (`high_court`): A, difficulty 4
- **Where:** 16.77306, 96.16089, rel/2409553 (113 x 102 m, around a courtyard). Between Pansodan St and Maha Bandula Garden St; faces the park and the Independence Monument.
- **Height:** 3 floors + clock tower (~40 m, unmeasured); 1905-11, James Ransome, Indo-Saracenic.
- **Facade:** dark red brick with white/cream stone bands, arcades, a tall clock tower with a red-domed cupola on the corner, a central pediment on Pansodan (photos 1-4, 9-12 h).
- **Refs:** 4 photos.
- **In landmarks.json:** no.

## 7. The Strand Hotel (`strand_hotel`): A, difficulty 3
- **Where:** 16.76959, 96.16257, way/102682120 (37 x 60 m) + ballroom way/185858884. 92 Strand Rd, faces the river and the port.
- **Height:** 3 floors (1901).
- **Facade:** cream-white Victorian front, central portico with a pediment over the porch, rows of tall windows with shutters, flagpoles; white steps with blue edging at the entrance (photo #1, 14 h).
- **Refs:** entrance (midday), an 1895 photo (historic: for layout only), two lobby photos (interiors exist online). A modern midday street-front photo is still missing: search Flickr / Wikivoyage "Strand Hotel Yangon facade".
- **In landmarks.json:** yes, no model.

## 8. Botataung Pagoda (`botataung`): A, difficulty 4
- **Where:** stupa 16.76846, 96.17198, way/180605242 (29 x 28 m, `roof:shape=pyramidal`, gold); compound way/314136068 (103 x 214 m). Strand Rd, by the river and Botataung jetty.
- **Height:** 40.1 m (131 ft 8 in), 96 x 96 ft base; hollow (mirrored maze walkway inside).
- **Facade:** a broad gold bell-shaped stupa with a small gold hti; a pond on its east side with a red-and-white raised walkway, gold-roofed pavilions and a fountain; the inside is green-gold mirror mosaic (photos #1, #2).
- **Refs:** 4 photos (midday; #3 shows renovation scaffolding).
- **In landmarks.json:** yes, model `bota` (base too wide, pond missing).

## 9. Karaweik (`karaweik`): A, difficulty 5
- **Where:** 16.79522, 96.16795, way/117381678 (86 x 54 m); EAST shore of Kandawgyi Lake, off Nat Mauk Rd; seen across the lake from Kan Yeik Thar Rd and the boardwalk.
- **Height:** 2 floors; 82 x 39 m (Wikipedia); 1972-74, U Ngwe Hlaing. Spire height unpublished.
- **Facade:** two gold karaweik birds at the bow, gold upper hull with a red band, red-and-gold halls with green-and-gold tiered roofs, a central gold-green tiered spire (photos #1, #2, midday).
- **Refs:** 2 photos.
- **In landmarks.json:** yes, model `kara` (too wide; json position wrong).

## 10. Bogyoke Aung San Market (`bogyoke_market`): A, difficulty 4
- **Where:** 16.78021, 96.15561, way/23395611 (195 x 195 m). Bogyoke Aung San Rd; next to Holy Trinity and Junction City.
- **Height:** 2 floors (Wikipedia), 1926; clock tower over the main entrance.
- **Facade:** white/cream walls with red trim lines, terracotta-red tile roofs, arched shop fronts and verandas; a white clock tower with a white dome on the corner; cobbled inner streets (photos #1, #2, 11 h).
- **Refs:** 4 photos (2 interiors: gem stalls, textile shop).
- **In landmarks.json:** yes, no model ("ochre", "green roofs" wrong).

## 11. Yangon Central Railway Station (`central_station`): A, difficulty 4
- **Where:** 16.78169, 96.16137, way/102685394 (199 x 57 m). North of Bogyoke Rd, tracks in a cutting; Pansodan Bridge over the tracks.
- **Height:** mostly 1-2 floors with tall pyatthat towers; 5,110 m2 (Wikipedia); 1954, U Tin (Wikipedia text) / Hla Thwin (infobox).
- **Facade:** pale cream-white walls with grey weathering, a long arcaded front, square towers topped by tiered white-and-gold pyatthat roofs, a big porte-cochere (photos #2, #3, 10 h, overcast).
- **Refs:** 4 photos.
- **In landmarks.json:** yes, no model.

## 12. Custom House (`customs_house`): A, difficulty 3
- **Where:** 16.76977, 96.16055, way/379864843 (89 x 48 m). Strand Rd, faces the wharves.
- **Height:** 4 floors (OSM), 1912-16, John Begg.
- **Facade:** red brick with white bands and white window surrounds, a white columned portico, a tall white clock tower with a white dome at the corner (photos #3, #4, 9 h).
- **Refs:** 4 photos.

## 13. Myanma Port Authority (`port_authority`): A, difficulty 3
- **Where:** 16.76967, 96.16173, way/391905730 (39 x 80 m); Pansodan St / Strand Rd corner, by Pansodan jetty.
- **Height:** ~5 floors + a tall square clock tower (~45 m, unmeasured); 1920.
- **Facade:** cream-white, a tower with a red tiled hip roof, tall arched windows, "MYANMA PORT AUTHORITY" letters on the front; a pedestrian bridge crossing Strand Rd in front (photos #1, #4).
- **Refs:** 4 photos (two from the river: good for the waterfront skyline).

## 14. Junction City and the Pan Pacific (`junction_city`, `pan_pacific`): A, difficulty 3
- **Where:** 16.77901, 96.15404, way/481323871 (172 x 91 m, mall podium) + roof way/1558163943. Bogyoke Aung San Rd at Shwedagon Pagoda Rd; behind Holy Trinity.
- **Height:** Junction City Tower 101 m (CTBUH, 2017); Pan Pacific 96 m (CTBUH), 25 fl (Wikipedia list).
- **Facade:** podium of beige stone and glass; office tower in blue-green glass with a crown; hotel tower in light stone with window grid (from memory: verify; only one free photo, a view FROM the tower).
- **Refs:** 1 photo; links: https://www.skyscrapercenter.com/building/junction-city-tower/22713 and /pan-pacific-yangon/22714 (photos there, CTBUH copyright).
- **In landmarks.json:** yes (both), no model; json position ~250 m off.

## 15. Sule Square (`sule_square`): A, difficulty 3
- **Where:** 16.77743, 96.15838, way/461661572 (34 x 125 m). 221 Sule Pagoda Rd, beside the Sule Shangri-La.
- **Height:** 92 m (CTBUH, 2016), 22 fl (OSM). Office tower over a mall podium.
- **Refs:** none free; https://www.skyscrapercenter.com/building/sule-square/46348.

## 16. Sule Shangri-La (`sule_shangrila`): A, difficulty 3
- **Where:** 16.77863, 96.15842, way/182860265 (34 x 122 m). 223 Sule Pagoda Rd; Sakura Tower opposite.
- **Height:** 80.5 m, 22 fl, 1996 (Wikipedia), ex Traders Hotel.
- **Facade:** pale beige/white tower with a regular punched window grid (photo shows it in the distance down Bogyoke Rd).
- **Refs:** 1 photo; CTBUH page /sule-shangri-la-hotel/9296.

## 17. Sakura Tower (`sakura_tower`): A, difficulty 2
- **Where:** 16.77903, 96.15937, way/129485357 (34 x 30 m). Corner of Sule Pagoda Rd and Bogyoke Aung San Rd.
- **Height:** 100 m, 20 fl, 1999 (Wikipedia; Nihon Sekkei). OSM 23 levels.
- **Facade:** blue-green glass curtain wall with white frames (from memory: verify). No free photo found; Wikipedia's thumbnail "Sakura Tower, Yangon, Myanmar.jpg" is not on Commons.

## 18. Centrepoint Towers (`centrepoint`): A, difficulty 3
- **Where:** OSM way/129485363 at 16.77274, 96.15833 (50 x 122 m; its `building:levels=2` is wrong); Sule Pagoda Rd.
- **Height:** office tower 110 m, hotel tower (Pullman) 96 m (CTBUH); 25 fl (Wikipedia list).
- **Facade:** photo (13 h) shows two towers behind the Independence obelisk: one grey-beige stone with a stepped crown, one blue glass (check which is which on the CTBUH pages).
- **Refs:** 1 photo.

## 19. Dala Bridge (`dala_bridge`): A, difficulty 4
- **Where:** road way/1219935185 (2.4 km), mid-river 16.7596, 96.1427; crosses the Yangon River from Lanmadaw/Seikkan side to Dala. Opened 6 Feb 2026 (Wikipedia).
- **Structure:** steel cable-stayed, the country's longest; two tall pylons in the river (photo, under construction).
- **Refs:** 1 photo (construction; no time). Satellite tile `sat_esri_z16.jpg` (old image, before the deck).

## 20. Martyrs' Mausoleum (`martyrs_mausoleum`): A, difficulty 3
- **Where:** 16.80245, 96.14759, way/431832281 (50 x 47 m) + memorial way/984908043; by Shwedagon's north gate, Arzarni Rd.
- **Facade:** a low sweeping red concrete arch / curved roof over black tombs, red paving, Shwedagon behind (photos; times unknown).
- **Refs:** 3 photos.

## 21. Maha Wizaya Pagoda (`maha_wizaya`): A, difficulty 4
- **Where:** 16.79491, 96.15222, way/160698623 (104 x 104 m), stupa part way/180612556 (54 x 54 m). South of Shwedagon across Shwedagon Pagoda Rd / U Htaung Bo roundabout.
- **Height:** not published (1980). Hollow inside (forest-painted ceiling: interior photos online).
- **Facade:** gold stupa on a gold-and-white tiered terrace, gold pyatthat porches, a cream arched entrance gate with gold lettering on the road (photos #1, #2, #4).
- **Refs:** 4 photos (only #1 has a time).
- **In landmarks.json:** yes, model `wiz`; json position off.

## 22. Kaba Aye Pagoda and Maha Pasana Guha (`kaba_aye`): A, difficulty 4
- **Where:** 16.85681, 96.15447, way/186911800 (105 x 105 m); Kaba Aye Pagoda Rd; Buddhist Museum way/1274989975, Pitakataik library nearby.
- **Height:** 111 ft (33.8 m) (Wikipedia; another passage says 117 ft 6 in); 5 porches; hollow.
- **Facade:** gold stupa on a white-cream terrace; porches with gold arched pediments and tiered gold roofs (photo #2). Cave hall: rough stone-look outside, gold pillars and white tiers inside (photo #4).
- **Refs:** 4 photos (3 interiors).
- **In landmarks.json:** yes, model `kaba`.

## 23. Chaukhtatgyi (`chaukhtatgyi`): A, difficulty 4
- **Where:** 16.81171, 96.16390, way/117384553 (83 x 72 m); Shwegondaing Lane.
- **Size:** Buddha 66 m long (Wikipedia); glass eyes 1.77 x 0.58 m.
- **Look:** white face and hands, red lips, gold robe and crown with jewels; soles rust-red with gold 108-mark panels; under a high steel shed with maroon trusses and a corrugated roof (photos 1-4).
- **In landmarks.json:** yes, model `chauk` (soles wrong).

## 24. Diamond Inya Palace (`diamond_inya`): A, difficulty 3
- **Where:** 16.84991, 96.15110, way/522822395 (106 x 135 m, OSM height 105, 33 levels); north side of Inya Lake, U Htun Nyein St.
- **Height:** 122 m est., 34 fl (Wikipedia, CTBUH), the tallest building in Myanmar.
- **Refs:** none free; https://www.skyscrapercenter.com/building/diamond-inya-palace/22589.

## 25. Times City (`times_city`): A, difficulty 3
- **Where:** compound way/922255286 at 16.81632, 96.12885 (Hanthawaddy Rd x Kyun Taw Rd, Kamayut); towers ways 793349746 (141 x 101 m), 793349747, 793349748, 1557960810 (all `building:levels=27`).
- **Height:** Office Tower I 105 m / 25 fl (Wikipedia list), Residences 92 m (CTBUH).
- **Refs:** none free; CTBUH /times-city-residences/41763.

## 26. Golden City (`golden_city`): B, difficulty 2
- **Where:** Wikipedia gives 16.82683, 96.16361 (Yankin); in the Esri tile (`sat_esri_z18.jpg`) that point is a building site, with a tower to the NE: locate the 7 towers before building. Not in OSM.
- **Height:** 109.7 m, 33 fl each (Wikipedia), 7 towers + business centre (5 fl).
- **Refs:** none free.

## 27. General Post Office (`general_post_office`): B, difficulty 3
- **Where:** 16.76946, 96.16385, way/148773604 (34 x 39 m). Strand Rd at Bo Aung Kyaw St.
- **Height:** 4 floors, 1908 (AC Martin & Co., for Bulloch Brothers).
- **Facade:** mauve-red brick with pale yellow bands, lancet / pointed arched windows in rows, a metal-and-glass entrance canopy, stucco detail (photos 1-4).

## 28. Central Telegraph Office (`central_telegraph`): B, difficulty 3
- **Where:** 16.77380, 96.16127, way/383573871 (34 x 65 m). Pansodan / Maha Bandula corner (now MPT).
- **Height:** 4 floors, steel frame, 1913-17, John Begg.
- **Facade:** red brick wings, a cream stucco centre with a giant Ionic colonnade and an arched pediment; a phone mast on the roof (photos 9 h).

## 29. St Mary's Cathedral (`st_marys`): B, difficulty 4
- **Where:** 16.77848, 96.16551, way/395657539 (84 x 35 m). Bo Aung Kyaw St / Bogyoke Rd corner.
- **Size:** 291 x 101 ft (88.7 x 30.8 m), 1895-99, Joseph Cuypers, Gothic Revival.
- **Facade:** red-brown brick, twin west towers with grey-silver spires, a rose window; inside: striped red-white-blue brick arches (interior photos #1, #2).

## 30. Holy Trinity Cathedral (`holy_trinity`): B, difficulty 4
- **Where:** 16.78007, 96.15411, way/186939481 (53 x 32 m). Bogyoke Aung San Rd, next to Bogyoke Market.
- **Built:** 1886-94, Robert Chisholm (Indo-Saracenic). Single tall spire.
- **Facade:** salmon-red brick, a white-topped spire with pinnacles, steep red roofs (photos; file `Saint_Mary_s_Cathedral_Yangon_Myanmar.jpg` is misnamed on Commons: it is Holy Trinity).

## 31. Immanuel Baptist Church (`immanuel_baptist`): B, difficulty 3
- **Where:** 16.77403, 96.16052, way/182859345 (34 x 28 m). Maha Bandula Garden St / Maha Bandula Rd, opposite City Hall.
- **Facade:** all white, twin pointed white spires, a clock in the gable, blue crosses (photos, 9 h).

## 32. Yangon Region (Divisional) Court (`division_court`): B, difficulty 3
- **Where:** 16.77048, 96.15944, rel/16612695 (129 x 107 m); south of Maha Bandula Park on Strand Rd / Sule Pagoda Rd.
- **Facade:** mint-green and cream walls, white trim, terracotta-red domes on the corners and centre (photos 1-4).

## 33. University of Yangon Convocation Hall (`convocation_hall`): B, difficulty 2
- **Where:** 16.83340, 96.13620, way/879406697 (59 x 64 m); University Ave; Pyay Rd campus.
- **Facade:** a tall monolithic block, dark grey weathered render, three huge round-arched windows with green frames, a cream ground-floor loggia with green canopies, the flag on top (photos #1-#3, 15 h); hall inside with balconies (#4).
- **In landmarks.json:** yes (`uni_convocation`): description and position wrong.

## 34. Inya Lake Hotel (`inya_lake_hotel`): B, difficulty 2
- **Where:** way/1281765358 (37 x 132 m, 16.84433, 96.15289) is the most likely main block, with Yangon Convention Center way/522822402 beside it; Kaba Aye Pagoda Rd, east shore of Inya Lake. (Wikipedia's coordinate 16.8389, 96.1561 lands on the Micasa Hotel: wrong.)
- **Facts:** 5 floors, 1958-62, Soviet modernism (Wikipedia).
- **Facade:** white, horizontal bands of windows, a big flat entrance canopy on white columns (photo #1, 2005).

## 35. People's Park and People's Square (`peoples_park`): B, difficulty 3
- **Where:** way/374243908 (890 x 1216 m) west of Shwedagon; gate building way/186911682.
- **Look:** lawns, reflecting pool with the Shwedagon behind (photo #2), the white LOVE letters, a lake (photos, midday).

## 36. National Theatre (`national_theatre`): B, difficulty 2
- **Where:** 16.78386, 96.14928, way/252656023 (124 x 111 m); Myoma Kyaung Rd; Tatmadaw Hall nearby.
- **Facade:** a beige-tan box with a deep cornice band, a glass entrance, wide red-carpeted steps (photo #1), 1987-91 (Chinese aid).

## 37. Yangon General Hospital (`ygh`): B, difficulty 4
- **Where:** compound way/265735321 (584 x 269 m) at 16.77817, 96.14979; Bogyoke Rd.
- **Facade:** main block 3 floors, dark red brick with cream bands, a central tower with a cupola (photo #1); 1904-11, Henry Hoyne-Fox. New YGH: white modern blocks (#2).

## 38. Ngahtatgyi Buddha Temple (`ngahtatgyi`): B, difficulty 4
- **Where:** 16.80850, 96.16250, way/314121257 (72 x 58 m), Shwegondaing.
- **Size:** seated Buddha 45.5 ft (13.9 m) on a 30 ft (9.1 m) pedestal, 46 ft wide.
- **Look:** white face, gold jewelled robe, a carved gold backdrop under a steel shed (photos #3, #4).

## 39. Thaketa Bridge (`thaketa_bridge`): B, difficulty 3
- **Where:** way/400623189 at 16.78530, 96.17922 over Pazundaung Creek (road ways 265969033...).
- **Look:** cable-stayed, two white H-pylons, fan cables, red-white kerb paint, grey deck (photos, midday), next to the old Dawbon bridge.

## 40. Maha Bandula Bridge (`maha_bandula_bridge`): B, difficulty 3
- **Where:** way/395086043; road ways 180591583, 396270110 around 16.7737, 96.1805; Maha Bandula Rd over Pazundaung Creek.
- **Structure:** cable-stayed, three spans, semi-fan (Wikipedia). No free photo.

## 41. Hledan flyover (`hledan_flyover`): B, difficulty 3
- **Where:** Pyay Rd decks, ways 274922221, 514101297 (~1.7 km) at 16.82654, 96.13078; Hledan Centre, M Tower, Junction Square around it.
- **Look:** concrete deck on single piers, grey parapets (protest photos 2021, midday, show the deck and the junction).

## 42. Other flyovers (`other_flyovers`): B, difficulty 2
From the OSM bridge clusters (main roads only): Kabar Aye Pagoda Rd at Shwegondaing (ways 345641467/468, 1.7 km, 16.8049, 96.1560), Kabar Aye Pagoda Rd by Myanmar Plaza (ways 497076740, 505434555/556, 0.8 km, 16.8258, 96.1541), May Ni Gone overpass (way/463264259, 16.8033, 96.1375), U Chit Maung / East Horse Race Course Rd (ways 463191685/695, 16.8136, 96.1699), Bayint Naung pass-over (two levels, ways 253295190..., 16.8594, 96.1087), Pyay Rd at 8 Mile (ways 846314954, 856335051, 16.8650, 96.1429). No free photos; `sat_esri_z17.jpg` shows the Shwegondaing one.

## 43-48. Other towers (B/C, difficulty 2-3)
- **Lotte Hotel Yangon** (`lotte_hotel`): way/1525507325 (304 x 124 m) at 16.84436, 96.13768, Inya Lake west shore (Hlaing); residences 104 m / 29 fl (Wikipedia list). No free photo.
- **M Tower** (`m_tower`): way/1514269236 (58 x 34 m) at 16.82596, 96.13049, Hledan; 111.2 m, 27 fl (Wikipedia list).
- **Crystal Residences** (`crystal_residences`): OSM "Crystal Tower" way/471327872 (133 x 103 m, 20 levels) at 16.81765, 96.13019; 90 m / 25 fl (Wikipedia list).
- **Pearl Condo** (`pearl_condo`): ways 374511963 / 374511964 (20 levels) at 16.8168, 96.1566, Kabar Aye Pagoda Rd; CTBUH lists Pearl Center Block F 55 m.
- **Kaba Aye Executive Residence, The Central Tower I, Kanbe Towers A-C**: 97 / 97 / 90 m (Wikipedia list), not in OSM by name.
- **Lanthit Yeiktha condominium** (`lanthit_condo`): ways 1416073598 / 1416073599, `height` 111 and 115 m, 25 levels (OSM) at 16.7784, 96.1434, Lanmadaw. If OSM is right these are among the tallest in the city: verify.

## 49-56. Downtown heritage, smaller (B/C)
- **Surti Sunni Jamah Mosque** (`surti_mosque`): way/439628149 at 16.77408, 96.15566, Shwe Bon Tha St; grey-cream stucco, banded minarets with balconies, a central tower (photos 1-4, 11 h).
- **Sri Kaali Amman Temple** (`sri_kali`): Little India, not in OSM by name (search the satellite at Anawrahta Rd / 26th St); a colourful gopuram crowded with painted figures, gold Burmese-style roof trims (photos 1-2).
- **Kheng Hock Keong** (`kheng_hock_keong`): way/471718493 at 16.77259, 96.14865, Strand Rd / Sintodan St; green-glazed Fujian roofs with dragons, red columns and lanterns, carved grey stone front (photos 1-4).
- **Musmeah Yeshua Synagogue** (`synagogue`): way/422795412 at 16.77423, 96.15382, 26th St; hidden behind shophouses: a blue-white arched gate with a menorah; inside white columns and blue arches (photos).
- **Lokanat Galleries / Sofaer's Building** (`lokanat`): way/379864744 at 16.77138, 96.16182, Pansodan / Merchant; ochre-yellow ornate stucco, three floors, corner dome (photo).
- **Inland Water Transport (ex Irrawaddy Flotilla, 1933)** (`inland_water_transport`): Pansodan 44-54; white classical, giant pilasters (photo).
- **Pansodan / Strand banks** (`pansodan_banks`): Myanma Economic Bank (ways 380918959, 481401430: ex Bank of Bengal, 1914, Sule Rd / Strand), MADB way/250279038 (ex A. Scott & Co, 1902), Myanmar Foreign Trade Bank ways 311199041 / 486467895, MICB way/481360230, Myanma Export Import way/481868719, Ascott & Co way/496088887; mostly cream/grey stone classical fronts with columns (photos: Pansodan St, MEB 3).
- **Myanma Railways HQ** (`railway_hq`): way/217129098 (87 x 68 m) at 16.77997, 96.15814, Bogyoke Rd; red-brick Victorian (no free photo).

## 57-61. Monuments, stadiums, museum (B/C)
- **Bogyoke Aung San statues** (`bogyoke_statue`): the gold standing statue on a lawn mound in Bogyoke Aung San Park (north shore of Kandawgyi; photo `Bahan_...panoramio_23_`), a bronze statue (2021 protest photo), others at Insein and Revolution Park. Not in OSM.
- **Bogyoke Aung San Stadium** (`aung_san_stadium`): way/613396987 (159 x 224 m) 16.78381, 96.16052, beside the station; white-grey stands with a pale green main stand front (photos).
- **Thuwunna Stadium + National Indoor Stadium 1** (`thuwunna`): ways 15059554, 180596940; 50,000 seats (1985); indoor stadium white ribbed concrete (photos).
- **National Museum** (`national_museum`): way/428294069, Pyay Rd; tall grey-beige slab with vertical fins (photo #2).
- **Judson Church** (`judson_church`): way/879735942 at 16.83080, 96.13417, campus; grey concrete church with a tall square tower (photo, backlit).

## 62-71. Minor and edge cases (C)
- **Kyaik Ka San Pagoda** (`kyaik_ka_san`): way/1528171622 (75 x 78 m) at 16.83710, 96.19080, Thingangyun; no free photo.
- **Kyauktawgyi Buddha Temple, Mindhamma Hill** (`lawka_chantha`): way/440018981 at 16.88460, 96.12318 (Wikipedia/Commons call the marble Buddha hall on Mindhamma Hill "Kyauktawgyi"); one evening photo only.
- **Kandawgyi Palace Hotel** (`kandawgyi_palace`): destroyed by fire 19 Oct 2017 (Wikipedia). The only photo is a night shot before the fire. Model only if the site has been rebuilt (check a recent satellite).
- **Hotels:** Chatrium Royal Lake way/236949218 (10 fl), Parkroyal way/129226161 (8 fl), Governor's Residence way/428294068 (teak mansion, 2 fl, 4 photos).
- **Malls:** Taw Win Centre way/222162072 (10 fl), Junction Square way/247753397 (4 fl), Dagon Centre I/II ways 374912639 / 235380314, City Mall St John way/519001655, Ocean Supercenter way/429024565.
- **Emerald Bay** (Thaketa riverside) ways 1000832972 / 1198784269 (100 m, 32 fl); **Inno City** ways 1516826581-87 (29-30 fl), mall way/1523975148.
- **Bridges:** Bayint Naung Bridges 1-2 rel/13902908 (Hlaing River, on the box's west edge); Pansodan Bridge way/408895989 (over the station tracks, 2 photos from it); Bayli and Nga Moe Yeik bridges (Ngamoeyeik Creek).
- **Yangon Zoo:** way/377827695, opened 1906; walled park.
- **Outside the box:** Mailamu (Melamu) Pagoda (North Okkalapa, north of lat 16.89: not found in the extract); Thanlyin Bridge (way/24940017, mid at 16.7976, 96.2288: the west end is inside the box, the bridge mostly beyond 96.235); Star City's Galaxy Tower (way/867530011, 28 fl) is on the Thanlyin bank at 96.2286.

## Gaps and next steps
1. No free photos for the modern towers (Sakura, Sule Square, Diamond Inya, Times City, Golden City, Lotte, M Tower, Crystal, Pearl, Kanthaya, Pan Pacific): their facades need the owner's photos, Google Street View by eye, or the CTBUH pages (copyright, for looking only).
2. Strand Hotel needs a modern midday front photo.
3. Golden City, Kanthaya Center, Sri Kaali Amman and the Bogyoke statues need positions (satellite).
4. Heights still unmeasured: Maha Wizaya, Karaweik's spire, the Port Authority and High Court towers, City Hall's tower, Martyrs' Mausoleum. Measure from the photos against the floor heights, or from shadows on the satellite.
