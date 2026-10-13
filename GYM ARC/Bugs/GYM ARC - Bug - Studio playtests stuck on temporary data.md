---
date: 2026-10-04
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Studio playtests stuck on temporary data

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Stopping and quickly restarting a Studio playtest left you on temporary data that did not save, for 5 minutes.
- **Cause:** The previous test session's save lock was still active, so the game refused to load the real save.
- **Fix:** Studio playtests take over a stale lock straight away. Live servers keep the strict lock.
- **Commit:** unknown
