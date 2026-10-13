---
date: 2026-10-08
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Infinite wait for machine Plates

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Output was full of "Infinite yield ... Plates" warnings.
- **Cause:** Seen while playing a local file copy (no save system, so the server never started and never made the plates); the client also waited forever.
- **Fix:** MachineClient never waits forever: timed waits in a loop, and each machine sets up once its parts exist.
- **Commit:** de4c285
