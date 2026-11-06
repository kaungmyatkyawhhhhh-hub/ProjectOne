# Prompt: a much better upgrade area (workshop) and a Part Shop, plus the new starter cars (Part 2)

_For Claude Code on the PC, with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). The owner asked for Claude's own ideas this time (marked **[idea]**); do those too._

## What the owner wants (2026-11-06)
"Make the upgrading area way better. Take examples from these photos and also add a part shop, for example pop tune ECU, crackle tune ECU, muffler delete, straight pipe, downpipe and more. Also add some of your own ideas."

**Reference screenshots** (from another Roblox game; copy the **layout and ideas**, not their art, icons or part brand names), in `Games/CityLegends/imports/refs/ui/upgrades/`:
- `upgrade_workshop_example.webp`: the workshop. It shows:
  - the car on a **lift in a real garage** (lifts, tool chests, tyre racks, strip lights);
  - the car's name top left, then a list of the **installed part in each slot** (Main Engine, Intake, Camshaft, ECU, Exhaust, Cylinder Head, Fuel Injector, Air Filter), with "Click on part to uninstall";
  - an **Items** grid of parts you own (x1) to install;
  - **PART SHOP / APPEARANCE / EXIT** tabs at the top and cash top right;
  - a **Stats** panel: Power (current / max), Torque and Weight, as bars;
  - a **live dyno graph** of power and torque against RPM;
  - a **Launch Control RPM** setting;
  - a row of **category icons** along the bottom (engine, gearbox, suspension, turbo, intake, body, wheels, tools).
- `parts_shop_example.png`: the Part Shop. It shows:
  - category tabs (Engine, Transmission, Turbos, Supercharger, Tires, Suspension, Body) and a search box;
  - **rarity filters** (All, Common, Uncommon, Rare, Epic, Legendary);
  - a grid of part tiles **coloured by rarity**, each with an icon, a name and a price;
  - a details panel with BUY.

## What we have now (keep it working)
`Config.CarParts`, `CarStats`, `client/CarUpgrades.lua` and `server/CarLevels.lua`:
- 12 parts (intake, fuel, flywheel, cams, displacement, turbo, exhaust, gearbox, tyres, brakes, suspension, weight), each Street / Sport / Race;
- paid with CP or cash; saved per car (`CarParts`);
- they change the car's numbers and its PI / class;
- stock S2 / R / X cars only take tyres, gearbox, suspension and exhaust (`TopClasses` / `TopAllowed`);
- opened from the garage's UPGRADE and from Legends Customs (PERFORMANCE PARTS).

**Nothing a player has now may be lost:** every car's current Street / Sport / Race parts become the matching new parts, installed (see Saves).

## 1. The workshop (the new upgrade screen)
- A **real workshop room** inside Legends Customs:
  - the car up on a **two-post lift**;
  - tool chests, a tyre rack, an engine on a stand, warm strip lights, a polished concrete floor and our Legends Customs sign;
  - Toolbox props allowed (cleaned: scripts removed, no logos).
  - The garage's UPGRADE button also takes you here, or shows the same screen over the garage.
- **Camera:** slow orbit round the car; drag to turn; tap a slot to zoom to that area (engine bay for engine parts, wheels for tyres / brakes, rear for exhaust).
- **Layout: our own, NOT the reference's** (owner, 2026-11-06: the first mockup was "a little too similar to the reference photo"). Follow `Games/CityLegends/imports/refs/ui/upgrades/workshop_mockup.png` (source: `workshop_mockup_source.html`), in our City Legends style, phone first:
  - **the car in the middle is the player's real 3D car model** (not a picture) on a turntable with a red ring and floor light; drag to spin;
  - **hotspot pins on the car** (ENGINE 5/8, BOOST 1/4, EXHAUST 3/5, GRIP 2/3, CHASSIS 2/4: filled slots / all slots, pin colour = best rarity fitted); tapping a pin zooms the camera there and opens that category;
  - **left rail:** round category buttons (Engine, Boost, Exhaust, Drive, Grip, Chassis, Body);
  - **top:** car name with its class badge and level on the left; **UPGRADE / SHOP / TUNE / STYLE** pills in the middle; cash, CP and a close ✕ on the right;
  - **right:** a **PI ring** (class letter and number, the change in green, "still class B (A at 601)"), four small rings (Power, 0-100, Top speed, Grip) with differences, and a big **DYNO RUN** button;
  - **bottom drawer:** the open category's slots as rarity tiles (tap one), then that slot's options (installed / owned · install / buy price).

