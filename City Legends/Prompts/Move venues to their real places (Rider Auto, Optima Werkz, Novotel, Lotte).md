# Prompt: put the venues at their real Yangon locations (Rider Auto, Optima Werkz, Novotel, Lotte first)

_For Claude Code on the PC with Studio (MCP). Owner: caveman mode, no questions (say what you will and won't do). No errors: leave a venue where it is rather than ship it broken. Read the game CLAUDE.md, the "Switch to the 1:1 map" and "Moving in (step 9)" rules, and `Config.YangonVenues`._

## What the owner wants (2026-11-21)
"Check from maps for the venues and place them exact at their location in game. Mainly dealerships, hotel, workshops, malls. Rider Auto, Optima Werkz, Novotel, Lotte are most important."

## Real locations (found by the cloud session; game world from `tools/yangon/city/geo.py`, 1:1, 3 studs/m)
| Venue in the game | Real place | lon, lat | Game x, z | District | Source |
|---|---|---|---|---|---|
| Dealership (Legends Motors) | **Rider Auto** (MK Rider Auto Showroom), (6/B) Ma Kyee Kyee Street, Sanchaung | street only | Ma Kyee Kyee Street runs (26761, 33635) -> (28706, 33773) | P6 | Yoma Bank dealer list + Rider Auto Facebook (Sanchaung). **The exact building on the street is not known:** find No. 6/B on Google Maps on the PC (or ask the owner for a pin) before moving it. |
| Customs / workshop (Legends Customs) | **Optima Werkz** | 96.14502, 16.81570 | (31605, 31426) | P1 | the owner's own Google Earth pin (`imports/refs/map/ygn map 2 project.kml`, "optima") |
| Hotel (suites) | **Novotel Yangon Max**, 459 Pyay Road, Kamayut | 96.13239, 16.82042 (owner pin) / 96.13196, 16.82012 (Accor GPS) | (27566, 29859) / (27429, 29960) | P4 | owner's KML "novotel" + accorhotels.com |
| Penthouse tower (tower_skyline: Lotte runs serviced residences) | **Lotte Hotel Yangon**, 82 Sin Phyu Shin Avenue, Pyay Road (by Inya Lake) | 96.13738, 16.84443 | (29162, 21899) | P2 | booking / trivago / tripadvisor GPS (agree to 4 decimals) |
| Malls | Myanmar Plaza (the real 1:1 landmark, already in place), Junction City, The Central, etc. | already built from OSM at their real spots | - | - | no move: check the Mall Shop job post and fast-travel spots point at the real malls |

Decision (owner said no questions): the **hotel venue goes to Novotel**, and **Lotte gets the Skyline penthouse tower** (its serviced residences). If the owner wants it the other way round, swap the two rows.

## How
1. In Studio, look at each spot (screenshot from above): the real building is there as a shell / landmark. Prefer using the REAL building: the venue's entrance, prompts, parking and marker at the real building's front, not a second building on top of it. If the venue needs its own built body (dealership, customs), clear the lot like `YangonSites.prepare` does (shells -> KeepOut boxes) and face the real road.
2. Update `Config.YangonVenues.Sites` (x, z, fx, fz, y), the minimap icons, fast-travel spots (`WestLayout.places`), `TravelSpots`, lamps (`d16_lamps.py` keeps off drive-ins), the menu shots if any look at the old spots, and anything keyed on the old positions (the bank / drop-off / gems must stay on one map; they are not moving).
3. Remove the old venue bodies from Kabar Aye Pagoda Road's east side; put the shells back there (`YangonSites.undo` for those lots).
4. Play-test each: drive there, enter, buy / tune / book a suite / open the penthouse, fast travel there. No script errors, nothing floating or inside a building, no overlapping parts.
5. Save (owner saves), commit, push, note it in `City Legends/City Legends.md` with before / after pictures.

## Tell the owner (short)
Where each venue is now (with a picture), Rider Auto's exact spot (or that it still needs a pin), anything left where it was and why.
