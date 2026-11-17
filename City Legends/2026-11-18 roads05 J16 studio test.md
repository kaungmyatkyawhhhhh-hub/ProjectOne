# roads05 J16 Studio test (18 Nov 2026)

Studio test of the roads05 network in the main place "City Legends" (121430381830562). 16 spots, built one at a time with the batch 0.5 builder (`YangonRoads.stepCell`) plus the paint plan. Before: [[2026-11-18 roads05 J12 junction test]]. Full state: `Games/CityLegends/build/city_1to1/roads05_HANDOVER.md`.

**How it was built**
- **Lifted 400 studs.** Every test shot floats 400 studs above the real map, which shows far below. At real height the test roads would sit on top of the game's own road meshes and flicker.
- **No terrain writes.** The test copy of the builder sends every terrain fill to a no-op. about 7,000 fills were skipped and the place's terrain was not touched.
- **Verges show as sky.** The grass verges are terrain, so they are skipped too. The blue you see between the roads is sky, not a hole, unless the note says otherwise.
- **Painted in the test.** The paint is laid as thin parts on the built surface; the game bakes it into meshes instead. A paint triangle with no road under it is left out and counted.
- **Data used.**
  - Up to the lane taper: roads from J15 (12:45) and paint from 6abc18b7.
  - From the lane taper on: the same roads and paint from 8e86c6b0 (13:31). The copy is in `build/city_1to1/roads05_studiotest/net/`.
  - Two newer versions came in during the test and were not tested: a new roads.json from the geometry agent (13:32, not pushed yet) and paint c6d7abe0. The next pass runs on those.
- **Tools.** `tools/yangon/city/roads05_studiotest.py` (data, paint triangles, cameras, pack) and `tools/yangon/city/Roads05StudioTest.luau` (install, run, paint, pick, clean). The steps are in their headers.

**Result:** 0 MOUTH FAILED at every spot. 11 spots pass, 3 pass with notes, 2 fail.

## Pass / fail by spot and fault
Faults are the owner's list (refs `City Legends/Owner ref - *`). Key: P = pass, F = fail, n = minor note, - = not in this spot.

