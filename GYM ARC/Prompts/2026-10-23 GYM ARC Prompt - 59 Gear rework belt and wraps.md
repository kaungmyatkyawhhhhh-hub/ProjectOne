---
date: 2026-10-23
tags: [gymarc, prompt]
status: todo
---
# 59 Gear rework: Belt + Wrist Wraps only

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Owner decision, 23 Oct: too many gear pieces. Gear is now only TWO items: the LIFTING BELT and the WRIST WRAPS. This replaces the gear plan in prompts 31, 47 and 57 (section 6). Follow CLAUDE.md Speed rules. Mobile first. Never undo the owner's manual Studio changes. Never delete player data: migrate it.

1) THE 2 ITEMS
- LIFTING BELT: boosts LOWER-BODY gains (legs, back, core).
- WRIST WRAPS: boosts UPPER-BODY gains (chest, arms, shoulders).
- Each has levels. For now only 2 are on sale: BASIC and PRO (coins, at Coach Dex > GEAR). Keep ELITE and CHAMPION in config as offSale for later.
- Suggested numbers (config): BASIC +5%, PRO +10% to that half of the body. Prices: keep the current Basic/Pro belt and wraps prices.
- Owning PRO means BASIC is replaced (only the best level you own counts; no stacking).
- Equipped automatically when bought (no gear slots to manage). Both show on the body as now (belt on the waist, wraps on the wrists).
- Icons: Downloads\gym_arc_gear_icons\ belt_basic, belt_pro, wraps_basic, wraps_pro (elite_/champion_ files stay spare).

2) REMOVE
- LIFTING STRAPS and KNEE SLEEVES: remove from shops, Inventory, config (keep the old entries commented for migration), and remove their 3D gear from bodies (players, trainers, NPCs).
- Any per-lift gear text like "+15% SQUAT GAINS" becomes "+10% LOWER BODY" / "+10% UPPER BODY".

3) MIGRATE OWNED GEAR (once per player, saved flag)
- Belt / wraps they already own: keep the level they own (Elite/Champion owners keep it working, shown in Inventory, just not sold).
- Straps -> counts toward WRIST WRAPS, sleeves -> counts toward the LIFTING BELT: if the player owns a higher level of straps/sleeves than of the matching item, they get that level of the matching item instead. Otherwise refund the coins they paid for the removed piece (from config prices).
- Anything bought with Robux is never lost: convert it to the matching item at the same level.
- Show a one-time popup: "Gear got simpler! Belt = lower body, Wraps = upper body." plus "+X COINS refunded" if any.

4) UI
- Coach Dex > GEAR: just 2 rows (BELT and WRAPS), each showing BASIC and PRO tiles side by side with the boost, price or OWNED, in the premium style (prompt 57 / PUMP SHOP style).
- Inventory > Gear: 2 tiles (your current belt and wraps level, or an empty "NO BELT YET" tile with "GET AT COACH DEX" that teleports there).
- Bottom-left boost row / stats: gear shows as part of the body-half boost; the hover card says "PRO BELT · +10% LOWER BODY".

TEST: a fresh save (buy Basic then Pro belt), an old save with straps + sleeves (migration + popup + refund), a save with an Elite belt (keeps working). Phone screenshots of Coach Dex GEAR and Inventory > Gear. Short progress note in the vault + update the gear note.
```
