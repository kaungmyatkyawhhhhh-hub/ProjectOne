---
date: 2026-10-08
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Machine sign text spilled over its frame

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** On the floating machine sign the text ran over the diamond's frame when the camera looked up or down.
- **Cause:** The text area was not clipped to the turning diamond.
- **Fix:** Content sits in a safe square inside the border, turns with the glass, and text shrinks to fit.
- **Commit:** 674553e

![[GYM ARC/Screenshots/sign_angle_below.jpg]]
![[GYM ARC/Screenshots/sign_angle_above.jpg]]
