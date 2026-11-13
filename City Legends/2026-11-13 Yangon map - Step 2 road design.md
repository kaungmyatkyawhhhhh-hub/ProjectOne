---
tags: [city-legends, yangon-map, road-design]
created: 2026-11-13
---
# Yangon map – Step 2: road design

Owner approved the street plan on 13 Nov 2026 ("OK"). This note is the road design that follows it.
Nothing was built or changed in Studio yet. Step 1: [[2026-11-13 Yangon map - Step 1 report]]. What gets built next: [[Yangon map - Build steps (Claude builds it)]].

![[ygn_road_design.png]]

## The numbers
- **33 roads, 34.8 km** (55,700 studs). The Monaco plan had 36 roads and 30.8 km, so the road budget is about the same.
- **Main roads: 3, 17.2 km**, 2+2 lanes, with traffic.
  - Yangon Loop: 12.8 km (20,500 studs). It starts and ends at the roundabout.
  - New Road ("new roasd"): 2.8 km.
  - University Avenue ("more roads"): 1.6 km.
- **Streets: 30, 17.7 km**, 1+1 lanes, no traffic. 16 are big real roads (Inya Road, Insein Road, Saya San Road and so on) and 14 are real streets.
- **Junctions: 44**, 28 of them on main roads. Most have 3 arms.
- **Slopes:** main roads never steeper than 2.3%, streets 2.8%. Flyover ramps are 8%.
- **Bends:** main roads 55 m or wider (88 studs). Streets 25 m or wider (40 studs).

## Decisions
1. **Scale: 1.6 studs per metre across**, the same as Monaco, so the cars, road widths and traffic numbers carry over. Heights also use 1.6 studs per metre (Monaco used 0.75 because of its mountains; Yangon is nearly flat).
2. **Road widths.**
   - Main road: 64-stud carriageway (4 lanes of 16) plus a 10-stud pavement each side: 84 studs.
   - Street: 32-stud carriageway (2 lanes of 16) plus pavements: 52 studs. This is a true 1+1 road. Monaco's streets were 64 wide with one lane each way, so `tools/riviera/Roads.luau` needs a per-road half width with kerbs and pavements.
   - No middle strip on main roads. Where the real road has two separate sides (Pyay Rd, Kabar Aye Pagoda Rd), the game road runs down the middle of them.
3. **Which real streets are built.** Inside the map there are 72 km of real streets. Game roads are about twice as wide as real ones, so only some fit. The rule:
   - every big real road (trunk, primary, secondary, tertiary) that touches the map;
   - streets 300 m or longer;
   - not within 200 m of a road already kept that runs the same way;
   - no dead ends: each street is cut back to its first and last junction;
   - no service lanes, driveways or parking aisles.
4. **Map edge.** The map is the loop, everything inside it, and 300 m outside it. Big roads that leave the map end in a short stub with a barrier and a far-city backdrop (16 road ends).
5. **Roundabout (Hanthawaddy).** 216 studs across: island 120, ring 48 wide (3 lanes), traffic anticlockwise. The real one is about 100 studs across at this scale; ours is bigger because our roads are wider. 4 arms: the loop from Pyay Rd, the loop's made-up link, Pyay Road South, Hanthawaddy Road. **U Wisara Road is left out**: the made-up link leaves the roundabout on the same line.
6. **Flyovers.** The main road runs over the top on a 64-stud deck, 14 studs above the ground (12 studs of clear height). Ramps are 8% and 139 m long (223 studs). A one-way side lane, 24 studs wide, runs at ground level on each side for the whole length. The corridor is 140 studs wide.
   - **Pyay Road Flyover:** on the loop, 1,190 m (1,910 studs), level deck 913 m. University Avenue and Hledan Road meet under it. **Insein Road** ends on Hledan Road 80 m west of the flyover, so the junction underneath has 4 arms.
   - **Kabar Aye Flyover:** the last 440 m of New Road (704 studs), level deck 161 m. New Road goes straight over the University Avenue junction and joins the loop 310 m north of it. This makes New Road 2.8 km (your line was 2.5 km). The loop itself turns at ground level under the deck and uses the two side lanes for 220 m.
7. **Ground.** Real heights (SRTM), lowest of each 180 m patch to drop roofs and trees, then smoothed over 150 m. Ground runs from 17.5 m to 38.6 m. Inya Lake's water is at 16 m and no ground is lower than 17.5 m. Roads lie on this ground, so roads that meet are always at the same height.
8. **Landmarks.** Optima (START) is on the loop 1.2 km from the roundabout. Novotel is on the loop 36 m past the south foot of the Pyay Road Flyover. MM Plaza is on the loop 150 m north of where New Road joins. All three are on the right-hand side going round from the roundabout.
9. **Where it sits in the place:** X = 30000 + x × 1.6, Z = −y × 1.6 (far from Monaco at X 14000). This is checked against what is in the place before anything is built.

## Files
In `Games/CityLegends/imports/refs/map/`:
- `ygn_road_design.png`: the picture above.
- `ygn_road_design.json`: the design in plan metres: every road as points 4 m apart (x, y, ground height, deck height), cross-sections, roundabout, flyovers, junctions, landmarks and the smoothed ground grid with the lake mask.
- `ygn_roads.json`: the same roads in world studs in the format `Roads.build` reads (8,746 samples).
Scripts: `Games/CityLegends/tools/yangon/` (d1 to d6, `make_design.py`; run order in its README).

## Not designed yet (done inside the build steps)
- The exact lane paths in the two junctions under the flyovers and round the roundabout.
- Pillar spacing, railings and ramp walls.
- Which side streets get a give-way line or a traffic light.
