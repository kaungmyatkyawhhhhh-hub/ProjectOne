---
date: 2026-10-05
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Stats coach line and panel overlapped

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** With Stats open during the tutorial on a machine, the coach line, the Stats labels and the machine panel slid on top of each other.
- **Cause:** Each piece of UI was placed on its own without knowing about the others.
- **Fix:** The coach line sits under the goal panel and the labels stack between it and the machine panel.
- **Commit:** fb99f0b
