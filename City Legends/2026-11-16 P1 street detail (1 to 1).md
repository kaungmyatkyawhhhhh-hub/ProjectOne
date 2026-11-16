---
tags: [city-legends, yangon, 1to1, street-detail, blueprint]
created: 2026-11-16
---
# P1 street detail at 1:1 (16 Nov 2026, in Studio, not saved)

The street layer of the pilot district P1: what makes a street read "Yangon". Built from [[2026-11-16 Research - Real Yangon street detail survey]] and [[2026-11-16 Research - Yangon street furniture and traffic life]] (densities per real km, photos in `Games/CityLegends/build/landmarks/refs/street_kit/`).

## What is there now
| Item | P1 count | Per real km of road | Notes |
|---|---|---|---|
| Concrete power poles | 1,937 | 24.7 | 9 m, square, tapering 0.30 to 0.16 m, dirty bottom 1.5 m, crossarm + cable rack; 1 in 3 with a fibre coil and junction box |
| Transformer platforms | 206 (of the poles) | 1 in about 9 poles | two poles, H-frame at 3.7 m, grey tank, fuses, red warning plate |
| Cable spans | 1,567 | | 6 to 14 black cables a span (Beams), they run on across junctions |
| Service drops to houses | 835 | | 1 to 2 from about half the street poles |
| White lamps | 343 posts + a head on every 2nd street pole | 4.4 posts | galvanised 10 m posts every 35 m on main roads, double-arm in the median where it is there; white LED (owner rule), on at night |
| Traffic signals | 47 poles at all 9 OSM signal junctions | | white pole, mast arm over the lanes, two HORIZONTAL black heads with a countdown panel, CCTV, controller cabinet |
| YBS stops | 28 of the 31 OSM stops | | 1 in 4 a Decaux shelter, the rest a pole plate; the stop's real Burmese / English name; orange bin |
| Street-name signs | 54 junction poles, 108 plates | | green plates, the real OSM Burmese and English names (90 plates drawn) |
| Tea-shop spills | 74 | | low blue tables and stools, or blue plastic chairs |
| Food carts and betel stalls | 129 | | umbrella carts with colour-block banners (no text), betel tables |
| Trishaws | 47 at 23 lane mouths | | sidecar BESIDE the bike on the rider's right, two seats back to back |
| Slab-covered drains | 62.6 km | | main-road pavement edge and street verges; some slabs missing, grates |
| Median railing | 0.2 km | | only narrow medians (wide ones are planted) |
| Litter at pole bases | 516 | | |

Not built, on purpose:
- Overhead direction gantries and police booths: no real text or positions to copy.
- Footbridges: none are mapped in P1.
- Motorbikes: banned in these townships.

## How it works (light, like the buildings)
- **Kit:** 33 pieces, 66 meshes, 11,418 triangles in all (one model, group asset 86646453630974). Templates sit in `ReplicatedStorage.YgnKit.Templates` (names `SCO_`, `SMT_`, `SPL_`, `SFB_`, `SGL_`, `SNE_`).
- **Data:** `ReplicatedStorage.YgnKit.Data_P1S` (700 tile strings, 0.47 MB). Each player's own client builds it within 700 studs of the camera (the buildings use 1,000).
- **Cables and plates:** cables are Beams; name plates are a picture on an invisible part. Neither adds a mesh.
- **Name atlases** (group images): 93884270174886, 94210211872736, 85893570964535.
- **Whole district:** 22,551 parts and 2.7 M triangles in the data. Near the camera on a dense street: 632 parts, 360 cables and 29 lights. The buildings there make 13,758 parts.
- **Play test (dense street, (31071, 30003)):** about 58.6 FPS without the street layer, about 57.3 FPS with it; memory +9 MB. FPS is capped near 60, so both are at the cap.
- **No flicker:** every kit piece checks out at 0 pairs. A placed sample (40 busiest tiles, 2,398 items, 337,010 triangles) has 0 flickering pairs between items.
- **Nothing in the wrong place:** nothing stands in a traffic lane or on a carriageway. Props keep clear of buildings, compound walls, gates, landmark lots, water, flyover decks, tree trunks (the green layer's 31,170 trees) and each other.

## Pictures (Studio, PlayLight 13 and Play at dusk)
- Residential street, poles and cables (compare `power_pole/01`): ![[P1 street detail - residential street, poles and cables.jpg]]
- Main road, YBS shelter and umbrella stall: ![[P1 street detail - main road, YBS shelter and stall.jpg]]
- Trishaw stand at a lane mouth (compare `trishaw/01`): ![[P1 street detail - trishaw stand at a lane mouth.jpg]]
- Tea-shop stools in front of a shop (compare `tea_shop/02`): ![[P1 street detail - tea-shop stools.jpg]]
- Play, residential street: ![[P1 street detail - residential street (Play).jpg]]
- Play, main road at dusk (white lamps on): ![[P1 street detail - main road at dusk (Play).jpg]]

## Still wrong / next
- The bus-stop name plates use an atlas image that was still in moderation during the test. It is approved now; check the plates in the next Play.
- Tea tables are a solid pedestal, not 4 legs. Seat cushions on the trishaws are plain blocks.
- Lamp posts read a bit too white. Real ones are galvanised grey.
- Not done yet:
  - parked cars (kerb parking on streets, nose-in on forecourts), using the traffic car models with client collision;
  - yellow kerb paint at bus bays;
  - railings by bus bays;
  - the old blue downtown canopy stops (P1 has none).
- Only 0.2 km of median railing: the real Kabar Aye median railing needs a check on photos.

## Run it again
All in `Games/CityLegends/tools/yangon/city/`, with `YANGON_SCALE=1to1`:
1. `python street_kit.py`: the kit. It prints the flicker test (must be 0).
2. `python street_signs.py P1`: the name plates. Upload the PNGs as Images, then run `street_signs.py P1 --ids <ids>`.
3. `python street_1to1.py P1`: the placement, about 2 minutes. Output: `imports/sync/ygn1to1_street/ygnstreet_p1.rbxmx` plus `build/city_1to1/street_P1/` (stats, preview, items).
4. `python street_flicker_test.py P1`: the placed check.

In Studio:
1. Upload the kit `.glb` as a Model.
2. `insert_asset` it, then run `require(ServerStorage.ClaudeTools.YangonStreetKit:Clone()).templates(holding)`.
3. PATCH the data rbxmx into asset 133014134133489.
4. `InsertService:LoadAsset` it and move `Data_P1S` into `ReplicatedStorage.YgnKit`.
5. To see it in Edit: `YangonStreetKit.preview(centre, radius)`; `unpreview()` clears it.
