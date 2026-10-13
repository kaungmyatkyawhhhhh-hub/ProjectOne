---
date: 2026-10-06
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Floating arms on the mirror Day one body

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** The progress mirror's "Day one" body had arms floating away from the torso.
- **Cause:** The bodies were assembled by hand on the client and the avatar used Roblox's newer joints (AnimationConstraints), which the code did not understand.
- **Fix:** Both mirror bodies are real rigs built on the server from your avatar's description, sized and shaped properly.
- **Commit:** 0d13f0c

![[GYM ARC/Screenshots/s1_mirror-screen_before.png]]
![[GYM ARC/Screenshots/s1_mirror-screen_after.png]]
