---
tags: [city-legends, research, traffic, yangon]
created: 2026-11-19
---
# Research - Yangon common traffic cars (2020-2026)

Owner, 19 Nov: "for traffic, rn the ai cars are blocky and so bad. i think it should be the cars that are common irl in yangon". Then: "they should use the cars from the cars that i already made by hand".
Builds on [[2026-11-16 Research - Yangon street furniture and traffic life]] (sections 2.13-2.16). Game side: [[2026-11-19 Yangon traffic - roster cars and racers]].

## What the sources say
- **The fleet is old Japanese used imports.** Most cars on Yangon roads are 2000s-2010 right-hand-drive Japanese used cars. Toyota is by far the biggest make (bestsellingcarsblog photo reports 2013-14; Irrawaddy; Frontier Myanmar).
- **Probox / Succeed is the taxi.** It was about 20% of all vehicles in town in 2014, and 95% of those were taxis, mostly white or silver. Yangon had about 66,000 registered taxis at the 2019 inspection (government news, via search). Crown Comfort-type taxis also run, white with a yellow TAXI roof sign and red plates (ref photo below).
- **The Suzuki Swift is the most common private car** (2014 report). Suzuki led new-car sales with about 50% in 2020 and 37% in 2021 (Focus2move). Swift, Ciaz and Ertiga are built locally.
- **The rest of the everyday mix:** Belta / Vios, Corolla Axio / Fielder, the Mark II / Chaser / Mark X ("shwe nga"), Crown, Wish, Alphard / Noah / Voxy, Hiace, Hilux / Hilux Surf / Land Cruiser / Prado, Honda Fit, Vitz / Ist / Ractis, Mazda Demio.
- **Since 2017-18 new imports are left-hand drive.** These are new Toyotas from Thailand, plus Hyundai, Kia and the local Suzukis. The fleet is a mix.
- **The EV wave since 2022.** The new-car market is small: about 4,200 units in 2024 and about 6,700 (estimated) in 2025. **88% of 2024's new cars were EVs.** BYD led with 33-34%, then MG and Leapmotor (Focus2move 2024, 2025). So BYD Atto 3 / Dolphin / Seal are a new but small share of the road.
- **YBS buses:** about 3,500-4,000 buses on 79-135 routes. In 2017-18, 500 Yutong and 500 Ankai buses came new from China. Before that the fleet was second-hand Korean and Japanese buses (Hyundai Aero City, Hino, Isuzu). The liveries are route-group colours (blue, red, green, purple, brown) and the yellow / white new fleet. There was no YBS-specific evidence of Higer or Golden Dragon.
- **Small commercial vehicles:** Suzuki Carry / Every and Daihatsu Hijet kei trucks; line-bus pick-ups (Town Ace / Lite Ace with a canopy); Toyota Dyna / Isuzu Elf light trucks.
- **Motorcycles are banned in central Yangon** (since 2003): none in traffic.
- **Colours:** white about 45%, silver about 25%, black about 10%, dark grey 5%, the rest 15% (2026-11-16 photo estimate). Taxis are white or silver.

## Top 15 for the game (share = our spawn weight, from the sources above; no exact registration split by model was found)
| # | Real type | Share | Game car |
|---|---|---|---|
| 1 | Toyota Probox / Succeed (taxi, van) | 18% | new: `probox` (ours, with an amber roof sign) |
| 2 | Suzuki Swift | 12% | roster `suzaki_swift` |
| 3 | Toyota Belta / Vios / Axio saloons | 12% | roster `toyoka_belta` |
| 4 | Toyota Mark II / Chaser | 9% | roster `toyoka_chaser` |
| 5 | Camry / Corolla-size saloons | 7% | roster `toyoka_camri` |
| 6 | Alphard / Wish / Noah | 6% | roster `toyoka_alfard` |
| 7 | Hiace vans and ferries | 6% | new: `hiace` |
| 8 | Suzuki Carry / Daihatsu Hijet kei trucks | 6% | new: `carry` |
| 9 | YBS bus (main roads only) | 6% | new: `ybs` |
| 10 | Toyota Crown | 4% | roster `toyoka_crown` |
| 11 | Land Cruiser / Hilux Surf / Prado | 4% | roster `toyoka_lc200` |
| 12 | BYD (Seal / Atto 3) | 3% | roster `byt_seal` |
| 13 | Other EVs (Kia EV6, MG) | 2% | roster `kio_ev6` |
| 14 | New luxury SUVs (LC300) | 2% | roster `toyoka_lc300` |
| 15 | Lexus LX | 1% | roster `lexis_lx700` |

Not in the game yet: Honda Fit, Hilux pick-up, Dyna / Elf trucks and Wish (the Alphard stands in for the Wish).

## Reference photos
![[2026-11-19 Yangon traffic - reference photos (Commons).jpg]]
Wikimedia Commons:
- top left: "Traffic congestion in Yangon" (CC BY-SA 4.0)
- top right: "Sule Pagoda - Traffic - Yangon 2" (CC BY-SA 4.0)
- bottom left: "Yangon taxi 06" (CC BY-SA 4.0); it shows a white Crown Comfort taxi with an amber TAXI sign and red plates, beside a Hijet-type kei truck
- bottom right: "YBS 3G-6922" (Flickr via Commons)

The full set is in `Games/CityLegends/build/landmarks/refs/street_kit/` (`cars/`, `taxi/`, `ybs_bus/`, `pickup/`, each with `sources.json`). The photos are references only and are not used in the game.

## Sources
- bestsellingcarsblog.com: "Myanmar 2014 photo reports: the cars of Yangon"; 2013 photo album
- focus2move.com: Myanmar 2020-2025 market reports (BYD 32.6% in 2024, 34.2% in 2025; EVs 88.4% in 2024; Suzuki about 50% in 2020 and 37.4% in 2021)
- Irrawaddy and Frontier Myanmar on car import policy (2017-18: left-hand drive only)
- Yutong press (500 city buses for Yangon, 2017); southeastasiainfra.com (1,000 YBS buses: Yutong + Ankai)
- Wikipedia "Yangon Bus Service" (fleet about 4,000, about 135 routes; undated)
- CEIC: 741,370 registered cars in Myanmar (Jul 2022)
