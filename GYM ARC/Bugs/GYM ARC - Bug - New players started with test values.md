---
date: 2026-10-09
tags: [gymarc, bug]
status: fixed
aliases: ["GYM ARC - Bug - New players started at 7'0 test height"]
---
# GYM ARC - Bug - New players started with test values

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

## First time (5 Oct)

- **What happened:** Every brand-new player joined at Growth Spurt 1 (4'6") and got the Late Bloomer title the moment they joined. An earlier version even gave 9999 coins, 999 DNA tokens and Growth Spurt 10.
- **Cause:** Leftover test numbers in the new-save template. The crew score formula also assumed Growth Spurts start at 1.
- **Fix:** New saves start at Growth Spurt 0, 0 coins, 0 DNA tokens (4'0", no titles, one free reroll). Crew score fixed to spurts x 100.
- **Commit:** fb99f0b

## Again (8-9 Oct): started at 7'0" test height

- **What happened:** For testing, new saves started at Growth Spurt 6 (7'0", the max height).
- **Cause:** The new-save template was set that way on 8 Oct (a05ab70) for testing.
- **Fix:** Release data reset: new DataStore, new players start at Growth Spurt 0 (4'0"), muscles 0, fresh leaderboards and crews.
- **Commit:** a22fe6b
