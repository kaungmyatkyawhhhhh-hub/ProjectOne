---
date: 2026-11-13
game: Stomp Evolution
build: v132
---
# Meta pass: shop, daily, codes, leaderboards (v132)

Built after "ok do all those". Tested in Play: daily pays, codes pay, leaderboard window fills, shop shows passes.

## Shop (live on universe 10775970272, group 33151111)
| Item | Type | Id | Robux | Effect |
|---|---|---|---|---|
| Auto Stomp | pass | 2088338400 | 399 | auto clicks 150/min (off in Sumo / UI open) |
| Double Mass | pass | 2089880379 | 249 | Mass x2 |
| VIP | pass | 2088656393 | 299 | Mass x1.25, VIP tag, gold sparkles |
| Starter Pack | product | 3730819116 | 39 | 10 min boost + coins, once |
| Boost S | product | 3730819128 | 15 | 5 min boost |
| Boost M | product | 3730819137 | 39 | 15 min boost |
| Boost L | product | 3730819147 | 99 | 45 min boost |

ProcessReceipt in SE_Meta: grant, save, then PurchaseGranted.

## Daily + playtime
- Daily streak (UTC days, 1 grace day): coins 20/30/45/60/80/110/250, Mass minutes 0/0/2/0/3/0/10. Window opens itself once per session.
- Playtime gifts at 5/10/20/40/60 min.

## Codes + update board
- Codes: STOMP, TITAN, RELEASE (once each, saved in d.codes).
- Update board: next "HARBOUR GIANTS", Saturday 15:00 UTC.

## Leaderboards
- OrderedDataStores SE_BestHeight_v1, SE_SumoWins_v1 → workspace attribute SE_Boards (falls back to server players in Studio).

## UI layout
- Top-right row: SHOP / DAILY / GIFT / TOP / CODES, sized to fit beside HEIGHT.
- AUTO square at x 374 desktop / 462 touch, y 206.
- Icons: Shop 105151991588633, Daily 87713927305425, Trophy 76516285491403, Code 99625808694855, GiftClock 92580653532111, Auto 120774137798937, X2 79112720198763, VIP 115927989276821, Chest 120407150216421.

## Still for the owner
2-player Sumo test, live save test, real phone test, server fill "fullest first". The console "No asset content representation" warnings are armour TextureIDs and harmless.
