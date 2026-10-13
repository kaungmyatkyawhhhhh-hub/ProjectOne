---
date: 2026-10-08
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Parking arrows pointed backwards

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** The painted arrows in the parking lot looked like they pointed back at their own shaft.
- **Cause:** The head was a single right-angle wedge, which read as half a head facing the wrong way.
- **Fix:** Two mirrored wedges make a proper arrow head pointing ahead (in the place and the builder).
- **Commit:** 36ea61c

![[GYM ARC/Screenshots/parking_arrows_before.jpg]]
![[GYM ARC/Screenshots/parking_arrows_fixed.jpg]]
