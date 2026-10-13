---
date: 2026-10-13
tags: [gymarc, feature]
status: in progress
---
# GYM ARC - Monetization

Back to [[00 GYM ARC Home|GYM ARC Home]].

Today monetization is OFF: the framework is built but no passes or products exist. The owner's new prompt turns it ON (planned, not built).

## How it works now (OFF)
- **Framework built (4 Oct)** with every id empty, so the Store never shows.
- **Passes in the old config:** 2x Gains, Auto Lift, Iron Lungs (+50% stamina), Fast Recovery, Shake Fridge, Gene Lock, VIP Gym.
- **Products in the old config:** DNA Token, Shake Pack (5), Server Boost (2x gains for the whole server for 30 min, buyer named on a board).
- **Rules built in:** the Store button only appears after the tutorial plus 5 minutes of play; no purchase prompt ever opens by itself.
- Ids: [[GYM ARC - Monetization products]].

## Planned change (monetization prompt, task 5)
- **Rule change:** monetization ON. The owner creates passes / products on the Creator Hub; ids go in `Config.Monetization` (0 = not set up, hidden in the shop).
- **Game passes:** 2x EXP, 2x Coins, VIP (chat tag, VIP title, a small VIP lounge in the pro gym with a mirror and smoothie cart, +1 daily quest reroll), Aura Pack (all aura colors), Auto Rep (hold the rep button; still uses stamina, not while AFK), Extra Pet Slot.
- **Developer products:** coin packs (small, medium, large), shake bundles (3 of a shake), instant stamina refill, skip Growth Spurt cooldown (only if a cooldown exists; never past 7'0").
- **Shop UI:** a "Shop" button on the HUD with tabs Passes, Coins, Boosts, Auras; big cards, Robux prices, "OWNED" state.
- **Correct purchases:** save before granting, never grant twice, handle leaving mid-purchase, check passes on join and after buying.
- **Fairness:** no loot boxes, no fake timers or "only 2 left", no pop-ups during training (at most one small skippable offer after a personal record, can be turned off). Free players can still reach every gym, max size, max height and every title.
- Also in that prompt: hide the Wardrobe, hardtekk music, lift screams, aura (see the related notes).

## Where it lives
- `Config/Monetization`, `Server/MonetizationService`, `StoreClient`

## Related
[[GYM ARC - Monetization products]], [[GYM ARC - Aura]], [[GYM ARC - Music and Sounds]], [[GYM ARC - Wardrobe and Gear and Fits Store]], [[GYM ARC - Economy and Daily Rewards]]
