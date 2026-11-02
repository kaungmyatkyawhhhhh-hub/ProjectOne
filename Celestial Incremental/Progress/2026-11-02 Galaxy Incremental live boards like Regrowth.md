---
date: 2026-11-02
tags: [galaxy, map, ui, boards, progress]
status: built and tested in Studio; not published
---
# Galaxy Incremental - live island boards like Regrowth (2 Nov, Claude Code)

**Sources:**
- Spec: [[2026-11-02 Galaxy Incremental - Boards like Regrowth (live, buttons, edge)]].
- Layouts: `Map\images\board_upgrades_v12.png` and `board_tree_v12.png`.

Place "Galaxy Incremental" (111654682859982, P&L Studios XP). GYM ARC was not touched.

Screenshots: `Map\screens\2026-11-02-live-boards\` (numbered 1-10).

## What changed
1. **The island terminal is gone.**
   - No Terminal parts, ProximityPrompts or ClickDetectors are left on the map (checked).
   - `MapConfig.Terminal` is removed.
2. **Every owned island has 2 boards on its far edge,** facing the spawn:
   - UPGRADES on the left, CONSTELLATION TREE on the right;
   - brass frame, 16 x 11 studs, tilted back 8 degrees;
   - a beacon orb on top.
   - Sizes are in `MapConfig.Boards`.
3. **The boards are live UI.**
   - They use the same v12 windows as the 2D Upgrades window, from new shared modules `UpgradesPanel` and `TreePanel`.
   - They show the owner's real numbers and refresh 4 times a second.
   - Real buttons: tabs, page arrows (1/2), BUY.
   - The frame edge has a running light.
   - The beacon shows only while something on that board can be bought.
4. **Visitors** see the owner's numbers, but their buttons are grey "VISIT".
5. **The server checks every board buy:**
   - it must be your island;
   - you must stand within 45 studs of the boards.
   - Tested: other island = refused, from the plaza = refused, at the boards = bought.
6. **Tutorial step 1** ("Buy an asteroid"): the arrow and ring point at the ASTEROID BUY on your board when it's on screen. Otherwise it uses the hotbar flow as before.
7. **The 2D Upgrades window (hotkey U)** now uses the same UpgradesPanel code. The look is unchanged.
8. **Spawn** now faces the boards.
9. **Boards are drawn** only for your own island and islands within 160 studs, which saves FPS.

## Tested in Play
- A real mouse click on the Tree board's BUY bought Comet Lure: 80.0K stardust spent, the node turned green, "BOUGHT!" showed.
- A tap on the board's asteroid BUY (phone mode) bought an asteroid: 210/s → 216/s. The tutorial step completed.
- Visitor view at Tester 6's island: all buttons show VISIT.
- No errors in the output after the fix.
- 56 FPS after a Play restart. Studio's viewport once froze (3D black, UI fine) and a restart fixed it.

## Differences from the spec (for the owner)
- **Board angle ±18.5° instead of ±14°.** At ±14° the two 16-wide boards overlap on a 26-radius edge; 18.5° is the smallest angle that fits.
- **Ring-1 tree nodes cost stardust, not shards.** That's what the design note says. The v12 picture shows a shard cost.
- **"Star Furnace" (in the v12 picture) doesn't exist in the game data.** The STARDUST tab shows the real upgrades, and tutorial step 1 points at the ASTEROID BUY.
- **The buy sound is a placeholder** (Roblox's built-in UI click, pitched). A real sound needs an audio upload to the group.

## Code
- Vault copies:
  - `Code\map\`: MapConfig, Kit, MapBuilder, MapService, MapClient.
  - `Code\friends-test\`: EconService, UIKit, GalaxyHUD, plus the new UpgradesPanel, TreePanel and GalaxyBoards.
- In Studio:
  - `ReplicatedStorage.Galaxy.UpgradesPanel` and `TreePanel` (ModuleScripts);
  - `StarterPlayerScripts.GalaxyBoards` (LocalScript).

## Owner to-do
- Save/publish the place, then do a 2-player test (a visitor at your boards).
- Optional: upload a buy sound to P&L Studios XP.
