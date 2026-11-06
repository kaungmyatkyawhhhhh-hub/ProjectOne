# Prompt: a much better upgrade area (workshop) and a Part Shop

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
- **Layout like the reference**, in our own City Legends style (the dealer menu's dark glass panels, showroom red, white type; the same components as our other menus), phone first:
  - top left: the car's name, class badge and level;
  - left: the **slots** with the part installed in each (tap to see it, uninstall, or swap);
  - below that: **My Parts** (the parts you own and haven't installed);
  - top: **PART SHOP / TUNE / APPEARANCE / EXIT**, plus cash and CP;
  - right: **Stats** (Power hp, Torque, Weight, 0–100, Top speed, Grip, PI and class) as bars, with **green / red differences** when you look at a part before installing it;
  - bottom right: the **dyno graph** (power and torque against RPM) that redraws when parts change;
  - bottom: the **category icons** (Engine, Forced Induction, Exhaust, Drivetrain, Tyres & Brakes, Suspension, Body, Tune).

## 2. Slots (what can be installed)
Each slot holds one part:
| Category | Slots |
|---|---|
| Engine | Intake, Air Filter, Camshaft, Cylinder Head, Fuel Injectors, Pistons & Internals, Engine Block / Displacement, **ECU tune** |
| Forced induction | Turbo (or Supercharger: one or the other), Intercooler, Blow-off valve |
| Exhaust | **Downpipe**, Catalytic converter (stock / high-flow / **decat**), Mid-pipe, **Muffler** (stock / sport / **muffler delete** / **straight pipe**), Exhaust tips |
| Drivetrain | Gearbox, Clutch, Flywheel, Differential (LSD), Final drive |
| Tyres & brakes | Tyres (street / sport / semi-slick / drift), Brakes (pads, discs, big brake kit) |
| Suspension | Springs / Coilovers, Anti-roll bars |
| Body | Weight reduction stages, Carbon bonnet, Carbon roof (small weight savings), Rear wing (small grip at speed) |

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
  - our own simple icons, drawn in one style.
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
5. **Engine swaps (Legendary):** a few fictional engines ("V8 4.0 Twin-Turbo", "Flat-6 4.0", "V10 5.2", "Inline-6 3.0 Turbo") that fit chosen cars only (e.g. a V8 in the Bavarica G20). Each changes power, weight and the engine sound to a fitting one already in the game. Big PI change, so the class rules apply.
6. **Nitrous:** a bottle (small / big) that refills slowly; a short boost with a blue flame. Counted in PI; off in races marked "no nitrous".
7. **Turbo sounds:** a turbo spool whistle and a blow-off "pssh" on gear changes when a turbo / blow-off valve is fitted (from Roblox library sounds or ones already in the game).
8. **Part condition is NOT added** (keeps it simple).

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
