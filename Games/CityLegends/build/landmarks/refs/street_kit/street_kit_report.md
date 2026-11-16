# Yangon street kit: real catalogue, sizes, densities, and what the game is missing

Made 16 Nov 2026 for the 1:1 rebuild (3 studs = 1 m). Map box lon 96.095-96.235, lat 16.75-16.89.

Files next to this report:
- `osm_street_items.json`: every street item in the box with all its OSM tags, position, counts, per-road-class densities, footbridge sites. Source: Geofabrik `myanmar-261112.osm.pbf` (OpenStreetMap contributors, ODbL), read with pyosmium. This dump is 4 days old and carries every tag, so the live OSM API was not needed (and `points.json` in `build/osm_ygn` had kept only one key per point, no `shelter`, no crossings, no ATMs, no police).
- `<item>/sources.json` + photos: Wikimedia Commons results that mention Yangon / Myanmar. 18 item folders, about 80 photos.
  - A file was downloaded only when its licence is CC0, CC BY, CC BY-SA or public domain. Credit the artist (in `sources.json`) if a photo is ever shown.
  - Each result carries `read_for_report`, and `photos_read_for_report` lists the 20 photos this report is built on. Book-scan noise was deleted.
  - Two crops were added: `traffic_signal/crop_horizontal_heads_countdown_Sule_Pagoda_Rd.png` and `police_booth/crop_police_kiosk_Pansodan_Strand.png`.
  - The other results (not downloaded or not free) are kept as links with their descriptions.

How sure each line is:
- **[OSM]** counted from the extract.
- **[photo]** seen in a downloaded photo (file named).
- **[source]** from a cited web page.
- **[known]** my own knowledge of Yangon, not checked in a photo this run. Check these on Mapillary or Google Street View before building.

Mapillary needs an API token and KartaView's API did not answer, so no street-level image sequences were sampled. The densities in section 3 come from OSM plus the photos, and are marked as estimates.

---

## 1. Counts from OpenStreetMap (whole box)

| Item | Count | Notes |
|---|---|---|
| Bus stops | **1,063** (1,055 points, 8 areas) | `shelter=yes` 56, `shelter=no` 23, untagged 984. `bench=yes` 38. 1,002 have a name. No `route_ref` on any stop. Plus 41 bus stations / terminals. |
| Traffic signals | **367** nodes = **214 junctions** (nodes within 50 m merged) | No `traffic_signals:countdown` tags. 17 crossings tagged `crossing=traffic_signals`. |
| Pedestrian crossings | **671** (510 points, 161 crossing ways) | `zebra` 62, `marked` 70, `uncontrolled` 10, `traffic_signals` 17, `overpass` 6, untagged 503. |
| Footbridges | **80 sites** (180 bridge ways: 94 footway, 79 steps) | 6.4 km of mapped deck and stair ways. Positions in `footbridge_sites`. |
| Street lamps | **3** | Not mapped in Yangon. Use the photo rules in section 2. |
| Power poles | **0** | Not mapped. 63 transmission towers, 9 high-voltage lines (3.0 km, 230 kV), 18 substations, 3 transformers. |
| Post boxes | 17 | Plus 39 post offices. |
| ATMs | **423** | KBZ about 90, CB about 60, AYA about 45, AGD 12, UAB 14, MAB 8. Most sit in a bank front or a booth by one. |
| Fuel stations | **100** (73 points, 27 areas) | Max Energy, Denko, MMTM, New Day, 360, PT Power, SPC, Yangon Petrol, CNG stations. |
| Police | 52 | Mostly stations. Only about 5 are traffic-police posts. The junction booths are **not mapped**. |
| Toilets | 53 | |
| Benches | 18 | Almost unmapped. |
| Waste bins | 9 | Almost unmapped. |
| Monasteries | **85** (59 points, 26 areas) | |
| Stupas / pagodas | **217** (29 points, 188 areas) | `building=yes` 76 of them. Buddhist places of worship in all: 589. Muslim 34, Christian 34, Hindu 16, Chinese 6, Jewish 2, Sikh 1. 161 untagged. |
| Schools | **527** (298 points, 229 grounds) | Plus 54 colleges / universities. |
| Markets | **67** | Bogyoke (Scott) Market, Thein Gyi Zei, Pazundaung, Yankin, Myo Thit and others. |
| Tea shops | **198** by name or `cuisine=tea` | Plus cafes 342, restaurants 1,267, fast food 160, `shop=tea` 34, `shop=coffee` 15. Chains: Lucky Seven, Shwe Kaung Kywal, Mahar Yangon, Yaung Chi Oo, Golden Tea, Rangoon Tea House. |
| Car parks | 206 | |
| Traffic cameras | 35 | |
| Traffic islands | 16 | |

**Per 100 m of road** (an item is counted on its nearest road within 40 m; a dual carriageway counts each side, so these are per 100 m of one-way carriageway):

