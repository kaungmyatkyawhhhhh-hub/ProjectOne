---
date: 2026-10-05
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Gain popup covered the bar and face

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** The "+12" gain popup could appear over the barbell or the lifter's face.
- **Cause:** The popup spot did not know the bar's path.
- **Fix:** The popup picks a spot beside the chest that misses the head and the bar's whole path (recorded from rack to bottom of the rep).
- **Commit:** 9e5aeae

![[GYM ARC/Screenshots/exp_popup.png]]
