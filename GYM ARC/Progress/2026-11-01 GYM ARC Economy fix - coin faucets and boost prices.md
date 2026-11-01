---
date: 2026-11-01
tags: [gymarc, progress, economy]
---
# GYM ARC - economy fix: coin faucets cut, Coach Dex boosts dearer (1 Nov)

Owner: "the game economy is broken rn. the coach dex boosts are like 300 and i used an alt account and i got 100k coins in 15 mins of playing from growth spurt 1 to growth spurt 6".

## Why (from Config + vault)
- Design income (PumpShop.CoinsPerMinute, tests/pacing): 55 / 84 / 119 / 179 / 255 / 304 / 328 coins a minute by spurt, so 15 min of reps ~3-5k coins.
- The big fixed rewards were set as "minutes of coins" for slow spurts (design: spurts 1-6 take ~56 min; the alt did it in 15).
  - Spurt milestones 100/200/300 x the spurt number: 12,600 coins over spurts 1-6.
  - Posing / runway show every 5 min, 1st place 500 / 1,500 / 4,000 / 6,000 / 8,000 (NPC-filled divisions, easy to win): up to ~25 min of income every 5 min.
  - Strongman Showdown 5,000 / 3,000 / 1,500 / 200.
  - Plus quests, daily, playtime, codes (RELEASE 1,800, HALLOFFAME 2,700), rivals.
- The Analytics Economy dashboard on the Creator Hub has no data yet (no live numbers to confirm the exact split).

## Changes
| Thing | Before | Now |
|---|---|---|
| Spurt milestones 25/50/75% | 100/200/300 x spurt number | 50 / 100 / 150 flat |
| Shows 1st/2nd/3rd/enter | Local 500/300/200/50 · Regional 1,500 · National 4,000 · ProQ 6,000 · Universe 8,000 | Local 150/90/60/20 · Regional 300/180/120/30 · National 500/300/200/50 · ProQ 600/360/240/60 · Universe 700/420/280/70 (1st ≈ 2 min of that stage's coins) |
| Strongman 1st/2nd/3rd/enter | 5,000/3,000/1,500/200 | 1,500/900/500/100 |
| Coach Dex Shake / Coconut Water | 100 | 250 |
| Supplements / Pre-Workout | 300 | 900 |
| Creatine / Protein Powder | 400 | 1,200 |
| Mass Gainer / Elite Pre / Whey / BCAA | 2,500 / 2,150 / 2,850 / 2,150 | 5,000 / 4,300 / 5,700 / 4,300 |
Rep coins, gear, DNA, cosmetics, login, quests, codes unchanged.

## New tool: where coins come from
Live console (F9 > Server): `game.ServerStorage.Admin:Invoke("earned", "AltName")` lists every coin that player got this session by source with %.
Use it on the alt after a 15 min run to confirm the split.

## Also (same day)
- Small popups: titles and buttons in the premium font (Montserrat Black Italic), titles in capitals; shop picture fixed (stayed see-through after the fade).
- Open question: spurts 1-6 in 15 min on the alt vs the ~56 min design (4/5/8/12/14/17). Check with the ledger + timing.

## Boosts: Pump Shop specials worth buying (1 Nov, later)
Owner: "people dont buy those special boosts at pump shop because they are so rich in coins and they only buy the coach dex coin boosts".
- Cause: Coach Dex's EXP boosts all stacked (Creatine +25% + Protein Powder +25% + Supplements +10% = +60%), more than a Robux special (+50%), for coins.
- Coach Dex EXP boosts (Creatine, Protein Powder, Supplements) are now ONE group (Config/Boosts `group = "CoachExp"`): one at a time. Using another while one runs is refused (no item used, toast "X is still running · One Coach Dex EXP boost at a time. Pump Shop specials stack on top"); the same one still adds time. BoostService also counts only the strongest of a group (old saves with several running).
- Robux specials stronger and stack on top: Whey Isolate +50% -> 2x EXP (+100%, 15 min); Mass Gainer +50% -> +150% (10 min). Elite Pre-Workout +50% speed and BCAA 2x regen unchanged (already 2x the coin versions).
- Best coin setup now +25%; with Whey on top +125%; Robux prices unchanged (x1 25 / x5 99).
- Tested in Studio: Supplements used, Creatine then refused and not taken.
- Owner to-do: the Roblox product descriptions for Whey / Mass Gainer (Creator Hub) if they mention +50%.

## Bug: one boost showed "x2" (1 Nov)
Owner (account HEINHEIN1922): one Mass Gainer showed "MASS GAINER x2", every boost did.
- Not a pass (no pass doubles boosts). The active-boost tile's tag = time left / one dose. Auras with a boost-time perk make one use longer: Toxic +10%, and Void (+10% Everything) / Galaxy (+5% Everything) count too (Auras.Perk adds `all`). 11 min left / 10 min dose = "x2".
- Fix (ActiveBoostsClient): the dose includes the worn aura's boost-time perk. One use = no tag; two uses = x2. The longer time itself was real and stays.
