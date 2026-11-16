# Yangon street-level detail survey: blueprint for the whole-map rebuild

Date: 16 Nov 2026. Scale: **3 studs = 1 m** (the rescale contract in `City Legends/2026-11-16 Yangon rescale plan - 1 to 1 at player scale.md`). Every count below is **per 100 m of street (one side unless "both sides")** or per real area, never per stud, so it survives any scale change.

Why: owner, 16 Nov: "rn yangon dont look like real life yangon like only the roads feel like yangon but everything else feels fake".

## How this was made
- **46 Commons photos** downloaded into this folder (`arterial/`, `township/`, `lane/`, `downtown/`, `market/`, `lake/`, `pagoda/`), licences in `sources.json`; the authors' names are on each `source_page`, because the scraper did not pick them up. All 46 are CC BY, CC BY-SA, CC0 or public domain. About 30 of them were studied one by one, and the numbers marked **[photo]** were read from them. Photo dates run 2008-2021. Most are dry-season shots (Feb-Apr): yellow padauk petals, a hazy sky.
- Web reading (links in "Sources" at the end): car fleet surveys, motorbike-ban reports, drainage studies, the Yangon power grid, YBS, Yangon trees, travel photo essays.
- Older vault research reused rather than repeated: the road look (`Roblox Playbook/2026-11-13 Research - Yangon road look.md`), the building kit refs (`../kit/kit_reference.md`, `../kit/palette_measured.json`), and the clutter and density reports (`Games/CityLegends/build/plan/clutter.md`, `density.md`).
- **[est]** marks numbers that come from general knowledge of Yangon and the photos together, without one clean measurement. Treat them as starting values to check against a new photo before locking them in.
- Not done: walking-tour videos. The YouTube frames need the browser, and stills were enough for the props. Street View: Yangon's coverage is patchy and not openly licensed, so it was not used.
- Commons' API rate-limited this machine after a few calls, so the files came through `Special:FilePath` and the licences from the file pages.

---

## 0. The ten things that make a street read "Yangon" (from every photo together)
1. **Big dark trees everywhere.** Rain trees and padauk 15-25 m tall arch over the streets. From the air, residential townships are 55-65% tree canopy with roofs poking through (`arterial/pyay_road_hanthawaddy_aerial.jpg`).
2. **Black overhead cables in every view.** 6-20 sagging black lines per street and 30-60+ downtown, on grey concrete poles 9-11 m tall with cross-arms, lamps and transformers (`downtown/busy_back_streets.jpg`, `arterial/kabaraye_bahan_095227.jpg`).
3. **Weathered concrete.** Black mildew streaks run down from every ledge, sill and balcony, and whole upper floors are near-black on 1960s-90s blocks (`lane/10th_ward_panoramio.jpg`, `arterial/kabaraye_bahan_094036.jpg`).
4. **Every window is caged or hooded.** Steel grilles, balcony cages, small corrugated "hood" awnings (blue, green, red), AC boxes, satellite dishes (many of them BLUE), laundry (`township/moe_kaung_rd_yankin_5099.jpg`).
5. **White and silver Japanese cars** (about 75%), with white taxis (roof TAXI sign, red plates), pickups and yellow YBS buses. No motorbike crowds in the centre.
6. **Walls along every frontage that is not a shop.** Painted compound walls 1.8-2.5 m tall with pillars, gates, finials, razor wire and painted ads (`arterial/kabaraye_bahan_095423.jpg`, `pagoda/kalaymyo_monastery_kabaraye.jpg`).
7. **The ground is paving, packed dust and drains, not lawn.** Grey concrete slabs, dirt shoulders, slab-covered drains, puddles, litter at the kerb (`downtown/signs_and_rubbish.jpg`).
8. **Signs stacked on signs.** Rectangular boards in red, blue, green, yellow and white, Burmese over English, projecting signs, LED scrollers, cloth banners strung across streets.
9. **Street life sits on the pavement.** Tea-shop stools (teal, green, red, pink) under a tree, umbrella stalls, push-carts, trishaws (`downtown/sidewalk_scene.jpg`, `downtown/45th_st_trishaws.jpg`).
10. **Gold.** Stupa spires, finials on monastery walls and golden roof ridges show up every few hundred metres.

---

## 1. Area types: the tiny details

Each block below is in the brief's 12 categories. Sizes are in metres (studs = ×3).

### 1A. Main arterial roads (Pyay Rd, Kabar Aye Pagoda Rd, University Ave, Insein Rd)
Photos: `arterial/*` (Kabar Aye at Bahan, Hledan Centre, Myaynigone, Insein Rd, Pyay Rd, the YBS stop, the Hanthawaddy aerial).

1. **Ground**
   - Carriageway: worn warm grey asphalt (about 105-120 grey, warm), patched in darker rectangles 2-6 m long about every 30-60 m. Oily darker stripes run down the middle of each lane, and dust gathers at the edges [photo].
   - Kerb: red/white bands about 1 m each, 20-30 cm tall, on most of Pyay and Kabar Aye. University Avenue and Insein Road are mostly plain concrete, often black with grime [photo].
   - Pavement: 2.5-4 m of grey poured concrete with joints every 1.5-3 m. It is cracked, and the dusty edge goes dirt-brown at the building line [photo]. Pavers appear only in front of malls (Hledan Centre, Myanmar Plaza).
   - Drain slabs run under the pavement edge: rectangular concrete covers about 0.5 × 1 m, with a square grate about every 20-30 m [est].
   - Bus bays have a **yellow-painted kerb** [photo `ybs_yin_pyin_bus_stop`]. Yellow cross-hatching is painted under the flyovers and at junctions [photo `kabaraye_bahan_095423`].
   - Building forecourts are concrete aprons 5-10 m deep where cars park nose-in ON the pavement [photo `kabaraye_bahan_095227`].
2. **Trees**
   - Rows of rain trees (*Samanea saman*), padauk (*Pterocarpus indicus*), mahogany and Indian almond along the pavement or just inside compound walls, every 10-20 m on each side [photo `ybs_yin_pyin_bus_stop`, `bo_aung_kyaw_st`].
   - Rain trees: trunk 0.8-1.5 m across, first fork at 3-5 m, crown 18-30 m wide, 15-25 m tall. Crowns meet over 2+2 roads in Golden Valley and Bahan.
   - Coconut palms in clusters of 2-5 behind walls (15-20 m tall).
   - Trunks: some trunks carry little shrines; painted white or red-white bands at the base exist on some roads [est; not confirmed in these photos].
