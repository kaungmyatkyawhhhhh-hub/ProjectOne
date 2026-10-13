---
date: 2026-10-13
tags: [gymarc, progress]
status: in progress
---
# 2026-10-13 GYM ARC UI redesign

Back to [[00 GYM ARC Home|GYM ARC Home]]

Prompt: [[2026-10-13 GYM ARC Prompt - UI redesign with image pieces]]. Feature note: [[GYM ARC - UI System]].

## Asset ids and the permission check (done)
- All 85 images found in the Myanmar Builders Club group by their exact names: 35 pieces, 37 icons, 13 shop icons. None missing.
- A piece, an icon and a shop icon all load in the game (the place is yours, the images the group's): no permission change needed.

## Foundation (done)
- The new look in Theme (colors, fonts, image panels and buttons) and one set of components for every screen. Commit 4e795bf.

## Steps
- 01 Main HUD (done): top row (coins, level + EXP bar, height), menu tiles, daily quest card, boost chips, Growth Spurt card, toasts. Commit 1df5e0d.
![[GYM ARC/Screenshots/ui_compare_00_foundation_login_streak.jpg]]
![[GYM ARC/Screenshots/ui_compare_01_main_hud_pc.jpg]]
![[GYM ARC/Screenshots/ui_compare_01_main_hud_phone.jpg]]
- 02/03 Machine panel (done): name + muscle group tag + AUTO, the muscle split line, - / barbell / + with MAX on top of +, weight + gold TIER tag, green stamina segments; gold PUMP above the big red REP button on the right; LEAVE top left; gold NEW PERSONAL RECORD banner. The Auto Lift button moved from the right column onto the panel (hidden while nothing is for sale). Commit 4a42ef0.
- Studio disconnected after the machine panel test (about 5:35 PM). Two tiny tweaks (PUMP button brighter when empty, toasts a little higher while training) are saved in GitHub but not yet in Studio; the Studio test switch TestPhoneSize is still on in the place. Next session: push them and clear the switch.
![[GYM ARC/Screenshots/ui_compare_02_machine_hud_phone.jpg]]
