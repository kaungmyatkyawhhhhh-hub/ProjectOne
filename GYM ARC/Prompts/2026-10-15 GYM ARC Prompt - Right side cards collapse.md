---
date: 2026-10-15
tags: [gymarc, prompt, ui]
status: queued
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: right-side cards collapse like the left menu (15 Oct)

```text
RIGHT-SIDE CARDS (Drink Shake card + Today's Quest card): make them collapse and expand like the left menu, mirrored.

- Put both cards in one container on the right. Add a small tab on its LEFT edge, same style as the left menu's collapse tab (graphite, gold chevron), vertically centered on the cards.
- Tap the tab: the container slides right until only the tab is left at the screen edge (tween X only, 0.25s Quad Out, same as the left menu). Chevron points left when collapsed, right when expanded.
- Collapsed: if a quest finishes or something is ready to claim, show a small red notice dot on the tab and pulse it once.
- Remember the state for the session (and save it in settings so it stays after rejoin).
- Auto-collapse while on a machine if it would overlap the machine panel; restore the previous state after leaving.
- Keep inside the safe area, never covering the top bar or the leaderboard. Touch target at least 44px.
Test on phone 844x390 and PC, expanded and collapsed. Screenshot. Commit.
```
