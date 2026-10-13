---
date: 2026-10-09
tags: [gymarc, progress]
status: done
---
# 2026-10-09 GYM ARC Spotting menu and Dante

Back to [[00 GYM ARC Home|GYM ARC Home]]

## What got done
- **Gameplay**
  - Beach gym uses copies of the real machines (Bicep Curl, Lateral Raise, Shrugs); old beach-only machine progress moves over.
  - New spotting system: tap a lifter, request card, hands / hype spots, click anywhere to push; then the "dopamine" pass (combo counter, milestones, gold boost, coins bar, ASSIST, coin burst, wrap-up). See [[GYM ARC - Spotting]].
  - Arm wrestling animation on every client (elbows on pads, hands swing with the meter, slam + fist pump).
  - MAX weight button on the machine panel: buys every next plate the level and coins allow, then picks the heaviest usable plate; placed on top of the + button after several layout rounds.
- **Look**
  - New loading screen (a barbell that loads with the game) and a cinematic menu tour with a profile and a breathing PLAY button; matte machine signs.
  - Gym lighting pass: warm pendant pools and wall washers in the starter gym, brighter spotlight pools in the pro gym; only 4 shadow-casting lights.
  - Dante the giant regular: mass monster, V-Taper frame, shirtless and bald, then 8'0" with uncapped widths.
  - Upper traps now grow; NPC upper traps stage meshes regenerated and re-imported by the owner.
- **Release prep**
  - Release data reset: new DataStore `GymArcDataStoreV1`, fresh leaderboards and crews, new players start at Growth Spurt 0 (4'0"); fix for the "still saving from another server" kick.

## Bugs fixed
- [[GYM ARC - Bug - Machine sign mirrored the room|Machine sign mirrored the room]]
- [[GYM ARC - Bug - Still saving from another server kick|Still saving from another server kick]]
- [[GYM ARC - Bug - New players started at 7'0 test height|New players started at 7'0 test height]]
- [[GYM ARC - Bug - Low FPS from shadow-casting gym lights|Low FPS from shadow-casting gym lights]]
- [[GYM ARC - Bug - Upper traps never grew|Upper traps never grew]]
- [[GYM ARC - Bug - NPC body shapes lost on players screens|NPC body shapes lost on players screens]]

## Saved / published
- After the beach gym change the log says "Not saved to Roblox yet" (the Studio window was titled "Place2"). No later Save to Roblox or backup is recorded for this day, and no 9 Oct backup file is in `GymArc_backups`. Studio was left with `TestMuscleShare = 2` for the owner's 2-player test.

## Screenshots
![[GYM ARC/Screenshots/spot_dopamine_combo_boost.jpg]]
![[GYM ARC/Screenshots/loading_barbell.jpg]]
![[GYM ARC/Screenshots/menu_returning_main_street.jpg]]
![[GYM ARC/Screenshots/giant_dante_8ft.jpg]]
![[GYM ARC/Screenshots/armwrestle_live.jpg]]
![[GYM ARC/Screenshots/max_button_above_plus.jpg]]
