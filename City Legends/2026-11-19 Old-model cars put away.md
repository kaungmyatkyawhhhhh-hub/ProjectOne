---
tags: [city-legends, cars, models]
created: 2026-11-19
---
# Old-model cars put away (19 Nov 2026, evening)

Owner: "remove all of the old model cars in the game rn and put them somewhere because only new model cars are supposed to be in the game".

## What was done (Studio, saved v1623; not published)
- **50 old models moved** from `ReplicatedStorage.CarModels` to the new folder **`ServerStorage.OldModelCars`** (nothing deleted). 61 models stay.
- **75 cars on sale**, none on an old model. The old-model cars are hidden with the existing `Pending` flag, from one list: `Cars.OLD_MODELS` in `src/shared/Cars.lua` (47 model ids; trims and cars on the same body follow).
- **Free car is now the Apex AE86** (`Cars.StarterId = "toyoka_ae86"`), because the Voltra (`kio_ev6`) is an old model.
- **Owners keep their old cars in the save.** They stay inside the saved `Owned` list; the game holds them back as `Shelved` (in memory only) until the id leaves `Cars.OLD_MODELS`. **Never add a separate saved list**: older code and an undo would drop the cars.
- Also changed: dealership turntables show new-model cars, the police car body is the JZX100, the chauffeur phone lists 6 cars (not the Rocket G, Nocturne, Grandeur), a car off sale can't be delivered from the market stash, the free car can't be sold before the first-car pick, a tower turntable never shows a shelved car.
- Scripts changed (repo + Studio, same text): `shared/Cars`, `shared/Config` (198,821 bytes), `server/PlayerData`, `server/Market`, `server/Care`, `server/Towers`. Tests: carlevels, goals, care updated; all pass except market_test's 1 failure that was there before.

## Moved models (50)
On sale before (36): astin_db9 astin_vantage bentz_190e bentz_cls63s bentz_e400 bentz_g63 bentz_gle53 bentz_gt63s bentz_s63 bentz_s65_w221 bnw_540i bnw_750li bnw_m3_f80 bnw_m6_v10 bnw_m8gc bnw_x6 bnw_x7 brabos_g63 byt_u8 chevo_c7 chevo_camaro dodger_challenger ferrara_f430 kio_ev6 lexis_lc500 lexis_lx700 maseroti_levante mazdo_rx7 nisun_r34 porsha_boxster porsha_panamera rolls_cullinan rolls_wraith toyoka_camri toyoka_lc200 xiaomo_su7
Retired (10): bentz_cla45 bentz_e300 bnw_530i byt_seal chevo_c6 lambrini_urus mazdo_rx8 suzaki_swift toyoka_belta toyoka_crown
Old cabin donors and a spare (4): bnw_m3_e92_cabin bentz_c63c ferrara_458s ferrara_458

**Kept on purpose (2 old models):** `toyoka_alfard` (the YBS job van; no new van exists) and `toyoka_lc300` (only as that van's steering wheel). Neither is sold.

## Choices made for the owner (each has a one-line switch)
1. **Traffic NOT changed.** Over half the everyday NPC traffic are light copies of old bodies (Swift, Belta, Camri, Crown, Alfard, LC200, Seal, LC300, LX700, plus the R34 racer). Left alone because the owner asked for exactly these the same day. Switch: move those `Traffic_*` templates out of `ReplicatedStorage.TrafficModels`.
2. **No cheap first car any more.** Cheapest car on sale is the AE86 ($110,000), then $160,000. Before: an $18,000 van at minute 0. Switch: take `toyoka_alfard` off `Cars.OLD_MODELS`.
3. **Paid things frozen, no refund:** chauffeur contracts for the Rocket G, Nocturne, Grandeur; shelved cars can't be sold; the cheapest tow car on sale is now $460,000.
4. **Free car changed** from the Voltra to the AE86.
5. "Old" = not in the game's own new-model list (`CarFinish.NEW`). That includes the 9 doubtful ones (kio_ev6, toyoka_lc200, bnw_m6_v10, porsha_boxster, astin_db9, astin_vantage, lexis_lc500, ferrara_f430, mazdo_rx7).
6. `pleiad_gc8` set to Pending: its model is not in Studio.
7. Not kept for owners: which car was selected, and custom plate fittings (the plate stays in the bag).

## Undo
- Models: `for _, m in game.ServerStorage.OldModelCars:GetChildren() do m.Parent = game.ReplicatedStorage.CarModels end`
- Code: empty `Cars.OLD_MODELS`, `StarterId` back to `kio_ev6`, the 4 Config lines back (or `git revert` the commit) and sync the 6 scripts. Every shelved car is back on the next load.
- To bring ONE car back: import its new model as `CarModels.<id>`, take its id off `Cars.OLD_MODELS`.

## Found on the way
- **Studio was saved with the TEST save store** (`PlayerData.storeName = "CityLegends_test"`), left by the power cut. Must be `CityLegends_v1` before any publish.
