---
date: 2026-10-09
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Low FPS from shadow-casting gym lights

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** The owner's PC ran at about 20 FPS in the gyms after the lighting pass.
- **Cause:** 14 lights cast shadows.
- **Fix:** Only 4 lights cast shadows now; arm wrestling animation only runs near the camera.
- **Commit:** 77e3238

![[GYM ARC/Screenshots/lighting_after_starter.jpg]]
