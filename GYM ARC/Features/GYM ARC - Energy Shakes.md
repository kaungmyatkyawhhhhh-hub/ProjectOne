---
date: 2026-10-04
tags: [gymarc, feature]
status: done
---
# GYM ARC - Energy Shakes

Back to [[00 GYM ARC Home|GYM ARC Home]].

A drink that refills stamina and gives bonus gains for a short time.

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

## Planned change
- **Smoothie bar shop** (new features prompt, task 5): a counter in the pro gym and a cart in the starter gym open a small shop panel. Items bought with coins:
  - **Protein Shake:** +20% EXP for 5 min
  - **Energy Shake:** stamina refills 50% faster for 5 min
  - **Chicken and Rice:** +10% EXP and +10% stamina refill for 10 min
  - **Coconut Water** (beach gym only): faster cardio distance for 5 min
- One boost of each type at a time; buying again extends it (with a max). Small boost icons with timers on the HUD. A 1-2 s drinking animation with a shaker. All numbers in Config.
- Monetization prompt: a "Shake bundles" product (3 of a shake).

## Related
[[GYM ARC - Stamina and Treadmills]], [[GYM ARC - Gains and EXP]], [[GYM ARC - Economy and Daily Rewards]]

## Screenshots
![[GYM ARC/Screenshots/s3_smoothie-bar-interior_after.png]]
![[GYM ARC/Screenshots/pro_gym_smoothie_corner.jpg]]
