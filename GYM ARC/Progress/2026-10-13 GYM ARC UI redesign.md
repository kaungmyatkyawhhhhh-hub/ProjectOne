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

## Big UI and bug run (evening, v2 style)
Prompts: [[2026-10-13 GYM ARC Prompt - Big UI and bug run]], then [[2026-10-13 GYM ARC Prompt - Keep the old left menu]]. The dark style above is cancelled.
- Images uploaded from Studio: the 3D menu icons (not used: the owner kept the old menu), the four trainer pictures and the main menu art.
- New look built: text, buttons, panels, top bar, the old left menu kept (tidied), stamina bar with boost icons, GROW tile, hint band and toasts.
- Bugs fixed: [[GYM ARC - Bug - Machine panel covered the player]], [[GYM ARC - Bug - Could not leave a machine]], [[GYM ARC - Bug - Too much floating text while lifting]], [[GYM ARC - Bug - Pro gym door teleport loop]]. Commit 8d268f5.
- Bug 5 fixed: [[GYM ARC - Bug - Wardrobe tops broken on the muscle body]] (three causes; commit 3039372). Still open and small: [[GYM ARC - Bug - Small skin spots on the lower back under tops]]. The Wardrobe stays hidden; tops are refunded once.
- Next: every panel in the new style, trainers, main menu and loading screen.
![[GYM ARC/Screenshots/ui_compare_v2_01_main_hud_menu_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_02_machine_hud_phone.jpg]]
- Settings window (mockup 10) done: two columns of ON / OFF rows (Music, Sound Effects, Others' Sounds, Low Graphics, Tutorial Hints, Gain Numbers, Rep Flash, EXP Popups, Spot Requests). Commit d71c4a0.
![[GYM ARC/Screenshots/ui_compare_v2_10_settings_phone.jpg]]
- Titles window (mockup 08) done: All / Owned tabs, rarity-colored cards, EQUIP / EQUIPPED, locks on titles you don't have yet.
![[GYM ARC/Screenshots/ui_compare_v2_08_titles_phone.jpg]]
- Quests window (mockup 05) done: Daily (3 quests + bonus + 7-day reward grid), Rewards (login streak), Achievements (the Coach's quest chain). The old login calendar card is gone; the Daily Reward and Quests pills open this window.
![[GYM ARC/Screenshots/ui_compare_v2_05_quests_daily_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_05_quests_rewards_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_05_quests_achievements_phone.jpg]]
- Stats window (mockup 07) done: Muscles (body card + 8 grade cards + Growth Spurt row), Lifts, Genetics tabs. The GROW tile now opens it when not ready. The Growth Spurt moment is centered.
![[GYM ARC/Screenshots/ui_compare_v2_07_stats_muscles_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_07_stats_lifts_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_07_stats_genetics_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_07_growth_spurt_moment_phone.jpg]]
- Shop window (mockup 04) done: Gym Store with pass cards, Robux prices from Roblox and a big detail panel with the buy button. Only items with ids show (today: Extra Trainer).
![[GYM ARC/Screenshots/ui_compare_v2_04_shop_phone.jpg]]
- Part 3 Trainers (mockup 06) done: picture tiles with perk + price only, tap to hire / equip / unequip, Not enough coins shake, gold 2ND SLOT pass button; followers now look like their pictures and have no name tags.
![[GYM ARC/Screenshots/ui_compare_v2_06_trainers_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_06_trainers_following_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_06_trainer_follower_red_cap.jpg]]
- Smoothie bar window (mockup 09) done: drink tiles with a colored icon, effect and time, green coin price; drinks not sold at that stall show where to get them.
![[GYM ARC/Screenshots/ui_compare_v2_09_smoothie_bar_phone.jpg]]
- Tutorial dialog (mockup 11) done: coach dialog with a live portrait and Tap to continue pages, green SKIP TUTORIAL (tap twice), 50 coins for finishing the tutorial.
![[GYM ARC/Screenshots/ui_compare_v2_11_tutorial_dialog_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_11_tutorial_skip_confirm.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_11_tutorial_skipped.jpg]]
- Arm wrestling screen (mockup 13) done: names over a red / blue tug bar, gold timer, big round TAP! button, colored opponent buttons.
![[GYM ARC/Screenshots/ui_compare_v2_13_arm_wrestle_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_13_arm_wrestle_pick_phone.jpg]]
- Posing screen (mockup 12) done: pose name in gold, Judges panel with live scores, TIMING bar and a big red POSE! button.
![[GYM ARC/Screenshots/ui_compare_v2_12_posing_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_12_posing_judges_phone.jpg]]
- Part 4 done: new loading screen (art, logo, tip, red progress bar with steps, SKIP after 5 s) and main menu (green PLAY, gold SHOP, blue UPDATES, coins / LVL / height pill); the live gym tour is gone.
![[GYM ARC/Screenshots/ui_compare_v2_00_loading_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_00_main_menu_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_00_main_menu_updates.jpg]]
- Emotes and Crew windows in the new style (no mockup for these).
![[GYM ARC/Screenshots/ui_compare_v2_emotes_window_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_crew_window_phone.jpg]]
