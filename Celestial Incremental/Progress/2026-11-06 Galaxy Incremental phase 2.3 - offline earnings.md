---
date: 2026-11-06
tags: [galaxy, progress, phase-2]
status: built and tested in Studio; NOT published, NOT saved
---
# Galaxy Incremental - Phase 2.3: OFFLINE EARNINGS + the return screen (6 Nov, Claude Code)

Step 2.3 of [[2026-11-06 Galaxy Incremental - Prompt - Phases 2 and 3 + trend changes]]. Checklist rows: **#411 #454 #91**.

## What's new
- **Offline earnings (server):** 50% of your income for the time away, up to 4 h. LONG NIGHT makes it 6 h, DEEP SLEEP 75%.
  - "Your income" here leaves out the timed boosts (Star Surge, potions, friends in the server), so a potion running at the moment you leave doesn't count for hours.
  - Under 2 min away = nothing.
  - It counts toward the Supernova (it's income).
- **The RETURN screen** ("WHILE YOU WERE AWAY", screens `2.3-pc-return-screen`, `2.3-phone-return-screen`):
  - how long you were away
  - the amount, counting up over 1.2 s with ticks
  - the rule ("50% of your income, up to 4 h")
  - **CLAIM**, free
  - **X also claims:** it never blocks play and never loses what you earned. Opening another window also claims.
- **x2 CLAIM (Robux):** the developer product `GameConfig.Products.OfflineX2`, **PROPOSED 25 R$**.
  - Why: a small impulse buy (Depth's cheapest offer is 32 R$), and it never sells luck.
  - Its id is 0 until you create it in Creator Hub, and **the button stays hidden until then**.
- **ProcessReceipt (#454):** the only place a product is granted (GalaxyStoreService).
  - The session must be loaded.
  - A PurchaseId already in the save gets "granted" without a second grant.
  - The grant + the receipt are saved before Roblox hears "granted". A failed save = NotProcessedYet, so Roblox asks again; the receipt in memory stops a double grant meanwhile.
- **Saves (#91):** every save tries 3 times (1 s, then 3 s apart) and stamps lastSeen. Saved after a pass purchase too.
- **Save version 4:** every Phase 2 field (automation switches, capstone, offline, streak, quests, gifts, free rewards, receipts, counters). An older save loads with them empty (checked: the Studio test save and fresh saves).

## Tests (Studio)
- **`TestOfflineHours = 3`:** "You were away 3h 0m", +106B (= 3 h × 50% × that save's income). CLAIM paid it once, a second CLAIM was refused.
- **`TestReceipt = "OfflineX2"`:** the same PurchaseId was sent twice.
  - Both answers were "granted", but the stardust went up only once, by exactly 2 × the amount shown (2.135e11).
- **Not tested:** a real Robux purchase. There is no product id yet, and Studio can't buy one.
