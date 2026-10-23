---
date: 2026-10-08
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Floating upper traps piece

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** A piece floated over the chest under the neck, with a sawtooth gap at higher levels.
- **Cause:** The muscle package's separate upper traps shell was made for the old torso and did not fit the new unified one.
- **Fix:** Shell removed; the unified torso grows the traps itself.
- **Commit:** 574ccec

![[GYM ARC/Screenshots/before_fix_max_floating_traps.png]]
![[GYM ARC/Screenshots/unified_front_max.png]]
