---
date: 2026-10-13
tags: [gymarc, monetization]
status: current
---
# GYM ARC - Monetization products

Back to [[00 GYM ARC Home|GYM ARC Home]]

**Monetization is OFF right now.** Every pass and product is already coded, but none has an id, so the Store button
never shows and no purchase prompt can open. Nothing has been created on the Creator Hub yet.

How to turn one on: create it on the Creator Hub (your experience > Monetization), then paste its id into
`ReplicatedStorage > Shared > Config > Monetization` (repo copy:
`C:\Users\kaung\ClaudeOne\src\ReplicatedStorage\Shared\Config\Monetization.luau`). Items without an id stay hidden. The
Store only appears after the tutorial plus 5 minutes of play, and never pops up by itself.

## Game passes (one-time)

| Name | Type | Description | Price (Robux) | ID | Status |
|---|---|---|---|---|---|
| 2x Gains | Game pass | Every rep gives double gains | Not set | none | OFF (no id yet) |
| Auto Lift | Game pass | Lifts for you while you're on a machine (toggle any time) | Not set | none | OFF (no id yet) |
| Iron Lungs | Game pass | 50% more stamina | Not set | none | OFF (no id yet) |
| Fast Recovery | Game pass | Stamina refills 50% faster | Not set | none | OFF (no id yet) |
| Shake Fridge | Game pass | A free Energy Shake every 10 minutes you play | Not set | none | OFF (no id yet) |
| Gene Lock | Game pass | Rerolling keeps your best muscle group's grade | Not set | none | OFF (no id yet) |
| VIP Gym | Game pass | +10% coins and a VIP tag on your player card | Not set | none | OFF (no id yet) |

## Developer products (can be bought again)

| Name | Type | Description | Price (Robux) | ID | Status |
|---|---|---|---|---|---|
| DNA Token | Developer product | One genetics reroll | Not set | none | OFF (no id yet) |
| Shake Pack | Developer product | 5 Energy Shakes | Not set | none | OFF (no id yet) |
| Server Boost | Developer product | 2x gains for everyone in the server for 30 minutes; buyer's name on the board | Not set | none | OFF (no id yet) |

Prices are set on the Creator Hub when you create each item; the game reads the price from Roblox, so there is no price
in Config. Everything paid can also be earned for free (DNA tokens from Growth Spurts, streaks and 400 coins at the
front desk; shakes for 25 coins).

## Badges (linked to titles)

Titles are never sold. A few big titles can also give a Roblox badge. Badges are free (not monetization) but also need
an id from the Creator Hub, pasted into `Config/Titles.luau` (`badgeId`). See [[GYM ARC - Titles]].

| Title | Rarity | How to get it | Badge ID | Status |
|---|---|---|---|---|
| Aesthetics God | Legendary | Every muscle at the level 45 EXP mark or higher | none | No badge yet (badgeId = nil) |
| Skyscraper | Legendary | Grow to 7'0" | none | No badge yet (badgeId = nil) |
| Defied Genetics | Legendary | Take a D-grade muscle group to 130% of the Growth Spurt goal | none | No badge yet (badgeId = nil) |

## Planned (not built yet)

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
| Extra Pet Slot | Game pass | Two pets follow you at once | To decide | 0 | Planned |
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
