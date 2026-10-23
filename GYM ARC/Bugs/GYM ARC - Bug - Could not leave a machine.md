---
date: 2026-10-13
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Could not leave a machine

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Pressing LEAVE / STOP TRAINING sometimes did nothing, so you stayed stuck on the machine, mostly while tapping fast or with Auto Lift on.
- **Cause:** Every tap, PUMP tap and Auto Lift tick sends a message to the server, and the server's anti-spam limit (16 a second) quietly threw away the extra ones, including the Leave message. Space was also used for lifting, so the jump key could not get you off.
- **Fix:** Leave now skips that limit (it has its own small one), your screen asks again every second until the server answers, and the jump button / Space gets you off (Space no longer lifts). Tested on all 22 machine types after 20 fast taps mid-rep, and on the bench with Auto Lift on.
- **Commit:** 8d268f5
