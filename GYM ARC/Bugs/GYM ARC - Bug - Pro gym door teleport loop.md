---
date: 2026-10-13
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Pro gym door teleport loop

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Without Growth Spurt 2, walking up to the pro gym door could teleport you again and again, even after walking away.
- **Cause:** The server's pro gym area still had its old size from before the gyms were made bigger (8 Oct), so a strip by the door inside the STARTER gym counted as the pro gym, and the safe spot it put you on was inside that strip too. Standing there teleported you every half second.
- **Fix:** The area now comes from the pro gym's own floor, the safe spot is 6 studs clear of it (checked when the server starts), one put-back per player at most every 1.5 s, and the message "Reach Growth Spurt 2 to enter the Pro Gym" at most every 3 s. The glass door stays solid for locked players. Tested solo: by the door nothing happens, inside you are put back once and stay there.
- **Commit:** 8d268f5
