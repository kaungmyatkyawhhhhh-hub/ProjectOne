---
date: 2026-10-15
tags: [gymarc, bug]
status: fixed
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Bug: the Quests window opened by itself

**What happened:** right after joining (even for a brand-new player in the tutorial) the Quests window popped open on the Daily quests tab, and a new player could see the Shop.

**Cause:** the window opens when today's login reward isn't claimed, but it opened the wrong tab and didn't wait for the tutorial. The Shop showed because a Studio test switch (TestStore) had been left on in the place.

**Fix (15 Oct):** it now waits until the tutorial is finished, opens the Streak (reward) tab and never while lifting. The test switch is cleared and only works in Studio now.

![[GYM ARC/Screenshots/fresh_player_start_no_popup.jpg]]
