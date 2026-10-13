---
date: 2026-10-13
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Dante skinny then suddenly huge

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Dante went skinny when he started walking, and after a pumped rep his torso became about 17 studs wide and got shorter each time. The statue and mirror rigs lost the golden ratio too.
- **Cause:** Three causes: Roblox rebuilt NPC body parts on every player's game when they walked (automatic scaling); the per-rep pump resized his parts and the 9 Oct fix read that as a rebuild and widened him again; the statue lost its shape the same way when placed.
- **Fix:** Automatic scaling is off once a body is shaped; the client restores the server's exact sizes and never re-widens; the pump never resizes shaped parts; other bodies keep their stages out to 180 studs.
- **Commit:** 28ee50f

![[GYM ARC/Screenshots/giant_dante_8ft.jpg]]
