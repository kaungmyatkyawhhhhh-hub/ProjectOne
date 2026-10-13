---
date: 2026-10-04
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Faded labels came back invisible

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** After a prompt faded the Stats labels out, some of them never came back: the muscle names just vanished.
- **Cause:** The fade helper kept each label's normal look in a memory table that Luau throws away when no script holds on to the label, so the look to fade back to was lost.
- **Fix:** The saved look now lives on each label itself (attributes). This fixed fading on every screen in the game.
- **Commit:** 43c29d0
