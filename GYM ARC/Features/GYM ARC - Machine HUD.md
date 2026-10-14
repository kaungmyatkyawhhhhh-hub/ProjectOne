---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Machine HUD

Back to [[00 GYM ARC Home|GYM ARC Home]].

What you see while you are on a machine. Rebuilt on 13 Oct to the owner's v2 mockups (02 / 03): nothing in the middle of the screen any more.

## How it works (13 Oct, v2)
- **Weight panel on the right:** AUTO TRAIN (green AUTO ON when Auto Lift is on; only shown while Auto Lift is for sale), WEIGHT "45 LB", "Tier 1 / 12" in gold (or what the weight needs), - and + buttons, and BEST WEIGHT (the old MAX: buys every next plate you can and picks the heaviest one you can lift). While the weight shown isn't bought yet, UNLOCK with its coin price takes BEST WEIGHT's place.
- **REP and PUMP:** a big red REP circle with your reps ("x13") and a gold PUMP circle beside it at the bottom right. Tap REP (or anywhere) to lift; tapping fast fills PUMP, which brightens and then shows the seconds left while PUMPED.
- **STOP TRAINING:** a red button right above the stamina bar. The jump button or Space also gets you off.
- **Stamina:** the big blue bar at the bottom reads "Stamina 60/100" while you lift.
- **New personal record:** gold "NEW PERSONAL RECORD!" text at the top center with the weight and machine under it.
- **No floating text:** coach lines and tips show one at a time in the top band and fade after 4 seconds. The left menu folds away while you lift.

## Before 13 Oct
- **Machine name** in white just above the panel.
- **Weight selector:** - and + buttons, big weight number, "lb · tier N" under it.
- **MAX button (9 Oct):** directly on top of the + button, same width, 1/3 of its height, yellow background with a soft yellow glow and white text. Buys every next plate you can and selects the heaviest usable one.
- **Barbell graphic:** plates in the current tier's bumper color; they jiggle on heavy reps.
- **Muscles trained:** small muted text under the barbell (with the split in percent); flashes on each rep for the secondary muscles.
- **Stamina:** a chunky 10-segment white bar; soft red under 15%; drained segments flash.
- **Rep counter:** "Reps x12", bounces on increase.
- **Pump bar:** above the panel; fills as you tap.
- **Exit** button (not an X).
- **Coach note:** one small gray line under the panel, 15+ original funny lines, changes at most every few sets.
- Stays low and compact so it never covers the lift.

## Where it lives
- `MachineClient`, `Config/CoachNotes`, `Config/Machines`

## Related
[[GYM ARC - Machines]], [[GYM ARC - Game Feel]], [[GYM ARC - Stats and Muscles Panel]], [[GYM ARC - UI System]]

## Screenshots
![[GYM ARC/Screenshots/max_button_above_plus.jpg]]
![[GYM ARC/Screenshots/s1_bench-hud_after.png]]
![[GYM ARC/Screenshots/full_lifting.png]]

## REP button and PUMP bar (14 Oct)
- REP is a normal red button at the bottom right again ("REP x13"), not the big circle.
- PUMP is a bar again, right above REP: it fills with gold on every rep you tap.
- When the bar is full it stays full, glows and says "TAP TO PUMP!". Tap it (or press Space) for PUMPED: double gains for a few seconds; the bar drains as the time runs out.
- Space with a bar that isn't full still gets you off the machine. Auto Lift pumps by itself when the bar is full.
- Nothing overlaps: the pump bar, REP, STOP TRAINING and the stamina bar each have their own space (phone and PC).
![[GYM ARC/Screenshots/ui_compare_v2_machine_hud_pump_full_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_machine_hud_pump_pc.jpg]]

## Final look (14 Oct)
Weight card top right, PUMP panel under it, big red REP bottom right, quiet STOP bottom left, stamina panel at the bottom. See [[2026-10-14 GYM ARC Final UI Black and Gold]].
![[GYM ARC/Screenshots/ui_compare_final_02_lifting_phone.jpg]]

## Phones (14 Oct)
REP 150 x 52 above Roblox's jump button, PUMP right above it, STOP above the thumbstick, a shorter weight card under the top bar; a level requirement gets its own line. No coach lines on screen.
![[GYM ARC/Screenshots/declutter_lifting_after_phone.jpg]]

## REP never moves (14 Oct, later)
REP (150 x 46) sits right above Roblox's jump button on phones, PUMP right above it, worked out once and only again when the screen size changes. On a PC it sits in the bottom right corner.

## Weight card moved down, BEST WEIGHT button (14 Oct)
- The weight card (machine name, - weight +, Tier, BEST WEIGHT) now sits on the right a bit above the middle of the screen (its centre at 40% of the height, 16 px from the right edge, inside the phone's safe area), no longer stuck under the top bar.
- PUMP and REP stay below it on the right, 10 px apart. On short screens the card shrinks a little (0.9) and only moves up if it still doesn't fit.
- The - and + buttons are always there; at the lightest / heaviest weight they turn grey and do nothing, so the weight stays centred.
- Bodyweight machines showed "+100 LB"; now just "100 LB".
- BEST WEIGHT is a real gold button with an up-arrow icon (no ring), on the same line as "Tier 10 / 12". When you are already on your best weight it turns into a flat dark "AT BEST" with a check and can't be pressed.

![[GYM ARC/Screenshots/panel_crunch_max_atbest.jpg]]
![[GYM ARC/Screenshots/panel_crunch_bestweight.jpg]]
![[GYM ARC/Screenshots/panel_squat.jpg]]
![[GYM ARC/Screenshots/panel_bench_max.jpg]]

