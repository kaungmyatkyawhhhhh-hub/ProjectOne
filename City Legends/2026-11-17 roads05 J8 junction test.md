# roads05 J8 junction test (17 Nov 2026)

Fourth pass on the roads05 P1-P12 network (batch 0.5 builder). Not built into the game: the owner approves the plan first.
Full state and next steps: `Games/CityLegends/build/city_1to1/roads05_HANDOVER.md`. Before: [[2026-11-17 roads05 J7 junction test]].

## What changed
- A slip road that passes a roundabout without joining it (Lane #4701 by Roundabout 1) is moved out up to 2 m, so its kerb no longer runs inside the ring's pavement (that was the sawtooth).
- A road that carries on from another road's end now starts on that end's full width (the grass gap in the Bogyoke x Pazundaung Y is road now).

## Counts (before -> after)
Failed joins 0 -> 0. QA unchanged: mouth_short 46, mouth_over 38, kerb_cross 22, median_cross 1, deck_grade 24, deck_foot 1; mouth_edge, overlap and all paint checks 0.

## Studio test (7 junctions, lifted 400 studs, ground not touched)
| junction | result | shot |
|---|---|---|
| University Ave x Kabar Aye | PASS | ![[2026-11-17 roads05 J8 test - University Ave x Kabar Aye.jpg]] |
| Bogyoke x Pazundaung Y | PASS (gore filled) | ![[2026-11-17 roads05 J8 test - Bogyoke x Pazundaung Y.jpg]] |
| Bahan Road at Roundabout 1 | better: sawtooth gone; notched island nose | ![[2026-11-17 roads05 J8 test - Bahan Road at Roundabout 1.jpg]] ![[2026-11-17 roads05 J8 test - Bahan slip nose close-up.jpg]] |
| Hanthawaddy Roundabout | small kerb points at the arms (not fixed yet) | ![[2026-11-17 roads05 J8 test - Hanthawaddy Roundabout.jpg]] |
| Sule Roundabout | tiny points at the arms (not fixed yet) | ![[2026-11-17 roads05 J8 test - Sule Roundabout (Roundabout 4).jpg]] |
| Pyay Road x University Ave | islands unpaved, small pavement breaks | ![[2026-11-17 roads05 J8 test - Pyay Road x University Ave.jpg]] |
| Waizayandar x Lay Daungkan slips | islands unpaved, small breaks | ![[2026-11-17 roads05 J8 test - Waizayandar x Lay Daungkan slips.jpg]] |

Satellite check: the small islands at Pyay x University Ave are paved concrete (crossings run onto them), so they will get pavement.

Plan status: not ready for approval (2 of 7 junctions pass).
