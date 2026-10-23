---
date: 2026-10-07
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Muscle spikes and speckled skin

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Muscles had spikes along their borders, tucked inside the body at level 0, and showed a grainy speckle.
- **Cause:** Border points grew with only one muscle; the Plastic material's grain followed the clothing pattern.
- **Fix:** Border points grow with the average of the muscles that share them, muscles at 0 lie flat on the skin, parts use SmoothPlastic.
- **Commit:** e27ebe7
