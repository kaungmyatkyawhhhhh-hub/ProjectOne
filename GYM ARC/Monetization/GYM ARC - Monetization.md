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
- **Rules built in:** the Store button only appears after the tutorial plus the player's first 5 minutes in the game (counted from their first join, not every session; changed 15 Oct, see [[GYM ARC - Bug - Store took 10 minutes to load]]); no purchase prompt ever opens by itself.
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
| Quest Reroll | Developer product | Swap one daily quest for a new one (after the free one each day) | 19 | 3718500732 | ON (owner, 14 Oct) |
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

### BETA TESTER badge (20 Oct)
| Badge | How to get it | Badge ID | Status |
|---|---|---|---|
| BETA TESTER | Join the game while the beta is on | 471600537426484 | ON (checked: the badge exists and is enabled) |

Every player who joins gets it once, and sees a gold toast "BETA TESTER badge earned!" the first time (after the main menu). The id and the switch are in `Config/Titles.luau`: set `BETA_BADGE_ENABLED = false` when the beta ends. Server: `BetaBadgeService` (checks the badge, then awards it; each call is in pcall and retried once after 5 s; joining never waits; never in Studio). Prompt: [[2026-10-20 GYM ARC Prompt - 16 Beta tester badge]].

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

## Quest Reroll (14 Oct)
- Developer product **Quest Reroll**, 19 Robux, id **3718500732** (`Config/Products.QuestReroll`). Bought only from the Quests window after picking a quest (not shown in the Store). The reroll happens in ProcessReceipt, once per PurchaseId, after the save is stored. See [[GYM ARC - Quests and Muscle of the Day]].

## Everything on sale (14 Oct, the owner's ids)
| Name | Type | What it does | Price (Robux) | ID | Store tab | Status |
|---|---|---|---|---|---|---|
| 2x EXP | Game pass | Double all training EXP | 249 | 2032508303 | Passes | ON |
| 2x Coins | Game pass | Double all coins earned | 149 | 2032286316 | Passes | ON |
| VIP | Game pass | +10% coins, VIP tag, the Royal aura (aura system coming) | 299 | 2032988308 | Passes | ON |
| Aura Pack | Game pass | Unlocks 5 auras (aura system coming next) | 199 | 2033954299 | Passes | ON |
| Auto Rep | Game pass | Lifts for you on a machine | 249 | 2033558291 | Passes | ON |
| Extra Trainer | Game pass | +1 trainer slot (prompt 24: up to 4 with the free slots) | 99 | 2032496303 | Passes | ON |
| Small Coins | Developer product | +1,000 coins | 25 | 3718306241 | Coins | ON |
| Medium Coins | Developer product | +5,000 coins | 99 | 3718306326 | Coins | ON |
| Large Coins | Developer product | +15,000 coins | 249 | 3718306360 | Coins | ON |
| Shake Bundle | Developer product | 3 Energy Shakes | 49 | 3718306390 | Boosts | ON |
| Endless Stamina (was Stamina Refill) | Developer product | 15 min of no stamina drain, stacks to 60 min | 49 | 3718306417 | Boosts | ON |
| DNA Token | Developer product | 1 DNA token | 99 | 3718499538 | Boosts | ON |
| Quest Reroll | Developer product | Reroll one daily quest | 19 | 3718500732 | (Quests window only) | ON |

Notes:
- The VIP pass's Roblox description mentions a VIP chat tag, a VIP title and a VIP Lounge in the pro gym; the game gives +10% coins and a VIP tag (no lounge yet).
- The Shake Bundle's Roblox description says "+20% EXP for 5 minutes each"; the game's Energy Shake refills stamina and gives +50% gains for 30 s.
- Prices shown in the Store come from Roblox; the numbers above are only the fallback if Roblox can't be reached. (22 Oct: the game's fallback for Endless Stamina said 15; fixed to 49.)

## Offers at the right moment (22 Oct, prompt 12; [[2026-10-22 GYM ARC Developer product sales]])
- `OfferClient`: one small card above the stamina bar with an X, gone after 12 s, never over a window / the menu / in the tutorial, no timers. Stamina runs out -> Endless Stamina (max once per 10 min, not while it runs); last shake drunk -> Shake Bundle (+ the coin price at the shake machine; once per session); after a Growth Spurt -> the 3 coin packs (once per spurt). Buy = Roblox's prompt (2 taps).
- Growth Spurt card / machine strip at 75%+: "Finish faster: Shake Bundle >" opens the Store on it (`UIBus.OpenShop(tab, itemKey)`).
- Card prices = the Store's Roblox prices (`Shared/ShopPrices`).
- Analytics custom events: `Shop_Opened`, `Offer_Shown_<offer>`, `Offer_Tapped_<offer>`, `Product_Bought_<key>` (value = Robux). Offers: Stamina, ShakeOut, AfterSpurt, FinishFaster.

## Removed (14 Oct)
- **Skip Growth Cooldown** (developer product 3718306447): removed from the game on the owner's request (it was never on sale: there is no wait between Growth Spurts). The product still exists on the Creator Hub; turn it off there if wanted.

## Endless Stamina (14 Oct)
Same product as the old Stamina Refill (3718306417), renamed by the owner in the Creator Hub.
- One purchase = 15 minutes where stamina never goes down (lifting, treadmills, Auto Rep keeps going without resting).
- Buying again adds 15 more minutes, up to 60. When another 15 wouldn't fit, the Store button says "Full: 60 min".
- The timer only runs while the player is in the game; leaving saves the time left.
- Given only inside ProcessReceipt, together with saving the purchase id, so a repeated purchase id never gives it twice.
- Shown as a gold lightning chip with a countdown ("14:32") above the stamina bar; the bar turns gold with a slow shine and an infinity sign.

![[GYM ARC/Screenshots/endless_stamina_store.jpg]]
![[GYM ARC/Screenshots/endless_stamina_store_full.jpg]]

## Store look (23 Oct, prompt 61; [[2026-10-23 GYM ARC Store passes premium restyle]])
Premium tiles in each item's colour, Robux prices on slim graphite buttons, owned = gold OWNED at full brightness (no checkmarks). The hero card on PASSES features the first pass you don't own in `Monetization.PopularPasses` (or THANK YOU when you own them all). Coach Dex / Go to Pump Shop sit at the bottom of the Store.

## New products (23 Oct, prompts 57 / 60; create them and paste the IDs in Config/Monetization)
Until an ID is set the item is hidden (the PUMP SHOP specials show SOON). Details and descriptions: [[2026-10-23 GYM ARC Gear, shop items, monetization and economy]].
- DnaTokenPack: DNA Token x3, 249 R$.
- StarterPack: Starter Pack, 49 R$, once per player.
- Supp_MassGainer_1 / _5, Supp_ElitePreWorkout_1 / _5, Supp_WheyIsolate_1 / _5, Supp_BcaaRecovery_1 / _5: 25 R$ (x1) / 99 R$ (x5).
- Coin packs (existing IDs) now scale with the player's stage: Small 20 min / Medium 120 min / Large 360 min of coins, never less than 1,000 / 5,000 / 15,000. New descriptions in the progress note.
- Coach Dex sells the existing Shake Bundle and DNA Token products too (same IDs and prices).
