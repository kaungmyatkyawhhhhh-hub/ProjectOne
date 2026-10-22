---
tags: [gymarc, feature]
status: built
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Pump Shop

## Now: three shops (22 Oct, [[2026-10-21 GYM ARC Prompt - 31 Shops rework and undiscovered|prompt 31]])
One shop window for all three (`PumpShopClient`); its title and tabs follow the shop. Tabs are always SUPPLEMENTS / GEAR (+ ALTERS or DNA LAB). Config: `Config/PumpShop.Shops`. The server only sells a shop's own items to a player standing at it.
- **Coach Dex** (Starter Gym front desk, the main shop): SUPPLEMENTS (Protein Shake, Creatine, Protein Powder, Supplements, Pre-Workout), GEAR (Basic and Pro), ALTERS. Talking to him: the tutorial's first quest, else he pays out a finished quest, then his shop opens. Quests are claimed in **Quests > Goals (CLAIM)**; new quests come by themselves after the tutorial.
- **PUMP SHOP** (town): ONE counter (the old Supplements one, sign "SPECIALS", clerk Mo). The Gear / Apparel / DNA Lab counters, tills, hanging signs and the COLD SHAKES fridge are gone (their wall displays stay as decoration; a plant where the fridge was). Sells: Mass Gainer (+50% progress, 10 min), Elite Pre-Workout (+50% rep speed, 10 min), Whey Isolate (+50% EXP, 15 min), BCAA Recovery (stamina refills 2x, 15 min); Elite and **Champion** gear (+20%, gold, 150,000); DNA LAB.
- **Coconut Stand** (beach gym, tag `CoconutStand`): Coconut Water only, x1 / x5. The cart was 3 studs in the air: now on the sand.
- **Apparel is off sale** (players keep what they own). **Smoothie stands removed** everywhere: Starter Gym cart (a plant now), Pro Gym bar (bench + 2 plants, its zone sign says LOUNGE), the town smoothie bar building (a small park now: `Town.PocketPark`, signpost arrow says "Park").
- **Links:** the Shop window has "Coach Dex" (teleports in front of him, camera behind you) and "Go to Pump Shop"; 10 s cooldown each, checked on the server. A gear level sold in the other shop shows a "Go to ..." button.
- Prices (minutes of coins at your stage): Mass Gainer 14, Elite Pre-Workout 12, Whey Isolate 16, BCAA 12.

## The room (23 Oct, prompt 51, [[2026-10-23 GYM ARC Pump Shop redesign]])
- ONE counter in the middle of the back wall (`Town.PumpShop.Interior.Counter`, its `Top` is the tagged PumpShopCounter with the SHOP prompt); a straight 13-stud aisle from the door with gold inlay lines.
- Behind it: PUMP SHOP in gold, the trophy shelf with the 4 specials, two SPECIALS menu boards. Side walls: 3 tall shelf units each. Front left GEAR (mannequins, Champion belt on a gold pedestal), front right DNA LAB (glass case with a turning, pulsing helix). Middle: BEST SELLER pyramid and a turning Elite Pre-Workout tub (NEW!).
- Shopkeeper Mo: bigger, black shirt with gold trim, black cap with a gold peak; leans, breathes, looks at you and points when you open the shop (CoachDexClient). Built at `Interior.ClerkSpot` by PumpShopService.
- Music inside: the town's tracks at 55% volume. Builder: `tools/builders/PumpShopRedesign.luau`; backup `ServerStorage.PumpShopBackup_23Oct`.
- The GET PUMPED mural is missing from the place (in the backup): owner to decide.

## Before prompt 31 (history)

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

## Prompt 28 (21 Oct; [[2026-10-21 GYM ARC UI cleanup]])
- No PUMP SHOP side menu button any more. The Shop window has a small "Go to Pump Shop" link under the grid (once the Pump Shop is open for you; `UIBus.GoPumpShop`, same 10 s cooldown).
