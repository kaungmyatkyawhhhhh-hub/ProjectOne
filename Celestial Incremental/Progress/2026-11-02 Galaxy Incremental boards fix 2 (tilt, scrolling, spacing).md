---
date: 2026-11-02
tags: [galaxy, boards, ui, progress]
status: built and tested in Studio; not published
---
# Galaxy Incremental - boards fix 2: tilt, scrolling, spacing (2 Nov, Claude Code)

**Sources:**
- Spec: [[2026-11-02 Galaxy Incremental - Boards fix 2 (tilt, scrolling, spacing)]].
- Prompt: [[2026-11-02 Galaxy Incremental - Prompt - Boards fix 2]].

Place "Galaxy Incremental" (111654682859982, P&L Studios XP). Only the two boards on each **personal** island were changed (Upgrades + Constellation Tree). The main island's boards (Leaderboard, Star Surge, signs) and GYM ARC were not touched.

Screenshots: `Map\screens\boards2_fixed\` (1-6).

## What changed
1. **Tilt 8° → 18°** (`MapConfig.Boards.Tilt`). The screens lean back and face up toward the player, like Regrowth's.
   - The bottom edge stays 2.5 studs above the floor (measured 2.56).
   - The two legs now lean with the board, from the floor up to 3 studs under the top, each with a brass foot block on the floor. Before, they were straight posts that only reached the bottom bar.
2. **No pages.** The `< 1/2 >` arrows are gone.
   - Each tab is one scrolling list of all its rows.
   - The scroll area is a new shared kit piece, `Kit.scroller` (UIKit): a 10 px gold thumb (gold gradient, ink outline, round ends) on a dark track.
   - The track only shows when there is something to scroll.
   - The board and the 2D Upgrades window (hotbar U) use the same code, so both changed.
   - How it scrolls:
     - **Mouse wheel:** Roblox doesn't wheel-scroll a 3D board by itself, so the kit does it. While the mouse is over a board's list, the camera's zoom is held so the wheel only scrolls.
     - **Mouse drag:** Roblox has none, so the kit projects the mouse onto the board's screen.
     - **Touch:** Roblox's own touch scrolling, with the same drag as a backup.
   - **A press that turns into a drag never buys.** A tap on BUY buys once (on release). Holding BUY buys about 8 times a second until you let go.
   - **Holding BUY used to stop after 1-2 buys.** Each buy changes the price, which rebuilds the button. The hold now follows the finger or mouse instead of the button.
   - **The refresh (4x/s) keeps where you scrolled to.** It only updates the text and buttons; the list is rebuilt only when you change tab.
   - **Tutorial step 1:** if you have scrolled away, the board scrolls the ASTEROID row back into view so the arrow can point at it.
   - **Tree board:** the constellation sits in a sideways scroll area. It scrolls only when the ring is wider than the panel; today it fits, so there's no bar.
3. **Angle 18.5° → 25°** (`MapConfig.Boards.Angle`). The frames are now **~6 studs apart** at the bottom, a bit more at the top because both lean back.
   - Both boards still face the island centre.
   - No lamp overlaps: the nearest lamp (±60°) is ~8.5 studs from a board's outer edge, so no lamps were moved.
4. **Small fix on the Tree board:** tapping a node you already own used to jump straight back to First Light. A tapped node now stays shown; after a buy the bar moves on to the next node you can buy, as before.

## Tested in Studio Play (my island, test data)
- **Wheel on the board:** 2 notches scrolled the list 180 px. The camera zoom was held while over the list and given back when the mouse left, with no jump.
- **Mouse drag on the board:** the list followed the drag (68 px down scrolled it back ~93 px).
- **Refresh:** after 3 s (12 refreshes) the list stayed at 180 px and the same row objects were kept.
- **Buy after scrolling:** a click on GAS GIANT bought exactly one (LV 11 → 12). The list stayed where it was.
- **Drag that starts on a BUY button:** it scrolled 78 px and bought nothing.
- **Hold BUY 1.5 s:** 8 buys (Moon 37 → 45), stopping on release.
- **Visitor:** island set to another owner for the test. The buttons showed VISIT; the wheel scrolled 0 → 90 and a drag scrolled to the bottom. The owner was set back.
- **2D Upgrades window:** the wheel scrolled 0 → 100, a drag scrolled back, and the same gold thumb shows.
- **Tree board:** tapping Lunar Pull shows it in the bottom bar. No scroll bar (it fits).
- No errors in the output.
- **Not tested:**
  - A real phone touch. Studio can't send touches from here; the touch path is Roblox's own plus the same drag code that was tested with the mouse.
  - Studio's injected wheel never zooms the camera, even over the sky, so the "no zoom over the board" part was checked by the held zoom limits, not by a real wheel.

## Code
- **In Studio:**
  - `ReplicatedStorage.Galaxy`: UIKit (`Kit.scroller`), UpgradesPanel, TreePanel, MapConfig;
  - `StarterPlayerScripts`: GalaxyBoards (`pointerFor`), GalaxyHUD (option removed);
  - `ServerScriptService.GalaxyMapService` (`makeBoards` legs).
- **Vault copies updated:** `Code\friends-test\` and `Code\map\` (checked identical to Studio).

## Owner to-do
- Save / publish the place.
- Try scrolling a board on your phone and tell me if a swipe also turns the camera.
