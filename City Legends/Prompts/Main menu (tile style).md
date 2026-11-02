# Prompt: the City Legends main menu (big-tile style)

_For Claude Code with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`)._

## Reference
- `Games/CityLegends/imports/refs/ui/menu_reference_tiles.webp` (owner, 2026-11-02): a big racing game's pause menu. The look:
  - **big bold coloured tiles** in a grid on a soft patterned background;
  - a **top bar** with the current car on the left, the player and money on the right, and **tabs** in the middle (with small number badges for new things);
  - one **big highlighted tile** (the selected one has a bright outline);
  - **key hints** along the bottom (Enter Select, Esc Back...).
- **Make our own version.** Same idea (big tiles, top bar, tabs, key hints), but **our own colours, fonts, icons and art**. Don't copy that game's logo, art, colours or text style exactly, so it doesn't look like a copy. Match City Legends' style (the night city / Riviera look: deep navy and warm gold, with one bright accent colour), and use the game's existing UI kit where it has one.

## Before you start
- Read:
  - `CLAUDE.md`;
  - `Roblox Playbook/Roblox Playbook - Rules for every game.md` (UI = designed art not placeholders; colour = meaning; feedback on every action; first-session rules; store rules);
  - `Games/CityLegends/CLAUDE.md`;
  - `City Legends/City Legends.md`.
- Call `list_roblox_studios` and use the Studio named **City Legends** only. Save a backup first.
- Read the current menu, HUD, garage and minimap code (`src/client/UI.lua`, `Main.client.lua`, `Minimap.lua`) and **reuse** what works. Replace the old menu with this one; don't build a second one next to it.

## How it opens
- **Open / close:** **M** on PC (or Esc if it doesn't clash with Roblox's own menu), a **menu button** top-left on phone, the **Start / Menu** button on gamepad.
- While open, the game keeps running (it's multiplayer). Your car is **braked and held** safely if you're driving; you can't be "busted" just because the menu is open, but the police timer keeps running.
- **First join:** the menu opens straight away as the start screen (see "New player").
- Smooth open / close animation (under 0.3 s), a soft blur behind. Sounds on hover and select.

## Layout
### Top bar
- **Left: the car you're driving.** Show the **car's name** big (the fictional name, e.g. "Enfurecido Aventador SVJ"), its class / tier chip (Starter / Mid / High) and a small colour swatch. **No car picture**: the owner wants the name.
  - Before the player has a car: it shows **CLAIM CAR** (pulsing) and opens the starter car pick.
- **Middle: 3 tabs only: CAMPAIGN · CARS · STORE**, switched with Q / E or the arrows (◀ ▶), shoulder buttons on gamepad, or tapping. A small number badge on a tab when something's new (a new car unlocked, a reward ready).
- **Right:** the player's avatar headshot, name, **level** with an XP bar, and **cash**.

### Bottom
- Key hints that change with the input (keyboard / gamepad / touch): Select, Back, Switch tab, Reset car, Close.

## CAMPAIGN tab (the home tab)
Big tiles, like the reference:
1. **PLAY** (the big highlighted tile, instead of "What's Next"): closes the menu and puts you back driving. If you have no car out, it spawns your selected car at the nearest safe spot. Shows a small "Next goal" line under it (for example "Earn $5,000 for your first upgrade"), taken from the goal ladder.
2. **WORLD MAP** (big tile with a live map picture, plus the time of day and weather icons and the district you're in): opens the full map:
   - the whole Riviera Bay map, with roads, districts and the sea;
   - **venue symbols** (our own simple icons): Legends Motors, Legends Customs, the bank, the 3 towers, the hotel, the casino, the gem showcase, Legends Realty, your house, races, deliveries, police station, the beach, the stadium...
   - **Tap / click a symbol → a card** (name, what you can do there, distance) with **FAST TRAVEL** and **SET WAYPOINT** buttons.
   - **Fast travel:** a short fade, then you and your car are placed at that venue's kerb spot, the area streams in first (pre-load), and you're facing the way in.
     - **Blocked while wanted by the police** (shows "Lose the police first") and during races / heists / deliveries.
     - A short cooldown (about 30 s).
     - The server checks it.
   - **Waypoint:** a GPS line on the minimap and the road.
   - Zoom, drag, a legend to filter symbols, and "You are here".
3. **COLLECTION / ACHIEVEMENTS:** goals and achievements:
   - the goal ladder;
   - achievements with progress bars and rewards (Claim button);
   - the cars collection % ("17 / 79 cars");
   - badges.
4. **SETTINGS:**
   - **Mini map:** on / off, and its spot (top-right by default, owner's choice);
   - **graphics** Low / Medium / High / Ultra;
   - camera shake, head movement, motion blur, chase-camera FOV;
   - units (km/h / mph);
   - music and sound sliders (separate);
   - controls (show keys, steering sensitivity for phone);
   - reduced motion.
   - All saved per player.
5. **EXIT TO DESKTOP** is not needed (Roblox has its own). Instead, a small **DAILY REWARD** tile (streak days, Claim) when one is ready.

## CARS tab
- A big grid of **your cars** (owned), grouped by brand like the garage, with "**X / 79 owned**" at the top.
- Each card: the car's name, tier chip, top speed / 0-60, the paint swatch, ✔ the selected one.
- Select a car → a side panel: stats bars, its trim, paint, and buttons:
  - **SPAWN** (spawns it near you, or swaps your current car; blocked while wanted or in a race);
  - **SET AS FAVOURITE**;
  - **CUSTOMISE** (waypoint to Legends Customs);
  - **SELL / MARKET** (opens the car market).
- A small "**Get more cars**" tile that sets a waypoint to Legends Motors (or opens its buy menu if you're there).
- Sort by brand / price / speed / newest, plus search.

## STORE tab
In-game purchases, following the **Playbook money rules**:
- a few clear items, for example:
  - **VIP** (pass);
  - **2x Cash** (pass);
  - a **Starter Pack** under 400 Robux;
  - cash bundles (developer products);
  - maybe a **garage space** pack.
- Each item: a clear name, the exact effect, the price **read from Roblox** (`MarketplaceService:GetProductInfo`), never typed in.
- Products granted **only in `ProcessReceipt`**, saved before confirming, never twice.
- **No fake sales, no countdowns, no "BUY NOW!"** (calm wording); respect `PolicyService`; no paid random items without shown odds; never sell race wins.
- **Ask the owner for the product and pass IDs and prices.** Until then, show the tiles greyed with "Coming soon".

## New player (first join)
1. The menu opens on the CAMPAIGN tab, with the top-left saying **CLAIM CAR**.
2. Press it (or PLAY): **choose 1 of 3 starter cars**, shown as 3 big cards with name, stats and a one-line feel ("easy and grippy", "fast but loose", "big and comfy"), picked from the Starter tier.
3. Confirm → the car is yours (server-checked, once only) → the menu closes → you're **driving within 15 seconds** of joining (Playbook first-session rule).
4. The first goal shows on the HUD.

## Make it better (extra ideas)
1. **Live 3D car behind the menu:** a slow camera orbit around your actual car in the world while the menu is open (cheap, no extra models).
2. **Badges and dots** on tabs and tiles when something's new (a reward, a car unlocked, an achievement done).
3. **Quick-select wheel** on gamepad / keyboard: hold a key for Spawn car / Despawn / Fast travel home / Waypoint to last venue.
4. **"Continue" chips** on the PLAY tile: your last activity (Resume delivery, Back to race, Go home).
5. **Friends on the map:** your friends' markers, with "Join friend" fast travel (same rules).
6. **Phone first:** tiles at least 44 px tall, thumb-reachable, test at 667 × 375; no tiny text.
7. **Gamepad:** full D-pad / stick navigation with a clear highlight (the bright outline from the reference).

## Rules
- Our own art: drawn icons and tiles, no placeholder buttons, no copied art, **no logos**, fictional names.
- Every action has feedback: a sound, a small animation, and the number or text change.
- The server checks: fast travel, spawn, the claim car, store, and achievements claims (types, rate limits).
- Respect `GuiService.ReducedMotionEnabled`.

## Check before you say done
- Test on PC (mouse + keyboard), gamepad and phone size:
  - open / close;
  - every tab and tile;
  - the claim car on a new save;
  - fast travel to every venue (and blocked when wanted);
  - spawning cars;
  - mini map on / off saved;
  - settings saved;
  - the store greyed until IDs.
- 2 players: fast travel and spawning don't break the other player.
- No console errors. Screenshots of each tab (PC + phone).
- Lune tests and `luau-lsp analyze` clean.
- Save, commit, push, and note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- what's in the menu;
- screenshots;
- the keys to open it;
- what's needed from the owner (store IDs and prices).
