---
date: 2026-10-15
tags: [gymarc, bug]
status: fixed
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Bug: the right-side cards covered the top bar buttons

**What happened:** on phones the cards on the right (Drink Shake, Today's Quest, the fold tab) sat over the top bar's Daily, Quests and settings buttons. The grey "MAX GROWTH SPURT · Reached 7'0"" card was also back on the HUD.

**Cause:** the game worked out "just under the top bar" from where the cards were on screen. Right after the game starts that position still reads 0, so the cards were put about 8 px from the top, and on phones nothing measured it again.

**Fix (15 Oct):** the position now comes from the screen layout settings, not from where the cards happen to be, so the cards always start 8 px under the top bar (and the fold tab moves with them). At 7'0" there is no Growth Spurt card on the HUD any more; the top bar's "7'0" MAX" and the Stats panel show it. See [[GYM ARC - UI System]] and [[GYM ARC - Growth Spurts]].

Before:
![[GYM ARC/Screenshots/2026-10-15_hud_before_max_card.jpg]]
After, PC and phone size:
![[GYM ARC/Screenshots/2026-10-15_hud_pc_right_after.jpg]]
![[GYM ARC/Screenshots/2026-10-15_hud_phone_right_after.jpg]]
