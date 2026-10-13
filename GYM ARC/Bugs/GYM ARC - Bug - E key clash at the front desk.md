---
date: 2026-10-06
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - E key clash at the front desk

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** The tutorial could not reach Coach Dex: pressing E at his desk bought a DNA token or sat you at the arm wrestling stool instead.
- **Cause:** Several prompts on the same key overlapped at the desk, and E picks the nearest one.
- **Fix:** DNA token moved to F (gamepad Y), arm wrestling prompts reach 4.5 studs (were 7), Dex 8 (was 10). A whole-map scan found no other clashes.
- **Commit:** 27613ba
