# Prompt: remove 8 Starter and Mid cars from the game

_For Claude Code. Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras._

## The cars to remove (owner, 2026-11-03)
**Starter (3):**
- `toyoka_crown`: Apex Crowne Athlete
- `byt_seal`: Dream-Build Volt Seal EV
- `mazdo_rx8`: Ahura RX-8

**Mid (5):**
- `bnw_530i`: Bavarica Werkz 530i G30
- `bnw_330i_g20`: Bavarica Werkz 330i M Sport
- `bnw_m3_e92`: Bavarica Werkz M3 E92
- `bentz_cla45`: Tri-Star Silber CLA 45
- `chevo_c6`: Golden Corvette C6

**The owner chose to keep** (don't remove): Land Cruzer 200, 540i, M5 F10, M6 V10, X6 M Sport, M8 Gran Coupe, E400, S63 W221, GLE 53, CLS 63 S, LX700, Hemi SRT, and every car not in the list above. The game goes from 80 to **72 cars**.

## Before you start
- Read `CLAUDE.md`, `Games/CityLegends/CLAUDE.md` and `City Legends/City Legends.md`.
- Search the whole code for each id before removing it. Cars are used in many places:
  - `Cars.lua` (roster, `Cars.Series` trim ladders, `REAL_WB`, levels);
  - `CarBuilder` / `CarMesh` (`DESIGNS`, `DIM_OVERRIDES`);
  - `CarSkin` (cabin donors, `STEER_DONOR`, `CLUSTER_RECT`, `KEEP_OWN_CLUSTER`, `CABIN_RECOLOUR`...);
  - `DialLooks`, `BrandMarks`, `TailLights`, `DashGauges`;
  - `Config` (dealership display, starter-car choices, traffic, market);
  - the car market;
  - challenges;
  - tests.
- **Careful with donors:** other cars may borrow a removed car's cabin or steering wheel (for example `bentz_cla45` and `bnw_x6` appear in donor tables). If a kept car uses a removed car's model as a donor, keep that model in `CarModels` as a donor only (not sold), or move the kept car to another donor, and check it still looks right.

## What to do
1. Take the 8 cars out of the **dealer, the roster, the market listings, the starter-car pick, traffic and the dealership display**.
2. **Fix the trim ladders** (`Cars.Series`) so they still make sense with the cars left, e.g. 5 Series: 540i → M5 E60 → M5 F10 → M5 F90. Show the owner the new ladders and levels.
3. **Players who already own a removed car:** they **keep it** (it stays in their garage and still drives) but it can't be bought any more. The save must not break. If keeping is not possible for a car, **refund its price** in cash and tell the owner which ones.
4. Remove the now-unused models from `CarModels` and the import files only if no kept car uses them (see donors). Keep `assets/CarModels.rbxm` in step.
5. Update the notes (`City Legends/City Legends.md`) with the removed list.

## Check before you say done
- Play-test: the dealer shows 72 cars, ladders look right, the starter pick works, traffic spawns fine, the market has no removed cars, an old save that owns a removed car still loads and can drive it.
- No console errors. Search the code again for each removed id: nothing left except the "owned legacy cars" handling.
- Lune tests (`market_test` too) and `luau-lsp analyze` clean.
- Commit and push; save the place.

## When done, tell the owner (short)
- the removed list;
- the new trim ladders;
- what happens to players who owned them.
