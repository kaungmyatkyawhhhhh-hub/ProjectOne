---
date: 2026-10-14
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Stray character stopped the server

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** In Play, the main menu never let you in and the game did nothing. Output said "ServerScriptService.Server.Analytics:1: Expected identifier when parsing expression, got '5'".
- **Cause:** A single "5" had been typed at the very start of the Analytics script in Studio (most likely a stray key press while that script was open). One broken server module stops every server system from starting.
- **Fix:** Removed the "5". Then compared every game script in Studio with the GitHub backup: all match, nothing else was changed.
- **Tip:** If the game suddenly does nothing in Play, look at the first red line in Output.
