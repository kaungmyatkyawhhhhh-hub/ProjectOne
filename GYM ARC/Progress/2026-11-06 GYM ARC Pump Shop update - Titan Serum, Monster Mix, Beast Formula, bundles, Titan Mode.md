---
date: 2026-11-06
tags: [gymarc, progress, monetization, supplements, bundles, titan]
---
# GYM ARC - Pump Shop update: TITAN SERUM, MONSTER MIX, BEAST FORMULA, bundles, TITAN MODE (6 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Spec: [[2026-11-06 GYM ARC Prompt - OP supplement + bundles]] · Before: [[2026-11-05 GYM ARC Supplements Gains + Stamina, alter tints removed]]

In Studio only. **Not published.** (Later 6 Nov) the owner created the 7 products: their ids are in `Config/Products`, so everything shows once published (see the end of this note).

## Owner answers (6 Nov)
- BEAST FORMULA's "+25% PR gains" = **+25% EXP** (a PR gives no EXP of its own in the code).

## What's in
| Item | Effect | Time (max) | Product key | Fallback price |
|---|---|---|---|---|
| **TITAN SERUM** x1 | x2.5 EXP, infinite stamina, x2 coins from reps (Auto Rep too) | 15 min (45) | `Supp_TitanSerum_1`: **starts now** | 149 |
| TITAN SERUM x3 | 3 into the inventory | | `Supp_TitanSerum_3` | 399 |
| **MONSTER MIX** | Auto Rep x2 speed (+100% rep speed) + infinite stamina | 30 min (60) | `Supp_MonsterMix_1` (inventory) | 99 |
| **BEAST FORMULA** | x3 coins from reps + 25% EXP | 15 min (45) | `Supp_BeastFormula_1` (inventory) | 99 |
| POWER HOUR | GAINS + STAMINA, both start now | 30 min each | `Bundle_PowerHour` | 45 |
| GYM RAT PACK | 5 GAINS + 5 STAMINA (inventory) | | `Bundle_GymRat` | 179 |
| TITAN PACK | 3 TITAN + 5 GAINS + 5 STAMINA (inventory) | | `Bundle_TitanPack` | 549 |
- **Stacking: everything ADDS** (BoostService): EXP and coins add as before; MONSTER's rep speed adds on top of Pre-Workout / auras (`repAdd`), so nothing that existed gets weaker; infinite stamina = BoostService `endless` (PlayerData.UseStamina), the stamina bar turns gold (no extra chip). Using one again adds its time up to its max.
- **Receipts:** ProcessReceipt only, everything checked before anything is given, saved before "granted", the purchase id stops a double grant. `data.suppBought` counts supplement / bundle buys (for the POWER HOUR card).
- **Art:** the owner's serum icons (512 tiles, 1024 featured) uploaded to Myanmar Builders Club → `ArtIds.Serums`; the Titan VFX (already uploaded) now used. Blending rule: `_alpha` at LightEmission 0.3 + LightInfluence 0, `_add` only at 1, UI `_alpha`.

## Shop (Pump Shop counter + the "Boosts" window from the HUD "+" slot)
Order: **TITAN SERUM featured card** (gold running frame, the looping TITAN MODE preview of your own avatar, "∞ STAMINA · 15 MIN") → MONSTER MIX → BEAST FORMULA → GAINS → STAMINA → **BUNDLES** (label, then POWER HOUR, GYM RAT PACK, TITAN PACK).
- "SAVE n R$" = what the contents cost separately (an exact pack where one exists: TITAN x3, GAINS x5...) minus the bundle, from **Roblox's real prices**. With the list prices: POWER HOUR 5, GYM RAT 19, TITAN PACK 48, TITAN x3 48. (In the test the owner's account sees GAINS / STAMINA at 23 / 90 (managed pricing) next to placeholder fallback prices, so it read 1 / 1 / 30; with the real products it fixes itself.)
- "BEST VALUE" = lowest Robux per minute of boost, worked out: **GYM RAT PACK** (179 R$ / 300 min).
- Owned counts on the tiles ("x3"), exact numbers on every card, no timers, no "was" prices.
- Studio only: Workspace `TestShopPlaceholders = true` shows the placeholder cards (buying one says "not set up yet"); `TestReceipt = "key=<product key>:<purchase id>"` tests a placeholder receipt.

## TITAN MODE
- **Activation (every time it starts, ~2.5 s, skippable after 0.5 s):** a glowing gold vial floats up from the hand (drink swirl), crouched wind-up (server pose, everyone sees it) with gold motes pulled in + FOV pull-in, **impact at 0.6 s**: front double biceps, gold shockwave ring on the floor, light rays + burst, small camera shake, gold flash, big **TITAN MODE** banner, deep boom + choir hit. Reduce Motion: no shake / flash / FOV. Others within 60 studs: the shockwave, burst and a soft boom + choir. Server chat "<name> entered TITAN MODE!" at most once per player per 10 min.
- **While active:** muscles +10% (MuscleRig.SetTitan, eased in at the impact, eased out at the end), gold veins on the arms (+ the torso when bare; one subtle pulse), red-gold eyes, steam off the shoulders, gold motes (~11 alive, below the face), a gold **TITAN** pill in the over-head stack (under the ALTER pill, right over the name), the gold timer tile, the main EXP number pops bigger and gold, every 10th rep a small gold burst.
- **Last 30 s:** the glow flickers, the aura thins; ~2.5 s before the end a soft power-down sound and the shrink-back. Nothing is left on the body after.
- Others half the particles, phones half again, off past 60 studs.

