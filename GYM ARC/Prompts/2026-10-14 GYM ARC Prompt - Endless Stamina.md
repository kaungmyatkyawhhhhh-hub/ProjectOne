---
date: 2026-10-14
tags: [gymarc, prompt, monetization]
status: in progress
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: Stamina Refill becomes Endless Stamina (14 Oct)

```text
STAMINA REFILL -> ENDLESS STAMINA (15 min). Same product ID 3718306417, renamed in Creator Hub.
- Buying it gives 15 minutes of no stamina drain (stamina stays full while lifting and on treadmills). It does NOT refill once and stop.
- Buying again while active adds 15 more minutes (stacks, max 60 min).
- The timer only counts down while the player is in the game. Save the remaining time if they leave, so they keep the rest next time.
- Give it only inside ProcessReceipt after the purchase is saved, using PurchaseId so it's never given twice.
- UI: a boost icon with a countdown (e.g. "14:32") in the active boosts row. While it's active, the stamina bar turns gold with a slow shine and an infinity symbol next to the number.
- Store: update the name, description and icon (Downloads\gym_arc_shop_icons\product_endless_stamina.png, upload and find the ID with search_asset), and move it to the BOOSTS tab.
- Auto Rep still works normally with it (it just never needs to rest).
Test: buy in Studio test mode, lift for a while (stamina doesn't drop), leave and rejoin (time kept), buy twice (stacks). Commit, update PROGRESS.md and Obsidian.
```
