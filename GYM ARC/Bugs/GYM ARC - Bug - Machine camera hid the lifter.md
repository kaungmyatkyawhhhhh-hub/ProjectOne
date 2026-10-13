---
date: 2026-10-05
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Machine camera hid the lifter

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Getting on a machine kept your walking camera angle, e.g. behind the squat rack's plates with the lifter hidden.
- **Cause:** Nothing turned the camera when you sat down.
- **Fix:** The camera turns once to a 3/4 view from the open side of the room (you can still rotate it).
- **Commit:** fb99f0b
