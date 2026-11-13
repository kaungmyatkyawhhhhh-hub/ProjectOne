# Prompt: make the performance shop (Workshop / Part Shop) a lot more fun, with more variety

_For Claude Code on the PC, with Roblox Studio connected (MCP). Read all of this first, plus the Workshop notes in `City Legends/City Legends.md` ("Workshop and Part Shop") and the Roblox Playbook rules (`Roblox Playbook/Roblox Playbook - Rules for every game.md`, especially money, odds and retention). Owner: talk short and simple (caveman mode, see `Preferences.md`). The owner asked for Claude's ideas this time; they're listed below. **No errors:** anything that can't be done cleanly is left out and written at the top of the notes._

## What the owner wants (2026-11-13)
"Make the car performance shop more fun, with different, more varieties, and make it a billion times better."

## What's there now (keep it all working)
`client/Workshop.lua`, `shared/PartData.lua`, `CarStats`, `server/CarLevels.lua`, `client/CarUpgrades.lua`, `client/PartArt.lua`: the workshop room, 47 slots in 7 categories, 150+ parts with rarity (Common → Legendary), 8 fictional part brands, 43 engine swaps, the dyno, TUNE, builds, parts moving between cars, selling, rare drops, nitrous, sound parts, real prices × 2.5 (`Config.Economy.PartPriceMult`). Old saves must keep every part.

## The new things (do them in this order; each one tested before the next)

### 1. Part rolls: every part is a little different (the main "loot" fun)
- Each part bought or dropped gets **1–2 small bonus stats** rolled from a list that fits its slot (e.g. a turbo: +1–4% power, −2–8% turbo lag, +1–3% top speed; tyres: +1–4% grip, +1–3% braking; ECU: +0.5–2% power, sharper throttle). Higher rarity = more and bigger rolls; Legendary always gets 2.
- A **"PERFECT"** tag (gold shine) on a part with top rolls (about 1 in 50).
- Rolls show on the part card, in green; they count in PI / class (keep the class rules).
- **Re-roll** a part's bonus stats with CP or cash (rising cost each time).
- Old parts from before this change get rolls too, never worse than now.

### 2. Brand sets: build loyalty to a part brand
- Fitting **3 / 5 parts of the same brand** on one car gives a **set bonus** (e.g. Pulsewerk 3-set: −10% turbo lag; Ferrolux 3-set: +3% grip; Tachyon 5-set: louder pops and +2% power) and a small brand badge on the car card.
- Each of the 8 brands gets its own style: a colour, a short motto, what it's good at (turbo, grip, sound, weight...). The shop can filter by brand.