3. **Overhead**
   - Concrete poles (spun or tapered square, about 25-30 cm thick, 9-11 m tall) on one side every 30-40 m. They carry 2 cross-arms (1.5-2 m) and 6-15 black cables, and every second or third pole has an LED cobra-head lamp on a 1.5-2 m arm [photo `kabaraye_bahan_095227`].
   - The bottom 1.5-2 m of a pole is often painted in black/white or red/white bands, or black-and-yellow chevrons on mast bases [photo `traffic_jam`, `kabaraye_bahan_095423`].
   - Separate grey steel lamp posts with one curved arm (10-12 m) every 30-35 m on the main roads, in the median on divided stretches [photo `pyay_road`, `myaynigone`]. Some stretches have ornate yellow multi-globe posts [photo `pyay_road`].
   - High-mast flood lamps at big junctions (20-25 m, ring of 6-8 heads) [photo `myaynigone_intersection`].
   - Pole transformers (grey drum or box, about 0.6 × 1.2 m, on a platform between two poles) about every 150-250 m [est].
4. **Furniture**
   - YBS shelters: white steel frame, flat roof about 3 m high, glass back panel, a bench, 1-2 lit advertising panels (1.2 × 1.8 m; Milo green and Nescafé red are typical), a "YBS" roof sign. One every 300-500 m per direction, often 3-4 shelters in a row [photo].
   - Concrete barrier blocks (orange, or red-white, about 0.6 × 1 m) run in lines along the median edge and at works [photo `pyay_road`, `kalaymyo`].
   - Big billboards on 1-2 steel columns (about 10 × 4 m, 8-12 m up) at every major junction and roundabout. Rooftop billboards are common [photo `myaynigone`, `kabaraye_095227`, aerial].
   - Green direction signs (white text, Burmese and English) on a cantilever or two posts. Traffic lights hang from the flyover soffits or arms.
   - Pedestrian footbridges (steel, green or blue, about 5.5 m clearance) at schools and markets.
5. **Life**
   - Traffic about 75% white or silver [photo: every arterial shot]. Mix: Toyota Probox / Succeed / Fielder / Corolla wagons (taxis), Belta, Vitz, Swift, Fit, Wish, Alphard, Land Cruiser Prado, Hilux, Suzuki Carry / Daihatsu Hijet mini-pickups (blue or white with canopy: "line-ka"), Kia K2700 / Hyundai Porter trucks.
   - Taxis: white or silver with a roof "TAXI" box and **red number plates** (private = black plates). The newer "City Taxi" fleet is white with a blue-yellow diagonal stripe [photo `moe_kaung_5099`].
   - Buses: YBS Yutong / Ankai, mostly **yellow and white** with a "YBS" header. Older Hino / Daewoo city buses are cream with blue, green or red stripes [photo `ybs`, `insein_road`, `bus_on_the_road`, aerial].
   - People wait in clusters of 5-15 at stops. A street dog appears now and then.
6. **Frontage**
   - A mix of setback compounds (walls, hedges, palms) and 4-15 storey blocks set back 5-15 m behind forecourts.
   - Big glass mall fronts only at the malls.
   - Monastery and pagoda walls: white with blue or teal pilasters every 3-4 m, golden finials on top, lattice panels, painted TOA / GMG paint ads [photo].
