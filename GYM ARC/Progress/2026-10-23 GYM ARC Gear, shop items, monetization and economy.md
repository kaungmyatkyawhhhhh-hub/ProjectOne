---
date: 2026-10-23
tags: [gymarc, progress, shop, monetization, economy]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Gear, shop items, monetization and economy (prompts 59, 57, 60, 61)

Prompts: [[2026-10-23 GYM ARC Prompt - 59 Gear rework belt and wraps|59 Gear rework]], [[2026-10-23 GYM ARC Prompt - 57 Shop items, Robux, gear icons, grow card|57 Shop items, Robux, gear icons, grow card]], [[2026-10-23 GYM ARC Prompt - 60 Auto Rep, DNA pack, Starter Pack|60 Auto Rep, DNA pack, Starter Pack]], [[2026-10-23 GYM ARC Prompt - 61 Economy rework|61 Economy rework]].
Owner decisions (23 Oct): gear only at Coach Dex (prompt 59 replaces 57 part 6, so no Robux Elite gear); PUMP SHOP tabs = SUPPLEMENTS · STYLE · DNA LAB; Starter Pack coins = 60 minutes of coins, min 5,000, max 10,000.
Game commits 91ce0d8 + 24dab03.

## Products for you to create (Creator Hub > Monetization > Developer Products)
Paste each ID in `Config/Monetization` (`id = productId(...)`). Until then each one is hidden (or shows SOON in the PUMP SHOP). I did not create any products.

| Key in config | Name | Description | Price |
|---|---|---|---|
| `DnaTokenPack` | DNA Token x3 | Three genetics rerolls. | 249 R$ |
| `StarterPack` | Starter Pack | Coins, 3 Protein Shakes, a DNA Token, 30 min 2x EXP and the STARTER title. One time only. | 49 R$ |
| `Supp_MassGainer_1` / `_5` | Mass Gainer / Mass Gainer x5 | +50% Growth Spurt and alter progress for 10 minutes. | 25 / 99 R$ |
| `Supp_ElitePreWorkout_1` / `_5` | Elite Pre-Workout / x5 | +50% rep speed for 10 minutes. | 25 / 99 R$ |
| `Supp_WheyIsolate_1` / `_5` | Whey Isolate / x5 | +50% EXP for 15 minutes. | 25 / 99 R$ |
| `Supp_BcaaRecovery_1` / `_5` | BCAA Recovery / x5 | Stamina refills twice as fast for 15 minutes. | 25 / 99 R$ |

New descriptions for the existing coin packs (they now scale, so no fixed number): Small "A pile of coins. The bigger you are, the more you get.", Medium "A big pile of coins. The bigger you are, the more you get.", Large "A huge pile of coins. The bigger you are, the more you get."

