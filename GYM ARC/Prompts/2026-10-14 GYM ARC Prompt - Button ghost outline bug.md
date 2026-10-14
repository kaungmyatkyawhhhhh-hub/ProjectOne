---
date: 2026-10-14
tags: [gymarc, prompt, bug, ui]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: ghost outline on gold/red buttons (14 Oct)

```text
BUG: every gold/red button has a misaligned ghost outline/highlight sticking out above-left of it (arm wrestle opponent cards, PASSES/MUSCLES tabs, EQUIP buttons, ALL tab). Fix it once in the shared Button component so every screen is fixed.

1. Find the extra layers inside the button (pulse ring / glow / shine / inner line / bottom lip). For EVERY layer:
   - AnchorPoint = (0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5).
   - Size relative to the button: UDim2.new(1, extra, 1, extra). Inner line/shine: (1,-4,1,-4). Glow ring: (1,6,1,6).
   - Same UICorner radius as the button (+ extra/2 for the ring), so the corners match.
   - Shine stays inside the button (put it in a ClipsDescendants frame with the same UICorner, or use a UIGradient on the button itself).
2. Animations:
   - Press and pulse use a UIScale on the button (scales from the center), never by tweening Size or Position.
   - The pulse ring tweens its own UIScale/transparency from the center.
   - Pulse ONLY on the single main CTA of a screen (e.g. KEEP, BUY, PLAY). Remove it from tabs, EQUIP buttons, opponent cards and anything with many copies.
3. Tabs (PASSES, MUSCLES, ALL/OWNED): active tab = gold fill only, no ring.
4. Check text is vertically centered in every button (TextYAlignment Center, no leftover offset), and the button rows line up (UIListLayout/UIGridLayout with the same padding, VerticalAlignment Center).
5. Arm wrestling opponent cards: all 4 cards the same size and height, text centered, Coral (Rival) uses the same card style as the others, and STAND UP is centered under the row.

Screenshot at 844x390 and PC: arm wrestle picker, Store tabs, Titles, Stats tabs, Quests, Genetics. No ring or highlight should stick out of any button. Commit, update PROGRESS.md and Obsidian.
```
