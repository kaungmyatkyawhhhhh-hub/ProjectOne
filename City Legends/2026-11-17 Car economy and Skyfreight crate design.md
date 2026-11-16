---
tags: [city-legends, economy, crate, monetization]
date: 2026-11-17
---

# City Legends - car economy, import crates and jobs (design decided 16-17 Nov 2026)

Everything here was decided in one long chat with the owner (Rong) and his friend Guapo. Numbers are starting values to tune in playtests. Research behind it: [[2026-11-17 Research - Monetization psychology, crate reveal, sound UI VFX]].

## Hard rules
- No real car brand names, logos or badges anywhere (game, pass names, thumbnail, descriptions). Roblox removed real-brand cars (Toyota, BMW, Lamborghini, Honda) and DevForum advice is to avoid them. Misspellings of a brand (for example "Baggate") do not protect us. Check any new name against trademarks and the Roblox catalog (we dropped "Aurelion" because it is a League of Legends character name).
- Hypercar stand-in for the Bugatti: working name **Velkara** (invented). Alternatives: Vantor GT, Solvane, Auranova.
- Roblox paid random items policy applies to any crate bought with Robux or with cash bought with Robux: show real numerical odds before purchase, every pull gives a car (never empty), cars from paid random items cannot be traded or sold, use `ArePaidRandomItemsRestricted` (PolicyService) to hide the crate for restricted users (UK under 18). Odds by rarity are acceptable only if every car inside a rarity has the same chance; if one car is rarer, it must be listed by name. This reading comes from DevForum, not an official statement - treat as a risk.
- Server rolls the crate, the client only plays the animation. Skip button for the animation.
- Mobile: keep Open and any tappable button away from Roblox's joystick (bottom-left) and jump button (bottom-right).
- Fps matters more than car quality. NPC traffic cars are the lightest models.

## Rarity and source
Each car has two attributes: rarity (Common, Uncommon, Rare, Epic, Legendary, Mythic, Hypercar) and source:
- **Local** = exists in Myanmar. Can be bought on the dealership shelf with cash at any rarity. The Legendary Local trio (Diablo-, LP700-, Murcielago-style) sits on the shelf at a very high price.
- **Import-only** = not in Myanmar. Only from crates and the airport.
- Epic examples named by the friend: 458 Speciale-style -> **Corsa Vento**, Huracan-style -> **Wedge Aria**. Legendary trio -> **Wedge Verra, Wedge Nox, Wedge Solis**. All with own badge, own lights and grille.
- Variants (families): base + 2-3 variants as separate cars of higher rarity, built from swappable parts (bumpers, wing, wheels, paint). Use own letters, not the real model letters. Family completion bonus. NOTE: the owner says all models are already done.

