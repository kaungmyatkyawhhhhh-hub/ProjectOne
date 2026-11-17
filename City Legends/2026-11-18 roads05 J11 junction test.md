# roads05 J11 junction test (18 Nov 2026)

Seventh pass on the roads05 P1-P12 network (batch 0.5 builder). Not built into the game: the owner approves the plan first.
Full state and next steps: `Games/CityLegends/build/city_1to1/roads05_HANDOVER.md`. Before: [[2026-11-18 roads05 J10 junction test]].

## What changed (builder only, same road data as J9)
- Width tests now use the road's half on the side being checked. Many roads are lopsided (Maha Bandula Road is 24 m on one side and 13 m on the other), and the wider half had cut kerbs short at Sule and deleted a corner kerb at the slip triangle.
- A short slip lane's two round corners no longer claim the same kerb. At Pyay the two kerbs that ran side by side are gone, and the merge corner was shortened, not removed.
- A traffic island is one paved surface now. Each road's pavement used to pave its own strip of the island at its own height, which left the dark streaks and holes.
- "This road keeps its own pavement past the corner" now stops at the road's next junction and at bigger roads. That had left pavement teeth and a kerb speck at Pyay, and removed 32nd Street's kerb at Sule.
- The Bahan island tip gets its round corner even where the slip meets Bahan Road inside the roundabout's zone.

## Counts (before -> after)
Failed joins 0 -> 0. QA rows (no data change): mouth_short 46, mouth_over 38, kerb_cross 22, median_cross 1, deck_grade 24, deck_foot 1.

## Studio test (7 junctions, lifted 400 studs, ground not touched)
| junction | result | shots |
|---|---|---|
| University Ave x Kabar Aye | PASS (one thin sliver by the deck to check) | ![[2026-11-18 roads05 J11 test - University Ave x Kabar Aye.jpg]] ![[2026-11-18 roads05 J11 test - University Ave x Kabar Aye close-up.jpg]] |
| Hanthawaddy Roundabout | PASS | ![[2026-11-18 roads05 J11 test - Hanthawaddy Roundabout.jpg]] ![[2026-11-18 roads05 J11 test - Hanthawaddy west close-up.jpg]] |
| Bogyoke x Pazundaung Y | PASS | ![[2026-11-18 roads05 J11 test - Bogyoke x Pazundaung Y.jpg]] ![[2026-11-18 roads05 J11 test - Bogyoke x Pazundaung Y close-up.jpg]] |
| Waizayandar x Lay Daungkan slips | PASS: island marks and pavement breaks gone | ![[2026-11-18 roads05 J11 test - Waizayandar x Lay Daungkan slips.jpg]] ![[2026-11-18 roads05 J11 test - Waizayandar islands close-up.jpg]] |
| Pyay Road x University Ave | better: side-by-side kerbs, streak and speck gone. Left: a tiny gap by the deck wall, a small kerb step | ![[2026-11-18 roads05 J11 test - Pyay Road x University Ave.jpg]] ![[2026-11-18 roads05 J11 test - Pyay north-west close-up.jpg]] ![[2026-11-18 roads05 J11 test - Pyay islands close-up.jpg]] |
| Bahan Road at Roundabout 1 | better: island tip rounded, loose pieces gone. Left: a kerb notch where the slip merges into Kan Yeiktha | ![[2026-11-18 roads05 J11 test - Bahan Road at Roundabout 1.jpg]] ![[2026-11-18 roads05 J11 test - Bahan slip end close-up.jpg]] |
| Sule Roundabout | better: the island's 32nd Street kerb is back. Left: a seam line by the ring, two small dark wedges | ![[2026-11-18 roads05 J11 test - Sule Roundabout west close-up.jpg]] |

Plan status: not ready for approval (4 of 7 junctions pass).
