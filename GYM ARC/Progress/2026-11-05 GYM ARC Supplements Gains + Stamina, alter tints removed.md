---
date: 2026-11-05
tags: [gymarc, progress, monetization, supplements, alters]
---
# GYM ARC - Supplements GAINS + STAMINA, alter tints removed (5 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Before: [[2026-11-05 GYM ARC Shop bugs fixed - Coach Dex, DNA Lab, Alter tint, Gem Mine skating]] · Why: [[2026-11-05 GYM ARC Supplements - why 0 sales and how to sell more]]

In Studio only. **Not published.** No receipts or ProcessReceipt code changed. Coach Dex's coin supplements unchanged.

## Owner decisions (5 Nov)
1. Alter tints: remove for good (Pump Shop, Inventory chips, body tint). Owners get what they paid (coins) or a similar skin; Robux buyers also a popup. Count owners first.
2. Supplements: build GAINS + STAMINA. Robux stays stronger / longer than coin, but not game-breaking (~1.6x cap, like a Legendary run card +60%). Coach Dex coin supplements stay exactly as they are. **No Luck for Robux** (paid random-item modifier: live odds + PolicyService). Luck stays coin-only, later.
3. Publish today after a private-server test (Coach Dex PC + phone, DNA Lab, tints, supplements). GEM parts stay switched off.

## 1. Alter tints: who owned one
- Read-only scan of the live saves (`GymArcDataStoreV1`) of every player who ever reached an alter: `LB2_Alters` + `LB2_HallOfFame` (796) + the old `LB1_Alters` and both Tallest boards from 7'0" (89 more) = **885 saves**.
- **1 owner: the owner's own account** (848360565, `Alter_Pumped_Crimson`, 40,000 coins). No real player owned a tint.
- Tints were only ever sold for **coins** (40,000 / 80,000, prompt 61, on sale for part of 23 Oct). Never a developer product: nothing in ProcessReceipt, no Robux popup needed.

## 1b. Tints removed (built)
- `DataMigrations.TintRefund` (every load, not a version step, so the place can still be rolled back): each `Alter_<alter>_<tint>` in `data.style.owned` -> its coins back (`Style.AlterTintPrice`: 1st tint 40,000, 2nd 80,000), the ids and the worn tints (`data.style.alter`) removed, a record in `data.style.tintRefund`. Runs once (after that nothing is left). Tested: 3 tints -> +200,000; run twice -> no double pay; a save with none -> unchanged.
- Code gone: `Style.Items` alter entries, `Style.Parse` "Alter", `StyleService` wear "Alter", `BodyService` tint, `MuscleRig` skin tint + `AlterTintPreview`, Inventory tint chips (`AltersPanel`). The price list stays in `Config/Style` only for the refund.
- The owner's save gets +40,000 coins on the next join after publishing. Skins (alter variants) are untouched.

## 2. Supplements GAINS + STAMINA (built)
| | Coach Dex (coins, unchanged) | NEW Pump Shop (Robux) |
|---|---|---|
| EXP | Creatine / Protein Powder +25% 10 min, Supplements +10% 15 min (one at a time) | **GAINS +60% EXP, 30 min**, stacks on top of a Coach Dex boost |
| Stamina | Coconut Water: half now + 50% faster 2 min; Shake: full + 50% EXP 30 s | **STAMINA: full now + refills 60% faster, 30 min** |
| Price | 250-1,200 coins | x1 25 R$, x5 99 R$ (shown from Roblox's real price; tag "SAVE n R$" = 5 x x1 - x5) |
- Both count on every rep, **Auto Rep too**. Using one again adds 30 min (max 60).
- Mass Gainer, Elite Pre-Workout, Whey Isolate, BCAA are **off the shelf**. Owned ones still work exactly as before; their 8 products stay in Config so an old / pending receipt still gives exactly what was bought.
- Config: `Config/Boosts` GainsSupp / StaminaSupp (art: Whey and BCAA tubs for now), `Config/Monetization` `Supp_GainsSupp_1/_5`, `Supp_StaminaSupp_1/_5` (**id = nil: the 4 products don't exist yet, the shop shows SOON**), `Config/PumpShop` (Pump shelf + a "Boosts" shop opened from anywhere).
- **HUD boost slot:** a gold "+" BOOST tile at the end of the bottom-left boost row while neither runs (shop open for you, products exist). Tap = the same shop window (Pump Shop kit) with GAINS + STAMINA.
- **Moments of need ("See boost", max once per 5 min over all, never in the tutorial, never while that one runs or the shop is open):**
  - stamina runs out: the existing "Out of stamina!" card gets a 3rd button SEE BOOST (STAMINA);
  - NEW PERSONAL RECORD (3.5 s after the banner): "New record! Keep it going" card (GAINS).
  - No card after a fail / loss.
- **Analytics per placement:** `Offer_Shown_<p>`, `Offer_Tapped_<p>`, `Offer_Bought_<p>` for p = HudSlot, SuppStamina, SuppPR, PumpShop (+ the existing `Product_Bought_Supp_...`).

## Tests (Studio, temporary save, phone layout)
- GAINS used with Creatine: EXP boost +25% +60% (2.22 -> 3.07). STAMINA: 83 -> 108 / 108 at once, regen x1.6, 30:00 each, a 2nd use -> 59:45.
- Prices / layout checked by borrowing the old Whey / BCAA product ids on the test client only (Roblox prices them 23 / 90 R$, so the tag read SAVE 25 R$). Config ids are back to nil.
- Coach Dex opens with the coin supplements unchanged. No script errors.
- Found + fixed: a "See boost" card could show under the open shop window (the shop isn't in `UIBus.CoverGuis`); now checked.

![[GYM ARC/Screenshots/2026-11-05_supplements/01_hud_boost_slot.jpg]]
![[GYM ARC/Screenshots/2026-11-05_supplements/02_supplements_window_gains.jpg]]
![[GYM ARC/Screenshots/2026-11-05_supplements/04_stamina_out_see_boost.jpg]]
![[GYM ARC/Screenshots/2026-11-05_supplements/05_see_boost_opens_stamina.jpg]]
![[GYM ARC/Screenshots/2026-11-05_supplements/06_pump_shop_counter.jpg]]
![[GYM ARC/Screenshots/2026-11-05_supplements/07_coach_dex_unchanged.jpg]]
(03 = the card-under-window bug, before the fix.)

## Before publishing (open)
- **4 developer products** on the Creator Hub: Gains Supplement 25, Gains Supplement x5 99, Stamina Supplement 25, Stamina Supplement x5 99. Then their ids go into `Config/Monetization`. Without them GAINS / STAMINA show SOON and the "+" slot / See boost cards stay hidden.
- **Private server test can't come before the publish** (a private server runs the published version). Plan: publish, join a private server right away, check Coach Dex (PC + phone), DNA Lab, supplements buy + apply, tint refund on the owner's save; roll back in version history if anything fails (safe: no save version bump).
- The owner's note "tints are back for owners" in the test list clashes with point 1 (removed for good). Built as point 1.
- Not done: 2-player server, real phone.
