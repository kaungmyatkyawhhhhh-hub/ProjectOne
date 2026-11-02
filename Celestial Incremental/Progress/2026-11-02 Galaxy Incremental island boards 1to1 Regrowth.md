---
date: 2026-11-02
tags: [galaxy, boards, ui, regrowth, progress]
status: built and tested in Studio; not published
---
# Galaxy Incremental - island boards as a copy of Regrowth's (2 Nov, Claude Code)

**Sources:**
- Law: [[2026-11-02 Galaxy Incremental - Island boards like Regrowth 1to1]].
- Prompt: [[2026-11-02 Galaxy Incremental - Prompt - Island boards 1to1 Regrowth]].
- References: `Map\screens\regrowth_boards\`.

This replaces [[2026-11-02 Galaxy Incremental boards fix 2 (tilt, scrolling, spacing)]].

Place "Galaxy Incremental" (111654682859982, P&L Studios XP). Only the boards on the personal islands changed. The centre's Leaderboard and Star Surge were not touched, and GYM ARC was not touched.

Screenshots: `Map\screens\boards_1to1\` (1-15).

## What's on every owned island now (MapConfig.Boards, one table)
- **Far edge, the pair (Regrowth's Perks Tree + Info):** CONSTELLATION TREE on the left, INFO on the right.
  - Two separate upright panels (0°), each turned 16° in toward the player (a shallow V), 3 studs apart.
  - The spawn faces the gap.
- **Left edge, BODIES (Regrowth's Machines):**
  - Tilted back 10° on two leaning legs with brass feet.
  - One row per body: name, LEVEL, TIER (e.g. "TIER 2 SILVER"), +x/s, the cost above UPGRADE, M (buy max), and the row's boost at the right (e.g. "12x").
  - Locked rows: UNLOCK + cost, or "unlock the MOON first". The Star row shows SUPERNOVA 1.
- **Right edge, STAR UPGRADES (Regrowth's Factory Upgrades):**
  - Cards for First Light, Orbit Speed and Comet Lure: name, short text, a big icon, the value + green step, a gold star badge with the level, price, UPGRADE (OWNED when bought).
  - The cards scroll sideways.
- **CONSTELLATION TREE (Perks Tree layout):**
  - A grid of rounded tiles: icon, value (x2, x1.5, 30s, NEW), and the cost under each.
  - A tile whose node needs an earlier one is a dark silhouette. Three silhouettes stand for nodes not in the game yet (like Regrowth's).
  - It scrolls.
- **INFO:** shows what you last tapped: a tree tile, a body row or a star card.
  - Icon, name, LEVEL / TIER, the value + green step, a short line, the TIER line, progress and the big UPGRADE with its cost.
  - Bodies show progress to the next x2 milestone (e.g. 54/100). Nodes show ring progress (e.g. 3/6).
  - **10x** buys up to 10 bodies at once. Nodes have only one level, so INFO shows one wide UPGRADE for them and no 10x.
  - Until you tap something, INFO shows the first node you can buy (all bought: the Asteroid).
- **Frames:**
  - Chunky 1.2-stud lavender stone frames with rounded corners, a brass trim round the screen, and a dark screen 0.4 studs back.
  - Upright boards stand on a stone pedestal with a brass band.
  - The animated neon edge is a glow in from every side plus a light that runs round, with sparks: violet tree, blue info, violet bodies, gold upgrades.
  - Big white titles with a dark outline.
- **Behaviour:**
  - Owner-only buying; visitors see VISIT.
  - The same data and remote as the 2D window. U still opens the same Upgrades window.
  - Lists scroll by wheel, drag and touch (`Kit.scroller` from boards fix 2), and a refresh never moves them.
  - Holding UPGRADE keeps buying.
- **Tutorial step 1:** the arrow + ring sit on the Asteroid's UPGRADE on the BODIES board. While that board is off screen (it is at the spawn), gold arrows on the floor lead you to it (Regrowth's floor trail). The hotbar is only used if you have no island.
- **New player (tier 0):** the rock now has a stone pad under each side board too, so all four boards stand on something.

## Other changes
- **Server (GalaxyEconService):**
  - New buys `BuyBody10` (up to 10) and `BuyBodyMax` (as many as you can pay for).
  - A board buy is checked within 40 studs of the island's centre (it used to be the old boards' spot).
- **EconConfig:** body TIER names (NO TIER, BRONZE, SILVER, GOLD, PLATINUM, DIAMOND, COSMIC) = the x2 milestones reached.
- **Moved out from in front of the new side boards:**
  - Crystals (now 3, at the back and back-left).
  - Banner (back-right).
  - Telescope (back-left by the bridge).
  - Top view: `8_top_view_tier6_layout.jpg`.
- **Old boards deleted:** the 2-board build, its beacons, and the TreePanel module (only the old Tree board used it). UpgradesPanel stays: it is the U window.
- **Studio test switch:** Workspace `TestFreshSave` = true starts every player on a new save that is never written.

## Tested in Studio Play
- **New save (TestFreshSave):**
  - Tier 0, all four boards on the rock pads.
  - Floor trail from the spawn to BODIES.
  - Arrow on the Asteroid's UPGRADE; a real click bought it (Own1 1 → 2) and tutorial step 1 completed.
- **Phone 667x375 (TestPhone):**
  - The HUD frame, with the camera set so the crop shows what a phone's 70° view sees.
  - A click on the Asteroid's UPGRADE bought it (LEVEL 2, +1 ESSENCE). Shots 5 and 6.
- **Own save:**
  - Tapping a tree tile switched INFO (Orbit Speed, OWNED, 6/6).
  - M on Moon bought 21 (47 → 68), leaving less than the next Moon costs.
  - INFO 10x + UPGRADE bought 10 Asteroids (54 → 64).
  - The U window shows the same numbers.
- **Visitor (TestIslands, Tester 7's island):** every button is grey VISIT. Test owners aren't real players, so their numbers are empty.
- No errors in the output.
- **Not tested:**
  - A real phone touch (Studio can't send touches from here; a mouse click was used).
  - A visitor seeing a real player's numbers (needs 2 players).

## Side by side with Regrowth (same camera angle)
- `1_sbs_perks_info_vs_tree_info.jpg`, `2_sbs_machines_vs_bodies.jpg`, `3_sbs_factory_vs_star_upgrades.jpg`
- **Where ours still differs:**
  - Regrowth's frames are thicker, bevelled stone. Its neon (lightning / flames) also spills outside the frame; ours stays inside the screen edge.
  - Regrowth's Machines rows have a "+MACHINE" button. We have one count per body, so the row has UPGRADE + M only.

![[Celestial Incremental/Map/screens/boards_1to1/1_sbs_perks_info_vs_tree_info.jpg]]
![[Celestial Incremental/Map/screens/boards_1to1/2_sbs_machines_vs_bodies.jpg]]
![[Celestial Incremental/Map/screens/boards_1to1/3_sbs_factory_vs_star_upgrades.jpg]]
![[Celestial Incremental/Map/screens/boards_1to1/4_spawn_view.jpg]]
![[Celestial Incremental/Map/screens/boards_1to1/5_phone_667x375_tutorial_arrow.png]]
![[Celestial Incremental/Map/screens/boards_1to1/7_visitor_view_VISIT.jpg]]

## Code
- **New:** `ReplicatedStorage.Galaxy.IslandBoardsUI` (the four screens).
- **Changed:**
  - GalaxyBoards (four boards, the shared INFO selection);
  - MapConfig (Boards, decorations);
  - GalaxyMapBuilder (BoardCFrames, BoardFrame, tier-0 side pads);
  - GalaxyMapService (makeBoards, spawn facing);
  - GalaxyEconService;
  - EconConfig;
  - GalaxyHUD (floor trail, arrow on BODIES).
- **Vault copies:** `Code\friends-test\` and `Code\map\`, checked identical to Studio. TreePanel.lua removed.

## Owner to-do
- File > Save / publish the place.
- Walk the island on your phone: tap a board button and say if anything is too small to read.
- Want the neon to spill outside the frame like Regrowth's (glowing parts round the frame)? Say so.
