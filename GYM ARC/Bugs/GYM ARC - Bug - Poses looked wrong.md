---
date: 2026-10-07
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Poses looked wrong

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Posing stage poses (Most Muscular, Double Biceps, Side Chest, Abs and Thigh) looked off: limbs half in the walk animation.
- **Cause:** Roblox's default animation kept playing on top of the pose, and joints not listed in a pose were left wherever they were.
- **Fix:** The default animation is paused while posing and every joint is written each frame. Poses retuned against the reference picture.
- **Commit:** 80817cd

![[GYM ARC/Screenshots/poses_FrontDoubleBiceps.png]]
![[GYM ARC/Screenshots/poses_fixed_FrontDoubleBiceps.png]]
