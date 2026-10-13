---
date: 2026-10-08
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Lag near the gym entrance

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** The game dropped to 22 FPS near the gym door.
- **Cause:** The progress mirror (16 studs from the door) re-set the size of its 14 muscle copies every frame, which made the engine rebuild them.
- **Fix:** Sizes are only set when they change. 60 FPS near the door.
- **Commit:** a61679a
