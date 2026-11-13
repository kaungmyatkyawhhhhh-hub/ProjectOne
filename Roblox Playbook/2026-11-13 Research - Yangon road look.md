---
tags: [research, city-legends, yangon-map, roads]
created: 2026-11-13
---
# Research – what Yangon's main roads look like (pavement, kerb, lines)

Why: the Yangon map (City Legends, build step 3) needed its own road colours. The road builder still had Monaco's red-pink pavers.
How: three agents each opened and looked at street-level photos of one road (43 photos in all, 2008 to 2023, mostly Wikimedia Commons, some Flickr and Mapillary). A fourth agent only kept what 2 or more photos showed.
Used in: `Games/CityLegends/tools/yangon/YangonRoads.luau` (`M.palette`, `M.centre`). Build log: [[Yangon map - Build steps (Claude builds it)]].

## What the photos show
| Thing | Pyay Road (16 photos) | Kabar Aye Pagoda Road (11) | University Avenue Road (16) |
|---|---|---|---|
| **Pavement** | plain grey poured concrete on most stretches; small grey pavers only in front of Hledan Centre; tiles at bus shelters | plain grey concrete, cracked and dusty; grey pavers only at Myanmar Plaza | plain grey concrete slabs with joints every 1.5 to 3 m, drain covers along the road edge |
| **Kerb** | **red and white bands**, one colour per kerb block, about 1 m each (4 to 5 bands per car), 25 to 30 cm tall; also on the median, the splitter islands and the Hanthawaddy roundabout island | **red and white bands**, about 1 m each, 15 to 20 cm tall; some lengths bare concrete | mostly **plain concrete**; red and white only at gates, a bus stop, the US Embassy and the flyover island |
| **Lines** | white dashed lane lines, white arrows and stop lines; no centre line (a raised median divides the road) | all white: a solid centre line where there is no barrier, dashed lane lines | all white: solid centre line (2011, 2016), dashed lane lines about 3.5 m long with 5 to 8 m gaps |
| **Middle** | narrow raised median (hedge with red and white kerb, or a steel railing, or white blocks: it changes by stretch and year) | changes by year: none, orange blocks, bare concrete blocks, or a black steel fence | none: an undivided road of about 4 lanes |
| **Asphalt** | worn warm mid grey, not black (about 120, 113, 106; 85 when wet) | worn mid grey (about 95, 95, 98) | worn mid to dark grey (about 98, 98, 102) |

Roadside things seen on all three: very large rain trees over the road, grey steel lamp posts with one curved arm, concrete poles with tangled black cables, billboards (at the roundabout), orange and red-white concrete barrier blocks.
Hanthawaddy roundabout (2 ground photos, 2014 and 2018): red and white kerb round the island, lawn with low hedges and a gold urn, white low lamps, a white dashed give-way line.

## The look we use (one look for all three main roads)
| Part | Choice | Why |
|---|---|---|
| Pavement | plain grey concrete, RGB 150, 146, 136, Roblox material `Pavement` (slabs with joints) | the normal sidewalk on all three roads |
| Kerb | red 195, 47, 45 and white 232, 228, 218 bands, 3.2 studs each | 1 m bands are a quarter of a car; our cars are 3 studs to the metre, so a quarter of a car is about 3.2 studs |
| Lines | all white 235, 235, 230: solid centre line, dashed lane lines (5.8 studs on, 7 off), solid edge lines | undivided roads have one solid white centre line; our main roads have no middle strip |
| Asphalt | unchanged: the game's dark asphalt (46, 47, 50 with the place's `RivAsphalt` texture) | the photos show a lighter warm grey (about 108, 104, 101), but the cars, the wet-road look and the night lighting are tuned on the dark one. **Owner's call** if the Yangon roads should go lighter |

## Not settled by the photos
- **University Avenue's kerb** is mostly plain concrete in real life. We paint it red and white like the other two so the map has one look.
- **The median**: Pyay Road and parts of Kabar Aye have one in real life; the design (step 2) has none.
- **Zebra crossings**: yellow at Hledan (2021), white near Hanthawaddy (2018). Not built yet.
- **Edge lines** rest on 1 photo per road; most photos show none. The step 3 prompt asks for solid edge lines, so they are in.
- **Give-way and stop lines** rest on 1 photo each.
- **Age**: nothing newer than 2018 for Kabar Aye; University Avenue's full views are 2010 to 2016. Colours are good to about plus or minus 20 (phone photos, mixed light).
- No street-level photo of Pyay Road's Inya Lake bank stretch was found.

## Best photos (to look at again)
- Pyay Road at Hledan Centre, 2017 (the kerb and pavement close up): https://commons.wikimedia.org/wiki/File:Hledan_center_front.jpg
- Kerb from 1 m away, 2021: https://commons.wikimedia.org/wiki/File:Protestors_resting_at_Hledan_Junction_Yangon.jpg
- Hanthawaddy roundabout, 2014 and 2018: https://commons.wikimedia.org/wiki/File:Hanthawaddy_Roundabout.jpg , https://commons.wikimedia.org/wiki/File:Hanthawaddy_Roundabout_2.jpg
- Pyay Road and the roundabout from the air, 2018: https://commons.wikimedia.org/wiki/File:Pyay_Road_and_Hantharwaddy_Roundabout.jpg
- Kabar Aye Pagoda Road, Bahan, 2018 (kerb and sidewalk): https://commons.wikimedia.org/wiki/File:Yangon_IMG_20180407_095227_kabar_aye_pagoda_road_bahan.jpg
- Kabar Aye Pagoda Road from a car, 2012 (lines, no median): https://www.flickr.com/photos/wagaung/7331604354/
- Myanmar Plaza front (kerb, pavers): https://commons.wikimedia.org/wiki/File:Myanmar_Plaza_IMG_5391.jpg
- University Avenue Road at No. 54, 2013 (the whole road): https://www.flickr.com/photos/27214509@N00/9104310714/
- University Avenue Road, red and white kerb, 2014: https://www.flickr.com/photos/83101443@N00/18585185499/
- University Avenue Road at the US Embassy, 2021: https://commons.wikimedia.org/wiki/File:Police_in_front_of_US_Embassy_Yangon_1.png
