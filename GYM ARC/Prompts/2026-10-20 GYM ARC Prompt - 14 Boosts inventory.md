---
date: 2026-10-20
tags: [gymarc, prompt]
status: todo
---
# 14 Boosts inventory

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Rework protein shakes and other consumables into an inventory system. No shop for these yet, only the inventory. Follow CLAUDE.md Speed rules. UI is Black + Gold, mobile first.

1) BOOSTS SECTION IN THE INVENTORY
- The Inventory menu (the old Titles button) gets tabs: Boosts first, then the existing ones (titles, auras, etc.). Don't break the existing tabs.
- Boosts shows a grid of item cards: icon, name, and count (x3). Items with 0 are hidden.
- Tapping a card opens a small panel: icon, name, what it does, duration, and two buttons:
  - USE: consumes 1 right away (drink animation + sound), with no equipping.
  - EQUIP: puts it in the player's Roblox backpack/hotbar as a Tool. Activating the Tool drinks it, uses 1 and removes the Tool if the count reaches 0. Pressing EQUIP again (now "UNEQUIP") takes it out of the backpack.

2) ITEMS (put these numbers in one config module so I can tune them)
- Protein Shake: keep its current effect exactly (stamina etc.).
- Coconut Water: refills 50% stamina right away, +50% stamina regen for 2 min.
- Creatine: +25% strength/rep EXP for 10 min.
- Protein Powder: +25% Growth Spurt progress for 10 min.
- Supplements (multivitamin): +10% to all training gains for 15 min.
Rules: using the same boost again adds its time (max 60 min). Different boosts stack. Boosts keep counting down while offline? NO: they only count down while in game. Save counts and remaining times in the player's data.

3) ACTIVE BOOSTS DISPLAY
- Small icons with timers (e.g. 9:42) near the stamina bar, max 4 shown, collapsible. Tapping one shows the name and effect.

4) CONNECT WHAT EXISTS
- Shake developer products (Small, Medium, Large, Shake Bundle) now ADD to the inventory instead of being used instantly. After buying, show "Added to inventory" with a USE NOW button.
- Existing saved shakes / old shake data: migrate them into the inventory count, so nobody loses anything.
- Keep a quick shake button on the HUD that uses 1 Protein Shake from the inventory (one tap, needed for the tutorial). Show "0" and grey it out when empty.
- Tutorial step 6 (drink the free shake) must still work and still log the same funnel step name: the free shake is added to the inventory and the pulsing button uses it.
- Daily rewards and quest rewards that gave shakes now add them to the inventory. Also add 1 Coconut Water to daily reward day 2 and 1 Creatine to day 5 so players see the new items.

5) TESTING
- Add a Studio-only command (only the owner's UserId) to give any item: /give creatine 5.
- Icons: use simple placeholders for now. I will make proper icons.

Short progress note in the vault.
```
