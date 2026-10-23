---
date: 2026-10-06
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Emotes and skate lean did nothing

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Emotes and the skateboard lean had no effect on the character.
- **Cause:** Avatars in this place use Roblox's newer joints (AnimationConstraints); that code only looked for the old Motor6D joints.
- **Fix:** Both joint types now work everywhere.
- **Commit:** 0d13f0c
