---
tags: [city-legends, research, yangon, interiors, catalogue, blueprint]
created: 2026-11-16
---
# Research - Yangon interiors catalogue (what can be built from real photos)

> Owner's rule: "make interiors of every building interior that u can see on the internet. dont put interior if its not in the internet."
>
> 53 buildings rated:
> - **A (19):** build now.
> - **B (21):** build only the spaces that have photos.
> - **C (12):** stays closed.
>
> 134 open-licence photos sit in `Games/CityLegends/build/landmarks/refs/interiors/<building>/` (local, sources.json each).
>
> **Build order (autopilot):**
> 1. Shwedagon platform and stairways
> 2. Sule
> 3. Bogyoke Market
> 4. Central Station
> 5. Botataung's gold corridor
> 6. Chaukhtatgyi and Ngahtatgyi halls
> 7. Maha Wizaya's chamber
> 8. Synagogue
> 9. St Mary's
> 10. Strand, Sule Shangri-La
>
> then the B spaces. Meliá and Myanmar Plaza are done.


Research date 2026-11-16. Map box: lon 96.095-96.235, lat 16.75-16.89.

Owner rule: build an interior only if real photos of it exist online. No photos = no interior (closed doors, dark glass or shutters only).

How to read this:
- **Rating.** A = many good photos, buildable now. B = some photos, build only the spaces that have photos. C = almost none, do not build.
- **Open photos (downloaded).** Openly licensed Wikimedia Commons files are saved in `refs/interiors/<slug>/`, with a `sources.json` (licence, author, page, what the photo shows). Credit the author when you use them. CC BY-SA also means share-alike.
- **Copyrighted photos.** These are links plus a text description only. Use them to look at, not to trace or copy into the game.
- **Coordinates.** All are approximate (about ±100 m). Snap to the OSM footprint before building.
- **Sizes.** Real figures come from the sources. "est." means estimated from photos (people about 1.6 m, doors about 2.1 m).

Already researched elsewhere (not repeated here):
- Meliá Yangon: `refs/melia_interior/melia_interior.md`
- Myanmar Plaza atrium: `refs/mall_interior/` and `refs/melia_interior/`
- Sedona: `refs/sedona/`

---

## 1. Summary table (build order: A first, then by how famous and visible)

