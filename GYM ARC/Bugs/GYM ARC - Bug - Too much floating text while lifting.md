---
date: 2026-10-13
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Too much floating text while lifting

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Several texts floated over the lift at once (the coach line, "Tap to pump (click or Space)", the muscle EXP text, the tutorial line).
- **Cause:** Each system drew its own text in its own place.
- **Fix:** All hints go to one band at the top: one at a time, gone after 4 seconds, and they can be turned off with Tutorial Hints in Settings. Toasts stack under the top bar and never cover each other or the machine panel.
- **Commit:** 8d268f5
