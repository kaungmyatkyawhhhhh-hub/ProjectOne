---
date: 2026-11-01
tags: [research, competitor, incremental, playlog, celestial, supernova]
---
# Regrowth Incremental - play log + how to play it (for Supernova Incremental research)

Owner (1 Nov night): "play regrowth incremental for 2 hours" + "document all these in obsidian so next time u can learn how to play this roblox game more ... we need the document for our game ... we're playing this game to research to make our game better".
Account: HEINHEIN1922 (owner bought the 27 R$ alpha access). Version shown bottom-left: ALPHA 0.8.4. Stats: [[2026-11-01 Research - Regrowth Incremental (paid access)]].

## HOW TO PLAY (tested 1 Nov 22:16+, session 2; rewritten from what actually worked)
**The tool:** `C:\Users\kaung\.claude\skills\play-roblox\rbx.exe` (our own, built 1 Nov: see skill `play-roblox`). It focuses the Roblox window by itself, sends real keys (scan codes, holds), real mouse (clicks, right-drag camera, wheel) and screenshots ONLY the game. Chain actions in one call with `;`:
`rbx.exe "key w 600; wait 300; shot <path>.png 1280"`. Click coordinates = pixels of the LAST screenshot (the tool maps them to the screen).

What works (tested):
- **Walk:** `key w 600` = hold W 0.6 s. Works first try (the old session's trouble was the input method, not the game). Use 0.4-0.9 s bursts, screenshot, repeat.
- **Buy a tycoon pad: LEFT-CLICK the glowing round pad.** Works from a few studs away; you don't need to stand on it. Each buy builds a piece instantly.
- **Zoom out:** `move 640 380; scroll -6` (wheel down = zoom out). Do this first: you see the whole plot and the floating pad labels.
- **Turn the camera:** `turn 300 0 400` = hold the right button and drag 300 px right over 0.4 s: ~90 degrees. Negative = left. Put the mouse on an empty spot first (`move 900 420`).
- **Read small labels:** `zoom X Y W H <path>` crops that part of the last shot at full detail (pad names/prices are tiny at 1280 px).
- **Keys:** E = STORE (Robux passes). T = TELEPORT (worlds). G = GUIDE BOOK (every feature explained). Close a window with its red X (top right of the window). Scroll a window's list with the wheel over it.
- **Combos:** `key w+a 650` holds W and A together (diagonal). `down w; wait 150; key space 200; wait 700; up w` = run and jump (jump is low: can't clear the big pipe; walk round it).
- **THE MACHINES BOARD is a 3D screen in the world, clicked like a phone screen:** walk to it, face it (it's on the terminal by the plot's platform; from the pad side you only see its dark back), then click the buttons ON the board (UNLOCK / UPGRADE). It took me ~15 tries to find this: the black arrow points AT THE BOARD, not at the pads next to it.
- **Floating labels can sit in front of the board's buttons** and catch the click: move so they don't overlap.
- **Hide Extra Text** (blue, under the tutorial card) shrinks the card to just the goal line + an "Open Info" button: do it first, the card covers half the screen.
- **The camera squashes in close when a wall is behind you** (between the pipe and the terminal): step back into the open (`key s 900`) and zoom out.
- **Camera with ARROW KEYS (owner's tip, tested):** `key left 400` turns the camera ~110 degrees left, `key right 400` back. Easier than right-drag. Short taps (100-150 ms) for small turns.
- **Q = SETTINGS** (tabs GAMEPLAY / HUD / STATS / MULTIS), **R = RUNES**.
- **Machine board buttons (per machine row):** blue UPGRADE (+1 level), purple "+MACHINE" (buys an extra copy: "2x" shows top right of the row and a new machine model appears on the plot), and a locked row's purple UNLOCK.
- **Click many upgrades in one call:** `click X Y; wait 350` repeated (12 upgrades in one go worked).
- **W walks where the CAMERA looks** (Roblox default): turn the camera with the arrow keys first, then W. A/D strafe left/right of the camera. Easiest way to reach a board: turn until it's in front, then W in 0.5-1 s bursts.
- **Lost / boxed in (fenced walkway, corner)? T -> FACTORY "Enter World"** teleports you to your plot's spawn ("Main Island" title flashes). The spawn is right by the platform and the boards.
- **Read a board:** stand ~8 studs in front of it, point the mouse at it and `scroll 5` (zoom in), then `zoom` the screenshot on it.
- **Inside the glass hall the camera can't zoom out far** (the roof blocks it) and gets jammed against walls/pipes: if the view goes weird, `key s 600` + arrow keys, or T -> Factory.
- **Walking up ramps:** buildings bought from pads (the Factory Entrance) have ramps you walk up by accident; pads on roofs are reached that way.
- **Not yet tested:** the $ / padlocked buttons top right, the "+" bottom left, the buy-amount "M"/"1x" toggle between the buttons.
- The **black chevron arrow** on the ground points from you to the tutorial's target. Turn the camera until it points straight up the screen, then W.
- The Mem/CPU/GPU bar at the top is Roblox's own stats overlay (on in this account), not the game's UI.

## FIRST MINUTES (what the game does)
- Spawn: you land on your plot (dark rocky land, a giant purple glowing crystal = the "singularity rock"). Above your head: title "Guest", name, and a plate with your Energy (purple, 500 at start) and a white diamond count (1).
- Tutorial: bottom-centre card with an NPC portrait ("utter38"), text, a progress bar and "x/26" steps, red "Skip Tutorial (Not Recommended)" + "Hide Extra Text". Step 1: "Welcome, Let's buy some Tycoon Buttons to unlock your very first Feature. [complete for 25 Eternal Shards]" with "0 / 4 Tycoon Buttons 0%". Every tutorial step pays premium currency (Eternal Shards).
- A huge black chevron beam on the ground from you to the target (very visible).
- Tycoon pads: Build Foundation (25 Energy) -> a stone foundation with stairs appears; Add Frames (50) -> wooden frame/fence; Install Pipes (next). So the first "feature" is BUILT in front of you piece by piece (tycoon style) - instant visible progress.
- Leaderboard (top right, Roblox list): columns STAGE? and ENERGY with huge numbers (3.3SpQg, 960.8QoQg) - shows how far veterans got (aspiration).
- Top right HUD: $ button + 2 locked buttons; energy "500 +0/s" readout.
- Game page: "625+ upgrades, 6 major chapters, 75+ currencies", Alpha access = exclusive rewards at release + "your feedback matters". Store: Every Gamepass 3K, Factory Master 135, Rune Hunter 540, Life Master 203, Dungeon Hunter 405, 2x Perks 342 (hints at features: factory, runes, life, dungeons, perks).

## OBSERVATIONS FOR SUPERNOVA INCREMENTAL (so far)
- Tycoon-building start: progress you SEE being built around you in the first 30 s (vs our numbers on a panel) -> our bodies flying into orbit must feel the same.
- Tutorial pays premium currency per step (25 Eternal Shards) -> rewarding the tutorial.
- The guide beam is huge and impossible to miss (like Noob / Tower).
- Number scale on the leaderboard (SpQg) = shows the long road.

## PLAY LOG - session 2 (1 Nov, 22:16 start; HEINHEIN1922, ALPHA 0.8.4)
(Times are the real clock. My first draft guessed the minutes from my own pace and over-counted; corrected at 22:37 = 21 minutes in. Everything below happened in those 21 minutes: the game moves FAST.)
**Block 1 (22:16-~22:19, real clock)**
- Start: 425 Energy, tutorial 1/26 "Welcome, Let's buy some Tycoon Buttons to unlock your very first Feature" (25 Eternal Shards), 2/4 pads done from session 1.
- W 0.6 s walked me next to a **red pad "Install Pipes" (75)**. Left-click: purple pipes appeared on the platform (425 -> 350). 3/4.
- A **blue pad** lit up with the black arrow on it; click: 4/4 (350 -> 253). Tutorial **2/26: "Great, Now let's unlock your first Machine, Machines are your primary Energy."** "0 / 1 Machines Unlocked".
- Energy started RISING by itself after the 4th pad (a "+3/s" bar floats over the pipe; 253 -> 532 over ~3 min). The first "feature" = the pipe line feeding energy from the crystal.
- Zoomed out: the next pads stand by a big dark screen/terminal: **"Machine Upgrades" 27.2K** (blue pad) and **"Empty floor" 500** (red pad). So the first Machine needs 500 Energy.
- **STORE (E):** dark-red window, title bar with TOKENS (0) + ETERNAL (0) counters, left tabs PACKS / POTIONS / ETERNAL / GIFT. Passes with crossed-out "was" prices:
  - ALL GAMEPASSES 3,299 R$ (was 4,750): all passes, 10% off, 62.5% off future passes, +400 Eternal Shards; "for any pass already bought, you get Eternal Shards".
  - FACTORY MASTER 149 (was 199). CRYSTAL PACK 225 (was 299). BARN MASTER 379 (was 499). LIFE MASTER 225 (was 299). SUPER TREES 259 (was 349). MONEY BOOST 399 (was 549). SUPER MINER 379 (was 499: 3x DMG, 3x FORGE, 2x). RUNE HUNTER 549 (was 749). 2x PERKS 379 (was 499).
  - Each pass = a grid of multipliers (3x / 2.5x / 2x / 1.6x...) for one later feature (factory, crystals, barn, life, trees, money, mining/forge, runes, perks): the store doubles as a MAP of every future feature.
  - Prices differ from the game page (Factory Master 135 there, 149 here): regional pricing or a change.
- Feel: the start is fast and readable (every click builds something). The STORE is one key (E) away, with "was" prices; the tutorial card stays on top of the store and covers the passes.
Screenshots: `01 start - tutorial 1 of 26.png`, `02 plot after 4 tycoon pads.png`, `03 store - packs tab.png`, `04 store - passes 2.png`, `05 store - passes 3.png`.

**Block 2 (~22:19-~22:25): stuck on the first Machine, then found the board**
- The "Empty Floor" pad (500, cyan = affordable) did NOT buy when clicked, walked onto, or long-clicked (8 tries). The tutorial arrow actually points to the terminal = the **MACHINES BOARD**. From the front it shows rows: "BASIC EXTRACTOR: LOCKED, BUY TO UNLOCK IT" (purple UNLOCK button), "FAST EXTRACTOR: LOCKED ???". Clicking UNLOCK on the board: **Basic Extractor Level 0, Tier 1, Basic, +3/s**, buttons UPGRADE and a second one. Tutorial: **"0 / 15 Machine Levels"**.
- The Empty Floor pad is probably a later tycoon piece (needs something first); not solved yet.
- **Confusing for a new player (lesson):** the board's back faces the pads, the floating pad labels cover its buttons, and the arrow ends on a spot where two pads also sit. I found it via the GUIDE BOOK text.
- **T = TELEPORT window** (blue frame, swirl icon): FACTORY "Starter Place" [Enter World], then padlocked worlds with their unlock rule: UNLOCK CRYSTALS, UNLOCK AUTOMATION, REACH STAGE 2, UNLOCK RESEARCH, UNLOCK LOGS, (a farm-like world), UNLOCK GEM BARN, REACH STAGE 5 (x2), REACH STAGE 6, + one more. About 13 worlds, each row tinted its own colour. Locked rows still show the world's name faintly behind the padlock (a tease).
- **G = GUIDE BOOK** (blue window, gold-star book icon): left column of diamond feature icons: TYCOON, ENERGY, LEVELS, CRYSTALS, JEWELS, PLATINUM, STAGE, RUNES; second column FACTORY, LIFE, TREE, BARN, MINING, DUNGEON. Each page = icon + name + subtitle ("ENERGY - MAIN CURRENCY", "TYCOON - BUILD TO UNLOCK") + plain text + a screenshot of the feature.
  - Tycoon page: "Factory is one of the core features of Regrowth Inc, you will continue to progress the Factory through out nearly the entire game. Factory is the first feature of the game, you progress the tycoon buttons using the starter energy you had when you joined, once you have unlocked the MACHINES board you can proceed to the Energy page."
  - Energy page: "Energy is the main currency of Regrowth Incremental, everything you do in the game is mostly aimed to increase your energy gain. Energy is also the main currency used for Stage ups. Energy gain is based on machines, once you purchased the machine board you automatically unlocked your first machine which began producing Energy. In order to progress and earn more energy, you upgrade your existing machines and purchase new machines as well as factory upgrades. **Every 10 machine upgrades your machine will tier up which boosts the energy gain of that machine by 1.5x.**"
  - Its picture of a late board: BASIC EXTRACTOR LEVEL 125 TIER 13 +134.6Qd/s [MAXED][MAXED], FAST EXTRACTOR LEVEL 125 +13.4QN/s, and a "5x" buy multiplier per row.
- Energy over time: 425 at 22:16 -> 1.95K by ~22:25 with only the pipe's +3/s (no machine yet). The old regulars' energy on the leaderboard keeps ticking up live (5.5SpQg).
Screenshots 06-16 (plot from above, teleport x4, guide book x4, machines board locked / unlocked).

**Block 3 (~22:25-~22:28): the machine loop**
- **Basic Extractor** upgrades: Lv0 +3/s -> Lv3 +7.5/s (next 13) -> Lv15 **Tier 2 "WOODEN"** +43.35/s (next 420) -> Lv18 +51/s (~700) -> Lv21 **Tier 3 "STONE"** +99.7/s (next 1.42K). A red bar under the tier fills toward the next tier; a tier-up roughly doubles the rate. Tier names = materials (Basic, Wooden, Stone...).
- Tutorial: 3/26 "0/15 Machine Levels" -> "1/2 Machine Tier" -> step **4/26: "You can also buy Extra Machines of that specific Machine, doing so grants an extra Generator of that type to gain even more Energy."** Bought the purple +MACHINE (~4.x... cost): the row shows **2x**, a 2nd extractor model APPEARS on the plot, rate +99.7 -> +199/s.
- Next goal "1/2 Machines Unlocked": **FAST EXTRACTOR** unlocked from its row: Lv0 Tier1 Basic **+200/s** (UPGRADE 2.5K, +MACHINE ~2.4K). Then **"0 / 6 Tycoon Buttons"**: back to the pads.
- Energy: 1.95K -> 5.52K in ~3 minutes while spending on ~25 upgrades.
- **R = RUNES** (purple window): families ENERGETIC (1M), SKY, RICHES, EARTH, ADVANCED, BONES (each a coloured tab with an icon); a LIST of rarities with owned counts: BASIC, CHARGED, VOLTIC, SPECIAL, HEXA, DARK...; INFO "BASIC [x0] 56%" (the odds are SHOWN, as Roblox requires), "1x". So runes = a paid-with-Energy gacha (1M per open).
- **Q = SETTINGS** (grey brushed-metal title bar): GAMEPLAY: Private Server [JOIN PRIVATE], Highlight Buyable Tycoon Buttons (ON), Hide Maxed Upgrades (OFF), Toggle Player Visibility... STATS (coloured tiles): Time Played 27m57s, Session Played, Time Since Last Major Reset, Upgrades Unlocked 3, Total Upgrade Levels 15, Robux Spent 0, Robux Gifted, Got Gifted, Total Eternal Shards 0, Total Runes Opened, Lowest Depth 0 (dungeon/mining?), Rune Luck 1, Rune Bulk 1, Runes Opened. MULTIS: empty so far.
- **Feel:** the machine loop is satisfying: every few clicks the number per second jumps, a tier-up doubles it, and a new machine model pops onto the plot. The board in the world is clever (diegetic) but hard to read: small text, labels in front, and you have to stand at the right angle.
Screenshots 17-21 (runes, settings x2, extra machine, fast extractor).

**Block 4 (~22:28-~22:31): 6 more tycoon pads, then LEVELS + the PERKS TREE**
- "Empty Floor" (500) bought with ONE click once the Machines board was owned: so pads light up (cyan / green = buyable now, red = locked / too dear) in a chain, and a pad only works when it's lit. That's why it failed earlier.
- 6 pads in ~1 minute, each changing the plot: a sand floor, a curved white wall, tiled floor everywhere, stone arches, a 2nd pipe line from the platform to the arches, then the arch room's boards. "x/6 Tycoon Buttons" with a % bar.
- **LEVELS unlocked (tutorial 8/26): "Nice, You Gain xp /s and they can be spent on this upgrade Tree. Let's buy 2 levels of the More Energy Upgrade."**
  - New HUD: top bar grows: a blue star "LVL 3" on the left of the name badge and a blue XP-crystal counter "2.06 (+1.11/s)" on the right; a small XP bar bottom-right "1.62/10 ★1" (level progress) with a magnifier icon.
  - In the arch room two big world boards: **PERKS TREE** (a node graph: icons in rounded squares with a "1x" and a blue-crystal cost; locked nodes are black silhouettes) and **INFO** (the selected node: "ENERGY Level 0 / Tier 0, 1x, +0.1x", "TIER 0 [NO TIER]", "0/10", a big purple UPGRADE button with "10x" and the cost "1" blue crystal).
  - Energy perk Lv2 = 1.2x energy (1 XP crystal each). The next node (purple crystal, 2 XP) appeared after; a green gem node (10 XP) shows below. Same "10 levels = a tier" pattern as the machines.
- Tutorial 9: "0 / 4 Machine Level" (back to the board).
- Energy: 5.5K -> 36K in ~3 minutes.

**Block 5 (~22:31-22:37): lost on the plot, then Factory Upgrades**
- Spent ~4 minutes walking in circles: W moves where the camera looks, and the camera follows the character, so turning with the arrow keys + W is the way (see HOW TO PLAY). The new pipe line adds a fenced walkway that boxed me in. Fixed with T -> Factory -> Enter World (back to spawn). **Lesson for us: a big plot + a camera that swings + boards that only read from one side = new players get lost. Our Supernova screens are 2D panels, keep them that way.**
- The plot keeps growing while idle: energy 36K -> 149K in those ~5 minutes (~+1K/s with the 2nd machine).
- **Fast Extractor** Lv0 -> Lv6 (+200/s -> +800/s; upgrade ~2.5K... 25.5K).
- Tycoon pads: **"Machine Upgrades" 27.5K + "Concrete Floor" 50K**: the floor turns to smooth concrete and a 2nd world board appears: **FACTORY UPGRADES** with **FURNACE** (gold star "1", 1x) and **PIPES** (star 1, 1x) and their UPGRADE buttons (~10K and ~1M), plus pads **"Marble Floor" 1M** and a yellow **"Factory Path" 300K**.
- Tutorial: "0/1 Furnace Level" -> **"21/40 Machine Levels"** (31/40 now).
- **UI feedback:** a red banner with a warning triangle "NOT ENOUGH ENERGY" at the top centre when you click something you can't afford.
- Other players walk through your plot (it's a shared server map: you see their plots' boards on the horizon and them standing next to yours). The leaderboard re-sorts live.
- XP: LVL 3 -> 8; the level bar bottom-right 9.87/146 ★8 (each level needs more XP: 10, 28, 42, 59, 82, 111, 146...). Blue XP crystals 6.18.

**Block 6 (22:37-22:44): 40 machine levels, perks, Factory Path, Marble Floor**
- 40/40 machine levels: **Basic Extractor Lv40 Tier 5 "IRON" +1.05K/s** (tiers so far: Basic, Wooden, Stone, (4?), Iron); **Fast Extractor Lv17 Tier 2 Wooden +3.23K/s** (next level 338K: costs grow ~x1.15 a level).
- Perks: Energy perk Lv8 = **1.8x** (+0.1x a level, 1 XP crystal each, 10 levels = a tier). XP crystals come at +1.52/s.
- Tutorial: "2/8 Energy Levels" -> "0/7 Tycoon Buttons". Pads: **Factory Path 300K** (a stone path winds over the floor), another (2/7), **Path Lights 1.5M with a "BONUS ★ 1.2x" tag** (some pads also give a boost). **Marble Floor 1M** = shiny reflective marble floor, but it doesn't count toward the 7 (an optional / cosmetic pad).
- **FACTORY UPGRADES** close up: FURNACE "BETTER FURNACE INCREASES ENERGY" 1.26x (+0.32x a level), next 100K. PIPES: 15K -> 6M after 3 buys (very steep).
- The Machines board scrolls to show what's next: **SUPER EXTRACTOR** and **MEGA EXTRACTOR** (LOCKED, "???") under a 3rd locked one. Teasing the next machines on the same board.
- Energy: 43K -> 1.74M in ~4 minutes. Level 12. Leaderboard: GalaxyPhoenix passed 1SpTg (others keep growing while you watch).

**Block 7 (22:44-22:50): the factory walls go up**
- Pads: Path Lights 1.5M (glowing light strips along the path), another 2.x M pad, then **steel frame pillars rise around the whole factory** (5/7). Next: **"Factory Entrance" 12.5M (with a ★ BONUS tag)** + 2 cyan pads. The remaining pads cost 4-8x my energy: the first wait of the game (~2-3 minutes of idling). This is where Regrowth starts to slow down.
- **Overview from above** (screenshot 33): in 30 minutes the empty rock became a marble-floored factory with a lit path, 2 pipe lines, the crystal, 3 world boards and an arch. That "my place grew" feeling is the main hook.
- The $ button (top right) shows a label "DEFAULT" (looks like a number-format / currency switch). The two padlocked buttons next to it are still locked.
- A gift box sits off the plot (bottom-left) and "REWARDS" signs stand around the plot: a daily-reward / free-gift spot to check.
- Energy 2.9M at 22:50, +~5.5K/s.

**Block 8 (22:50-22:57): the first wall, the glass hall**
- Tutorial **14/26: "Nice, now grind some more and once you feel as if you gain enough then start buying these buttons to unlock your first inc feature."** = the game openly says "grind now". ~35 min in (both sessions), the first real wait.
- Bought with idle energy (~30K/s): frame **beams** (the steel posts become a cage), **glass windows** all round (you're now INSIDE a glass factory hall: the biggest visual moment so far), **Factory Entrance 12.5M** (a glass entrance building). Still 5/7: these are optional pads; the 2 counted ones are dearer.
- Waits: 2.4M -> 12.5M took ~4 minutes of idling. I spent it on optional pads and documenting.
- XP: level 16 (bar 701/909).
- Leaderboard: GalaxyPhoenix jumped from SpTg to OcTg (huge numbers rising live). A new player "Theee18" (stage 1, 34T) joined: new players and veterans share the server.
- **Feel:** fun up to here: something new every ~30 s. From 35 min the gaps grow to minutes; the game fills them with optional cosmetic pads (floors, lights, glass) so there's still a click to make.

**Block 9 (22:57-23:03): income upgrades**
- FURNACE ★2 -> ★4: 1.26x -> **1.98x** (+0.32x a level, ~100K-1M each). PIPES ★3 1.5x (+0.25x), next 6M ("Better pipes system will improve the energy").
- Pads now cost 12.5M-75M ("Outside Path 75M ★1.2x"). Two cyan roof pads couldn't be bought from far away (or were too dear). The next real goal (2 counted pads) needs more income: machine levels + furnace.
- Energy 3-8M, +~40K/s. Level 17.

**Paused at 23:00 (44 min of real play this session)**: tutorial 14/26, 5/7 tycoon buttons, Level 17, ~9.7M Energy, +~40K/s, 2 machines (Basic Lv40 Iron, Fast Lv17 Wooden), Furnace 1.98x, Pipes 1.5x, Energy perk 1.8x. The next counted pads need far more energy: Regrowth's first real grind wall, about 35-45 minutes into a new account.

## LESSONS FOR SUPERNOVA INCREMENTAL (from 44 minutes; most important first)
**Copy**
1. **Build the player's place in front of them.** Every pad adds something you SEE (floor, pipes, arches, glass hall, entrance). In 30 minutes an empty rock became a glass factory. That "my place grew" feeling is Regrowth's strongest hook; our asteroid / star should visibly grow with every buy.
2. **A new thing every ~30 seconds for the first 30 minutes**: pads, machines, tier-ups, a new board, a new currency (XP crystals), a new tree. Pacing was excellent until ~35 min.
3. **Clear numbers on everything**: "+99.7/s", "1.26x (+0.32x)", "21/40 Machine Levels 52%", costs on every button, a red "NOT ENOUGH ENERGY" banner. You always know what a buy does.
4. **Tiers every 10 levels with a big jump** (rate roughly doubles; tier names = materials: Basic, Wooden, Stone, Iron). A small goal inside every upgrade row.
5. **Tease what's next on the same screen**: locked rows "SUPER EXTRACTOR / MEGA EXTRACTOR ???", locked worlds in Teleport ("Reach Stage 5"), the store passes as a map of future features.
6. **The tutorial pays premium currency per step** (25 Eternal Shards) and has a step counter "14/26" and a % bar for each goal.
7. **A guide book (G)** that explains every feature with a picture: great for players who got lost.

**Avoid**
1. **3D boards you must walk to and face** (Machines, Factory Upgrades, Perks): small text, labels in front of buttons, only readable from one side. I lost ~10 minutes. **Our menus stay 2D panels.**
2. **A guide arrow that ends where several things overlap**, and pads that stay "lit" but can't be bought yet (Empty Floor looked buyable, needed the board first). Make the next action unmistakable.
3. **A camera that jams against walls** inside a big plot + a fenced walkway that traps you. If we have a 3D space, keep it open and small.
4. **The tutorial saying "now grind some more"** at step 14: a wall in the first hour with no new toy. Fill it (an idle reward, a first gacha, a mini-event).
5. **The store one key away (E) next to the tutorial card**, with crossed-out "was" prices that never change (Roblox may treat a permanent "was" price as a fake sale). Our store opens later and shows honest prices.
6. **Huge veteran numbers on the leaderboard from minute 1** (SpQg vs your 500): aspiration for some, discouraging for others; show "players near you" too.

**We already do better / should**
- Our first 3 minutes: no walking needed, everything on one screen.
- Honest offers, no fake discounts, odds shown before paid random items (Regrowth does show rune odds: keep doing that).
- Fill Regrowth's 35-minute wall with something new to do (our first Supernova / layer should land around there).

**Not yet seen (next session):** Crystals, Automation, Stage 2, Research, Logs, Gem Barn, Runes (1M per open), Mining, Dungeon, Life, Trees: the 6 chapters. Music and sound effects (screenshots only, can't hear).


## EVERYTHING IN THE GAME: UI, VFX, SFX (owner, 1 Nov: "document the sfx and vfx and ui, like EVERYTHING")
### UI (what it looks like)
- **Style:** dark charcoal panels, chunky italic white sans-serif headings with a black outline, diamond / rhombus frames everywhere (portraits, bottom-bar buttons, top name badge). Colour = meaning: purple = Energy, white diamond = gems, gold = Tokens / gold passes, purple crystal = Eternal Shards, red = store / not affordable, blue = affordable / next.
- **Top centre:** a diamond badge with your avatar headshot + your name; under it your Energy and "+/s".
- **Over your head:** "Guest" title, @name, a black plate with Energy (purple flame icon) and gems (white diamond).
- **Top right:** $ button + 2 padlocked buttons; Energy readout "425 +0/s" with the purple flame icon. The Roblox player list is restyled: PLAYERS / STAGE / ENERGY / LVL columns with huge numbers (4.5SpQg).
- **Bottom centre:** 5 diamond buttons with key letters above them: T (blue arrows/cards), E (red basket = STORE), Q (silver gears = settings), G (blue book with gold star), R (purple crystal). A red label "STORE" appears under E when its window is open.
- **Tutorial card (bottom centre):** diamond NPC portrait (utter38, a dark robed figure with purple glow), name, step "2/26", text, a segmented progress bar + "0 / 1 Machines Unlocked 0%", buttons Skip Tutorial (red, "Not Recommended" with a warning triangle) and Hide Extra Text (blue).
- **Tycoon pads:** flat glowing discs (red = not yet / can't afford, cyan-blue = the next one) with a small floating dark label: name + purple-flame price ("Install Pipes 75").
- **Windows:** STORE = dark-red panel with a glowing red border, a red X close button, a scroll bar, side tabs as diamond icons with labels.
- Bottom-left: "ALPHA 0.8.4" + a round "+" button.

### VFX (what I saw)
- The **singularity crystal**: a huge purple glowing crystal shard on your plot with swirling purple energy wisps, a purple glow pool on the ground and floating sparks.
- **Tycoon build:** the piece appears instantly when you click (no build animation seen yet).
- **Pads:** soft neon glow discs.
- **Guide beam:** a big black chevron arrow made of ">>" segments lying on the ground from you to the target.
- **Pipes:** purple-lit pipe segments; an energy bar "+3/s" floating over the pipe.
- **Store open:** the world behind blurs (depth of field) and darkens.
- World: misty lilac sky, fog, dark rocky ground, dead trees, ruined stone towers: a grim "after the singularity" mood.

### SFX (needs a listen)
I can't hear the game (screenshots only), so nothing here is confirmed. To fill in: the sound on a pad buy, the energy tick, the store opening, the tutorial step done, the background music, the crystal's hum.

