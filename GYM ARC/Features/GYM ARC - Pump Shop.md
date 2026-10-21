---
tags: [gymarc, feature]
status: built
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Pump Shop

Built 21 Oct ([[2026-10-20 GYM ARC Prompt - 19 Coins useful again (shops)]]). One big store in the town hub that sells everything worth buying with coins. Coins only, no random rolls.

## Where and what
- **Building (rebuilt 21 Oct, prompt 23, [[2026-10-21 GYM ARC Pump Shop building rebuilt]]):** a 2-storey red brick corner store (38 x 44) on the north-east corner of the old parking lot (`Workspace.Town.PumpShop`, built by `tools/builders/PumpShop.luau`): black storefront with display windows and mannequins, striped awning, lit sign on the facade and a hanging blade sign, a "GET PUMPED" mural on the north wall, windows on every side, AC units and a water tank on the roof. The rest of the lot is paving and a small park. **The parking lot and the first shop (`PumpShop_old`) are in `ServerStorage.PumpShopBackup`** (move them back to undo).
- **4 sections**, each with a counter ("Shop" prompt), a sign and a clerk (Mo, Rita, Jay, Dr. Vale): SUPPLEMENTS (tubs and shakers) and GEAR (belts and straps, knee sleeves) on the back wall, APPAREL (2 mannequins) and DNA LAB (glowing sample tubes) on the side walls, a shake fridge and a podium with a giant tub.
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

## Gear levels look (21 Oct, prompt 34)
- Basic black, Pro red, **Elite silver** (was gold; gold is for the Champion level of prompt 31), on the new gear meshes ([[GYM ARC - Wardrobe and Gear and Fits Store]]).
