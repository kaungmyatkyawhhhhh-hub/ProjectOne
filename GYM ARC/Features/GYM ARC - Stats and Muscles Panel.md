---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Stats and Muscles Panel

Back to [[00 GYM ARC Home|GYM ARC Home]].

Three ways to see your stats: labels floating around your character, the full "Your muscles" panel, and a small body-map widget while lifting.

## How it works
- **Stats labels (Stats tile):** toggles small labels around your character in the world. Hidden by default.
  - Strength (all muscle levels added) and Stamina above the head; Chest, Core, Legs on one side, Shoulders, Back, Arms on the other.
  - Thin white lines to dots on the body; dark see-through box, white name, light blue-white number with commas.
  - Same size on screen at any distance, never behind walls, never over a machine prompt.
  - They lean a little with the camera's turn speed (faked in 2D so text stays sharp; none with Reduced Motion).
  - Hovering a label tints those muscles red on your body (only the ones facing the camera).
- **Muscles button:** appears at the bottom center while labels are shown; opens the panel.
- **"Your muscles" panel:** Growth Spurt bar + height + "x/6 groups at level y", six group cards (grade badge, EXP, genetics multiplier, each muscle with a bar, the machines that train it). "Needs work" in soft red on the weakest group. Close with X, Esc or a tap outside. At 7'0" the button reads "MAX GROWTH SPURT REACHED".
- **Body-map widget (on a machine):** slides in at the right with front and back silhouettes made of muscle shapes, glowing by level; the trained muscles pulse and flash warm each rep. A "-" folds it into a chip. Tapping it opens the panel. Shows "Max" at the height cap.
- **Phones:** labels step aside while lifting on short screens; the widget shows the stats then.

## Where it lives
- `StatsClient`, `StatsLabelsClient`, `BodyMapClient`, `Shared/UI/BodyFigure`
- `MuscleRig.SetHighlight` (red hover tint)

## Related
[[GYM ARC - Muscles and Bodies]], [[GYM ARC - Growth Spurts]], [[GYM ARC - UI System]], [[GYM ARC - Machine HUD]]

## Screenshots
![[GYM ARC/Screenshots/stats_final_labels-on_idle.png]]
![[GYM ARC/Screenshots/stats_final_muscles-panel.png]]
![[GYM ARC/Screenshots/stats_final_on-machine_widget-and-labels.png]]
![[GYM ARC/Screenshots/v9_hover_highlight_chest.png]]

## Physique fix (14 Oct)
- Each group's %, its grade and its bar now come from the same number: how close that group's muscles are to the full look. Grades: S 90%+, A 75%+, B 55%+, C 35%+, D below. Bar colors: S red, A gold, B teal, C steel, D dark gray.
- The big number on the body card is the average of the six groups.
- The LABELS switch is now a small eye button in the corner of the body card (gold while the labels show).
- The left menu slides away while the window is open, so it never covers it on a phone.
See [[GYM ARC - Bug - Physique numbers did not match]].
![[GYM ARC/Screenshots/declutter_physique_phone.jpg]]
Small phone:
![[GYM ARC/Screenshots/declutter_physique_small_phone.jpg]]
