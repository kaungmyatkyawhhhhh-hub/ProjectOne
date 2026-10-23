---
date: 2026-10-23
tags: [gymarc, progress, monetization]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Shop product IDs wired (prompt 63)

Prompt: [[2026-10-23 GYM ARC Prompt - 63 Wire the shop product IDs|63 Wire the shop product IDs]]. Feature: [[GYM ARC - Monetization]]. Game commit f3d2f0d.

## What changed
- The owner's 10 new developer product IDs are in `Config/Monetization` (they were 0 = hidden). Nothing else needed code: the grants, the Store and the PUMP SHOP were built in prompts 57 / 60 and only waited for the IDs.
- All go through `MonetizationService` ProcessReceipt: the purchase id is remembered in the save, the save is stored, and only then Roblox hears PurchaseGranted (a retried receipt never grants twice).
- The PUMP SHOP specials now show x1 / x5 Robux buttons (BEST on x5) instead of SOON. DNA LAB shows DNA Token x3. The Store shows DNA Token x3 and the Starter Pack (pinned until bought).

| Product | ID | Roblox name / price (checked) | Gives |
|---|---|---|---|
| Starter Pack | 3721356162 | Starter Pack, 49 | once: coins (60 min, 5k-10k), 3 shakes, 1 DNA token, 30 min 2x EXP item, STARTER title; bought again = its value in coins |
| DNA Token x3 | 3721356358 | DNA Tokens X3, 249 | 3 DNA tokens |
| Mass Gainer | 3721356862 | Mass Gainer, 25 | 1 |
| Mass Gainer x5 | 3721356950 | Mass Gainer X5, 99 | 5 |
| Elite Pre-Workout | 3721357276 | Elite Pre-Workout, 25 | 1 |
| Elite Pre-Workout x5 | 3721357343 | Elite Pre-Workout X5, 99 | 5 |
| Whey Isolate | 3721357465 | Whey Isolate, 25 | 1 |
| Whey Isolate x5 | 3721357767 | Whey Isolate X5, 99 | 5 |
| BCAA Recovery | 3721357940 | BCAA Recovery, 25 | 1 |
| BCAA Recovery x5 | 3721358083 | BCAA Recovery X5, 99 | 5 |

All 10 are on sale on Roblox and the names / prices match Config.

## Test purchases (Studio, owner's test save, Workspace TestReceipt hook = the real ProcessReceipt)
Each purchase id was sent twice; then the game was stopped, rejoined and 3 of them were sent a third time.

| Product | 1st receipt | Same id again | After rejoin | Save before -> after |
|---|---|---|---|---|
| Starter Pack | Granted (already owned on this save: paid its value, +37,955 coins) | Granted, nothing added | Granted, nothing added | coins 10,588 -> 48,543 |
| DNA Token x3 | Granted | Granted, nothing added | Granted, nothing added | tokens 11 -> 14 |
| Mass Gainer x1 + x5 | Granted | Granted, nothing added | (x5) nothing added | 1 -> 7 |
| Elite Pre-Workout x1 + x5 | Granted | Granted, nothing added | - | 0 -> 6 |
| Whey Isolate x1 + x5 | Granted | Granted, nothing added | - | 0 -> 6 |
| BCAA Recovery x1 + x5 | Granted | Granted, nothing added | - | 0 -> 6 |

- Each grant fired `Product_Bought_<key>` once (the repeats did not).
- Store prices loaded from Roblox for every item (Price_ attributes: StarterPack 49, DnaTokenPack 249, plus all old items).
- The Starter Pack's first-time grant was not re-run (this save already owns it from the prompt 60 test, which used the same code path).
- The test items, DNA tokens and coins stay on the test save.

![[GYM ARC/Screenshots/p63/pumpshop_supplements.jpg]]
![[GYM ARC/Screenshots/p63/pumpshop_dnalab.jpg]]
