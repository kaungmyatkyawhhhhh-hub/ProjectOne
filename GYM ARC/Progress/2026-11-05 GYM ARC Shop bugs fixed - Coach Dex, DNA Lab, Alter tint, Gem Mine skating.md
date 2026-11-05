---
date: 2026-11-05
tags: [gymarc, progress, bug, shop, monetization]
---
# GYM ARC - shop bugs fixed: Coach Dex, DNA LAB, Alter tint, Gem Mine skating (5 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Shops: [[GYM ARC - Pump Shop]] · Supplements: [[2026-11-05 GYM ARC Supplements - why 0 sales and how to sell more]]

In Studio only. **Not published.** No purchases, receipts or ProcessReceipt touched. No player data changed.

## 1 + 2. DNA LAB empty AND Coach Dex shop won't open: ONE cause
- **What they were meant to do (notes):** DNA LAB = the coin DNA token next to the Robux x1 / x3 ([[2026-10-23 GYM ARC Gear, shop items, monetization and economy]], prompt 60). Coach Dex = SUPPLEMENTS (coin boosts + Shake Bundle, DNA token, DNA x3 for Robux), GEAR (Basic/Pro), SKINS.
- **Cause:** in `PumpShopClient` the line `local ROBUX_COLORS = {...}` (the colours of the Robux tiles) was lost when the PLATES tab code was added on 4 Nov (plates commit). Every Robux tile then crashed the shop's refresh: `PumpShopClient:240: attempt to index nil with 'ShakePack'`.
  - Coach Dex's SUPPLEMENTS tab has Robux tiles, so the refresh crashed BEFORE the window opened: nothing happened when you talked to him.
  - The Pump Shop's DNA LAB has the Robux x1 / x3, so it crashed after clearing the tiles: empty tab.
  - The Pump Shop's SUPPLEMENTS tab has no such tiles, so it kept working (that's why only supplements sold).
- **Live proof (Creator Hub > Error report, last day):** since version V1717 (4 Nov, 5:01 PM): 1,484 x `...with 'ShakePack'` (Coach Dex) + ~227 x `...with 'DnaToken'` (DNA LAB). ![[GYM ARC/Screenshots/2026-11-05_shop_bugs/live_error_report.jpg]]
- **Fix:** the line put back (same colours as the code backup). Nothing else changed in the shop.
- Checked all 620 scripts for other missing names of this kind: none found.

## 3. ALTER TINT removed from the Pump Shop
- **Notes:** alter tints were taken off sale on 23 Oct; owners keep them ([[2026-10-23 GYM ARC Auras tab, colour swatches, STYLE 15, STOP above boosts]]). The STYLE tab still listed owned ones under YOURS with an "ALTER TINT" label (the owner's save has `Alter_Pumped_Crimson`).
- **Fix:** the Pump Shop STYLE tab no longer lists alter tints (`PumpShopClient.styleEntries`).
- Buy path: already closed on the server since 23 Oct (`StyleService.Buy` only sells the 15 name/title colours). Not a developer product, so nothing in ProcessReceipt.
- Saves untouched: `data.style.owned` / `data.style.alter` keep every tint.
- **Owner to decide:** "can still use it" — on 27 Oct the owner had the Inventory alter tint chips turned off and the body no longer shows a worn tint ([[GYM ARC - Body Alters]]). So today a bought tint has no visible effect anywhere. Bring it back (Inventory > Alters chips + body tint), or leave it off?

## Extra: skateboarding inside the Gem Mine (owner, 5 Nov)
- **Cause:** the no-skate box `Town.GemMineGym` covered only the middle of the cave (X 122..188, Z 94..143); the hall (`GemMineGym.Zone`) is X 68..214, Z 94..168. West, east and south parts counted as "outdoors".
- **Fix:** `Town.GemMineHall`: inside the cave's area AND below street level (Y < -1) = inside. A flat box that big would have blocked skating on the streets above. Both the SKATE button (client) and the server's 0.5 s check use it, so riding in from outside takes the board away too.
- Checked: cave west / east / south / middle / descent ramp = no skating; streets above the cave and the plaza = skating.

## 4. Sales: what Coach Dex sells vs the Pump Shop supplements (nothing changed)
| Kind | Coach Dex (coins) | Pump Shop (Robux, x1 25 / x5 99) |
|---|---|---|
| EXP | Creatine +25% 10 min (1,200) · Protein Powder +25% 10 min (1,200) · Supplements +10% 15 min (900); one at a time | Whey Isolate +100% 15 min · Mass Gainer +150% 10 min; stack on top |
| Rep speed | Pre-Workout +25% 5 min (900) | Elite Pre-Workout +50% 10 min |
| Stamina | Protein Shake: full stamina + 50% EXP 30 s (250) | BCAA Recovery 2x regen 15 min |
| Robux at Dex | Shake Bundle, DNA Token, DNA x3 | — |
- Overlap: same 3 kinds; the Robux ones are already 2-6x stronger and stack (since 1 Nov). Nothing moved, hidden or repriced. The fix doesn't add any link from the Pump Shop to Dex (the Dex shop window already had a "Go to Pump Shop" link; Dex's line says "The PUMP SHOP in town has the strong stuff").
- Expect: with Dex's coin shop back, some players will buy coin boosts again (that was the situation before the bug).