| spot | road gap / hole | stray or buried kerb | corner pavement | median | deck / seam | paint (zebra, stop, arrow, box) | owner ADD | overall |
|---|---|---|---|---|---|---|---|---|
| University Ave x Kabar Aye (under the flyover) | P | P | P | P | P (piers off the lanes) | P | P: full ground junction under the deck | **PASS** |
| Hanthawaddy Roundabout | P | P | P | n: a gap in the SE arm median | - | P | - | PASS (check the median gap against OSM) |
| Pyay Rd x University Ave | n: the known open gore by the deck wall | P | P | P | n: thin seam lines in the box | n: a zebra runs into the gore under the deck | P | PASS with notes |
| Sule Roundabout | P | P | P | P | n: a thin seam line | P | - | **PASS** |
| Waizayandar x Lay Daungkan | P | P | P | P | - | P (the best paint shot) | - | **PASS** |
| Bahan Rd at Roundabout 1 | **F: 2 holes where the slip meets the ring** | **F: two kerbs side by side** | **F: sawtooth nose** | P | - | P | - | **FAIL (was PASS in J12)** |
| Bogyoke x Pazundaung Y | P | P | P | P | - | n: sparse (1 zebra, no stops / arrows on 2 arms) | - | PASS with notes |
| Yangon Central (deck fork) | P | P | - | - | n: a crease where the Sule deck meets the two branch decks | P | P: two separate decks over the railway | **PASS** |
| Kun Chan x Gyophyu | P | **F: 2-3 red/white kerb stubs on the road** | P | P | n: seam lines | P | P: gore asphalt | **FAIL** |
| Double junction (East Horse Race Course x Banyar Dala) | n: an empty square (3 bridges not built, test box) | **F: a crumpled kerb scrap on the road** | **F: a loose 250-stud pavement strip** | P | - | P: one box, zebras outside it | P | **FAIL** |
| Sule Shangri-La corner | n: a dark wedge at the east arm | P | **F: small square corners** | P (barrier + nose) | - | P | **F: no sweeping radii, island, forecourt yet** | **FAIL (known, not built)** |
| Downtown straight (Sule Pagoda Rd #2) | P | P | n: wide walk on one side only | P (barrier) | - | P | n: no trees in pits | **PASS** |
| Baho Rd under the Hledan flyover | P | P | P | - | P | P | P: piers off the lanes | **PASS** |
| Shwedagon deck (climb, run, land) | P | P | - | P (paved nose) | n: a crease and a dark wedge at the landing | P | P: one width over the railway | **PASS** |
| Long straight median (Waizayandar) | P | P | - | P (n: joint lines in the grass) | - | P | - | **PASS** |
| Lane taper (Thein Phyu 3 -> 2) | P | P | - | - | - | P: no jog, no side-by-side dash | - | **PASS** |

Count: 11 pass, 3 pass with notes (Pyay x Univ, Pazundaung Y, Hanthawaddy), 2 fail on new faults (Bahan, Kun Chan), plus 2 fails already known or caused by the test (double junction's scraps are real; Sule Shangri-La is not built yet). The Sule Shangri-La radii and the double junction's missing bridges are known gaps, not new.

## Builder bugs found (for the geometry and paint agents; their files were not touched)
1. **Bahan Rd at Roundabout 1 (geometry / builder).** Two holes near (35395, 37985) and (35385, 38000), where Lane #4701 / the slip meets the ring arm. The strip between the slip and the Bahan arm has a sawtooth nose and two kerb lines side by side. This was a PASS in J12, so it is a regression from the J13-J15 data (ring_level / osm_joins / absorb near Roundabout 1?).
2. **Stray kerb pieces on the road.**
   - Kun Chan x Gyophyu: 2-3 short red/white kerb stubs inside the box, by the island nose and the zebra edge.
   - Double junction: a crumpled kerb scrap lying on the SE arm.
   - `scrub` does not catch these. kerbsim / QA `kerb_cross` should find them.
3. **Loose pavement strip.** A ~250-stud pavement band runs west from the double junction with no road beside it (Road #18 side?).
4. **Deck seams.**
   - A crease line where Sule Pagoda Rd's deck end meets the Alan Pya / Gyophyu decks (deck_butt fork).
   - A crease plus a dark wedge where the Shwedagon deck lands.
   - Thin dark seam lines across junction boxes (Kun Chan, Pyay x Univ, Sule): slab joints at slightly different heights (QA seam_step?).
5. **Sule Pagoda Rd deck before the fork is 93 studs wide** (half 41 / 52). Owner ref `Alan Pya bridge merged in game (wrong)`: the branches are separate, but the approach deck is one very wide slab. Check it against the real photo.
6. **Pazundaung Y paint is sparse.** One zebra, and no stop lines or arrows on the east and south-west approaches (paint QA `arrow_missing` / `stopline_missing`?).
7. **Pyay x University (paint).** A zebra runs into the open gore under the deck. Ground paint should stop at a ramp footprint or gore.
8. **Paint height vs the built surface.** At every spot 0-90 paint vertices (median ~20) had no built surface within 6 studs of their data height (mostly at the test box edge). At the double junction 293 deck-paint vertices sat on 3 bridges that were not built (test box). Not a game bug by itself, but worth a QA rule: paint on the surface the builder actually lays.
9. **Test-box artifact, not a bug.** `buildDecks` builds a deck only in the cell that holds its middle sample, so a test box needs to reach the deck's middle (the double junction's 3 bridges were missing).

## Shots (49, `City Legends/2026-11-18 roads05 J16 test - <spot> - <view>.jpg`)
Best for the owner:
- ![[2026-11-18 roads05 J16 test - Waizayandar x Lay Daungkan - close-up.jpg]]
- ![[2026-11-18 roads05 J16 test - University Ave x Kabar Aye - close-up.jpg]]
- ![[2026-11-18 roads05 J16 test - Double junction - driver.jpg]]
- ![[2026-11-18 roads05 J16 test - Hledan flyover over Baho Rd - driver.jpg]]
- ![[2026-11-18 roads05 J16 test - Kun Chan x Gyophyu - overview.jpg]]
- ![[2026-11-18 roads05 J16 test - Downtown straight - driver.jpg]]

Every spot has overview, close-up and driver shots (the Shwedagon deck also has a side shot). Spot names: University Ave x Kabar Aye, Hanthawaddy Roundabout, Pyay Road x University Ave, Sule Roundabout, Waizayandar x Lay Daungkan, Bahan Road at Roundabout 1, Bogyoke x Pazundaung Y, Yangon Central, Kun Chan x Gyophyu, Double junction, Sule Shangri-La corner, Downtown straight, Hledan flyover over Baho Rd, Shwedagon deck run, Long straight median, Lane taper.

## Studio state after the test
- Scratch folder `Roads05Test`, `YangonScraps` and all 27 `Roads05_*` data modules are gone.
- The paint modules were never parented to the place, and the no-terrain builder copy was never parented either.
- `ClaudeTools.YangonRoads` is the repo file (checksum 1729564226).
- Saved: "Saved new changes in City Legends" at 07:12:53Z in the Studio log.
- Studio lock released.

## Next pass
Re-run on the new roads.json (geometry agent, 13:32) and paint c6d7abe0:

    python roads05_studiotest.py <net> [paint.json]
    -> PATCH 133014134133489
    -> install, then run each spot

Then look again at Bahan, Kun Chan, the double junction (use a bigger box so its bridges are built) and Pazundaung Y.
