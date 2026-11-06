---
date: 2026-11-07
tags: [galaxy, progress, ui]
status: fixed and checked in Studio (PC + 667x375 phone); NOT published
---
# Galaxy Incremental - UI corners: square layers poking out of rounded windows (7 Nov, Claude Code)

Owner's screenshot: the Constellation Tree + Info window showed square corners / a lighter layer behind the rounded frame.

Screens: `Progress/screens/2026-11-07-ui-corners/`:
- `BEFORE-all-pc.png`, `AFTER-all-pc.png`, `AFTER-all-phone.png`: each window's 4 corners, enlarged x4.
- One sheet per window (`before-pc-*`, `after-pc-*`, `after-phone-*`).

## What was poking out, and the fix
1. **TREE / INFO (the one in the screenshot).**
   - **Cause:** the 2D window reuses the 3D island boards' screen code. It drew a SQUARE stone-coloured layer under the rounded screen. On a 3D board that layer fills the gap to the square stone frame around it; in the 2D window there is no stone frame, so it showed at all 4 corners.
   - **Fix:** it's drawn only on the 3D boards now (IslandBoardsUI `shell`, `ctx.world`).
2. **The 3 windows that scroll on phones** (UPGRADES, STATS, STORE).
   - **Cause:** the scroll frame was exactly the window's width, so Roblox drew the scroll bar over the window's rounded right edge (a square strip at the corner).
   - **Fix:** the scroll frame is now 12 px wider than the window; the bar runs beside it. UPGRADES' phone scale counts that margin.
3. **Every button** (Kit.button): its stripe texture was a fixed 512x128 image, clipped by `ClipsDescendants`. That clips SQUARE, not to the curve. It's now the button's size, tiled, with its own rounding.
4. **Every window header** (Kit.window): the same with its stripes; now its size, tiled, rounded like the header.
5. **Nested radius rule:** the window's outer frame is 10. The body and header are inset 3, so they're now 7 (were 8, bigger than the rule allows). A helper works it out: `Kit.InnerRadius(outer, inset)`.
6. **UIStroke on the outermost layer:** the window's accent line moved from the inner body to the outer frame, Border mode. `Kit.Round` sets Border on any stroke of the layer it rounds.

**The one helper:** `Kit.Round(frame, radius)` (UIKit). One UICorner per layer, reused if there is one. The old `Kit.corner` now calls it, so every window, panel, card and button built with the Kit goes through it.

## Checks
- **Corner detector (test tool):** at every window's 4 corners, just outside the curve, nothing filled is drawn that isn't rounded at that spot. The title icons and sparkles break out over the corner on purpose; glows are rounded 9-slice images.
- **Every rounded layer's children:** no child draws a square layer in its parent's corners (UPGRADES, TREE, FORGE, BLACK HOLE, DAILY, STORE, SETTINGS, STATS).
- **Screenshots** (PC + phone, 4 corners each):
  - Before: only TREE / INFO had visible square corners.
  - After: all rounded.
  - On the phone, UPGRADES / STATS / STORE were square at the top right until fix 2.

## Not checked / flags
1. **Phone windows that scroll** (UPGRADES, STATS, STORE, TREE): their bottom corners are the bottom of the scroll area until you scroll to the end. TREE / INFO's bottom was checked scrolled to the end (rounded).
2. **3D island boards:** their square stone layer stays on purpose: it is the board's 3D stone frame. On a LOCKED Star Forge / Black Hole board it hides (the sign art is the only frame, 7 Nov).
3. **Toasts and the small popups** were not shot one by one.
   - Toasts use Kit boxes, so Kit.Round covers them.
   - The CODES and GUIDE windows are Kit windows, so the same fixes apply. Not screenshotted.
