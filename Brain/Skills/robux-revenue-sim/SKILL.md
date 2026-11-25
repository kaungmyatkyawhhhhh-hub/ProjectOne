---
name: robux-revenue-sim
description: "Use to forecast or improve a Roblox game's Robux revenue: a Monte Carlo sim (scripts/revenue_sim.py) of players, retention, would-be payers and each offer (passes, dev products, subscriptions, Premium Payouts) that gives Robux and DevEx USD ranges, a per-offer breakdown and a price sweep for the best price. Calibrated to the game's own Creator Dashboard numbers, with researched benchmarks (references/benchmarks.md). Use it even when the user only says 'how much will this make', 'price this pass', 'best monetization', 'is this offer worth it', or 'robux simulation'."
---

# Robux revenue sim

The sim is a decision tool, not a promise. It is only as right as its inputs, so the method is: **match today's dashboard first, then test changes, then confirm the winner with a real Roblox price test.** Never tell the owner a sim number is guaranteed income.

## Files

| File | Use |
|---|---|
| `scripts/revenue_sim.py` | `--example > model.json` (starter model), `model.json` (30-day forecast: p10/p50/p90 players, DAU, spend, earned Robux, Premium Robux, USD, payer rate, ARPPU, ARPDAU, spend per offer), `model.json --sweep "Offer name"` (best price), `--selftest`. Python 3, no packages. ~10 s for 200 runs. |
| `references/benchmarks.md` | DevEx rates, 70% share, payer-rate and ARPDAU benchmarks, with sources. |

## Method

1. **Read the game's offers from its code/config** (pass ids, product prices, when each is first shown: tutorial gates, "calm until spurt 3", etc.). One `offers` row each: `kind` = `pass` / `product_once` (starter pack) / `product_repeat` (consumables) / `subscription`, `price`, `seen_from_day`, `value` (how much more than a typical purchase it feels worth: starter packs ~2, consumables ~0.5), `impulse` (daily chance a would-be payer looks at it: higher when it is shown in the flow, lower when it is buried in a shop).
2. **Get the real numbers from the owner** (only they can open the Creator Dashboard): new players/day, D1/D7/D30, minutes per DAU, payer conversion, ARPPU, Premium payout last 30 days. If the game is new, use `references/benchmarks.md` and say the forecast is a benchmark guess.
3. **Calibrate:** change `payer_potential` (share who would ever pay) and `wtp_median` / `wtp_sigma` (how much they will pay) until the sim's `payer_rate`, `arppu` and `spend_robux` match the dashboard within ~10%. Set `premium_robux_per_premium_minute` so `premium_robux` matches the real payout.
4. **What-ifs:** change one thing per run (a new offer, a price, showing an offer earlier, better D7) and compare p50 USD against the calibrated base. Report the change as a range (p10-p90), not one number.
5. **Price:** `--sweep` each paid offer. The best price is a starting guess for a Roblox price test (Creator Dashboard, Managed Pricing), never the final price.
6. **Kid check before shipping any offer** (revenue that makes kids quit is a loss the sim can't see): no paid offer in the first minutes, nothing that blocks free progress, the free path stays fun, paid random items show odds, and it follows Roblox's monetization rules. Run `impatient-kid-sim` / `overstimulated-kid-sim` on the flow if it changes the first session.

## Honest limits (say these to the owner when giving numbers)

- No simulation is perfect. This one gets close only after step 3, and the real price test is the final word.
- Willingness to pay is one number per player: buying one offer does not use up budget for another (shortcut: upgrade if offers clearly cannibalize each other, e.g. two starter packs).
- Retention is a power-law fit through D1/D7/D30. Offers do not change retention in the sim. Model a retention hit by hand (lower d7) if an offer feels pushy.
- Each run simulates 1/10 of the players and scales up (`"scale": 1` for exact counts, 10x slower).
- DevEx USD assumes everything is cashed out at the rates in the model.

## Lessons

(Add a dated line whenever the owner corrects a result.)
