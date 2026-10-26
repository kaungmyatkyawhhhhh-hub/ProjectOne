---
date: 2026-10-26
tags: [gymarc, feature, retention]
status: active
---
Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Features index|All features]]

# GYM ARC - Playtime Gifts

Gifts for the minutes you play each day, so there's always a reason to play a little longer.

- **When:** after 3, 8, 15, 25, 40 and 60 minutes played **today** (UTC day). Time counts across rejoins (saved), and a new set starts the next day.
- **What:** 2 min of coins (at least 50), a Protein Shake, 4 min of coins (at least 100), a Creatine, 8 min of coins (at least 250), then a free trainer roll (10 min of coins, at least 300, before trainers open at Growth Spurt 1).
- **How:** paid by itself (nothing to tap) once the tutorial is done. A reward popup in the toast lane says what you got and the next gift: "PLAYTIME GIFT 2/6 · Protein Shake. Next: +330 coins in 7 min". After the 6th it says "Come back tomorrow for more gifts!"
- **No new HUD card:** the right column only shows TODAY'S QUEST and TAP TO GROW (owner, 22 Oct).
- **Code:** `Config/Playtime` (all numbers), `Server/PlaytimeService` (counts and pays; save `data.playtime = { day, seconds, claimed }`), `PlaytimeClient` (popup), `TrainerService.AddFreeRolls`. Analytics custom event `PlaytimeGift` (value = gift number).
- Added 26 Oct: [[2026-10-26 GYM ARC Retention pass]].
