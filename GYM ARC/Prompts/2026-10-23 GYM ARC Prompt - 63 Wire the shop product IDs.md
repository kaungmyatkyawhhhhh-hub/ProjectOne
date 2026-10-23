---
date: 2026-10-23
tags: [gymarc, prompt]
status: done
---
# 63 Wire the shop product IDs

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
New developer product IDs (owner created them on the Creator Hub). Put them in Config.Monetization and wire them up (prompts 57 + 60):
- Starter Pack = 3721356162 (49 R$)
- DNA Tokens x3 = 3721356358 (249 R$)
- Mass Gainer = 3721356862 (25 R$)
- Mass Gainer x5 = 3721356950 (99 R$)
- Elite Pre-Workout = 3721357276 (25 R$)
- Elite Pre-Workout x5 = 3721357343 (99 R$)
- Whey Isolate = 3721357465 (25 R$)
- Whey Isolate x5 = 3721357767 (99 R$)
- BCAA Recovery = 3721357940 (25 R$)
- BCAA Recovery x5 = 3721358083 (99 R$)
Make sure every one goes through ProcessReceipt (save before PurchaseGranted, never grant twice), the x5 ones give 5, and the Store/PUMP SHOP show Roblox's real prices. Test each with a Studio test purchase and list the results in the progress note.
```

Done: [[2026-10-23 GYM ARC Shop product IDs wired]].
