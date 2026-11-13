---
date: 2026-11-14
tags: [mega-bite, ui, hud, phone, change-log]
---
# MEGA BITE: HUD fixes from the phone audit (tap floor)

The roblox-ui-pro audit, run on a simulated **Samsung Galaxy A06 (705×338)**, the smallest common phone. On that screen `K.BaseScale` is ×0.666, so everything you tap had shrunk:
- Settings: 29×34 px.
- Shop, Index and the right-column tiles: 37–41 px wide.
- Labels: 6–11 px.

Screens get smaller, thumbs don't.

## What changed
- **`UIKit`:**
  - New `K.TouchFloor = 0.82` and `K.TapScale(v)`: the normal scale, but never below 0.82 on touch screens.
  - `K.AttachScale(gui, {tap = true})` uses it.
  - Readouts (the top corners) still shrink with the screen.
- **`MB_HUD`:**
  - `corner()` takes a `tap` flag. **LeftMid** (Shop, Index, Settings) and **RightCol** (the unlock tiles) use the tap floor.
  - The **Settings gear** is 44 → 54 (it was the smallest target), and LeftMid is 218 tall.
  - **Shop/Index labels** are 15 → 18.
  - **Right-column labels:** 100 px wide, 14–18 before scaling (was 9–14), so "CLOWNFISH" stays on one line.
  - **Right-column row (short phones):**
    - The tiles sit right under the minimap.
    - They are 96 px apart, so "FOSSILIZE" and "CLOWNFISH" don't touch.
    - They start 12 px further in from the screen edge, so the edge tile's name stays on screen.
    - The row-or-column choice now uses DART's own scale.
  - **SPRINT and ability labels** are 16 → 21 (were 10.7 px on the A06).
  - **Quest counter "1 / 2":** the bar is 14 → 18 tall and the number 14 → 21 (was 9.3 px).
  - **"FOSSIL V x4"** is 17 → 21.
- **`MB_Crew`:**
  - The chip keeps its place and size (bigger, it ran into the SIZE readout).
  - Its words are 15 → 17.
  - An invisible **46 px-tall tap area** (`Hit`) sits around the slim pill.
- **Backups:** `ServerStorage.UIKit_preTapFloor_14Nov`, `MB_HUD_preTapFloor_14Nov`, `MB_Crew_preTapFloor_14Nov`.

## Checked (14 Nov, Play in Studio, audit + screenshots)

| Device | Viewport | Tap targets | Audit |
|---|---|---|---|
| Galaxy A06 | 705×338 | Shop/Index 50×57, Settings 44×50, tiles 45×52, Sprint 61×47, Dart 74×74 | 0 overlaps; 2 accepted (below) |
| iPhone 17 Pro | 750×381 | all ≥ 44 | same 2 accepted |
| PC (Studio window) | 976×584 | column layout as before | 0 errors; the "Q" / "SHIFT" key hints are 13 px |

**Accepted on purpose:**
- The minimap's "N" (10–11 px, a compass mark, not something to read).
- The Crew chip's words at 12.8–13.6 px (keeping the chip its old size so it doesn't hit the readout).

There were no script errors in the console. On phones, nothing overlaps DART or SPRINT. The game has no Roblox jump button; it uses its own controls and a floating stick on the left.

**Not checked:**
- Tablets.
- Console.
- A real phone.
- The Fossilize/ability unlock celebrations (they snapshot tiles, and the tiles have moved).

**The place is not saved or published.**

## Earlier audit items now resolved
- **"12 corner sizes":** the corners group into ≤ 4 families (inner corners = outer minus the outline), so the HUD's corners are consistent.
- **"Trench under the jump button" / "Settings in the thumbstick area":** the PC-sized audit used estimates of Roblox's own controls, which this game doesn't use. The audit now checks the game's own controls (DART, SPRINT) instead.
