---
tags: [city-legends, map, rebuild]
created: 2026-11-20
---
# District rebuild P6 (Sanchaung, Ahlone, Kyimyindaing) into the game

**State: in the game and saved, but NOT drive-tested yet.** Not published.

## In the game (19 Nov)
- District moved in: 9,059 buildings, terrain, green, 2 pagodas.
- Roads swapped: 42 cells, 422 meshes, 21,032 boxes. Lanes for P1 P2 P3 P4 P6 P7: 1,033 lanes, 0 dead ends.
- Verge (grass edge by the roads) done over 15 tiles.

## Scheduled run, 20 Nov (nobody at the PC)
**Passed**
- Save store is `CityLegends_v1` (0 scripts with the test store). Saved v1627.
- 50 old car models in `ServerStorage.OldModelCars`, 61 in `CarModels`.
- Cars by data (in Play, server): 75 on sale, 0 old, 0 without a model. Dealer turntables hold 5 new-model cars. The job van model is still there.
- Terrain scan P6: 0 road boxes with terrain over, 0 stray terrain near flyovers.
- Deck feet: 65 ok.

**Failed / found**
- **New bug: May Ni Gone flyover, south end (29045, 35057).** An invisible pavement box (8 x 57) lies along the ramp start, 1.5 to 2.9 studs over the road. A car would hit it. Not moved (not driven yet). Fix: move that box to `ServerStorage.RB_PBoxOnDeck`, then drive it.
- Deck feet: 2 more bad = the known Road #25 valley foot (still open).

**NOT done**
- **Drive test of the 11 spots, traffic count, looking at the dealer / CARS list / turntables / YBS van.** Why: Windows was locked. A locked PC draws no frames, and the game's client only runs while frames are drawn. The car spawned on the server but the player never got in.
- After screenshots (same reason).
- Clean-up: `RB_OldP6`, `RB_PBoxOnDeck`, `MapBugScanP6` all KEPT (only deleted after a passed drive). `RB_OldR25` / `RB_OldR25B` kept.
- Kit props on roads. Minimap for P6 (needs the home PC).

## To finish
1. Be logged in, Studio on screen (not minimised, PC not locked).
2. Move the May Ni Gone box, run the drive test (steps in `rebuild_progress.json` "P6" -> "resume" and "run_20nov").
3. Then shots, clean-up, save.
