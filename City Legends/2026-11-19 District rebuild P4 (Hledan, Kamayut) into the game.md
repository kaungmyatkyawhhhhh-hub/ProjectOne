# District rebuild P4 into the game (19 Nov 2026)

P4 (Hledan, Kamayut, Insein Road, Pyay Road west side) is now in the main place, with the J37 roads.

**What went in**
- Buildings, trees and walls were cleared again against the J37 roads: 11,209 buildings, 14,113 shells, 7,259 roof parts and 3,932 far-tree parts.
- Terrain (1,554 tiles) and 4 pagodas.
- Roads: 52 road cells (476 meshes) and 23,906 collision boxes. The edge column shared with P1 and P2 was rebuilt whole.
- Traffic lanes now cover P1, P2, P3, P4 and P7: 923 lanes, no dead ends.
- The minimap shows P4 in colour.

**Play test: PASS** (test save, then put back on the live save)
- The car drove these roads on the road boxes: Insein Road, Parami, Hanthawaddy, Baho, Bayint Naung, Pyay Road and Hledan Road.
- Both Hledan flyover ramps were driven up from the ground road with no bump.
- Traffic: all 28 traffic cars were on the road.
- No script errors.

**Fixed along the way**
- **Flyover starting in the air** ([[Owner ref - flyover deck starts in the air (gap at the foot).webp]]): the road builder kept old height data from the ground roads when it built the flyovers. Two Hledan flyovers started 1.5 and 4 studs above the road. The builder is fixed, and that road cell was rebuilt. Shot: [[2026-11-19 Flyover foot fixed - Hledan Road Flyover.jpg]].
- **No menu and no traffic in Play**: a Burmese street name in the new traffic data was saved in a form the game can't read. The data writer is fixed and every traffic file was load-tested.
- 132 road boxes had terrain over them. That terrain was carved off.
- 31 invisible wall pieces and 17 props stood on the new roads. They were removed.

**Not done**
- The same flyover fault exists in P3 (Khayaypin flyovers, Lanmadaw flyover). Those 3 road cells need rebuilding.
- One junction mouth failed in the Hledan build (Lane #1255 on Lane #7606).
- The grass verge beside the new roads is done for part of P4 only.
- The edge cells next to P5 and P6 hold only P4 roads. They get rebuilt with P5 and P6.

Studio restart recommended (memory 13-17 GB).

Pictures:
- [[2026-11-19 rebuild P4 - Hledan flyover foot - after.jpg]]
- [[2026-11-19 rebuild P4 - Hledan junction aerial - after.jpg]]
- [[2026-11-19 rebuild P4 - Insein Road - after.jpg]]

Steps, ids and traps: `Games/CityLegends/build/city_1to1/roads05_HANDOVER.md` "REBUILD P4" and `rebuild_progress.json`.
Next: the rest of the P4 verge, the P3 flyover cells, then P6 and P8.
