---
date: 2026-10-28
tags: [speedarc, feature]
status: done (M5) - waiting for pass / product IDs
---
# SPEED ARC - Store and Monetization

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

## Fair rules (never break)
- Robux never wins a race by itself (passes help training and coins, never race pace).
- No paid luck on coach rolls (rolls are coins only; Faster Rolls has the same odds).
- No fake timers. The Starter Pack's 24 h window is real and isn't shown as a countdown.
- Offers only at calm moments (after a race's results, never in one, never in the tutorial), at most one small card per 10 min.
- The price in the game = Roblox's real price (read from Roblox when the ID is set).

## Passes (Config/Store.Passes)
| Pass | R$ | What |
|---|---|---|
| Auto Train (hero) | 249 | AUTO button on the training panel: 3 taps a second, steady x1.2 combo, any station. "STILL TRAINING?" every 15 min; no answer in 60 s = off |
| 2x Speed | 249 | training x2 |
| 2x Coins | 149 | coins x2 (all coin boosts together stop at x8) |
| VIP | 299 | +10% coins, VIP before your name, VIP kit, VIP Gold trail, VIP name style, [VIP] in chat |
| Extra Coach Slot | 99 | 3 coach slots |
| Extra Coach Slot 2 | 149 | 4 coach slots (needs the first) |
| Trail Pack | 199 | Lightning, Rainbow, Comet, Neon Wave |
| Faster Rolls | 99 | no roll animation + ROLL x3 |

## Products (Config/Store.Products)
| Product | R$ | What |
|---|---|---|
| Small / Medium / Large coins | 25 / 99 / 249 | 20 min / 2 h / 6 h of coins at your league |
| 2x Speed 15 min | 25 | x2 training for 15 min of play, stacks with the New Runner / gift boost |
| Starter Pack | 49 | once, first 24 h only: 1 h of coins, 2x Speed 30 min, gold Canvas Runners, STARTER title |

## Where things show
- STORE button (left menu) and the "+" on the coins pill (opens COINS).
- Offer card (bottom centre, X to close): Starter Pack after a race win; Auto Train after 10 min of tapping (once a session).
- An AUTO button on the training panel (opens the store if you don't own it).

## Receipts
One `ProcessReceipt` on the server. The receipt id is saved with the grant and the save is written **before** Roblox is told PurchaseGranted. A repeated receipt (Roblox retry, rejoin) is never granted twice. If the save fails, Roblox is told "not yet" and retries later.

## Setup still needed
Create the passes and products in Creator Hub with the exact prices, then put their IDs in `Config/Store.lua` (`Id = 0` now = card says SOON). The list with icon ideas is in [[2026-10-28 SPEED ARC Progress - 5 Store, passes, Starter Pack, Locker cosmetics|Progress 5]].

## Studio test switches
`TestGrantPass` = "AutoTrain" ..., `TestBuyProduct` = "CoinsSmall" or "CoinsSmall:receiptId", `TestOffer` = "StarterPack", `TestOpenWindow` = "Store" / "Store:COINS".

## Analytics
OfferShown_X, OfferTapped_X, OfferBought_X custom events.

## Where it lives
`Server/Services/StoreService`, `Server/Services/TrainingService` (Auto Train), `Client/Controllers/StoreController`, `Client/Controllers/CoachController` (Faster Rolls), `Shared/Util/Boosts` (pass multipliers), `Config/Store`.
