---
date: 2026-10-28
tags: [speedarc, progress]
prompt: "[[2026-10-28 SPEED ARC Prompt - 5 Store, passes, Starter Pack, Locker cosmetics]]"
---
# Progress 5 - Store, passes, Starter Pack, Locker cosmetics (M5)

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

Done overnight without questions (owner asleep). **The passes and products still need IDs from you** (list below). Until then their cards say "SOON R$ 249" and can't be bought.

## Built
- **STORE** ([[SPEED ARC - Store and Monetization]]): gold STORE button in the left menu + a "+" on the coins pill. Tabs PASSES / COINS / BOOSTS. Owned passes say OWNED. Prices come from Roblox once the IDs are in (lesson: the game price must be Roblox's price).
- **8 passes:** Auto Train (hero card), 2x Speed, 2x Coins, VIP, Extra Coach Slot, Extra Coach Slot 2, Trail Pack, Faster Rolls.
  - **Auto Train:** an AUTO button on the training panel. The server taps 3 times a second with a steady x1.2 combo, on any station. Every 15 min a "STILL TRAINING?" card; no answer in 60 s = auto stops.
  - **VIP:** +10% coins, VIP before your name (gold), VIP kit, VIP Gold trail, VIP name style, [VIP] in chat.
  - **Trail Pack:** Lightning, Rainbow + 2 new trails: Comet and Neon Wave.
  - **Faster Rolls:** no roll animation, ROLL x3 button (same odds, same coin price; Legendary+ still get their reveal).
- **5 products:** Small / Medium / Large coins (20 min / 2 h / 6 h of coins at your league), 2x SPEED 15 min (stacks with the New Runner boost: you always get what you paid for), Starter Pack.
- **Starter Pack:** once per player, only in the first 24 h after first joining. 1 h of coins + 2x SPEED 30 min + gold Canvas Runners (shoe skin) + STARTER title. Shown after a race WIN (results closed) and in the STORE, never as a timed popup.
- **Offer card:** small card at the bottom, only at calm moments (not training, not racing, no window, never in the tutorial), at most one per 10 min. Two offers: Starter Pack (after a win) and Auto Train (after 10 min of tapping, once a session).
- **ProcessReceipt:** one handler on the server. Records the receipt id with the grant, saves BEFORE telling Roblox "granted", never grants the same receipt twice, works after a rejoin.
- **LOCKER** ([[SPEED ARC - Locker]]): new tabs KITS, HEAD, BIB, NAME, TITLE.
  - 6 kit pieces (3 tops, 3 bottoms) + the VIP kit, 6 headwear, bib number 1-999 + 4 colours (unlock by league), 6 name styles (gradient name over your head), titles list.
  - Prices are minutes of coins at your league (Customization note): kits 5-30 min, headwear 5-20, name styles 60-180.
  - Worn items are welded on by the server (everyone sees them). Other players' worn items hide past 150 studs.

## Tested (Studio, test switches instead of real Robux)
- Every pass granted with `TestGrantPass`: 2x Speed -> training x2, 2x Coins + VIP -> coins x2.2, Auto Train -> +537 MPH in 5 s with no taps, VIP tag + name style over the head.
- Products with `TestBuyProduct`: Small coins +1,200 (L1); **the same receipt id again = nothing** (no double grant); 2x SPEED 15 min = 15:00 boost; Starter Pack +3,600 coins + 30 min boost + title; a second Starter Pack is refused.
- **Rejoin** (Studio save): Medium coins with receipt "persist-receipt-1" -> rejoin -> same receipt again = coins unchanged; the 2x Coins pass is still there.
- Locker: bought + wore Gold Race Tee, Blue Race Shorts, Team Cap, Fire name style, bib 27; then Blue Singlet + Black Split Shorts + Headband + bib 88.
- No script errors in the output.

**Not tested:** real Robux purchases (needs the IDs, then a Studio test purchase works from the real prompt). Phone size (the Device Simulator wasn't on).

## For you: passes and products to create in Creator Hub
Please create these in **the group's** experience (Creator Hub > your experience > Monetization), with **exactly these prices**, then send me the IDs (I'll put them in `Config/Store.lua`):

| Type | Name | Price | Description | Icon idea (cartoon, no people) |
|---|---|---|---|---|
| Pass | Auto Train | 249 R$ | Trains for you on any station. | a blue treadmill with a gold lightning bolt |
| Pass | 2x Speed | 249 R$ | Double SPEED from every training tap. | a gold running shoe with "2x" |
| Pass | 2x Coins | 149 R$ | Double coins from everything. | two gold coins with "2x" |
| Pass | VIP | 299 R$ | +10% coins, VIP tag, VIP kit, VIP trail, VIP name style. | a gold crown on a black badge |
| Pass | Extra Coach Slot | 99 R$ | Equip one more coach. | a whistle with "+1" |
| Pass | Extra Coach Slot 2 | 149 R$ | Equip one more coach again. | a stopwatch with "+1" |
| Pass | Trail Pack | 199 R$ | 4 trails: Lightning, Rainbow, Comet, Neon Wave. | 4 coloured speed streaks |
| Pass | Faster Rolls | 99 R$ | Skip the roll animation, roll 3 at once. | a coach card with "x3" and speed lines |
| Product | Small Coins | 25 R$ | 20 minutes of coins | a small coin pile |
| Product | Medium Coins | 99 R$ | 2 hours of coins | a coin stack |
| Product | Large Coins | 249 R$ | 6 hours of coins | a coin chest |
| Product | 2x Speed 15 min | 25 R$ | Double training for 15 min of play | a stopwatch with "2x" |
| Product | Starter Pack | 49 R$ | Coins, 2x Speed 30 min, gold Canvas Runners, STARTER title (once) | a gold gift box with a shoe |

I did **not** make or upload any icons (you approve each image first, then upload to the group). In the game the cards use drawn badges, so nothing is waiting.

## For you: .fbx files to import
`Downloads\speed_arc_models\locker\` (script: `Games/SpeedArc/blender/locker_kit.py`, previews in `SPEED ARC/Screenshots/models/locker/`):
- Kit_Singlet (1.7K tris), Kit_Tee (1.4K), Kit_ZipTop (1.6K), Kit_Shorts (1.1K), Kit_SplitShorts (1.2K), Kit_Tights (1.2K)
- Head_Headband (1.5K), Head_Cap (0.8K), Head_Visor (0.9K), Head_Shades (0.4K), Head_BucketHat (1.3K), Head_Beanie (1.1K)
Put them in `ServerStorage/Meshes` like the others. They are light grey on purpose: the game tints each one. Until they're in, simple part stand-ins show (blocky).

## Changes / calls I made
- The 2x SPEED product stacks on top of the New Runner / gift 2x (otherwise buying it in your first 15 min would do nothing).
- The tee and zip top have shoulder caps, not sleeves: a rigid sleeve would stick out while the arms swing.
- Boost badge moved next to the rank badge (on the MPH plate it covered "MPH").
- Left menu is now LOCKER / COACHES / STORE / CODES + INVITE, starting under the coach chips.
- New Studio test switches: `TestGrantPass`, `TestBuyProduct` ("Key" or "Key:receiptId"), `TestOffer`, `TestOpenWindow` = "Store" / "Store:COINS".
- Analytics events: OfferShown_X, OfferTapped_X, OfferBought_X.

## Screenshots
![[2026-10-28 p5 store passes.jpg]]
![[2026-10-28 p5 store coins.jpg]]
![[2026-10-28 p5 store boosts.jpg]]
![[2026-10-28 p5 starter offer and kit.jpg]]
![[2026-10-28 p5 locker kits.jpg]]
![[2026-10-28 p5 locker bib.jpg]]
![[2026-10-28 p5 locker name.jpg]]
![[2026-10-28 p5 wearing tee cap bib.jpg]]
![[2026-10-28 p5 auto train vip name.jpg]]
