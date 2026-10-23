---
date: 2026-10-15
tags: [gymarc, bug]
status: fixed
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Bug: the main menu and loading screen did not always fill the screen

**What happened:** on some phones a strip on the right showed the game world behind the menu. The GYM ARC logo also sat under Roblox's buttons in the top-left corner.

**Cause:** the background was sized in pixels from the screen size once, and only followed size changes of the first camera. Phones change size after joining and when rotated, so the background could end up too small. The logo started at the very top of the screen.

**Fix (15 Oct):** both backgrounds now always fill the whole screen by themselves (no pixel sizes), and the picture is cropped to cover it. The logo starts just under Roblox's top bar, the buttons under it; on short screens the logo shrinks a little and the player card moves next to the buttons. Checked on 10 screen sizes in a row: covered every time, nothing overlapping. A real phone test (join several times, rotate) is still to do. See [[GYM ARC - Loading Screen and Menu]].

Before (logo under the top-left buttons):
![[GYM ARC/Screenshots/2026-10-15_menu_before_logo_under_buttons.jpg]]
After, phone size:
![[GYM ARC/Screenshots/2026-10-15_menu_phone_after.jpg]]
![[GYM ARC/Screenshots/2026-10-15_loading_phone_after.jpg]]
After, PC:
![[GYM ARC/Screenshots/2026-10-15_loading_pc_after.jpg]]
