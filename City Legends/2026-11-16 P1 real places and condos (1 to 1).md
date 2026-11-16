---
tags: [city-legends, yangon, 1to1, places, fuel, condos, compounds, blueprint]
created: 2026-11-16
---
# P1 real places and condos (1 to 1)

> Owner: "most of the stuff like the gas station near myanmar plaza ... is missing", "also the yangon condominiums arent there?"

Pilot district P1 (lon 96.133-96.159, lat 16.810-16.834). In Studio, **not saved**.

## What is in P1 now
| Kind | Count | How |
|---|---|---|
| Fuel stations | 2 (all OSM fuel stations inside P1) | forecourt, canopy on columns, Neon lights under it, fascia band, 5 pump islands (10 pumps, yellow bollards), kiosk, painted IN / OUT arrows. Collision on the columns, islands, pumps and kiosk. |
| Car parks | 4 OSM car parks, 1,027 bays | asphalt slab, white 2.5 x 5 m bays, 6 m aisles |
| Courts | 17 (tennis, from OSM `sport`) | concrete slab, lines, net posts and net |
| Grass / earth pitches | 12, with 24 goals | goals at both ends (no paint on grass) |
| Playgrounds | 2 | sand pad with a kerb, swings, climbing frame |
| Walled compounds | 16 on their real OSM outlines (of 20 mapped: 4 had no building inside) | universities (University of Yangon, Foreign Languages, Distance Education ...), embassies (US, Korea, Australia), international and local schools, temples / monasteries. Gate at the OSM gate where one is mapped, otherwise on the street side. |
| Civic buildings | 128 | school, hospital, hotel, embassy and office buildings get the civic look (not houses) |
| Monastery / temple halls | 29 | low villa look, 1-3 floors |
| Condos | 8 at their real levels (11 condo towers in all) | see the list below |

Not included:
- Names and signs: the landmark-name rule allows only Novotel, Myanmar Plaza and Optima Werkz.
- Logos and brand names.
- Fuel colours: only the satellite roof colour (Myawaddy, University Avenue: pale green-grey). The fascia green is a plain colour, not checked against a photo.

## P2 (north of P1: Inya Lake north / east, Kaba Aye, Mayangone edge)
- **Fuel:** New Day (Kabar Aye Pagoda Rd, 1 km north of Myanmar Plaza). Canopy measured on the satellite: 27 x 22 m, roof pale grey-green. 6 islands with 12 pumps, a kiosk, IN / OUT arrows.
- **Car parks:** 9, with 146 bays.
- **Courts:** 6 tennis.
- **Baseball fields:** 3. No goals: nothing is invented for a sport the kit does not have.
- **Playgrounds:** 2.
- **Walled compounds:** 13 of the 14 mapped:
  - schools (BEHS 4, BEMS 1, BEPS 10 Mayangone, MISY, Khayay, International School);
  - hospitals (Yankin Children, Kan Thar Yar, Parami);
  - universities (UIT, ICTTI, Economics Hlaing campus);
  - Micasa Hotel.
  - Kaba Aye stays its landmark site.
- **Condos at real levels:**
  - Sae Lae May Condos: 12 levels.
  - May Inya: 10 levels.
  - Myat Lay Hall and Kaytumati Hall: 7 levels each.
  - A 5-part tower group at 16.8343, 96.1562 (just north of P1): 30-39 levels. The only source is OSM, and it needs checking.
  - Diamond Inya (33 levels) stays its landmark site.
- **Greenery:** green P2 run again. It found 39 trees on the new lots; now there are 0.

## Condos (height = 4.5 m ground floor + 3.33 m a floor + 1.2 m parapet)
| Condo | Levels | Game height | Source | Look |
|---|---|---|---|---|
| Pearl Condo (Kabar Aye Pagoda Rd), 4 towers (o374511963, o374511964, o374511984, o374512116) | 20 | about 69 m + roof | OSM building:levels (CTBUH lists "Pearl Center Block F" at 55 m, which does not match 20 floors) | white towers with terracotta hip roofs, from the satellite |
| Pyay Garden (o375498991) | 25 | about 86 m | OSM building:levels | condo kit |
| University Yeik Mon Housing x2 | 14 | about 49 m | OSM building:levels | condo kit |
| Sakura Residence (o250279020) | 6 | about 22 m | OSM building:levels | condo kit |

