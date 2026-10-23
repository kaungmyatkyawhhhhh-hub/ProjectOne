---
date: 2026-10-15
tags: [gymarc, bug]
status: fixed
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Bug: some phones got the PC machine layout

**What happened:** on some phones the machine buttons (REP, STOP, the weight card) used the PC layout in the corners.

**Cause:** the game decided "phone or PC" from one single check, and on a phone it placed REP next to Roblox's jump button. When there was no jump button (hidden, not made yet), it fell back to the PC corners.

**Fix (15 Oct):** a small screen (short side under 500) is always the phone layout. Otherwise the game asks Roblox what the player is using right now (touch = phone) and checks again whenever that changes. A phone with no jump button uses a fixed raised spot on the bottom right. If the weight card would still overlap, it gets a bit smaller. The F9 console says which layout was picked and why ("HUD layout = phone, reason = ...").

**Still to check:** a real phone with the jump button (Studio can't show it). See [[GYM ARC - Machine HUD]].

Touch, no jump button:
![[GYM ARC/Screenshots/2026-10-15_hud_phone_touch_nojump.jpg]]
PC:
![[GYM ARC/Screenshots/2026-10-15_hud_pc.jpg]]
Phone size with a keyboard:
![[GYM ARC/Screenshots/2026-10-15_hud_phone_keyboard.jpg]]
Tablet:
![[GYM ARC/Screenshots/2026-10-15_hud_tablet.jpg]]
