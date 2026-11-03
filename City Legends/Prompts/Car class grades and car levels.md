# Prompt: car class grades (D to X) and car levels, instead of player-level locks

_For Claude Code with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras: where something below isn't decided, **ask the owner**._

## What the owner wants (2026-11-03)
Reference: `Games/CityLegends/imports/refs/ui/car_class_grades.png` (a racing game's class table) plus these rules from that game:
1. **Every car gets a class grade from a Performance Index (PI) number**, shown like the racing games: **D, C, B, A, S1, S2, R, X**. The reference's ranges are: D 301–400, C 401–500, B 501–600, A 601–700, S1 and S2 (no range shown), R 801–900, X 999.
   - **Suggested full ranges** (show the owner and let them change them, in `Config`): **D 100–400, C 401–500, B 501–600, A 601–700, S1 701–750, S2 751–800, R 801–900, X 901–999.**
2. **Car levels:** each car you own has its **own level, up to 50**, earned by driving that car (distance, cut-ups, races, drifts, challenges).
3. **Upgrades and parts:** all parts can be installed from car level 1, in any order (nothing locked behind the car's level).
4. **Car Points (CP):** you earn Car Points as the car levels up, and spend **CP or cash (Credits)** to buy parts for that car.
5. **Brand discounts:** maxing a car to level 50 gives **5% off that brand's cars** at the dealer, stacking up to **25%** when you max 5 cars of the same brand.
6. **Fast levelling:** a car can go from level 1 to 50 in roughly **2.5–3 hours** of driving.
7. **"Instead of levels":** the class grade replaces the **player-level locks** on cars in the dealer.

## Before you start
- Read:
  - `CLAUDE.md`;
  - `Roblox Playbook/Roblox Playbook - Rules for every game.md` (money and progression rules);
  - `Games/CityLegends/CLAUDE.md`;
  - `City Legends/City Legends.md`;
  - `City Legends/Research - Driving games.md`.
- Read how it works now:
  - `Cars.lua` (player-level unlocks per car, the extra SPORT / TOP trims, series ladders);
  - `CarStats.lua` (power, torque, weight, made-up stats);
  - `Brands.lua` (brand XP / levels and their perks);
  - `Goals.lua` (goals like "reach level N");
  - `Customs.lua` (looks);
  - `DealerMenu.lua`, `MainMenu.lua` (CARS tab), `PlayerData.lua`.

## Questions to ask the owner first (don't guess)
1. **Without player-level locks, what stops a new player buying a top car?** Only its price? Or should some classes still need something (e.g. S2 / R / X need a player level, or owning a car of the class below)?
2. **Does the player level stay** (for XP, rewards and goals), just without locking cars?
3. **Brand levels:** the game already has brand levels with perks (`Brands.lua`). Should the new "max 5 cars = 25% off" **replace** them or sit next to them?
4. **Which parts** exist to spend CP / cash on? (The game has looks at Legends Customs; performance parts like engine / turbo / tyres / weight / brakes / suspension don't exist yet.) If performance parts are wanted, they raise the car's PI and can move it up a class. Confirm before building them.
5. The exact class ranges (the suggested ones above, or others).

## Then build
1. **PI per car:** work out each car's PI (100–999) from its real performance (power-to-weight, top speed, 0–60, grip / handling, braking), so the classes feel right (e.g. a starter hatch is D, the M5 F90 around A, the SVJ R, the Chiron Super Sport X). Put the formula and every car's PI in a table for the owner. Store PI in `Cars` / `CarStats`; the class letter comes from `Config` ranges.
2. **Show the class everywhere:** a coloured badge with the letter and PI ("A 645") in the dealer menu, the garage / CARS tab, the car market, the HUD while driving, and race lobbies. Use the class colours (our own colours, same idea as the reference: D / C / B / A / S1 / S2 / R / X).
3. **Car levels (1–50):** per owned car, saved in `PlayerData` (`CarLevels`, `CarXP`, `CarCP`). XP from driving that car. The curve tuned so 1 → 50 takes about 2.5–3 hours. A level-up pop-up with the CP earned.
4. **Car Points and parts:** as answered by the owner (question 4). Parts installable from level 1, any order. Paid with CP or cash. The server checks every purchase and saves before confirming.
5. **Brand discounts:** level-50 cars per brand → 5% each, up to 25% (5 cars). Shown on the dealer's price ("−15% brand bonus"). The server applies it.
6. **Dealer:** replace the "Level N" lock with the class badge (and whatever the owner answers to question 1). Update the "next unlock" box, goals that mention car levels, and the store's Starter Pack if it mentions levels.
7. **Races:** race lobbies can be limited by class (e.g. "A class race") later. Only add this if the owner asks.

## Rules
- Old saves keep working: players keep every car they own; nothing gets locked away from them.
- All numbers (ranges, the XP curve, CP per level, part prices, discount %) in `Config` with comments.
- The server checks: XP gain (no cheating with speed hacks; reuse the existing checks), CP spending, discounts, purchases.
- No paid random items; no Robux for performance (Playbook: never sell race wins).

## Check before you say done
- Every car has a PI and class; the table is shown to the owner.
- Dealer, garage, market and HUD show the class badge (PC and phone screenshots).
- Drive a car: car XP rises, level-up gives CP; a part can be bought with CP or cash; level 50 gives the brand discount; 5 maxed cars cap at 25%.
- An old save still has all its cars.
- No console errors; Lune tests and `luau-lsp analyze` clean.
- Commit, push, save the place; note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- the class table and each car's class;
- how car levels, CP and discounts work;
- screenshots;
- anything still waiting on the owner's answers.
