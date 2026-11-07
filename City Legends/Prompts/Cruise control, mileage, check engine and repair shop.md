# Prompt: cruise control, mileage (value drops), check engine light, wear, a repair shop, fuel and gas stations

_For Claude Code on the PC, with Roblox Studio connected (MCP). **The owner allows inserting any models from the Toolbox / Creator Store for better realism** (2026-11-07): put them in a holding folder in `ServerStorage` first, **remove every script** (Script, LocalScript, ModuleScript; check for hidden ones and fake "copy this command" pop-ups), remove real brand logos and names, then use them; keep a credit list (name, ID, creator) in the notes. Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. Read the Roblox Playbook rules first (`Roblox Playbook/Roblox Playbook - Rules for every game.md`)._

## What the owner wants (2026-11-07)
"Make a prompt for cruise control, check engine light and mileage. The more mileage you have for the car, the cheaper the car value drops. Also add a repair shop, and when the car's redlining for a long time or driving too long without maintenance, etc."

**Keep it fun, not a chore:** wear is slow, warnings are clear, repairs are quick and cheap compared with what players earn, and a car never strands the player.

## 1. Cruise control
- A key to switch it on at the current speed: pick a **free key** (check every key the game already uses; `J` looks free) plus a **button on the phone driving HUD**.
- While on: the car holds that speed on flat roads, up and down hills (the server-checked driving code, not a teleport). **Hold / tap throttle or brake** keys to change the set speed in steps of 5 (mph or km/h by the player's units setting), or a small **+ / −** on the phone button.
- It **switches off** on braking, a crash, leaving the car, the engine stopping, a race / time trial / job start, or when traffic is right ahead closer than a safe gap (a short beep).
- A small **cruise icon with the set speed** on the HUD and on the car's live cluster where it has a spot (green when on).
- Works on every car (old and new models): it's driving code, not a model change.

## 2. Mileage (odometer) per car
- Every owned car has its **own odometer**, saved, counted by the server from the distance it really drives (not in the garage, not on the car transporter / fast travel, not while towed).
- Show it:
  - in the **garage** and **CARS tab** (e.g. "12,480 mi");
  - on the **car's live cluster** where it has an ODO / trip spot (the LFA's "TRIP A" lines, the digital screens);
  - in the **market** and the **dealer's used cars** (see 4).
- **Existing cars:** start each owned car at a fair mileage worked out from its car XP (the XP mostly comes from driving), not 0 and not random. Note the formula.
- New cars bought new from the dealer start at **0–10 mi**.

## 3. Value drops with mileage (and condition)
- A car's **value** (sell-back, trade-in, the market, the garage's "worth" line) = its price (from `Real car prices and harder cash.md`) × a **mileage factor** × a **condition factor**:
  - mileage: loses value smoothly as miles go up (e.g. −10% by the first 1,000 game miles, −25% by 5,000, −40% by 20,000), with a **floor** (never under 45% of its price);
  - **collector cars** (`PriceSource = "collector"`) lose much less (floor 80%);
  - condition (section 4): a car with low health or an overdue service is worth a little less (up to −10%); a **full service history** (always serviced on time) gives a small bonus (+3%).
- All numbers in `Config` (one `Config.Wear` / `Config.Value` block) so the owner can tune them. Tune "game miles" to how far players really drive per hour.
- Show the value with a small breakdown when selling: "Price $120,000 · Mileage −18% · Condition −2% → $96,000".

## 4. Wear, maintenance and the check engine light
Each car has a few simple health numbers (0–100%), saved per car:
- **Engine:**
  - goes down slowly with normal driving;
  - **faster when the car is held on the rev limiter / redline** for a long time (e.g. more than 3 seconds in a row, over and over), with repeated hard launches, and when driving far past the **service interval**;
  - big crashes take a little too.
