---
date: 2026-10-14
tags: [gymarc, prompt, monetization]
status: in progress
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: quest rerolls (14 Oct)

```text
- 1 FREE quest reroll per daily reset (same reset as daily quests). Config.Quests.FreeRerollsPerDay = 1. Saved in player data with the reset day, so rejoining or switching servers doesn't give another.
- After the free one is used, every reroll costs R$ 19: Developer Product "Quest Reroll", Config.Products.QuestReroll = 0 (placeholder, I'll send the ID). Reroll ONLY inside ProcessReceipt after the purchase is confirmed and saved, using PurchaseId so it never happens twice or gets lost. Remember which quest they chose to reroll before prompting the purchase.
- Reroll swaps one quest for a new random one (never the same quest, never a duplicate of the other two). Completed/claimed quests can't be rerolled.
- Button text: "REROLL - FREE" (gold) when the free one is ready, "REROLL - R$ 19" after. Small "Free reroll in 5h 12m" under it.
- All checks on the server.

Test: free once per day only (fake the date in Studio to test the reset), R$ 19 rerolls exactly one quest, rejoin doesn't refresh the free one, can't reroll a done quest. Commit, update PROGRESS.md and Obsidian.
```
