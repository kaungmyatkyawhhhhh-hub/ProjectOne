---
date: 2026-10-07
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Title Book did not open on phones

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** On phones, tapping Titles in the menu never opened the Title Book; long descriptions were also cut off.
- **Cause:** It listened to the PC button only.
- **Fix:** Listens to the phone tile too; descriptions wrap.
- **Commit:** 29eb5a6
