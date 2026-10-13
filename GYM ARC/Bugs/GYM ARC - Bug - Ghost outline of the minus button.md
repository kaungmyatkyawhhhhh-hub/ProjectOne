---
date: 2026-10-05
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Ghost outline of the minus button

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** At the lightest weight, a faint outline showed where the hidden "-" button was on the machine panel.
- **Cause:** The button was hidden but its drop shadow was not.
- **Fix:** The shadow hides with the button.
- **Commit:** fb99f0b
