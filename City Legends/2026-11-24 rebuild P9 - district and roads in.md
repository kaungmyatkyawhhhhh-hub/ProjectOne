# 24 Nov: P9 rebuilt and in the game (home PC)

P9 (north-east: Okkalapa, Parami, Thingangyun side) is now in the main place. Saved as v1853. Not published.

## What went in
- **District:** 15,622 buildings (shells 18,936 parts, roofs 11,649), night windows, terrain, grass and far trees, 4 pagodas sitting on the ground. Two old pagodas were moved to `ServerStorage.RB_OldP9.Temps`.
- **Roads:** the J37 road build for P9, baked into 42 mesh cells with 16,513 collision boxes. The column on the P2 edge was rebuilt whole, so the seam matches. 0 failed junction mouths.
- **Clean-up after the swap:** terrain over 26 road boxes cleared (re-check 0), 20 street props that stood on the new roads removed, 3 far tree crowns on roads taken out, grass verge raised and trimmed along every pavement.
- **Traffic:** NPC lanes for P1-P4 and P6-P9 (1,227 lanes, 0 dead ends). Lane heights follow the built roads. All 23 lane modules load.
- **Minimap:** P9 is in colour. 73 new tiles, all approved (tile `d_0_0` too).
- **Flyover feet:** Parami, Pinlon and Nga Moe Yeik Bridge flyovers: all 6 feet flush with the road.

## Play test (test save, then put back to `CityLegends_v1` and checked in a fresh Play)
- Drove up 3 flyovers and 4 ordinary P9 roads. The car stayed on the road with no steps or bumps.
- One run stopped in an NPC traffic queue on the Nga Moe Yeik flyover. That is traffic, not a road fault (picture).
- No script errors from the new lanes or minimap. One fresh minimap tile was still loading (HTTP 502) in Play. It was approved and should show after a short wait.

Pictures:
- `2026-11-23 rebuild P9 - Parami Road flyover ramp (Play) - after.jpg`
- `2026-11-23 rebuild P9 - Nga Moe Yeik bridge flyover (Play) - after.jpg`

## P10 and P5: offline work done, Studio not started
- **P10:** 11,960 buildings. Packs are in `imports/sync/ygn1to1_p10/`, and the road data is in `imports/sync/rebuild_RB10_data.rbxmx`. Nothing is uploaded yet.
- **P5:** 3,166 buildings. Packs are in `imports/sync/ygn1to1_p5/`, and the road data is in `imports/sync/rebuild_RB5_data.rbxmx`. Nothing is uploaded yet.
- **Next:** the same Studio steps as P9, P10 first. Every step and asset id is in `build/city_1to1/rebuild_progress.json`.
