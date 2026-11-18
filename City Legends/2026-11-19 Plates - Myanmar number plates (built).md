---
tags: [city-legends, plates, economy, ui]
created: 2026-11-19
---
# City Legends: Myanmar number plates + Plate Office (19 Nov 2026)

> Owner, 19 Nov: "add license plates like the real myanmar. its like the 9E-9999 is expensive and 3Q-3152 (random letters & numbers) are cheap".
> Owner rules the same day: the front digit is 1-9 (never 0), the number is 1000-9999 (never 0001 / 0099). Fancy numbers only at a real-feeling Plate Office.
> Research: [[2026-11-19 Research - Myanmar license plates]].

## What the real plates look like (what the game copies)
- Private car: **black plate, white letters**, raised rim. Top line `YGN-38` (region + township 1-45), big middle line `5T-1648`. Latin letters since 2013 (no Burmese on car plates; only army plates keep Burmese numerals).
- Taxi / hire / bus: **red plate**, doubled letters `AA`..`HH` (`HH-7891`).
- Real plates also print the car's make and model on a 3rd line, so a real plate can't move to another car. The game leaves that line out (fictional makes, small plate spot) and lets you move plates between your own cars (a game choice).
- Lucky numbers in Myanmar: **9** above all (Burmese numerology), repeated digits, digits adding up to 9; **8** from Chinese influence. Real prices found: phone number 0977 7777777 sold for 112M kyat (2016), 9999999 for 42M, 8888888 for 33M; the car plate "7704" for 500,000 kyat (2013). No RTAD plate auction prices found.
- Real Yangon RTAD office: Ywarthagyi, Dagon Myothit (South) Township (driving tests, new licences), far east of the built districts. **Kept for later:** when that district is built, the Plate Office can move there.

## Rules in the game
- Format `[1-9][letter]-[1000-9999]`; letters A-Z without I and O (the research couldn't confirm which letters Myanmar skips; I and O read as 1 and 0). Server rejects anything else.
- Every owned car gets a **free random plate** (`3Q-3152`) the first time it spawns or the plate screen opens. Traffic cars get random plates too (rear plate; ~half the Probox and ~12% of other small cars are red taxis). Taxi and YBS job vehicles and the chauffeur's car get red hire plates; the patrol car a black one.
- **Event plates** stay: the GGFest look's `GGFEST26` still shows over the registered plate. Customs no longer sells free-text plates (its NUMBER PLATE section is now a button to the plate screen).
- **Unique in every server:** each plate is a key in the DataStore `CityLegends_v1_Plates` (follows the PlayerData store name, so test runs use `CityLegends_test_Plates`), claimed with `UpdateAsync` (value = owner's UserId, 0 = free again). Released when a plate is sold or a free plate is replaced. Without DataStores (Studio offline) only unique per server.
- **Moving:** any plate you own can go on any of your cars (the car it left gets a free random one).
- **Selling back:** 50% of what you **paid** (not of the pattern value: a lucky roll can't be sold for its value). Free plates can't be sold. Up to 20 plates each.

## Prices (cash only, no Robux)
- Roll a random plate (menu, anywhere): **$3,000**. A lucky roll keeps its pattern but sells back for $1,500.
- Claim a chosen number (Plate Office only): **$25,000** base + pattern values, rounded to 2 figures:
  - four same digits (1111..9999): +$400k (x1.5 for 8s, x3 for 9s)
  - round thousand (1000..9000): +$150k (same lucky multipliers)
  - sequence (1234, 6789, 9876 ...): +$250k
  - three same digits: +$70k (lucky multipliers)
  - round hundred: +$40k; mirror (1221): +$80k; repeating pair (1212): +$60k; double pairs (1122): +$50k
  - only 8s and 9s: +$150k; 2-3 lucky digits: +$15k each
  - adds up to 9: +$15k (the "7704" belief)
  - front digit matches four same digits (9E-9999): x2.5; front digit = first digit of a fancy number: x1.2; lucky 8 / 9 series: x1.15
- Results (Studio self-test): see the test section. Ordinary vanity plates land $50k-$500k; the top `9E-9999` is about $3.5M, above the best Local car ($1.8M), as a long-term cash sink.

## Where it lives
- **Menu:** the phone car menu's PLATES tile (•••), and Legends Customs' NUMBER PLATES button: roll, move, sell, see the office's ideas. PC players reach it through Customs or the office (the ••• menu is phone-only).
- **Plate Office:** a counter + canopy in RTAD navy on the empty grass lot between Legends Customs and the realty on Kabar Aye Pagoda Road (P1), its slab running to the pavement; prompt "Number plates" (E); map icon **#** (blue). No interior (no photos of the inside).

## Code
- `src/shared/Plates.lua`: format, roll / taxi, price + why lines, ideas, `draw` (the real plate look), `selfTest`.
- `src/server/PlateShop.lua`: saved `profile.Plates = { Car, Bag }`, the DataStore claims, remote `PlateCall` (state / roll / quote / claim / move / sell), `PlateOpen`, the office.
- `src/client/PlateClient.lua`: the NUMBER PLATES screen (Customs panel style; half the screen on phones).
- Hooks: `PlayerData` (Plates field, `storeName`), `Main.server` (spawn), `Customs` (event plates only), `Chauffeur`, `CarSkin` + `CustomsClient` (draw), `TrafficBodies` (rear plate by a ray), `UI` (PLATES tile, 4-row car menu), `Main.client`, `Minimap` (#), `Strings` (`plates.*`, Burmese marked for review).

## Test (Studio, 19 Nov)
(filled in below after the play test)
