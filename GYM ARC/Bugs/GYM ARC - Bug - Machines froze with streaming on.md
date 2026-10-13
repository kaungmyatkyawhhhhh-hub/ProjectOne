---
date: 2026-10-05
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Machines froze with streaming on

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Sometimes tapping did nothing on the bench: the machine never animated.
- **Cause:** With StreamingEnabled, a player's game waited at most 10 seconds for a machine's bar and plates to arrive, then gave up for good.
- **Fix:** Machines, NPCs and the gym cat always stream in whole (Persistent), and the game keeps waiting. (8 Oct: the wait is now timed in a loop so it never hangs either.)
- **Commit:** 9e5aeae
