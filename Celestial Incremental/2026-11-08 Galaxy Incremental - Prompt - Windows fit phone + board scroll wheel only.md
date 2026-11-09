---
date: 2026-11-08
tags: [galaxy, prompt, claude-code, phone, ui, boards]
---
# Galaxy Incremental: windows fit the phone screen + boards scroll with the mouse wheel only (owner, 8 Nov)

Owner (3 phone screenshots of UPGRADES): "the ui doesnt fit in mobile screens rn, u see it even goes outside of the bottom of the screen" and "for the boards, make it so that u cant scroll with ur mouse and only scrollable with ur scroll wheel on pc. cuz on mobile when u click on it, it opens the tab." And: "no testing since ill be the one testing".
Rules: [[Lessons - Galaxy to +1 SHRINK (feel - sound, VFX, screen FX, lighting)]] (PHONE LAYOUT, WINDOWS / INPUT). Related: [[2026-11-07 Galaxy Incremental - Prompt - PHONE HUD fix (live game)]].

```text
GALAXY INCREMENTAL – WINDOWS FIT PHONE SCREENS + BOARDS SCROLL WITH THE MOUSE WHEEL ONLY.
Do NOT playtest or run test sessions: the owner tests this himself. Do NOT publish. Just make the changes, then do a static self-review (read your code back, check the numbers below) and report.

WHAT THE OWNER SAW (phone, landscape, UPGRADES window open):
- The window runs off the BOTTOM of the screen. The 4th tab (BLACK HOLE) and the 2nd row's buttons are cut off.
- Roblox's JUMP button sits on top of the window's bottom-right corner, right over a buy button. The tutorial arrow points at that same hidden button.
- The header is very tall (title + ESSENCE + X take about 1/7 of the screen). Card text is clipped: "UNLOCK PLANET" runs out of its button, and "opens at SUPERNOVA 1 (ring 2)" is cut off at the bottom.
- The tutorial "LOCKED" label overlaps the card's art.

1. ONE RULE FOR EVERY WINDOW (UPGRADES, Tree, Info, Forge, Black Hole, Shop, Settings, every popup): use the shared WindowManager / UiKit. If there isn't one, make it.
   - The window's size is computed from the SAFE viewport, not a fixed size:
     - safe = the camera ViewportSize minus GuiService:GetGuiInset() and the top-bar insets (ScreenInsets = CoreUISafeInsets on every ScreenGui);
     - window = min(designSize, 0.92 × safe width, 0.86 × safe height), applied with a UIScale on the window root (not by resizing its children);
     - recompute on ViewportSize change (rotation, resize).
   - The window is centred in the safe area, so nothing ever goes off any edge.
   - While any window is open on a touch device: GuiService.TouchControlsEnabled = false (hides the jump button and thumbstick), restored when the last window closes. Also hide the hotbar and the left chips while a window is open on phone.
   - PHONE layout (safe height < 500 px), designed on purpose, not shrunk:
     - header 44-52 px tall: the title on the left, the ESSENCE pill compact (icon + number only), X on the right;
     - the tab column is narrower (icon + short label) and becomes a ScrollingFrame if the tabs don't fit, so BLACK HOLE stays reachable;
     - cards are AutomaticSize Y inside a UIListLayout; the right list is a ScrollingFrame with AutomaticCanvasSize Y, and its last card has padding below it, so the bottom card is never clipped;
     - text: TextScaled with UITextSizeConstraint (min 14, max 28), TextWrapped, and enough width; buttons shrink their label ("UNLOCK" not "UNLOCK PLANET") instead of overflowing.
   - The tutorial arrow and "LOCKED" tag are children of the TARGET button/card (adorned, in the card's own layout), never at fixed screen positions. They must not overlap card art or text.

2. BOARDS (in-world SurfaceGui boards with lists, e.g. PERKS, TOP SUPERNOVAS, BOOSTS):
   - No drag or click-to-scroll at all: board ScrollingFrames get ScrollingEnabled = false and ScrollBarThickness 0 on touch.
   - PC: the MOUSE WHEEL scrolls the board while the cursor is over it (MouseWheelForward/Backward on the list, or a transparent capture frame on top), moving CanvasPosition by about 1 row per notch with a short tween, clamped to the canvas. A thin scrollbar is shown on PC only, as a hint.
   - Touch (and a plain click on PC): one TAP on the board opens its window (as it does now). A drag on the board must not scroll it and must not open the window twice (one open per tap, debounce 0.3 s).
   - Gamepad: no board scrolling; the window it opens handles that.

REPORT (short): the files changed, the WindowManager size formula and the phone breakpoint values, the list of windows now using it, and how board scrolling now works on PC / touch / gamepad. Mention anything you couldn't do.
```
