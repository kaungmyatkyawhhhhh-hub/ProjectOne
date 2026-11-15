# Yangon building kit: reference pack

42 photos from Wikimedia Commons, all openly licensed (CC BY / CC BY-SA 2.0-4.0, CC0). Each file's Commons page, download URL, licence and author are in `sources.json` (key = `<type>/<file>`). CC BY-SA images need credit (author + licence) if they are ever shown in the game or in a video.

How the numbers were made: measured on the photos against a known size, or (marked "typical") taken from common Yangon building practice where the photos can't show it. Reference sizes used: car about 4.5 m long / 1.5 m tall (minivan 1.9 m), city bus 3.1 m tall / 12 m long, door 2.1 m, person 1.65 m. Expect about plus or minus 10%; perspective makes upper floors read short, so the numbers below are already corrected for that.

Colours are sRGB estimates of the paint as it looks in daylight (not of shadowed pixels). Before using them in Studio, put each one through `city/look_calib.py` (textured materials render much darker than their colour).

---

## 1. Downtown colonial shophouse rows (Pansodan / Mahabandoola / 19th-50th streets)

**Photos** (`downtown_shophouse/`): `pansodan_row.jpg` (a row of 4-5 storey fronts on Pansodan, cars for scale), `merchant_rd_corner.jpg` (ochre corner block, shops under), `pansodan_corner_5storey.jpg` (5-storey corner with a domed corner), `pansodan_pink_corner.jpg` (pink arcaded corner with clock), `26th_street_01.jpg` / `26th_street_02.jpg` (ordinary side street: balconies, grilles, awnings, wires), `26th_street_facade_detail.jpg` (turquoise front: arched windows, louvred shutters, AC), `aqua_balconies.jpg` (stacked balustraded balconies).

