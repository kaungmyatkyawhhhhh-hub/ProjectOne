---
date: 2026-10-13
tags: [gymarc, progress]
status: in progress
---
# 2026-10-13 GYM ARC New features run

Back to [[00 GYM ARC Home|GYM ARC Home]]

Prompts: [[2026-10-13 GYM ARC Prompt - New features run]] and [[2026-10-13 GYM ARC Prompt - Pick audios]]. Seven tasks in order; this note grows with each one.

## Sounds picked (owner's request)
- Every placeholder and every new sound slot now has a real id, only from Roblox's licensed library (ProSoundEffects, APM Music). Full list: [[GYM ARC - Music and Sounds]].
- New area music for the beach and the town; the area check knows the bigger gyms now.
- Listen first (weak fits): CrowdOoh, RivalLose, DoorSlide, SkateGrind.

## Task 1: Posing Competition (done)
- Rounds every 12 minutes on the beach stage: countdown banner and waypoint, NPC bodybuilders fill in, three timed poses, judges' cards, audience vote, podium, coins, the "Posing Champion" title, and the winner becomes the statue. Details: [[GYM ARC - Posing Competition]].
- New stage pieces in `Feature_PosingComp`: taped marks, a 3-step podium, a scoreboard screen. The stage's old Montserrat backdrop text now uses the game's fonts.
- Tested solo in Studio (perfect taps won 30 points; vote, podium, title, coins, statue all worked; no errors). Not tested: two real players, the phone emulator.
- Commit: 7761f14

![[GYM ARC/Screenshots/posing_3_contestants_score_cards.jpg]]
![[GYM ARC/Screenshots/posing_podium.jpg]]

## Task 2: Daily quests + login streak (done)
- 3 daily quests per player from a pool of 12, reset at 00:00 UTC, tracked automatically; a Quests tile in the side menu with CLAIM, one SWAP a day and a +150 bonus for all three. Details: [[GYM ARC - Quests and Muscle of the Day]].
- The login streak is now a 7-day calendar with a CLAIM card on join; day 7 = 300 coins, a DNA token and the "Dedicated" title; missing a day starts again at day 1. Details: [[GYM ARC - Economy and Daily Rewards]].
- Tested solo (claims, swap limit, day 7, quest progress); no errors. Not tested: the spotting quest with two players, a real midnight reset.
- Commit: f9f6f1e

![[GYM ARC/Screenshots/daily_quests_panel.jpg]]
![[GYM ARC/Screenshots/streak_popup_day7.jpg]]

## Task 3: Arm wrestling (done)
- Two tables now (a new one in the pro gym), the machines' OCCUPY prompt and sign, NPC opponents to pick from (easy / medium / hard), a big TAP button, 8 s matches, a 15 taps/s cap, a capped strength bonus, a little EXP, and the "Arm Wrestling King" title. Details: [[GYM ARC - Arm Wrestling]].
- Fixed: pins against an NPC never counted ([[GYM ARC - Bug - Pins against an NPC never counted]]).
- Tested solo against the NPCs (pick, countdown, tapping, pin, win, title, coins, quest); no errors. Not tested: two real players.
- Commit: d1b3b0c

![[GYM ARC/Screenshots/armwrestle_vs_npc_live_bar.jpg]]
![[GYM ARC/Screenshots/armwrestle_win_screen.jpg]]

## Task 4: Leaderboards (done)
- Six boards (Biggest, Strongest, Tallest, Most reps today, Posing wins, Arm wrestling wins), top 10 with headshots and "Your rank", on walls in the starter gym and the pro gym and a stand in the town plaza. Details: [[GYM ARC - Leaderboards and Statue]].
- Tested with example data on all three walls; the real read works (the new boards start empty). Not tested: real data from several servers (needs the published game).
- Commit: a518a47

![[GYM ARC/Screenshots/leaderboards_starter_gym.jpg]]
![[GYM ARC/Screenshots/leaderboards_town_plaza.jpg]]

## Task 5: Smoothie bar (done)
- Owner's answers: [[2026-10-13 GYM ARC Prompt - Task 5 answers and continue]].
- Protein Shake, Energy Smoothie, Chicken & Rice and Coconut Water (beach only) as timed boosts at the pro gym's smoothie bar (new menu board), a starter gym cart and a beach coconut cart; HUD timers; boosts pause while away. Details: [[GYM ARC - Energy Shakes]].
- Fixed in testing: [[GYM ARC - Bug - Smoothie boost charged when already full]], [[GYM ARC - Bug - Paused smoothie boosts wiped before the restore]].
- Commit: 0815b75

![[GYM ARC/Screenshots/meals_shop_panel_starter_cart.jpg]]
![[GYM ARC/Screenshots/meals_drinking_shaker.jpg]]

## Task 6: NPC rivals (done)
- Benny (starter gym, bench), Coral (beach gym, arm wrestling) and Dante (pro gym, squat), each with a challenge card, a title and coins. Rivals are an extra goal: gyms already open by Growth Spurt. Details: [[GYM ARC - NPC Rivals]].
- Also fixed: [[GYM ARC - Bug - Tutorial path target nil]].
- Commit: 01aa58d

![[GYM ARC/Screenshots/rival_card_benny.jpg]]
![[GYM ARC/Screenshots/rival_win_benny.jpg]]

## Saved / published
- Not saved to Roblox yet: File > Save to Roblox, then File > Download a Copy to `Documents\GymArc_backups\GymArc_2026-10-13.rbxl`.
