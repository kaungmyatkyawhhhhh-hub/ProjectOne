---
date: 2026-11-26
tags: [city-legends, map, overlaps, fuel, places, buildings, bugs]
---
# Overlaps: gas station and building merged (26 Nov 2026)

Owner: "the gas station and a building is merged in together" (Kabar Aye Pagoda Road by Myanmar Plaza). Owner rule: no
overlapping parts, no z-fighting, anywhere.

## What it was
There are two real (OSM) fuel stations on Kabar Aye Pagoda Road near Myanmar Plaza, both built from the places layer
(`places_1to1.py`, data `Data_P1P` / `Data_P2P`):

| Station (OSM) | Where | What was wrong |
|---|---|---|
| New Day (`n2578264080`, P2) | north of Myanmar Plaza, (34887, 24640) | a 3-storey "building" stood in the middle of the forecourt and the canopy ran through it (up to 23 studs deep). The building was 4 Microsoft footprints (`m96155337_16836218_0..3`) that are really the station's own canopy roof seen from the satellite. The places plan had marked them "cleared", but they were never removed. |
| Myawady (`n2956795311`, P1, the game's fuel stop `fuel_yangon`) | south of Myanmar Plaza by the flyover, (34607, 29128) | the canopy's end stood 0.5 studs from the shophouse next door and that building's awning ran under the canopy; a tree crown stood in the kiosk. |

## Why the placement check missed it
- P2's buildings in the place are still the run made BEFORE the places plan (`buildings_P2_before_places`). The plan
  said "clear these 4 buildings", but only P1's buildings were re-run and swapped; P2's never were.
- `places_1to1.py build` checks "nothing in a building" against `buildings_P2/plots.json`, a NEWER run that no longer
  had those 4 buildings, so it reported 0. It never looked at what is really in the place.
- The lot checks we had (`LotFinder`, `VenueLots1to1`) test venue lots only, against road boxes and shells. Nothing
  tested the places layer, the kit detail (walls, awnings, trees) or the landmarks against each other.
- The Myawady lot is a guessed 34 x 26 m rectangle (OSM has only a point). It was cut clear of footprints + 0.6 m, but
  kit walls, awnings and roofs reach about 1 m past a footprint.

(The rest of this note: the checker, counts before / after, what was fixed and what is left.)
