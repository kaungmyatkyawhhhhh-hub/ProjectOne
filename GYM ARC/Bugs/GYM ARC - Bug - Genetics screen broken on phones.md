---
date: 2026-10-14
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Genetics screen broken on phones

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** On a phone the genetics screen was spread over the whole screen: the group names ran into each other ("ShoulBacArmLegChestCore"), the multipliers overlapped ("x1.5x1.5..."), and KEEP and "DNA tokens" were cut off at the right edge.
- **Cause:** The labels were placed under 3D plates on the screen and shrunk to fit; on a small screen there wasn't room.
- **Fix:** The screen is now one centered panel that always fits (at most 600 wide, scaled to the screen), with fixed rows so nothing can overlap. See [[GYM ARC - Genetics]].
