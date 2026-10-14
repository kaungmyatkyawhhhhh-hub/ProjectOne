---
date: 2026-10-14
tags: [gymarc, bug, monetization]
status: fixed
---
# GYM ARC - Bug - Store showed only one pass

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** The Store only showed the Extra Trainer pass.
- **Cause:** Not an error: every other pass and product still had no id in `Config/Monetization` (only the ids the owner had sent were in), and the Store hides items without an id.
- **Fix:** All the owner's ids are in, each with its Store tab (Passes / Coins / Boosts), its shop art and a fallback name and price. The Store reads each item's real name / price / icon from Roblox once when the game starts (each item separately, retried 3 times, cached); if that fails the item still shows with the fallback. An id of 0 is skipped with a warning. Owned passes keep their OWNED stamp.
- **Commit:** f9a48e2
- **Status:** fixed

![[GYM ARC/Screenshots/store_passes.jpg]]
![[GYM ARC/Screenshots/store_coins.jpg]]
![[GYM ARC/Screenshots/store_boosts.jpg]]
