---
tags: [city-legends, economy, cars, jobs]
created: 2026-11-19
status: in Studio (main place, saved), not published
---
# City Legends: economy applied (19 Nov 2026)

The owner approved [[2026-11-19 Economy - fair car prices proposal]] (all 6 points + the "?" car decisions + the 458 changes). This is what went into the game.

## What changed
- **New prices for all 160 cars on sale**, exactly the approved table. Example: Apex Cambria $93,000, Horizon Z33 $210,000, Horizon R35 $940,000. The Orient Voltra stays free.
- **Local / Import and rarity on every car.** 74 Local (sold at Legends Motors for cash), 86 Import (crates only; 6 of them are Hypercars).
  - Owner's decisions: Import = W201 Evo II, C346 Rallye, W213 V8 S (E63). Local = Maestrale GTS, JZA80, Z100 V8, BNR34, S7, W213 3.0 (E400), R35, Brava, Nocturne, Sovereign Grand Tourer. 458 Spider = Local, 458 Speciale = Import.
  - The dealer shows an Import as **IMPORT ONLY · FROM CRATES** with its value and rarity, and a grey IMPORT button. The server refuses to sell it ("Import only: from crates"), and the car market won't deliver one either.
- **Trims.**
  - The R35 has 2 trims: **2010** (the old R35) and **Zenith** (the "2017 Nismo"-style one: 600 hp, 0-60 2.5 s, 205 mph, class S1 750, $1,700,000). Same model.
  - The E-class line is only the W213 3.0 (E400) and the W213 V8 S (E63).
  - **Deleted (19 ids):** the Sport and Top trims of the W201 Evo II, Maestrale GTS, JZA80, Z100 V8, S7, Nocturne and Sovereign Grand Tourer; the Revuelto (LB744) Sport and Top; and the old 458 Italia (`ferrara_458`) with its 2 trims. Testers who owned them lose them; their selected car falls back to one they own. No errors.
- **Class price floors:** S2 from $1.8M, R from $3.1M, X from $8.7M (every car passes).
- **Jobs:**
  - Delivery pay per stud 7 → 4. Delivery is now about $37k an hour at rank 1, near the other jobs.
  - **AFK posts:** 2x Cash no longer applies to post paychecks (Double Pay still does). Post pay stops rising after rank 3. No hotel suite income while on duty at a post.
- **Crate rules saved for later** (`CrateRules`): 30% duplicate refund from cash crates, hypercars only from crates with a pity guarantee, no airport cash buy. Premium cash crate: a Legendary at least every 8 crates, a Hypercar at least every 20 (about 200 h of a free mid player). There was no airport hypercar code to turn off.

## Tests (Studio, main place, 19 Nov)
- Lune isn't on this PC, so the same checks ran in Studio:
  - Every car on sale has a price, source and rarity.
  - Class floors pass. Only the 3 Éclairs are class X. The R35 Zenith is above the 2010 (S1 750 vs A 696).
  - The deleted ids are gone.
  - A save that owns deleted cars loads clean: they are dropped, and the selected car falls back to the free one. A save that owns only deleted cars gets the free car.
- **Play test on a fresh test save** (`StudioUnlockAll` off):
  - Imports refused, cash unchanged: W213 V8 S, F142 Speciale, Velocité Noir Origine.
  - Local cars bought at the new prices: Apex Cambria −$93,000, F142 Spider −$1,900,000.
  - Deleted ids answer "Unknown car".
- **Post paycheck at rank 5:**
  - 2x Cash only: $330 (= rank 3 pay, no 2x).
  - Double Pay: $660.
  - `OnPost` is set while on duty at the post.
- **Back on `CityLegends_v1`** (checked on the Server in Play):
  - The new prices, the imports, the R35 trims and the post cap are all live.
  - No script errors.
  - `StudioUnlockAll` is back on. The place is saved, not published.

![[2026-11-19 Economy applied - dealer R35 trims and new prices.jpg]]
![[2026-11-19 Economy applied - import car from crates.jpg]]

## Leftovers applied (19 Nov 2026, owner approved)
1. **Day-7 streak car:** a dealer (Local) car you don't own, worth up to **$150,000** (`StreakCarMaxPrice` 50,000 -> 150,000; `Goals.streakCar` filters on `Source == "Local"` instead of the Mid tier, and never picks the free car). 18 cars are in the pool. Players who own all 18 still get the cash fallback (`StreakCarCash`, scaled to $9,000 by Config's cash scaler).
2. **Sell-back stays at 60%** of the car's current price. No change.
3. **Every free gift car is Local.** Imports stay crates only.
   - Legends Rewards SPIN / SUPER SPIN car prize: `Rewards.pickCar` now takes Local cars only (same tiers and price caps).
   - First-car pick and the Starter Pack's car (both use `Config.Menu.StarterChoices`): the C346 Rallye (Import) is replaced by the **Apex AE86** (Local, $110,000, "Light rear-drive drifter"). The three are now Horizon Z33 ($210k), Bavarica Werkz G20 Sport ($160k) and Apex AE86 ($110k), all Local.
   - No other path gives a free car (grep of every `Owned[...] = true`: buying, the market, tester unlocks and save repair only).
   - `Config.lua` got smaller (198,884 -> 198,860 bytes).

**Tests (Studio, main place, test save `CityLegends_test`, unlock-all off for the run):**
- First-car pick: the C346 Rallye is refused ("Pick one of the three"). The AE86 was claimed.
- Starter Pack (test receipt): the pick opened. The AE86 was refused ("You own that one"). The G20 Sport was claimed.
- Day 7 (`ClaimDaily` with the streak at day 6): it gave the **Bavarica Werkz G06 Sport Sport** (Local, $130,000).
- The live pick code was run 2,000 times for day 7: 18 different cars, all Local, all $150k or less. Owning all of them gives the cash fallback.
- Spin car prize: 3,000 picks, 4 Local cars, all under $120k. Super spin: 3,000 picks, 32 Local cars, all under $600k. No Imports.
- Back on `CityLegends_v1` (checked on the Server in Play): the new rules are live, unlock-all is back on, no script errors. The place is saved, not published.

## Left for later / watch
- **Sell-back** still pays 60% of the car's (new) price. Testers who bought cars cheap before today gain once when they sell.
- ~~Day-7 streak car~~: done (see Leftovers applied).
- ~~Gift cars~~: done, Local only (see Leftovers applied).
- A deleted car's paint (`Customs`) stays in a tester's save. It's harmless.
- **Crates themselves are not built yet.** `CrateRules` is the agreed data for when they are.
- `tools/economy/model.py --lua` writes `CarMeta`. The live prices are frozen at the approved run. A re-run now prices lower, because delivery and posts pay less.