### 3. Build planner and archetypes
- A **BUILD PLANNER** tab: pick a goal: **Drag**, **Drift**, **Grip / Track**, **Top Speed**, **Street**, **Sleeper** (looks stock, fast inside), or **"Best for my class"** (best build that stays in the car's class, e.g. stays A).
- It suggests a full set of parts for that goal, shows what you already own, what's missing, the total cost, and the new numbers (power, 0–60, ¼ mile, top speed, grip, PI / class) before buying. **BUY ALL MISSING** and **FIT ALL** buttons.
- The car gets a goal tag in the garage ("DRIFT BUILD", "SLEEPER").

### 4. Better numbers you can feel
- Show **0–60, 0–100, ¼ mile time, top speed and lap-feel (grip)** for every change, before and after, worked out from `CarStats` (an estimate, labelled as one).
- **Stage badges** like real tuning: **Stage 1 / 2 / 3 / 4** by how many power parts are fitted, shown on the car card, garage and dealer.
- **Dyno:** keep the dyno run; add a **before vs after overlay**, a **power-to-weight** line, a **share card** (a nice picture of the result with the car and the numbers), and a **dyno leaderboard** per class (best hp on the server and all-time, by car).

### 5. Try before you buy
- **Hear it:** a ▶ preview button on sound parts (exhaust, ECU tunes, turbo, blow-off) plays the car with that part for a few seconds in the workshop.
- **Test it:** "TEST FOR 2 MIN" on any part: you drive out with it fitted for 2 minutes (like the dealer's test drive), then it comes off unless you buy it. One test per part per day.

### 6. A shop that changes every day
- **Today's deals:** 4 parts at 20–40% off, new every day (UTC).
- **Weekly Legendary:** one Legendary part or engine swap for sale this week only, then it rotates.
- **Weekend sale** on one category (e.g. "Turbo weekend").
- A small "NEW" and "SALE" pill on those parts.

### 7. Part crates (cash only, odds shown)
- **Street Crate, Sport Crate, Race Crate:** bought with **in-game cash or CP only (never Robux)**, each gives one random part for your car's slots, with **the odds shown** before buying (like the spin wheel's ODDS). Duplicates can be sold or fused (8).
- Follow the Playbook's odds rules. No Robux crates (owner can decide later).

### 8. Fuse and upgrade parts
- **Fuse:** 3 parts of the same rarity → 1 random part of the next rarity (Common → Uncommon … Epic → Legendary), with a nice animation.
- **Part levels:** a part can be raised from level 1 to 5 with CP and cash; each level adds a little to its rolls (max +5% total), shown as stars on the card.

### 9. Visible parts: what you buy, you see
- Where it's safe on the new models, performance parts show on the car: **brake calipers** (big brake kits bigger, in the chosen colour), **exhaust tips** (shape and number from the exhaust parts), **rear wing**, **carbon bonnet** (carbon look), **wider tyres / forged wheels**, a **roll cage** inside, **intake / turbo** visible through engine-cover glass on cars that have it.
- Old models: only the parts that already show (no new visuals on them).

### 10. Goals and collection
- **Tuning challenges** in Goals / daily tasks: e.g. "Make a Starter car reach 400 hp", "Build a sub-11s ¼ mile car", "Fit a full brand set", "Get a PERFECT part" (cash, CP and crate rewards).
- **Parts Dex:** a collection book of every part (seen / owned / PERFECT), with rewards for completing a brand or a category.

### 11. Share and copy builds
- Look at another player's car build (walk up to it or from the meet): see its parts, numbers and Stage.
- **"COPY BUILD"**: the planner fills with their build for your car (if it fits), showing what you're missing and the cost.

### 12. The workshop feel
- A **mechanic** NPC in the workshop with a few short tips ("Your rear tyres are holding this car back", "One more Pulsewerk part for a set bonus").
- Small sounds and animations: parts snapping on, the lift moving, a ratchet sound, sparks on a fuse, a cheer on a PERFECT roll.
- Everything in the **City Legends UI style** (the dealer / Workshop look), phone first.

## Rules
- **Balance:** rolls, sets, levels and fuses are all small; together they can't break the class system (cap the total extra at about +10% per stat, and PI / class always shows the truth). Re-check race fairness.
- **Economy:** use the prices from `Real car prices and harder cash.md` / `PartPriceMult`; crates and re-rolls are money sinks, tuned so a normal player can afford something new every play session. All numbers in `Config` (one block per feature), noted in the notes.
- **Saves:** new fields for rolls, levels, sets, crates, dex, deals; old saves load with every part kept (and fair rolls). Server checks every buy / roll / fuse / test (no cheating from the client). Add tests (like `tools/carlevels_test.luau`).
- **Performance:** no FPS drop in the workshop or when many tuned cars are around.

## Check before you say done
- In Play (PC and phone 667 × 375, 2 players): each feature from 1 to 12 used at least once (buy and roll, re-roll, a set bonus, the planner's BUY ALL / FIT ALL, the numbers before / after, a dyno share card and leaderboard, a sound preview, a 2-minute test, today's deals, a crate with odds, a fuse and a level-up, a visible part on a new car, a tuning challenge, the dex, copy a build).
- An old save keeps every part and gets fair rolls.
- No console errors; Lune tests and `luau-lsp analyze` clean; FPS fine.
- Screenshots of each new screen; save the place, commit, push; note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- the screenshots;
- the crate odds and the main prices;
- anything left out and why.
