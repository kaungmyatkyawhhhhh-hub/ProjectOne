---
date: 2026-10-23
tags: [gymarc, progress, hud]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Active boost tiles half size (prompt 59)

Prompt: [[2026-10-23 GYM ARC Prompt - 59 Active boost tiles half size]]

Game commit 49d7afd (`ActiveBoostsClient`, `SIZE = 0.5` at the top).

## What changed
- **Half size:** the bottom-left active boost tiles are half their old size (50 -> 25 mockup px).
  - The icon, corner, outline, hover glow, lift and the gap between tiles (6 -> 3) scale with them.
  - Same bottom-left spot.
- **Timer:** 13 -> 6.5 would be too small, so it stays at the HUD's smallest label (11). It measured 12.7 px on the test window.
- **"x2" tag:** it can't go under the game's 10 px text minimum (`Theme.MinTextSize`). So it is as small as that allows: 16x11 (was 22x14), with a thinner text outline.
- **"+3" tile:** half size, its number at 11.
- **Tap area:** each tile has an invisible tap / hover area of at least 32 px on screen (measured 32 px). It reaches a little past the small gap.
- **Info card:** the same size; it sits lower to follow the smaller tiles.
- **Outline:** the tiles keep the plain HUD outline from prompt 58 (the brief said "gold outline"; it was taken off in prompt 58, and chrome has no gold borders). Switching it back is one word.

## Tested (Studio, phone layout 844x390)
- Rush Hour, Server Boost, Endless Stamina and a Coconut Water x3 (the drink timer was set on the client only, for the test view). Shown in the screenshot.
- The tap area is the top element at the tile: nothing covers it.

## Not tested
- The hover / tap info card by eye: Studio's test mouse doesn't fire hover, and a click after a hover closes the card again. Its code is unchanged.
- **Timer spacing:** two long timers side by side ("24:59" next to "14:59") come very close, because the timers are wider than the half-size tiles.

![[GYM ARC/Screenshots/prompt59/01_boost_tiles_half.jpg]]
