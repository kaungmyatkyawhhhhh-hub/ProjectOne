# Prompt: move fun cars into the Starter tier (and add the A45 S)

_For Claude Code. Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. Do this together with `Remove 7 starter and mid cars.md`._

## What the owner wants (2026-11-03)
Make the start of the game more fun: move these cars from **Mid** down to **Starter**:
- `bnw_540i`: Bavarica Werkz 540i G30 (a fast sports sedan);
- `chevo_camaro`: Golden Camaro ZL1 (a muscle car);
- `toyoka_chaser`: Apex Chasor Tourer V (a drift sedan).

**And add one new car to Starter (owner, 2026-11-03):**
- **Tri-Star Silber A45 S** (a hot hatch, inspired by the Mercedes-AMG A45 S; fictional name, no badges). New id e.g. `bentz_a45s`. It replaces the CLA 45 (which is being removed) as the small fast Tri-Star Silber.
  - Starter tier, a price in the same range (about $45K–55K), AWD, a punchy 4-cylinder turbo feel; put it in a sensible series (its own, or the start of a Tri-Star Silber ladder). Show the owner the numbers first.
  - **3D model:** the owner will send one (or Claude Code finds a good, clean, legal one on Sketchfab / the Creator Store and shows it to the owner first). Convert it with the new-model routine (`Better car models and clean interiors.md`, Part 3: own cluster, logos covered, quality checklist). Until the model is in, the car isn't sold (don't show a blocky placeholder).
  - Real wheelbase in `CarBuilder.REAL_WB` (about 2.73 m).

## What to do
1. Set their `Tier = "Starter"` in `Cars.lua`, with Starter prices that fit the ladder (suggest about **$40K–60K**; e.g. Chasor $40K, Camaro $48K, 540i $55K). **Show the owner the prices and the level each needs before saving.**
2. Keep their driving feel exciting, but balanced against the other Starter cars (top speed / acceleration from `Cars.lua` and `CarStats`); they should be the fun "goal" cars of the Starter tier, not faster than Mid cars.
3. **Fix the trim ladders** (`Cars.Series`) after the move: the 540i heads the 5 Series ladder (540i → M5 E60 → M5 F10 → M5 F90), so the ladder starts in Starter and goes up into Mid. Make sure the levels per step still work.
4. **Starter-car pick for new players** (`Config.Menu.StarterChoices`): it currently includes `byt_seal`, which is being removed. Replace it so the 3 choices are fun. Suggested: **Chasor Tourer V** ("drifts easily"), **Camaro ZL1** ("loud and fast"), **Horizon 350Z** ("grippy sports car"). **Ask the owner** which 3 they want before changing it (the Swiff and Belto are being removed too, so none of the 3 can be them).
5. Anything that reads the tier (dealer menu tabs, the market, traffic mix, Customs price multiplier `TierMult`, goals like "own 5 Starter cars", the store's Starter Pack) still works.
6. Players who already own these cars keep them. No refunds needed.

## Check before you say done
- Dealer menu: the 3 cars show under Starter with the new prices; the 5 Series ladder reads right.
- A new save: the starter pick shows the 3 chosen cars and gives the picked one once.
- No console errors; Lune tests and `luau-lsp analyze` clean.
- Commit, push, save the place, note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- the new Starter list with prices;
- the starter pick;
- anything that changed in the ladders.