## Import flow (friend's idea, adopted)
1. Drive to the dealership, open a crate, see the reveal.
2. Car goes into the import queue with a timer (server timestamp, keeps running offline). Max 3 queued.
3. Wait: Common 1 min, Uncommon 3, Rare 6, Epic 8, Legendary 12, Mythic 15, Hypercar 15. (Owner's first idea was about 10 min for every import; scaled so free players are not bored.)
4. Notification and map marker to the airport cargo area. Claim there, car spawns on the apron with a short plane/truck animation.
5. Rush Import (Robux) skips the timer: Common 19, Uncommon 39, Rare 69, Epic 99, Legendary 149, Mythic 199, Hypercar 249 R$. Rush lives on the import queue screen, not on the crate screen.
- Keep dealership and airport close (compact map). Top HUD shortcut buttons to Dealership and Airport.

## Dealership
One building, three tabs: Buy (shelf), Import Crates, Exclusive. Shelf prices (cash): Common 8,000; Uncommon 25,000; Rare 80,000; Epic 250,000; Legendary 800,000.

## Crates
| Crate | Cost | Contents |
|---|---|---|
| Basic | 5,000 cash | Common to Rare |
| Premium | 40,000 cash or 199 R$ | Rare to Legendary, small Mythic chance |
| **Skyfreight** | 399 R$ only | Epic and above |

Skyfreight (399 R$), pool of 39 cars (target; launch with fewer, models are done so can be larger): Epic 15 cars 58% (about 3.87% each), Legendary 8 cars 32% (4% each), Mythic 6 cars 7% (about 1.17% each), Hypercar 10 cars 3% (0.3% each). Launch version was Epic 4 / Legendary 3 / Mythic 1 / Hypercar 1 with 60 / 33 / 6 / 1.
Owner wanted the Bugatti-type at 1%. With 10 hypercars the tier is 3%; if it must stay the top chase, list its exact odds (this reveals it).
- Pity: guaranteed Legendary or better every 10 Skyfreight crates; guaranteed Hypercar (any) at 100 crates (earlier plan: 150). Show as "N crates until a guaranteed X", not a fraction.
- Duplicates refund about 50% of value: Common 4k, Uncommon 12k, Rare 40k, Epic 125k, Legendary 400k, Mythic 1M, Hypercar 2.5M.
- Do not sell cash for Robux (keeps the paid random rules simpler). Robux buys crates, Rush Import and a Double Pay gamepass (199 R$).
- **Owner decision 17 Nov: do not show the cars on the crate screen, keep it curious.** Show mystery silhouettes with "?" on rarity-tinted tiles, tier odds and car counts, and a "Car odds" button with the equal-chance line. A collection book shows unowned cars as silhouettes.

## Income and sinks
- Active jobs (delivery, taxi): about 600 cash/min (about 36k/h) at the start, rising to about 100k/h late. Passive posts about 200/min with an hourly cap. Daily login 2k rising to 20k over 7 days.
- Targets: Basic crate in 10-15 min of play; Premium in about an hour for free players.
- Sinks: garage slots (3 free, then 50k, 150k, 400k...), paint and wheels 2k-50k, traffic fines, small repair fees.
- Bonus for obeying traffic (stopping at lights and roundabouts). Chase bonus for catching the rare NPC supercar.

## Jobs (Roblox-roleplay style) and AFK
Job Center near spawn. Jobs: delivery, taxi, shopkeeper/tea shop, traffic police, bus driver, dealership staff. Passive jobs pay about a third of active per minute, must stand at the post, capped per hour (about 2 h then a "tap to keep going" prompt).
Owner wants players to rejoin the same place at 19 minutes of idle (Roblox kicks idle at 20): server saves position, job, car; `TeleportService:TeleportAsync` to the same place with `ServerInstanceId = game.JobId`; restore from teleport data; retry on failure; only for players at a passive post. Not an official Roblox statement that this is allowed - watch moderation.

## Traffic and NPC supercars
NPC traffic must stop at intersections, roundabouts and lights. Rare NPC supercars cut through traffic: one Lambo-type in the whole city, about 10 GTR/Fairlady-type, optionally one Bugatti-type is NOT in traffic (it must stay exclusive).

## Skyfreight crate screen - UI reference
ChatGPT mockups (16-17 Nov). Chosen style: cargo-label paper panel, hazard stripe border, stencil title, orange plane logo, orange metal crate with blue stripe, bright daytime airport background with the Shwedagon. Green Open button "OPEN 1 CRATE | R$ 399 per pull" moved up into the middle of the left half; "CAR ODDS" cargo-tag button; pity bars with gap text; "Cars from this crate cannot be traded." No spiky sunburst anywhere. Needs: purchase confirmation popup before spending Robux, Skip button, bigger small text for phones, pity bar fills that match the text. Build the real screen in Studio, the ChatGPT image is layout reference only.

## Open items
- Name check for Velkara; list of the finished models sorted into tiers.
- Build order: car data table (name, rarity, source, odds, import time, non-tradable flag) -> server-side crate roll -> timer queue saved to player data -> airport claim -> shelf -> jobs -> Rush and packs.
