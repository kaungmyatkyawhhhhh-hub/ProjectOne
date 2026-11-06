# Prompt: one Urus only (the Performante model, no trim) and only two 458s

_For Claude Code on the PC, with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras._

## What the owner wants (2026-11-06)
"The current Urus Performante in the game will be the one and only Urus, with no trim, and remove 'Performante' from the Urus name. Remove the 458 Italia: there will only be the 458 Spider and 458 Speciale."

## 1. One Urus
Now (`Games/CityLegends/src/shared/Cars.lua`):
- `lambrini_urus` = "Enfurecido Brava": the **old** model, $1.5M;
- `lambrini_urusp` = "Enfurecido Brava Sport": the **new** Urus Performante model (new-model routine), $1.9M;
- they share the series "ENFURECIDO BRAVA" (`Ids = { "lambrini_urus", "lambrini_urusp" }`).

Change to:
- **The only Urus = `lambrini_urusp`** (the new Performante model), renamed **"Enfurecido Brava"** (no "Sport", no "Performante", no trim word). Keep its stats, class and $1.9M price.
- **Its series has only that car:** `{ Name = "ENFURECIDO BRAVA", Ids = { "lambrini_urusp" } }`, and **no trim steps** (no SPORT / TOP ladder: set `NoTrims` or whatever stops the trims for it).
- **The old `lambrini_urus`:** off sale everywhere (dealer, market, rewards, spin wheel, store, starter lists, `Config` price / order lists like the one at `Config.lua` "Order = { ... lambrini_urus ... }"), and **players who own it get `lambrini_urusp` instead** (swap it in their saves on load, keeping the car's level, XP, CP, parts and Customs looks; if they own both, keep the better one's progress and give the difference in CP). After the swap nobody has two Urus.
- Search the whole game for "Brava Sport", "Urus" and "Performante" in names players can see (dealer, garage, market, Customs, notes in UI) and fix them. `CarSkin.lua`'s internal donor / cabin names can stay.
- Check `CarFinish.NEW` still has `lambrini_urusp`, so it keeps the new-model looks.

## 2. Only two 458s
- `ferrara_458` (the 458 Italia, "Rosso Rampante F142") is already in `Cars.RETIRED` (owner, 2026-11-05). Make sure it's **gone from sale everywhere** (dealer, market, rewards, spin wheel, any lists) and that the old **"ROSSO RAMPANTE F142 COUPE"** series doesn't show anywhere to new players.
- Owners of the 458 Italia keep it (retired cars stay in garages), same as other retired cars.
- The **F142 line** for sale = **F142 Spider** (`ferrara_458spider`) and **F142 Speciale** (`ferrara_458speciale`) only, in that order.

## Check before you say done
- Dealer: one "Enfurecido Brava" (the new model, no trims); the F142 line shows only Spider and Speciale.
- A test save that owns the old Urus: after joining it owns the new Brava with its level, parts and paint; one that owns both ends up with one.
- Market, spin wheel, rewards: no old Urus, no 458 Italia.
- Lune tests (add the Urus save swap to `tools/carlevels_test.luau`) and `luau-lsp analyze` clean; no errors.
- Save the place, commit, push; note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- done, how many owners were moved to the new Urus (if known), screenshots of the dealer's Brava and F142 line.
