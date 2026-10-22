---
date: 2026-10-23
tags: [gymarc, progress, world, shop]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Pump Shop redesign (prompt 51)

Prompt: [[2026-10-23 GYM ARC Prompt - 51 Pump Shop redesign|51 Pump Shop redesign]]. Feature: [[GYM ARC - Pump Shop]].
Builder: `tools/builders/PumpShopRedesign.luau`. Backup of the whole building before: `ServerStorage.PumpShopBackup_23Oct`.

The shop window (SUPPLEMENTS / GEAR / DNA LAB) is unchanged; only the room, the shopkeeper and a few outside touches.

## Inside
- **One counter in the middle of the back wall.** From the door you look straight at it down a 13-stud aisle with gold inlay lines (wide enough for 7'0"). Black counter, glass front with lit tubs inside, black marble top with a gold edge. On it: a register, a bell, a THANKS! jar (gold stars, no money), an open tub with a scoop, a shaker. The SHOP prompt (E) is on the counter top. The old SPECIALS counter and its prompt are gone.
- **Behind the counter:** "PUMP SHOP" in gold, a trophy shelf with the 4 specials (Mass Gainer, Elite Pre-Workout, Whey Isolate, BCAA) on gold plinths under a light, with icon plaques, and two SPECIALS menu boards (icon, name, effect and time, read from the boost config).
- **Side walls:** 3 tall shelf units each (PROTEIN, PRE-WORKOUT, RECOVERY / MASS, SHAKES, VITAMINS) full of tubs and shakers in the new boost icon colours, glowing gold shelf edges.
- **Front left: GEAR.** Two mannequins in the window (belts, wraps, knee sleeves), the Champion belt on a gold pedestal under a spotlight with a CHAMPION plaque, a pegboard of belts and straps, a small stand.
- **Front right: DNA LAB.** Glass case with a glowing teal helix that turns slowly and pulses, a teal floor ring, a lab bench with flasks, test tubes and a microscope, a hanging DNA LAB sign.
- **Middle:** two low islands: a Mass Gainer pyramid with BEST SELLER; a giant Elite Pre-Workout tub turning on a gold plinth with Whey stacks and NEW!.
- **Look:** dark slate floor, gold LED strip round the ceiling, warm cans (soft light cones over the counter as the "haze"), two fill panels, cream walls over a black wainscot.
- **Shopkeeper Mo:** bigger (1.4x tall, broad), black shop shirt with a gold band and badge, black cap with a gold peak (clearly not Dex). He leans on the counter, breathes, looks at you when close and points when you open the shop (the same code as Coach Dex, `CoachDexClient`).
- **Music:** inside the shop the town music carries on (no restart) at 55% volume (`Config/Sounds` AreaMusic.PumpShop / AreaVolume).
- **Motion:** the turning tub and helix and the helix pulse run on each client (`TownClient`, tags ShopSpin / ShopPulse), only within 80 studs.

## Outside
- Facade kept (brick, cornice, awning, lit PUMP SHOP sign, blade sign, planters, bench). The windows now show the lit shelves, the gear mannequins and the DNA helix.
- Chalkboard: NEW: ELITE PRE-WORKOUT. The two south street trees moved 1.2 studs out (their crowns poked through the wall).

## Numbers
- Parts 738 -> 1,351 (inside ~830; all small props anchored, no collision, no shadows). Lights 20 -> 24.
- Teleport point (Entrance), GO TO / guide target (the counter; the guide spot is in the aisle in front of it) and the unlock rules are unchanged and checked.

## Tested (PC viewport in Studio)
Walked in, pressed E at the counter, the panel opened, bought 1 Mass Gainer (11,738 -> 7,138 coins, "You have 1", in the hotbar). Mo leans and looks. No errors.

## Needs the owner
- **The GET PUMPED mural on the north wall is gone from the place** (it is still in the backup). Nothing in this run deletes it, so it looks like it was removed by hand. Put it back?
- Phone check (844x390) of walking in: not done on a real phone.

![[GYM ARC/Screenshots/pump_shop/p51_before_front.jpg]]
![[GYM ARC/Screenshots/pump_shop/p51_after_front.jpg]]
![[GYM ARC/Screenshots/pump_shop/p51_before_side.jpg]]
![[GYM ARC/Screenshots/pump_shop/p51_after_side.jpg]]
![[GYM ARC/Screenshots/pump_shop/p51_before_above.jpg]]
![[GYM ARC/Screenshots/pump_shop/p51_after_above.jpg]]
![[GYM ARC/Screenshots/pump_shop/p51_before_inside.jpg]]
![[GYM ARC/Screenshots/pump_shop/p51_after_inside_door.jpg]]
![[GYM ARC/Screenshots/pump_shop/p51_after_counter.jpg]]
![[GYM ARC/Screenshots/pump_shop/p51_after_gear.jpg]]
![[GYM ARC/Screenshots/pump_shop/p51_after_dna_lab.jpg]]
![[GYM ARC/Screenshots/pump_shop/p51_shopkeeper.jpg]]
![[GYM ARC/Screenshots/pump_shop/p51_bought.jpg]]