| # | Building | Area | In map? | Rating | Spaces with real photos | Open photos here |
|---|---|---|---|---|---|---|
| 1 | Shwedagon Pagoda (platform, stairways, tazaung halls) | Dagon / Bahan | yes | **A** | 4 covered stairways (S stairway with shops, W stairway with escalators), shrine halls (tazaung), Buddha halls, reclining-Buddha hall, bell pavilions, open platform | 23 (`shwedagon/`) |
| 2 | Sule Pagoda | Kyauktada (downtown) | yes | **A** | Inner shrine rooms, carved teak shrine pavilions, glass-mosaic walls and columns, 28-Buddha hall, nat shrine, ring of shops (outside) | 14 (`sule_pagoda/`) |
| 3 | Bogyoke Aung San (Scott) Market | Pabedan | yes | **A** | Central hall (arched steel roof, jewellery stalls), textile aisles, stairwell shops, plan board | 7 (`bogyoke_market/`) |
| 4 | Yangon Central Railway Station | Mingala Taungnyunt | yes | **A** | Ticket hall, lobby/concourse, ticket booths, platforms 1-7 under steel canopies, porte-cochère | 14 (`yangon_central_station/`) |
| 5 | Botataung Pagoda (hollow stupa) | Botataung | yes | **A** (Commons: few) | Zigzag inner corridor in gold leaf and mirror mosaic, relic display cases | 5 (`botataung/`) |
| 6 | Chaukhtatgyi reclining Buddha | Bahan | yes | **A** (Commons: few whole views) | Steel-roof hall around a 66 m reclining Buddha, glass-mosaic plinth, niche walls, painted soles | 6 (`chaukhtatgyi/`) |
| 7 | Ngahtatgyi seated Buddha (the "Kyauk Htat Gyi" pair's partner) | Bahan | yes | **A** | Steel-truss hall, 14 m seated Buddha, carved teak backdrop, red floor | 11 (`ngahtatgyi/`) |
| 8 | Maha Wizaya Pagoda (hollow) | Dagon | yes | **A** | Round inner chamber: forest-painted walls, blue domed ceiling with animals, relic shrine | 6 (`maha_wizaya/`) |
| 9 | Musmeah Yeshua Synagogue | Pabedan (26th St) | yes | **A** | Sanctuary with central bimah, ark wall, women's gallery, benches, chandeliers | 12 (`musmeah_yeshua_synagogue/`) |
| 10 | St Mary's Cathedral | Botataung | yes | **A** | Nave with painted brick vaults, choir, pulpit, side chapels | 5 (`st_marys_cathedral/`) |
| 11 | The Strand Hotel | Kyauktada | yes | **A** | Lobby, lobby lounge, Sarkies Bar, café, corridors (official gallery + 2 Commons) | 2 (`strand_hotel/`) |
| 12 | Sule Shangri-La | Kyauktada | yes | **A** | Colonial-style lobby with grand staircase and balcony, lobby lounge with tiered chandelier, Gallery Bar, ballroom, room corridor | 1 (`sule_shangri_la/`) |
| 13 | Kheng Hock Keong Chinese temple | Latha | yes | **A** | Main hall, altars, dragon columns, lanterns | 9 (`kheng_hock_keong/`) |
| 14 | Meliá Yangon (done, see its file) | Bahan | yes | **A** | Lobby, bar, restaurants | in `melia_interior/` |
| 15 | Myanmar Plaza (done) | Bahan | yes | **A** | Atrium, escalators, shop corridors | in `mall_interior/` |
| 16 | Pan Pacific Yangon (in Junction City) | Pabedan | yes | **A** (official only) | 6th-floor double-height sky lobby, restaurants, pool | 0 |
| 17 | Chatrium Hotel Royal Lake | Tamwe / Bahan | yes | **A** (official only) | Lobby with gold-inlay feature wall, lobby lounge, Grand Ballroom | 0 |
| 18 | Lotte Hotel Yangon | Hlaing (Inya Lake W shore) | yes | **A** (official only) | Lobby with big chandelier and full-height lake windows, lounge, restaurants | 0 |
| 19 | Rosewood Yangon (ex New Law Courts, 1927) | Kyauktada | yes | **A** (official/press only) | Portico, lobby with mural, Ionic colonnade, teak stair rails, restaurants | 0 |
| 20 | The Secretariat (Ministers' Building) | Botataung | yes | **B** | Arcaded red-brick corridors, spiral/double staircase, skylight, parliament hall, Aung San's office | 5 (`secretariat/`) |
| 21 | Junction City mall | Pabedan | yes | **B** | Shop galleries, top-floor food court and cinema (social media / reviews only) | 0 |
| 22 | Junction Square mall | Kamayut | yes | **B** | Large open event atrium, shop galleries, cinemas | 0 |
| 23 | Kaba Aye Pagoda + Maha Pasana Cave | Mayangon | yes | **B** | Cave assembly hall (220 × 140 ft); pagoda inner sanctum with hollow pillar and silver Buddha | 1 (`kaba_aye_maha_pasana_cave/`) |
| 24 | Karaweik Palace (barge restaurant) | Kandawgyi, Mingala Taungnyunt | yes | **B** | Buffet dining halls, show stage, carved panels (booking/TripAdvisor photos) | 0 |
| 25 | National Museum | Dagon | yes | **B** | Lion Throne room (others: few, photography restricted) | 0 usable |
| 26 | Inya Lake Hotel | Mayangon | yes | **B** | Lobby hall (2005 photo + booking photos), function halls | 1 (`inya_lake_hotel/`) |
| 27 | Novotel Yangon Max | Kamayut | yes | **B** | Lobby, restaurants (booking sites) | 0 |
| 28 | Rose Garden Hotel | Mingala Taungnyunt | yes | **B** | Lobby lounge, staircase (booking sites) | 0 |
| 29 | PARKROYAL Yangon | Mingala Taungnyunt | yes | **B** | Tall lobby with columns, staircase, fountain (booking sites) | 0 |
| 30 | Mogul Shiah Mosque | Kyauktada (30th St) | yes | **B** | Prayer hall: white arches, chandeliers, blue patterned carpet | 3 (`mogul_shiah_mosque/`) |
| 31 | Bahadur Shah Zafar Dargah | Dagon | yes | **B** | Prayer hall (pink walls), tomb chambers | 5 (`bahadur_shah_zafar_dargah/`) |
| 32 | Armenian Church of St John the Baptist | Kyauktada | yes | **B** | Nave with timber trusses, altar | 3 (`armenian_church/`) |
| 33 | University of Yangon Convocation Hall | Kamayut | yes | **B** | Auditorium seating, gallery | 1 (`yangon_university_convocation_hall/`) |
| 34 | Bogyoke Aung San Museum | Bahan | yes | **B** | Living, dining and reception rooms, bedrooms, library (news photos) | 0 |
| 35 | Thamada Cinema | Mingala Taungnyunt | yes | **B** | Oval auditorium with balcony (Cinema Treasures photos) | 0 |
| 36 | Rangoon Tea House | Kyauktada | yes | **B** | Bright ground-floor tea room, upstairs bar (press photos) | 0 |
| 37 | Lucky Seven tea shop (49th St) | Pazundaung / Botataung | yes | **B** | Wooden tables, plant-covered terrace | 0 |
| 38 | Thiri Mingalar market | Hlaing / Kamayut | yes | **B** | Fruit hall on ground floor, banana yard (blog photos) | 0 |
| 39 | Circle-line stations (e.g. Pazundaung, Mingaladon outside) | various | partly | **B** | Platforms only | 0 (Flickr set on Commons) |
| 40 | Thuwunna Stadium | Thingangyun | yes | **B** | Seating bowl / stands (football photos) | 0 (on Commons, not downloaded) |
| 41 | Holy Trinity Cathedral | Pabedan | yes | **C** | Almost none (one blog text) | 0 |
| 42 | Yangon City Hall | Kyauktada | yes | **C** | None found (Commons: 56 files, all exterior) | 0 |
| 43 | Surti Sunni Jamah Mosque | Kyauktada | yes | **C** | None found (exterior only) | 0 |
| 44 | Immanuel Baptist Church | Kyauktada | yes | **C** | None found (exterior only) | 0 |
| 45 | Theingyi Market | Pabedan / Latha | yes | **C** | Almost none | 0 |
| 46 | Taw Win Centre | Dagon | yes | **C** | Almost none | 0 |
| 47 | Hledan Centre | Kamayut | yes | **C** | Almost none | 0 |
| 48 | Times City (Times Mall) | Kamayut | yes | **C** | Almost none | 0 |
| 49 | Sule Square mall | Kyauktada | yes | **C** | Almost none | 0 |
| 50 | City Mart / Ocean branches | many | yes | **C** | Generic supermarket photos only | 0 |
| 51 | Myanmar Convention Centre | Mayangon | yes (check) | **C** | Almost none | 0 |
| 52 | Yangon International Airport | Mingaladon | **no** (lat 16.907) | n/a | Outside the map | 0 |
| 53 | Kempinski Yangon (ex State House project) | Kyauktada | yes | **C** | Not opened, no photos | 0 |

---

## 2. Buildings (one section each, same order)

### 1. Shwedagon Pagoda: platform, stairways and halls (A)
- **Where:** lon 96.1496, lat 16.7984 (stupa centre). Inside the map.
- **Facts:** Stupa 99 m (112 m to the tip of the hti). The hill is 51 m high. The plinth is octagonal, with 8 planetary posts; 4 directional shrines (E Kakusandha, S Konagamana, W Kassapa, N Gautama). Pavilions for the Tharrawaddy bell (NE corner) and the Singu bell (NW). Four stairways guarded by chinthe pairs. Vendors line the E and S stairways. The W stairway has escalators; the S stairway has lifts. Sources: [Wikipedia](https://en.wikipedia.org/wiki/Shwedagon_Pagoda), [Lonely Planet](https://www.lonelyplanet.com/pois/1092872), [Sacred Destinations](https://www.sacred-destinations.com/burma/yangon-shwedagon-pagoda), [Asia for Visitors](https://asiaforvisitors.com/burma/yangon/swedagon/).
- **Photos:** Commons category [Shwedagon pagoda interior](https://commons.wikimedia.org/wiki/Category:Shwedagon_pagoda_interior) (150 files) and [Shwedagon pagoda](https://commons.wikimedia.org/wiki/Category:Shwedagon_pagoda) (1,000+). Also countless TripAdvisor and Google Maps photos.
- **Spaces:**
  - **Covered stairways (S and E, with shops):** a long stepped hall. A row of gilded round columns (gold shaft, dark green base, about 0.5 m diameter est.) carries a coffered teak or white-painted ceiling. Bays 3-4 m (est.) with shops on both sides selling Buddha images, flowers, umbrellas and gold leaf. Floor: polished stone or marble with inlaid geometric patterns at the landings. Width about 8-10 m (est.). Downloaded: `2016_Rangun_Pagoda_Szwedagon_006_`, `Empty_Shwedagon_Pagoda_Corridor`, `...religious_sites_15/28`.
  - **W stairway:** paired escalators running between the same gold-and-green colonnades (`...religious_sites_16`).
  - **S entrance hall / pagoda office:** white walls, a black-and-white chequered floor, a green carpet runner and notice boards (`Shwedagon_Pagoda_Office`).
  - **Tazaung shrine halls on the platform:** open-sided halls. Gold columns on green or red bases, carved and gilded teak ceilings or green-and-gold coffers, a mirror-mosaic back wall and rows of seated white-and-gold Buddhas on a stepped dais. Floors are polished marble or tile; worshippers sit on red patterned carpets. Typical hall about 10 × 15 m, ceiling 5-6 m (est.).
  - **Reclining-Buddha hall:** a dark wood ceiling with fans; the Buddha lies on a glass-mosaic plinth along the back wall (`..._068`).
  - **Bell pavilions:** a tiered pyatthat roof in dark carved teak on gold columns; the bell hangs from a beam (`...religious_sites_20`).
  - **Platform:** white marble paving, about 0.6 m tiles (est.) set in a grid, with a brown/red mat path for walking in the sun. Ring of shrines around the plinth. Platform size was not found in the sources: measure it from satellite.
- **Build:** everything above. The interior of the stupa itself is solid: never build an inside.

### 2. Sule Pagoda (A)
- **Where:** lon 96.1588, lat 16.7747 (roundabout). Inside the map.
- **Facts:** The stupa is octagonal from base to spire, about 44-48 m tall. Four entrances with tiered roofs. A ring of street-front shops forms the outer wall (palmistry and astrology stalls). 8 planetary shrines inside. Sources: [Wikipedia](https://en.wikipedia.org/wiki/Sule_Pagoda), [yangongui.de](https://yangongui.de/sule-pagoda), [Lonely Planet](https://www.lonelyplanet.com/points-of-interest/sule-paya/1368174).
- **Photos:** Commons [Sule pagoda](https://commons.wikimedia.org/wiki/Category:Sule_pagoda) (180+). Interiors by Marcin Konsek (2016 series), Gerd Eichmann and others.
- **Spaces:**
  - **Inner ambulatory and shrine pavilions:** carved and gilded teak screens and ceilings with deep coffers. Glass cases hold small images. Clock and flags on the back wall. Floor: glass-mosaic or tiled, a teal/white pattern. Monk for scale: ceiling about 4 m (est.) (`2016_Rangun_Pagoda_Sule_13/14/15/19`).
  - **Shrine rooms in the base:** small rooms (about 4 × 4 m est.) with yellow-painted walls, white pierced-concrete window screens, one white-and-gold Buddha on a carved base, flowers and umbrellas (`01-yangon-sule-paya-d02`, `_16`).
  - **Glass-mosaic surfaces:** columns and walls in diamond-pattern mirror mosaic in silver and teal (`Pagoda_Sule_13`, `Glasmosaik`).
  - **28-Buddha hall:** a long row of standing gold Buddhas behind glass, with carpet in front (`28Buddhas-01`).
  - **Nat shrine:** a room with oversized painted nat masks and a clock (`Nat-gje`).
- **Build:** the ring of shrine rooms and pavilions, the ambulatory, and the shops (fronts only).

### 3. Bogyoke Aung San (Scott) Market (A)
- **Where:** lon 96.1540, lat 16.7801. Inside the map.
- **Facts:** Built 1926, two storeys, more than 2,000 shops in 4 wings. The central hall has a high arched roof full of small booths (gems and jewellery, air-conditioned). A new wing across Bogyoke Market Rd was added in the 1990s. Cobbled inner lanes (one source only). Arcades on the outside with iron arches. Sources: [Wikipedia](https://en.wikipedia.org/wiki/Bogyoke_Market), [yangongui.de](https://www.yangongui.de/?p=50723), [Myanmar Insider](https://www.myanmarinsider.com/?p=2209), [Asia for Visitors](https://asiaforvisitors.com/burma/yangon/scotmarket/).
- **Photos:** Commons [Bogyoke Aung San Market](https://commons.wikimedia.org/wiki/Category:Bogyoke_Aung_San_Market).
- **Spaces:**
  - **Central hall:** a long nave with a steel arched or trussed roof, clerestory light and a high ceiling (8-10 m est.). Glass-fronted jewellery booths line both sides of a tiled aisle about 4 m wide. Yellow and red shop signs (`Bogyoke_Aung_San_Market_inside`, `Jewellery_Market`).
  - **Textile and handicraft aisles:** narrow aisles (2-2.5 m) packed floor to ceiling with longyi cloth, plastic stools and fluorescent tubes (`Textile_shop`, `Bogyoke_Ang_San_Market`).
  - **Stairwells to the first floor,** used as art shops with painted canvases on the walls.
  - **Block plan:** a plan board shows parallel blocks with aisles between them (`Bogyoke_Aung_San_Market_Map`). Use it for the layout.

### 4. Yangon Central Railway Station (A)
- **Where:** lon 96.1611, lat 16.7817. Inside the map.
- **Facts:** Opened 5 Jun 1954 (rebuilt 1947-54). 5,110 m² building. 7 platforms (3 island + 1 side). Burmese pyatthat roofs. A circle-line counter is at platform 7. Sources: [Wikipedia](https://en.wikipedia.org/wiki/Yangon_Central_railway_station), [Roads & Kingdoms](https://roadsandkingdoms.com/2015/living-inside-yangon-central), [worldofdecay blog](https://worldofdecay.blogspot.com/2014/12/burmese-days-3-rangoon-central-railroad.html).
- **Photos:** Commons [Yangon Central Railway Station](https://commons.wikimedia.org/wiki/Category:Yangon_Central_Railway_Station) (101).
- **Spaces:**
  - **Ticket hall:** double height, about 8 m (est.), with a first-floor gallery and balustrade. Cream walls and square columns with simple capitals. Wooden ticket counters with barred windows, a big wall clock, steel queue rails and green timetable boards. Floor: grey terrazzo (`YANGON_RAILWAY_STATION_..._8941455162/8941467890/8941481598`, `Yangon_Central`).
  - **Lobby / concourse:** a light steel roof, rows of seats and blue signs (`Yangon_Central_Station_Lobby`).
  - **Platforms:** long platforms under steel truss canopies on single columns. Green-painted sawtooth roof sheets; round number signs "6 West / 7 West" hang from the trusses. Concrete platform edge with a yellow line. Station clocks (`Yangon_Central_railway_station_11/12`, `Platform_No.1`).
  - **Porte-cochère** under the front building: a concrete arcade (`..._05`).

### 5. Botataung Pagoda (A online, few on Commons)
- **Where:** lon 96.1711, lat 16.7688 (river front). Inside the map.
- **Facts:** The stupa is hollow. Rebuilt after its destruction on 8 Nov 1943. A zigzag corridor with right-angle turns runs round the inside. Walls are gold leaf near the Buddha hair relic and mirror mosaic further on. Glass showcases hold relics found in 1943. Sources: [Wikipedia](https://en.wikipedia.org/wiki/Botataung_Pagoda), [Lonely Planet](https://www.lonelyplanet.com/myanmar-burma/yangon/attractions/botataung-paya/a/poi-sig/1368172/357104), [myandering blog](https://myandering.blogspot.com/2013/08/botataung-paya-yangon.html), [terragalleria photo 1](https://terragalleria.com/asia/myanmar/yangon/picture.myan58026.html) / [photo 2](https://terragalleria.com/asia/myanmar/yangon/picture.myan58025.html) (copyrighted: gold corridor with relic cases).
- **Spaces:** **Inner corridor.** About 1.5-2 m wide and 2.5-3 m high (est.). Gold-leaf walls and ceiling that look like crinkled foil, plus faceted mirror mosaic in other sections. Glass showcases set into the walls hold silver and gold relic miniatures. Right-angle turns form a maze around the central relic chamber. The relic chamber sits behind bars/glass at the centre. Downloaded: `Room_Inside_Paya`, `BotahtaungPagodaYangonTreasuresOnInnerPagoda2013`, `Botataung_Pagoda_10424722066`, `Eingang-gje`.

### 6. Chaukhtatgyi reclining Buddha (A online)
- **Where:** lon 96.1490, lat 16.8047 (Shwegondaing Rd). Inside the map.
- **Facts:** The Buddha is about 66 m long and 16-17 m high (replaced 1957-66, consecrated 1973). It sits under a large red-roofed steel shed whose girders are marked "Lanarkshire Steel". 108 red-and-gold segments on the soles. A small hall with sandalwood Buddhas is at the head end, and a mural behind the feet. Sources: [Wikipedia](https://en.wikipedia.org/wiki/Chaukhtatgyi_Buddha_Temple), [yangongui.de](https://www.yangongui.de/?p=50492), [renown-travel](https://renown-travel.com/burma/yangon/chaukhtatgyipagoda.html).
- **Photos:** Commons [Chaukhtatgyi Paya](https://commons.wikimedia.org/wiki/Category:Chaukhtatgyi_Paya) (20, mostly details) and [Statue of the Buddha reclining at Chaukhtatgyi Paya](https://commons.wikimedia.org/wiki/Category:Statue_of_the_Buddha_reclining_at_Chaukhtatgyi_Paya). Whole-hall views are plentiful on TripAdvisor and Google Maps.
- **Spaces:** **Hall.** About 80 × 30 m (est.). Open steel portal frames, a corrugated roof with skylight strips, and polished tile floor. A glass-mosaic plinth runs the length of the Buddha. Side walls have rows of red/gold/teal niches. White columns with golden shrine rows. Downloaded: 6 details (plinth, niche wall, hall floor).

### 7. Ngahtatgyi seated Buddha (A)
- **Where:** lon 96.16256, lat 16.80845 (OSM way/314121257, checked on Esri z19 16 Nov; was 96.1488, 16.8072), across Shwegondaing Road from Chaukhtatgyi. Inside the map. Note: "Kyauk Htat Gyi" in the brief = Chaukhtatgyi; Ngahtatgyi is its neighbour.
- **Facts:** A seated Buddha about 14 m high (one source: 20 m) in royal attire, in front of a carved teak backdrop with dragon and floral carving. Sources: [renown-travel](https://renown-travel.com/burma/yangon/ngahtatgyipagoda.html), [yangongui.de](https://www.yangongui.de/?p=50499), [takeyourbackpack](https://www.takeyourbackpack.com/backpacking-in-myanmar/visit-nga-htat-gyi-buddha-temple/).
- **Spaces:** **Hall.** A steel-truss shed (exposed grey trusses, a high skylight band) and a red polished floor. A white-faced Buddha with gold robes and a winged crown sits on a tiered gilt throne in front of a dark carved-teak backdrop about 18-20 m high (est.). There is a bell in the hall. Downloaded: 11 (`Yangon-Ngahtatgyi-12-Halle` is the best whole-hall view).

### 8. Maha Wizaya Pagoda (A)
- **Where:** lon 96.1475, lat 16.7956 (south of Shwedagon). Inside the map.
- **Facts:** Built 1980. The stupa is hollow and open to visitors. Painted trees grow up the walls (leaves partly plastic), under a light-blue dome with animals and constellations; the relic shrine is in the centre. Sources: [Lonely Planet](https://www.lonelyplanet.com/points-of-interest/maha-wizaya-zedi/1369939), [renown-travel](https://www.renown-travel.com/burma/yangon/mahawizayapagoda.html), [thailex (ambulatory)](https://thailex.info/THAILEX/THAILEXENG/LEXICON/Maha%20Wizaya%20Zedi%20(ambulatory).htm).
- **Spaces:** **One round chamber,** about 20 m diameter (est.). Dark-green/teal forest mural round the wall with tree trunks in relief. Door arches with white surrounds at the cardinal points. Dome ceiling in pale blue with painted birds, fish, a crocodile and other animals. In the centre, a white mini-stupa shrine with gold Buddhas on an octagonal base, ringed by a low rail. Polished stone floor. Downloaded: 6 (Konsek 2016 `Maha_Wizaya_17-21`).

### 9. Musmeah Yeshua Synagogue (A)
- **Where:** lon 96.1537, lat 16.7744 (26th St, near Mahabandoola Rd). Inside the map.
- **Facts:** Built 1893-96. A two-level Sephardic layout: central bimah, women's balcony upstairs, red velvet, teak pews with rattan seats, chandeliers and white pillars. Sources: [Wikipedia](https://en.wikipedia.org/wiki/Musmeah_Yeshua_Synagogue), [Lonely Planet](https://www.lonelyplanet.com/myanmar-burma/yangon-rangoon/attractions/musmeah-yeshua-synagogue/a/poi-sig/1368213/357104), [danfellner.com](https://danfellner.com/2016/04/15/myanmar-jewish-synagogue/).
- **Spaces:** **Sanctuary,** about 15 × 25 m (est.). Slim white columns carry a gallery on three sides with a white balustrade. A blue-and-white painted ceiling with round medallions and hanging glass pendant lamps. Central bimah with a carved wood/brass rail. The ark wall at the end has red velvet curtains with gold menorah embroidery and tall brass menorahs. Black-and-white chequered floor. Dark teak benches with rattan seats. Downloaded: 12.

### 10. St Mary's Cathedral (A)
- **Where:** lon 96.1640, lat 16.7770 (Bo Aung Kyaw Rd). Inside the map.
- **Facts:** Gothic Revival, red brick. Built 1895-99, consecrated 1910. Designed by Joseph Cuypers. Survived the 1930 earthquake (two vaults fell). Sources: [Wikipedia](https://en.wikipedia.org/wiki/St._Mary%27s_Cathedral,_Yangon), [Lonely Planet](https://www.lonelyplanet.com/myanmar-burma/yangon/attractions/st-mary-s-cathedral/a/poi-sig/1368219/357104), [UCA News centennial makeover](https://www.ucanews.com/news/st-marys-gets-centennial-makeover/36585).
- **Spaces:** **Nave plus aisles and choir.** Pointed-arch vaults whose brick ribs are painted in red-and-white stripes and zigzag bands, on cream walls. Clustered columns banded in red and white. Stained glass in the clerestory and rose window. Teak pews and pulpit, a cream-and-gold altar and a chequered tile floor. Nave about 70 m long and 20 m high (est.). Downloaded: 5 (`Arches_of_St_Mary_s`, `Inside_St._Mary_s`, `St_mary_pulpit`, ...).

### 11. The Strand Hotel (A)
- **Where:** lon 96.1625, lat 16.7710 (92 Strand Rd). Inside the map.
- **Facts:** Opened 1901. Renovated and reopened Nov 2016. The lobby is black and white, with rattan peacock chairs, ceiling fans, soaring ceilings and a marble floor. The Sarkies Bar has teak panelling. Sources: [Afar](https://www.afar.com/magazine/myanmars-grandest-hotel-gets-a-makeover), [Wallpaper](https://www.wallpaper.com/travel/myanmar/yangon/hotels/the-strand-yangon), [SCMP](https://www.scmp.com/magazines/post-magazine/travel/article/2073145/yangons-strand-slice-colonial-heaven-dress-code), official site [hotelthestrand.com](https://www.hotelthestrand.com) (gallery, copyrighted).
- **Spaces:**
  - **Lobby:** about 12 × 20 m and 6 m high (est.). Cream columns and walls, a brass/crystal chandelier, a black-and-white marble floor, cane chairs and potted palms (`Lobby_of_Strand_Hotel`, `Myanmar_-_Strand_Hotel`).
  - **Sarkies Bar:** a teak-panelled room with a bar counter (official photos only).
  - **Café and restaurant:** official photos only.

### 12. Sule Shangri-La (A, official)
- **Where:** lon 96.1570, lat 16.7786 (223 Sule Pagoda Rd). Inside the map.
- **Facts:** Ex Traders Hotel, reopened 2014 after a 2.5-year renovation. Colonial lobby with white columns and a grand staircase up to an open balcony. The lobby lounge has a high ceiling, a tiered crystal chandelier and peacock motifs. The Gallery Bar is a British-pub style room with dark wood, wrought iron and brass. Myanmar Ballroom. Sources: [Hospitality Design](https://hospitalitydesign.com/news/traders-hotel-yangon-rebrands-as-sule-shangri-la/32719), [Executive Traveller](https://www.executivetraveller.com/sule-shangri-la-yangon-opens-after-extensive-renovations), official [shangri-la.com](https://www.shangri-la.com/yangon/suleshangrila/about).
- **Spaces:** lobby, lobby lounge, Gallery Bar and ballroom (official galleries). A guest corridor from the Traders era is on Commons (`Traders_Corridor`).

### 13. Kheng Hock Keong (A)
- **Where:** lon 96.1524, lat 16.7718 (Strand Rd, Latha). Inside the map.
- **Spaces:** **Main hall.** Red lacquered timber with gilt carved altars, two stone dragon columns, bronze censers on red tables, red lanterns, and a dark stone floor. Side altars have gilt carved screens. Entrance with door gods and four heavenly-king statues. Downloaded: 9 (Konsek 2016 series). Source: [Commons category](https://commons.wikimedia.org/wiki/Category:Kheng_Hock_Keong,_Yangon).

### 14-15. Meliá Yangon and Myanmar Plaza (A, done)
See `refs/melia_interior/melia_interior.md` and `refs/mall_interior/`. Not repeated here.

### 16. Pan Pacific Yangon (A, official only)
- **Where:** in Junction City tower, lon 96.1517, lat 16.7790. Inside the map.
- **Facts:** 25 storeys, opened late 2017. Architect DP Architects. **Sky lobby on the 6th floor, double height,** with views to Shwedagon. Sources: [Pan Pacific press release](https://mynewsdesk.com/sg/pan-pacific-hotels-group/pressreleases/pan-pacific-yangon-opened-in-style-in-the-heart-of-yangon-2430384), [Skyscraper Center](https://www.skyscrapercenter.com/building/pan-pacific-yangon/22714), booking galleries ([Expedia](https://www.ebookers.ie/Yangon-Hotels-Pan-Pacific-Yangon.h20043820.Hotel-Information)).
- **Build:** the sky lobby only, reached by lift from the street. Copyrighted photos only, so build from the description.

### 17. Chatrium Hotel Royal Lake (A, official)
- **Where:** lon 96.1620, lat 16.7860 (Natmauk Rd, S of Kandawgyi). Inside the map.
- **Facts:** Interiors by Thats ITH Interiors (Nov 2017). The lobby and VIP lounge have a gold-inlay feature wall inspired by temple walls. The lobby lounge has a half-relief "aub" feature wall and a 12-cornered chandelier based on a chedi base. Grand Ballroom. Sources: [Design Awards entry](https://thedesignawards.co.uk/hotel-property-winners-2020/chatrium-hotel-royal-lake-yangon-ith-interiors-2), [designsoc](https://thedesignsoc.com/chatriumhotelroyal-lake-yango-thats-ith-interiors/), [chatrium.com lobby lounge](https://www.chatrium.com/royallakeyangon/experience/dine/lobby-lounge), [function rooms](https://chatrium.com/royallakeyangon/meetings-events/function-rooms).

### 18. Lotte Hotel Yangon (A, official)
- **Where:** lon 96.1311, lat 16.8543 (Inya Lake W shore, Hlaing). Inside the map.
- **Facts:** Built 2017. Lobby with a large chandelier, floor-to-ceiling windows onto the lake and warm colours. Sources: [lottehotel.com](https://www.lottehotel.com/yangon-hotel/en/information.html), [The Lounge](https://app.lottehotel.com/yangon-hotel/en/dining/the-lounge.html), [Ampersand](https://ampersandtravel.com/burma/hotels/the-lotte), [She Wanders Abroad review](https://shewandersabroad.com/?p=14244).

### 19. Rosewood Yangon (A, official/press)
- **Where:** lon 96.1593, lat 16.7705 (Strand Rd × Sule Pagoda Rd). Inside the map.
- **Facts:** In the former New Law Courts (1927), opened 2020. A portico with 1920s chandeliers leads through two sets of iron-framed doors into the lobby. Original bronze doors, teak handrails and a row of Ionic columns. A mural by Than Kyaw Htay above reception. Restaurants by Bond Design Studio. Sources: [Hospitality Design](https://hospitalitydesign.com/news/rosewood-yangon-myanmar/84803), [Home Journal](https://www.homejournal.com/en/article/Rose-Tinted:-Revisit-Colonial-Glamour-at-the-Newly-Minted-Rosewood-Yangon-), [Jacada](https://jacadatravel.com/asia/myanmar/yangon-rangoon/accommodation/rosewood-yangon).

### 20. The Secretariat / Ministers' Building (B)
- **Where:** lon 96.1655, lat 16.7765 (Thein Phyu Rd). Inside the map.
- **Facts:** A red-and-yellow brick Victorian complex. Tour route: the Parliament House (Union-Jack-pattern ceiling), the west-wing cabinet room where Aung San was killed (1947), and a double staircase in the minister's office. Restoration with Italian experts, with the "10 traditional arts" in interiors. Sources: [Wikipedia](https://en.wikipedia.org/wiki/Ministers%27_Building), [Irrawaddy](https://www.irrawaddy.com/news/burma/gen-aung-sans-secretariat-office-restored-open-public-martyrs-day.html), [W&M blog tour](https://law.wm.edu/academics/intellectuallife/researchcenters/postconflictjustice/internships/internship-blogs/2019/kristin_palmason/tour-of-the-secretariat-building-and-martyrs-day.php), [The National](https://www.thenationalnews.com/arts-culture/art/myanmar-past-and-present-meet-at-the-secretariat-1.712984), [SCE restoration](https://sceproject.it/?p=11082), [RBA architects](https://www.rbaarchitects.com.au/post/yangon-secretariat).
- **Spaces with photos:**
  - Arcaded verandah corridors: red walls, white round arches, tiled floor (`The_Ministers_Office_Building_Corridor`).
  - Staircase hall seen from above: a curving stair with a red carpet and an octagonal well (`YangonSecretariatStaircase`).
  - Skylight lantern (`...Inside`).
  - Old parliament hall wall: pale blue with the flag (`Parlamentssaal...`).
- **Build:** corridor and staircase. Rooms without photos stay closed.

### 21. Junction City (B)
- **Where:** lon 96.1517, lat 16.7790, opposite Bogyoke Market. Inside the map.
- **Facts:** Opened 2017. Architect DP Architects. 4-5 retail floors; the top floor is the food court and cinema. Sources: [Lonely Planet](https://www-lonelyplanet-com-57e2.imagizer.com/pois/1630600), [DP Architects](https://www.dpa.com.sg/?p=2866), [Good Life Myanmar](https://www.goodlifemyanmar.net/?p=4172) (photo from the mall's Facebook), [Wanderlog](https://wanderlog.com/place/details/557032).
- **Build:** the ground-floor shop gallery only, if a Google Maps photo set is checked first. No open photos.

### 22. Junction Square (B)
- **Where:** lon 96.1307, lat 16.8183 (Pyay Rd × Kyun Taw Rd, Kamayut). Inside the map.
- **Facts:** 305,000 sq ft, 270 shops, 3 cinemas and a large open event atrium. Owner Shwe Taung Group. Sources: [Harman case study](https://pro.harman.com/case_studies/junction-square-shopping-centre-myanmar), [Distech](https://insights.acuitybrands.com/distech-controls-project-references-blog/junction-square-yangon-myanmar), [Wanderlog](https://wanderlog.com/place/details/749020).

### 23. Kaba Aye Pagoda and Maha Pasana Guha cave (B)
- **Where:** lon 96.1497, lat 16.8565 (Kaba Aye Pagoda Rd, Mayangon). Inside the map.
- **Facts:** Built 1952 for the Sixth Synod. **Pagoda:** a hollow central pillar holding a large silver Buddha, ringed by 4 golden Buddhas; small images on the walls. **Cave:** about 455 × 370 ft outside; assembly hall about 220 × 140 ft; 6 entrances; seats up to 10,000. Sources: [renown-travel](https://renown-travel.com/burma/yangon/kabaayepagoda.html), [Lonely Planet](https://www.lonelyplanet.com/points-of-interest/mahapasana/1368227).
- **Photos:** `012_Examinations_Maha_Pasana_Cave` (Commons): gold octagonal columns, a coffered ceiling with a skylight panel, rows of white-draped tables. The pagoda interior is on Google Maps and TripAdvisor only.

### 24. Karaweik Palace (B)
- **Where:** lon 96.1636, lat 16.7897 (E shore of Kandawgyi). Inside the map.
- **Facts:** Several dining rooms over 3 floors (Ottara at the centre, Dekkhina on the lake side, Shwe War), theatres and reception halls. Carved wood panels, nat statues and murals. Nightly buffet with a cultural show from 18:00. Sources: [kupi](https://www.kupi.com/en/explore/myanmar/yangon/karaweik-palace), [gomyanmartours](https://www.gomyanmartours.com/?p=19031), [renown-travel](https://renown-travel.com/burma/yangon/karaweikhall.html), [trip.com moments (photos)](https://ae.trip.com/moments/poi-karaweik-palace-20905684). Commons: exterior only.
- **Build:** the main buffet hall and stage, from the trip.com and TripAdvisor photos.

### 25. National Museum (B)
- **Where:** lon 96.1421, lat 16.7926 (Pyay Rd, Dagon). Inside the map.
- **Facts:** About 14 halls on 4-5 floors. The ground floor has a purpose-built Lion Throne room: the throne is 26 ft high, gilded and jewelled, with models of 8 throne types. Photography inside has been restricted, so there are few photos. Sources: [Wikipedia](https://en.wikipedia.org/wiki/National_Museum_of_Myanmar_(Yangon)), [Asia for Visitors](https://asiaforvisitors.com/burma/yangon/yangon-museum/), [exotravel](https://www.exotravel.com/blog/?p=1150).
- **Build:** the Lion Throne room only.

### 26. Inya Lake Hotel (B)
- **Where:** lon 96.1555, lat 16.8460 (37 Kaba Aye Pagoda Rd). Inside the map.
- **Facts:** Soviet modernism, 1958-62, renovated in the 1990s. Fireplace in the lobby. Sources: [Wikipedia](https://en.wikipedia.org/wiki/Inya_Lake_Hotel), [inyalakehotel.com](https://www.inyalakehotel.com/our-story.php).
- **Photos:** `Hall_du_Dusit_Inya_Lake_Hotel_2005`: a low lobby with a glass wall to the garden, a carved panel, polished floor and armchairs.

### 27-29. Novotel Yangon Max, Rose Garden, PARKROYAL (B)
Booking-site galleries only (copyrighted).
- **Novotel Max:** lon 96.1349, lat 16.8278 (459 Pyay Rd). Glass façade, minimalist warm interiors ([Hotel Designs](https://hoteldesigns.net/industry-news/novotel-yangon-max-tranquillity-in-the-heart-of-myanmar/)).
- **Rose Garden:** lon 96.1630, lat 16.7860. Bagan-inspired design, lobby lounge and staircase ([Discovery DMC](https://discoverydmc.com/hotel/rose-garden-hotel)).
- **PARKROYAL:** lon 96.1600, lat 16.7840 (33 Alan Pya Phaya Rd). Tall lobby with columns, a staircase and a fountain ([hotels.com](https://sg.hotels.com/ho486447/parkroyal-yangon-yangon-myanmar)).
- **Build:** lobby only, after looking at the gallery.

### 30. Mogul Shiah Mosque (B)
- **Where:** lon 96.1557, lat 16.7742 (30th St). Inside the map.
- **Photos:** 3 Konsek 2016 shots: white arcades with black-banded column capitals, crystal chandeliers, a blue patterned carpet and green/red banners.

### 31. Bahadur Shah Zafar Dargah (B)
- **Where:** lon 96.1495, lat 16.7926 (Ziwaka Rd). Inside the map.
- **Photos:** 5. A prayer hall with pink walls, green-framed windows, ceiling fans and a red patterned carpet. A mazar room with white tile walls and tombs draped in green/red/gold cloth.

### 32. Armenian Church of St John the Baptist (B)
- **Where:** lon 96.1628, lat 16.7735 (Bo Aung Kyaw St × Merchant St). Inside the map.
- **Photos:** 3. A nave with dark-stained timber trusses, white walls, a red runner, wooden pews, an arched altar niche and a brass candle stand.

### 33. University of Yangon Convocation Hall (B)
- **Where:** lon 96.1350, lat 16.8295. Inside the map.
- **Photos:** 1 (`Innenansicht der Convocation Hall`): an auditorium with rows of folding wooden seats, a gallery and cream walls with arched windows.

### 34. Bogyoke Aung San Museum (B)
- **Where:** lon 96.1660, lat 16.8027 (Bogyoke Museum Lane, Bahan). Inside the map.
- **Facts:** Ground floor: dining room joined to reception and living rooms. Upper floor: bedrooms, library and a small altar room. Rooms restored to the family's time. Sources: [Wikipedia](https://en.wikipedia.org/wiki/Bogyoke_Aung_San_Museum), [Myanmar Mix](https://myanmarmix.com/en/node/1123), [Coconuts](https://coconuts.co/yangon/news/aung-san-museum-gets-makeover-ahead-martyrs-day).

### 35. Thamada Cinema (B)
- **Where:** lon 96.1597, lat 16.7820 (Alan Pya Phaya Rd). Inside the map.
- **Facts:** 1958. Oval auditorium with orchestra and balcony levels. Sources: [Wikipedia](https://en.wikipedia.org/wiki/Thamada_Cinema), [Cinema Treasures](https://cinematreasures.org/theaters/26248) (balcony photo).

### 36-37. Rangoon Tea House and Lucky Seven (B)
- **Rangoon Tea House:** lon 96.1609, lat 16.7728 (77-79 Pansodan Rd). Designed by M.ID (Mya Myitzu, 2014). A bright downstairs tea room and a speakeasy-style upstairs. Sources: [Habitus](https://www.habitusliving.com/articles/mya-myitzu-m-interiors-design), [Afar](https://www.afar.com/places/rangoon-tea-house).
- **Lucky Seven:** lon 96.1674, lat 16.7745 (49th St). Heavy wooden tables inside, a plant-packed terrace and 100+ seats. Source: [i-discoverasia](https://walks.i-discoverasia.com/walks/bogalay-zay-street/locations/lucky-7-yangon).

### 38. Thiri Mingalar market (B)
- **Where:** about lon 96.12, lat 16.83 (Hlaing/Kamayut; sources disagree). Inside the map.
- **Facts:** Opened 2010, 2,108 tenants, open 24 h. A fruit section on the ground floor of a multi-storey building, and a banana yard behind. Sources: [Wikipedia](https://en.wikipedia.org/wiki/Thiri_Mingalar_Market), [Migrationology](https://migrationology.com/yangons-thiri-mingalar-market-a-sensory-buffet-of-burmese-sights-and-sounds/), [Legal Nomads](https://www.legalnomads.com/a-remarkable-morning-in-yangon-thiri-mingalar-market/).

### 39. Circle-line stations (B)
Platforms only. Low concrete platforms, small ticket huts and green/yellow canopies. Photos: Commons Flickr set "The Yangon Circular Railway (…)" ([search](https://commons.wikimedia.org/w/index.php?search=Yangon+Circular+Railway&ns6=1)). Build a platform only where you are placing that exact station.

### 40. Thuwunna Stadium (B)
- **Where:** lon 96.196, lat 16.818. Inside the map.
- **Photos:** Commons "International football at Thuwanna Stadium 01-09" (stands and pitch). Seating bowl only.

### 41-53. C list (do not build interiors)
- **Holy Trinity Cathedral** (lon 96.1527, lat 16.7812): no interior photos found. Commons 2016/2018 sets are exterior; one blog describes marble floors and wooden pews.
- **City Hall** (lon 96.1593, lat 16.7746): Commons has 56 files, all exterior. One text source says the interior is "deep red and gold". No photos, so do not build.
- **Surti Sunni Jamah Mosque** and **Immanuel Baptist Church:** exterior photos only.
- **Theingyi Market:** text only ([Wikipedia](https://en.wikipedia.org/wiki/Theingyi_Market), [Uni Köln study PDF](https://kups.ub.uni-koeln.de/5458/1/Heritage_under_Transition_-_Theingyi_Zay_Yangon_Myanmar.pdf) may hold plans; check before building).
- **Taw Win Centre, Hledan Centre, Times City, Sule Square, City Mart/Ocean:** reviews only. No usable interior photo sets found.
- **Myanmar Convention Centre:** no interior photos found.
- **Airport:** outside the map (lat 16.907).
- **Kempinski Yangon (State House):** not opened. No photos.

---

## 3. Downloaded open photos (all Wikimedia Commons)

Each folder has a `sources.json` with the file name, Commons page, licence, author, date and what the photo shows.

`shwedagon/`, `sule_pagoda/`, `botataung/`, `chaukhtatgyi/`, `ngahtatgyi/`, `maha_wizaya/`, `kaba_aye_maha_pasana_cave/`, `bogyoke_market/`, `yangon_central_station/`, `musmeah_yeshua_synagogue/`, `st_marys_cathedral/`, `armenian_church/`, `mogul_shiah_mosque/`, `bahadur_shah_zafar_dargah/`, `kheng_hock_keong/`, `secretariat/`, `strand_hotel/`, `inya_lake_hotel/`, `sule_shangri_la/`, `yangon_university_convocation_hall/`.

Licences are mostly CC BY-SA 2.0/2.5/3.0/4.0, CC BY 2.0/3.0, and a few CC0 / public domain. When we credit in-game or on the game page, list the authors from `sources.json`. The main authors are Marcin Konsek, Gerd Eichmann, calflier001, Go-Myanmar, Shin Khant Maung and Bjoertvedt.