| Road class (km in box) | Bus stops | Signals | Crossings | ATMs | Tea shops | Restaurants |
|---|---|---|---|---|---|---|
| Trunk (27.6) | 0.14 | 0.08 | 0.14 | 0.03 | 0.004 | 0.04 |
| Primary (311.6) | **0.19** | 0.06 | 0.11 | 0.04 | 0.015 | 0.09 |
| Secondary (177.6) | **0.17** | 0.07 | 0.12 | 0.04 | 0.019 | 0.11 |
| Tertiary (103.9) | 0.04 | 0.01 | 0.006 | 0.008 | 0.011 | 0.07 |
| Residential (2,282.7) | 0.003 | 0.001 | 0.002 | 0.006 | 0.004 | 0.02 |

So on a primary or secondary road there is a bus stop about every **530-580 m on each side**, and a signal node about every 1.5 km per carriageway (about one signalled junction every 700-900 m along a main road). OSM under-counts shops on residential streets.

---

## 2. The designs (sizes in metres, then studs at 3 / m)

### 2.1 YBS bus stop
Three kinds exist side by side:

1. **FMI Decaux shelter (2018 on)** [photo: `ybs_bus_stop/03`, `04`; source: lepetitjournal 17 Feb 2019: about 150 built, 500 planned, which is about 15% of all YBS stops]
   - Size: about 4.2 m long, 1.5 m deep. Roof underside 2.4 m, top 2.6 m (12.6 x 4.5 x 7.8 studs).
   - Shape: a flat aluminium roof sloping slightly back. Two round posts (about 0.1 m) at the back and one at the open front corner. A glass back panel. A lit ad box (1.2 x 1.8 m face, 0.2 m deep, silver frame) closes one end.
   - Seats: 3-4 single perforated steel seats on a rail at 0.45 m.
   - On top: a white **YBS** box about 1.2 x 0.45 x 0.15 m. "YBS" in dark blue on the left, then the route numbers in Burmese digits in red circles. A second white blade over the front carries the stop name in Burmese and English.
   - Floor: a white / light grey tiled plinth 0.1 m high. The kerb along the bus bay is painted **solid yellow**.
   - Usually with one or two free-standing double-sided ad panels (1.2 x 1.8 m on a 2.6 m post) and an orange YCDC wheelie bin.
   - Colours at midday: roof and frame 220, 222, 224; glass 150, 170, 175 at 50% transparency; YBS box white 245 with red 200, 30, 30 circles.
2. **Old YCDC blue canopy (before 2017; downtown, Sule area)** [photo: `ybs_bus_stop/01`]
   - Size: long runs of 10-30 m, about 2.5 m deep, the roof edge about 3.0 m high, the crown 3.4 m.
   - Shape: a barrel-vault roof of blue round tubes (about 0.1 m) with diagonal bracing, light grey or cream roof sheets, posts every 2.5-3 m. Notice boards hang between the posts.
   - Colours: blue 40, 100, 175; roof sheet 210, 205, 190.
3. **Pole only (most stops)** [photo: `ybs_bus_stop/06`; known]
   - A 3 m steel pole (0.06 m) with a white plate (about 0.6 x 0.4 m): YBS logo, route numbers, stop name. Often tied to a tree or a power pole.
   - Waiting people stand at the kerb. A tea or betel stall is often within 10 m.

Share to use: about 15% Decaux, 5% old canopy (downtown only), 80% pole-only [source plus estimate].

### 2.2 Traffic signals
[photos: `cars/06` (Sule Pagoda Road, 2021), `footbridge/01` (Pansodan / Strand junction, 2019); crops checked]
- **Heads**: **HORIZONTAL** black housings, Japanese style (the JICA / YCDC system), not vertical. One box holds the lamps side by side with a **two-digit LED countdown built into the same housing**. Red digits run next to the red ball, green next to the green, and there are red or green arrow lamps for turns.
  - Size: about 1.25 x 0.40 x 0.25 m. Lenses 0.30 m. A short visor over each lamp.
- **Mounting**: a **white or light grey round steel pole**, 6-7 m, with a long horizontal **mast arm (6-10 m) right across the carriageway**. Usually two heads on one arm (one over the inner lanes, one near the tip). A CCTV camera sits on the pole top or on the arm.
- Next to the pole: a grey and blue controller cabinet (about 0.6 x 0.4 x 1.1 m) [photo `footbridge/01`].
- **Big junctions** also have a high-mast floodlight (about 20 m, a ring of 6-8 floods) [photo `footbridge/01`].
- **Where** [OSM]: 214 signalled junctions in the box, all on primary, secondary or trunk roads. The 16 nodes on residential roads are mostly at their mouths on a main road.
- In the game: one pole + arm + head per approach on the right-hand kerb (`details.py signals()`).
  - The pole is 22.5 studs (7.5 m at 3 / m: right) and the arm 6-18 studs (OK).
  - **Wrong**: the head is a VERTICAL 1.4 x 3.6 x 1.0-stud box with three balls. It should be a horizontal box with a countdown.
  - **Wrong**: the pole is dark steel. It should be white or light grey.
  - Missing: the camera, the cabinet and the high mast.

