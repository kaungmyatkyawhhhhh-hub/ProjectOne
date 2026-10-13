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