| Item | Value (m) | How |
|---|---|---|
| Ground floor (floor to floor) | 4.5-5.5 (main roads), 3.8-4.5 (side streets) | `pansodan_row`: the 1.9 m minivan vs. street to first cornice |
| Upper floors | 3.6-4.2 (1st and 2nd), 3.2-3.6 (top) | same photo, corrected for perspective |
| Facade bay (window pitch) | 1.8-2.4; a plot front is 2-4 bays | `pansodan_row`, `26th_street_facade_detail` |
| Windows | 1.0-1.3 wide x 2.2-2.8 tall, round or segmental arch on top; many are French doors to the floor | door 2.1 m in `26th_street_facade_detail` |
| Window sill | 0.0 (French door onto a balcony) or 0.8-0.9 | same |
| Balcony depth | 0.9-1.5 (balustraded, on brackets) | `26th_street_02`: Honda Fit 4.0 m |
| Arcade / "five-foot way" | 2.5-3.5 deep, 4-5 tall (main roads and corners only) | `pansodan_pink_corner` |
| Parapet | 1.0-1.5 with a heavy cornice; corners get pediments, turrets, domes | `pansodan_row` |
| Plot | 6-8 wide x 20-30 deep, a back lane behind (typical: the downtown grid's long thin lots) | |
| Height | 3-5 storeys, 15-23 m to the parapet | |

**Roof and clutter:** hidden pitched roofs of rusty red or grey corrugated iron behind the parapet (`pansodan_row` shows one); satellite dishes on the parapet, black plastic water tanks, aerials, plants growing out of cornices, drainpipes in sky-blue plastic down the front.

**Colours (sRGB):** cream 235, 222, 195; ochre / mustard 205, 165, 90; mint and turquoise 140, 200, 180 / 90, 185, 185; pale pink 225, 170, 170; brick red (court-style) 160, 60, 50; fresh white 235, 235, 230. Almost every one is streaked: black mould stains 60-90 grey running down from every ledge and cornice.

**Materials:** lime render over brick, painted; teak louvred shutters and doors (brown 110, 70, 40 or painted green / blue); cast-iron or concrete balustrades; steel roller shutters on the shops.

**Signage:** small to medium shop boards over each shop (Burmese script, red / yellow / blue), striped or plain awnings at 2.4-3 m, blue plastic awnings on the upper floors. Fewer and smaller than in the townships.

**What makes it Yangon:** the decay. Grand British-era fronts (pilasters, arches, cornices) under black rain stains, missing paint, plants in the cracks, AC units and dishes bolted on anywhere, laundry on the balconies, and dense overhead wires crossing the street at 5-8 m.

**Must-have details**
- Black streak texture under every ledge (most important single detail).
- Arched tall windows with louvred teak shutters, some open at angles.
- Projecting balustraded balconies on brackets.
- Cornice + parapet line, corner pediment / turret on corner plots.
- Ground floor: roller shutters and shop openings, small awnings.
- AC units, satellite dishes, laundry, blue drainpipes.
- Wires strung across the street.

---

## 2. 1960s-90s concrete walk-up apartment blocks (4-8 storeys)

**Photos** (`walkup_apartment/`): `anawrahta_block_01.jpg` (two 6-7 storey blocks over shops, a bus for scale: the key reference), `mahabandula_block_cages.jpg` (front of stacked balconies, cages, dishes on the roof line), `30th_street_blocks.jpg`, `47th_street_blocks.jpg` (street walls of blocks), `block_shopfronts_grilles.jpg` (yellow / green block, grilles, shop signs), `balcony_grilles_grime.jpg` (slatted concrete balconies, grime close up), `yankin_5storey_blocks.jpg` (suburban 5-storey blocks with shops), `roofscape_from_sakura.jpg` (from above: roofs, tanks, sheds).

| Item | Value (m) | How |
|---|---|---|
| Ground floor | 3.6-4.2 (shops) | `anawrahta_block_01`: bus 3.1 m tall |
| Upper floors | 2.9-3.1 | same, floor lines on the right block |
| Facade bay | 3.0-3.6 (one room or one balcony) | same; block fronts are 3-6 bays |
| Windows | 1.2-1.8 wide x 1.2-1.4 tall; louvred glass (jalousie) or steel casements | |
| Window sill | 0.9-1.0 | |
| Balcony depth | 1.0-1.5 | `anawrahta_block_01`, `balcony_grilles_grime` |
| Cage / grille | 0.3-0.8 beyond the wall or balcony edge; full height of the storey | `mahabandula_block_cages` |
| Parapet | 0.6-1.0, plain | |
| Plot / block | 7.5-15 wide (one or two downtown lots) x 20-30 deep downtown; free-standing estate blocks 12-18 x 30-60 | |
| Height | 4-8 storeys (walk-up), 15-28 m | |

**Roof and clutter:** flat concrete. Black or blue plastic water tanks (1-2 m3: 1.1-1.4 m across, 1.2-1.7 m tall) on steel stands; big old mesh satellite dishes 1.5-2.4 m across on poles (very Yangon, see `anawrahta_block_01`); TV aerials; corrugated sheds and lean-to covers; drying lines.

**Colours (sRGB):** stained white 200, 198, 190 (in shade far greyer); beige tile 195, 180, 150; pale green 170, 200, 170; sky blue 160, 200, 225; butter yellow 225, 205, 140. Each flat paints its own balcony, so one block shows 3-5 colours.

**Materials:** concrete frame, rendered and painted; small mosaic tiles on some fronts; steel window grilles and balcony cages (white, green or rust); concrete slat / breeze-block screens; plastic and canvas sun shades.

**Signage:** a full row of shop signboards along the ground floor (1-1.5 m tall, bright red / yellow / green, Burmese text); big vinyl banners hung on the balcony rails of the 1st-2nd floors; vertical boards on the corners.

**What makes it Yangon:** each flat customises its own balcony (cage, tarp, plants, laundry, a different paint), so the grid of the block is broken into a patchwork; the rooftop dishes and tanks; the rain stains; shops under every block.

**Must-have details**
- Balcony grid where every bay is different (open rail / cage / tarp / closed in).
- Steel grilles on every window up to the top floor.
- Hanging laundry and green shade nets.
- AC units on brackets, dishes at odd angles.
- Rooftop tanks on stands and large mesh dishes.
- Ground floor shop band with signboards.
- Mould streaks and patchy repainting.

---

## 3. Township street shophouses with signboards (Hledan / Kamayut / Yankin, 2-4 storeys)

Commons has few Hledan photos (most are 2021 protest pictures with crowds), so this set uses the same building type from Kamayut, Yankin and downtown.

**Photos** (`township_shophouse/`): `kamayut_street.jpg` (a Kamayut road with shophouses and signs), `yankin_3storey_shop.jpg` (3-storey shophouse, pale blue, grilles, telecom lightbox, shop board: the key reference), `yankin_shop_signs.jpg` (2-4 storey shops on Moe Kaung Road), `poe_computer_signboards.jpg` (signboards stacked up an older block), `mahabandula_signboards.jpg` (red / yellow boards and umbrellas), `open_shopfront.jpg` (ground-floor shop with its front fully open).

| Item | Value (m) | How |
|---|---|---|
| Ground floor | 3.3-3.8 | `yankin_3storey_shop`: shop door 2.1 m |
| Upper floors | 3.0-3.3 | same |
| Facade bay | 4-6 (the whole front is often one bay) | same |
| Windows | 1.2-2.0 wide x 1.2-1.5 tall, aluminium sliding, always with steel grilles | |
| Window sill | 0.9 | |
| Balcony depth | 0.6-1.2 (small, often caged), or none | |
| Shop awning / canopy | 1.0-1.5 deep at 2.4-2.8 high | `yankin_3storey_shop` |
| Parapet | 0.5-1.0, or none under a low pitched roof | |
| Plot | 4.5-6 wide x 15-25 deep (row) or 8-12 wide (detached) | |
| Height | 2-4 storeys, 7-14 m | |

**Roof and clutter:** low pitched corrugated metal (blue, red, green; 10-20 degrees) behind a short parapet or with an exposed fascia; or flat with a water tank and a dish; rooftop extensions in corrugated sheet.

**Colours (sRGB):** pale blue 190, 215, 235; light grey cladding 190, 192, 195; white 230, 230, 225; pastel pink 225, 185, 175; cream 230, 215, 180; red accents 200, 40, 40.

**Materials:** rendered brick / concrete, ACP cladding panels on newer fronts, aluminium windows, steel grilles, roller shutters, corrugated metal, some timber neighbours.

**Signage:** dense and colourful: a full-width fascia board over the shop (0.8-1.2 m tall), vertical boards (0.6-0.8 wide x 1.5-2.5 tall) on the pillars, telecom lightboxes (shield / rounded shapes) sticking out at 2.5-4 m, banners on upper floors. Red and yellow dominate, Burmese script in white or black. Use made-up names only.

**What makes it Yangon:** a mix of small owner-built houses side by side (each a different height and colour), grilles everywhere, signs of different sizes at different heights, and a mobile shop cart or tea stall in front.

**Must-have details**
- Full-width fascia sign + vertical pillar signs + one projecting lightbox.
- Window grilles on every floor.
- Neighbours of different heights (break the street line by 1-2 storeys).
- Pitched coloured metal roof edge visible on some.
- Open shop fronts with goods hanging out, roller shutters on closed ones.
- Compound wall with diamond lattice openings between buildings.

---

## 4. Detached houses and small villas (Bahan / Golden Valley / Kamayut / Yankin, 1-3 storeys)

**Photos** (`villa/`): `yankin_villa_gate.jpg` (2-storey white villa, portico, balustrades, gate with pillars, razor wire: the key reference), `university_ave_compound_gate.jpg` (compound wall and gate, trees), `colonial_timber_villa.jpg` (old teak villa with verandas and fretwork), `yankin_timber_house.jpg` (2-storey teak house), `yankin_house_gate.jpg` (house behind a metal gate), `small_house_dagon.jpg` (small 1-storey house under trees), `ahlone_hipped_roofs_aerial.jpg` (from above: red hipped roofs among trees).

| Item | Value (m) | How |
|---|---|---|
| Ground floor | 3.3-3.8; plinth raised 0.5-0.9 above the yard | `yankin_villa_gate`: gate leaf about 2.3 m |
| Upper floors | 3.2-3.6 | same |
| Facade bay | 3.5-4.5 | same |
| Windows | 1.2-1.5 wide x 1.5-1.8 tall, teak frames, with grilles | |
| Window sill | 0.8-0.9 | |
| Balcony / veranda depth | 1.5-3.0 (veranda), 1.0-1.5 (balcony) | |
| Eaves overhang | 0.8-1.2 | |
| Parapet | none (hipped roof); modern boxes 0.6-0.9 | |
| Compound wall | 1.8-2.4 tall, 0.2-0.25 thick, pillars every 3-4 m, often with spikes, glass or razor wire on top | `yankin_villa_gate`, `university_ave_compound_gate` |
| Gate | 4-6 wide, 2.2-2.6 tall, pillars 0.5-0.7 square, 2.6-3.0 tall with lamps | `yankin_villa_gate` |
| Plot | Bahan / Golden Valley 25-45 wide x 35-60 deep (0.25-0.6 acre); Kamayut / Yankin 15-25 x 25-35 (typical) | `ahlone_hipped_roofs_aerial` for density |
| Setback | 3-8 to the house; trees in the yard | |
| Height | 1-3 storeys, 5-12 m to the ridge | |

**Roof and clutter:** hipped roofs at 25-35 degrees (red clay-colour or green / blue metal sheet, some clay tile), gables with fretwork bargeboards on old teak houses; few roof items: a water tank on a tower in the yard, a dish, solar heater on some.

**Colours (sRGB):** white 240, 238, 230; cream 235, 225, 200; teak brown 120, 75, 40; roof red 165, 65, 45; roof green 60, 110, 80; gates dark green 30, 70, 55 or black with gold details 190, 150, 70.

**Materials:** rendered brick (white / cream), teak (doors, windows, whole older houses), metal roof sheet, cast concrete balustrades, wrought-iron gates.

**Signage:** almost none: a small house number plate on the gate pillar; sometimes a company board for offices in villas.

**What makes it Yangon:** you see the wall and gate first, the house second. Tall wall, big dark gate, lamp-topped pillars, razor wire, mango / palm / rain trees over the wall; Western "palace" columns on new villas next to old teak houses.

**Must-have details**
- Compound wall with pillars + gate as the street-facing piece (a separate kit part).
- Hipped roof with deep eaves.
- Teak window frames with grilles.
- Balustraded balcony or veranda.
- Trees behind the wall (palms, big shade trees).
- Optional: classical portico columns (new money), or teak fretwork (old).

---

## 5. Modern condo towers (10-25 storeys)

**Photos** (`condo_tower/`): `yankin_tower_construction.jpg` (blue-glass tower with a podium being finished: the key reference), `skyline_modern.jpg` (towers over a white block), `view_junction_city.jpg` (towers on Bogyoke Road from above), `olympic_tower_view.jpg` (the city from the 15th floor: tower roofs and mid-rise), `kyimyindaing_skyline.jpg` (towers on the west side), `red_hill_towers.jpg` (towers at the Red Hill flyover).

| Item | Value (m) | How |
|---|---|---|
| Podium floors | 4.0-4.5 (1-3 floors: shops, parking) | `yankin_tower_construction`: cars 4.5 m |
| Typical floor | 3.0-3.2 | same, floor lines counted |
| Facade bay | 3.5-4.2 | |
| Windows | strip glazing 1.5-3.0 wide x 1.8-2.1, sill 0.6-0.9; or full curtain wall | |
| Balcony depth | 1.2-1.8, glass or steel rail; AC ledges 0.6-0.8 with louvred screens | |
| Parapet | 1.1-1.5, often a tall crown frame 3-8 m | |
| Plot | 40-80 x 50-100 (0.5-1.5 acres) with a podium; tower footprint 25-35 x 30-50 | |
| Height | 10-25 storeys, 35-80 m (height limits near Shwedagon keep most under about 25 storeys) | |

**Roof and clutter:** flat roof with the lift overrun and stair cores, a decorative crown frame or curved fin, water tanks, telecom masts on some, building name in big letters near the top.

**Colours (sRGB):** blue / teal glass 70, 120, 160 and 60, 140, 140; white paint 235, 235, 232; cream 230, 215, 185; pale salmon 225, 170, 140 (`downtown_market_lane` background tower); grey 150, 155, 160.

**Materials:** concrete frame, rendered and painted, tinted glass bands, aluminium cladding, glass or steel balcony rails.

**Signage:** building name across the crown or podium; podium shop and bank signs; billboards on the podium roof.

**What makes it Yangon:** a white or pastel painted concrete tower with blue or green glass stripes up its middle, standing among low decaying blocks; AC units still on every ledge; laundry on some balconies even in new towers.

**Must-have details**
- Vertical glass strip (blue / green) up the middle or corners.
- Podium of 1-3 taller floors.
- Repeating balconies with AC ledges.
- Crown frame or fin on top.
- Building name lettering (made-up names).

---

## 6. Low sheds, markets and halls

**Photos** (`market_shed/`): `downtown_market_lane.jpg` (a long market hall with rusty corrugated roof and a 2-storey market on the other side, crowd for scale: the key reference), `theingyi_market.jpg` (Theingyi market front on Bandoola Road), `sanpya_market.jpg` (Sanpya fish market sheds, umbrellas), `samanea_market_hall.jpg` (modern steel-canopy market), `suburb_teashop_shed.jpg` (roadside tea-shop shed), `strand_market_stalls.jpg` (stalls and a canopy on Strand Road), `okkalapa_station_shed.jpg` (low station / platform shed).

| Item | Value (m) | How |
|---|---|---|
| Market hall, 1 storey | eaves 4-6, ridge 7-9 | `downtown_market_lane`: people 1.65 m |
| 2-storey market | floors 4.0-4.5 | same (right side) |
| Bay (column / truss pitch) | 3-4.5; stalls 2 x 2 to 3 x 3 | |
| High windows / vents | small arched vents 0.6 x 1.2 in a row at 3-4 m | `downtown_market_lane` |
| Awning / tarp | 1.5-3 deep at 2.2-2.6 | same |
| Tea-shop / small shed | eaves 2.4-3.0, ridge 3.5-4 | `suburb_teashop_shed` |
| Parapet | none (exposed eaves); old halls have a rendered gable / pediment end | |
| Plot | halls 15-40 wide x 40-150 long; small sheds 5-10 x 6-12 | |

**Roof:** gable or monitor (raised ridge vent) roofs of corrugated iron at 15-25 degrees, rusty red-brown or faded grey; patched sheets; tarps and blue / green plastic awnings below the eaves; big umbrellas in the open lanes.

**Colours (sRGB):** rusty roof 140, 80, 60; faded grey roof 150, 150, 145; whitewash walls 225, 220, 205; cream 230, 215, 180; tarp blue 50, 110, 180; tarp green 60, 140, 80; plastic stool red 210, 40, 40.

**Materials:** corrugated galvanised iron, steel or timber trusses, whitewashed brick ends, concrete floors, plastic tarps, bamboo.

**Signage:** a few boards at the entrances (market name in Burmese), stall boards hung under the eaves, plastic banners.

**What makes it Yangon:** rusty corrugated roofs everywhere (they dominate the view from above: `walkup_apartment/roofscape_from_sakura.jpg`), stalls spilling out under tarps onto the road, low plastic stools and tables.

**Must-have details**
- Rusty corrugated roof with patched sheets (texture + colour variation).
- Deep low awnings / tarps along the long sides.
- Row of small vents high in the end walls.
- Stalls, umbrellas, low plastic stools in front.

---

## Key numbers (summary)

| Type | Ground floor | Upper floor | Bay | Window w x h / sill | Balcony / cage | Parapet | Plot w x d | Storeys |
|---|---|---|---|---|---|---|---|---|
| 1 Downtown colonial | 4.5-5.5 | 3.6-4.2 | 1.8-2.4 | 1.1 x 2.5 / 0-0.9 | 0.9-1.5 | 1.0-1.5 | 6-8 x 20-30 | 3-5 |
| 2 Walk-up block | 3.6-4.2 | 2.9-3.1 | 3.0-3.6 | 1.5 x 1.3 / 0.9 | 1.0-1.5 (+0.3-0.8 cage) | 0.6-1.0 | 7.5-15 x 20-30 | 4-8 |
| 3 Township shophouse | 3.3-3.8 | 3.0-3.3 | 4-6 | 1.5 x 1.3 / 0.9 | 0.6-1.2 | 0.5-1.0 | 4.5-6 x 15-25 | 2-4 |
| 4 Villa | 3.3-3.8 (+0.5-0.9 plinth) | 3.2-3.6 | 3.5-4.5 | 1.3 x 1.6 / 0.85 | 1.0-3.0 veranda | none (hipped, eaves 0.8-1.2) | 15-45 x 25-60 | 1-3 |
| 5 Condo tower | 4.0-4.5 podium | 3.0-3.2 | 3.5-4.2 | strip 2 x 2 / 0.75 | 1.2-1.8 | 1.1-1.5 (+crown) | 40-80 x 50-100 | 10-25 |
| 6 Market / shed | eaves 4-6 (sheds 2.4-3) | 4.0-4.5 | 3-4.5 | vents 0.6 x 1.2 | awning 1.5-3 at 2.4 | none | 15-40 x 40-150 | 1-2 |

Shared street details for every type: overhead wires on concrete poles at 6-9 m, blue plastic drainpipes, AC units, satellite dishes, laundry, grilles, black rain streaks below ledges, plants growing from walls, Burmese-script signs in red / yellow / blue.
