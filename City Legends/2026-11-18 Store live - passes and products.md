---
tags: [city-legends, monetization, store]
created: 2026-11-18
---
# City Legends: the Robux store is live in code (18-19 Nov 2026)

Phase 1 of [[2026-11-18 Monetization and economy - plan]]. The owner made the passes and products in Creator Hub on 18 Nov (Managed Pricing off).

| Kind | Name | Id | Price | What it does now |
|---|---|---|---|---|
| Pass | 2x Cash | 2094087139 | 499 R$ | x2 cash from driving, cut-ups and jobs |
| Pass | VIP | 2094033148 | 399 R$ | gold VIP tag over the head and in chat, free VIP bays at the tower garages, +10% cut-up cash |
| Pass | Double Pay | 2094591074 | 499 R$ | x2 job pay (delivery job now; the new jobs system reads the same attribute) |
| Product | Starter Pack | 3733093451 | 49 R$ | $50,000 + one of the 3 starter cars you don't own yet (the first-car picker opens). Once per player |
| Product | Garage Space | 3733093637 | 49 R$ | +1 garage space at the house you have placed (only offered while it has room) |
| Product | Spin | 3733093797 | 25 R$ | +1 SPIN at Legends Rewards (the odds open before the Robux buy) |

- **Cash packs removed** (plan: no cash for Robux). SUPER SPIN stays free / cash only (`productId = 0`).
- **Premium:** +10% cash (driving, cut-ups, jobs).
- **No paid power in competitions:** race and duel prizes are never multiplied. XP is never multiplied either.
- Stacking: 2x Cash x Double Pay = x4 on jobs; 2x Cash x VIP x Premium on a cut-up = x2.42.

## How it works (code)
- `src/shared/Config.lua`: `Config.Menu.Store` (the 5 tiles), `Config.Passes` (Cash2x, Vip, DoublePay), `Config.Products` (StarterPack, GarageSpace, Spin), `StarterPackCash`, `VipCutBonus`, `PremiumBonus`.
- `src/server/Store.lua` (new):
  - The game's **only** `ProcessReceipt`. Idempotent: each PurchaseId is saved in `profile.Rewards.Receipts` (last 50). The grant is saved before it is confirmed; a failed save undoes it and Roblox retries. `NotProcessedYet` while the save is not loaded or the product is unknown.
  - Starter Pack bought twice (past the client block): pays its $50k only. All 3 starter cars owned: the car's price in cash instead. Garage Space with no room (house removed between prompt and receipt): the first space's cash price ($50k) instead.
  - Passes: `UserOwnsGamePassAsync` at join (pcall), `PromptGamePassPurchaseFinished` mid-session. Cached as player attributes `Cash2x`, `Vip`, `DoublePay`, `Premium`; also `StarterPack`, `StarterPick`.
  - `Store.earnMult(player, kind)` ("drive", "cut", "job"), used by `Main.server` (cut-ups, driving income) and `Activities` (delivery job) and `Jobs.lua`.
  - Studio only: `ServerStorage.StoreTestReceipt` (BindableFunction) sends a receipt by hand (for repeat tests).
- `Rewards.lua`: its old spin receipt handler is gone; `Rewards.data` / `Rewards.send` are exposed; save fields `StarterPack`, `StarterPick`.
- `Houses.lua`: `bayRoom`, `rebuild`, player attribute `BayRoom`. `Parking.lua`: VIP pass parks free.
- `Main.server` `ClaimStarter`: also takes the Starter Pack's pick (a car not owned).
- Client: `MainMenu` STORE tiles (price from `GetProductInfo`, OWNED / PICK YOUR CAR / NEED A HOUSE states, live on attribute changes); the first-car picker doubles as the pack's picker; `RewardsClient` Robux spin button shows its R$ price and opens the odds on the first tap; `Main.client` VIP chat prefix.

## Tests
- Lune `tools/store_test.luau` (receipt idempotency, rollback, not-loaded wait, Starter Pack once, multipliers). Lune and luau-lsp are not installed on this PC: run it on the other PC (`lune run tools/store_test.luau .`).
- All changed files compile (Studio `loadstring` check on commit 6eca8857).
- Studio: see the results section below.

## Results
(filled in below)
