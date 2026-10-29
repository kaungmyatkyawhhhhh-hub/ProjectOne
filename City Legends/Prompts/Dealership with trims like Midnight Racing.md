# Prompt: Legends Motors dealership menu with trims (like Midnight Racing)

_For Claude Code on the PC, with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`)._

## Before you start
- Read:
  - `CLAUDE.md`;
  - `Roblox Playbook/Roblox Playbook - Rules for every game.md`;
  - `Games/CityLegends/CLAUDE.md`;
  - `City Legends/City Legends.md` (car series, levels, the car market, Legends Motors).
- Call `list_roblox_studios` and use the Studio named **City Legends** only. Don't `rojo build` over the baked place. Save a backup first.
- **References** (in `Games/CityLegends/imports/refs/dealership/`):
  - `mr_dealer_menu.webp`: the buy menu from the Roblox game **Midnight Racing**. The owner wants ours **laid out like this**.
  - `car_detail_panel.webp`: a car detail panel from another game, with **trims** and stats. The owner wants these details and the trim chips.
  - The Midnight Racing wiki page: https://robloxmidnightracing.fandom.com/wiki/Dealership. Summary:
    - you walk to the counter and press E to open the menu;
    - car **brands** along the bottom, changed with < >;
    - the car list on the left;
    - performance stats on the right;
    - the car's name, cost, BUY and EXIT along the top;
    - some cars need a minimum level.
- **Rules:**
  - no real brand names or logos;
  - **no emblems**, so brand tiles show our brand name as text (BNW, MERCER, LAMBRINI...), never a badge picture;
  - our own fonts and colours (don't copy Midnight Racing's look exactly);
  - the server checks every purchase and level.

## What the owner wants
1. **The dealership works like Midnight Racing's.** Walk to the counter in Legends Motors and press E (or tap) to open a full-screen menu. The camera moves to a **showroom turntable**, and the selected car appears there in 3D, slowly turning (drag to spin, scroll to zoom).
2. **Layout** (like `mr_dealer_menu.webp`, in our style):
   - **Top bar:** EXIT (left), the car name + year and **COST** (middle), **BUY** (right; greyed with the reason when locked).
   - **Left: "Vehicles" list** of the selected brand's cars, scrolling with up / down arrows. Each row: a small photo, the name, the price, and tags ("★ Bodykits" if it has customs parts, "◉ Trims" if it has trims).
   - **Bottom: brand bar** with < > arrows, one tile per brand (our names as text, in our style).
   - **Right: stats bars:**
     - **Max speed** (km/h and mph);
     - **Power-to-weight**;
     - **Braking**;
     - **Weight**;
     - **Drive** (RWD / AWD / FWD).
     Bars are filled against the best car in the game, with the number at the end.
   - **Middle, above the car:** the **Trim selector**: "Trim  <  NAME  >".
   - **Bottom left:** the player's **level** badge and XP bar ("Your Level").
3. **Each car has trims, from worst to best** (like `car_detail_panel.webp`):
   - Use our existing **series** in `Cars.Series` as the trim ladders, for example:
     - "BNW 5 SERIES": 530i → 540i → M5 E60 → M5 F10 → M5 F90;
     - "LAMBRINI": LP570 → LP640 → LP700 → LP750.
   - Split series that mix different cars into the right car + trims where it makes sense (for example the 3 & 4 Series: 330i → M3 E92 → M3 F80 → M4). **Show the owner the full car → trims list before changing it.**
   - **Most trims need a level:**
     - the base trim is open (or the car's own level);
     - each better trim needs more levels (now 5 per step, `Cars.LevelsPerTrim`);
     - locked trims show a 🔒 with "Level 15", and BUY says "Reach level 15".
   - **Trim detail panel** (right side, under or instead of the bars; like the second picture, in our style):
     - **Power** (hp), **Torque**, **Weight**, **Seats**;
     - **Vehicle colour** swatches (pick before buying) and **Interior colour**;
     - **Trims** as chips (Base / Turbo / ...) with the selected one highlighted;
     - a one-line **description** (fictional, no brand names);
     - **feature icons:** ABS, drive (RWD / AWD), fuel / octane, gearbox (M / A), MPG, and **Sound** (our own simple icons).
   - Pick a trim and a colour, then BUY. The car arrives in the garage in that colour (the colour is saved like a Customs paint).
4. **Buying:**
   - a confirm pop-up ("Buy the BNW M5 F10 for $1,250,000?");
   - the server checks money, level and that the car isn't already owned;
   - one purchase per click, so spam clicking can't charge twice (Midnight Racing's bug).
   - On success: a short celebration (sound + confetti + "NEW CAR"), and a **"Drive it now"** button that spawns it outside.
5. **Showroom:** the turntable has spotlights and a polished floor; the car turns slowly. The other cars on show in the building stay as they are (`Config.Dealership.Display`).

## Owner's decisions (2026-10-29)
- **The car market rule changes (owner chose B):** cars from $600K up (`Cars.MarketFromPrice`, F430 and above) are **no longer market-only**. Every car and trim can be **bought at the dealer once you reach its level**:
  - top cars and top trims need high levels;
  - suggest a level ladder that puts the most expensive cars around levels 40–60, and show the owner before setting it.
  - **The car market stays** as a second way to get cars (buying and selling between the market's listings, flips, deals). It just isn't the only way any more.
  - Update `Cars.isMarketOnly`, everything that uses it, the Market, the garage text, the `market_test`, and the notes.
- **Owning the previous trim first:** not needed. **Levels only**, unless the owner says otherwise.

## Our ideas to make it better
1. **Compare:** hold a button to compare the selected trim with the car you're driving (green / red arrows on each stat).
2. **Test drive:** a 60-second test drive of any unlocked trim on a short route round the block, then back to the menu.
3. **"Next unlock" hint:** under the level badge, "Next: M5 F90 at level 25".
4. **Owned tag:** owned cars and trims show ✔ OWNED and a **DRIVE** button instead of BUY.
5. **Sort and search:** sort by price / speed / level, and search by name.
6. **Phone first:** big buttons (44 px or more), swipe left / right on the car to change trim, and swipe the brand bar. Test at 667x375.
7. **Sound:** the engine revs once when you switch trims (from the car's own sound).
8. **Wishlist ★:** star a car, and the HUD shows how much more money you need.

## Check before you say done
- 2-player test in Studio:
  - open the menu, switch brands, cars and trims;
  - a locked trim can't be bought, and the server refuses it even if forced;
  - buy, spam click, and get only one charge;
  - colour saved;
  - drive it now.
- No console errors.
- Screenshots: PC and phone size, next to the two references.
- Every Lune test passes (`market_test` too). `luau-lsp analyze` is clean.
- Write the changes into `City Legends/City Legends.md` and `Games/CityLegends/CLAUDE.md`. Commit, push and save the place.

## When done, tell the owner (short)
- the car → trims list with the level for each;
- how the menu works;
- what's untested;
- the new level for every car and trim (top cars now at the dealer).
