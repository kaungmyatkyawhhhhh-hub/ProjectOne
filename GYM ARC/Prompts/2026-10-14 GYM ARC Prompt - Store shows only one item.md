---
date: 2026-10-14
tags: [gymarc, prompt, bug, monetization]
status: in progress
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: the Store only shows the Extra Trainer pass (14 Oct)

```text
BUG: the Store only shows the Extra Trainer pass. Everything else is missing.

1. Find why: check Output for errors when the Store opens. Likely causes: GetProductInfo erroring on one item (e.g. a placeholder ID 0) and stopping the whole loop, wrong InfoType (Enum.InfoType.GamePass for passes, Enum.InfoType.Product for products), a tab/category filter, or a recent refactor that dropped items from Config.
2. Fix it so one bad item can never break the shop:
   - Wrap every GetProductInfo in pcall, with retry and cache. If it fails, use the fallback name/price/icon from Config instead of skipping the item.
   - Skip IDs that are 0 (placeholders) quietly, and log a warning.
   - Use MarketplaceService:GetProductInfo once per item when the game starts and cache it, not every time the shop opens.
3. Make sure the Store has all of these:
   PASSES tab: 2x EXP 2032508303, 2x Coins 2032286316, VIP 2032988308, Aura Pack 2033954299, Auto Rep 2033558291, Extra Trainer 2032496303
   COINS tab: Small Coins 3718306241, Medium 3718306326, Large 3718306360
   BOOSTS tab: Shake Bundle 3718306390, Stamina Refill 3718306417, Skip Growth Cooldown 3718306447
   (DNA Token and Quest Reroll: add later when I send IDs. Until then, hidden.)
4. Owned passes show the gold OWNED stamp and stay in the list (don't hide them).
5. Test: open every tab, every item shows the right name, icon and price, and buying works in Studio test mode. Screenshot every tab.

Commit, update PROGRESS.md and Obsidian.
```
