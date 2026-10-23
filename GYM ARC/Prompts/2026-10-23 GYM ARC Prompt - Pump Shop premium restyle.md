---
date: 2026-10-23
tags: [gymarc, prompt, ui]
status: done
---
# PUMP SHOP premium restyle (+ Agency checkmarks)

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
PUMP SHOP panel: restyle it in the same premium style as the Alters / Auras detail panels (not chunky). The Coach Dex shop uses the same panel, so it gets this too.
- TILES: each item's tile gets a soft themed background in its own colour filling the tile (Mass Gainer dark gold, Elite Pre-Workout deep purple, Whey Isolate teal, BCAA green...), faint rings or light rays behind the icon, a dark gradient at the bottom for the text. A thin outline in the item's colour (not the thick chunky border). Selected tile: the outline turns gold with a soft glow (the new glow component).
- ICON: centred, with a soft glow behind it in the item colour.
- NAME: white stroked text, same font and size as "PUMPED" scaled to the tile. Never wraps out of the tile.
- EFFECT: a slim dark pill with a thin outline in the item colour and white text: "+50% EXP · 15 MIN". Shorten long ones so they fit ("+100% STAMINA REGEN" -> "2x STAMINA REGEN"). Nothing overflows the tile (BCAA does now).
- PRICE: a slim dark graphite button with a thin outline, a small coin icon and white text "3,950" (like the "WORN" button). Can't afford: price in red + "NEED 1,200 MORE" small under it.
- DETAIL STRIP (bottom): the selected item's themed background behind it, icon with glow, name white stroked, the one-line description in light grey. Buy buttons on the right: "x1" and "x5" as slim graphite buttons with a thin gold outline and a coin + price; the x5 one gets a small "BEST" tag only if it's cheaper per item.
- TABS / title / coins / X stay as they are.
- Keep the purchase animation (coins count down, item flies to Inventory) and the select bounce + sound.
TEST: screenshots of all 3 tabs, one with an item you can't afford, next to the Alters panel. Short note in the vault.
```

Also (same message):

```text
Trainer Agency: remove the gold checkmarks from the trainer tiles completely. Owned trainers already show their real art (not owned = silhouette), so the check isn't needed. Keep the "x2" dupe count. MY TRAINERS keeps its check for EQUIPPED trainers.
```
