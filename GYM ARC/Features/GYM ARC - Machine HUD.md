---
date: 2026-10-09
tags: [gymarc, feature]
status: done
---
# GYM ARC - Machine HUD

Back to [[00 GYM ARC Home|GYM ARC Home]].

The compact panel that slides up while you are on a machine.

## How it works
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
