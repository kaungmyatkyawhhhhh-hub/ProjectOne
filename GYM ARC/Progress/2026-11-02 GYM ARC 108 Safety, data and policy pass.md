---
date: 2026-11-02
tags: [gymarc, progress, safety, data, policy]
status: built and tested in Studio, not published (goes live with the next publish)
---
# GYM ARC - 108 Safety, data and policy pass (2 Nov, Claude Code)

Prompt: [[2026-10-29 GYM ARC Prompt - 108 Safety, data and policy pass]]. Rules written in [[GYM ARC - Player Data and Saving]] and the Home note.

## 1) Paid random items
- **Odds:** trainer rolls show every trainer's % on the roll grid (always on) and on the reveal card; the DNA reroll has its "View odds" panel.
  - **Fixed:** the Trainer Agency's grid added up to 99.95% for players without Atlas. Celestial only opens once you own Atlas, and the server divides by what's open. The grid now shows each player's real chance (e.g. Common 35.97%) and always adds up to 100%.
  - The gym agencies were already at 100%, and so are the genetics odds (grades, frame, body type).
- **Aura spins: none exist.** Every aura is earned, in a pass, or a fixed coin buy.
- **No "Luck" product exists**, so there was nothing to remove.
- **PolicyService (new):** on join the server asks Roblox for `ArePaidRandomItemsRestricted`; if the call fails, the player counts as restricted.
  - Restricted players never see, get offered or can buy: the 3 coin packs, DNA Token, DNA Token x3, the Starter Pack and the Premium Pack (`Config/Monetization.PaidRandom`). Their coins and DNA are earn-only.
  - **Code touched: 7 scripts, 9 places:**
    - Config/Monetization: the rule, plus ForSale, StarterOpen and PremiumOpen.
    - MonetizationService: the policy check, plus a log if one is bought anyway.
    - StoreClient: waits for the answer.
    - CoinOffer: the "out of coins?" bar.
    - GeneticsClient: the Robux buttons.
    - PumpShopClient: the DNA tiles.
    - OfferClient and the Starter / Premium Pack card: follow through ForSale / StarterOpen / PremiumOpen.
  - Tested with the Studio switch `TestPaidRandomRestricted`:
    - Restricted: the Store has no COINS tab, no DNA and no Starter Pack (`Screenshots/108/store_restricted.jpg`).
    - Not restricted: all back (`store_not_restricted.jpg`).
    - No errors.
- **Owner decisions left:**
  - The VIP pass includes a free trainer roll a day. It stays on sale to restricted players, since the roll is a perk and isn't sold alone. Say if it should be hidden too.
  - The Quest Reroll product (19 R$) swaps a quest for a random one. It's not an item, so it's left as is.

## 2) Save version
- `data.dataVersion` plus `Server/DataMigrations` (Latest = 1, a step 0 -> 1, and an id-rename table). It runs once on load.
- A server with older code never writes a newer save: the player is asked to rejoin ("GYM ARC just updated!..."). Unknown fields are kept.
- **Bug found and fixed:** equipping or buying an alter skin or a variant rebuilt the saved alter table and dropped `alter.goalsV`.
  - On the next join, a 7'0" player's EXP was rescaled from the oldest alter goals again. With today's smaller goals that scales it down.
  - The alter table is now changed field by field (`alterWith`).
  - Saves that already lost EXP this way can't be repaired automatically.
- Tested:
  - A test save marked version 0 printed "save version 0 -> 1".
  - An id rename moves the item.
  - A newer save is refused.

## 3) Right to Erasure
- Command: `game.ServerStorage.Admin:Invoke("erase", userId)` (EraseService). It removes:
  - the save, replaced by `{ erasedAt }` (no personal data); any server still holding them stops saving;
  - every board entry, including 60 days of the daily board;
  - the Hall of Fame board entry (so the statue goes);
  - Powerlifting records, crew membership and the daily notification.
- All servers drop the player.
- Tested on a fake user: the board entry is gone, the save is `{"erasedAt":...}`, and 75 board entries were cleared.
- **Webhook (owner, about 5 min):**
  1. Creator Hub > Account > Webhooks (create.roblox.com/settings/webhooks) > Create Webhook.
  2. Trigger: "Right To Erasure Request".
  3. Webhook URL: a Discord channel webhook (Discord: channel settings > Integrations > Webhooks > New Webhook > Copy URL) or a Guilded one.
  4. Each request posts the user id. Run the erase command in a live server, then delete the message.

## 4) Remotes audit
A read-only pass listed every remote; I fixed what was missing.
- **Fixed, a real exploit:** the clothing store's BuyCosmetic accepted the Pump Shop's lifting gear (the Champion belt and wraps are an EXP multiplier) without the gear's rules. It's now refused there (CosmeticService).
- **Also fixed:**
  - Trainers `equip`: NaN or inf broke the handler.
  - MachineService weight index: `math.huge` indexed past the tiers.
  - The HallOfFame remote had no rate limit (now 2/s).
  - Members and LikeReward had none (now 1/s).
  - GeneticsSeen logged an analytics event on every call (now once per save).
  - The mirror built two rigs per tap (now one look every 4 s).
  - New `Guard.Number` (a real number, in range, whole) for future checks.
- **Already fine:**
  - Every remote is rate limited (Guard).
  - Reward amounts are all computed on the server.
  - Reps: the client sends no amount, there are 0.4 s between reps, and a reps-per-second bucket.
  - Prompts check distance on the server.
- **Not done: a gains-per-minute cap.**
  - Every gain is computed on the server from its own multipliers, and the rep rate is already capped, so a client can't send more.
  - A per-minute EXP watchdog would only catch our own multiplier bugs.
  - "Power Hour" and "rested" don't exist in the code yet.
  - Say if you want the watchdog: it would log to the Admin console and never punish.
- **Left by design:**
  - Rolling and selling trainers works from the TRAINERS menu, anywhere.
  - Court "Join" from the menu.
  - PosingComp join from anywhere.

## 5) Backup routine
- In the Home note ("Weekly backup").

## 5b) Analytics names (not changed: tell me first)
| Pattern | Names |
|---|---|
| Offer_Shown_ / Offer_Tapped_ + offer | 20 |
| Product_Bought_ + product | 25 |
| Product_Bought_Pass_ + pass | 8 |
| Guide_ + how + guide | up to 100 |
| Tour_ + how + tour | up to 40 |
| Locked_Tap_ + tile | 9 |
| Code_Redeemed_ + code | 4 now, +1 per new code (no limit) |
| Load_ + step | 2 |
| LaunchEvent_Online_ + event | 1 (+1 per event) |

- About 209 built names + about 38 fixed = **about 247 custom event names**.
- Roblox caps how many custom event names it tracks; check the current number in Creator Hub > Analytics > Custom events.
- If we're over it, the fix is one event name each, with the id as a custom field (`Guide` + guide id, `Code_Redeemed` + code). Dashboards would change, so only on your OK.

## 6) Checks (report only)
- **Chat:** on **TextChatService** (ok for May 2027). Only the stock Animate scripts in Workspace.NPCs use the old `Chatted` (harmless).
- **Links / socials in game text: none.** The only one is the Roblox group, through Roblox's own join prompt.
- **Sounds:** all from Config/Sounds (APM / Pro Sound Effects / Roblox), except **two music tracks uploaded by the game's own group, named "videoplayback" and "videoplayback (2)"** (86451874359343, 113417603188158).
  - They're the Starter Gym and Pro Gym music.
  - The names suggest audio taken from a video site, so they're likely not licensed.
  - Replace them with APM tracks before the ads: a copyright strike can take the game down.
