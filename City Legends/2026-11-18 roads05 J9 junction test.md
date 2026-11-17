# roads05 J9 junction test (18 Nov 2026)

Fifth pass on the roads05 P1-P12 network (batch 0.5 builder). Not built into the game: the owner approves the plan first.
Full state and next steps: `Games/CityLegends/build/city_1to1/roads05_HANDOVER.md`. Before: [[2026-11-17 roads05 J8 junction test]].

## What changed
- Roundabouts: the kerb points where arms meet the ring are gone. The cause was two one-way arms lying on top of each other at the ring (Hanthawaddy Road): the ring's kerb was drawn all the way round over every arm. Shallow ring corners now have at least a 1 m radius.
- Roads that reach a roundabout now come down (or up) to its level over about 33 m. Sule's arms met the ring up to 1.7 m higher or lower, which left steps at the edge.
- Small traffic islands are paved now (181 in the network). On the satellite they are paved concrete.
- A corner's pavement now changes width smoothly from the street's pavement to the main road's.

## Counts (before -> after)
Failed joins 0 -> 0. QA rows not worked on yet: mouth_short 46, mouth_over 38, kerb_cross 22, median_cross 1, deck_grade 24, deck_foot 1.

## Studio test (7 junctions, lifted 400 studs, ground not touched)
| junction | result | shot |
|---|---|---|
| University Ave x Kabar Aye | PASS (3 islands paved) | ![[2026-11-18 roads05 J9 test - University Ave x Kabar Aye.jpg]] |
| Hanthawaddy Roundabout | PASS (points gone) | ![[2026-11-18 roads05 J9 test - Hanthawaddy Roundabout.jpg]] |
| Bogyoke x Pazundaung Y | PASS | ![[2026-11-18 roads05 J9 test - Bogyoke x Pazundaung Y.jpg]] |
| Pyay Road x University Ave | better: islands paved; one pavement gap at a slip corner, a small hole in one island | ![[2026-11-18 roads05 J9 test - Pyay Road x University Ave.jpg]] ![[2026-11-18 roads05 J9 test - Pyay island close-up.jpg]] |
| Waizayandar x Lay Daungkan slips | better: islands paved, small holes left | ![[2026-11-18 roads05 J9 test - Waizayandar x Lay Daungkan slips.jpg]] |
| Sule Roundabout | west side still messy (32nd Street runs right beside the ring) | ![[2026-11-18 roads05 J9 test - Sule Roundabout (Roundabout 4).jpg]] |
| Bahan Road at Roundabout 1 | island tip still notched | ![[2026-11-18 roads05 J9 test - Bahan Road at Roundabout 1.jpg]] |

Plan status: not ready for approval (3 of 7 junctions pass).
