---
date: 2026-10-23
tags: [gymarc, prompt, ui]
status: done
---
# Auras tab cleanup, alter colour row, STYLE cut to 15, STOP above boosts

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Inventory > Auras is broken/messy (owner screenshot). Fix:
1. The aura COLOUR VARIANT pickers ("ORIGINAL" / "RED..." bars from prompt 61) float across the grid, cover a tile and stick out of the panel. Move the variant picker INTO the detail panel only: a row of small round colour swatches under the benefit pill ("ORIGINAL" + each variant; locked ones dimmed with a coin price; tap = preview, tap EQUIP to wear). Nothing about variants on the grid tiles except a tiny dot showing which colour is equipped.
2. Tiles in the same premium style as the Alters tiles / detail panel: each aura's own themed background (dark, its colour), a thin outline in the rarity colour, orb centred with a soft glow, name white stroked, rarity word small in its colour under it. No green EQUIP buttons on the tiles: tap the tile to select it, and EQUIP/EQUIPPED lives in the detail panel. Equipped tile = thin gold outline + small "EQUIPPED" tag (no gold check circle).
3. Locked/next tiles: "ALTER 5" / unlock condition as a slim grey line, not a purple button.
4. Use the real orb pictures from Downloads\gym_arc_transparent_icons\auras\ (aura_ember, aura_frost, aura_storm, aura_golden, ...), so each aura looks different. If some already use them and still look alike, tell me which ones and I'll make new art.
5. Grid: 4 columns that fill the space left of the detail panel, equal gaps, scroll for the rest (14 / 19 shown with "???" for undiscovered).
```

```text
Inventory > Looks > Alters detail panel: an empty dark bar overlaps the "ALTER 1 · HUMAN TIER" line under GAINS X1.15 (owner screenshot). It's the alter COLOUR VARIANT picker from prompt 61. Fix it the same way as the Auras one:
- A neat row of small round colour swatches in its OWN space under the tier line ("ORIGINAL" + each variant; locked ones dimmed with the coin price; tap = preview, then WEAR). It never overlaps text; the panel lays out top to bottom with a UIListLayout and equal gaps.
- If an alter has no variants (or they haven't loaded), show nothing there (no empty bar).
- Grid tiles: replace the gold check circle on the worn alter with a thin gold outline + small "WORN" tag, same as the auras.
```

```text
PUMP SHOP > STYLE: too many styles. Cut it down to 15 total:
- NAME TAG (8): Violet, Ice, Fire, Gold, Mint (solid) + Sunset, Galaxy, Rainbow (gradients). Solid 10,000-20,000, gradients 60,000-100,000 coins.
- TITLE COLOUR (7): 5 solid + 2 gradients, same price ranges.
- REMOVE the aura colour variants and alter colour variants entirely (shop items, the variant pickers in Inventory > Auras and > Alters, config). Players who already bought one keep it working, shown as a small extra option in its detail panel, but nothing new is sold.
- Every other style beyond these 15: off sale (keep in config as offSale; owners keep theirs).
- Tile art: instead of the same sparkle icon, each tile shows the PLAYER'S OWN NAME (or their current title for title colours) written in that style, big in the middle of the tile. Gradients animate slowly.
- Two small section labels in the row: "NAME TAG" and "TITLE COLOUR", so it's clear what each one changes.
```

```text
On a machine, the bottom-left boost tiles cover the STOP button. Move STOP up so it sits fully ABOVE the boost row, with a 10 px gap, and keep it at least 10 px clear of the left nav / anything above it.
- Make it a layout rule: the boost row always reserves its space at the bottom-left; anything else in that corner (STOP, toasts, Coach Dex dialog edge) stacks above it. When the boost row grows or shrinks (0-6 tiles, "+3" tile), STOP stays clear.
- Check on 667x375, 844x390 and desktop, with 0, 2 and 6 boosts running.
```
