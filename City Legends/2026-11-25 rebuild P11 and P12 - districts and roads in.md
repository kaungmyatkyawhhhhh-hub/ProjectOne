---
tags: [city-legends, roads, roads05, rebuild]
created: 2026-11-25
---
# 24-25 Nov: P11 and P12 rebuilt and in the game (home PC)

Follows [[2026-11-24 rebuild P10 and P5 - districts and roads in]]. Same chain as P9 / P10 / P5. Nothing is published. Every step and asset id is in `build/city_1to1/rebuild_progress.json` (keys "P11" and "P12").

## P11 (Yankin, Thuwunna, Golden City; between P1, P2, P8, P9 and P10)
- **District:** 8,551 buildings (shells 10,727 parts, roof parts 5,363), 29 night window cells, terrain, grass and 1,537 far trees. The 2 pagodas that were there (on TEMP plates) were placed again on the ground.
- **Roads:** the J37 road build in 42 mesh cells (433 meshes) with 24,576 collision boxes. All four edges were rebuilt whole with the neighbour's roads: the P1 column, the P2 / P9 row, the P8 row and the P9 / P10 corner. 0 failed junction mouths.
- **Clean-up:** no terrain over the roads, 3 far tree crowns and 15 street props that stood on the new roads removed, the grass verge raised and trimmed.
- **U Chit Maung flyover:** it now has its road surface. The old dip where it meets the Banyar Dala flyover and East Horse Race Course Road is gone (the deck is level across the junction). The yellow-black barrier is removed and the deck is back in the NPC lanes. All 11 flyover feet in P11 are flush.

## Found and fixed in the bake (shared code, so P12 and every later rebuild get it)
- **Decks built twice:** the rebuild helper builds every flyover that touches its box. In a 16-box district build a flyover crossing 4 boxes was built 2-3 times and all copies were baked (5,771 doubled parts on the U Chit Maung deck: flicker and doubled walls). `roads05_bake.py` now drops exact duplicate parts. The first P11 swap had them; it was re-baked and swapped again. Check after each district: 0 duplicate boxes, 0 duplicate meshes in the swapped cells (P11: 0 / 0).
- **Tilted collision boxes:** 10 road boxes tilted 55-80 degrees (invisible walls) where the surface fit had its points on one line (at the P12 edge and two deck feet). The fit now keeps the plain box then. 17 small pavement boxes standing almost upright under the U Chit Maung deck are dropped too.

## Traffic and minimap
- **NPC lanes now cover P1 to P11:** 1,382 lanes, 3,247 links, 0 dead ends; all 28 lane modules load.
- **Minimap:** P11 in colour (25 tiles uploaded, all approved).

## Play test (test save, then back to `CityLegends_v1`, checked on the Server)
- Drove up the U Chit Maung flyover from its south foot, along the whole deck, level across the Banyar Dala junction, and down the Banyar Dala flyover to the ground. No steps; NPC cars were driving on the deck.
- Drove three ground roads across the P9, P1 and P8 edges. No steps. No script errors.

Pictures:
- ![[2026-11-24 rebuild P11 - U Chit Maung flyover deck (Play) - after.jpg]]
- ![[2026-11-24 rebuild P11 - Waizayandar Road at the P9 seam (Play) - after.jpg]]

## Saves
- P11 district v1959; road export saved; first swap v1994; after the re-swap a Team Create drop ("Lost connection") closed the place at 20:35 UTC. After a relaunch the work was there except the map art sync and barrier removal (redone). Saved 20:47 UTC, v2005 (before Play), v2007 (after Play).
- The 19:09 UTC save failed with "PublishService AssetUpload failed" (Roblox's upload side, the same minutes 4 road uploads failed); it worked 10 minutes later.

## P12
(see below)
