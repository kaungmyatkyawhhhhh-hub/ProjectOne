---
date: 2026-10-23
tags: [gymarc, progress, ui, tutorial]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Tutorial restyle and screen cleanup

Prompts:
- [[2026-10-23 GYM ARC Prompt - 52 Tutorial restyle|52 Tutorial restyle]]
- [[2026-10-23 GYM ARC Prompt - 53 Tutorial and toast cleanup|53 Tutorial and toast cleanup]]
- [[2026-10-23 GYM ARC Prompt - Coach dialog spacing|Coach dialog spacing]]
- [[2026-10-23 GYM ARC Prompt - Machine controls equal width|Machine controls equal width]]
- [[2026-10-23 GYM ARC Prompt - SHOP never locked|SHOP never locked]]

Features: [[GYM ARC - Tutorial]], [[GYM ARC - Unlock Guides]], [[GYM ARC - Machine HUD]]. Game commit e47e859.

The tutorial's steps and rewards are unchanged; only the look and where things sit.

## Coach Dex dialog (shared with the unlock guides)
- **Box:** dark graphite with the hex mesh, a thin gold outline and a thick dark bottom edge. It is ~55% of the screen wide, centred at the bottom and clear of the left nav. Its height fits its words.
- **Inside (12 px padding):**
  - the live portrait of the new Coach Dex in a gold frame, on the light backdrop of `tutorial2.png`;
  - "COACH DEX" in gold chunky, with the gold "+50" coin pill on the same row at the top right (the words start below it, so they never run under it);
  - the words in the second font (Montserrat Bold, sentence case, white, 1.2 line height);
  - "Tap to continue (1/2)" small and grey at the bottom right.
- **Not done:** a still picture of Coach Dex. No uploaded Dex picture exists; the portrait in `tutorial2.png` is this live portrait. A new picture would need an upload, so it needs your OK.

