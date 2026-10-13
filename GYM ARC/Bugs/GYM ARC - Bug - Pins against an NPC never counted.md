---
date: 2026-10-13
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Pins against an NPC never counted

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Against an NPC opponent the bar stopped at 98% and never pinned; the match always went to time.
- **Cause:** A tap filled the bar to 100%, but the NPC's push in the same server tick took it back to 98% before the pin was checked.
- **Fix:** A pin counts the moment a tap fills the bar, and the NPC stops pushing a full bar.
- **Commit:** d1b3b0c

![[GYM ARC/Screenshots/armwrestle_win_screen.jpg]]
