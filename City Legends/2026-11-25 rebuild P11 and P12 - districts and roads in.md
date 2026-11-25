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

## P12 (Thingangyun / South Okkalapa, east of P11): done 25 Nov, saved v2109
- **District:** 10,456 buildings (shells 13,426 parts, roof parts 8,346), 34 night window cells, terrain, grass, 2,716 far trees and the Shwe Oat Gu pagoda on the ground.
- **Roads:** first swapped on 25 Nov night, then paused by the lead for the road-bug fixes. Re-baked on 25 Nov with the new bake (roads cut exactly at district edges, small holes filled, the deck rules) and fresh markings (double yellow centre lines, lane dashes in step). 49 mesh cells, 429 meshes, 19,206 collision boxes; the P11 / P10 / P8 edge column rebuilt whole. 0 duplicate boxes or meshes, 0 tilted boxes.
- **Clean-up:** no terrain over the roads, no trees on them, 6 street props on the roads removed, the grass verge raised and trimmed.
- **Flyover feet:** Waizayandar (two decks), Kamarkyi Bridge, Road Flyover #4 and #5: all 9 feet flush.
- **Road-bug detector on the 49 P12 cells (first bake -> re-bake):**

| Kind | Before | After |
|---|---|---|
| Sawtooth spikes into the grass | 24 | 4 |
| Bare gaps in the road | 71 | 22 |
| Loose kerb pieces on the road | 31 | 4 |
| Median stubs | 60 | 60 |
| Median in a junction | 2 | 2 |
| Lone lane dashes | 113 | 111 |
| Yellow paint near a junction | 8 | 202 (see below) |
| Grass on the road, crossing lines, low ramp walls | 0 | 0 |

  The yellow count went up because the new markings draw the owner's double yellow centre line, and that line runs on past side-road mouths (the old paint had a white centre line). Checked on a top view: it is the centre line, not paint inside the junction.
- **Traffic:** NPC lanes now cover all of P1 to P12: 1,469 lanes, 3,465 links, 0 dead ends; all 30 lane modules load. 39 of 46 NPC cars were driving in P12 during the test.
- **Minimap:** P12 in colour (22 tiles, all approved).
- **Play test (test save):** Road Flyover #5 up and down, the Kamarkyi Bridge flyover, and two ground roads across the P11 and P10 edges. No steps, no script errors. Store put back to `CityLegends_v1` and saved v2109. Studio would not start a second Play for the Server check, so the store was read in Edit.

Pictures:
- ![[2026-11-25 rebuild P12 - Road Flyover 5 ramp foot (Play) - after.jpg]]
- ![[2026-11-25 rebuild P12 - Than Thu Mar Road at the P10 seam (Play) - after.jpg]]

## What's left
- P11 still has the bake from before the road-bug fixes, except the cells the road-bug sweep re-baked. A re-bake with the new bake would tidy its seams like P12's.
- In P12, kinds the bake can't fix: 60 median stubs, 111 lone dashes and 4 spikes at mouth notches (builder / data work in the road-bug note).
- Road Flyover #4 also lies in P8's cell 29x23 (laptop bake). It is the same deck, so it was left alone.
