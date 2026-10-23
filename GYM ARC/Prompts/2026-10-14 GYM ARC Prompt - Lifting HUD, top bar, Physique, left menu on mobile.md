---
date: 2026-10-14
tags: [gymarc, prompt]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: lifting HUD, top bar, Physique and left menu on mobile (14 Oct)
Three messages sent while the loading screen was being rebuilt.

```text
LIFTING HUD FIXES (mobile):
1. REP button is too big and covers Roblox's mobile jump button.
   - Make it smaller: about 150x52 on phone (was ~200x70), text size down to match (REP ~24, xN ~14).
   - Keep it OUT of the jump button area. Roblox's jump button sits bottom-right (roughly the bottom-right 170x170 px on phone). Place REP just above/left of that zone: anchor bottom-right, Position offset about (-12, -150) on touch devices. Read the real jump button position from PlayerGui.TouchGui.TouchControlFrame.JumpButton if it exists and place REP above it with 10px gap. On PC/console keep it bottom-right.
   - PUMP bar sits directly above REP, same width.
   - Weight card goes up so nothing overlaps (it can be a bit shorter).
2. Stamina bar: anchored to the very bottom center (10px from the edge), max 280px wide on phone, slimmer. It must not overlap STOP, REP or the jump button.
3. Weight card: the "Needs Lower Back 35..." text overlaps "BEST WEIGHT". Put the requirement on its own line (small gray, truncate with ...) and BEST WEIGHT on the line under it, or hide the requirement when the weight is usable.
4. Remove the floating hint text "Reps go on their own. Tap fast to make that bar nervous." (or show it once for 3 s as a small pill under the top bar, first time only).
5. STOP stays bottom-left, above the thumbstick area on mobile (not overlapping the move stick).
Test on phone 844x390 and a small phone 667x375 with the touch controls visible: REP, PUMP, STOP, stamina and the jump button all reachable and not overlapping. Screenshot, commit, update PROGRESS.md and Obsidian.
```

```text
MOBILE FIXES (top bar + Physique):

1. TOP BAR must line up with Roblox's own top-left buttons (Roblox logo, menu, chat):
   - Use GuiService.TopbarInset (and listen to its Changed signal) instead of hardcoded positions. Our chips must have the SAME height as Roblox's buttons and be vertically centered on the same line: Size Y = TopbarInset.Height, Position Y = TopbarInset.Min.Y (ScreenGui IgnoreGuiInset = true so the math matches).
   - Start our left chips right after TopbarInset.Min.X + 8px (never under Roblox's buttons), right group ends 8px before the screen edge (and before Roblox's right-side buttons if any).
   - Same corner radius as Roblox's buttons (fully round pills), same gap (8px) between every chip. All chips in one UIListLayout (Horizontal, VerticalAlignment Center) so they can't drift.
   - On small phones, hide the least important chip first (height chip -> level bar) instead of shrinking text.
   - Anything under the top bar (Posing Competition card, quest card, zone messages) starts at TopbarInset.Max.Y + 8px so it never touches the top bar.

2. PHYSIQUE PANEL:
   - Opening any panel hides/collapses the left menu (it currently overlaps the panel on mobile).
   - Panel uses UIScale + max size so it fits 844x390 and 667x375 fully, centered, with the soft blur behind.
   - BUG: every muscle shows 100% but grades are B / A / S / C and the total says 12%. The bars, %, grades and total must come from the same numbers: % = that group's progress to max look, grade from that % (S >= 90, A >= 75, B >= 55, C >= 35, D below), total = average of the groups. Check where 100% comes from (probably clamped or wrong max) and fix it.
   - Bar color follows the grade (S red, A gold, B teal, C steel, D dark gray) like the mockup 07_physique.png.
   - The "LABELS OFF" toggle: move it inside the body diagram corner (small icon button), not in the tab row.
   - Grade plates and names must line up in one column; use a UIListLayout with fixed row height.
Test phone 844x390, small phone 667x375, PC. Screenshot, commit, update PROGRESS.md and Obsidian.
```

```text
LEFT MENU POSITION (still wrong): the left menu tiles must be centered vertically on the LEFT MIDDLE of the screen, not at the top-left.
- Menu container: AnchorPoint = (0, 0.5), Position = UDim2.new(0, 12 + safe-area left inset, 0.5, 0). Do NOT add any fixed top offset.
- If something else (a script, the collapse tween, or a UIListLayout on the parent) moves it to the top, fix that: the collapse/expand tween must only change the X position, never Y.
- The "<" collapse tab stays attached to the right edge of the menu, also vertically centered.
- Use ScreenGui.ScreenInsets = DeviceSafeInsets (or GuiService:GetGuiInset) so it's centered in the visible area on phones with notches.
- The center of the menu must equal the center of the screen height on phone (844x390, 667x375) and PC. Screenshot to prove it, commit.
```
