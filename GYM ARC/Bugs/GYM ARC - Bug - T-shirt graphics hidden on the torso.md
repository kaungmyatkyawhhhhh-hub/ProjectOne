---
date: 2026-10-07
tags: [gymarc, bug]
status: wont-fix (engine limit)
---
# GYM ARC - Bug - T-shirt graphics hidden on the torso

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** T-shirt graphics don't show on the muscle torso, and muscles wear clothing through a second textured part.
- **Cause:** A game script can't set a SurfaceAppearance image, and other people's clothing images can't be read into an EditableImage.
- **Fix:** Engine limit.
- **Commit:** unknown
