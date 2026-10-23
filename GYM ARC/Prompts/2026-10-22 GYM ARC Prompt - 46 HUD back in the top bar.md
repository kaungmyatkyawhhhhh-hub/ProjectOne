---
date: 2026-10-22
tags: [gymarc, prompt]
status: done
---
# 46 HUD back in the top bar

Back to [[00 GYM ARC Home|GYM ARC Home]] - replaces the "top bar: coins only" part of [[2026-10-22 GYM ARC Prompt - 43 HUD top bar cleanup]]

```text
HUD fix (owner): the right-side column looks bad. Put these back in the TOP BAR, like the HUD mockup C:\Users\kaung\Downloads\gym_arc_ui_style_match\05_hud_dark_chunky.png. This replaces the earlier "topbar: coins only" change. Never undo the owner's manual Studio changes.

TOP BAR (one row, same dark graphite pill style + gold outline, same height):
- Left of centre: COINS pill, then the LVL pill ("LVL 52 · 4'6"" with the small gold EXP bar). Move LVL out of the bottom-left corner.
- Right side, in this order: POSING SHOW pill ("POSING SHOW 0:27" + a small gold JOIN button inside the pill), DAILY pill (calendar icon + "DAILY", red "!" chip in the corner when there's a reward), SETTINGS gear (moved from the bottom-left).
- When no posing show is starting soon, the POSING SHOW pill is hidden and the others slide over (no gap).

RIGHT SIDE (under the top bar): only TODAY'S QUEST, then TAP TO GROW under it. Nothing else stacked there.

LEFT NAV: keep as it is now (2 columns, locks and badges). Remove the empty space the gear and LVL left behind.

Phones (667x375): the top bar must fit in one row. If it doesn't fit, shorten the posing pill to "SHOW 0:27" + JOIN. Nothing may overlap the left nav or the quest card.

TEST: screenshots at 1920x1080 and 667x375, with and without a posing show coming up. Short progress note in the vault.
```
