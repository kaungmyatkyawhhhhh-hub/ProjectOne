---
date: 2026-10-21
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-21 GYM ARC Boosts inventory

Prompt: [[2026-10-20 GYM ARC Prompt - 14 Boosts inventory]]. Feature note: [[GYM ARC - Boosts Inventory]].

## What changed
- New Inventory **Boosts** tab (first tab): Protein Shake, Coconut Water, Creatine, Protein Powder, Supplements with USE and EQUIP (backpack Tool).
- Boost timers by the stamina bar (max 4, foldable, tap for info). Time pauses while away.
- The old Energy Shakes are the inventory's Protein Shakes (moved over for every save). The quick shake button uses the inventory and shows 0 / grey when empty. The Shake Bundle adds to the inventory with a USE NOW popup. Login days 2 and 5 give Coconut Water and Creatine.
- Studio-only `/give <item> <count>` for the owner.

## Tested in Studio (phone layout)
Tutorial shake step from the inventory (1 -> 0, funnel step 06 logged); `/give` for every item; USE (Creatine 5 -> 4, 10:00 timer on the HUD); EQUIP then activating the Tool (Coconut Water 2 -> 1, its timer started); the "Added to inventory" popup. No errors in Output.

## Needs the owner
- Icons are placeholders.
- Two "Protein Shake"s now: the inventory one (old Energy Shake) and the smoothie bar's (+20% EXP 5 min). Rename one?
- Check EQUIP on a real phone (the Roblox hotbar didn't show in my Studio phone test).
- Creatine and Protein Powder both work as EXP boosts.
