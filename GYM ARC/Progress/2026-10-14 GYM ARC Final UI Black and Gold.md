---
date: 2026-10-14
tags: [gymarc, progress]
status: in progress
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-14 GYM ARC Final UI Black and Gold

Prompt: [[2026-10-14 GYM ARC Prompt - Final UI pass]]. The final UI kit "BLACK + GOLD": dark graphite panels, gold for rewards and the active tab, red only for the one big button on each screen, teal only for progress. One screen at a time, a commit after each.

## 1. Store (the reference) and the shared look
- Every window now has: dark graphite panel with a thin light line along the top, the title big and slanted on the left, the tabs right after it (the active one gold, the others flat and gray), your coins and a dark X on the right. Windows are a bit smaller and the gym stays visible around them (a soft dark shade only near the window).
- Buttons: the main button on a screen is red (or gold) with a shine, a glow and a light streak that sweeps across once when the window opens; it pulses gently. Other buttons are quiet dark ones.
- One heavy slanted font for titles, names, buttons and numbers (Montserrat Black Italic); small gray text for descriptions.
- Store: the big tile on the left shows the picked item (gold frame, BEST SELLER tag on Auto Lift, big picture, gold name, red price button). The grid on the right has dark tiles with price pills. Owned passes get a tilted gold OWNED stamp and their picture and name go dim.
- While a window is open the coin counter at the top hides (the window shows its own).
- In Studio, the Workspace attribute TestStoreAll = true shows every item so the Store looks full (only Extra Trainer has a real id).
Mockup, then the game (phone, owned stamp, PC):
![[GYM ARC/Screenshots/ui_compare_final_04_store_mockup.png]]
![[GYM ARC/Screenshots/ui_compare_final_04_store_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_final_04_store_owned_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_final_04_store_pc.jpg]]
Commit 83261db.

## 2. Quests
- Tabs are now DAILY, STREAK and GOALS.
- Each quest row: an icon tile, the quest in big slanted capitals, a teal progress bar and the coin reward in gold.
  - Ready to claim: gold border with a soft glow, a gold icon tile and a red CLAIM button that pulses.
  - Still going: a dark pill like "1 / 2" (tap it to be told where to go).
  - Claimed: the row fades and shows DONE in teal.
- The once-a-day swap button is now a small round badge on the corner of the icon tile.
- On the right: the ALL 3 BONUS card with a big gold "1 / 3", a gold bar, the bonus coins, a CLAIM button when all three are claimed, and "Resets in 6h 47m".
- Claiming: coins fly up toward your coin counter with a small gold sparkle burst.
- The small 7-day calendar moved off the Daily tab; the Streak tab has the full one.
- Tested with a real quest: did 50 chest reps on the bench, the row turned gold with CLAIM, claimed it, the coins flew and the row showed DONE.
Mockup, then the game:
![[GYM ARC/Screenshots/ui_compare_final_05_quests_mockup.png]]
![[GYM ARC/Screenshots/ui_compare_final_05_quests_claim_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_final_05_quests_coin_burst_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_final_05_quests_pc.jpg]]
![[GYM ARC/Screenshots/ui_compare_final_05_quests_streak_pc.jpg]]
![[GYM ARC/Screenshots/ui_compare_final_05_quests_goals_pc.jpg]]
Commit 9dc1eb9.

## 3. Coaches
- The Trainers window is now called COACHES, with your coins in the header.
- Each tile: the coach's picture in a dark box and the perk in big letters ("+5%" with a small "EXP").
  - The coach who is with you: tile a bit bigger, gold frame with a soft glow, the perk in gold and "COACHING".
  - Coaches you own: a dark EQUIP button.
  - Coaches you don't own yet: picture grayed out, a lock in the corner and the price in a dark pill.
- Bottom: "Tap a coach to hire or swap · 1 / 1 active" and the gold "R$ 99 · 2ND SLOT" button (it pulses gently).
Mockup, then the game (a test save with two coaches hired, then your save with none):
![[GYM ARC/Screenshots/ui_compare_final_06_coaches_mockup.png]]
![[GYM ARC/Screenshots/ui_compare_final_06_coaches_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_final_06_coaches_locked_pc.jpg]]

