---
date: 2026-10-09
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - New players started at 7'0 test height

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** For testing, new saves started at Growth Spurt 6 (7'0", the max height).
- **Cause:** The new-save template was set that way on 8 Oct (a05ab70) for testing.
- **Fix:** Release data reset: new DataStore, new players start at Growth Spurt 0 (4'0"), muscles 0, fresh leaderboards and crews.
- **Commit:** a22fe6b