7. **Density** [est from the aerial]: 30-50% building cover along the road. The rest is compound gardens and car aprons, never empty lawn.
8. **Colour**: asphalt warm grey, kerb red (195, 47, 45) / white, pavement grey (150, 146, 136), walls dirty white, huge dark-green tree masses. Sky: hazy pale blue.
9. **Religion**: a golden stupa or monastery roof visible every 300-600 m.
10. **Dirt**: dust film on the kerb face, leaves and padauk petals in the gutter, plastic bags at the pole bases.
11. **Water**: where the road runs beside Inya Lake (Pyay Rd, Kabar Aye), a low railing, then the embankment (see 1F).
12. **Night**
   - Street light: white LED [owner's own rule: white].
   - LED scrolling signs (red), lit shop boards, billboards lit from below, 24 h convenience stores (bright white).

### 1B. Downtown grid streets (the 1st to 50th streets, Maha Bandula, Anawrahta, Bogyoke)
Photos: `downtown/*`, `lane/street_view_8391036518`, `lane/street_soccer_hitech`, `lane/10th_ward_panoramio`.

1. **Ground**
   - Street: 9-12 m of asphalt with no lines on the numbered streets, very worn, with mud and dust in the gutters.
   - Pavement: 1.5-3 m of concrete slabs (about 0.6-1 m), cracked and raised 20-40 cm above the road. Shop plinths and steps break it into pieces, with 1-3 steps at doorways [photo `signs_and_rubbish`].
   - The kerb is a plain concrete edge, chipped, with an open drain or slab-covered drain behind it.
   - About 1 slab in 10-20 is broken or missing [est].
2. **Trees**: few. 0-3 trees per 100 m (rain trees on some wider streets like Bo Aung Kyaw, with crowns over the whole street) [photo `bo_aung_kyaw_st`]. Weeds and figs grow out of facades and roof edges [photo `busy_back_streets`].
3. **Overhead (the heaviest anywhere)**
   - 30-80 cables crossing or running along each block. Concrete and old steel poles every 20-30 m on both sides, with grey cobra lamps on long arms over the street [photo `busy_back_streets`].
   - Bundles of coiled spare cable (1-2 m loops) on every second or third pole.
   - TV aerials on the roof edges; satellite dishes 0.6-1.8 m on balconies (blue, white, grey; 3-10 per facade) [photo `typical_downtown_street`, `10th_ward`].
4. **Furniture**
   - Hardly any formal furniture: a few police booths at the big junctions, signal heads on poles, and "no parking" plates.
   - Water barrels and ceramic water pots (free drinking water) on stands [est, common].
5. **Life**
   - Parked cars nose to tail on both sides: 15-18 per 100 m per side [photo `typical_downtown_street`].
   - Trishaws (sidecar bicycles), 2-6 per 100 m in the side streets [photo `45th_st_trishaws`, `typical_downtown_street`].
   - Push-carts, pickups unloading, 20-60 people per 100 m by day.
   - Men in longyi (about 60%), women in htamein, monks in the morning. Pigeons near the mosques.
   - Umbrella stalls: 4-12 per 100 m, with plastic stools and low tables [photo `45th_st_trishaws`, `sidewalk_scene`].
6. **Frontage**
   - Continuous walls with no gaps. Colonial 3-5 storey buildings (yellow, red brick, mint green), 1960s-90s 6-10 storey walk-ups (mint, cream, pink, grey), with balcony cages on every floor [photo].
   - Ground floors are fully open shops behind steel roller shutters (grey or blue).
   - Signboards stacked 2-6 deep on poles, plus boards across the facade (2-6 m × 0.6-1.2 m, red / white / green / blue / yellow).
   - Blue tarp and green construction mesh on 1 building in 5-10 [photo `busy_back_streets`].
7. **Density**: 85-100% frontage built, buildings 6-10 storeys, the street 12-15 m between facades. The lanes behind the blocks are 3-5 m (rubbish, water pipes, cats).
8. **Colour**: faded pastel paints (mint 170, 215, 200; cream; pale pink; yellow), dark grime. Blue awnings and dishes dot the facades.
9. **Religion**: Hindu temples (colourful gopurams), mosques (green and white, minarets), Chinese temples, Sule Pagoda.
10. **Dirt**: litter heaps at the pavement edge every 20-40 m (white plastic bags), betel-spit red stains on the pavement [est, common], puddles, black water in the drains.
11. **Water**: the Strand and the river (not in the batches yet).
12. **Night**
   - Neon and LED boards (green, red, blue), strings of coloured LEDs, white fluorescent tubes at stalls.
   - Beer-station tables (green plastic chairs) fill 19th Street [photo `19th_st_night`].
   - The upper floors are dark.

### 1C. Township streets (Saya San Rd, Moe Kaung Rd, Inya Rd, Dhammazedi Rd, Hledan side streets)
Photos: `township/*`.

1. **Ground**
   - Road: 7-10 m of asphalt, often with no kerb. The asphalt edge breaks into a dirt and gravel shoulder 1-3 m wide, or into concrete drain slabs [photo `moe_kaung_5099`, `saya_san_093225`].
   - On some stretches a narrow raised pavement (1-1.5 m), patchy.
   - A shop forecourt is a raised concrete step 15-40 cm high [photo `moe_kaung_5099`].
   - Puddles in the potholes in the wet season.
2. **Trees**
   - 4-10 trees per 100 m per side: padauk (yellow bloom in April, petals carpet the road [photo `saya_san_093225`]), mango, tamarind, Indian almond, ashoka, neem.
   - Bougainvillea (magenta) over the walls, coconut palms behind them.
   - Canopy over the road: 30-70%.
3. **Overhead**
   - Slim concrete poles 8-10 m every 30-40 m on one side, 4-10 lines, a lamp on every second pole [photo `saya_san_093225`].
   - Service drops fan from the poles to each house (1-3 per house).
4. **Furniture**: few. Street-name plates (blue or green) at corners, ward signboards, small shrines, water pots, the odd bus stop.
5. **Life**
   - Parked cars: 4-10 per 100 m per side.
   - 1 kiosk or umbrella stall per 50-100 m (blue umbrella, cooler box, a stool) [photo `saya_san_093225`].
   - A tea shop every 150-300 m.
   - **Motorbikes do appear** in the outer townships (Yankin shot) [photo `moe_kaung_5105`]: about 1 per 100 m at most, never a cluster.
   - Ambulances and charity vans.
6. **Frontage**
   - Two kinds, alternating in runs of 50-200 m:
     - (a) rows of 4-5 storey walk-ups, continuous, ground-floor shops;
     - (b) compounds behind walls (houses, offices, monasteries).
   - Walk-ups: a balcony cage on every flat, corrugated window hoods in blue, green or red 0.5-0.8 m deep, an AC on 1 in 2 windows, laundry on 1 in 3 balconies, 1-2 dishes per facade [photo `moe_kaung_5099`].
7. **Density**: 45-65% built [est from the aerial]. Gaps between buildings 0-3 m; vacant lots fenced with corrugated sheet.
8. **Colour**: concrete grey with black streaks, cream, pale blue. Shop signs in saturated primaries.
9. **Religion**: a neighbourhood monastery or stupa every 300-500 m, with a gate arch, a blue railing on a low green plinth wall, and a gold spire [photo `moe_kaung_5105`].
10. **Dirt**: dust, fallen leaves, small rubbish heaps by the poles.
11. **Water**: none.
12. **Night**: shop strip lights and tea-shop fluorescents. The lamps are 30-60 m apart, so dark gaps are normal.

### 1D. Small lanes (ward lanes, "lan-thwe", 3-6 m)
Photos: `lane/*`.
1. **Ground**: concrete lanes (cast panels 3-4 m long with joints) or patched asphalt. An open drain on one or both sides (0.3-0.6 m, black water, a slab bridge at each gate). Grass and weeds in the cracks. Packed earth next to the walls [photo `dog_and_bike`].
2. **Trees**: from the compounds (mango, banana, papaya, coconut). Potted plants line the lane edges.
3. **Overhead**: 1-2 poles per 50 m, wires zig-zag across, lanes 5-10 m up.
4. **Furniture**: none, apart from a ward notice board, a water tank stand or a shrine.
5. **Life**: kids playing football or chinlone with goals of netting [photo `street_soccer_hitech`], bicycles, dogs (1-3 per 100 m, lying in the shade), chickens, a vegetable hawker with a basket on a bicycle.
6. **Frontage**: walls and gates (steel sheet gates in green, blue or maroon), wooden and brick houses, timber upper floors, lean-to sheds.
7. **Density**: very tight, building to building, 1-3 m side gaps.
8. **Colour**: rust, teal paint, mossy concrete.
10. **Dirt**: plastic in the drains, stains.
12. **Night**: a single bare bulb or fluorescent tube per house front.

### 1E. Residential compounds (Golden Valley, Bahan, Kamayut, Mayangon)
Photos: aerial, `saya_san_*`, `kabaraye_095508`.
1. **Ground**
   - Inside: concrete drives, tiled porches, small lawns (at most 20-30% of the lot), shrubs, packed earth under the trees.
   - Outside: the wall, then a strip of grass or dirt 0.5-2 m, then the road.
2. **Trees**: the compounds hold most of the city's big trees: 2-6 per lot (rain tree, mango, jackfruit, coconut, banana).
3. **Overhead**: a pole line along the street. A drop to each gate.
4. **Furniture**: gates 3-5 m wide, steel sliding or hinged, painted dark green, maroon or black. A guard hut (1.5 × 1.5 m) at the bigger compounds. Name plates.
5. **Life**: a parked car inside the gate. A watchman on a stool.
6. **Frontage**
   - The wall is 1.8-2.5 m: rendered brick painted white or cream, pillars every 3-4 m, on top **glass shards, spikes or razor wire on about 30%** [photo `yayadar_st` razor wire].
   - Bougainvillea spilling over. Old colonial teak houses with corrugated roofs, fretwork eaves and dark-stained walls [photo `kabaraye_095508`].
7. **Density**: building cover 25-40% of a lot. Lots run 20-40 m wide along the street, so a gate every 20-40 m.
8. **Colour**: deep green dominates. Roofs are corrugated metal: rust red, blue, grey-zinc, green [aerial].

### 1F. Inya Lake and Kandawgyi Lake shores
Photos: `lake/*`.
- **Inya, along Pyay and Kabar Aye**
  - An **embankment** about 2-3 m above the water: an asphalt walkway on top 3-4 m wide, a grass slope down to the water (no wall) [photo `inya_embankment`].
  - On top: twin-head lamp posts every 25-30 m; little pavilion-roof bench shelters (green with a white or red pyramid canopy, 1.5 × 1 m) every 40-60 m [photo].
  - Planters (white or green painted concrete rings, about 1.2 m) with small trees every 15-20 m.
  - The park side has manicured lawns, flower beds in patterns, royal palms in rows [photo `inya_park_grounds`].
  - Water: grey-green to brown-green, flat. Water lilies near the edges. Sailing dinghies moored in rows (the Yangon Sailing Club, masts 5-6 m) [photo `inya_01`].
  - Vendor carts under umbrellas along the walkway in the evening.
- **Kandawgyi**
  - A **teak boardwalk** about 1-1.5 m above the water on concrete piles every 3-4 m, brown timber deck 2-3 m wide, rust-brown handrail, running along the shore for kilometres [photo `kandawgyi_bridge`, `kandawgyi_02`].
  - Concrete revetment edges, huge rain trees and palms right on the bank, lily pads (10-30% of the near-shore water), a fountain jet.
  - Karaweik barge, Shwedagon on the skyline.
- **Colours**: water (90-110, 115-125, 100-110) olive grey-green, never swimming-pool blue. Lily pads dark green. Deck timber (120, 90, 60).

### 1G. Markets (Theingyi, Bogyoke, the township wet markets)
Photos: `market/*`, `downtown/45th_st_trishaws`.
- **Building**: a long 2-3 storey concrete market hall with a red corrugated roof, a colonnade, steel grilles and green tarps hung between the columns. Signs at the gates [photo `theingyi_market`].
- **Street**: vendors take the outer lanes. Every 2-3 m: a stall of crates, metal basins and plastic baskets on tarp or low tables. Multicolour umbrellas (2-2.5 m across: blue/white check, segmented red / yellow / blue / green) and blue pop-up canopies. Fluorescent tubes on poles. Hanging scales [photo `night_market_on_street`].
- **Cars**: double-parked, solid traffic.
- **Ground**: wet, dark, scattered with vegetable waste and plastic.

### 1H. Pagoda surroundings (neighbourhood stupas, monasteries, the big pagodas)
Photos: `pagoda/*`, `arterial/kabaraye_095423`, `township/moe_kaung_5105`.
- **Neighbourhood stupa**: gold (or white with a gold upper part), 4-15 m, on a square plinth with small corner stupas, a golden hti on top, often inside a monastery compound wall. Roughly 1-3 per km² in the townships [est].
- **Monastery**
  - Multi-tiered roofs with golden fretwork eaves, tin roofs in red, teal or rust, wall finials in gold every 3-4 m [photo `kalaymyo`].
  - A gate arch with a gilded name board. Signboards on stands.
  - Pruned trees in rows, a blue railing.
- **Under renovation**: a stupa wrapped in **yellow cloth**, bamboo scaffold [photo `kalaymyo`].
- **Approach roads to the big pagodas**: covered stairways, chinthe (lion) pairs, red and gilded name pillars, stone balustrades, mossy walls [photo `street_near_shwedagon`]. Monks in maroon walking in file.

### 1I. Overpasses and flyovers (Hledan, Kabar Aye / Bayintnaung, Shwegondaing)
Photos: `kabaraye_095423`, `hledan_center_front`, `kabaraye_095227`.
- **Deck**: bare concrete, a grey soffit with drain pipes (black PVC, 15 cm) down every pier. Piers 1.5-2.5 m, often painted with ads or black-yellow chevrons at the base.
- **Parapets**: white or grey with a steel railing on top. Lamp posts every 30-40 m on the parapet.
- **Under the deck**: traffic signals hang from it. Vendors, parked taxis, motorbike-free dust, pigeons.
- **Ramps**: 5-6% grade, solid retaining walls painted with ads.

---

## 2. Key density numbers (per 100 m of street; one side unless stated)

| Item | Main road | Downtown street | Township street | Lane | Notes |
|---|---|---|---|---|---|
| Concrete power poles | 2.5-3.5 | 4-5 per side | 2.5-3.5 | 1.5-2 | 30-40 m apart; downtown 20-25 m, both sides |
| Cables in a cross-section | 6-15 | 30-80 | 4-10 | 2-6 | black; sag 0.5-1.5 m between poles |
| Street lamps | 3 per side (30-35 m, staggered) | 4-5 (on poles) | 1.5 (every 2nd pole) | 0.5-1 | white LED |
| Pole transformers | 0.5 | 1 | 0.5 | 0.3 | grey drum, 2-pole platform |
| Big trees (crown ≥ 10 m) | 5-10 | 0-3 | 4-10 | 1-4 (from yards) | canopy over road: 40-80% / 0-15% / 30-70% / 10-40% |
| Palms (coconut) | 1-3 | 0 | 1-3 | 1-2 | behind the walls |
| Parked cars | 3-8 (on forecourts) | 15-18 | 4-10 | 1-4 | ~75% white or silver |
| Moving traffic in view (day) | 20-60 | 5-15 | 3-10 | 0-2 | taxis about 30% |
| Umbrella stalls / kiosks | 0.5-2 | 4-12 | 1-2 | 0-1 | 2-2.5 m umbrellas |
| Tea shops | 0.3 | 1-2 | 0.5 | 0.2 | 6-20 low tables, 30-60 stools |
| Trishaws | 0-1 | 2-6 | 1-2 | 0-1 | parked at corners |
| Pedestrians in view | 10-30 | 20-60 | 3-10 | 2-6 | |
| Stray dogs | 0-1 | 0-1 | 1-2 | 1-3 | sleeping in shade |
| Shop signboards | 3-10 | 15-40 | 6-15 | 0-2 | Burmese plus English |
| Gates in a compound wall | 2-4 | - | 2-4 | 3-5 | 3-5 m wide |
| Litter clumps | 3-8 | 10-30 | 5-10 | 5-15 | white and coloured plastic |
| Drain grates / slab covers | 3-5 grates | slabs all along | slabs all along | open drain | slab 0.5 × 1 m |
| Bus shelters | 0.2-0.3 per direction | 0.1 | 0.05 | 0 | |
| Billboards | 0.5-2 (junctions) | 0.5 | 0.3 | 0 | 10 × 4 m on columns, or rooftop |

**Ground cover per area type** [est, from the aerial and the photos]:
- Residential townships: tree canopy 55-65% from above; built footprint 30-45%; open lawn under 10%.
- Downtown: built 75-85%, canopy 5-10%.
- Lakeside park: lawn 40-60%, canopy 30-40%.
- **Empty open grass between buildings is almost never seen in inner Yangon.**

**Buildings**
- Walk-ups 4-5 storeys at 3.0-3.2 m a floor. Downtown 6-10.
- Gaps between walk-ups 0-1 m, between compounds' houses 3-10 m.
- Facade "weathering share" (darkened area) on buildings over 15 years old: 30-70%.

---

## 3. Colour palette at midday (sRGB targets for the photo; calibrate through `city/look_calib.py`)

| Thing | Colour | Note |
|---|---|---|
| Sky, zenith (dry season) | 150, 185, 220 | pale; haze lifts it |
| Sky, horizon | 215, 222, 225 | near-white haze band, 5-10° high |
| Monsoon sky | 200-225 grey-white | flat bright cloud |
| Asphalt (main) | 108-120 warm grey | patches 80-95 |
| Asphalt (lane) | 95-105 | dust overlay at the edges 170, 160, 140 |
| Concrete pavement | 150, 146, 136 | older: 130, 126, 118 |
| Packed earth / dust | 150, 128, 100 | dry; wet 95, 80, 65 |
| Kerb red / white | 195, 47, 45 / 232, 228, 218 | dirty white 200, 195, 185 |
| Tree crowns | 55-75, 85-105, 40-55 | dark; rain-tree crowns sit darker than lawns |
| Lawn (parks only) | 95, 130, 60 | dry season goes straw 160, 150, 95 |
| Wall cream / mint / pink | 228, 218, 190 / 170, 215, 200 / 225, 190, 185 | faded |
| Mildew streaks | 60-80 grey-black | about 40-60% opacity over the wall |
| Corrugated roofs | rust 150, 70, 50 / blue 60, 110, 170 / zinc 160, 165, 165 / green 90, 130, 100 | |
| Gold (stupas, finials) | 210, 170, 60 | metallic |
| Lake water | 95, 118, 105 | olive green-grey |
| Taxi plates / private | red 190, 30, 30 / black | |
| YBS bus | yellow 240, 200, 40 + white | |

Overall feel: warm, slightly washed out, dusty. Saturation comes in small doses (signs, umbrellas, stools, gold) against a grey, dark-green and pale-sky base.

---

## 4. Comparing with the game (4 screenshots, the kit pilot and the generator)

What the screenshots show:
- **Main road** (shot 1): a perfect clean 3+3 carriageway, a lawn median with chunky glossy red/white kerbs, no trees along the road, no poles, no wires, no traffic, no parked cars. A white hotel tower with uniform dark-blue windows. A white stepped wall. Far buildings scattered on bare ground. A saturated deep-blue sky with pink clouds.
- **Park** (shot 2): one savannah-acacia tree on uniform yellow-green ground. A flat bare shore to the water.
- **Residential block** (shot 3): a huge empty field of mottled grass between buildings. Clean walk-up boxes with flat textures. A few corrugated sheds. No walls, no trees, no wires, no ground detail.
- **Aerial** (shot 4): green-grey land with sparse scattered white boxes and red hip roofs. Almost no tree canopy. A blue-grey fog band, and a blue lake.
- **Kit pilot**: six flat-colour types. Candy pastels with no weathering. Laundry as coloured squares. No hoods, grilles or AC on most. Plain white cars. No street layer.
- **Generator** (`details.py`, `green.py`):
  - poles every 96 studs (32 m at the new scale; fine for streets, but the batches give only ONE side and few wires);
  - city trees 46 studs apart (15 m at 3 s/m: fine as spacing, but only on free spots, so the count is low);
  - compound walls only on some plot kinds;
  - vendors only in batch 2;
  - no drains, no parked cars, no ground-material rules, no weathering, no window hoods / AC at street level beyond the 364 kit buildings.

## 5. GAP LIST (ranked by how much each makes the game look fake)

Format: **real** / **game now** / **fix** / **kind**: KIT = reusable prop or kit piece, GEN = generator rule, LOOK = lighting or material setting.

1. **Open grass between buildings**
   - Real: inner townships have under 10% open lawn. The ground is concrete yards, packed earth, gardens under trees, drains and walls.
   - Game: uniform yellow-green "grass" fills every gap (shots 2, 3, 4).
   - Fix: a ground-material pass per plot and block. Inside compounds: 35% concrete (150, 146, 136), 30% packed earth (150, 128, 100), 25% shrub/garden (a dark-green mix), 10% lawn. Street shoulders: dirt and gravel strips 1-3 m. Parks keep lawn. No exposed "field" over 15 × 15 m outside parks, pitches and vacant lots; a vacant lot gets a corrugated-sheet fence (2 m, rust and zinc) and weeds.
   - Kind: GEN (terrain / ground paint) + KIT (dirt and gravel decals).
2. **Tree canopy far too thin, wrong species shape**
   - Real: 55-65% canopy in the residential townships; rain trees 15-25 m tall with 18-30 m crowns; 4-10 big trees per 100 m of street side.
   - Game: sparse small flat acacias, about 1 per 15-30 m only where free.
   - Fix:
     - A tree kit of 6 species, each in 3 sizes: **rain tree** (domed umbrella crown 20-30 m wide, dark 60, 90, 45; trunk 1 m, forks low), **padauk** (rounded 12-15 m, lighter green, yellow-bloom variant), **mango** (dense dark oval 8-12 m), **tamarind** (feathery 10-15 m), **coconut palm** (15-20 m, leaning 5-15°), **ashoka** (narrow column 8-12 m).
     - Rules: along every street side, one big tree per 10-20 m wherever there is a yard or pavement (no lane, no door). Each compound plot gets 2-6 trees (1 per 150 m² of yard). Aim for 55% canopy in residential batches.
     - Optional 1 m white or red-white trunk band on main-road trees (40%).
   - Kind: KIT + GEN.
3. **No overhead wires on main roads, and too few on streets**
   - Real: grey concrete poles 9-11 m every 30-40 m with 2 cross-arms, 6-15 black cables (30-80 downtown), cable coils, a transformer about every 200 m, service drops to every house.
   - Game: none in shot 1; the generator has poles on one side with a few Beams.
   - Fix:
     - KIT pole family: plain, plus lamp arm, plus transformer platform, plus coils; banded base (1.5 m black/white or red/white).
     - GEN: every 32 m (96 studs) on one side of every road, both sides downtown (every 22 m). Wires: 6 lines (main), 10 (street), 40 (downtown) as Beams with 3-5% sag. One drop line per building to its facade at 4-6 m.
   - Kind: KIT + GEN.
4. **Empty land between buildings: density too low**
   - Real: 45-65% built in townships, continuous rows downtown, gaps 0-3 m.
   - Game: scattered boxes on open ground (shots 3, 4).
   - Fix: infill to the measured cover (the `density.md` design). Walk-up rows set 0-1 m apart in runs of 50-200 m alternating with walled compounds; downtown 100% frontage.
   - Kind: GEN.
5. **Clean, unweathered facades**
   - Real: black mildew streaks under every sill and ledge; 30-70% of old facades darkened; faded paint.
   - Game: clean flat textures and pastel kit.
   - Fix: atlas rule. Every facade texture row gets a streak layer: vertical streaks 0.3-1.5 m wide hanging 1-4 m below each ledge, darkness by building age (new 0-10%, 1990s 30%, 1960s 60%), and a 0.5-1 m darker band at street level (splash and dust). Keep 2-3 clean "new" buildings per block.
   - Kind: KIT (atlas) + GEN (age per plot).
6. **Compound walls and gates missing**
   - Real: 1.8-2.5 m walls with pillars every 3-4 m along 80-100% of every non-shop frontage; gates every 20-40 m; razor wire, glass or spikes on 30%; monastery walls with gold finials.
   - Game: none in the screenshots; the generator walls only some plot kinds.
   - Fix: wall on EVERY non-shop plot's street side.
     - KIT wall set (plain, lattice panel, railing on plinth, monastery with finials) in white, cream, mint, pale blue.
     - Gates (steel sliding / hinged, green, maroon or black, 3-5 m).
     - Toppers (razor coil, spikes) on 30%.
     - Painted ad patches (paint brands) on 20% of long walls.
   - Kind: KIT + GEN.
7. **Sky and haze too saturated and blue**
   - Real: dry-season midday zenith (150, 185, 220), a near-white band at the horizon, a warm dusty light; monsoon flat bright grey-white cloud.
   - Game: deep cobalt with pink clouds; a blue fog over the aerial.
   - Fix: Atmosphere colour (220, 222, 215), haze 1.5-2.5, decay warm (210, 200, 180), density 0.3-0.35; cloud cover 0.4-0.6, white clouds (no pink at midday); sky-box tint pale.
   - Kind: LOOK (`DayCycle.YANGON_DAY`).
8. **No parked cars, no traffic mix**
   - Real: 15-18 parked cars per 100 m per side downtown, 4-10 in the townships, cars nose-in on forecourts; 75% white or silver; taxis with roof signs and red plates; blue mini-pickups; yellow YBS buses.
   - Game: none.
   - Fix: client-side parked cars from `TrafficModels` (anchored, no lamps).
     - Colour table: white 55%, silver 20%, black 8%, grey 7%, other 10%.
     - 30% of sedans and wagons get the taxi kit: a roof box (0.5 × 0.25 × 0.15 m, white with black TAXI) and red plates.
     - KIT: mini-pickup with canopy (blue or white, 3.4 m), YBS bus skin (yellow and white).
     - GEN: parking spots along kerbs per area type.
   - Kind: KIT + GEN.
9. **Window hoods, grilles, AC, laundry, dishes, tanks missing or too clean**
   - Real (walk-ups):
     - a grille or balcony cage on 90% of windows;
     - corrugated hood awnings on 50-80% (blue 60, 110, 170 / green / red, 0.6 m deep, sloped 20°);
     - AC on 1 in 2 windows (newer) or 1 in 4 (older);
     - laundry on 1 in 3 balconies;
     - 1-10 dishes per facade (blue, white, grey; 0.6-1.8 m);
     - roofs: 1-3 black or blue water tanks (Ø 1.1 m), TV aerials, rooftop sheds.
   - Game: the kit pilot has some; the mesh mass buildings have none.
   - Fix: KIT facade-detail modules (hood, cage, AC, dish, laundry line, tank) placed by GEN from window spots, with those shares.
   - Kind: KIT + GEN.
10. **Signboards too sparse and too tidy**
    - Real: downtown 15-40 boards per 100 m (stacked, projecting, on poles); township 6-15; sizes 2-6 × 0.6-1.2 m; red, white, blue, green, yellow backgrounds; Burmese text big and English small; LED scrollers (red); cloth banners across the street every 100-200 m downtown.
    - Game: one sign per kit building; none on the mesh buildings.
    - Fix: KIT sign set (wall board, projecting board, pole-mounted stack of 2-4, LED scroller, cross-street banner on two ropes), using `burmese_words.json` text. GEN: 1-3 per shop frontage, stacks at corners.
    - Kind: KIT + GEN.
11. **Pavements and edges too perfect**
    - Real: concrete slabs with joints, cracks, 1 in 10-20 broken; drain-slab rows; dirt shoulders where there is no kerb; shop plinths 15-40 cm with steps; puddles.
    - Game: smooth uniform pavement on every road; streets are kerbed like boulevards.
    - Fix:
      - Township streets and lanes: no raised kerb. Asphalt goes to a 0.6-1 m slab-covered drain (KIT drain slab 0.5 × 1 × 0.12 m, grey 140; 5% missing showing a dark channel) or to a dirt shoulder.
      - Main roads keep raised kerbs. Add a crack and patch decal layer.
      - Shop fronts get a raised plinth step.
    - Kind: GEN (road cross-section per class) + KIT.
12. **Main-road median looks like a golf green**
    - Real: hedges, crotons, bougainvillea, small palms, lamp posts or barrier blocks in a line; on many stretches a narrow concrete median with orange or red-white blocks.
    - Game: a perfect lawn with oversized glossy kerbs.
    - Fix:
      - Median infill: low hedge (0.6-1 m, dark green) with flowering patches (magenta, red-leaf croton) every 3-6 m, a lamp post every 35 m on medians over 2 m.
      - Narrow medians: concrete with a block line.
      - Kerb: matte material, 20-25 cm, dirtier white.
    - Kind: GEN + KIT.
13. **No street life: tea shops, stalls, umbrellas, trishaws**
    - Real: downtown 4-12 stalls per 100 m, township 1-2; a tea shop every 150-300 m with 6-20 teal or green low tables and 30-60 stools (teal, green, red, pink; 30 cm) under a tree or tarp; trishaws at corners.
    - Game: only in some batches.
    - Fix: GEN rule for all batches, with the area-type densities above. KIT: umbrella (3 patterns), cart, stool and table cluster, cooler box, blue pop-up canopy.
    - Kind: KIT + GEN.
14. **Asphalt too uniform and dark**
    - Real: warm grey 105-120 with darker patches every 30-60 m, oil stripes down the lanes, dust at the edges.
    - Game: a clean dark asphalt slab.
    - Fix: a patch and stain decal set on the road meshes (patch rectangles 2-6 m, 1 per 40 m per lane), an edge-dust gradient 0.5-1 m. Optional: lift Yangon asphalt to 100-110 (owner's call, noted 13 Nov).
    - Kind: KIT (decals) + LOOK.
15. **Roofs wrong**
    - Real (aerial): corrugated metal in rust red, blue, zinc grey and green on houses and sheds; flat concrete roofs with tanks and sheds on walk-ups; green construction mesh on 1 in 10 towers.
    - Game: neat red hip roofs and plain white flat tops.
    - Fix: corrugated roof material set in 4 colours with rust variation; pitched houses 70% corrugated / 30% tile; flat roofs get clutter (tanks, a stair hut, aerials).
    - Kind: KIT + GEN.
16. **Lakeshores bare**
    - Real: an Inya embankment walkway with lamps every 25-30 m, pavilion benches every 40-60 m, planters, sailing boats; the Kandawgyi teak boardwalk on piles; lily pads; olive water.
    - Game: flat grass to the water.
    - Fix: a GEN shore profile per lake (Inya: 2-3 m bank with a 3.5 m path on top; Kandawgyi: boardwalk 2.5 m wide, 1.2 m up, piles every 3.5 m) plus a KIT (pavilion bench, twin lamp, planter ring, dinghy, lily-pad clusters 3-8 m covering 10-30% of the water within 15 m of shore). Water colour (95, 118, 105).
    - Kind: KIT + GEN + LOOK.
17. **Pagodas and monasteries too rare**
    - Real: a gold spire or monastery roof visible every 300-600 m; 1-3 small stupas per km².
    - Game: only OSM-tagged worship points.
    - Fix: extra small stupas in monastery compounds and at junction shrines to reach 1-3 per km²; wall finials on monastery walls; a yellow-cloth "renovation" variant on 10%.
    - Kind: GEN + KIT.
18. **Billboards missing**
    - Real: 0.5-2 per 100 m at main-road junctions; 10 × 4 m on columns 8-12 m up; rooftop frames on 1 in 10 mid-rise roofs.
    - Game: none.
    - Fix: KIT billboard (single and double column, rooftop frame) with made-up adverts (no real brands). GEN: at every main junction and roundabout arm.
    - Kind: KIT + GEN.
19. **Bus stops and the YBS look**
    - Real: white steel shelters with ad panels, a yellow kerb at the bay, rows of 3-4 shelters at big stops.
    - Game: generic shelters.
    - Fix: a KIT YBS shelter (3.2 m roof, glass back, 2 lit panels) plus yellow kerb paint for 25 m; buses in the yellow livery.
    - Kind: KIT.
20. **No people, monks or dogs in Yangon**
    - Real: 3-60 pedestrians per 100 m; longyi on about 60% of men; monks in maroon (morning); 1-3 dogs per 100 m in the lanes.
    - Game: no pedestrians in Yangon (`Pedestrians.lua` is Riviera-only).
    - Fix: switch the pedestrian paths to Yangon pavements; a clothing set (longyi checks, htamein, white shirts, monk robes); KIT dog (lying and walking).
    - Kind: GEN (code) + KIT.
21. **Kerb blocks too big and too clean**
    - Real: 20-30 cm tall, bands 1 m, matte, grimy, chipped.
    - Game: oversized glossy blocks (shot 1).
    - Fix: kerb 0.25 m high × 0.3 m wide at 3 s/m (0.75 × 0.9 studs), matte (SmoothPlastic, no reflectance), white (215, 210, 200), red (175, 50, 45), with a dirt gradient on 30%.
    - Kind: GEN (road builder palette).
22. **Rubbish and litter absent**
    - Real: 5-30 litter clumps per 100 m (white plastic bags, bottles), heaps at pole bases, leaves and padauk petals in the gutters.
    - Game: none.
    - Fix: KIT litter decals and 3 small mesh heaps; GEN 1 clump per 5-20 m by area type, extra at pole bases and drains.
    - Kind: KIT + GEN.
23. **Construction and repair everywhere**
    - Real: green scaffold mesh on 1 in 10 towers, tower cranes on the skyline (2-6 in view), blue tarps, bamboo scaffolds, orange barrier lines.
    - Game: none.
    - Fix: KIT (mesh-wrapped tower shell, crane, tarp) placed on 5-10% of tall plots.
    - Kind: KIT + GEN.
24. **Night: too few lit signs, no stall lights**
    - Real: white LED street lights (owner's rule); green, red and blue neon and LED shop boards; LED strings; white fluorescent tubes at every stall and tea shop; dark upper floors.
    - Game: lamps only.
    - Fix: signs carry a night Neon face (tag FacadeNight); stalls and tea shops get 1-2 white tube parts (Neon 230, 240, 235) plus a small PointLight on 1 in 3 (budget).
    - Kind: KIT + LOOK.
25. **Flyover underside too clean**
    - Real: a grey soffit with black drain pipes, signals hanging, black-yellow chevron bases, ads on piers, vendors and parked taxis underneath, cross-hatched yellow paint.
    - Game: plain decks.
    - Fix: KIT pier dressing (pipe, chevron base band 1.2 m, ad panel) plus GEN for signals and yellow hatching under each deck.
    - Kind: KIT + GEN.

Also seen (smaller):
- the white stepped "merlon" wall in shot 1 reads Middle-Eastern; Yangon walls have flat or tile copings and gold finials only on religious sites;
- the hotel tower windows are too uniform: real towers show mixed curtains and AC units, and some blinds;
- street-name plates (blue / green, Burmese and English) at every corner;
- traffic police booths (white or blue kiosks) at the big junctions;
- water-pot stands (free drinking water) every 200-400 m in the townships.

---

## 6. Build order suggestion (biggest win first, inside the budget rules)
1. LOOK: sky, haze and water colour (minutes; touches every view).
2. GEN ground materials, then the tree kit and canopy rules (gaps 1-2).
3. Poles and wires everywhere (gap 3).
4. Walls and gates on every non-shop plot (gap 6), then infill density (gap 4).
5. Facade weathering atlas plus the detail modules (gaps 5, 9, 15).
6. Parked cars, signs, street life, litter (gaps 8, 10, 13, 22).
7. Shores, pagodas, billboards, bus stops, flyovers, night (gaps 16-25).

Budget notes:
- Trees, poles and props must be **reused kit meshes** (a few hundred unique assets at most).
- Wires are Beams (0 parts). Litter and cracks are decals and textures, not parts.
- Parked cars and people are client-side and LOD'd (WorldFx `LOD` tag).
- Every count above is per 100 m or per km², so it scales with the batch.

---

## Sources
Photos (all in this folder; licences in `sources.json`): Wikimedia Commons.
- Kabar Aye Pagoda Road, Bahan (2018): `https://commons.wikimedia.org/wiki/File:Yangon_IMG_20180407_095227_kabar_aye_pagoda_road_bahan.jpg`
- Saya San Road (2018): `https://commons.wikimedia.org/wiki/File:Yangon_IMG_20180407_093225_saya_san_road_bahan.jpg`
- Moe Kaung Road, Yankin: `https://commons.wikimedia.org/wiki/File:Moe_Kaung_Road_-_Yankin_yangon_IMG_5099.jpg`
- Pyay Road and the Hanthawaddy Roundabout (aerial): `https://commons.wikimedia.org/wiki/File:Pyay_Road_and_Hantharwaddy_Roundabout.jpg`
- Downtown: `https://commons.wikimedia.org/wiki/File:Typical_downtown_Yangon_street_(8436540489).jpg`, `https://commons.wikimedia.org/wiki/File:Busy_back-streets_of_Yangon_(5089264983).jpg`
- Inya embankment: `https://commons.wikimedia.org/wiki/File:Inya_Lake_embankment.JPG`
- Kandawgyi boardwalk: `https://commons.wikimedia.org/wiki/File:Kandawgyi_Lake_bridge.jpg`
- The full list of 46 is in `sources.json`.

Web:
- Car fleet in Yangon (Probox ~20% of vehicles, taxis, Swift, white Japanese used cars): https://bestsellingcarsblog.com/2014/12/myanmar-2014-photo-reports-the-cars-of-yangon/
- Japanese used-car share (98% second hand, 95% Japanese): https://www.autocarpro.in/news-international/japanese-cars-dominate-myanmar-car-market-report-20807
- Motorbike ban (2003, central townships; enforcement weaker outside): https://www.frontiermyanmar.net/en/yangons-two-wheeled-conundrum/ , https://myanmarmix.com/en/node/3006
- Power grid, tangled cables and concrete poles: https://www.frontiermyanmar.net/en/down-to-the-wires-fixing-yangons-broken-power-grid/ (search summary; page blocked to the fetcher)
- Covered roadside drains, missing slabs: https://myawady-myawady.blogspot.com/2015/05/a-flood-free-rainy-season-for-yangon.html?m=1 ; downtown drains: https://teacircleoxford.com/opinion/broken-roads-and-blocked-drains-the-recurring-samsara-of-yangons-urban-problems/
- YBS (2017, ~4,000 buses, Yutong and Ankai): https://en.wikipedia.org/wiki/Yangon_Bus_Service , https://chinabuses.org/news/2017/0608/article_11112.html
- Yangon trees (rain tree "kokko", padauk; YCDC planting of tamarind, laburnum, crepe myrtle): https://onishingo.blogspot.com/2020/06/8-common-trees-in-yangon-8.html , https://www.irrawaddy.com/lifestyle/trees-glorious-trees.html
- Tea shops and street life (purple and red plastic stools, vendors): https://migrationology.com/41-photos-of-yangon-myanmar
