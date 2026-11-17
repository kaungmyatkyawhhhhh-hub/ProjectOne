# roads05 J12 junction test (18 Nov 2026)

Eighth pass on the roads05 P1-P12 network (batch 0.5 builder). Not built into the game: the owner approves the plan first.
Full state and next steps: `Games/CityLegends/build/city_1to1/roads05_HANDOVER.md`. Before: [[2026-11-18 roads05 J11 junction test]].

## What changed
- Bahan: where the slip lane merges into Kan Yeiktha, the round corner's kerb was deleted near its end. Kan Yeiktha is very wide and bends; the check treated it as a smooth curve while the road is built from straight pieces, so the kerb looked "1 stud on the road". A corner's own kerb is no longer deleted against its own road. Its pavement height now comes from the built road, not the cut part next to the roundabout (it was 4 studs low).
- Sule: the "seam" was a crease. A cross street 30 studs from the roundabout kept its old height, so Maha Bandula Road dropped 0.7 studs in its last 4 studs. Roads round a roundabout are now flat out to 40 studs past it, then ramp.
- A round corner whose curve runs onto the other road is made shorter.
- Tried and undone: a smaller limit on big merge curves (it opened a 30-stud kerb gap), and running dead street ends on to OSM joins (it fixed no QA rows).

## Counts (before -> after)
Failed joins 0 -> 0. QA rows unchanged: mouth_short 46, mouth_over 38, kerb_cross 22, median_cross 1, deck_grade 24, deck_foot 1. Each mouth row was checked against OSM (`qa_J12_osm.json`): 33 are real OSM dead ends (explained), 49 are OSM joins still to fix, 2 do not sit on an OSM end.

## Studio test (7 junctions, lifted 400 studs, ground not touched, final build)
| junction | result | shots |
|---|---|---|
| Bahan Road at Roundabout 1 | PASS: kerb continuous through the merge | ![[2026-11-18 roads05 J12 test - Bahan Road at Roundabout 1.jpg]] ![[2026-11-18 roads05 J12 test - Bahan slip end close-up.jpg]] |
| Sule Roundabout | PASS: seam and wedges gone | ![[2026-11-18 roads05 J12 test - Sule Roundabout.jpg]] ![[2026-11-18 roads05 J12 test - Sule Roundabout west close-up.jpg]] |
| Hanthawaddy Roundabout | PASS | ![[2026-11-18 roads05 J12 test - Hanthawaddy Roundabout.jpg]] ![[2026-11-18 roads05 J12 test - Hanthawaddy west close-up.jpg]] |
| Waizayandar x Lay Daungkan slips | PASS | ![[2026-11-18 roads05 J12 test - Waizayandar x Lay Daungkan slips.jpg]] ![[2026-11-18 roads05 J12 test - Waizayandar islands close-up.jpg]] |
| Bogyoke x Pazundaung Y | PASS (tiny notch on a pavement's back edge) | ![[2026-11-18 roads05 J12 test - Bogyoke x Pazundaung Y.jpg]] ![[2026-11-18 roads05 J12 test - Bogyoke x Pazundaung Y close-up.jpg]] |
| Pyay Road x University Ave | PASS with notes: the "gap" by the flyover wall is the open gore between two roads that split, which grass fills in the game (the test has no ground). A 1-stud notch on a pavement's back edge | ![[2026-11-18 roads05 J12 test - Pyay Road x University Ave.jpg]] ![[2026-11-18 roads05 J12 test - Pyay islands close-up.jpg]] |
| University Ave x Kabar Aye | NOT clean: a 1-stud hole between a slip's kerb and the west island (also in the J11 shot); 4 slip lanes end 6-7 studs beside the flyover's side roads (OSM joins them; they need a merge taper) | ![[2026-11-18 roads05 J12 test - University Ave x Kabar Aye.jpg]] ![[2026-11-18 roads05 J12 test - University Ave x Kabar Aye close-up.jpg]] |

Plan status: not ready for approval (6 of 7 junctions pass; 49 QA rows still to fix).