## 2. Slots (what can be installed)
Each slot holds one part:
| Category | Slots |
|---|---|
| Engine | Intake, Air Filter, Camshaft, Cylinder Head, Fuel Injectors, **Fuel Pump**, Pistons & Internals, Engine Block / Displacement, **Ignition** (coils, spark plugs), **ECU tune** (Stage 1, Pop, Crackle, Burble, **Anti-Lag map**, **Rev Limiter raise**), **Engine Swap** (43 engines, below) |
| Forced induction | **Turbo** (ball-bearing, big single, twin-turbo kit) **or Supercharger** (centrifugal, twin-screw, smaller pulley): one or the other; Intercooler, Blow-off valve, **Wastegate**, **Boost Controller** |
| Exhaust | **Downpipe**, Catalytic converter (stock / high-flow / **decat**), Mid-pipe, **Muffler** (stock / sport / **muffler delete** / **straight pipe**), Exhaust tips |
| Drivetrain | Gearbox (close-ratio, **sequential**, **dual-clutch**), **Short Shifter**, Clutch, Flywheel, Differential (LSD), Final drive, **Carbon Driveshaft** |
| Tyres & wheels | Tyres (**street / sport / semi-slick / drift / drag radials / rally**), **Forged light wheels** (lighter, small grip and acceleration gain) |
| Brakes | Pads, discs, big brake kit |
| Suspension & steering | Springs (**lowering springs**) / Coilovers / **Air suspension** (lower when parked), Anti-roll bars, **Camber kit**, **Strut brace**, **Poly bushings**, **Drift angle kit** (more steering lock) |
| Cooling | **Oil cooler**, **Race radiator** (keep power on long runs; small effect) |
| Body & interior | Weight reduction stages, Carbon bonnet, Carbon roof, **Lightweight battery**, **Bucket seats**, **Roll cage** (stiffer, small grip), Rear wing (small grip at speed) |

Every part on both icon sheets has a slot here (68 parts). Effects stay small per part; the big jumps are turbo / supercharger, displacement and engine swaps.

## 3. Parts and the Part Shop
- **Rarity:** Common (grey), Uncommon (green), Rare (blue), Epic (purple), Legendary (orange / gold). Rarity tells how strong the part is and how much it costs:
  - Common ≈ a little better than stock;
  - Uncommon ≈ today's Street;
  - Rare ≈ Sport;
  - Epic ≈ Race;
  - Legendary ≈ a little above Race, with a perk (see below), and expensive.
