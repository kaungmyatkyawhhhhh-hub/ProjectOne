---
tags: [city-legends, monetization, economy, plan]
created: 2026-11-18
---
# City Legends: monetization and economy plan (18 Nov 2026)

> Owner (18 Nov): "lets plan for monetization and economy and stuff first". This work runs on the laptop while the PC finishes the map rebuild.

Builds on [[2026-11-17 Car economy and Skyfreight crate design]] and [[K04 Monetization and economy]].

## What already exists (code)
- **STORE tab** (`MainMenu`): 6 items from `Config.Menu.Store`: VIP, 2x Cash, Starter Pack, Cash $25k, Cash $100k, Garage Space. **None has an id, so nothing sells yet.** Prices are read from Roblox.
- **SPIN / SUPER SPIN** (`Rewards`) with Robux spins. `productId = 0`, so they are hidden. `ProcessReceipt` is wired.
- **Economy numbers** in `Config.Economy`: cut-ups, jobs, heist, gifts, daily tasks, playtime gifts, level-ups, part prices.
- **Not built:** the crate/import system (Basic / Premium / Skyfreight, the import queue, Rush Import, airport claim), Double Pay, the car rarity/source fields.

## Blocker to settle first: car licences
Many car models are **CC-BY-NC (non-commercial)** and most likely ripped from racing games (list in [[City Legends]]). Selling Robux while using them is a licence risk, and selling **those cars in Robux crates** is the worst case.
- **Rule for the plan:** Robux crates and paid offers contain only cars whose licence allows it (our own or CC-BY), until the NC cars are replaced.
- **Owner decision (18 Nov): "the cars in the game are already good"**: keep the current cars, in crates too. The licence risk is accepted. If a takedown claim ever comes, swap that one model (the game works with any model).

## Phase 1: sell what is already built (laptop, about 1 day)
1. **Make the passes and products on Roblox** (owner: Creator Hub, about 15 min) and put the ids in `Config.Menu.Store` + spin `productId`.
2. **Starting prices** (K04: auto/2x is the hero; small impulse items):
   | Item | Type | Price | Note |
   |---|---|---|---|
   | 2x Cash | Pass | 299 R$ | hero |
   | VIP | Pass | 199 R$ | tag, VIP bays, +10% cut-ups |
   | Double Pay (jobs) | Pass | 199 R$ | from the 17 Nov design; or merge into 2x Cash |
   | Starter Pack | Product, once | 49 R$ | $50k + a choice of a safe-licence car; offered after the first race or job, never in the tutorial |
   | Garage Space | Product | 49 R$ | |
   | Spin | Product | 25 R$ | odds shown on the button |
3. **Cash packs:** the 17 Nov design said "no cash for Robux" (keeps the crate odds rules simple). **Recommendation: drop the 2 cash packs**, and sell time savers and the Starter Pack instead.
4. **Premium:** +10% cash for Premium players.
5. **Measuring:** Seen, Prompted and Bought events per item (K04). Judge by revenue per 1,000 players after 7 days.

## Phase 2: the car economy from the 17 Nov design (laptop, about 3 to 5 days)
- Car `rarity` + `source` (Local / Import-only) on every car.
- Dealership with 3 tabs: Buy (shelf), Import Crates, Exclusive.
- Crates: Basic (cash), Premium (cash or 199 R$), Skyfreight (399 R$).
  - Odds are shown before buying, and every pull gives a car.
  - Pity counter.
  - Duplicates refund 50%.
  - PolicyService restriction hides the crate where needed.
  - The server rolls; the client only animates.
- Import queue (max 3, real timers that keep running offline), airport claim, Rush Import (19 to 249 R$).
- Collection book with silhouettes.
- **Sinks:** garage slots, paint and wheels, fines, repairs.
- **Income targets:** a Basic crate in 10 to 15 min; a Premium crate in about 1 h for free players.

## Phase 3: retention and timed sales
- Daily login 2k → 20k (the streak exists; check its numbers against the targets).
- Right-moment offers (small card, at most once per X minutes).
- GGFest: limited GG wrap / plate (already built, free during the event). Use the event for the launch, but no paid power in races or duels.

## Rules (owner)
- Paid random items only with the odds shown (K04).
- No fake timers, no "was" prices.
- No paid power in competitions.
- Never weaken what players own.
- No real brand names.

## Before building
- Run the kid simulations on the plan (kid-focus-group / impatient-kid-sim skills), per the Brain.
- Tune the starting numbers in playtests.