## 4. Physique
- The Stats window is now called PHYSIQUE, with tabs MUSCLES / LIFTS / GENES and the LABELS ON/OFF switch next to the X.
- Left: your body card on a dark red glow, with a big gold number (how grown your muscles look) and the physique word in gold (Beginner ... Aesthetic ... Mass Monster).
- When a Growth Spurt is ready, a gold TAP TO GROW button takes the number's place (and pulses).
- Right: the six muscle groups, best first: the genetics grade on a small gold plate, the name, a fat shiny bar in the grade's color (S red, A gold, B teal, C gray) and the % toward the Growth Spurt goal.
- The separate Forearms and Calves cards are gone (the mockup shows the six groups).
Mockup, then the game (your save is maxed, so every bar is full):
![[GYM ARC/Screenshots/ui_compare_final_07_physique_mockup.png]]
![[GYM ARC/Screenshots/ui_compare_final_07_physique_phone.jpg]]

## 5. HUD
- Left menu: dark glass tiles with white line icons (the Shop's cart is gold), small slanted labels and plain red dots. The tile of the open window gets a gold border.
- Top bar: bold slanted words (DAILY, QUESTS), and the level as "LVL 45" with a small gold bar toward the next level.
- Right column: the quest cards have a plain teal bar ("TODAY'S QUEST 1/3").
- The Growth Spurt button is now wide: gold "TAP TO GROW" with "GROWTH SPURT 2 READY" under it (it pulses) when you can grow, a quiet dark "GROWTH SPURT 2 · 62%" before that, and "MAX HEIGHT" at 7'0".
- Bottom: the STAMINA panel: teal lightning icon, "250 / 250" and a fat teal bar (soft red when nearly empty).
Mockup, then the game (your save is at max height, so it shows MAX HEIGHT):
![[GYM ARC/Screenshots/ui_compare_final_01_hud_mockup.png]]
![[GYM ARC/Screenshots/ui_compare_final_01_hud_phone.jpg]]

## 6. Lifting
- Top right, the weight card: the machine name with its muscle group in a red tag, dark - and + squares, the weight big ("315 LB"), "Tier 12 / 12" and BEST WEIGHT in gold.
- Under it, the PUMP panel: a gold flame, PUMP, the % and a shiny gold bar. When it's full it glows and says TAP TO PUMP!
- Bottom right: the big red REP button with the rep count.
- Bottom left: a quiet "x STOP" button.
- Bottom center: the stamina panel from the HUD step.
Mockup, then the game:
![[GYM ARC/Screenshots/ui_compare_final_02_lifting_mockup.png]]
![[GYM ARC/Screenshots/ui_compare_final_02_lifting_phone.jpg]]

## 7. Title screen
- One dark panel on the left: the GYM ARC logo (GYM white, ARC red), "Everyone starts tiny.", the big red PLAY (it gently pulses and a shine sweeps across once), a gold SHOP and a dark UPDATES (red dot while there is news).
- Under a thin line: your avatar picture, your name, "Level 46 · 7'0"" and your coins.
- Bottom right: a small gold NEW tag with the newest update's name. Tapping it opens the update notes.
- The loading screen before it did not change.
Mockup, then the game:
![[GYM ARC/Screenshots/ui_compare_final_00_title_mockup.png]]
![[GYM ARC/Screenshots/ui_compare_final_00_title_phone.jpg]]

## Settings: Reduce Motion
A new Settings row, Reduce Motion (Off by default). On = the looping pulses and shine sweeps on buttons stop.

## Arm wrestling: one per stool
Owner's request ([[2026-10-14 GYM ARC Prompt - Arm wrestling one per seat]]): only one person or NPC per arm wrestling stool. NPC opponents now lock their stool while they're on it; tested in Play (dropping a dummy onto the NPC's stool and forcing it to sit: it never stays on). Also fixed a small bug found while testing: the OCCUPY prompt could stay off after a match. See [[GYM ARC - Arm Wrestling]].

## 8. Loading screen
- The GYM ARC logo is now a picture (the white and red logo), with "Everyone starts tiny." in gray under it. The main menu uses the same picture.
- The tip sits in a dark tile with a small gold TIP tag.
- At the bottom: what is loading ("LOADING THE GYM") in bold italic, the percent in gold on the right, a thick shiny red bar, and small dots under it (the gold one is the current tip).
- SKIP is a quiet dark button in the top right.
Mockup, then the game:
![[GYM ARC/Screenshots/ui_compare_final_00_loading_mockup.png]]
![[GYM ARC/Screenshots/ui_compare_final_00_loading_game.jpg]]

## 9. Top bar with TopbarPlus
Owner's request ([[2026-10-14 GYM ARC Prompt - Top bar with TopbarPlus]]): the top bar buttons are now TopbarPlus icons on Roblox's own top bar, the same size and line as Roblox's buttons. Coins, height and level on the left; Daily, Quests and Settings on the right. On a narrow phone the height button folds away first. See [[GYM ARC - UI System]] and [[GYM ARC - Credits]].
- Also found and fixed: a stray "5" typed into a server script stopped the whole game from starting ([[GYM ARC - Bug - Stray character stopped the server]]).
- Also: the Studio test setting TestPhoneSize was switched off. It squeezed the HUD into a box inside the Device Emulator, which is why the left menu looked stuck near the top and the stamina bar looked too high.
![[GYM ARC/Screenshots/declutter_topbarplus_phone.jpg]]

## 10. Less UI on screen (declutter) and lifting on phones
Owner's requests ([[2026-10-14 GYM ARC Prompt - Loading screen, declutter HUD, Genetics mobile]], [[2026-10-14 GYM ARC Prompt - Lifting HUD, top bar, Physique, left menu on mobile]], and "the daily quests and coach quests uis are so big").
- The right side shows only ONE small card at a time. Which one: TAP TO GROW when ready, then the posing competition, then a coach quest ready to hand in, then today's quest, then the legend challenge, then the coach quest still going, then the Growth Spurt progress. Every quest is still in the Quests window.
- The cards are smaller (narrower, smaller text, a thin bar).
- No more MAX HEIGHT card (the top bar shows the height).
- Stamina is a slim bar at the very bottom center (280 wide, 10 px from the edge).
- The left menu is always in the middle of the left side, has no Quests tile any more (QUESTS is on the top bar) and slides away while a window is open.
- Area notes ("Stretching area...") show once when you walk in, then not again for a minute.
- The yellow "!" over new machines only shows within 25 studs.
- No coach lines on screen while lifting.
Lifting on phones:
- REP is smaller (150 x 52) and sits above Roblox's jump button; PUMP sits right above REP; STOP sits above the thumbstick. (While you sit on a machine Roblox hides its touch buttons, so they then sit a fixed 150 px up.)
- The weight card is shorter. When a weight needs a higher level, that line gets its own row and BEST WEIGHT moves under it, so they never overlap.
Before and after (phone):
![[GYM ARC/Screenshots/declutter_hud_before_phone.jpg]]
![[GYM ARC/Screenshots/declutter_hud_after_phone.jpg]]
![[GYM ARC/Screenshots/declutter_lifting_after_phone.jpg]]
![[GYM ARC/Screenshots/declutter_lifting_needs_line.jpg]]
Small phone (667 x 375) and REP above the jump button:
![[GYM ARC/Screenshots/declutter_lifting_small_phone.jpg]]
![[GYM ARC/Screenshots/declutter_lifting_above_jump.jpg]]

## 11. Genetics screen for phones
Owner's request ([[2026-10-14 GYM ARC Prompt - Loading screen, declutter HUD, Genetics mobile]]): the genetics screen was broken on phones ([[GYM ARC - Bug - Genetics screen broken on phones]]). It is now one centered panel that always fits. Tested: the first reveal, the "are you sure" question for a good roll, a reroll with UP / DOWN, the odds, and the small phone size. See [[GYM ARC - Genetics]].
![[GYM ARC/Screenshots/panel_genetics_phone.jpg]]

## 12. Physique numbers and phones
Owner's request ([[2026-10-14 GYM ARC Prompt - Lifting HUD, top bar, Physique, left menu on mobile]]): the Physique window's %, grades and total now all come from one number ([[GYM ARC - Bug - Physique numbers did not match]]), bars follow the grade color, the labels switch is an eye button on the body card, and the window fits small phones. See [[GYM ARC - Stats and Muscles Panel]].
![[GYM ARC/Screenshots/declutter_physique_phone.jpg]]

## 13. Physique note, REP that never moves, the 3D genetics stage back
- Physique ([[2026-10-14 GYM ARC Prompt - Physique taller frame note]]): the real numbers stay. Under the big % a small gray line "Taller frame - more muscle to fill" shows once you are taller than the starting height. After a Growth Spurt a small message shows once: "You grew! Your muscles have more room to grow." The Studio test switch only works in Studio.
- REP ([[2026-10-14 GYM ARC Prompt - Fixed REP spot and 3D genetics back]]): REP now has ONE spot, right above Roblox's jump button (12 px gap, right edges lined up), worked out once and only again if the screen size changes. Found on the way: the first try measured the jump button before Roblox had placed it (REP ended up at the top), so a measurement only counts once the button is in the lower half of the screen.
- Genetics: the 3D stage (the bar with the plates, the overall plate, the DNA helix) is back. Phones now see it framed exactly like a PC; nothing sits on top of the stage any more: the title and DNA tokens are on the top bar line, everything else is one panel along the bottom. (The set pieces had never been moved, so nothing needed moving back.)
- Still to do: the side-by-side screenshots at 844x390, 667x375 and 1920x1080 (Studio's Play button got stuck waiting, see the session notes).

## 14. Tests after Studio unstuck, world signs, stats lines
- REP: the same spot on four sits (bench, squat rack, bench again, overhead press).
![[GYM ARC/Screenshots/rep_fixed_overhead_press.jpg]]
- Genetics 3D stage on the phone emulator: nothing covers the stage. (The 667x375 and 1920x1080 shots still need the emulator switched to those devices.)
![[GYM ARC/Screenshots/genetics_camera_phone.jpg]]
- World signs ([[2026-10-14 GYM ARC Prompt - World signs and stats overlay]], [[GYM ARC - Bug - World signs in your face]]): spawn view clear; the arm wrestling table has a small gold label.
![[GYM ARC/Screenshots/world_signs_spawn_phone.jpg]]
![[GYM ARC/Screenshots/world_signs_arm_table_phone.jpg]]
- Stats lines ([[GYM ARC - Bug - Stats lines pointed at the wrong places]]): before, then standing still and walking.
![[GYM ARC/Screenshots/stats_overlay_before.jpg]]
![[GYM ARC/Screenshots/stats_overlay_phone_still.jpg]]
![[GYM ARC/Screenshots/stats_overlay_phone_walking.jpg]]

## 15. Performance: culling, LOD, streaming
Owner's request ([[2026-10-14 GYM ARC Prompt - NPC culling, LOD and streaming]]). All three steps are done; see [[GYM ARC - Performance]] for what changed, the before / after numbers and the one Studio setting the owner still has to set (the streaming radius).

## 16. Menu music, past the height cap, DNA tokens
- Loading screen and menu play the owner's track 118959016267248, faded out on Play. See [[GYM ARC - Music and Sounds]].
- Saves past the 7'0" cap got +10,000,000 EXP on every muscle once and their Growth Spurt set back to 6. See [[GYM ARC - Growth Spurts]].
- DNA tokens now come only from Growth Spurts (+1), 25,000 coins, or the 99 Robux product 3718499538. See [[GYM ARC - Genetics]] and [[GYM ARC - Monetization]].
- Quest rerolls: 1 free a day, then 19 Robux (product 3718500732), swapped only after the purchase is saved. See [[GYM ARC - Quests and Muscle of the Day]].
- Fixed the ghost ring on gold / red buttons in the shared button code. See [[GYM ARC - Bug - Ghost ring on gold and red buttons]].
- Machine panel moved down to the right middle, greyed - / +, "100 LB" without the plus, a real BEST WEIGHT button. See [[GYM ARC - Machine HUD]].

- Skating is as fast for big players, the stamina bar only shows while exercising, a new SKATE button next to jump. See [[GYM ARC - Skateboard and Skate Park]] and [[GYM ARC - Stamina and Treadmills]].

- Daily rewards: +1 DNA token on days 4 and 7. See [[GYM ARC - Economy and Daily Rewards]].
