---
date: 2026-10-13
tags: [gymarc, prompt]
status: done
---
# 2026-10-13 GYM ARC Prompt - Big UI and bug run

Back to [[00 GYM ARC Home|GYM ARC Home]]

Replaces the earlier [[2026-10-13 GYM ARC Prompt - UI redesign with image pieces]] (that dark style is cancelled). Work log: [[2026-10-13 GYM ARC UI redesign]].

```text
BIG UI + BUG RUN. Do the parts in order. Save this prompt to the Obsidian vault first. After each part: test on phone size (844x390) and PC, check Output for errors, take screenshots, export to src/, update PROGRESS.md and Obsidian, commit.
Don't ask me anything; make sensible choices and write them down.

FILES (all in C:\Users\kaung\Downloads):
- gym_arc_ui_mockups_v2\*.png = the 15 new screens. They are the source of truth. Look at ALL of them before starting.
- gym_arc_ui_3d_icons\ = menu_*.png (3D left-menu icons), trainer_*.png (trainer portraits), menu_art.png (main menu + loading art)
- gym_arc_ui_icons\ = small white line icons, gym_arc_shop_icons\ = pass/product icons (already uploaded)
- GYM_ARC_UI_v2_gymleague_style.md = the full style guide (colors, fonts, buttons, panels). Read it.
Upload any of these images that aren't in the Myanmar Builders Club group yet, then find every ID with search_asset (scope group, exact name match; ignore old look-alikes like "btn-red").
The old dark style (GYM_ARC_UI_redesign.md, gym_arc_ui_pieces) is CANCELLED. Don't use it.

====================================================================
PART 1 - BUGS FIRST
1. The machine HUD sits in the middle of the screen and covers the player. Move it to match 02_machine_hud.png: a weight panel on the right side, REP + PUMP circles bottom-right, STOP TRAINING above the stamina bar. Nothing in the middle.
2. I can't leave the machine. STOP TRAINING always works, and so does the jump button/key. Test every machine type, mid-rep, with AUTO on, phone and PC.
3. Too much floating text while lifting ("Reps go on their own...", "Tap to pump (click or Space)", the muscle EXP text over the panel). Remove those. Only ONE hint at a time, in the top tutorial band, hidden after 4 s. Toasts stack under the top bar and never cover the machine HUD or each other.
4. Pro gym teleport loop: without Growth Spurt 2, walking into the pro gym door sometimes teleports you again and again even when you walk away. Find the cause and fix it: use a solid invisible barrier plus the message "Reach Growth Spurt 2 to enter the Pro Gym" (3 s cooldown per player), or teleport once to a safe spot clearly outside the zone with a per-player debounce. Test walking in, standing in it, backing out, and with 2 players.
5. Wardrobe/gear clothes (hoodies etc.) are broken. Put on every top at level 0, half, max and mass monster, front and back. Find the real cause (shirt template mapping on the muscle meshes, the second textured part, the stage meshes for other players, or the template images) and fix it, don't just hide parts. The Wardrobe must stay hidden (Config.Features.Wardrobe = false). Anyone wearing a broken item gets it removed and their coins refunded. Write the cause in the Obsidian Bugs folder.

====================================================================
PART 2 - REBUILD ALL UI IN THE GYM LEAGUE STYLE (see the style guide)
- FredokaOne text, white with a thick black stroke. Glossy gradient buttons with dark outlines. Dark rounded pills in the top bar. Dark panels with tabs above them and a red X with a white border. The game blurs behind open menus.
- Do NOT copy Gym League's plate/weight-loading system. Our machines keep REP / PUMP / weight - + / AUTO. Only the look changes.
- Top bar: coins, height "6'4" / 7'0"", level on the left; Daily Reward, Quests, settings gear on the right (leave room for Roblox's buttons).
- Left menu: only 7 square tiles in 2 columns with the 3D menu_*.png icons popping out the top: Shop (yellow), Quests (green), Stats (red), Trainers (blue), Titles (purple), Emotes (orange), Crew (teal), with a red badge for notifications.
  Merge the rest: Stats/Genetics/Muscles = tabs inside Stats; Day/login streak = Daily Reward pill + a Rewards tab in Quests; Coach hints = a toggle in Settings; Settings = the gear; Wardrobe hidden.
- Screens to match: 01_main_hud, 02/03_machine_hud, 04_shop, 05_quests (Daily/Rewards/Achievements tabs, CLAIM/GO/DONE, 7-day grid), 07_stats, 08_titles, 09_smoothie_bar, 10_settings, 11_tutorial_dialog (top band + green SKIP TUTORIAL + coach dialog box with portrait), 12_posing, 13_arm_wrestle.
- Anything without a mockup (Crew, Emotes panel, toasts, spotting popup, prompts, leaderboards, vote, machine billboards) = same style.

====================================================================
PART 3 - TRAINERS (06_trainers.png)
- Each trainer is shown as its PICTURE (trainer_exp/stamina/coins/pump.png), not a logo. No names anywhere in the UI (no "Rookie Coach", no "Coach Sam").
- Under each picture: the perk only (+5% EXP, +10% Stamina, +5% Coins, +25% Pump) and the price with a coin icon (300 / 450 / 600 / 800 from Config).
- Tapping the picture does it: not owned = buy it right away (not enough coins: tile shakes + "Not enough coins" toast); owned = equip ("TAP TO EQUIP"); equipped = green outline + "FOLLOWING" (tap again to unequip).
- Bottom row: "Following 1/1", plus the gold "R$ 99 2ND SLOT" button for the Extra Trainer pass (ID 2032496303).
- The trainer NPC that follows you in the world should look like its picture (same colors/hat).

====================================================================
PART 4 - MAIN MENU + LOADING SCREEN (00_main_menu.png, 00_loading.png)
- Both use menu_art.png on the right side, fading into dark on the left, with a blurred dark copy filling the background. Remove the old white PLAY button, the pointing hand and the live-gym background.
- Main menu: GYM ARC logo + "Everyone starts tiny." on the left, big green PLAY, gold SHOP and blue UPDATES buttons, small coins / level / height pill at the bottom.
- Loading screen: shows instantly from ReplicatedFirst (remove the default loading screen). Logo, a rotating tip (tips in Config.UI.LoadingTips), red progress bar with step text ("Loading muscles... 64%") driven by ContentProvider:PreloadAsync + save data loaded, SKIP top-right after 5 s, fade into the main menu.

====================================================================
QUALITY
- Phone first (UIScale on the short side), then 1280x720 and 1920x1080. Nothing overlapping, nothing off screen, touch targets at least 44 px.
- Screenshot each screen next to its mockup in screenshots/ui_compare_v2/.
- Morning report at the top of PROGRESS.md: what's done, anything I need to upload, and the 3 things to test first.
```
