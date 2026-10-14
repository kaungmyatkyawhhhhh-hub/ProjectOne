---
date: 2026-10-13
tags: [gymarc, feature, monetization]
status: in progress
aliases: ["GYM ARC - Monetization products"]
---
# GYM ARC - Monetization

Back to [[00 GYM ARC Home|GYM ARC Home]].

Today monetization is OFF: the framework is built but no passes or products exist. The owner's new prompt turns it ON (planned, not built).

## How it works now (OFF)
- **Framework built (4 Oct)** with every id empty, so the Store never shows.
- **Passes in the old config:** 2x Gains, Auto Lift, Iron Lungs (+50% stamina), Fast Recovery, Shake Fridge, Gene Lock, VIP Gym.
- **Products in the old config:** DNA Token, Shake Pack (5), Server Boost (2x gains for the whole server for 30 min, buyer named on a board).
- **Rules built in:** the Store button only appears after the tutorial plus 5 minutes of play; no purchase prompt ever opens by itself.
- Ids, prices and badges: see "Passes, products and badges" below.

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
[[GYM ARC - Aura]], [[GYM ARC - Music and Sounds]], [[GYM ARC - Wardrobe and Gear and Fits Store]], [[GYM ARC - Economy and Daily Rewards]]

## Passes, products and badges

**Monetization is OFF right now.** Every pass and product is already coded, but none has an id, so the Store button
never shows and no purchase prompt can open. Nothing has been created on the Creator Hub yet.

How to turn one on: create it on the Creator Hub (your experience > Monetization), then paste its id into
`ReplicatedStorage > Shared > Config > Monetization` (repo copy:
`C:\Users\kaung\ClaudeOne\src\ReplicatedStorage\Shared\Config\Monetization.luau`). Items without an id stay hidden. The
Store only appears after the tutorial plus 5 minutes of play, and never pops up by itself.

### Game passes (one-time)

| Name | Type | Description | Price (Robux) | ID | Status |
|---|---|---|---|---|---|
| 2x Gains | Game pass | Every rep gives double gains | Not set | none | OFF (no id yet) |
| Auto Lift | Game pass | Lifts for you while you're on a machine (toggle any time) | Not set | none | OFF (no id yet) |
| Iron Lungs | Game pass | 50% more stamina | Not set | none | OFF (no id yet) |
| Fast Recovery | Game pass | Stamina refills 50% faster | Not set | none | OFF (no id yet) |
| Shake Fridge | Game pass | A free Energy Shake every 10 minutes you play | Not set | none | OFF (no id yet) |
| Gene Lock | Game pass | Rerolling keeps your best muscle group's grade | Not set | none | OFF (no id yet) |
| VIP Gym | Game pass | +10% coins and a VIP tag on your player card | Not set | none | OFF (no id yet) |

### Developer products (can be bought again)

| Name | Type | Description | Price (Robux) | ID | Status |
|---|---|---|---|---|---|
| DNA Token | Developer product | One genetics reroll (1 token) | 99 | 3718499538 | ON (owner, 14 Oct) |
| Shake Pack | Developer product | 5 Energy Shakes | Not set | none | OFF (no id yet) |
| Server Boost | Developer product | 2x gains for everyone in the server for 30 minutes; buyer's name on the board | Not set | none | OFF (no id yet) |

Prices are set on the Creator Hub when you create each item; the game reads the price from Roblox, so there is no price
in Config. Everything paid can also be earned for free (DNA tokens: +1 every Growth Spurt or 25,000 coins; shakes for 25 coins).

### Badges (linked to titles)

Titles are never sold. A few big titles can also give a Roblox badge. Badges are free (not monetization) but also need
an id from the Creator Hub, pasted into `Config/Titles.luau` (`badgeId`). See [[GYM ARC - Titles]].

| Title | Rarity | How to get it | Badge ID | Status |
|---|---|---|---|---|
| Aesthetics God | Legendary | Every muscle at the level 45 EXP mark or higher | none | No badge yet (badgeId = nil) |
| Skyscraper | Legendary | Grow to 7'0" | none | No badge yet (badgeId = nil) |
| Defied Genetics | Legendary | Take a D-grade muscle group to 130% of the Growth Spurt goal | none | No badge yet (badgeId = nil) |

### Planned (not built yet)

From [[2026-10-13 GYM ARC Prompt - Monetization and hype]]. This prompt turns monetization ON and replaces the list
above. The ids would go in `Config.Monetization` (0 = not set up, hidden in the shop). Prices are still to be suggested
when the work is done.

| Name | Type | Description | Price (Robux) | ID | Status |
|---|---|---|---|---|---|
| 2x EXP | Game pass | Double training EXP forever | To decide | 0 | Planned |
| 2x Coins | Game pass | Double coins forever | To decide | 0 | Planned |
| VIP | Game pass | VIP chat tag, VIP title, small VIP lounge in the pro gym (mirror + smoothie cart), +1 daily quest reroll | To decide | 0 | Planned |
| Aura Pack | Game pass | Unlocks all lift aura colors | To decide | 0 | Planned |
| Auto Rep | Game pass | Holding the rep button keeps repping at normal speed (on a machine, not AFK, still uses stamina) | To decide | 0 | Planned |
| Extra Trainer | Game pass | A second personal trainer follows you, perks stack ([[GYM ARC - Personal Trainers]]); in `Config/Monetization` with no id, so off | To decide | 0 | In config, off |
| Coin pack (small) | Developer product | Coins | To decide | 0 | Planned |
| Coin pack (medium) | Developer product | Coins | To decide | 0 | Planned |
| Coin pack (large) | Developer product | Coins | To decide | 0 | Planned |
| Shake bundle | Developer product | 3 of a smoothie bar shake | To decide | 0 | Planned |
| Instant stamina refill | Developer product | Fills stamina now | To decide | 0 | Planned |
| Skip Growth Spurt cooldown | Developer product | Only if a cooldown exists; never past 7'0" | To decide | 0 | Planned |

Planned shop: a Shop button with tabs Passes, Coins, Boosts, Auras; big cards, Robux price, "OWNED" on owned items.
Fairness rules stay: no loot boxes or random paid rewards, no fake timers, no pop-ups during training (at most one small
skippable offer after a personal record, can be turned off), and free players can still reach every gym, max size, max
height and every title. Purchases saved before they are granted, never granted twice.

Note: the other planned prompt ([[2026-10-13 GYM ARC Prompt - New features run]]) says monetization stays OFF; the
monetization prompt is the one that turns it on.

## DNA Token (14 Oct)
- Developer product **DNA Token**, 99 Robux, id **3718499538** (`Config/Products.DNAToken`). Gives 1 token, granted in ProcessReceipt only after the save is stored, once per PurchaseId (a retried or repeated receipt never grants twice). Tested with a Studio test receipt, also after rejoining.
- Sold in the Shop (Items, next to the 25,000 coin button) and on the Genetics screen when you press REROLL with no token.
