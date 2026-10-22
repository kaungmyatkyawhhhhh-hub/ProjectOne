---
date: 2026-10-23
tags: [gymarc, progress, trainers, hud]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Roll card side layout and NEXT pill outline (prompt 57)

Prompt: [[2026-10-23 GYM ARC Prompt - 57 Roll card side layout and NEXT pill outline]]

Game commit b8b7bf0.

## What changed
- **Roll card on phones:** when the stacked card would show under 90% of its size, it turns sideways: the picture on the left, and the rarity, NAME, stat rows and dupe line in a column on the right (`Config/RollReveal.Side`). Desktop keeps the stacked card.
  - One card is 400 wide. An X3 shares the row (260 each on 844x390).
  - The picture's faint backdrop fades out at its right edge, so no hard line shows.
- **Text floor:** no word on any roll card (phone or desktop) is smaller than the HUD's smallest label (11) once the card's scale is applied.
  - The "ready to evolve" dupe line is shorter so it fits at that size: "X3 · READY: IRON-BORN" (it was "X3 · READY: EVOLVE TO IRON-BORN").
- **Settings labels:** kept non-italic (your change), and they stay in GitHub.
- **NEXT alter pill (HUD):**
  - The thick gold outline is gone. It now uses the same outline as the other HUD cards (1.5 px, solid), tinted in the next alter's colour: steel blue for SHREDDED, red for PUMPED.
  - READY: that outline does the ready glow (the evolve button's glow component). A soft glow breathes behind the pill and a highlight runs round the outline, still in the alter's colour.
- **SHREDDED pill art:** the art did fill the whole pill, but it is dark steel with thin blades only near the edges, so the black shade hid it. SHREDDED now gets a lighter shade and a light wash of its steel blue (`AlterThemes` `pillShade` / `pillWash`, per alter). PUMPED is unchanged.

## Tested (Studio, phone layout 844x390)
- **Single side card:** The Shadow showed at 124% (it was ~70%); the smallest text measured 13.7 (floor 11).
- **X3 side cards:** all at 100%, smallest text exactly 11.
- **NEW single card:** Coach Lou, from the group welcome gift's free roll.
- **PUMPED READY pill:** a fresh test player at 7'0". Red outline and red glow, no gold.
- **SHREDDED pill (your account):** steel-blue outline; the art before and after the fix is in shots 02 and 03.
- No script errors; the logic tests pass.

## Not tested
- PUMPED while still progressing (not ready). Only its READY state was on screen; same outline code.
- 667x375 and tablet.
- **Test player:** the fresh test player is set up with Studio switches; they were all removed afterwards.

![[GYM ARC/Screenshots/prompt57/01_pumped_ready_pill.jpg]]
![[GYM ARC/Screenshots/prompt57/02_shredded_pill_before.jpg]]
![[GYM ARC/Screenshots/prompt57/03_shredded_pill_after.jpg]]
![[GYM ARC/Screenshots/prompt57/04_side_card_shadow_phone.jpg]]
![[GYM ARC/Screenshots/prompt57/05_side_x3_phone.jpg]]
![[GYM ARC/Screenshots/prompt57/06_side_card_new_lou.jpg]]
