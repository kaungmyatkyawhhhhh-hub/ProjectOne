---
date: 2026-10-08
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Highlight flickered on hover

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Hovering a stat label made the red muscle highlight flicker.
- **Cause:** Once fully on, the highlight dipped and climbed back every frame (a fade-out step ran when it should not).
- **Fix:** Fixed the fade, added a short grace time and a bigger hit area; the hovered label stays put.
- **Commit:** 9da5fb0

![[GYM ARC/Screenshots/hover2_chest_steady.png]]
