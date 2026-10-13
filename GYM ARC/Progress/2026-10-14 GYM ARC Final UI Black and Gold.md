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
