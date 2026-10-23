---
date: 2026-10-14
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Treadmill played the plate clank

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Running on a treadmill played the metal plate clank on every step, like a barbell.
- **Cause:** Every machine used the same lockout sound code; the treadmill (cardio) was never excluded.
- **Fix:** Cardio machines skip all metal sounds and get their own TreadmillLoop and TreadmillStep slots (ids empty for the owner to pick). Bodyweight sets with no plates don't clank either.
- **Commit:** 9036463
