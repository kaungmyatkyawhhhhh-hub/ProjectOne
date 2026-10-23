---
date: 2026-10-14
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Stats lines pointed at the wrong places

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** the stats labels' lines (Chest, Shoulders, Back, Core, Arms, Legs) ended beside the body instead of on it.
- **Cause:** on phones with screen insets the full-screen layer is bigger than the 3D view, so every point was shifted up and to the left; the points were also smoothed and set a little off-centre.
- **Fix:** the drawing layer is placed exactly over the 3D view each frame, each line ends on the exact body point every frame (on the muscle's surface), and the labels are grouped by side (Shoulders, Chest, Arms left; Back, Core, Legs right). Standing still with the labels open turns you to face the camera.
