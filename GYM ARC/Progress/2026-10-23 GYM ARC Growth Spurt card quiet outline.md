---
date: 2026-10-23
tags: [gymarc, progress, hud]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Growth Spurt card quiet outline (prompt 58)

Prompt: [[2026-10-23 GYM ARC Prompt - 58 Growth Spurt card quiet outline]]

Game commit 20bd0a2.

## What changed
- **GROWTH SPURT card (right column):**
  - The thick gold outline is gone. It has the same outline as the other HUD cards (1.5 px, solid), tinted in one Growth Spurt colour: the gold of the TAP TO GROW button (`GROW_ACCENT` in ProgressClient).
  - **READY:** it stays the same dark card, only taller. "TAP TO GROW" is in gold and "GROWTH SPURT 2 READY" sits under it.
  - The outline does the pulsing glow (the evolve button's glow component, `Shared/UI/ReadyGlow`) in that gold. The loud gold button with its scale pulse is gone.
- **Machine strip** (the same card shown at the top left while on a machine): the same treatment.
  - It's now a quiet card with its outline in gold, or in the next alter's colour.
  - READY: "TAP TO GROW" / "ALTER NOW" in that colour, and the outline glows. It used to turn into the gold button, and it had a thin gold inner line.
- **Other gold outlines removed from the HUD:**
  - The offer card at the bottom (2 px gold).
  - The "Added to inventory" toast (2 px gold).
  - The Active Boosts tiles at the bottom left (thin gold edge, and the "+3" tile).
  - They all use the plain HUD outline now.
  - Checked in play: no visible HUD element has a gold outline.
- **Fixed on the way:** the glow sat at the same layer as the card and drew a gold wash over it (it made the card look gold-brown). The card is now one layer above its glow. This applies to the NEXT alter pill too.
- **Not changed** (not HUD cards): the READY TO GROW popup's 3 px gold border, the Daily window's DNA day, the Stats window's highlight, the hotbar's held-item ring (a selection mark), and world signs.

## Tested (Studio, phone layout 844x390, fresh test player)
- **Growth Spurt 2 at 51%:** gold-tinted thin outline, the same thickness as Today's Quest.
- **READY:**
  - First try: "TAP TO..." was cut off and the card was washed gold. Both fixed: the text is measured again after the quiet style changes its font, and the glow layer was fixed.
  - After: a dark card, the full "TAP TO GROW" in gold, and a soft gold glow (measured breathing 0.39 to 0.7).
- **Machine strip (ready):** checked by its settings only (gold title, outline highlight on). It shows only on a machine.
- No script errors; the logic tests pass. The test switches were removed.

## Not tested
- The Active Boosts tiles, offer card and toast on screen. The fresh player had none; it's a one-line colour change each.
- 667x375 and tablet.
- **Screenshot blur:** the blurred world in shots 02 and 03 is only from hiding the READY TO GROW popup for the test.

![[GYM ARC/Screenshots/prompt58/01_growth_spurt_progress.jpg]]
![[GYM ARC/Screenshots/prompt58/02_ready_before_fix.jpg]]
![[GYM ARC/Screenshots/prompt58/03_ready_glow.jpg]]
