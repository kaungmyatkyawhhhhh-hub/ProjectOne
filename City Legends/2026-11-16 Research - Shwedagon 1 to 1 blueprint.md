---
tags: [city-legends, research, yangon, shwedagon, landmark, blueprint]
created: 2026-11-16
---
# Research - Shwedagon Pagoda 1 to 1 blueprint

> The modelling blueprint for Shwedagon, the most important landmark.
> - **Stupa:** 99.36 m tall (from the trustees' official per-tier breakdown), with every tier's height and width.
> - **Orientation:** the whole complex is turned 17 degrees anticlockwise from north.
> - **Platform:** 213 x 278 m, with the stupa off-centre.
> - **Stairways:** four, with their real lengths, step counts and widths.
> - **Around the stupa:** the 12 planetary posts, both bells, Naungdawgyi and the 72 footprints, all in `platform_plan.json` (metres from the stupa centre).
> - **Colours:** gold (212, 175, 92), from midday photos only.
>
> Files: `Games/CityLegends/build/landmarks/refs/shwedagon/` (32 open-licence images, sources.json). The game's current Shwedagon is wrong in shape, scale, orientation and layout (12 points listed below); it is rebuilt from this.


Gathered 16 Nov 2026 for the 1:1 Yangon rescale (3 studs = 1 m, SH = SV = 3, platform Y0 = 58 m x 3 = 174 studs).
All sizes are in **metres**. Multiply by 3 for studs.
Data files in this folder:
- `sources.json`: every image with its licence and author, plus the text and data sources.
- `platform_plan.json`: OSM footprints, posts, bells, trees, stairs and elevators, in the stupa frame below.

Source key:
- **[OFF]** Board of Trustees of Shwedagon Pagoda, official site, "About Shwedagon" and the place pages (shwedagonpagoda.org.mm). This is the primary source.
- **[OSM]** OpenStreetMap, read through Overpass on 2026-11-16. It includes a detailed 3D `building:part` model of the stupa.
- **[PH]** Measured by me on Commons photos in this folder.
- **[SD]** Sacred Destinations.
- **[M2D]** myanmar2day guide.
- **[WP]** Wikipedia (EN, MY, DE).

---

## 0. Datum and frame

| Item | Value |
|---|---|
| Stupa axis (centre of the bell) | **16.79834 N, 96.14959 E**. The game's `SHW.centre` (31636, 3830) already matches this to within 1 m. |
| Platform (main terrace) level | **58 m above sea level**, 190 ft [OFF]. Game: Y0 = 174 studs. |
| **Rotation** | The whole complex is turned **17 deg anticlockwise** from true north [OSM: plinth edges, platform outline and all four stairways agree]. The "north" face looks to bearing 343, east to 73, south to 163, west to 253. |
| Stupa frame used below | Origin at the stupa axis on the platform floor. **+E** points along bearing 73 and **+N** along bearing 343, in metres. To get true east/north: `x_true = E*cos17 - N*sin17` and `y_true = E*sin17 + N*cos17`. |
| Height | **99.36 m (326 ft 0 in) from the platform to the tip of the diamond bud, hti included** [OFF: the eight parts below add up to exactly 326.00 ft]. |

**99 or 112 m?** The trustees' own breakdown includes the hti and totals 326 ft (99.36 m). The "325 ft without the hti" line on English Wikipedia contradicts that table. The 112 m / 367 ft (MY-WP: 368 ft / 112.17 m, plus 344 ft / 105 m) figures have no breakdown. They probably measure from a lower datum, such as the middle terrace or the street. **Build 99.36 m above the platform.**

---

## 1. The main stupa, tier by tier

### 1a. Official height table [OFF] with widths [OSM, PH]

| # | Part (Burmese) | Height of the part | From -> to (m above the platform) | Plan / width | Notes |
|---|---|---|---|---|---|
| 1 | Plinth (pha-nut-taw) | 6.13 m [OSM 20.11 ft]; guides say 6.4 m / 20-21 ft [SD] | 0 -> 6.13 | Near-octagonal: a square of 101-105 m across the straight faces, with stepped chamfered corners and a central bay on each face (see 1c). Bounding box 110 x 111 m. | Perimeter "around the base" **1,420 ft = 433 m** [OFF]. The top is a walkway (the upper terrace, men only) carrying the plinth stupas. |
| 2 | Three terraces (pichaya / paccaya) | 12.87 m (official "terraces 62 ft 4 in" = 19.00 m including the plinth) | 6.13 -> 19.00 | Three steps, each about 4.29 m tall. Outer half-width 41 -> 37.6 -> 34.2 m, top deck half-width about 31 m. Square with redented corners: the four cardinal sides are straight and the four diagonal sides are serrated (about 2 m steps) [OSM, M2D]. | Gold. Skillion slopes in OSM run from half-width 40.5 to 30. |
| 3 | Octagonal dais (shit-mhaung) | 7.87 m (25 ft 10 in) | 19.00 -> 26.87 | Octagon, about 60 m across the flats at its foot and 46 m at its top [OSM r 30 -> 22-23]. Small redents at the corners. | Gold. |
| 4 | Circular bands (kyi-wun, "turban" rings) | 7.37 m (24 ft 2 in) | 26.87 -> 34.24 | Five rings stepping in, diameter **42.4 m -> about 31 m** [OSM bottom r 21.2; PH top ring about the bell's width]. | In side photos they flare out like a skirt under the bell. |
| 5 | Bell (khaung-laung) + inverted alms bowl (thabeik-hmauk) | 14.00 m (45 ft 11 in) | 34.24 -> 48.24 | Bell rim **dia about 30-32 m** [PH 29.7, OSM 31.7]. At 41.9 m it is 24.8 m [PH]. The festoon band (pan-zwe) at 42-47 m is 23 m [OSM]. The shoulder at about 46.5 m is 18.5-19 m. The bowl at 46.5-48.2 m is about 18.6 m. | **16 flower ornaments on the shoulder** [SD]. A girdle band (yin-zi) round the middle. |
| 6 | Ovolo mouldings / concentric rings (baung-yit) | 13.21 m (43 ft 4 in) | 48.24 -> 61.44 | Seven stacked rings, diameter **18 m -> 9.4 m** [PH: 17.3 m at 51.4; 13.0 at 58.3]. | Gold plate. |
| 7 | Lotus: inverted petals, upturned petals, "tender lotus" (kya-hmauk, kya-lan) | 8.79 m (28 ft 10 in) | 61.44 -> 70.23 | dia **9.8 m -> 8.1 m** [PH]. OSM gives 7-8 m. | Down-turned petal band, then a bead band, then up-turned petals. |
| 8 | Banana bud (hnget-pyaw-bu) | 15.82 m (51 ft 11 in) | 70.23 -> 86.06 | Widest **7.2 m at about 72.6 m**, neck about 2.9 m at 82 m, about 1.4 m at the top [PH, OSM 7.1 m]. | **13,153 gold plates, each about 30 cm square** [SD]. Reinforced with steel and concrete in 1999. |
| 9 | Umbrella crown (hti) up to the diamond bud | 13.31 m (43 ft 8 in) | 86.06 -> 99.36 | Bottom tier **dia 4.72 m** (15 ft 6 in), top tier 1.07 m. See 1b. | Stainless steel frame with gold plates (new 1999 hti). 0.5 t of gold, 6.3 t in all. |

Totals and other facts [OFF]:
- Gold on the stupa: 2,034.68 viss (3.08 t).
- Copper: 145 t.
- Stainless steel: 4.47 t.
- 33,699 gold plates of 1 sq ft each (the official table labels this "Bell rim").
- Gold plates cover the top down to about the middle band of the bell (finished by 1980). Below that the surface is gold leaf on lacquer, re-gilded every five years.

### 1b. Hti, vane and orb [OFF]

| Element | Size |
|---|---|
| Hti | 7 tiers (wrought rings with hanging bells), 43 ft 8 in total. **Bottom tier 0.99 m tall and 4.72 m across. Top tier 0.46 m tall and 1.07 m across.** Interpolate the tiers in between: heights 0.99 / 0.90 / 0.81 / 0.72 / 0.64 / 0.55 / 0.46, diameters 4.72 / 4.11 / 3.50 / 2.90 / 2.29 / 1.68 / 1.07, about 5.1 m in all. |
| Bells on the hti | 4,016 gold, 474 silver and 793 mixed-metal bells hang from the tier rims. Model them as a fringe. |
| "Screw pine flower" (bud above the tiers) | **3.66 m tall** (12 ft; a second passage says 8 ft 2 in). Diameter 1.02 m at its widest and 0.51 m at its narrowest. |
| Main shaft (pan-le-daing) | 11.70 m from the base of the bronze pillar to the diamond head. 10 cm diameter at the root, 7 cm at the tip. |
| Vane (hnget-myatna) | Steel triangle on a rotating ring, **1.27 m long x 0.76 m wide**, flat. 1,098 diamonds and 1,338 other gems. 419 kg. |
| Diamond orb (sein-bu) | **0.56 m tall, 0.27 m diameter**, gold, tipped by a 76 ct diamond. 4,351 diamonds in all. |
| Stack in the model | Tiers 86.06 -> about 91.1. Screw pine flower 91.1 -> 94.8. Shaft and vane about 94.8 -> 98.8. Orb 98.8 -> 99.36. |

### 1c. Plinth plan (stupa frame, metres) [OSM way 779515064]

| Item | Value |
|---|---|
| Straight faces | S face at N = -51.0, E face at E = +52.5, N face at N = +51.2, W face at E = -50.7. |
| Central bays (on the axes, in front of the adoration halls) | S: E -4.7..+6.6 out to N -56.6. E: N -6.2..+4.9 out to E +54.2. N: E -3.2..+6.2 out to N +54.8. W: N -3.7..+7.0 out to E -55.2. That is **about 11 m wide and 4-5 m proud**. |
| Corners | Stepped chamfer from about +-25 to +-45 m along each face, in about 2 m steps (2.2 x 6.4 m). The plan reads as an octagon. |
| On the plinth top | **64 small stupas** in a ring at half-width 46-48 m: about 3.5 m base, 4.40 m tall, top 10.53 m above the platform. OSM maps 56 of them. **4 larger stupas at the cardinal points** at (0, -49), (+51, -2), (-50, +2), (+1, +52): base up to about 11 m, 8.40 m tall, top 14.53 m. Trustees count **68 upper-platform cetis** (64 + 4) [OFF]. |
| Round the plinth's foot | **62 gilded niche shrines**, about 3 x 3 m and 6.1 m tall, in a row at half-width 52-56 m, each holding a seated image [OSM `building=shrine`]. Also four man-lion sphinxes (manussiha) at the corners and pairs of chinthe (three per side) [Facts and Details]. |
| Low wall | A 1 m wall chamfers the four diagonal corners at about 62 m radius [OSM barrier=wall, height 1]. |

### 1d. Lathe profile for the round part (radius in m, height in m above the platform)

From the top of the octagonal dais to the hti base:

```
(21.2,26.87)(21.2,28.3)(19.7,28.3)(19.7,29.8)(18.2,29.8)(18.2,31.3)(16.7,31.3)(16.7,32.8)(15.5,32.8)(15.5,34.24)
(15.4,34.24)(15.1,35.0)(14.5,37.0)(13.6,39.5)(12.4,41.9)(11.7,42.0)(11.7,47.0)  <- festoon band 42-47 (dia 23.4), relief
(9.6,46.5)(9.4,48.24)                                                            <- shoulder + inverted bowl
(9.0,48.24)(9.0,49.6)(8.3,50.1)(8.3,51.5)(7.6,52.0)(7.6,53.4)(6.8,53.9)(6.8,55.3)(6.0,55.8)(6.0,57.2)(5.3,57.7)(5.3,59.1)(4.7,59.6)(4.7,61.44)
(4.9,61.44)(4.6,63.5)(4.4,64.5)      <- inverted lotus petals (petals hang over the band)
(4.2,64.5)(4.2,66.0)                 <- bead band
(4.0,66.0)(4.05,70.23)               <- upturned lotus
(4.0,70.23)(3.6,72.6)(3.3,75.0)(2.65,78.0)(2.0,80.5)(1.45,82.2)(1.0,84.0)(0.7,86.06)   <- banana bud
```

Above that come the hti tiers from table 1b.

The profile was cross-checked on `remote_from_peoples_park.jpg` (a 600 m west view, so little perspective). With 0.137 m per pixel, the photo puts the bell rim at 33.4 m (official 34.24) and the bud's widest point at 7.2 m (OSM 7.1). The two agree.

---

## 2. The platform

### 2a. Size and outline [OFF, OSM way 117388457]

- Official size: **900 ft N-S x 700 ft E-W (274 x 213 m), 14 acres (5.66 ha)**.
- OSM gives 278 x 213 m and 58,112 m².
- The stupa is **not centred**. The platform runs from E -100 to +112 and from N -104 to +175. There is much more room to the north (Naungdawgyi, the bells, the Victory Ground).

Outline in the stupa frame, anticlockwise, from OSM:

```
(-98.5,172.4) (-100.3,3.8) (-100.5,0.0) (-98.9,-103.2) (-0.3,-102.5) (110.2,-104.2) (110.8,-8.3) (112.4,166.7) (18.4,175.3)
```

The NE corner is cut from (112.4, 166.7) to (18.4, 175.3). The corners in reality are less clean than this polygon: buildings overhang the hill. Retaining walls and the slope fall to the middle terrace.

### 2b. The four covered stairways (zaungdan) [OFF + OSM]

| | South | East | North | West |
|---|---|---|---|---|
| Top on the platform edge | (-0.3, -102.5), on the axis | (110.8, -8.3) | (18.4, 175.3), **18 m east of the axis** | (-100.3, 3.8) |
| Foot (OSM) | (-5.9, -303.5), gate at (-6, -319) | (312.9, -26.7) | (31.4, 278.7) | (-287.1, 11.8) |
| Official length | 770.8 ft = **234.9 m** | 774.8 ft = **236.2 m** | 438 ft = **133.5 m** | 694 ft = **211.5 m** |
| Steps | **152** | **204** | **143** | **164** (plus escalators) |
| Overall width (incl. shop rows) | 63 ft = 19.2 m | 89 ft = 27.1 m | 60 ft = 18.3 m | 40 ft = 12.2 m, 22 ft = 6.7 m high |
| Roofed pavilions (roof sections) | 10 | 5 | 6 | 5 |
| Shops | 65 (Buddhist goods, flowers, Pitaka bookshops on the west side) | 140 (images, bells, carvings) | 71 | 71 |
| Columns | 142 | 238 | 56 | 106 middle, 136 side, 32 corner |
| Notes | Main approach from Shwedagon Pagoda Road. **1842 stone arch and two ogre statues** at the entrance. Two lions (1887), two crocodiles inside. **26 bronze manussiha** on the outer walls. Two marble entrance stairs. Roofs: **9-tier** over the top, a 3-tier centre pavilion, a 7-tier pavilion, a "Sanpare" pavilion, and a **5-tier leading roof with two side pavilions** at the platform. OSM roof 28 x 191 m. | Rebuilt 1995-97. Two lions added in 1995. Dips at the midpoint (old Dhammazedi site). Covered bridge and elevator at about (137, -45) to (173, -48). | The 1460 Shin Saw Pu stairway. Ogress statue near the top at (27, 174). Chinthe pair at the foot, statues at (27, 284) and (39, 283). | Built 1935-2002. **8 escalators** (1990; the trustees now list 6). Two lions added at the entrance. Fire of 1931. Chinthe at the foot at (-287, -5) and (-285, 28). |

Entrance chinthe sizes disagree:
- 18 ft / 5.5 m for the southern pair [SD].
- About 30 ft / 9 m for each passage [Lonely Planet; Alamy caption 29.5 ft].
- 11 m for the south [global-geography].

**Use about 9 m for the southern pair** and check against `day_southern_entrance.jpg` and `stair_entrance.jpg`. Treat the E and W pairs (added in 1995) as smaller until a photo shows otherwise. The OSM chinthe groups at the west foot and People's Park side are at (-317..-330, -93..-106) and (-315..-328, 100..112).

The rise works out to about 23-27 m. The south stairs give 152 steps x about 15-16 cm plus landings. Take each foot's height from the DEM, not from the step count.

### 2c. Elevators and escalators [OFF counts, OSM positions]

| Where | Count | Position |
|---|---|---|
| South elevator | 4 cars | Tower at (81.8, -185.6), joined by a covered walkway (OSM roof 7 x 84 m centred at (81, -147)) to the SE of the platform. |
| East elevator | 2 cars | (172.7, -48.4), joined by a covered bridge (`bridge=yes covered`) at about (125-136, -45). |
| North elevator | 2 cars | (-30.6, 241.6), with the "Northern Elevator Walkway" roof, 19 x 78 m, at (-34, 211). |
| West escalators | 6 | Inside the western stairway. |

### 2d. Planetary posts (12 in total: a pair on each cardinal side, one in each corner) [OFF, OSM positions, Commons photos]

| Day | Planet | Animal | Direction | Position (stupa frame) |
|---|---|---|---|---|
| Sunday | Sun | Garuda (galon) | NE corner | (55, 54) |
| Monday | Moon | Tiger | E (pair) | (65, -13), (64, 12) |
| Tuesday | Mars | Lion | SE corner | (57, -54) |
| Wednesday a.m. | Mercury | Elephant with tusks | S (pair) | (13, -62), (-11, -62) |
| Thursday | Jupiter | Rat | W (pair) | (-62, -10), (-62, 13) |
| Friday | Venus | Guinea pig | N (pair) | (15, 64), (-12, 64) |
| Saturday | Saturn | Naga (dragon) | SW corner | (-53, -53) |
| Wednesday p.m. | Rahu | Elephant without tusks | NW corner | (-52, 56) |

Each post, from the photos `post_*.jpg`:
- **A water basin** about 1.2 m across and 1 m high, gilded, with an embossed rim.
- **A gilded seated Buddha** of about 0.8-1 m on a pedestal behind the basin.
- **The day's animal** as a statue of about 0.6-1.2 m, often white and gold, at the basin.
- **A slim red-and-gold post** of about 3-3.5 m holding a **signboard** with the day name in Burmese.
- **A guardian-deva statue** of about 1.5 m beside it.
- **A small tiered spire** behind.
- A low railing in front.

The posts stand about 8-12 m out from the plinth faces, just outside the niche-shrine row. Three are dedicated masonry posts (Ta Kun Tai):
- Sunday corner, 1879: brick, the tallest, 7 tiers on top, 8 niches at the base.
- Tuesday corner, 1924: octagonal, glass mosaic, a hamsa bird on top.
- NE near Naungdawgyi, 1961: jade-clad, with a small ceti on top.

### 2e. The four adoration halls (cardinal tazaungs) [OFF, OSM]

| Hall | Buddha image | Centre (stupa frame) | Footprint | Notes |
|---|---|---|---|---|
| South | Konagamana | (1.1, -64.5) | 20.0 x 17.3 m | Gilded multi-tier spire with carvings. Double-tier windows with ceramic floral tiles. Rebuilt after Cyclone Nargis (2008). |
| East | Kakusandha | (63.6, -0.8) | 20.2 x 18.4 m | Rebuilt after the 1931 fire. Glass-mosaic gold pillars. |
| West | Kassapa | (-63.8, 1.5) | 18.8 x 17.9 m | Destroyed in 1931, rebuilt. Multiple tiers. |
| North | Gautama | (1.8, 62.4) | 20.5 x 16.9 m | 1894, Sir Po Tha. Glass and gold columns, carved Jataka panels. 2 roof tiers fell in 2008 and were restored. |

All four touch the plinth's central bays (the plinth face sits at 51-56 m) and open towards their stairways. Roofs are gilded **pyatthat**. Take the tier count from the photos and the official VR tour for each hall; do not guess. The southern stairway's top pavilion is 5-tier and its upper roof 9-tier [OFF].

### 2f. Main structures on the platform

From OSM footprints and names. The full list of 72 is in `platform_plan.json`. Centres are in the stupa frame, sizes in m.

| Structure | Centre | Footprint | Height / notes |
|---|---|---|---|
| **Naungdawgyi Pagoda** (Elder Brother stupa) | (62.7, 127.6) | 45.4 x 44.3 | **46 m (150 ft)** [OFF]. Gilded, bronze-plated in 2000. Its own ring of 21 ft stupas (about 30 small ones) and 8 skillion terrace parts up to 44 ft. NE of the main stupa. |
| King Tharrawaddy's bell (Maha Tissada Gandha) pavilion | (81.3, 80.2) | 13.8 x 12.0 | Sunday (NE) corner. See section 2g. |
| King Singu's bell (Maha Gandha) pavilion | (-65.9, 95.3) | 15.8 x 11.9 | Rahu (NW) corner, "near the Western hall / museum" [OFF]. See section 2g. |
| Buddha's Footprint hall | (-10.6, 140.5) | 50.7 x 41.7 | North side. Largest footprint on the platform. |
| Chanthargyi pavilion (30 ft seated Buddha) + Shin Saw Pu image | (-51.9, 114.6) | 33.4 x 30.9 (official hall 88 x 40 ft = 26.8 x 12.2 m) | Rahu corner, by the Victory Ground. |
| Victory Ground (Aung Myay) | about (-29, 108) | Paved, slightly raised, lotus-shaped in plan | Open area. Keep it clear: a photo viewpoint. |
| Sacred Hair Relic Washing Well (Hsandaw Twin) | (-17, 85) | 9 x 9 basin, inside a pavilion | |
| Htidaw (King Mindon's 1871 hti) stupa | (40.8, 77.7) | 11.2 x 10.1 | Round building with the old hti displayed, entrance on the W. Sunday corner. |
| Boe Boe Aung pavilion / Kanna Market Two-Pice pavilion | (36.5, 84.9) | 36.2 x 32.0 | Sunday corner. |
| Pyidawpyan image hall | (60.7, 96.3) | 16.7 x 11.6 | |
| Mahabodhi Temple replica | NE of the north hall [SD] (OSM area near (26, 119)?) | about 7 x 7 | Indian sikhara tower, pale. `day_htis_gje480.jpg` shows its painted panels. |
| Dhammazedi inscriptions pavilion | (104.3, 154.3) | 10.6 x 7.5 | Three stone slabs (1485). |
| Shin Ma Htee / Shin Izzagona halls | (62.5, 157.4) / (66.8, 74.2) | 12.8 x 12.6 / 19.2 x 12.5 | Round Naungdawgyi. |
| Photo Gallery | (-29.4, 127.2) | 17.7 x 13.1 | |
| Long west row (Tooth Relic replica, ticket office, U San Chain hall) | (-88.7, -12.4) | 118 x 23 | Along the W edge. |
| East row | (95.2, 22.7) and (85.4, -21.5) | 46.7 x 21.6 and 52 x 18 | Along the E edge, next to the east stair top. |
| South-edge row (Saedawmu / U Maung Gyi shrine) | (41.8, -93.8) | 71.7 x 17.2 | SE. |
| Padashin image / SE corner hall | (93.3, -71.2) | 34.9 x 23.0 | Tuesday corner, by the south elevator walkway. |
| Golden replica stupa (1/90 scale, 45 in tall, 1999) | (51.7, -75.6) | 12.4 x 10.7 (pavilion) | Between the Tuesday and Wednesday corners. |
| Sun-Moon (Nay La) shrine | (-47.4, -69.6) | 15.7 x 11.7 | Peacock-in-sun and rabbit-in-moon statues in front. |
| Jade pavilion (Jade Buddha) | (-69.2, -82.0) | 9.2 x 7.7 (+ hall) | Saturday (SW) corner. 28-Buddha hall. |
| Shwedagon Bo Bo Gyi + Sakka + Okkalapa statues | SW (Saturday) corner | Small pavilion | |
| Brahma-holding-a-child statue | (36, -54) | | Next to the Tuesday post. |

Platform inventory from the trustees [OFF], to check the model against:
- 4 adoration halls.
- **30 bells**.
- **5 Bodhi trees**.
- **3 high masts** (floodlight masts).
- 4 flag poles.
- 2 overhead water tanks.
- 2 museums.
- 3 stone umbrellas.
- 3 Shan umbrellas.
- 4 water-cooler tanks.
- 75 square-terrace cetis.
- 104 brick shrine-pagodas (gandhakuti cetis).
- 76 brick pavilions.
- 47 brick chambers.
- 75 rest-houses / halls on the main terrace. OSM maps about 72 footprints.

### 2g. The great bells [OFF, M2D]

| Bell | Weight | Height | Mouth diameter | Wall | Where |
|---|---|---|---|---|---|
| **Maha Gandha (King Singu's), 1778-79** | 23-24 t (15,555 viss) | **2.34 m** (7 ft 8 in) [OFF]. M2D gives 7 ft. | **2.06 m** (6 ft 9 in) | 30 cm (12 in) [M2D] | NW (Rahu) corner, pavilion at (-66, 95). Fell into the Yangon River in 1825 and was raised by local people. |
| **Maha Tissada Gandha (King Tharrawaddy's), 1841-43** | 42 t (25,440 viss) | **2.59 m** (8 ft 6 in) [OFF]. M2D says 14 ft 3 in, probably including the hanger. | **2.34 m** (7 ft 8 in) | 38 cm (15 in) [M2D] | NE (Sunday) corner, pavilion at (81, 80). The pancarupa (five-creature) hanger is 9 ft 1 in = 2.77 m. |

Both bells:
- Hang low from a heavy gilded beam carried by gilded and red-lacquer posts.
- Are dark bronze, partly gilded, with red bands where they are painted (see `bell_gje345.jpg` and `bell_singu_min.jpg`).
- Are struck by visitors with a wooden striker (`bell_tharrawaddy.jpg`).

### 2h. Floor

- **Marble slabs, white to light grey, with a grey-beige / pinkish-grey geometric inlay** (large radiating star and octagon bands; see `day_main_pagoda_esplanade.jpg`). The contrast is low.
- A **mat walkway** is laid round the stupa for hot feet. Its colour varies: check the VR tour.
- Shrines and halls stand on their own polished-stone plinths 0.3-0.6 m high.
- **No dark-red ring and no teal walkways were found in any photo or source.**

### 2i. Bodhi trees [OFF, M2D, OSM]

Official: 5 on the platform. The four historical ones are at:
- **Sunday (NE)**: planted 1983.
- **Tuesday (SE)**: 1921.
- **Saturday (SW)**: 2005.
- **Rahu (NW)**: 4 Jan 1948, Independence day.

M2D also has two Bodhi trees near the NW corner: a large one from 1903 and a smaller one planted by U Nu.

Tree points from OSM (species not tagged):
- SE (96, -97)
- SW (-100, -96)
- S edge (-50, -95), (-39, -96)
- NW group (-87, 78), (-83, 74), (-84, 113)
- (-73, -56)
- NE (91, 109)
- N (22, 146), (33, 168), (46, 158)
- (47, 98), (-71, 165)

Each Bodhi tree is big: 15-20 m tall, with a crown 15-20 m wide, rising out of a raised, railed, gilded-rim planter (see `day_platform_gje510.jpg`). Model the four corner trees first.

### 2j. Pavilion roofs (pyatthat) and walls

- Tazaungs are teak or concrete halls, 10-50 m long, on short plinths.
- They have **red or gold glass-mosaic columns** and **gilded carved fascias**.
- **Tiered pyatthat roofs**: 3, 5, 7 or 9 tiers, the odd numbers only. The tiers are gilded, with flame finials (`day_pagoda_shrine_halls.jpg`, `day_southern_entrance.jpg`). A few halls have **green-painted** eaves and ceilings (`day_platform_gje510.jpg`).
- The lower roofs are often dark red, gold-edged zinc.
- **White** shrine buildings (lime-washed with gilded spires) are mixed in, especially on the SW side (`day_main_pagoda_esplanade.jpg`).

---

## 3. Colours at midday (never from dusk shots)

Median RGB was measured on daylight photos. Gold is mirror-like, so the hue matters more than the brightness.

| Surface | Measured (photo, light) | Suggested game base colour | Notes |
|---|---|---|---|
| Gold, stupa (neutral light) | (176, 155, 93) #B09B5D, overcast (`day_main_pagoda_esplanade`) | **(212, 175, 92)** with Metal, reflectance about 0.5 | Gold is yellow, a little green-leaning, not orange. The gold pixels in sunny `dsc010` have a median of (157, 129, 74), with highlights at (255, 248, 182). |
| Gold, sun highlight | (226, 206, 120) p90, (255, 248, 182) p99 | Comes from the specular | Sharp, almost white-yellow highlight lines on every ring edge. |
| Gold, terrace skirt, overcast | (160, 138, 77) | (200, 160, 80) | A touch darker than the bell: gold leaf, not plate. |
| White marble floor | (134, 132, 131) overcast; near white in sun | **(226, 224, 220)** | The photos are exposed for the gold, so the floor reads too dark in them. Real white marble is about 0.75-0.8 albedo. |
| Floor inlay bands | (119, 109, 104) overcast | **(170, 158, 150)** grey-beige | Low contrast. |
| White shrines / lime-wash | (132, 139, 138) overcast; (210, 194, 182) low sun | **(232, 230, 224)** | Cool white with gold spires. |
| Red (columns, lacquer, lower roofs) | Dark red roof (30, 20, 23) in shade | **(150, 32, 28)** deep lacquer red; roofs (110, 30, 26) | Glass-mosaic columns sparkle red and gold. |
| Green trim (some tazaungs) | `gje510` | (40, 110, 80) | Use sparingly. |
| Sky reference | (190, 201, 205) overcast; (76, 103, 150) clear | | |

Colours are measured on downsized JPEGs with camera auto-exposure. Treat them as hue and contrast targets and tune brightness by a side-by-side screenshot.

---

## 4. Night look

- From dusk until about 22:00 the whole stupa is **floodlit from below**: from the plinth-top lights, the platform and **3 high masts** [OFF]. The platform lamps and the shrine niches are lit too.
- No published lux or wattage was found. Calibrate on the photos.
- Floodlit gold in the night photos:
  - Median (150, 110, 6) to (205, 137, 52): a **saturated orange-gold**, more orange than in daylight.
  - Highlights clip to (255, 234, 89) to (255, 250, 190).
  - The sky is (12, 11, 4) to deep navy.
- **The stupa is the brightest object in Yangon's night skyline.** It is still blown-out yellow at exposures where the city is dark. From 1-2 km away (Kandawgyi, People's Park) it reads as a glowing gold cone with a darker band at the bell rim.
- In-game:
  - Use a warm floodlight colour of about (255, 190, 110).
  - Put emissive-like "glow" on the gold, strongest on the bell and terraces and weaker on the hti.
  - Leave the small plinth stupas a step dimmer.
  - Use the neon or LED halo strings on the shrines (`night_view_030.jpg`, "Note the Neon Trim" on Commons) as accents.
- Night references: `night_from_east.jpg`, `night_view_030.jpg`, `night_platform_1.jpg`, `remote_from_park_2.jpg`.

---

## 5. The setting

Positions here are **true** east/north metres from the stupa axis, the same as the game's OSM roads.

- **Singuttara Hill:**
  - Summit platform at 58 m above sea level. Wikipedia gives 51 m for the hill.
  - Three terraces [WP]: the lower terrace at road level, a concrete footpath circling the hill; the **middle terrace**, where the sacred precinct starts (shoes off) and where the museums, the trustees' office (89, -102) and parking sit; and the **upper terrace**, the platform.
  - Slopes are steep and wooded (forest and lawn polygons).
  - The colonial British military occupied the hill until 1929, and old fortification remains lie below the SW corner [OFF, Yangon Bo Bo Gyi page]. A 1.39 km boundary wall runs round the W and SW of the compound (OSM wall 1553983561).
- **Moat:** **no moat was found** in OSM, on the official site or in the guides. Do not build one unless a source turns up. The water round the hill is:
  - **Kan Taw Min lakes 1-3** S/SW, 360-630 m away.
  - **Thway Say (Blood-Washed) Lake** N, 300-425 m.
  - The **Blood-Cleansing pond** to the right of the north entrance.
  - The **Shin Upagutta Mingala pond** (2.34 acres, 1994) NW, by U Wisara Road and Arzani Street.
  - **Kandawgyi Lake** E, from 850 m.
  - Small fountain pools in the gardens.
- **Parks:**
  - **People's Park** to the W: about 400 m to 1.2 km, x -1214..-324.
  - **People's Square** in front of it: the classic west view.
  - **Thein Gottara Park** (the wooded W/NW slopes, x -527..257).
  - **Kan Taw Mingalar Garden** S.
  - The **Singuttara gardens** (12.5 acres, 2005, with lights and fountains).
  - **Memorial Park** N.
- **Approach roads:**
  - **Shwedagon Pagoda Road** comes from the south (4 lanes) and ends at the south gate area at about y -330.
  - **U Htaung Bo Road** curves along the south (3-4 lanes, y about -310..-390).
  - **Arzani Street** is a one-lane, one-way loop round the E and N of the hill, about 230 m out.
  - **U Wisara Road** runs on the west (2 lanes, x about -300..-460) with the **U Wisara roundabout** to the SW (about (-290, -380)).
  - Parking: E (220, -40) about 3,200 m², S (150, -200) about 3,500 m², N (-114, 238) about 3,700 m², W (-223, -30).

---

## 6. What is wrong with the current `shwedagon()` in `tools/yangon/city/landmarks.py`

1. **Not rotated.** Everything (plinth, platform, halls, stairs) is axis-aligned to true north. The real complex is turned **17 deg anticlockwise**, which is plainly visible from the air and on the minimap.
2. **Mixed scales.** The stupa is built at SH 2.3 x SV 3: 23% too slim against its own height, and against the rescale plan's SH = SV = 3. The platform and stairs are at 1.6 studs/m and Y0 is 93 (58 x 1.6). At 1:1 the platform should be at 174.
3. **Wrong vertical profile.**
   - The terraces, octagon and bands are squeezed into 6.4-21.4 m. Real: 6.13-34.24 m.
   - The bell starts at **21.4 m instead of 34.24 m** and stops at 38 instead of 48.
   - The "ring cone" runs 38-66 instead of 48-61.
   - Lotus at 53-62 instead of 61-70.
   - Bud at 66-81 instead of 70-86.
   - Hti at 81-93 instead of 86-99.4.
   - Orb at 97.6 m with a 2.4 m diameter: real **0.27 m**, top at 99.36.
4. **Wrong widths.**
   - Bell rim **48.8 m** across instead of about 31.
   - The square terraces are 88, 80 and 73 m wide; the octagons 66 to 49 m.
   - Bud about 10.5 m instead of 7.2.
   - Hti base 7.6 m instead of 4.72.
   - **8 hti tiers instead of 7.**
   - Vane 3 m instead of 1.27 x 0.76 m.
   The overall silhouette is a squat, too-wide bell low down.
5. **Plinth plan.** A redented square with no central bays and wrong corner steps; the real plan is near-octagonal with stepped chamfers. The pointed niches every 16 studs on the plinth faces stand in for the real **62 freestanding niche shrines** round the foot.
6. **Plinth stupas.** The 64 small ones are in about the right ring, but the extra "diagonal" stupas (`x * 0.72` inside the ring) are invented and stand on the terraces. The 4 big ones have the wrong size. The corner sphinxes and chinthe are missing.
7. **No planetary posts.** All 12 are missing; they are the most photographed things on the platform.
8. **Adoration halls too big.** They are 42 x 30 m and topped by a 9-tier spire (`pyatthat(..., 9, 96.0)`). The real halls are about 20 x 18 m against the plinth bays, at 64 m from the axis.
9. **Random tazaungs.** The ring of halls along the edge is `rng` sizes, white/red walls, random green roofs and random 3-7 tier spires. The inner ring of pagodas and pavilions is entirely invented. Missing:
   - **Naungdawgyi (46 m)**, the second-tallest thing on the platform.
   - Both great bells.
   - The Bodhi trees.
   - The Buddha's Footprint hall, Chanthargyi, the hair-relic well, the Victory Ground and the Mahabodhi replica.
   Use the OSM footprints in `platform_plan.json` instead.
10. **Wrong platform shape.**
    - It is an octagon of 470 x 500 studs (294 x 312 m), roughly centred on the stupa, with 72-stud chamfers.
    - Real: **213 x 278 m**, rotated, with the stupa well south of centre (platform N -104..+175).
    - The south and west edges are only about 100 m from the axis; the game puts them at about 134 and 147 m.
11. **Invented floor colours.** The dark-red ring (`MARBLE_BAND`) and the teal walkways (`MARBLE_TEAL`) do not exist. Real: white marble with a low-contrast grey-beige inlay.
12. **Stairways.**
    - 17-36 steps per flight (at 1.2-stud risers) instead of 143-204.
    - Widths 22-26 studs: no shop rows and no roof pavilion sequence (south: 10 pavilions, a 9-tier top roof and a 5-tier leading roof).
    - Chinthe only on the south; real: pairs at every entrance plus the south ogres and arch.
    - The north stair top is not offset 18 m east.
    - No elevator towers or bridges (S, E, N) and no escalators (W).
13. **One gold for everything.** One flat gold material with a night glow on all of it. The real stupa has gold plate above the middle of the bell and leaf below, a slight tone and texture change. The hti and vane are jewelled; the small stupas' gold is a little more orange.
14. **Collision is approximate**, which is fine. But with the right profile the bell collision should start at 34 m, not 21 m.

---

## 7. Build list (in order)

1. **Frame:** stupa axis at 16.79834 N / 96.14959 E, rotation 17 deg anticlockwise, platform Y0 = 174 studs, SH = SV = 3.
2. **Platform slab:** the outline in section 2a, with retaining walls dropping to the DEM. White marble top with the inlay pattern. Edge kerbs and balustrades where the halls are open.
3. **Main stupa:** the plinth (section 1c), 3 terraces, octagonal dais, 5 bands, bell with the festoon band and 16 shoulder ornaments, bowl, 7 rings, lotus (down petals, beads, up petals), banana bud with a plate texture, hti (7 tiers, bell fringe, screw pine flower, vane, orb). The total must come to 99.36 m.
4. **Plinth top:** 64 small stupas (4.4 m), 4 cardinal stupas (8.4 m), and the 1 m corner walls.
5. **Round the plinth:** 62 niche shrines, 4 corner manussiha, chinthe, and the **12 planetary posts** with their animals and signboards.
6. **The 4 adoration halls** (about 20 x 18 m) with gilded pyatthat. Count the tiers from photos.
7. **Landmark structures:**
   - Naungdawgyi (46 m).
   - Both bell pavilions with the bells at their real sizes.
   - Buddha's Footprint hall.
   - Chanthargyi.
   - Htidaw.
   - Hair-relic well.
   - Mahabodhi replica.
   - Victory Ground.
   - Dhammazedi inscriptions.
8. **The other halls** from the OSM footprints (about 72). Use kit pieces: red/gold mosaic columns, gilded fascias, 3-, 5-, 7- or 9-tier pyatthat or plain red roofs, and white lime-washed shrines.
9. **Trees:** 4-5 Bodhi trees in railed planters at the corner positions, plus the other OSM tree points.
10. **The 4 covered stairways** at their real lengths, step counts and widths: shop rows, pavilion roof sequence, entrance gates and chinthe pairs (about 9 m at the south). The south gets the 1842 arch and ogres. The west gets escalators.
11. **Elevator towers and bridges** S, E and N.
12. **Hill:** middle and lower terraces, wooded slopes, the trustees' office, museums and parking. Ponds round the hill (no moat). Gardens W and S, and the People's Park edge.
13. **Night:**
    - Floodlight rig on the plinth top and 3 high masts.
    - Glow levels as in section 4.
    - Lit shrine niches and platform lamps.
    - LED halo strings on some shrines.
14. **Check:**
    - Put a camera at People's Park (W, about 600 m) and compare it with `remote_from_peoples_park.jpg`. The silhouette ratio should be bell rim / total height = 0.30.
    - Put a camera on the platform's SE corner and compare it with `day_central_stupa_gje460.jpg`.
    - Compare a night view from the east with `night_from_east.jpg`.

## 8. Still to verify

- Pyatthat tier counts of each adoration hall. Use the official VR tour or photos.
- Exact chinthe heights at each stair. Measure on photos against people.
- The height of each stair's foot. Use the DEM.
- The mat walkway colour.
- Whether the plinth is 6.13 m or 6.4 m. Photos cannot separate the two; use 6.13 so the total stays 326 ft.
