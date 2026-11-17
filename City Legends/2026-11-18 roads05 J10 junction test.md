# roads05 J10 junction test (18 Nov 2026)

Sixth pass on the roads05 P1-P12 network (batch 0.5 builder). Not built into the game: the owner approves the plan first.
Full state and next steps: `Games/CityLegends/build/city_1to1/roads05_HANDOVER.md`. Before: [[2026-11-18 roads05 J9 junction test]].

## What changed (builder only, same road data as J9)
- A round corner's zone no longer reaches across a narrow street onto its far kerb. That had left a 3 m gap in a slip road's pavement at Pyay Road x University Ave.
- A street's own pavement width (1.3 m) is used where it takes over another road's pavement. The main roads' 2.5 m width had cut holes at island tips.
- Traffic islands are filled correctly: no square hole, no hollow island, and the same height as the pavement round them.
- Near a roundabout, the ground beside a road that was lowered to the ring's level is cleared down to the verge. Sule's west arms are up to 1.5 m lower than the raw height data, and the ground there would have stood over the pavement.

## Counts (before -> after)
Failed joins 0 -> 0. QA rows not worked on (no data change): mouth_short 46, mouth_over 38, kerb_cross 22, median_cross 1, deck_grade 24, deck_foot 1.

## Studio test (7 junctions, lifted 400 studs, ground not touched)
| junction | result | shot |
|---|---|---|
| University Ave x Kabar Aye | PASS | ![[2026-11-18 roads05 J10 test - University Ave x Kabar Aye.jpg]] |
| Hanthawaddy Roundabout | PASS | ![[2026-11-18 roads05 J10 test - Hanthawaddy Roundabout.jpg]] |
| Bogyoke x Pazundaung Y | PASS | ![[2026-11-18 roads05 J10 test - Bogyoke x Pazundaung Y.jpg]] |
| Pyay Road x University Ave | better: slip gap and island holes gone, all islands paved. Left: two kerbs side by side at the north-west corner, a dark streak in one island, a kerb speck | ![[2026-11-18 roads05 J10 test - Pyay Road x University Ave.jpg]] ![[2026-11-18 roads05 J10 test - Pyay island close-up.jpg]] ![[2026-11-18 roads05 J10 test - Pyay west close-up.jpg]] |
| Waizayandar x Lay Daungkan slips | FAIL: marks in 3 islands, small pavement breaks | ![[2026-11-18 roads05 J10 test - Waizayandar x Lay Daungkan slips.jpg]] |
| Sule Roundabout | FAIL: west links (real in OSM and on the satellite) still have broken kerbs | ![[2026-11-18 roads05 J10 test - Sule Roundabout (Roundabout 4).jpg]] |
| Bahan Road at Roundabout 1 | FAIL: island tip still notched (cause found, see the handover) | ![[2026-11-18 roads05 J10 test - Bahan Road at Roundabout 1.jpg]] |

Plan status: not ready for approval (3 of 7 junctions pass).
