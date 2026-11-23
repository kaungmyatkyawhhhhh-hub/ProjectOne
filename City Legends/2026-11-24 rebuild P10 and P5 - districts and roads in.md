# 24 Nov: P10 and P5 rebuilt and in the game (home PC)

Both districts are now in the main place. P10 was saved as v1875 and P5 as v1883. Nothing is published.

## P10 (east of P9)
- **District:** 11,960 buildings (shells 14,671 parts, roof parts 9,876), 42 night window cells, terrain, grass and far trees, and 4 pagodas sitting on the ground.
- **Roads:** the J37 road build, baked into 49 mesh cells with 19,038 collision boxes. The column on the P9 edge was rebuilt whole, so the seam matches. 0 failed junction mouths.
- **Clean-up after the swap:** no terrain over the roads, no street props on the new roads, and 1 far tree crown on a road taken out. The grass verge was raised and trimmed along every pavement.
- **Flyover feet:** Lay Daungkan, No. 2 Main Road, Bayint Naung and Nga Moe Yeik Bridge flyovers: all 8 feet are flush.

## P5 (west of P4)
- **District:** 3,166 buildings (shells 3,995 parts, roof parts 2,358), 25 night window cells, terrain, grass and far trees.
- **Roads:** the J37 road build, baked into 33 mesh cells with 7,932 collision boxes. The column on the P4 edge was rebuilt whole. 0 failed junction mouths.
- **Clean-up after the swap:** terrain over 3 road boxes cleared, and 6 street props that stood on the new roads removed (walls and a power pole). No trees on the roads. The verge was raised and trimmed.
- **Flyover feet:** Bayint Naung Bridge 2, Thamaing Station Road (two decks) and Baho Road #2 flyovers: all 8 feet are flush.

## Traffic and minimap
- **NPC lanes now cover P1 to P10:** 1,322 lanes with 0 dead ends. Lane heights follow the built roads, and all 26 lane modules load.
- **Minimap:** P5 and P10 are in colour. Adding P5 moved the map grid west, so all 81 detail tiles were uploaded again. All are approved.

## Play test (test save, then put back to `CityLegends_v1` and checked in a fresh Play)
- **P10:** drove up 5 flyover feet and 4 ordinary roads. The car stayed on the road with no steps. On the Nga Moe Yeik flyover the car drifted to the side (the same as the P9 test), but it did not drop.
- **P5:** drove up 5 flyover feet and 4 ordinary roads, including the rebuilt P4 edge. No steps.
- No script errors in the log.

Pictures:
- `2026-11-24 rebuild P10 - Lay Daungkan Road flyover (Play) - after.jpg`
- `2026-11-24 rebuild P10 - No. 2 Main Road flyover ramp (Play) - after.jpg`
- `2026-11-24 rebuild P5 - Thamaing Station Road flyover (Play) - after.jpg`
- `2026-11-24 rebuild P5 - Baho Road at the P4 seam (Play) - after.jpg`

## What's left
- **P11 and P12** are not in the game yet. Building P11 also lets the U Chit Maung deck get its road surface, so its barrier can come out.
- Every step and asset id is in `build/city_1to1/rebuild_progress.json` (keys "P10" and "P5").
