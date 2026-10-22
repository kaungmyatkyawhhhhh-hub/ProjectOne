---
date: 2026-10-23
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Trainer screens rebuilt to the references

Prompts:
- [[2026-10-23 GYM ARC Prompt - 52 Match the trainer references]]
- [[2026-10-23 GYM ARC Prompt - Next evolution button]]
- [[2026-10-23 GYM ARC Prompt - Remove EVOLVE tag]]
- [[2026-10-23 GYM ARC Prompt - Rounded tier backgrounds]]
- [[2026-10-23 GYM ARC Prompt - Ready glow]]

Game commits cc77592 and 331b96e. Logic, numbers and saves are unchanged.

## What changed
- **Shared tile (`Shared/UI/TrainerTile`):**
  - a 4 px border in the stage or rarity colour with a soft glow;
  - on the Agency, a brighter rarity hex, a burst behind the trainer and slowly turning light rays;
  - LIMITLESS in a rainbow; MYTHIC and ETERNAL in their two colours;
  - a bigger LV / chance.
- **Agency:**
  - one panel: TRAINER AGENCY with a gold underline and 2 x 4 big tiles;
  - under it: the pity pill with a thin teal bar, then ROLL / X3 / AUTO / MY TRAINERS / gear.
  - Removed: keycaps, the price line, "Following".
  - The tiles take the height the screen has.
- **MY TRAINERS:**
  - header: TRAINERS, the EQUIPPED pill (a gold + buys the slot pass while you don't own it), OWNED, EVOLUTIONS;
  - left: 4-wide big tiles, best first (stage, rarity, level);
  - right: big tile, an EXP bar in the stage colour (LV chips at both ends), boost rows with icons, the NEEDS line and mini tiles, EQUIP / UNEQUIP, the next-stage button, the total line.
  - Phones: 2–3 rows, with the detail beside his tile. PC: 4 rows, with the detail stacked like the reference.
- **Next-stage button:**
  - always at full brightness, with its stage effect moving;
  - can evolve: a soft glow breathing behind it and a highlight running round the outline (`Shared/UI/ReadyGlow`, reusable for the alter pill and claim buttons). The EVOLVE! tag is gone. Tapping asks "EVOLVE?" first.
  - can't evolve yet: tapping makes the NEEDS line hop in gold.
- **Evolutions chart:** a gold-edged hex panel titled TRAINER EVOLUTIONS, 5 tiles with arrows, captions in grey italic.
- **Rounded corners:** the tier art never shows square corners. Fixed on the tiles, mini tiles, the big tile, the chart, the next-stage button and the roll reveal cards.
- **Bug fixed:** the detail's slide-in (prompt 54) restored the first trainer's look, which left a dim mini tile at 3/3. It now fades a cover instead. This also fixes the alters detail.

## Needs the owner
- **Glow texture:** uploaded with the owner's OK, no moderation problem: `rbxassetid://130246501630405` (`ClaudeOne/assets/ui/ready_glow.png`, a plain white blurred rounded rectangle, in `Config/UI.ReadyGlow`). The button's edge sits where the glow is ~85% bright, so the halo starts strong and fades over ~22 px.
- **"LV 1" on the next-stage button:** the server keeps the best level of the 3 copies when evolving, so the button shows that level (e.g. LV 18), not LV 1. Should evolving reset to LV 1 instead? That would be a rule change.

## Still differs from the references
- The Agency panel shows your coins (the top bar hides them while a window is open) and has an X. MY TRAINERS is in the button row, not the header.
- Phone MY TRAINERS shows 2–3 rows with the detail beside the big tile (the reference's tall column doesn't fit 390 px).
- The chart and the EVOLVE? box have an X.

## Screenshots (reference, then now)
![[GYM ARC/Screenshots/prompt52/ref_agency.png]]
![[GYM ARC/Screenshots/prompt52/01_agency_844.jpg]]
![[GYM ARC/Screenshots/prompt52/02_agency_844_silhouettes.jpg]]
![[GYM ARC/Screenshots/prompt52/03_agency_pc.jpg]]
![[GYM ARC/Screenshots/prompt52/ref_my_trainers.png]]
![[GYM ARC/Screenshots/prompt52/05_my_pc_limitless_max.jpg]]
![[GYM ARC/Screenshots/prompt52/04_my_844_beastmode_not_ready.jpg]]
![[GYM ARC/Screenshots/prompt52/08_my_667_three_rows.jpg]]
![[GYM ARC/Screenshots/prompt52/ref_evolutions.png]]
![[GYM ARC/Screenshots/prompt52/06_chart_pc.jpg]]
![[GYM ARC/Screenshots/prompt52/07_chart_844.jpg]]

Ready glow (the uploaded texture), faintest, brightest, then a close-up:
![[GYM ARC/Screenshots/prompt52/09_ready_glow_faintest.jpg]]
![[GYM ARC/Screenshots/prompt52/10_ready_glow_brightest.jpg]]
![[GYM ARC/Screenshots/prompt52/13_ready_glow_closeup.png]]

Corners close up:
![[GYM ARC/Screenshots/prompt52/11_closeup_button_corners.png]]
![[GYM ARC/Screenshots/prompt52/12_closeup_tile_corner.png]]

Notes:
- Shot 08 (667x375) is from before the title became TRAINERS and before the side layout's big tile grew to fill the empty space.
- Shot 07 is from before the corner fix.

## Tested
- 844x390, 667x375 and PC (Studio). Covered: the Agency, MY TRAINERS over several pages, BEAST-MODE not ready, ready (the glow), a maxed LIMITLESS, the chart, EVOLVE? then a real evolve (it worked), the NEEDS hop.
- No script errors; the tests pass.

## Not tested
- The motion by eye (the glow's breathing was checked by its numbers).
- A real phone.
