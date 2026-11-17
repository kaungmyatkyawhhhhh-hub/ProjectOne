# roads05 J28 studio check (18 Nov 2026, GEOMETRY agent)

Main Studio "City Legends". The test was re-packed first (current builder + J28 data), asset 133014134133489 revision 200. All 17 spots were built with the no-terrain copy of YangonRoads and checked with `qaBuilt`. In Studio: `ClaudeTools.Roads` = repo (checksum 1407280218), `ClaudeTools.YangonRoads` = repo (1416678337).

## What changed
1. **Pyay Road x University Ave: Insein Road's start** (`Roads.luau`, only on the Yangon `edgeSurface` path; Monaco is unchanged).
   - Insein Road starts on the end of Pyay (Prome) Road. Pyay Road #9 lies beside it and Hledan Road #3 crosses it, at three different heights.
   - Its first cross-section was one straight line from edge to edge, so it sat 0.2 to 0.4 above the middle road: a step along the whole join.
   - Now every cross-section with a pinned edge, or inside a junction, pins its inner points too (eighths across). Each inner point sits 0.06 under the bigger road it lies on, so that road's face shows and the two faces are never in one plane.
   - Smaller roads now read the height of the face that shows.
   - Result: pyay_univ road_step 27 -> 8. The flicker probe round the join found 6,430 two-faces-in-one-plane cells between different roads before, and 5,781 now. That overlap was already there before J28; it is the next thing to fix here.
2. **Gyophyu ramp foot, west side** (`roads05_fix.py`, new step `deck_feet`).
   - The deck smoothing (J14-J16) moved the flyover's plan line up to 5 studs, but the ground road's cut stretch kept the old OSM line.
   - The crossing mouth next to the ramp foot is cut on the road's own edge, so it stood 1 to 1.5 studs off the ramp wall. That left a slit, a dip and no kerb.
   - Now the road's cut stretch takes the deck's plan (3,776 samples on all decks). mouthsim: 0 failed of 11,569.
   - Result: kunchan_gyophyu 3 / 42 -> 1 / 28 (box_hole / kerb_gap).
3. **The Studio check is now repeatable** (`YangonRoads.qaBuilt`).
   - Where two tops lie within 0.01 of each other (an overlap), the check looks at all of them and picks one by a fixed order: Kerb, then Pavement, then Road.
   - Before, it took whichever part the engine happened to return first, so the same build counted ±1-3 per spot.
   - Test: the same build of kunchan_gyophyu and of double_junction, run twice each, gave identical counts.
   - The QA agent now owns this check (its own copy, `T.qa`).

## Per spot, J27 -> J28 (box_hole / kerb_gap / road_step / pave_step / buried)

| spot | J27 | J28 |
|---|---|---|
| bahan_ring | 6 / 54 / 0 / 7 / 0 | 6 / 53 / 0 / 6 / 0 |
| deck_run | 1 / 11 / 2 / 12 / 0 | 1 / 10 / 2 / 12 / 0 |
| double_junction | 12 / 86 / 1 / 23 / 2 | 12 / 86 / 1 / 23 / 2 |
| downtown_straight | 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 |
| hanthawaddy | 5 / 11 / 0 / 0 / 0 | 5 / 11 / 0 / 0 / 0 |
| hledan_flyover | 4 / 5 / 7 / 1 / 0 | 4 / 5 / 7 / 1 / 0 |
| kunchan_gyophyu | 7 / 47 / 1 / 15 / 0 | 1 / 28 / 2 / 15 / 0 |
| lane_taper | 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 |
| long_median | 2 / 2 / 0 / 0 / 0 | 2 / 2 / 0 / 0 / 0 |
| pazundaung_y | 2 / 15 / 0 / 0 / 0 | 2 / 15 / 0 / 0 / 0 |
| pyay_univ | 5 / 25 / 27 / 15 / 2 | 5 / 25 / 8 / 15 / 2 |
| roundabout4 | 5 / 47 / 1 / 11 / 0 | 5 / 47 / 1 / 11 / 0 |
| slip_triangle | 3 / 33 / 3 / 9 / 3 | 3 / 33 / 3 / 9 / 3 |
| sule_north | 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 |
| sule_shangrila | 3 / 5 / 2 / 1 / 0 | 3 / 5 / 2 / 1 / 0 |
| univ_kabaraye | 8 / 44 / 14 / 6 / 0 | 8 / 44 / 14 / 6 / 0 |
| ycentral | 0 / 0 / 0 / 2 / 0 | 0 / 0 / 0 / 2 / 0 |
| **total** | **63 / 385 / 58 / 102 / 7** | **57 / 364 / 40 / 101 / 7** |

The owner's target is 0 on every count at all 17 spots. Not there yet.

## Shots
- `2026-11-18 roads05 J28 test - kunchan_gyophyu - gyophyu ramp foot west.jpg`: the ground arm now runs up to the ramp wall, with no slit.
- `2026-11-18 roads05 J28 test - pyay_univ - insein road start.jpg`: Insein Road's start (front) meeting Pyay (Prome) Road, with no step.

## Traced, not fixed (next pass)
- **Rounded kerb noses / double_junction kerb_gap 86:** 18 clusters. Box holes come from 1-stud slits between a corner arc's kerb chords and the next road's edge (for example round (39930, 32838) and (39941, 32839)).
- **Bahan hole strip:** a "None between two pavements" scan found 15 slot spots, for example (35387, 37898), (35406, 38080) and (35470, 38138). `qaBuilt` does not count them; worth adding as a QA rule.
- **Overlaps (item 6):**
  - Yawmingyi Street: a corner pavement wedge laps a straight pavement block at (34552, 42646).
  - pyay_univ: Hledan Road #3, the smaller road, runs right through the junction under Insein and Pyay with its slab within 0.05 of theirs. It should get no slab there, like a crossing arm.
- **slip_triangle buried 3:** Lane #15's own kerb edge at (43464, 29305) is not on Waizayandar Road, but its carriageway 1 stud in is pinned to Waizayandar (0.25 higher), so the kerb stands only 0.14-0.2 over it.
- **univ_kabaraye pave_step 6:** a small island at (34396-34402, 28831-28837) where pavement from Lane #1248, Hledan Road #3 and Islands meet 0.2-0.3 apart. They need the J26 rule: one height function per spot.
