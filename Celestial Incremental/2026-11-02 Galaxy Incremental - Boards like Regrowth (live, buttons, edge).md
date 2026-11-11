---
date: 2026-11-02
tags: [galaxy, map, boards, regrowth, decided]
status: decided
---
# Galaxy Incremental - island boards like Regrowth (2 Nov)

Owner (2 Nov, with screenshots): "the boards are in an awkward position, it should be like this position (3rd pic) where its near the outer edge and aligns with the edge. and also the board is still using proximity prompt and theres no buttons on the board. its suppose to be like the regrowth incremental boards".
Screens: `Map\screens\regrowth_boards\` (galaxy_board_now_1/2 = what we have, galaxy_starsurge_good_position = the position he likes, regrowth_board_* = the reference).

## What Studio showed (checked 2 Nov, Island_1)
- Terminal_Upgrades sits at island-local (-14, 0, 13) = 19 studs from the centre, in the middle of the floor, turned at an odd angle -> "awkward".
- It is a static image slot (`BoardImagePending`, no image yet) + ClickDetector + ProximityPrompt "Open". No buttons. MapConfig.Terminal.Images is empty.

## How Regrowth's boards work (from the screenshots)
- The board IS the UI: a live SurfaceGui with real buttons. PERKS TREE board: click a node to buy it (cost under it, multiplier on it, locked nodes dark). INFO board next to it: icon, LEVEL x / TIER, multiplier and +0.1x, progress 0/10, a big UPGRADE button with the cost and a "10x" toggle. MACHINES board: rows with LEVEL, TIER, +rate, UPGRADE and +MACHINE buttons. FACTORY UPGRADES: cards with an icon, value + step, a star level badge and an UPGRADE button with the price.
- Numbers update live as you buy; the tutorial arrow points at the button on the board.
- Boards stand at the EDGE of the platform, their backs to the void, following the edge line, slightly tilted back, in pairs that angle in toward the player (Perks Tree + Info). Thick frame with an animated glow on the edges.
- No prompt to open a window: you just click/tap the buttons on the board (the same windows also open from the hotbar).

## Decided for Galaxy
1. **Position**: on the OUTER edge of each personal island, on the far side from the bridge, backs to the void, each panel's face tangent to the rim (perpendicular to the island radius), set just inside the lamp ring (radius ~26, lamps at 27.5 move aside so nothing overlaps). Two panels side by side, centred +-14 deg either side of the far point, so they angle in toward the island centre like Regrowth's pair. Tilted back 8 deg. Bottom edge 2.5 studs above the floor.
2. **Panels** (left to right when facing them): **UPGRADES** and **CONSTELLATION TREE**. Each 16 x 11 studs (the window ratio 1.455).
3. **Content = the approved v12 windows, live** (the same layout as `board_upgrades_v12.png` / `board_tree_v12.png`; those PNGs are now the LAYOUT REFERENCE, not images to paste). SurfaceGui CanvasSize exactly 745 x 512 so every position/size can be copied 1:1 from the v12 window (the PNGs are 2x: divide by 2).
   - Upgrades: header bar with title + SHARDS pill (no close X on the board), tab buttons STARDUST / COMETS / PLANETS / FORGE / BLACK HOLE (locked tabs grey with a lock and the unlock text), 3 rows per page with icon, LV, name, description, now > next multiplier, BUY button with the cost (green = can buy, grey + red cost = can't, purple MAX); page arrows if a tab has more than 3 rows.
   - Tree: constellation with clickable diamond nodes (bought = green edge, buyable = gold edge, locked = dark with ?), the bottom bar shows the selected node with its value and a shard BUY button.
   - Static textures, animated glows (rotating UIGradient on the frame edge, sparkle on a buyable button), icons do not move (UI rules from v12).
4. **Input**: buttons work by mouse click and by tap. No ProximityPrompt, no ClickDetector. The board GUIs live in PlayerGui with Adornee = the panel (so buttons receive input); server checks the player owns the island and is within 45 studs.
5. **Visitors** see the owner's board with the owner's numbers; buy buttons show "VISIT" grey and do nothing.
6. **Spawn**: the player now spawns facing the boards (tutorial step 1 is "buy Star Furnace on the board"; the tutorial arrow points at the button on the board, like Regrowth). The Core is behind you and shows when you turn; the bridge is in view to the side.
7. Frame: brass low-poly frame 0.8 thick (gold = interactive), dark screen, a beacon on top only when something is buyable.
8. The STAR SURGE board on the plaza stays where it is (the owner's good example).