## Moments ("See boost" rules: once per 5 min over all, never in the tutorial, never after a fail)
- After a Growth Spurt / an alter: **"Go TITAN for the next one?"** with the same looping preview → SEE TITAN opens the shop on it (takes the after-spurt slot from the coins card while TITAN is for sale).
- Stamina out: STAMINA as before; a player who bought STAMINA 3+ times gets **POWER HOUR** instead.
- Analytics: `Offer_Shown / Tapped / Bought_<placement>` for `TitanAfterSpurt`, `TitanAfterAlter`, `SuppPowerHour` (+ the existing HudSlot / PumpShop / SuppStamina / SuppPR); `Product_Bought_<key>` as before.

## Tests (Studio, FreshPlayer temporary data)
- **Receipts:** all 7 give exactly their contents (TITAN x1 15:00 running, x3 +3, MONSTER +1, BEAST +1, GYM RAT +5/+5, TITAN PACK +3/+5/+5, POWER HOUR both 30:00). The same purchase id sent again: nothing more given. On temporary data the save is refused, so the answer is NotProcessedYet (correct: save first; Roblox retries).
- **Boosts:** MONSTER rep speed x2.00, infinite stamina 30:00; BEAST EXP +25%, coins hit the x4 cap (x8 with the 2x Coins pass) on a player who already had coin boosts; TITAN EXP +150%, coins +100%, stamina full on every rep.
- **Bot** (`Calc/pace_sim.luau`, now takes `repSpeed`; a ★0 player with 2 Voltas, lifting minutes):

| Setup | Alter 1 | Alter 15 | All Growth Spurts |
|---|---|---|---|
| no boosts | 12.0 | 27.2 | 4.6 |
| TITAN | 9.5 (1.26x faster) | 21.1 | 2.9 |
| TITAN + GAINS + BEAST | 8.3 (1.45x) | 18.9 | 2.5 |
| everything (TITAN + GAINS + BEAST + Creatine + MONSTER's x2 reps) | 4.1 (2.9x) | 9.2 | 1.3 |
- **FPS:** first build of the vein pulse wrote every decal every frame: 4 extra bodies in TITAN MODE cost 22.6 → 15.0 fps. Fixed (12 updates a second, others still): now 13.9 → 13.5 (Studio under remote control runs ~14 fps; the cost is what matters). ~30 TITAN particles alive with 5 bodies.
- 0 script errors in the runs.
- Screenshots: `GYM ARC/Screenshots/pump_shop_1106/` (shop PC + phone, featured card, bundles, MONSTER and BEAST cards, the three timers, the TITAN offer card, before / activation / active front + back / last seconds / ended, phone activation; `phone/` = 667x375 copies). No video: a frame sequence instead.

## Open / for the owner
- **The coin cap (x4 before the 2x pass)** limits BEAST's x3 for players who already have big coin boosts (and TITAN + BEAST together reach it).
- The flex shows the posing hint "Move or jump to stop" (the same as the alter flex).
- The boost row's timers sit very close together with three long serums running ("29:40 14:53").
- `data.suppBought` reaches the client at the next join (the POWER HOUR card counts buys from earlier visits).
- Not done: a real 2-player server, a real phone.

## Also today
- Console "Asset content representation is being generated" when changing skins: the new VFX textures are fine now; one id (94499805564230) is the **Inferno skin's TexturePack** that Roblox hasn't finished generating. The skin still shows right (Roblox uses the maps directly). Rebuilding the SurfaceAppearance gives the same pack (same maps), so it's left to Roblox.
- A first test receipt ran on the Studio account's real save by mistake (TITAN etc. given and saved); it was taken back off and saved at once (all those counts back to 0, no boost time left). All later tests used FreshPlayer temporary data.

![[GYM ARC/Screenshots/pump_shop_1106/01_shop_titan_featured_pc.jpg]]
![[GYM ARC/Screenshots/pump_shop_1106/02_shop_bundles_pc.jpg]]
![[GYM ARC/Screenshots/pump_shop_1106/09_titan_activation_impact_pc.jpg]]
![[GYM ARC/Screenshots/pump_shop_1106/10_titan_active_front.jpg]]
![[GYM ARC/Screenshots/pump_shop_1106/06_offer_go_titan_phone.jpg]]

## Later 6 Nov: the real product ids
| Product | Id | List price | Owner's account (managed pricing) |
|---|---|---|---|
| TITAN SERUM | 3728842856 | 149 | 135 |
| TITAN SERUM x3 | 3728843110 | 399 | 360 |
| MONSTER MIX | 3728843203 | 99 | 90 |
| BEAST FORMULA | 3728843569 | 99 | 90 |
| POWER HOUR | 3728843662 | 45 | 41 |
| GYM RAT PACK | 3728843778 | 179 | 162 |
| TITAN PACK | 3728843909 | 549 | 495 |
- In `Config/Products`; each id checked against Roblox (the right name for each).
- Tested on temporary data with the Studio switch OFF (as players will see it): all 7 cards show with Roblox's real prices; a test receipt with each real id gives the right thing (TITAN and POWER HOUR start, the rest go to the inventory); a repeated purchase id gives nothing more. The tags from the real prices: TITAN x3 SAVE 45 R$, POWER HOUR SAVE 5, GYM RAT PACK SAVE 18 + BEST VALUE, TITAN PACK SAVE 45.

![[GYM ARC/Screenshots/pump_shop_1106/16_shop_real_ids.jpg]]
![[GYM ARC/Screenshots/pump_shop_1106/17_bundles_real_ids.jpg]]
