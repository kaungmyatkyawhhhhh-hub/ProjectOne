---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Energy Shakes

Back to [[00 GYM ARC Home|GYM ARC Home]].

A drink that refills stamina and gives bonus gains for a short time.

## Smoothie bar: shakes and meals (built 13 Oct, new features run task 5)
- **Where:** the pro gym's smoothie bar (counter, stools, fridge, blenders, and a hanging menu board with the items and prices), a smoothie cart in the starter gym by the front windows, and a coconut cart on the sand by the beach gym entrance. Walk up to the front of the counter and press **Order**.
- **Menu (coins):** Protein Shake 60 (+20% EXP, 5 min), Energy Smoothie 50 (stamina refills 50% faster, 5 min), Chicken & Rice 90 (+10% EXP and +10% refill, 10 min), Coconut Water 40 (beach cart only: run 50% farther on the treadmill, 5 min).
- **Not the same as the bag's Energy Shake:** the bar's items have their own name, color and icon (a cup with a straw or a bowl, in the item's color); the bag shake keeps its white shaker icon and its "Drink shake" button.
- **Boosts:** one of each kind at a time. Buying again adds its time, up to 3 drinks' worth; when the next drink wouldn't fit, the button says FULL and nothing is charged.
- **Timers:** a small pill for each running boost at the top right ("Protein Shake 14:14").
- **Leaving:** boosts pause while you're away and continue when you come back; the timers show again as soon as you join.
- **Drinking:** your character holds a shaker in the item's color for 2 seconds and does the shake chug (everyone sees it).
- **Where it lives:** `Config/Meals`, `Server/MealService`, `MealClient`; stalls built by `tools/builders/SmoothieCarts` (`Feature_SmoothieBar` folders). Studio test switch: `TestMealRejoin`.

## How it works
- **Buying:** 25 coins at the shake machine by the starter gym door. Also earned from quests and the tutorial.
- **Carry:** up to 20 shakes in your bag.
- **Drinking:** the Drink shake button on the right. Refills stamina fully and gives +50% gains for 30 s; drinking again adds time, up to 90 s. A countdown shows the boost.
- **Flavors:** Chocolate, Strawberry, Vanilla, Banana, Cookies and Cream, Mint. Cosmetic only.
- **Chug:** the character plays a quick shake-chug pose when drinking.
- **Tutorial:** new players get a free shake when they first run low on stamina.

## Where it lives
- `Config/Stamina` (Shake table)
- `Server/StaminaService`, `Server/BoostService`, `ShakeClient`
- Numbers: [[GYM ARC - Config values]]


## Related
[[GYM ARC - Stamina and Treadmills]], [[GYM ARC - Gains and EXP]], [[GYM ARC - Economy and Daily Rewards]]

## Screenshots
![[GYM ARC/Screenshots/s3_smoothie-bar-interior_after.png]]
![[GYM ARC/Screenshots/pro_gym_smoothie_corner.jpg]]
![[GYM ARC/Screenshots/meals_shop_panel_starter_cart.jpg]]
![[GYM ARC/Screenshots/meals_hud_timers.jpg]]
![[GYM ARC/Screenshots/meals_drinking_shaker.jpg]]
![[GYM ARC/Screenshots/meals_coconut_cart_beach.jpg]]

## Now the inventory's Protein Shake (21 Oct, prompt 14)
The Energy Shakes in the bag are the **Protein Shake** item of the Inventory's Boosts tab now (same effect: full stamina, +50% EXP for 30 s, stacking to 90 s). Old saves' shakes moved over on join (`data.shakes` -> `data.items.Shake`). The quick DRINK SHAKE button by the stamina bar uses one (it shows "0" and turns grey when you have none). The Shake Bundle product adds 3 to the inventory and offers USE NOW instead of drinking them. See [[GYM ARC - Boosts Inventory]].
Note: the smoothie bar also sells a "Protein Shake" (+20% EXP for 5 min, Config/Meals). Two different things with the same name: rename one?