## Around it
- **GO TO:** a normal-size gold ChunkyButton at the bottom centre, 12 px above the dialog (or above the hotbar / stamina bar when there's no dialog). Never over the character. It still teleports (fade, whoosh, 3 s cooldown).
- **SKIP:** one small dark pill, always in the same spot: just under the top bar on the right, left of the machine controls, on and off machines. The first tap turns it gold, "TAP AGAIN TO SKIP"; the second skips. The unlock guides use the same pill (one tap there, as before).
- **Step band:** a dark pill with white chunky text at the top centre. It wraps to two lines instead of running into SKIP.
- **Buttons the step needs** (the shake slot, STOP, Stats, Muscles): the rest of the screen dims, the button gets a pulsing gold glow and a bouncing gold arrow with a word ("TAP STOP"). The unlock guides point at their tile the same way.
- **World marker:** the target's name in gold chunky, the distance ("4m"), a gold diamond and chevron. It stays below the top bar, and hides when you're right next to the target (the machine's own sign is there).
- **Only the tutorial on screen:** while it runs, these hide:
  - the right column (Growth Spurt card)
  - DAILY and settings (coins and LVL stay)
  - the quest card
  - the boosts row
  - the Growth Spurt strip on machines

  The left nav and the machine controls stay. Everything fades back when the tutorial ends.
- The white hand in your phone screenshot is Studio's touch-emulation cursor, not part of the game.

## Toasts (every toast in the game)
- **One toast lane** at the top centre, just under the top bar (under the step band). Toasts queue and show one at a time for ~2.5 s, sliding down and fading out. Never in the middle of the screen.
- **Rewards too:** NEW WEIGHT UNLOCKED, LVL UP, NEW TITLE and the rest use the same lane (they keep their sound; a newer LVL UP replaces one still waiting).
- **New card:** dark graphite with hex, a thin gold outline and a dark bottom edge. The icon sits on its own (no box), the title is white stroked chunky, and the second line is small light grey. A long one-line toast wraps onto two lines.

## On a machine
- **"Set done":** now a small line like "+80.5K CHEST" (BIG REP in gold) that rises beside the REP button and fades. It never covers a button or a toast.
- **Your title:** your own overhead title (and ALTER pill) hides while you're on a machine. Others still see it.
- **Machine controls:** the weight card, AUTO TRAIN, PUMP and REP are now one width (REP's), with the same edges, 8 px gaps and 12 px corners.
  - The weight card keeps its own layout (- and + at the ends, the weight in the middle), scaled to that width, with its gold line as thick as PUMP's.
  - Fits 667x375 under the top bar.

## SHOP never locked
- SHOP is open from the first join: no padlock, no NEW badge, no "Unlocks at Growth Spurt 1" toast, no unlock guide.
- Every Store tab works. No Store tab had a lock.
- The "no purchase popups in the first 5 minutes" rule stays.
- The rule is now written in `docs/DESIGN.md` and `CLAUDE.md`.

## Layout rule (now in CLAUDE.md)
- **Top bar:** coins / LVL / daily / settings.
- **Under it on the right:** SKIP.
- **Top centre:** the toast lane.
- **Bottom centre:** GO TO / Coach Dex dialog / stamina.
- **Right side:** machine controls.
- **Left:** left nav.
- **Middle of the screen:** nothing except the world marker.

## Tested (Studio, temporary save; 667x375, then desktop)
- **667x375:** the first step, the GO TO step, the bench with a NEW TITLE toast, LVL UP + TAP STOP, set done, the shake step, a long toast wrapping, SHOP opening on the first frame.
- **Desktop:** the first step with the marker, TAP STOP + set done, SKIP armed (gold) then a skip, an unlock guide (Genetics) with the new dialog and the Spotlight on its tile.
- The marker was checked with a test-only switch: Studio's screenshot tool doesn't draw "always on top" billboards.
- No script errors. The game tests pass.

## Needs your decision
- **The shake step on a machine:** the hotbar (where the shake sits) hides on machines, so there's nothing to tap and the 15 s safety net drinks the shake for the player. Making the shake usable on a machine changes the steps, which this brief ruled out. Tell me if you want it.
- **A Coach Dex still picture:** only if you want one (an upload; I'd ask first).

## Before / after
![[GYM ARC/Screenshots/ui_v3/tutorial/before_01_goto_phone.png]]
![[GYM ARC/Screenshots/ui_v3/tutorial/phone_01_first_step.jpg]]
![[GYM ARC/Screenshots/ui_v3/tutorial/before_02_goto_desktop.png]]
![[GYM ARC/Screenshots/ui_v3/tutorial/desktop_01_first_step_marker.jpg]]
![[GYM ARC/Screenshots/ui_v3/tutorial/before_03_new_weight_toast.png]]
![[GYM ARC/Screenshots/ui_v3/tutorial/phone_02_bench_toast_stack.jpg]]
![[GYM ARC/Screenshots/ui_v3/tutorial/before_04_lvlup_setdone.png]]
![[GYM ARC/Screenshots/ui_v3/tutorial/phone_03_set_done.jpg]]
![[GYM ARC/Screenshots/ui_v3/tutorial/phone_04_tap_stop_lvl_up.jpg]]
![[GYM ARC/Screenshots/ui_v3/tutorial/phone_05_shake_step.jpg]]
![[GYM ARC/Screenshots/ui_v3/tutorial/phone_06_long_toast_wraps.jpg]]
![[GYM ARC/Screenshots/ui_v3/tutorial/phone_07_shop_open_first_join.jpg]]
![[GYM ARC/Screenshots/ui_v3/tutorial/desktop_02_tap_stop_set_done.jpg]]
![[GYM ARC/Screenshots/ui_v3/tutorial/desktop_03_skip_armed.jpg]]
![[GYM ARC/Screenshots/ui_v3/tutorial/desktop_04_unlock_guide_dialog.jpg]]
![[GYM ARC/Screenshots/ui_v3/tutorial/desktop_05_unlock_guide_spotlight.jpg]]
