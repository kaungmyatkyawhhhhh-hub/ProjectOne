---
date: 2026-10-07
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Obliques never grew

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** The obliques and serratus never showed on anyone.
- **Cause:** Only the pro gym's Cable Woodchop trained Obliques, so the stat stayed at 0 until Growth Spurt 2.
- **Fix:** The Crunch Bench trains Obliques too (secondary), so they grow from the start.
- **Commit:** adda7fc

![[GYM ARC/Screenshots/obliques_test.png]]
