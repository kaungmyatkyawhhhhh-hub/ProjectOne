# roads05 J7 junction test (17 Nov 2026)

Third pass on the roads05 P1-P12 network (batch 0.5 builder). Not built into the game: the owner approves the plan first.
Full state and next steps: `Games/CityLegends/build/city_1to1/roads05_HANDOVER.md`.

## Counts (before -> after)
| check | before | after |
|---|---|---|
| failed joins (mouthsim = Studio "MOUTH FAILED") | 20 | 0 |
| mouth_edge | 27 | 0 |
| kerb_cross | 552 (rough rule) | 22 (builder's own rule) |
| mouth_short | 89 | 46 |
| mouth_over | 50 | 38 |
| median_cross | 3 | 1 |
| overlap (doubled roads) | 10 | 0 |
| paint_off / zebra_median / stack_paint | 438 / 129 / 89 | 0 / 0 / 0 |

Two joins are square ends under a flyover on purpose (Road #20 under the U Chit Maung bridge, Thamaing Station Road under
Bayint Naung Bridge 2).

## What changed
- One flyover deck per raised stretch: Lay Daungkan Road had one 12 km "deck" over every ground junction between its two
  real bridges (that made the slip-road gaps at Waizayandar).
- Doubled carriageways (two OSM lines whose widths overlap) merged into the bigger road.
- Every join the builder would fail gets the smallest fix its own edge walk accepts.
- Paint never off the asphalt, never on a median, never two markings on one spot.
- Builder: ring corner kerbs used the wrong roundabout's centre; arm kerbs could stay on the ring carriageway.

## Studio test (7 junctions, roads lifted 400 studs; the ground terrain was not touched)
| junction | result | shot |
|---|---|---|
| University Ave x Kabar Aye | PASS | ![[2026-11-17 roads05 J7 test - University Ave x Kabar Aye.jpg]] |
| Hanthawaddy Roundabout | small kerb points where arms meet the ring | ![[2026-11-17 roads05 J7 test - Hanthawaddy Roundabout.jpg]] ![[2026-11-17 roads05 J7 test - Hanthawaddy ring kerb close-up.jpg]] |
| Pyay Road x University Ave | hole fixed; small pavement breaks | ![[2026-11-17 roads05 J7 test - Pyay Road x University Ave.jpg]] |
| Sule Roundabout | loose ring kerbs fixed; tiny pavement points | ![[2026-11-17 roads05 J7 test - Sule Roundabout (Roundabout 4).jpg]] |
| Waizayandar x Lay Daungkan slips | gaps fixed; islands unpaved | ![[2026-11-17 roads05 J7 test - Waizayandar x Lay Daungkan slips.jpg]] |
| Bahan Road at Roundabout 1 (new) | FAIL: sawtooth kerbs on the slip by the ring | ![[2026-11-17 roads05 J7 test - Bahan Road at Roundabout 1.jpg]] |
| Bogyoke x Pazundaung Y (new) | small gore with no slab | ![[2026-11-17 roads05 J7 test - Bogyoke x Pazundaung Y.jpg]] |

Earlier tests had left grass terrain in the main place outside the built map (Pyay x University Ave, the slip triangle);
it was removed. Overlays regenerated: `Road plan - P1 .. P12 overlay.png` and 7 `Road plan - Close-up ...` pictures.

Plan status: not ready for approval yet (1 junction fails, 5 have minor marks; see the handover's Next list).