- **Our own fictional part brands** (never real ones, and not the reference game's): e.g. Ferrolux, Kestrel Works, Tachyon, Steelvein, Pulsewerk, Nightcoil, Draxa, Corvin Motorsport. Names like "Kestrel Works Cold Air Intake", "Tachyon Stage 2 ECU". Write them in `Config`; check none is a real company.
- **The Part Shop screen**, like the reference:
  - category tabs, a search box and rarity filters;
  - tiles coloured by rarity, each with its icon, name, price and **"fits this car" / "doesn't fit"**;
  - a details panel with BUY (cash, or CP where it makes sense), plus **BUY & INSTALL**;
  - **use our icon sets:** `part_icons_sheet.png` (33 tiles) and `part_icons_more_sheet.png` (35 more: lowering springs, air suspension, camber kit, strut brace, bushings, drift angle kit, short shifter, sequential and dual-clutch gearboxes, final drive, carbon driveshaft, street / sport / drift / drag / rally tyres, forged wheels, centrifugal and twin-screw superchargers, smaller pulley, big single / twin / ball-bearing turbos, wastegate, boost controller, anti-lag, rev limiter, coils, spark plugs, fuel pump, oil cooler, radiator, light battery, roll cage, bucket seats), both in `Games/CityLegends/imports/refs/ui/upgrades/` (each with an `_source.html` holding every icon as SVG; the first is `part_icons_source.html`; the source with every icon as SVG is `part_icons_source.html` next to it). Turn each icon into a sharp white PNG (512 px, transparent) for Roblox, and copy the tile look: rarity gradient, top shine, rarity pill, name, brand · slot, a green price bar. The owner asked for these (2026-11-06).
- **Exhaust and ECU parts the owner asked for**, each with its own sound / feel:
  - **Pop Tune ECU:** pops on lift-off;
  - **Crackle Tune ECU:** long crackles on lift-off, and on downshifts;
  - **Burble Tune ECU:** soft burbles at low revs;
  - **Muffler Delete:** louder, rawer;
  - **Straight Pipe:** loudest, most raw, a tiny bit more power;
  - **Downpipe:** more power with a turbo, a louder turbo sound;
  - **Decat:** more power, louder crackles.
  - Use the sound system's existing **Pops / Crackle / ShiftPop** pieces (`Config` audio, e.g. `Exhaust_*_Pops`), with louder volume and more distortion for loud exhausts. No new engine sound IDs: the owner sends those. Where a car has no pops sound yet, use the shared one.
  - Small **exhaust flames** for the loud tunes (pop / crackle + straight pipe / decat), at night too.
- Prices go up with the car's price (`Config.partCash`) and with rarity.
- The **class rules stay**:
  - parts change PI and can move a car up a class;
  - stock S2 / R / X cars only take tyres, gearbox, suspension and exhaust (exhaust **sound** parts are fine on them);
  - the shop greys out what doesn't fit and says why.

## 4. Tune tab
- **Launch Control RPM** (like the reference): the revs the car holds before a launch; a good value gives a better start.
- **[idea]** Simple tuning sliders with a short line of help each:
  - **Final drive:** acceleration vs top speed;
  - **Ride height:** lower = more grip, but scrapes on bumps;
  - **Brake bias:** front / rear;
  - **Tyre pressure:** grip vs drift;
  - **Downforce:** only if a wing is fitted.
  - Small effects, saved per car, with a RESET.

## 5. Own ideas [idea]
1. **Dyno run:** a DYNO button. The car spins its wheels on rollers in the workshop, the engine revs to the redline with the right sound (pops if tuned), the graph draws live, and it ends with "**412 hp → 468 hp (+56)**". Share-worthy.
2. **Builds:** save up to 3 builds per car (e.g. Street, Race, Drift) and switch with one tap; parts move between builds you own.
3. **Parts move between cars:** uninstalling puts the part back in My Parts, so you can fit it to another car it suits. Selling a part gives back 50%.
4. **Rare drops:** sometimes a part is a reward: the daily streak, race golds, the Legends spin, bank heists. Legendary parts only come from the shop at a high price, or as rare rewards.
5. **Engine swaps: 43 engines (the 25 most popular tuning engines, plus the top BMW and German ones)** (owner, 2026-11-06: "the top 25 most popular tunable engines in the world"); see the section below.
6. **Nitrous:** a bottle (small / big) that refills slowly; a short boost with a blue flame. Counted in PI; off in races marked "no nitrous".
7. **Turbo sounds:** a turbo spool whistle and a blow-off "pssh" on gear changes when a turbo / blow-off valve is fitted (from Roblox library sounds or ones already in the game).
8. **Part condition is NOT added** (keeps it simple).

## Engine swaps: the 25 most popular tuning engines (owner, 2026-11-06)
An **ENGINE SWAP** slot (Engine category). A swap replaces the car's engine: its power, torque, weight, rev limit, layout and **sound** (use the closest engine sound already in the game: I4, I6, V6, V8, rotary or flat-4). After a swap, the normal engine parts tune it further, up to that engine's **tuned max**.
- **Names:** engine codes only (like chassis codes), never the maker's or trademark words (no "VTEC", "EcoBoost", "Coyote", "Hemi", "Hellcat", "TFSI"). Add a short layout name, e.g. "2JZ 3.0 I6 Twin-Turbo".
- **Fits:** every petrol car except stock S2 / R / X cars (class rule) and EVs. Drive type stays the car's own. The engine bay doesn't change visually (no new engine meshes needed); the workshop shows the engine icon and the dyno.
- **PI and class** move with the swap. The shop shows the new class before buying ("B 562 → A 648").
- Price by rarity (times the car price factor as usual). Rough start: Uncommon $150K, Rare $350K, Epic $800K, Legendary $2M–3M. Tune these after play-testing.

| # | In-game name | Real engine (for reference only, never shown) | Stock hp | Tuned max hp | Rarity |
|---|---|---|---|---|---|
| 1 | 2JZ 3.0 I6 Twin-Turbo | Toyota 2JZ-GTE | 320 | 900 | Legendary |
| 2 | RB26 2.6 I6 Twin-Turbo | Nissan RB26DETT | 276 | 800 | Legendary |
| 3 | VR38 3.8 V6 Twin-Turbo | Nissan VR38DETT | 565 | 1,000 | Legendary |
| 4 | Barra 4.0 I6 Turbo | Ford Barra 4.0 turbo | 362 | 900 | Legendary |
| 5 | 6.2 Supercharged V8 | Dodge / SRT 6.2 supercharged | 707 | 1,000 | Legendary |
| 6 | LS7 7.0 V8 | GM LS7 | 505 | 800 | Legendary |
| 7 | 20B 3-Rotor Twin-Turbo | Mazda 20B-REW | 300 | 800 | Legendary |
| 8 | LS3 6.2 V8 | GM LS3 | 430 | 750 | Epic |
| 9 | 454 7.4 Big-Block V8 | Chevrolet big-block 454 | 450 | 900 | Epic |
| 10 | 5.0 V8 32-Valve | Ford 5.0 4V V8 | 460 | 800 | Epic |
| 11 | 4G63 2.0 I4 Turbo | Mitsubishi 4G63T | 280 | 650 | Epic |
| 12 | 1JZ 2.5 I6 Turbo | Toyota 1JZ-GTE | 280 | 650 | Epic |
| 13 | 13B 2-Rotor Twin-Turbo | Mazda 13B-REW | 276 | 600 | Epic |
| 14 | N54 3.0 I6 Twin-Turbo | BMW N54 | 300 | 650 | Epic |
| 15 | B58 3.0 I6 Turbo | BMW B58 | 382 | 750 | Epic |
| 16 | 350 5.7 Small-Block V8 | Chevrolet small-block 350 | 300 | 600 | Rare |
| 17 | SR20 2.0 I4 Turbo | Nissan SR20DET | 250 | 550 | Rare |
| 18 | 3S 2.0 I4 Turbo | Toyota 3S-GTE | 255 | 550 | Rare |
| 19 | 4B11 2.0 I4 Turbo | Mitsubishi 4B11T | 291 | 550 | Rare |
| 20 | EJ25 2.5 Flat-4 Turbo | Subaru EJ257 | 300 | 550 | Rare |
| 21 | K20 2.0 I4 | Honda K20 | 220 | 450 | Rare |
| 22 | F20 2.0 I4 High-Rev | Honda F20C | 240 | 350 | Rare |
| 23 | B18 1.8 I4 High-Rev | Honda B18C | 195 | 400 | Uncommon |
| 24 | CA18 1.8 I4 Turbo | Nissan CA18DET | 170 | 400 | Uncommon |
| 25 | EA888 2.0 I4 Turbo | VW EA888 | 220 | 500 | Uncommon |

- The rev limit, torque curve (for the dyno graph) and weight change per engine: rotary and high-rev engines rev to 9,000+, big V8s are heavy with lots of low torque, small I4s are light.
- Each swap gets its own icon (the engine-swap icon with its layout: I4 / I6 / V6 / V8 / rotary / flat-4 badge).
- Check the list against current tuning sources before building; swap an entry only if it's clearly not a popular tuning engine.

### Plus: the top 10 BMW tuning engines and the top 10 German tuning engines (owner, 2026-11-06)
Same rules as above (engine codes only, never "M", "AMG", "TFSI", "VR6" or other trademark words; the closest existing sound; class rules). The N54, B58 (BMW) and EA888 (VW) are already in the 25 above, so each list adds the rest. **43 engines in all.**

**BMW top 10** (N54 and B58 are #14 and #15 above):
| # | In-game name | Real engine (reference only) | Stock hp | Tuned max hp | Rarity |
|---|---|---|---|---|---|
| 26 | S58 3.0 I6 Twin-Turbo | BMW S58 | 473 | 900 | Legendary |
| 27 | S63 4.4 V8 Twin-Turbo | BMW S63 | 600 | 1,000 | Legendary |
| 28 | S55 3.0 I6 Twin-Turbo | BMW S55 | 425 | 800 | Epic |
| 29 | S85 5.0 V10 High-Rev | BMW S85 | 500 | 650 | Epic |
| 30 | S65 4.0 V8 High-Rev | BMW S65 | 414 | 550 | Rare |
| 31 | S54 3.2 I6 High-Rev | BMW S54 | 333 | 450 | Rare |
| 32 | N55 3.0 I6 Turbo | BMW N55 | 300 | 550 | Rare |
| 33 | M52 2.8 I6 | BMW M50 / M52 | 190 | 500 | Uncommon |

**German top 10** (other German makers; EA888 is #25 above):
| # | In-game name | Real engine (reference only) | Stock hp | Tuned max hp | Rarity |
|---|---|---|---|---|---|
| 34 | M177 4.0 V8 Twin-Turbo | Mercedes M177 / M178 | 603 | 1,000 | Legendary |
| 35 | 4.0 V8 Twin-Turbo (EA825) | Audi / VW group 4.0 V8 TT | 591 | 1,000 | Legendary |
| 36 | 5.2 V10 High-Rev | Audi / Lamborghini 5.2 V10 | 602 | 1,000 | Legendary |
| 37 | 3.8 Flat-6 Twin-Turbo | Porsche 3.8 turbo flat-six | 640 | 900 | Legendary |
| 38 | 2.5 I5 Turbo | Audi 2.5 five-cylinder (EA855) | 400 | 800 | Epic |
| 39 | M156 6.2 V8 | Mercedes M156 | 507 | 650 | Epic |
| 40 | 4.0 Flat-6 High-Rev | Porsche 4.0 naturally aspirated flat-six | 500 | 600 | Epic |
| 41 | M139 2.0 I4 Turbo | Mercedes M139 | 416 | 550 | Rare |
| 42 | 3.2 Narrow-V6 | VW 3.2 narrow-angle V6 | 250 | 650 | Rare |
| 43 | 1.8 I4 Turbo 20V | VW / Audi 1.8T (EA113) | 180 | 450 | Uncommon |

- The shop's ENGINE SWAP tab gets filters: **All / Japanese / American / BMW / German / Other** (Barra = Other).
- The 5-cylinder needs its own warble: use the closest sound (I6 pitched up) until the owner sends an ID.

## Saves (don't lose anything)
- New save fields: owned parts, installed parts per car, builds, tune settings.
- **Old saves:**
  - each car's current Street / Sport / Race part becomes the matching Uncommon / Rare / Epic part, **installed**;
  - each new slot without a match starts **stock**;
  - the car's numbers and PI after the move are the **same or a little better, never worse**.
- Server checks every buy / install / uninstall / sell before it's saved (as now). No cheats from the client.
- Write a migration test (`tools/carlevels_test.luau` style) with an old save.

## Check before you say done
- In Play (PC and phone 667 × 375):
  - open the workshop from the garage and from Legends Customs;
  - buy parts in each category, install, uninstall, swap between two cars;
  - try a part that doesn't fit;
  - see the stats and dyno change;
  - a dyno run;
  - the Pop / Crackle tunes and the straight pipe on the road (sound and flames);
  - an old save keeps its parts.
- Screenshots of the workshop and the Part Shop next to the two references.
- Lune tests and `luau-lsp analyze` clean; no console errors; FPS fine in the workshop.
- Save the place, commit, push; note it in `City Legends/City Legends.md` (with the part list and prices).

## When done, tell the owner (short)
- screenshots (workshop, Part Shop, dyno run);
- the part list with rarities and prices;
- anything that needs the owner (sound IDs, prices to approve).

---

## PART 2: new starter cars (350Z, 330i, Ford Focus RS Mk3)
_Owner, 2026-11-06: added to this prompt so both are done in one run. Do Part 1 (the upgrades) first, then this. **The Ford Focus RS replaces the Golf** (owner, 2026-11-06), so don't convert or add the Golf._

### What the owner wants (2026-11-06)
The free starter pick (`Config.Menu.StarterChoices`) becomes:
| Slot | Car | Id | Top speed | Feel text |
|---|---|---|---|---|
| 1 | Horizon 350Z (Z33 after the rename) | `nisun_350z` | 155 | "Grippy sports car" |
| 2 | Bavarica Werkz 330i (G20 Sport after the rename) | `bnw_330i_g20` | 155 | "Quick, comfy sedan" |
| 3 | **Ford Focus RS Mk3** (new car, see below) | new id, e.g. `dearb_focus_rs` | 165 | "All-wheel drive, drift mode" |

Why: the Camaro (top 184) was standing in for the A45 S and was far too fast for a free car. The Focus RS is a little faster than the other two (165): the owner is fine with that.

### Changes
1. **Starter pick** = the 3 cars above. The Chasor, the A45 S and the Camaro leave the pick; they stay in the game as normal cars you can buy (the A45 S is still waiting for its model, `Cars.Pending`).
2. **Bring the 330i back:** remove `bnw_330i_g20` from `Cars.RETIRED`, and move it to the **Starter** tier with a Starter price (about $40K, in line with the 540i $42K and the 350Z $38K). Keep its id, so players who own it keep it. Check its model, cluster and wheel still work.
3. **Ford Focus RS Mk3 (new car):** the owner will put the model in `Games/CityLegends/imports/importing cars/`. Then do the normal new-model routine (`Better car models and clean interiors.md`, Part 3: licence check, logos out, live cluster, clean interior):
   - **Licence first:** check the model's licence before anything else. A commercial licence (bought) or CC-BY is fine (credit it). If it's **NC** (non-commercial) or looks ripped from a game (part names like a racing game's files), **write a warning at the top of the notes for the owner**, then carry on.
   - **New fictional brand "Dearborn"** (Ford; a city name like "Stuttgart" for Porsche): add it to `Cars.Makes`; no Ford oval or lettering anywhere (front, rear, wheel caps, steering wheel, seats, the "RS" badges and side lettering).
   - Name by **chassis code** (Focus Mk3 = C346): **"Dearborn C346 Rallye"**. Never use "Ford", "Focus" or "RS".
   - Stats like the real car: about 350 hp, **all-wheel drive** with a rear bias that lets it slide (a **drift mode** feel: more power to the rear wheels), 0–60 about 4.5 s, top speed 165. Starter tier, price about $42K. Real wheelbase 2.65 m in `CarBuilder.REAL_WB`.
   - **Change it up a little**, the same way as `Small design changes on famous new cars.md`, so it reads as our own:
     - **our own wheels** from that prompt's wheel library (a sport multi-spoke, same size and fit);
     - a **different grille mesh** and lower intakes (slat count / pattern);
     - **tail lights:** change the inner glowing pattern only (outer shape stays);
     - **small details:** the rear spoiler end plates, the diffuser fins and the exhaust tips;
     - a **"C346"** script on the boot in our own font;
     - before / after renders at normal distance and close up.
   - It's a new model, so it also gets the new-model looks (the lighting / car look prompt) if those are done.
4. **The Golf:** don't add it (its model was CC-BY-NC-SA and possibly ripped). Leave its `.glb` in the folder; the owner decides later. No "Wolfsburg" brand for now.
5. **Until the Focus model is in:** slot 3 uses the **540i** (`bnw_540i`, top 155, "Fast and comfy") as its stand-in (`fallback`), not the Camaro. When the Focus is in, it takes the slot.
6. New players who already picked a starter keep their car.

### Check before you say done
- A new player sees the 3 picks (with the 540i in slot 3 until the Focus arrives), can pick each one, and gets it in the garage; phone-size screenshot of the pick screen.
- The 330i shows in the dealer under Starter; old owners still have it.
- Lune tests and `luau-lsp analyze` clean; save the place, commit, push; note it in `City Legends/City Legends.md`.

### Report (starter cars)
- done, the pick screen screenshot, the Focus's licence, and that the Focus model is still needed (if it is).
