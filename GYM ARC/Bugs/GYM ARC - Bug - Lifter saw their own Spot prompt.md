---
date: 2026-10-05
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Lifter saw their own Spot prompt

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** On the Squat Rack or Flat Bench, Stats faded out 4 of the 6 labels for no visible reason.
- **Cause:** Your own "Spot - help them lift" prompt was still active behind the machine panel, and the labels moved out of its way.
- **Fix:** The lifter's own machine prompts are switched off on their screen. Other players still see Spot.
- **Commit:** fb99f0b
