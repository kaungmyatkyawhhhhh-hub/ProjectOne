---
date: 2026-10-22
tags: [gymarc, progress, monetization]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-22 GYM ARC Developer product sales

Prompt: [[2026-10-20 GYM ARC Prompt - 12 Developer product sales]] (+ the owner's skip button request: [[2026-10-22 GYM ARC Prompt - Skip button after 5 seconds]]). Feature: [[GYM ARC - Monetization]].

## 1) Does buying work?
- **ProcessReceipt** is set once, on the server (`MonetizationService`; no other script in the place sets it). It handles every product id: Small 3718306241, Medium 3718306326, Large 3718306360, Shake Bundle 3718306390, Endless Stamina 3718306417 (+ DNA Token, Quest Reroll). It answers PurchaseGranted only after the item is given AND the save is stored; a repeated purchase id never gives twice.
- **Tested** (Studio test receipts through the real ProcessReceipt, temporary save): all 5 give the right thing (coins 1,000 + 5,000 + 15,000 = 21,000; 3 shakes; 15 min Endless Stamina); the same purchase id again gave nothing. (On the temporary save the answer is "not yet" because that save never stores; on a real save it is "granted", as tested for the DNA Token on 14 Oct.)
- **Shop open time:** 0.15 s from the tap (844x390). The ~10 minute wait was already fixed (prompt 11 / 15 Oct: prices and pictures load in the background, the Store shows cached prices and never waits).
- **Where products are:** Store > BOOSTS (Shake Bundle, Endless Stamina, DNA Token) and Store > COINS (Small / Medium / Large; the coins "+" opens this tab). The Store opens on AURAS (prompt 20), so a product took 3-4 taps and was never offered at the moment it helps. The new cards and link below are 2 taps (Buy + Roblox's confirm).

## What was wrong
- **Nobody was shown a product when they needed it:** products sat on the 2nd / 3rd Store tab only. (Most likely the main reason for 0 sales.)
- **Wrong fallback price:** the game's own price for Endless Stamina was R$ 15 while Roblox sells it for R$ 49. Whenever Roblox's info was slow, the Store said R$ 15 and then Roblox's prompt asked 49 (looks like a trick to a kid; most cancel). Fixed (49). All other prices match Roblox.

## 2) Offers at the right moment (one small card, never a full-screen popup)
- One card at a time at the bottom center, just above the stamina bar (clear of STOP / REP and the side menu). Gold border, the product's picture, honest text, a red price button and an X. It goes away by itself after 12 s, never shows over a window, the menu or in the tutorial, no timers, no "last chance". Buy opens Roblox's purchase prompt.
- **Stamina runs out** (not in the tutorial, not while Endless Stamina runs): "Endless Stamina · 15 min" (R$ 49). At most once per 10 minutes.
- **Last shake drunk:** "Shake Bundle · 3 shakes: Full stamina + 50% gains each. Or 25 coins at the shake machine." (R$ 49). Once per session.
- **After a Growth Spurt** (after its celebration): "Boost your next spurt: Coins buy Energy Shakes and boosts that help you train." with 1K R$ 25 / 5K R$ 99 / 15K R$ 249. Once per spurt.
- **Growth Spurt bar at 75%+:** a small gold "Finish faster: Shake Bundle >" line under the Growth Spurt card (and under the machine strip); it opens the Store on BOOSTS with the Shake Bundle picked.
- Prices on the cards are the Store's prices from Roblox (`Shared/ShopPrices`).

## 3) Analytics (Roblox custom events)
- `Shop_Opened`, `Offer_Shown_<Stamina | ShakeOut | AfterSpurt | FinishFaster>`, `Offer_Tapped_<same>`, `Product_Bought_<key>` (value = Robux spent, logged after the receipt is saved). The client's events are checked on the server (only these names, at most one of each per 3 s per player).
- Next report: compare Offer_Shown -> Offer_Tapped -> Product_Bought per offer to see where buyers drop off.

## Owner's request: SKIP TUTORIAL after 5 s
- The SKIP TUTORIAL button now shows only after 5 s of play (counted from when the menu is gone and the genetics screen has closed). Tested: not there 2.5 s after Keep, there at 7 s.

## Tested in Studio
- 844x390: stamina card, shake card (R$ 49 from Roblox), after-spurt card (X closes it), Finish faster link -> Store on the Shake Bundle; 667x375: the after-spurt card fits. Server logged Shop_Opened and Offer_Shown_Stamina / ShakeOut / AfterSpurt.
- Not tested: tapping a card's Buy into a real Roblox purchase (opens Roblox's dialog), a real phone.

![[GYM ARC/Screenshots/offers/offer_shake_bundle_844.jpg]]
![[GYM ARC/Screenshots/offers/offer_after_spurt_844.jpg]]
![[GYM ARC/Screenshots/offers/offer_after_spurt_667.jpg]]
![[GYM ARC/Screenshots/offers/finish_faster_link.jpg]]
![[GYM ARC/Screenshots/offers/finish_faster_store.jpg]]
![[GYM ARC/Screenshots/offers/tutorial_no_skip_first_5s.jpg]]
![[GYM ARC/Screenshots/offers/tutorial_skip_after_5s.jpg]]

## Needs the owner
- The Shake Bundle's Roblox description says "+20% EXP for 5 minutes each"; the game's shake gives full stamina and +50% gains for 30 s. Please update the description on the Creator Hub so it matches.
