---
date: 2026-10-23
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Pump Shop premium restyle

Prompt: [[2026-10-23 GYM ARC Prompt - Pump Shop premium restyle]]. Game commit 136881c.

## What changed
- **Window:** the Pump Shop, which is also Coach Dex's shop and the coconut stand, now matches the Alters / Auras panels. Tabs, title, coins and X are unchanged.
- **Tiles:**
  - a soft background in the item's colour with faint rings behind the icon and a dark fade at the bottom;
  - a thin outline in its colour; the picked tile gets a gold outline with the soft glow (`ReadyGlow`);
  - the icon centred on a glow;
  - the name white and stroked, one line, shrinking to fit;
  - the effect in a slim dark pill outlined in its colour. Long effects are shortened: "+100%" becomes "2x", and an effect over 20 characters drops its time (the strip still says it). BCAA no longer overflows.
- **Price:** a slim graphite button with a coin.
  - Can't afford: the price in red and "NEED x MORE" under it.
  - Owned gear: a gold OWNED. Gear sold at the other shop: "AT COACH DEX".
  - Tapping the price only picks the tile; buying stays in the strip, so kids don't spend by accident.
- **Strip:** the item's background, icon on a glow, white stroked name, one light grey line.
  - Slim graphite buttons with a gold outline, a coin and the price (x1, x5, Buy Pro, Buy token, Reroll); red when you can't afford.
  - A small BEST tag shows on x5 only if it's cheaper per item. Today x5 is exactly 5 times the price, so it never shows.
- **Kept:** the buy animation (coins count down, the item flies to the Inventory button) and the select bounce + sound.
- **Agency:** no gold checkmarks on the tiles. Owned trainers already show their art, and the "x2" count stays. MY TRAINERS keeps its check for equipped trainers.

## Tested (Studio 844x390)
- Pump Shop: Supplements, a real buy, and the can't-afford state.
- Gear, DNA Lab, and Coach Dex's shop.
- The Agency without checks.
- No script errors; the tests pass.

![[GYM ARC/Screenshots/pump_shop/00_ref_alters_panel.jpg]]
![[GYM ARC/Screenshots/pump_shop/01_supplements.jpg]]
![[GYM ARC/Screenshots/pump_shop/02_supplements_cant_afford.jpg]]
![[GYM ARC/Screenshots/pump_shop/03_gear.jpg]]
![[GYM ARC/Screenshots/pump_shop/04_dna_lab.jpg]]
![[GYM ARC/Screenshots/pump_shop/05_coach_dex.jpg]]
![[GYM ARC/Screenshots/pump_shop/06_agency_no_checks.jpg]]
