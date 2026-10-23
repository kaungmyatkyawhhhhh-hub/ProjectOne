---
date: 2026-10-15
tags: [gymarc, bug]
status: fixed
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Bug: the Robux Store took about 10 minutes to load on a phone

**What happened:** on a phone the Store took about 10 minutes before it could be used.

**Cause:** the Store window itself was fast. The Shop button only appeared after the tutorial plus 5 minutes of play, and those 5 minutes started again in EVERY session. So every player waited 5+ minutes each time they joined. The server also checked the passes one after another.

**Fix (15 Oct):** the 5 minutes now only count for a brand-new player (from their very first join). The Store shows straight away from the game's own list (names, prices, pictures), and Roblox's prices update quietly in the background (1 retry at most). The server checks all passes at the same time; until it knows, only that pass's buy button shows "...". The shop pictures load in the background.

**Measured in Studio:** before, the Shop button appeared after 300 seconds of play every session. After, it appears right when you press PLAY; the Store opens in 0.1 s, and again in 0.1 s the second time. A slow-network phone test is still to do. See [[GYM ARC - Monetization]].

![[GYM ARC/Screenshots/2026-10-15_store_pass_pending.jpg]]
