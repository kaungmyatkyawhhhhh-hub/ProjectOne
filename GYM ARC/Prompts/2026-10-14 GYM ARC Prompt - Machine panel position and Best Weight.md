---
date: 2026-10-14
tags: [gymarc, prompt, ui]
status: in progress
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: machine panel position, BEST WEIGHT button (14 Oct)

```text
MACHINE PANEL (exercise name / - weight + / Tier / BEST WEIGHT): move it down. It's stuck at the top right under the top bar.

1. Position: right side, a bit ABOVE the vertical middle of the screen.
   AnchorPoint = (1, 0.5), Position = UDim2.new(1, -(16 + right safe inset), 0.40, 0). Use ScreenInsets = DeviceSafeInsets.
2. The PUMP bar and REP button stay below it on the right with a 10px gap between each. Nothing overlaps the jump button or the stamina bar.
   If the screen is too short for all three (small phones), shrink the panel a little (UIScale 0.9), don't push it back up to the top.
3. Bugs in the same panel:
   - At max tier (12/12) the + button disappears and the layout shifts. Keep + visible but greyed out/disabled, so - and + are always both there and the weight stays centered between them.
   - The weight shows "+100 LB". It should be just "100 LB" (no plus sign).
4. Check on phone 844x390, small phone 667x375 and PC, on 3 machines including Crunch Bench at max tier. Screenshot each.

Commit, update PROGRESS.md and Obsidian.
```

Second message:

```text
MACHINE PANEL - make BEST WEIGHT a real button (right now it looks like a yellow label).
- Use the final kit's gold button: gold gradient fill (#FFF3C4 -> #F6C75A -> #C98A12), dark text (GothamBlack italic), corner 8, dark 2px outline, a thin light top line, a darker bottom lip so it looks pressable. Min 44px tall at phone size (the hit area can be bigger than the visual).
- Add a small icon on the left of the text (an "arrow up to line" or trophy icon from our white line icons, tinted dark).
- Text: "BEST WEIGHT". Press = UIScale 0.94 and bounce back + click sound.
- Layout: bottom row of the panel, Tier "12 / 12" on the left and the BEST WEIGHT button on the right, both vertically centered on the same line.
- States:
  - Already at your best weight: flat dark button, muted text "AT BEST" with a check icon, not clickable.
  - Otherwise: gold and clickable. Tapping it jumps the weight to the best one you can lift.
- No pulse ring on it (only the main CTA gets that).
Screenshot both states. Commit.
```