## 5. Tests
- Studio, solo: fresh player (FreshPlayer, temp data) and the owner's max save (7'4"), PC and phone layout (TestInput Touch).
  - Coach Dex opens from his Talk prompt (walk up + E), all tiles incl. Shake Bundle / DNA / DNA x3. ![[GYM ARC/Screenshots/2026-11-05_shop_bugs/coach_dex_max_player_phone_prompt.jpg]] ![[GYM ARC/Screenshots/2026-11-05_shop_bugs/coach_dex_fresh_player.jpg]]
  - DNA LAB: coin token 25,000 + Robux x1 (90) + x3 (225), prices from Roblox. ![[GYM ARC/Screenshots/2026-11-05_shop_bugs/dna_lab_fixed.jpg]]
  - STYLE: no alter tint. ![[GYM ARC/Screenshots/2026-11-05_shop_bugs/pump_style_no_alter_tint.jpg]]
  - No console errors.
- **Not done:** 2-player local server (the Studio tool can only start solo play); private live server (needs a publish); real phone tap on the prompt (ClickablePrompt is on).
- Owner: Studio > Test > Clients and Servers > 2 players, talk to Dex on both; after publishing, check that the Error report line stops.

## Supplements "sell more" prompt: numbers report (NOT built, waiting for OK)
Facts first:
- The 3-kind merge (Gains / Stamina / Luck, prompt 97) was never built: today there are 4 Robux supplements (above). There is **no Luck boost**, and Robux luck clashes with the owner rule of 29 Oct ("rolls are coins-only, no Robux luck") and the Playbook. Need a decision.
- Boosts already work during Auto Rep (they apply to every rep; nothing pauses them).
- Mass Gainer (x2.5) and Whey (x2) are the same kind of boost (EXP = Growth Spurt progress); Creatine and Protein Powder are both x1.25.
- Check needed before building: the overall EXP cap (x5, +1 per alter tier). A high player with trainers + passes may already sit at the cap, so a Whey/Mass Gainer would add little for them.

Proposal (coin boosts unchanged):
| Robux item | Now | Proposed |
|---|---|---|
| Whey Isolate (EXP) | +100% 15 min | +100% **30 min** |
| Mass Gainer (progress) | +150% 10 min | +150% **20 min** |
| Elite Pre-Workout (speed) | +50% 10 min | +50% **20 min** |
| BCAA Recovery (stamina) | 2x regen 15 min | 2x regen **30 min + full stamina on use** |
| Price | x1 25 · x5 99 | same; x5 card says "Save 26 R$" (5 x 25 = 125, real) |
Then (after OK): HUD boost slot with "+", "See boost" cards at stamina 0 / after a Growth Spurt or NEW PR (max 1 per 5 min, never after a fail or lost arm wrestle, close button), analytics per placement (stamina-0, HUD slot, PR, Pump Shop).
