---
date: 2026-10-05
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Genetics screen text clipped

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** On the genetics screen the body type bonus was cut off ("+15% Back, Legs, Traps, abs") and the quest tracker's empty panel peeked out behind the barbell.
- **Cause:** Too little room for the line, and the right-hand column was not hidden while genetics was open.
- **Fix:** One full line ("+15% Back, Legs, Traps - abs show later") and the right column hides while genetics is open.
- **Commit:** fb99f0b
