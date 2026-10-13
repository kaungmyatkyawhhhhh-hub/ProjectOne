---
date: 2026-10-06
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Machines unusable after Exit

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** After pressing Exit you could not get back on the same machine.
- **Cause:** The server turned the machine's prompt back on just before telling your screen you had left, and your screen caught that change and hid the prompt again for good.
- **Fix:** Fixed in MachineClient's close step. Tested getting on and off 5 times on the bench and the pull-up bar.
- **Commit:** 0d13f0c