## Prompt 59: gear = Lifting Belt + Wrist Wraps
- Belt = lower body (legs, back, core), Wraps = upper body (chest, shoulders, arms). BASIC +5% (750) and PRO +10% (4,000) at Coach Dex > GEAR; ELITE / CHAMPION kept in config as off sale (owners keep them working).
- Only the best level you own counts (worn or not); buying equips it. Only the next level can be bought.
- Straps and knee sleeves are gone (shops, Inventory, bodies; a trainer's knee sleeves are wraps now). Once per player: straps count toward wraps and sleeves toward the belt (a higher level = that level of the matching piece), otherwise the coins come back; a one-time "Gear got simpler!" note with the refund.
- Coach Dex > GEAR: two rows (BELT / WRAPS), BASIC and PRO tiles side by side with the new pictures. Inventory > Gear: your belt and wraps first ("NO BELT YET" + GET AT COACH DEX when you have none), then your other wearables.
- Uploaded with your OK: the 8 belt / wraps pictures (basic, pro, elite, champion). Straps / sleeves pictures not uploaded (not used).
- Not done: the bottom-left boosts row hover line "PRO BELT · +10% LOWER BODY" (gear isn't shown in that row today).

## Prompt 57: shop items, Robux, grow card
- "Finish faster: Shake Bundle >" lines removed (under the NEXT pill and the machine strip).
- Coach Dex > SUPPLEMENTS: + SHAKE BUNDLE (49 R$) and DNA TOKEN (99 R$) (+ DNA x3 once set up), with their pictures and a Robux icon on the price.
- PUMP SHOP > DNA LAB: the DNA token picture; the coin token next to the Robux x1 / x3.
- PUMP SHOP specials: Robux only (x1 / x5), no coin price; SOON until the products exist; you can't buy past the carry limit. Paid items are never cut by the limit.
- TAP TO GROW card: "GROWTH SPURT n" big white stroked, "TAP TO GROW" small in the growth colour, upright text, a faint up-arrow on the right. Not seen on screen yet (the test save is at 7'0").

## Prompt 60: Auto Rep, DNA pack, Starter Pack
- Store PASSES hero: Auto Rep first for non-owners (already), now taking turns with the Starter Pack until it's bought.
- On a machine, non-owners get a small AUTO chip on the REP button: it opens the Auto Rep card (picture, "Lifts for you while you're on a machine. Toggle it any time.", price, BUY). Owners keep their AUTO toggle.
- One soft offer a session: after a set really ends (no rep for the set break) with 150+ hand-tapped reps this session: "Tired of tapping?" (not in the tutorial, not for owners, gone after 12 s).
- DNA x3 next to the single in the Store (BOOSTS), Coach Dex SUPPLEMENTS and DNA LAB; "SAVE n%" only when it really is cheaper per token (249 vs 3 x 99 = SAVE 16%). Genetics with 0 tokens: tapping REROLL opens "Need a DNA Token. A DNA token pays for one genetics reroll." with coins, x1, x3 and an X.
- Starter Pack (once): coins (60 min at your stage, 5,000 to 10,000), 3 Protein Shakes, 1 DNA Token, a 2x EXP item (30 min when used), the STARTER title (Rare). Offered once after the first Growth Spurt (not in the tutorial or the first 5 minutes), then pinned at the top of Store BOOSTS. "WORTH n R$" only when our own prices say so. A second purchase gives its value in coins, no second title.
- Analytics: Offer_Shown / Tapped for AutoRep, AutoRepChip, StarterPack, DnaNeed; Product_Bought for every product.

## Prompt 61: economy
- One helper: `Economy.Minutes(spurts, minutes)` = minutes x the BASE coins a minute at that stage (57 / 110 / 152 / 200 / 220 / 222 / 328), rounded like shop prices. Every reward is max(old amount, new amount).
- Coin boosts: all multipliers together capped at x8 in one place (BoostService.Coins); trainers' coin boost capped at +100%. Stats header shows "COIN BOOST x2.8", "(MAX)" at the cap.
- STYLE tab in the PUMP SHOP (fixed prices, bought once): 12 name tag colours and 12 title colours (8 solid 5,000-20,000, 4 gradients 60,000-120,000), 2 colours for each aura you own (25,000 / 50,000), 2 tints for each alter you reached (40,000 / 80,000). Preview in the strip, TRY for aura / alter colours, WEAR / TAKE OFF; colour chips in Inventory > Auras and > Alters.
- Trainer snacks: SNACKS button at the Agency (Small / Medium / Large: 3 / 10 / 30 min of coins, +120 / 400 / 1,200 trainer EXP), FEED on MY TRAINERS (never past the max level; evolving still needs 3 copies, no coin fee).
- There is no group daily chest in the game, so that one wasn't changed.

### Rewards and prices before / after (Spurt 0 / Spurt 3 / 7'0")
| Item | Old | Spurt 0 | Spurt 3 | 7'0" |
|---|---|---|---|---|
| Login day 1 / 4 / 7 | 25 / 70 / 300 | 115 / 230 / 855 | 400 / 800 / 3,000 | 655 / 1,300 / 4,900 |
| Daily quest (60 one) / all-done bonus | 60 / 150 | 170 / 570 | 600 / 2,000 | 985 / 3,300 |
| Coach quest first / FirstSpurt / repeat | 10 / 200 / 60 | 55 / 285 / 230 | 200 / 1,000 / 800 | 330 / 1,650 / 1,300 |
| Posing 1st / enter (that stage's show) | 150 / 25, 300 / 50, 2,000 / 250 | 455 / 55 | 1,600 / 200 | 2,600 / 330 |
| Rivals Benny / Coral / Dante | 150 / 300 / 600 | 285 / 455 / 685 | 1,000 / 1,600 / 2,400 | 1,650 / 2,600 / 3,950 |
| Legend / guide | 60 / 25 | 170 / 55 | 600 / 200 | 985 / 330 |
| Offline (8 h, the cap) | 240 | 547 | 1,920 | 3,148 |
| Re-rack / spot payout | 5 / 5 | 5 / 5 | 20 / 20 | 35 / 35 |
| Arm wrestle win / loss | 15 / 5 | 30 / 10 | 100 / 30 | 165 / 50 |
| Group gift / rebalance gift | 1,000 / 500 | 1,000 / 500 | 3,000 / 1,000 | 4,900 / 1,650 |
| Coins Small / Medium / Large | 1,000 / 5,000 / 15,000 | 1,150 / 6,850 / 20,500 | 4,000 / 24,000 / 72,000 | 6,550 / 39,350 / 118,100 |
| Starter Pack coins | new | 5,000 | 10,000 | 10,000 |
| Snacks Small / Medium / Large | new | 170 / 570 / 1,700 | 600 / 2,000 / 6,000 | 985 / 3,300 / 9,850 |

## Tested (Studio, PC viewport; the test save is at 7'0")
- Coach Dex GEAR: bought Basic then Pro belt (7,147 -> 6,397 -> 2,397), OWNED, NEW GEAR toast; Pro Wraps red when short.
- Coach Dex SUPPLEMENTS with Shake Bundle and DNA Token (Robux prices); PUMP SHOP specials show SOON (no products yet).
- Test receipts through the real ProcessReceipt (fake IDs, removed after): Starter Pack +10,000; a second Starter Pack paid +37,955 (its value) and no second title; DNA x3; Mass Gainer; the same receipt twice granted once.
- STYLE: bought the Crimson name tag (name over the head in crimson, Roblox's own name hidden) and the Crimson tint for Pumped (40,000).
- Snacks: bought Small + Medium, rolled a trainer, fed Medium: "+2 LV, now LV 3", 140 / 160 EXP.
- Coach Dex's portrait, gear and economy: no errors in Output.
- Not tested on screen: the gear migration on an old save with straps / sleeves, the AUTO chip and the 150-rep offer, the Genetics need-a-token card, the Starter Pack offer after a first spurt, the TAP TO GROW card, phone sizes.
- The test account (yours, HEINHEIN1922) now owns the Starter Pack, a belt, a Crimson name / tint and a trainer from these tests.

![[GYM ARC/Screenshots/shop_economy_57_61/coach_gear_two_rows.jpg]]
![[GYM ARC/Screenshots/shop_economy_57_61/coach_gear_pro_bought.jpg]]
![[GYM ARC/Screenshots/shop_economy_57_61/coach_supplements_robux.jpg]]
![[GYM ARC/Screenshots/shop_economy_57_61/pump_specials_robux_soon.jpg]]
![[GYM ARC/Screenshots/shop_economy_57_61/pump_style_tab.jpg]]
![[GYM ARC/Screenshots/shop_economy_57_61/name_tag_crimson.jpg]]
![[GYM ARC/Screenshots/shop_economy_57_61/alter_tint_crimson.jpg]]
![[GYM ARC/Screenshots/shop_economy_57_61/my_trainers_feed.jpg]]
![[GYM ARC/Screenshots/shop_economy_57_61/my_trainers_fed.jpg]]
