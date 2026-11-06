---
date: 2026-11-07
tags: [galaxy, progress, bug, ui]
status: fixed and tested in Studio (PC + 667x375 phone); NOT published
---
# Galaxy Incremental - Bug: clicking inside a window closed it (7 Nov, Claude Code)

Owner: in UPGRADES, clicking a tab or an Asteroid / Moon / Planet row made the window close.

Screens + clip: `Progress/screens/2026-11-07-window-bug/` (`upgrades-clicking-inside-stays-open.gif`).

## The cause: (b), the "tap outside closes" backdrop
- Since 2.7 (#163) the backdrop was ONE full-screen invisible TextButton under the windows (ZIndex 0).
- It was under the window on screen, but Roblox still gave it the clicks that landed on a window's **plain frames** (a row's empty part, the tab column, a panel), because only buttons sat above it there.
- Proof: a click on an empty spot of the first row logged `BACKDROP down`, `BACKDROP click`, then `Upgrades.Visible=false`.
- Setting every frame in the window to `Active = true` did NOT stop it. So any full-screen button anywhere under a window is unsafe.

The other three, checked:
- **(a)** No UserInputService "click outside" test exists.
- **(c)** Real on PHONES: a tap that wasn't caught by the UI went on to GalaxyBoards' world-tap raycast. If it hit the FORGE / BLACK HOLE board, it fired a *toggle* that could close the window. Fixed too (see below).
- **(d)** There was no distance auto-close.

## The fix: one WindowManager (`ReplicatedStorage.Galaxy.WindowManager`)
- **Every window registers** its root + close function: UPGRADES (U), TREE (T), FORGE (F), BLACK HOLE (B), STORE (E), DAILY (J), STATS (P), SETTINGS (Q), GUIDE (G), CODES (C), SECTORS (S), the return screen (R).
- **A window closes only by:**
  - its X;
  - Esc / gamepad B;
  - a tap on the backdrop;
  - walking more than **25 studs** from the board that opened it (measured from the character).
- **The backdrop** is now four dim strips AROUND the open window (they cover only the outside, under the hotbar). A click inside a window can't reach it.
- **Input:** window roots and their panels are `Active` (not the parts inside buttons, so buttons keep working).
- **While a window is open, the world ignores clicks:** board taps (GalaxyBoards), buttons on 3D boards (IslandBoardsUI `tap`, only buttons in a SurfaceGui, not the TREE window's own panels), ProximityPrompts (MapClient), the pad ClickDetector.
- **Opening what's already open does nothing:** a board or a hotbar key no longer toggles it shut. (So pressing U again doesn't close UPGRADES any more; X / Esc / outside do.)
- Files: WindowManager (new), GalaxyHUD, GalaxyBoards, IslandBoardsUI, MapClient, GalaxyBlackHole, GalaxyCodes, GalaxyDaily, GalaxyForge, GalaxyGuide, GalaxySectors, GalaxySettings, GalaxyStore.

## Tests (Studio)
| Window | PC: clicks inside, stayed open | Phone: taps inside, stayed open |
|---|---|---|
| UPGRADES | 32 (every tab, rows, buy buttons, empty areas) + drag-scroll of the list | 29 + drag |
| TREE | 34 (nodes, BUY ALL, INFO, empty) | 19 + drag |
| FORGE | 28 (ROLL, BULK, book, odds) | 19 |
| DAILY | 28 (quests, gifts, empty) | 19 |
| STATS | 29 | 19 |
| BLACK HOLE | 21 (not COLLAPSE / AUTO-SUPERNOVA) | 14 (no buttons) |
| STORE | 13 (empty areas only: the buttons open Robux prompts) | 22 (empty areas only) |

- **Closes:** outside click closes (PC and phone); X closes.
- **Esc / gamepad B: NOT tested.** The Studio test tool's key presses don't reach the game (T didn't open the TREE either). Esc calls the same close as the backdrop, which works. **Owner: please try Esc once.**
- **Board can't re-toggle:** BLACK HOLE opened from a board, then the same board fired again: still open. FORGE twice: still open.
- **Walk-away:** a window opened from a board 40 studs away closed within 1.5 s; one from a board 5 studs away stayed open.
- **Drag-scroll by mouse:** works on UPGRADES (its own drag code). STATS on the phone scrolls by touch / wheel only (Roblox's normal ScrollingFrame), which the test tool can't send.

## Also in this pass (owner's message): the boost chips moved to the middle-bottom LEFT
- FRIENDS (+10% per friend), GROUP +10% and BOOSTS x… are one column at the left now (BOOSTS was on the right).
- The column's bottom is fixed: 80% down the screen on PC, 68% on a phone (above the move thumbstick's corner). BOOSTS sits at the bottom, the social chips and any potions stack upward, and the BOOSTS list opens upward.
- Screens: `pc-boost-chips-bottom-left`, `phone-boost-chips-bottom-left`, `phone-boosts-list-opens-up`.

## Owner's test save: a Black Hole happened by accident (my fault)
- The save now shows **BlackHoles 1, Dark Matter 24, AUTO-SUPERNOVA on**. Shards went from 574K to ~1.7K and stardust reset (Supernovas 19, run 2).
- No test of mine pressed COLLAPSE on purpose. Most likely, during the earlier phone screenshot pass (9 UI art task), clicks meant for the hotbar / Settings landed on COLLAPSE and AUTO-SUPERNOVA while the BLACK HOLE window was still open (on a phone those buttons are where the hotbar was).
- It's the Studio test save only (no real player). I can't undo it without a backup.
- From now on my click tests skip any point on COLLAPSE / AUTO-SUPERNOVA / Robux buttons. The first blocklist missed COLLAPSE (its label isn't inside the button); caught before clicking.