### 2.3 Street lamps
- **Main roads** [photo: `tea_shop/01` shows the older type; known for the newer type]:
  - (a) Older type: cobra-head sodium lamps on a long curved single arm (2-2.5 m) bolted to the concrete power pole at 8-9 m.
  - (b) Newer main roads (Pyay, Kabar Aye, University Avenue, Insein, Shwedagon Pagoda): galvanised conical or octagonal steel poles 9-10 m tall, often **double-arm poles in the median** (two 1.5-2 m arms) every 30-35 m. Elsewhere single-arm poles on the kerb side, every 30-40 m. White LED heads (0.7 x 0.3 x 0.12 m).
  - Some downtown and Strand Road stretches have decorative black or green cast lamps.
- **Side streets** [photo: `tea_shop/01`]: a cobra head or a small LED head on the power pole itself, about one in every second or third pole. This is what the game already does (`YangonPoleLights`, every second pole).
- Colour at night: white, about 5,000-6,500 K. The owner already set this.
- In the game: main roads get Monaco's StreetLamp copy on both kerbs, staggered, every 96 studs (32 m at 3 / m). The spacing is right, but the lamp is the wrong design, and real divided roads light from the median.

### 2.4 Concrete power poles, wires, transformers
[photos: `power_pole/01`, `02`, `tea_shop/01`, `street_lamp/03`; agrees with the 16 Nov kit critique]
- **Pole**: prestressed concrete, square or H-section, tapering from about 0.30 m at the ground to 0.16 m at the top. 9 m tall on streets, 10.5-12 m where it carries 11 kV (about 30 / 45 / 50 studs at 3 / m; the game's 25.4-stud pole is 8.5 m, fine for a street). Colour: weathered concrete 150, 148, 140, with a darker band 0-1.5 m (splash and dirt) and peeling posters.
- **Crossarms**: steel channel 1.5-2.4 m. Low-voltage poles carry 2-4 pin insulators or a vertical rack of 4 shackle insulators instead. 11 kV poles have a top arm with 3 white or grey insulators.
- **Wires**: the defining look. 6-20 black cables per span (power, ABC bundles, phone, cable TV, fibre), sagging 0.5-1 m over a 30-40 m span. A **coiled slack loop** of fibre on about one pole in three, and junction boxes (0.3 x 0.4 m grey). Cables cross the street to the houses at 5-7 m. Red-and-white sleeves on wires over the railway and low crossings [photo `power_pole/02`].
- **Transformers** [known]: two poles about 2.5 m apart with a steel H-frame **platform at 3.5-4 m** holding a grey tank transformer (about 1.2 x 1.0 x 1.4 m), fuse cut-outs above, a warning plate (red skull) and sometimes a small fenced meter box at the foot. Roughly one per 250-400 m of street; more downtown.
- **Spacing**: 30-40 m. **Downtown numbered streets: poles on both sides** [photo `tea_shop/01`]. Elsewhere one side.

### 2.5 Street name signs
[source: Coconuts Yangon "New but slightly underwhelming street signs cover downtown core"; known for the green ones]
- **Downtown (Pansodan, Merchant and the streets between)**: big blue rectangles with white letters. Burmese on top, English below, about 1.2 x 0.45 m, on one or two grey poles about 2.5 m up.
- **Elsewhere (older YCDC signs)**: green plates with white Burmese and English, about 0.9 x 0.3 m, on a single 2.4-2.7 m pole at the corner. Often faded, and often on a power pole.
- Where: one or two per junction of named streets.
- Fonts: Burmese in a plain Myanmar sans; English in plain capitals (DIN-like). Keep the real street names, as the vault rule for real names allows.

### 2.6 Overhead direction signs
[known; Commons gave only national highway shield drawings (`overhead_direction_sign/03-06`)]
- Green boards with white Burmese and English text and white arrows, on a steel gantry or a cantilever over the main roads at the big junctions and flyover approaches (Hledan, Myaynigone, Bayintnaung, Shwegondaing, the Kabar Aye / Pyay junctions).
- Board about 4-6 x 1.8-2.5 m, the bottom at about 5.5 m (16.5 studs). Gantry columns are grey steel, 0.4 m.
- Smaller post-mounted blue route boards on the roundabouts.
- Count unknown (none in OSM). Estimate: one gantry per direction at each of the 10-15 biggest junctions, so about 30 in the box.

### 2.7 Kerb paint
[photos: `ybs_bus_stop/03` and `04` (yellow), `kerb_paint/01` and `tea_shop/02` (plain); game note 2026-11-13 Research - Yangon road look]
- **Plain grey concrete** on most downtown streets: tall kerbs (0.20-0.25 m), rounded and dirty, with slab-covered drains behind them (0.5-0.6 m slabs).
- **Solid yellow** on the kerb top and face along YBS bus bays and no-stopping stretches (yellow 230, 180, 40).
- **Red and white** blocks (about 1 m each) on medians, traffic islands, near junctions and in front of government compounds [photos `ybs_bus/03` (Sule median), `ybs_bus/02`]. Already in the game. White plastic water-filled barriers (about 1.2 x 0.5 x 0.8 m) stand at some median ends [photo `ybs_bus/03`].
- **Black and white** blocks are also common on median noses and bridge approaches [known].
- So not every kerb should be red and white. Main roads: red / white at junctions and medians, yellow at stops, grey elsewhere. Streets: grey.

### 2.8 Police traffic booths
[photo: `footbridge/01`, a crop of the Pansodan / Strand corner (2019); not in OSM]
- A small **hexagonal kiosk on the corner pavement / island** next to the signal pole, not in the middle of the road. About 2.0 m across and 2.3 m to the eaves.
- Shape: a waist-high base (red or maroon) with a yellow / blue band, windows with grilles all round, and a **bright orange hipped roof with a wide overhang** (about 2.8 m across, the peak about 3.2 m).
- Next to it: the signal controller cabinet, a big billboard on green columns, police motorbikes parked in a row, and a white or dark-blue police Hilux.
- Officers: white shirt, dark-blue trousers, white cap [photo `footbridge/01`].
- Count: about one per major signalled junction (estimate 20-30 in the box). Check positions on Street View; some junctions have only an umbrella.

### 2.9 Pedestrian fences in medians
[known; Commons found nothing usable (`median_fence/01` is the National Library)]
- Main-road medians (Pyay, Kabar Aye, Sule Pagoda, Anawrahta, Bogyoke) carry a **steel railing 1.0-1.2 m high**: rails top and bottom with vertical bars, painted silver-grey, green or white. Some stretches have a **planted median with a low wall**.
- Gaps only at the signalled crossings.
- The same railing runs along the kerb by footbridges and bus bays to stop people crossing.

### 2.10 Tea shop setup
[photos: `kerb_paint/02` (labelled "Street food goodness"), `tea_shop/02`, `food_cart/03`]
- **Classic low setup**: low tables 0.45-0.5 m high, about 0.6 x 0.6 m tops, plastic, blue or white. Stools 0.25-0.30 m high, seat 0.27 m square, **blue** most often, also red, pink and green. A thermos and a tray of cups on each table. People on stools under the shop's tarp or a red pop-up gazebo (3 x 3 m, eave 2.1 m).
- **Second setup, just as common**: full-size **blue plastic chairs** (seat 0.43 m, back to 0.80 m) at blue plastic tables (0.70 m high, 0.70 m square), in long rows on the pavement [photo `tea_shop/02`].
- Inside the shop: steel-legged tables, a glass cabinet of snacks (0.9 m high), a big steel kettle on a charcoal stove.
- Pavement spill: 4-12 tables per shop, so 2-6 m of pavement covered.
- The game (`tea0-2`) has a 1.6 table at 1.3 studs (0.43 m) and three stools 0.85 studs (0.28 m): right for the low setup. The chair-and-table setup is missing, and so are the gazebo, the thermos and the cups.

### 2.11 Street food carts and stalls
[photos: `food_cart/02`, `03`, `kerb_paint/02`]
- **Cart**: a steel or wooden counter about 1.6-1.8 m long, 0.6 m deep, 0.9 m high, the front wrapped in a printed vinyl banner (telecom and drink ads in blue, red, yellow). Steel trays on top, a gas or charcoal stove, a plastic bucket. Sometimes on two bicycle wheels with push handles.
- **Shade**: a big multi-colour umbrella (2.0-2.4 m across; segments red / green / yellow / blue) or a tarp (pink, red, blue) on bamboo or steel poles at about 2.2 m.
- **Seats**: pink, red or blue perforated stools (0.45 m) or low stools; steel-framed tables.
- **Night**: a bare LED bulb on a cable (white), Chinatown strings of red lanterns.
- The game's `vendor0-4` (5.0-stud canopy disc, cart 3.0 x 2.2 x 1.8 studs, one stool) is close for the umbrella type. Missing: the banner-wrapped counter, the tarp stalls and the bulb at night.

### 2.12 Trishaws (saiq-ka)
[photos: `trishaw/01`, `02`; sources: inkl / mingalago]
- A standard black roadster bicycle (28-inch wheels, 0.71 m across; wheelbase 1.15 m; 1.85 m long; handlebar at 1.05 m) with a **sidecar on the rider's right**.
- The sidecar: a red or maroon steel frame on one wheel (about 0.6 m). **Two padded seats back to back** (one facing forward, one backward), vinyl cushions in red, maroon, black or green, seats at 0.55-0.6 m. Box about 1.2 m long, 0.65 m wide.
- Whole width about 1.45 m. A small white licence plate on the handlebar, a bell, often a parasol or a plastic sheet roof in the rain.
- Where: stands of 4-10 at lane mouths, markets and bus stops, mostly on the side streets. They are restricted on the main roads downtown.
- The game's trishaw has the sidecar on the right (correct), but **one seat only** and a 3.4-stud frame (1.1 m at 3 / m: about 40% too short). Real length at 3 / m: 5.5 studs, width 4.4 studs.

### 2.13 YBS buses
[source: Myanmore YBS guide (2017-18); photo `ybs_bus_stop/06`, `03`]
- **Route colour groups** (body colour by group):
  - Blue: north districts (1, 11, 20-23, 35-42, 61, 68, 69).
  - Red: east districts (2-7, 12-19, 24-30, 38, 59, 63, 64).
  - Green: lines that feed the main roads (43-55, 60, 62, 66, 67).
  - Purple: south districts (8-10, 31-34, 70).
  - Brown: downtown (56-58).
- The network has been renumbered and grown since (to about 130 lines, Wikipedia). The colour-by-area idea stayed, but check current liveries.
- **Livery** [photos `ybs_bus/03`, `ybs_bus/02`, `ybs_bus_stop/06`, `ybs_bus_stop/03`; Feb 2017-2018]:
  - Older second-hand Korean and Japanese buses (mostly **Hyundai Aero City**, also Hino and Isuzu) were repainted in bright blocks: an orange roof frame and pillars, a **green band** under the windscreen, a **red lower front**, blue skirts, plus all-over ad wraps on the sides.
  - Some are mostly **blue with a white swoosh**.
  - The route box over the windscreen is white with "YBS" in blue between two **red squares holding the route number in Burmese digits**. A Burmese destination strip sits under the windscreen.
  - Newer Chinese buses (Yutong, Ankai, Golden Dragon; 2017-19) are **yellow, with a white YBS header**.
  - Red plates ("YGN 3G-6922").
- Size: 10.5-12 m long, 2.5 m wide, 3.1-3.3 m high (31.5-36 x 7.5 x 9.6 studs). Minibus lines use Toyota Hiace or Coaster-type buses, often wrapped in ads [photo `power_pole/01`].
- Display: an LED or printed route number on the front top, the right-hand door (Myanmar drives on the right; most old buses had a left-hand door cut in on the right side).
- **Red number plates** for commercial vehicles (white letters) [photo `ybs_bus_stop/06`].

### 2.14 Taxis
[source: bestsellingcarsblog 2014; photos `tea_shop/02`, `street_lamp/03`]
- About 20% of all vehicles in town in 2014 were Probox / Succeed, 95% of them taxis, mostly **white or silver**. Also Nissan AD, Caldina, Fielder, Honda Partner, Belta, Corolla Axio, Suzuki Swift (later).
- [photo `taxi/01`] A white Toyota Crown Comfort / Probox-class car with a **yellow "TAXI" roof light** (about 0.45 x 0.15 x 0.12 m). A company badge, "CITY TAXI" and a licence number on the front doors, the car number in red on the rear wing. **Red plates** with white letters ("YGN AA-3855").
- In the game: taxi type A (hatch / Probox) as 22% of parked cars, but there is no taxi roof light and no red plate.

### 2.15 Pick-ups (line buses and goods)
[photos: `street_lamp/03`, `tea_shop/01`]
- **Line-bus pick-ups (ferries)**: Toyota Town Ace / Lite Ace or Mazda pick-ups with a **steel canopy roof and two bench rows** in the back, people standing on the tailboard. White with red or blue stripes, or ex-Japanese company liveries (red-white-blue). About 4.3 x 1.7 x 2.2 m with the roof.
- **Kei pick-ups and vans**: Suzuki Carry, Daihatsu Hijet, Suzuki Every. 3.4 x 1.48 x 1.8 m. White or silver.
- **Toyota Dyna / Hino Dutro / Isuzu Elf**: small trucks with a high steel cage or tarp, 4.7-6 x 1.7-2.0 x 2.2-2.8 m. White or blue cab.
- Mostly on red commercial plates.

### 2.16 Cars and their colour mix
[source: bestsellingcarsblog 2014, Irrawaddy 2019; photos `street_lamp/03`, `tea_shop/02`]
- Most common: Toyota Probox / Succeed (taxis), Suzuki Swift (most common private car), Toyota Belta, Honda Fit, Mazda Demio, Toyota Vitz / Ist / Ractis, Corolla Fielder / Axio, Toyota Mark II (JZX90-110, the "shwe nga"), Mark X, Crown, Wish, Alphard, Hiace, Hilux (and Hilux Surf / Prado), Honda CR-V / Fit.
- Since the 2017-18 import rules, new imports are left-hand drive (Suzuki Swift / Ciaz / Ertiga built locally, Toyota from Thailand, Hyundai, Kia). The fleet mixes right- and left-hand drive.
- **Sizes** (m):

  | Model | L x W x H |
  |---|---|
  | Probox | 4.24 x 1.69 x 1.52 |
  | Belta | 4.30 x 1.69 x 1.46 |
  | Mark II JZX110 | 4.74 x 1.76 x 1.46 |
  | Wish | 4.59 x 1.70 x 1.60 |
  | Alphard (2nd gen) | 4.85 x 1.83 x 1.90 |
  | Hilux (2015 on) | 5.33 x 1.86 x 1.80 |
  | Hiace (long) | 4.84 x 1.69 x 1.98 |
  | Swift | 3.85 x 1.70 x 1.50 |

- **Colours** (estimate from the photos and sources): white about 45%, silver / light grey about 25%, black about 10%, dark grey 5%, red, blue, champagne and others 15%.
- **Plates**: private plates are **black with white letters** ("YGN 4P-6094"), commercial and taxi red.
- In the game: kinds A-F and 70% white / silver / grey. That fits. The black plates and red commercial plates are missing.

### 2.17 Footbridges
[OSM; known]
- 80 sites in the box. Steel or concrete decks 2.0-2.5 m wide with a **5.5 m clearance**, a steel truss or plate-girder side, a corrugated or polycarbonate roof on many (blue or green), and two stairs (1.5-2 m wide, 20-30 steps) with landings. Sides often carry big ad banners.
- The game: 18 built in the batches. The clearance is 18 studs (6 m at 3 / m), which is right.

### 2.18 Others seen or mapped that the kit lacks
- **Orange YCDC wheelie bins** (about 0.6 x 0.7 x 1.1 m) at bus stops and pavements [photo `ybs_bus_stop/04`].
- **Betel stalls**: a glass-top box on a small table, a stool, red stains.
- **Slab-covered drains** along the kerb with broken slabs and open gaps [photo `kerb_paint/01`].
- **Concrete traffic-island noses** painted black and white, and **water tanks** (black / blue plastic 1-2 m^3) on roofs (already in).
- **Satellite dishes**, **blue tarps** and **awnings** on facades [photo `tea_shop/01`] (building kit's job).
- **Shrines**: a small spirit-house / Buddha shelf on a post by trees and junctions [known].

---

## 3. Densities per 100 m (one side of the road)

Estimates from OSM (bus stops, signals, crossings) and the photos (everything else). Check with Mapillary when a token is available.

| Item | Main road (primary / secondary) | Downtown numbered street | Residential street / lane |
|---|---|---|---|
| Bus stops | 0.18 (one per ~550 m) [OSM] | 0.1 | 0 |
| Street name signs | 0.3-0.5 (one per junction) | 1-2 (every corner, about 60-70 m blocks) | 0.2 |
| Direction / regulatory signs | 1-2 | 1 | 0.3 |
| Street lamps (own poles) | 3 (both sides or the median, 30-35 m) | 0 (on the power poles) | 0 |
| Power poles | 2.5-3 (one side) | 5-6 (both sides, 30-40 m) | 2.5-3 (one side) |
| Transformer platforms | 0.3 | 0.4 | 0.3 |
| Stalls (umbrella / cart / tarp) | 2-4 by markets and bus stops, 0.5 elsewhere | 4-8 | 0.5-1 |
| Tea-shop spill (tables) | 1-3 | 4-8 | 1-2 |
| Parked cars | 3-6 in service lanes / half on the pavement; none where bus bays or railings | **12-16** (both kerbs, plus a **centre row of nose-in parking** on many downtown streets) | 6-10 (both kerbs, half on the verge) |
| Motorbikes | 0 inside the ban area | 0 | 0 inside the ban area |
| Trishaws | 0 (restricted downtown) | 1-3 at stands | 1-2 |

**Motorbikes**: petrol motorbikes have been banned in most of the Yangon City Development Committee townships since 2003 [source: Frontier Myanmar, Coconuts, Saigoneer]. Outer townships ride them (Hlaing Tharyar, Insein, North Okkalapa, Thaketa, Dagon Seikkan, Dala). The map box takes in parts of Insein (north-west), North Okkalapa / Thingangyun (north-east) and Thaketa (south-east). In those edge areas a few motorbikes (and e-bikes everywhere) are right; in the middle (Kamayut, Bahan, Sanchaung, downtown, Mayangone) **none** except police. The township lines are not in this extract; take them from OSM `boundary=administrative admin_level=8` when this is built.

---

## 4. Pedestrians

- **Men**: a longyi (pahso) in **small checks or plaids**, mostly dark (navy, dark green, brown, maroon, grey, black), with a white or pale shirt or a T-shirt [photos `tea_shop/01`, `ybs_bus_stop/01`, `trishaw/02`]. Office workers wear a white shirt; some wear trousers. Rubber or velvet flip-flops.
- **Women**: a htamein in **brighter prints** (pink, purple, red, teal, floral and geometric patterns), with a fitted blouse in a matching or plain colour [photos `ybs_bus_stop/02`, `04`, `food_cart/03`]. Thanaka (yellow-cream paste) on the cheeks for many [photo `ybs_bus_stop/01`]. An umbrella in the sun or rain is very common [photo `ybs_bus_stop/04`].
- **Monks**: maroon / burgundy robes (about 120, 35, 35), carrying alms bowls in the morning. **Novices** too. **Nuns** wear **pink** robes with an orange-brown sash and shaved heads [source: Wikipedia, travel sources].
- **School children**: white shirt or blouse with **green** longyi / htamein (secondary) or green shorts / skirt (primary) [source: Wikipedia "School uniforms in Myanmar"]. Nursing students: white and red. Technological universities: white and dark blue.
- **Muslim women** in black or dark hijab downtown [photo `tea_shop/01`].
- **Density** (estimate):
  - Downtown markets and Sule: 20-40 people per 100 m of pavement by day.
  - Main-road shopping stretches: 8-15.
  - Residential streets: 2-6.
  - Peaks 7-9 am and 4-7 pm (bus stops crowded, 10-30 waiting), lunch at tea shops.
  - Monks 6-9 am (alms rounds, lines of 5-20).
  - School children 7-8 am and 3-4 pm near schools.
  - Night: tea shops and night markets (Chinatown 19th Street) busy until about 10 pm. The rest of the city empties after 9 pm.
- In the game (`YangonStreetLife.lua`): men and women in plain solid colours; monks (maroon); kids in white and green near schools; 8-part blocky figures at Roblox size (5.4 studs = 1.8 m). Missing: patterned longyi, nuns, umbrellas, thanaka, time-of-day density.

---

## 5. What the game has, and what is missing or wrong

The game has, from `details.py` / `streetlife.py` / `YangonStreetLife.lua` (counts are the items in `build/city/details_*.json` and `src/shared/YangonStreetLife*.lua`):
- 398 bus stops (shelter or pole), 321 signal pole sets and 18 footbridges.
- 17,909 power poles (Beams as wires), with a lamp on every second pole.
- 829 tea-shop sets, 504 vendor umbrellas (downtown batch only), 200 trishaws.
- 1,629 kerb trees, 2,262 road patches.
- 8,242 parked-car spots, 982 standing spots and 2,350 pavement paths.

### Top 15 gaps (biggest effect on "this is Yangon" first)

1. **Bus stops are all one invented design** (blue frame, white panel, bench, at every OSM stop that fits). Real Yangon has three: the white FMI Decaux shelter with the YBS route box and a lit ad end (about 15%), the old blue tubular canopy downtown, and a plain YBS pole (about 80%). Build the three, put the yellow kerb along the bay, add the orange bin and the ad panels.
2. **No YBS buses or line-bus pick-ups in traffic.** The most visible Yangon vehicles are missing:
   - YBS buses in the route-group colours (blue, red, green, purple, brown, and the yellow / white new fleet), 11-12 m long.
   - The Town Ace / Mazda ferry pick-ups with a roof and benches.
   - Kei trucks, Dyna trucks.
   - Traffic types are A-F cars only.
3. **Wires are too thin and too few, and poles are one-sided everywhere.** Real streets show 6-20 cables per span, slack loops, junction boxes and cables to every house. Downtown numbered streets have poles on both sides every 30-40 m. The game puts poles every 96 / 72 studs on one side (`poles()`), which at 1.6 studs / m is 60 / 45 m. At 3 / m use 33 m (100 studs) on streets, 30 m on downtown streets (both sides).
4. **Transformers are too rare and the wrong shape.** The game has one 1.4 x 2.2 x 1.2-stud box on 7% of poles. Real ones are a two-pole H-frame with a platform at 3.5-4 m and a tank transformer, about one per 300 m.
5. **Main-road lamps are Monaco's StreetLamp.** Replace them with the Yangon types:
   - grey conical poles 9-10 m, white LED heads;
   - double-arm poles in the median on divided roads (Pyay, Kabar Aye, University Avenue);
   - cobra heads on the power poles on older roads.
6. **No police traffic booths** at the big junctions (Sule, Hledan, Myaynigone, Bogyoke and Shwedagon Pagoda Road), and no traffic police figures in white and dark blue. The booth is a hexagonal kiosk with an orange hipped roof on the corner, next to the signal pole and cabinet.
7. **No median railings.** Main-road medians in Yangon carry 1.0-1.2 m steel railings with gaps only at crossings. Divided roads in the game have bare medians.
8. **Kerb paint is wrong in places.** It needs to vary:
   - yellow at bus bays;
   - red and white at junctions, medians and government frontages;
   - black and white on median noses;
   - plain grey on most streets.
   (The look rule of 2026-11-13 puts red and white bands on every kerb.)
9. **No street name signs or overhead direction signs.** Needed:
   - blue (downtown) and green (elsewhere) Burmese + English name plates at every corner of named streets;
   - green overhead boards at the 10-15 biggest junctions and flyover approaches.
   The real-word sign atlas from commit 5be64cc9 can draw them.
10. **No zebra crossings or pedestrian signals as items.** OSM has 671 crossings (132 marked or zebra) and 17 signalled ones. The game's `RoadLines` has `noZebra`; crossings are not placed from OSM.
11. **Traffic signal heads are the wrong design.** Yangon uses **horizontal** black heads with the **countdown digits built in**, on **white** poles with long mast arms (photos `cars/06`, `footbridge/01`). The game uses a vertical three-ball head on a dark pole. Also missing:
    - the CCTV camera on the arm;
    - the controller cabinet;
    - the high-mast floodlights at big junctions;
    - pedestrian heads at signalled zebras.
    Place them from the 214 real junctions after the rescale.
12. **Trishaws are too small and have one seat.** Real: 1.85 x 1.45 m, a 0.71 m bicycle wheel, two vinyl seats back to back in red / maroon. The current frame is 1.1 m at 3 / m. Add stands of 4-10 at markets and bus stops, not only pairs at lane mouths.
13. **Parked cars lack downtown's centre-row nose-in parking and the right plates.** Missing:
    - the middle-of-the-street angle parking on the downtown numbered streets;
    - black private plates and red taxi / commercial plates;
    - taxi roof lights;
    - left-hand-drive cars (a share, for the post-2018 fleet);
    - Alphards and Hiaces in the right numbers.
14. **Pedestrians are plain, with no time of day.** Missing:
    - checked longyi for men, patterned htamein for women;
    - umbrellas (very common), thanaka;
    - pink-robed nuns;
    - morning monk alms lines;
    - crowds waiting at bus stops at peak hours;
    - density by area (downtown and markets 3-5 times the residential level) and by hour (thin after 9 pm except tea shops and night markets).
15. **Tea shops and stalls have one look.** Missing:
    - the blue chair-and-table rows;
    - the red pop-up gazebos and tarps on poles;
    - banner-wrapped counters;
    - thermoses and cups;
    - betel stalls;
    - the bare bulb at night.
    Vendors exist only in batch 2 (downtown), though stalls cluster by every market (67), bus stop and school gate.

### Scale traps for the rebuild
The current props were built at different scales. At 3 studs = 1 m:
- The power pole (25.4 studs = 8.5 m), the signal pole (22.5 = 7.5 m) and the tea stools (0.85 = 0.28 m) are right.
- The bus-stop roof (7.75 studs = 2.6 m) is right.
- The trishaw (3.4-stud frame = 1.1 m, 2-stud wheels = 0.67 m) and the vendor umbrella (5.0 studs = 1.7 m) are too small.
- The footbridge clearance (18 studs = 6 m) is right.

Specify every new prop in metres (this report) and multiply by `geo.SPM`.

## Sources
- OpenStreetMap contributors (ODbL), Geofabrik Myanmar extract 2026-11-12.
- Wikimedia Commons photos: see each `<item>/sources.json` (licence and artist per file).
- [Le Petit Journal: about 150 bus shelters already installed in Yangon (17 Feb 2019)](https://lepetitjournal.com/birmanie/environ-150-abribus-deja-installes-dans-yangon-250460)
- [Myanmore: The Ultimate Yangon Bus Service Guide](https://www.myanmore.com/ultimate-yangon-bus-service-guide/)
- [Wikipedia: Yangon Bus Service](https://en.wikipedia.org/wiki/Yangon_Bus_Service)
- [Coconuts Yangon: New street signs cover downtown core](https://coconuts.co/yangon/news/new-slightly-underwhelming-street-signs-cover-downtown-core)
- [Best Selling Cars Blog: Myanmar 2014 photo report, the cars of Yangon](https://bestsellingcarsblog.com/2014/12/myanmar-2014-photo-reports-the-cars-of-yangon/)
- [Irrawaddy: Burma's clunkers scrapped in rush for new cars](https://www.irrawaddy.com/feature/burmas-clunkers-scrapped-rush-new-cars.html)
- [Frontier Myanmar: Yangon's two-wheeled conundrum](https://www.frontiermyanmar.net/en/yangons-two-wheeled-conundrum/)
- [Saigoneer: Yangon, lessons from a neighbor that banned bikes](https://saigoneer.com/asia-news/10010-yangon-lessons-from-a-neighbor-that-banned-bikes)
- [Wikipedia: School uniforms in Myanmar](https://en.wikipedia.org/wiki/School_uniforms_in_Myanmar)
- [inkl / AFP: In Myanmar, sidecars still a popular mode of transport](https://www.inkl.com/news/in-myanmar-sidecars-still-a-popular-mode-of-transport)
- [MingalaGo: Myanmar trishaw](https://mingalago.com/en/interest/detail/myanmar-trishaw)
- [Frontier Myanmar: Faces of Yangon, the men in blue](https://www.frontiermyanmar.net/en/faces-of-yangon-the-men-in-blue/)