Next to P1 but not built: Crystal Residences (lon 96.130, just west of P1, 90 m / 25 floors, Wikipedia list), Diamond Inya and Lotte (P2 landmark sites), and Lanthit (Lanmadaw). There is no 1:1 ground there yet.

## Fuel stations and the old game venues (venues not moved yet)
| Real station | Where | Fits |
|---|---|---|
| Myawady (OSM n2956795311) | Kabar Aye Pagoda Rd, by the flyover, 500 m south of Myanmar Plaza | `Config.Fuel.Stations` fuel_yangon (the nearest real station to it: 1.2 km) |
| Myawaddy (OSM n3838315913) | University Avenue Rd, north side; canopy measured on the satellite (24 x 18.6 m) | a second Yangon fuel stop, or Legends Service. Legends Service's old spot (96.1482, 16.8135) lands on a real car-service shop ("Inya Mying 22+"), which could be its 1:1 home. |
| Max (New University Ave), New Day, Max (west) | just outside P1 (east, P2, west) | for later districts |

## How it works
- `tools/yangon/city/places_extract.py P1`: every OSM object in P1 with all its tags. Takes about 9 minutes and writes `build/city_1to1/places_P1/osm_all.json`.
- `places_1to1.py P1 plan`: writes `places.json` and `plan.json`. `places.json` holds:
  - the lots to clear;
  - the small buildings on car parks, pitches and playgrounds to drop;
  - the compounds and their gates;
  - per-building changes: condo levels, civic look, Pearl crowns.
- `buildings_1to1.py P1` reads `places.json`. It drops generic buildings on the lots, walls the compounds and gives the overrides.
- `places_1to1.py P1 build` writes the places as client-streamed data `ReplicatedStorage.YgnKit.Data_P1P` (kit_pack B records, LOAD 900). It also writes:
  - `keepout.json`: green and street keep trees and props off these lots;
  - `driveways.json`: fuel entries and exits for the roads builder (cut the kerb there);
  - `Grade_1.txt`: terrain cut over the graded slabs.
- `green_1to1.py P1`: run again. It found 118 trees standing on the new lots; now there are 0.
- New colour codes in `src/shared/YangonKitData.lua` (PCN, PAS, PLN, PLY, PCW, PCS, PFG ... PLT is Neon).
- Studio: `places_pack.py P1` (all of it) or `places_pack.py P1 places` (the places layer only). PATCH asset 133014134133489, then `tools/yangon/PlacesApply.luau` (`unshells`, `shells`, `data`, `kitData`, `grade`). Then `YangonShellFacades.apply` (map P1-P4) and, for green, `G.data` and `G.farOld` merged into the existing Far.

## Roads05 (16 Nov evening)
- The P1 / P2 roads are now roads05 (one centre line per dual carriageway).
- `places_1to1.py` takes its corridors from `build/city_1to1/roads05_P1_P2/roads.json`: carriageways plus pavements plus 0.6 m, the same as `roads05_clear.road_polys`.
- Both districts were planned and built again against it. Nothing is on a road or in a building.
- All condos stand clear of the new corridors (under 2 m² of touch).
- Compounds and condos live in the kit-building data (`buildings_1to1` reads `places.json`). The districts agent swaps those.

## Checks
- Nothing stands on a road corridor or in a building: 0 and 0.
- Flicker test on the places (coplanar faces): 0.

## Still missing in P1
- Bus terminals and markets: none mapped as areas in P1.
- Hospitals: they are buildings only (civic look), with no compound outlines in OSM.
- Name signs: not allowed by the landmark-name rule.
- Interiors: no photos.
- Named condos as their own 3D models: no free photos (catalogue). Pearl has the satellite roof look only.
- Unnamed pitches are treated as football fields.
