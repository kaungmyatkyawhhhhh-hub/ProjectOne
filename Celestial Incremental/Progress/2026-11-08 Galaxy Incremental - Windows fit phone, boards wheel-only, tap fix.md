---
date: 2026-11-09
tags: [galaxy, progress, ui, phone, boards, bug]
status: in Studio, NOT tested (owner tests himself), NOT published
---
# Galaxy Incremental: windows fit phones, boards scroll with the wheel only, phone tap fix (9 Nov, Claude Code)

Prompt: [[2026-11-08 Galaxy Incremental - Prompt - Windows fit phone + board scroll wheel only]].
Owner, 9 Nov: "in mobile, the buttons only works when its held, not when pressed."
Owner said no testing, so only a static self-review was done: the code was read back, the numbers checked and every changed script compiles.
Checklist rows: #138 (updated), #212 (now CHANGED).

## 1. Buttons only worked when held (phone)
**Cause:** `Kit.scroller` (every scrolling list: UPGRADES rows, the TREE, the boards) treated a press as a "drag" when:
- the finger moved 6 design px, which is only ~3-4 screen px once the window is scaled down; or
- the list bounced even 1 px (`ElasticBehavior = Always`).

A normal tap wobbles that much, so the buy button skipped its click. A HOLD still worked, because hold-to-buy fires after 0.4 s, before the finger moves on release.

**Fix (UIKit):**
- A press only counts as a drag after **12 screen px on touch** (6 with a mouse).
- Lists only bounce when they can actually scroll.

Also: the window's invisible layers (the card's VFX layer over the buy button, icon and text holders) are no longer set to sink input (WindowManager). Only visible panels sink input now.

## 2. One fit rule for every window (WindowManager)
- `safe` = the HUD root (DeviceSafeInsets: no notch or home bar) minus Roblox's top-left button row (`Kit.topbar`).
- **Phone scale = min(1, 0.92 x safe width / design width, 0.86 x safe height / design height)**, applied with the window's UIScale. The window is centred in the safe area.
- Recomputed on every ViewportSize change.
- **Phone = short side < 500 px** (`Kit.phone`). PC and tablets keep their old sizes.
- `WM.safeArea`, `WM.phoneScale`, `WM.centre`, `WM.fit`.

**While any window is open on touch:**
- `GuiService.TouchControlsEnabled = false`: the jump button and thumbstick hide, and come back when the last window closes.
- On phones the hotbar and left chips hide (as before). The **stardust counter, LVL and shards counter** hide too, because the window now uses the whole safe area. That one is my call; say if you want the counter kept.

**Windows using it:**

| window | how on a 667x375 phone |
|---|---|
| UPGRADES | new phone layout 600x284, scale 1.0 (360-px Android: 0.96) |
| GUIDE, SETTINGS, CODES, GALAXY (sectors), FORGE, DAILY, RETURN, BLACK HOLE, WHAT'S NEW | whole window fitted (e.g. GUIDE 0.60, FORGE 0.64) |
| STORE, STATS, TREE | box fitted to 0.92 x 0.86 of the safe area, centred; their long lists scroll inside, so text stays readable |

## 3. UPGRADES phone layout (UpgradesPanel, `opts.phone`)
Designed for the phone and drawn 1:1 there, not the PC window shrunk. PC and the island boards are unchanged.
- **Header 45 px:**
  - "UPGRADES" at the left;
  - the ESSENCE pill (icon + number only);
  - X (36 px) at the right.
- **Tab column 152 px:**
  - a ScrollingFrame, so BLACK HOLE is always reachable;
  - each tab is an icon + label;
  - locked tabs show the lock icon + what opens them.
- **Cards 404x92, one list:**
  - LV / LOCKED sits UNDER the icon (no longer on the art);
  - the title shrinks to fit;
  - the description wraps onto 2 lines at 14 px;
  - the chip is 14 px;
  - there's 12 px padding under the last card.
- **Buttons:**
  - every label shrinks to fit (TextScaled + UITextSizeConstraint, min 14);
  - "UNLOCK PLANET" is "UNLOCK" on phones;
  - "+BODY" is 14 px.
- **Hover fix (PC too):** a button now returns to its own size after a hover. The tall +BODY row button used to shrink to 52 px.
- **Tutorial arrow:**
  - it still follows the target button every frame;
  - the target's card is now scrolled into view first, so it never points at a hidden button;
  - not re-parented onto the button, because the list clips its children and would cut the arrow off.
- **Not done:** the cards use fixed positions, not `AutomaticSize` + `UIListLayout` as the prompt said. The result is the same on screen.

## 4. Boards (SurfaceGui lists) scroll with the wheel only
- **All devices:** no drag or click-to-scroll (`ScrollingEnabled = false`, Roblox bar 0).
- **PC:** the mouse wheel over the list scrolls about **one row per notch** (UPGRADES 120 design px; the other boards 90), with a 0.15 s tween, clamped. The thin gold bar shows on PC only.
- **Touch:** one tap opens the board's window; a drag does nothing. GalaxyBoards opens at most once per 0.3 s.
- **Gamepad:** no board scrolling; the window it opens handles that.

## Files changed (in Studio)
- `ReplicatedStorage.Galaxy`: UIKit, WindowManager, UpgradesPanel.
- `StarterPlayerScripts`: GalaxyHUD, GalaxyBoards, GalaxyGuide, GalaxySettings, GalaxyCodes, GalaxyStore, GalaxySectors, GalaxyForge, GalaxyDaily, GalaxyBlackHole, GalaxyLive.
- **Vault copies in `Code/friends-test/` are NOT updated:** Studio couldn't send files to this PC (its HTTP allowlist blocked it). Studio is the up-to-date copy.

## Owner to check (phone)
1. Tap (don't hold) a BUY button in UPGRADES: does it buy once?
2. Does UPGRADES fit with all 4 tabs and no jump button? Is the text readable?
3. Does a tap on a board open its window once? Does a drag do nothing?
4. On PC, does the wheel scroll a board row by row?
