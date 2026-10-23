---
date: 2026-10-23
tags: [gymarc, prompt]
status: done
---
# 57 Shop items, Robux, gear icons, grow card

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Owner changes, 23 Oct. Follow CLAUDE.md Speed rules. Mobile first. Never undo the owner's manual Studio changes. Keep players' owned items and saves (migrate, never delete).
UPLOAD RULE: list the images before uploading and wait for my OK; one at a time, stop at the first moderation problem.

1) REMOVE the "Finish faster: Shake Bundle >" line under the NEXT alter pill (and any other "finish faster" upsell lines on the HUD).

2) COACH DEX > SUPPLEMENTS: add SHAKE BUNDLE and DNA TOKENS as items there (the same Robux products as in the Store, same prices and IDs, no new products). Icons: Downloads\gym_arc_transparent_icons\shop\product_shake_bundle.png and product_dna_token.png (already uploaded for the Store: reuse those assets). A small Robux icon on their price instead of the coin.

3) PUMP SHOP > DNA LAB: use the DNA token picture (product_dna_token.png) on its tiles instead of the empty/placeholder icon.

4) GEAR PICTURES: Downloads\gym_arc_gear_icons\ (512 transparent PNGs): belt_, wraps_, straps_, sleeves_ x basic / pro / elite / champion (16 files). Basic = brown leather, Pro = black + silver, Elite = purple + silver, Champion = gold. Use them on every gear tile (Coach Dex GEAR, PUMP SHOP GEAR, Inventory > Gear, toasts, popups).

5) PUMP SHOP SUPPLEMENTS COST ROBUX
- Mass Gainer, Elite Pre-Workout, Whey Isolate and BCAA Recovery become Robux developer products (consumable). Suggested prices (put in config, I'll set the final ones): single 25 R$, x5 for 99 R$.
- Create the developer products (or list the names/prices for me to create if you can't), and wire them through the existing purchase handler (ProcessReceipt, server-checked, no double-granting).
- Price buttons show the Robux icon + price. Remove the coin prices for these 4. Coin-priced normal supplements stay at Coach Dex.

6) ELITE GEAR FOR ROBUX (every gear piece)
- Ladder per piece: BASIC (coins, Coach Dex) < PRO (coins, Coach Dex) < ELITE (ROBUX, PUMP SHOP) < CHAMPION (big coin price, PUMP SHOP).
- ELITE LIFTING BELT, ELITE WRIST WRAPS, ELITE LIFTING STRAPS, ELITE KNEE SLEEVES: each a one-time Robux purchase (saved forever; a developer product with saved ownership, or a game pass if that's simpler; say which). Suggested 99 R$ each (config).
- Benefits: clearly better than PRO (e.g. Pro +10% -> Elite +15% for that gear's stat), but CHAMPION stays the best (+20%) so free players can still reach the top by playing. Show the benefit on the tile ("+15% SQUAT GAINS") and a small "vs PRO +10%" line in the detail strip.
- Players who already own an Elite piece from before keep it (no charge).
- Elite tiles get the purple theme background and a small Robux tag.

7) "TAP TO GROW" CARD (growth spurt ready): it looks ugly (washed-out olive fill, "TAP TO..." cut off, italic).
- Same style as the NEXT alter pill: dark graphite card with the quiet HUD outline in the growth colour, pulsing glow (glow component) when ready.
- Text fits, never cut off: "GROWTH SPURT 2" big white stroked on the first line, "TAP TO GROW" in the growth colour small on the second line. Fixed sizes that fit on 667x375; not italic.
- Optional: a faint upward-arrow / height-ruler background art filling the card, like the alter pills.

TEST (phone first): Coach Dex SUPPLEMENTS with the 2 new items, PUMP SHOP all 3 tabs with icons and Robux prices, a test purchase of a supplement and an Elite belt in Studio (test mode), Inventory > Gear, and the TAP TO GROW card. Screenshots. Short progress note in the vault with the product list and prices.
```
