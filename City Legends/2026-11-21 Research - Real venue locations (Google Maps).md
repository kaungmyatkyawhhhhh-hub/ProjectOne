# Real venue locations from Google Maps (21 Nov, owner's order)

Owner: "check from google, open view, earth, 3d, maps for the venues and place them exact at their location in game. Mainly dealerships, hotel, workshops, malls. Rider auto, Optima Werkz, Novotel, lotte are most important." Also: People's Park, the Shwedagon view point, the Shwedagon Pagoda parking, "the central point" (view and build).

Coordinates read from the Google Maps place pages (the `!3d<lat>!4d<lon>` in the URL). Game studs by `tools/yangon/city/geo.py` at the 1:1 scale: X = 30000 + (lon - 96.14) x 106,558 x 3, Z = 30000 - (lat - 16.82) x 110,540 x 3.

| Place | Real | lat, lon | Game X, Z | Venue in the game | Where the game has it now |
|---|---|---|---|---|---|
| Rider Auto Premium Car Sale Center | car dealer | 16.8087921, 96.1349875 | 28398, 33717 | Legends Motors (dealership) | 35454, 22409 (a made-up row on Kabar Aye) |
| Optima Werkz Yangon | tuning workshop | 16.8156414, 96.1451333 | 31641, 31445 | Legends Customs (workshop) | 35534, 21839 |
| Novotel Yangon Max | hotel | 16.8199958, 96.131663 | 27335, 30001 | the hotel | 36030, 19833 |
| Lotte Hotel Yangon | hotel + residences | 16.8443204, 96.1372798 | 29130, 21935 | a tower (penthouses) or a second hotel: to decide | tower_aurum 34841, 19737 |

Rider Auto sits about 1,500 studs south of the Hanthawaddy Roundabout (28250, 32194).

## Not done yet
- Nothing is moved. Moving a venue = a new lot (`Config.YangonVenues.Sites`), `tools/yangon/city/venues_1to1.py` -> `VenueLots1to1.luau` check -> `YangonSites.prepare` (flat pad, shells out, KeepOut box), fast-travel spots, minimap, then a Play check. Each real lot must first be looked at on the satellite view and Street View for its size and which way it faces.
- Still to look up: the other dealerships, hotels, workshops and malls; People's Park; the Shwedagon view point; the Shwedagon parking; "the central point" (The Central on Kabar Aye, already has letters and a pavilion in the game, or another place: check with the photos).
- Check each of the four lies inside a built district (P1-P4, P6-P8) before moving.
