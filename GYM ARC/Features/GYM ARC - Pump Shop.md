---
tags: [gymarc, feature]
status: built
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Pump Shop

Built 21 Oct ([[2026-10-20 GYM ARC Prompt - 19 Coins useful again (shops)]]). One big store in the town hub that sells everything worth buying with coins. Coins only, no random rolls.

## Where and what
- **Building:** on the old parking lot between the gyms, on the way to the Beach Gym (`Workspace.Town.PumpShop`, built by `tools/builders/PumpShop.luau`). Glass front with open doors, a lit gold "PUMP SHOP" sign on the roof, ceiling lights. **The parking lot and 5 street lamps + the bus stop that stood there are in `ServerStorage.PumpShopBackup`** (move them back to undo).
- **4 sections**, each with a counter ("Shop" prompt), a sign and a clerk (Mo, Rita, Jay, Dr. Vale): SUPPLEMENTS (tubs and shakers), GEAR (belts and straps on hooks, knee sleeves), APPAREL (3 mannequins), DNA LAB (glowing sample tubes). An "ALTERS · COMING SOON" corner is kept free.
- The window has a tab for every section, so you can browse everything from any counter.
- **PUMP SHOP tile** in the left menu once the shop is open: takes you to the entrance (10 s cooldown).
- The smoothie bar and carts still stand; their prompt opens the Supplements section now.

## Prices (`Config/PumpShop`, with a note on how each was chosen)
Coins per minute of active play (`lune run tests/pacing coins`, 60 simulated players, no boosts): Spurt 0: **57**, 1: **110**, 2: **152**, 3: **200**, 4: **220**, 5: **222**, 7'0": **328**.
- **Supplements** (into the inventory, x1 / x5 / x10): price = minutes x your stage's rate. Protein Shake 3 min, Coconut Water 3, Creatine 5, Protein Powder 5, Supplements 4, **Pre-Workout** (new: +25% rep speed, 5 min) 4. E.g. at Spurt 2: shake 455, Creatine 760.
- **Gear** (worn, perk while worn; Basic -> Pro -> Elite): 750 / 4,000 / 25,000; +5% / +10% / +15% EXP. Belt: squats and deadlifts; Wrist Wraps: pressing; Lifting Straps: pulling; Knee Sleeves: legs.
- **Apparel** (looks only, try on first): shorts 500-750, tank tops 1,000-1,500, headbands 400-600, shakers 600-900, gym bags 1,200-1,500.
- **DNA Lab:** 25,000 base, +10% for each token bought this week (resets Monday 00:00 UTC). Applies everywhere tokens are bought with coins (Genetics screen, Store). "Reroll genetics" opens the Genetics screen.

## Unlocks and nudges
- Opens after 8 minutes of play or the first Growth Spurt (Supplements only); Gear and Apparel at Growth Spurt 2. Coach Dex says one line each time.
- "You can afford: Pro Lifting Belt!" gold note (at most every 5 min) when something new becomes affordable; tap = go to the shop.
- Owned gear and apparel: **Inventory > Gear** (wear / take off).

![[GYM ARC/Screenshots/pump_shop/outside.jpg]]
![[GYM ARC/Screenshots/pump_shop/inside.jpg]]
![[GYM ARC/Screenshots/pump_shop/panel_phone.jpg]]