- **Service (oil):** every car has a **service interval** in miles (e.g. every 600 game miles; Config). Overdue = engine wear speeds up.
- **Tyres** and **brakes:** wear with distance, drifting, burnouts and hard braking (drifting / burnouts wear tyres much faster).
- **Body:** small dents / scratches from crashes if the game has damage visuals; otherwise skip body.

**Effects (small, never game-breaking):**
- **Check engine light** (amber engine icon) on the HUD and on the car's **live cluster**, in its real spot when the cluster has one:
  - **amber steady:** service overdue, or engine health under 60%;
  - **amber flashing:** engine health under 30% (misfires);
  - plus a small "Service due" / "Engine needs repair" line in the garage.
- Engine under 60%: a little less power (up to −8%); under 30%: rough idle and **misfire pops / stutter**, a puff of smoke, up to −15% power; under 10%: **limp mode** (top speed capped, still drivable), never a dead car. A message says where the nearest repair shop is (with a map pin).
- Worn tyres: less grip (up to −10%); worn brakes: longer stopping (up to −10%), a squeal sound.
- **New players are protected:** no wear for the first hour of play, and the first service is free.
- **Races / time trials:** wear still counts, but no car's health drops during a race enough to change the result (only after it).

## 5. Repair shop: "Legends Service"
- A new **repair shop** venue on the map, near Legends Customs (realistic building in the Monaco style: workshop doors, a lift, tyre racks, a sign "LEGENDS SERVICE", lit at night; cleaned Toolbox props allowed: scripts removed, no logos). On the minimap and the fast-travel list. If space is tight, a separate service bay at Legends Customs with its own entrance is fine.
- Drive in, stop in the bay, press the interact key / tap SERVICE: a screen in the game's UI style (the same kit as the dealer / Customs):
  - the car's health bars (engine, service, tyres, brakes, body) and mileage;
  - options: **Oil service**, **Engine repair**, **New tyres**, **Brakes**, **Body repair**, and **Full service** (all of them, with a small discount);
  - prices: a **real-world-style price** (oil service about $100–300, brakes $400–1,500, tyres the price of the car's tyre set, engine repair by damage) **× the same `PartPriceMult` (2.5)** and a little more for expensive cars (at most × 1.5);
  - a short animation (the car on the lift, a few seconds), then the bars fill.
- A **service book** per car: date and mileage of each service (shown in the garage; it gives the value bonus above).
- Tuned parts (from the upgrades) keep working; a fresh service never removes parts.

## 5b. Super realistic buildings (owner, 2026-11-07)
- The **repair shop** and the **gas stations** must look **super realistic**, like real Monaco buildings: real proportions, proper materials (concrete, glass, brushed metal, tiles), detailed interiors you can see through the doors / windows, workshop lifts, tool walls, tyre racks, an air / water point, lit signs, good lighting day and night, people / staff NPCs if the game has them. Use **cleaned Toolbox models** wherever they look better than building from parts. Fictional names and logos only (no Esso, Shell, TotalEnergies, Bosch etc.).
- Check them from the street, from above and up close (day and night) and compare with real photos.

## 5c. Fuel and gas stations
### Fuel
- Every car has a **fuel tank** (its real size in litres / gallons, close enough) and uses fuel as it drives: more with hard throttle, high revs and a big engine; less when cruising. Tuned engines and engine swaps use a bit more.
- **A full tank lasts about 30–45 minutes of normal driving** (Config), so players refuel now and then, not all the time.
- **Fuel gauge:** on the HUD and on every car's **live cluster** where it has one (the LFA's fuel bar, the Maybachs' fuel bar, the needles' fuel dials). A **low-fuel light** and a toast at about 15% ("Low fuel: nearest station 0.8 mi", with a map pin).
- **Running out:** the engine sputters, then the car coasts to a stop (it doesn't vanish or explode). The player can:
  - **call roadside help** (a tow to the nearest gas station for a fee, or a small fuel can delivered: a few litres, enough to reach a station), or
  - push on: on foot to a station and back is too slow, so make roadside help cheap.
- **EVs** (the EV6, SU7, U8, Seal and any other electric car) use **battery charge** instead: a battery gauge, charging at the gas stations' fast chargers (a little slower than refuelling).
- **Never in races:** fuel can't run out during a race, time trial, job or heist (it pauses at 1%).
- **New players** start with a full tank, and their first fill-up is free.
- Fuel and charge are server-side and saved per car.

### Gas stations at their real places in Monaco
- **Find the real fuel stations in Monaco** and put ours where they really are on our map:
  - get them from **OpenStreetMap** (Overpass API: `amenity=fuel` inside Monaco; the map already uses OSM data; credit "© OpenStreetMap contributors");
  - you may **look** at Google Maps / Street View to check each one's position, layout and look, but don't copy Google's map data or images into the game;
  - **don't put stations close to each other** (owner, 2026-11-07: some real ones are very close together on Google Maps). If two real stations are near each other (e.g. within about 400 m in real life, or so close on our map that both are visible from one), **keep only one of them** (the one on the bigger road / easier to reach) and skip the other. Spread the stations so every part of the map has one within a fair drive. Note which ones were kept and skipped.
  - place each station on our map at the matching spot (the map is built from OSM, so convert with the same transform). If a real spot doesn't fit our roads, put it on the nearest sensible plot and note it.
- **Each station:**
  - a canopy with lights;
  - 2–6 pumps (fuel types / prices shown), plus **EV fast chargers**;
  - a small shop / kiosk with a lit window, an air and water point;
  - our own **fictional fuel brand** (e.g. "Riviera Fuel"), a price sign;
  - lit at night (no neon: warm white / LED light).
  - Traffic can drive past and in / out without getting stuck.
- **Refuelling:** stop at a pump, press the interact key / tap FUEL: a small screen (the game's UI style) with the litres, price and "Fill up" or "Add $X"; a short animation (nozzle in, numbers counting), then done. Price per litre about a real Monaco price × a small multiplier (Config) so a full tank costs **about 1–3% of an hour's earnings**.
- Add them to the minimap, the world map / fast travel list and the GPS ("nearest gas station").

## 6. Fair balance (don't make players quit)
- An oil service should cost about **2–5% of what a player earns in an hour** with that car class; a full engine repair about 15–30%.
- Normal driving with on-time services should **never** reach the flashing check engine light.
- Remind gently: a "Service due in 50 mi" toast, not spam.
- Everything in `Config` and noted in `City Legends/City Legends.md` with old / new values.

## Saves and safety
- New save fields per car: miles, engine / service / tyres / brakes / body health, the service book. **Old saves** get sensible starting values (mileage from car XP; health 100%, service due in a while).
- Mileage, wear and repair payments are **server-side** and checked; the client can't set them.
- Add a Lune test (like `tools/carlevels_test.luau`) for mileage counting, value, wear and repair prices, and an old save loading.

## Check before you say done
- In Play (PC and phone 667 × 375):
  - cruise control on / off, adjust, cancels on brake;
  - mileage goes up while driving and shows in the garage and on the clusters;
  - selling shows the value breakdown;
  - holding the redline wears the engine; overdue service lights the check engine light; misfires below 30%; limp mode below 10%;
  - the repair shop fixes everything and the light goes off;
  - an old save loads with fair mileage;
  - fuel goes down while driving and shows on the HUD and the clusters; the low-fuel light; running out, then roadside help; refuelling at a station; an EV charging; fuel never runs out in a race.
- Screenshots: each gas station next to a real photo of the same spot, the fuel gauge and low-fuel light, refuelling; the cruise icon, the check engine light (HUD and a cluster), the repair shop outside day / night and its screen, the sell breakdown.
- Lune tests and `luau-lsp analyze` clean; no errors; FPS fine. Save the place, commit, push; note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- the controls (cruise key and button);
- how fast cars lose value and wear (the main numbers);
- the repair shop's location and prices;
- the gas stations (how many, where, fuel prices) and how long a tank lasts;
- the Toolbox models used (credits);
- screenshots.
