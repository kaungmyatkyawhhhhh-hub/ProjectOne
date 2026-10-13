---
date: 2026-10-08
tags: [gymarc, bug]
status: open
---
# GYM ARC - Bug - MachineClient at the 200 locals limit

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** The machine script can't take new top-level variables; new code has to go into tables.
- **Cause:** Luau allows at most 200 local variables at the top of one script, and MachineClient is at that limit.
- **Fix:** Not fixed yet. Workaround: new code goes in tables (ExpPops, bars.*). Splitting the script would fix it.
- **Commit:** unknown
