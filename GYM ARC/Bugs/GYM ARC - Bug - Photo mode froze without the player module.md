---
date: 2026-10-13
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Photo mode froze without the player module

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Pressing PHOTO did nothing and the game waited forever.
- **Cause:** Photo mode tried to load Roblox's standard movement module, which this game doesn't use.
- **Fix:** It stops walking the same way the genetics screen does (the movement keys are held back). Found while testing task 7, before release.
- **Commit:** 63d7cd0
