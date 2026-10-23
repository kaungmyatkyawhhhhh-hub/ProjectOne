---
date: 2026-10-14
tags: [gymarc, prompt, monetization]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: how players get DNA Tokens (14 Oct)

```text
DNA TOKENS: change how players get them. Save this to Obsidian first.

Only 3 ways to get a DNA Token, nothing else:
1. FREE: +1 token for every growth spurt the player completes (one per spurt, given once, server-side). Show a toast "+1 DNA Token" with the growth spurt celebration.
2. COINS: buy 1 token for 25,000 coins (Config.DNA.CoinPrice = 25000). In the Shop (Boosts tab or a Genetics section) and on the genetics screen next to REROLL. Server checks and removes the coins; not enough coins = shake + "Not enough coins" toast.
3. ROBUX: Developer Product "DNA Token", 99 Robux, gives 1 token. ID: Config.Products.DNAToken = 0 (placeholder, I'll send the real ID). Use the existing ProcessReceipt handler: give the token only after the data is saved, and record PurchaseId so it's never given twice.

Remove every other source of DNA tokens (daily rewards, quests, achievements, level-ups, codes, starting tokens, anything else). Players keep the tokens they already have.

Genetics screen:
- Show the token count (gold).
- If they have 0 tokens, REROLL opens a small choice: "25,000 coins" or "R$ 99". Never auto-spend coins without them tapping.
- Tokens are saved in the player's data and can't go negative. All checks are on the server.

Test: growth spurt gives exactly 1, buying with coins works and fails correctly, Robux purchase in Studio test mode gives 1 (and not again on rejoin). Commit, update PROGRESS.md and Obsidian.
```

Follow-up message:

```text
this is the id for the dna token: 3718499538
```
