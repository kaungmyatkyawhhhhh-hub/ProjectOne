---
date: 2026-10-21
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-21 GYM ARC Old starter gym restored

Prompt: [[2026-10-21 GYM ARC Prompt - 32 Restore the old starter gym]]. Feature notes: [[GYM ARC - Town and Gyms]], [[GYM ARC - Machines]], [[GYM ARC - Tutorial]].

## Done
- The old starter gym is back (88 x 85, ceiling 16, the original zones and machines): put back from `ServerStorage.StarterGymBackup.Before`, the copy made just before prompt 26. No version history needed.
- The 11 pro machine copies from prompt 16 are out of the starter gym (kept in `StarterGymBackup.ProCopies`). They open with the pro gym again (Growth Spurt 2); the beach gym copies are unchanged.
- Kept: the 6 dumbbell Train spots + picker, the Trainer Agency desk, the arm wrestling table, the leaderboard wall. (The Coach Dex counter from prompt 31 isn't built yet.)
- The prompt 26 layout is kept in `StarterGymBackup.LayoutV2` (untagged, never loads).
- Outside: the grass west of the gym is filled back in; the 15 trees prompt 26 had pushed into one line are spread over that strip again (their exact old spots weren't saved).
- Tutorial: new players now start in the middle aisle, 16 studs from a Flat Bench, facing it (the old start spot was 68 studs away with the benches back on the mirror wall).
- "Train next" window: also lists up to 2 dumbbell exercises per muscle group (before Growth Spurt 2 the arms only have dumbbells). Go leads to the nearest free dumbbell spot in a gym you've opened.
- Quests only name starter machines, so all of them can still be done. Saves, MachineIds and unlocks are unchanged.
- Growth Spurt 2 stays at level 52: the pacing test gives 15.9 min (target 15).

## Tested in Studio (fresh test player, nothing saved)
- No errors on start; 25 starter machines + 6 dumbbell spots live; nothing from the backups is tagged.
- After the genetics reveal the player stands at the new start spot, and the gold path leads straight to the Flat Bench. The dumbbell Go path picks the nearest spot.
- Logic tests pass (machines, quests, daily quests, EXP, gains, pacing).

![[GYM ARC/Screenshots/starter_restore/angle1_from_desk.jpg]]
![[GYM ARC/Screenshots/starter_restore/angle2_from_back_left.jpg]]
![[GYM ARC/Screenshots/starter_restore/angle3_rack_wall.jpg]]
![[GYM ARC/Screenshots/starter_restore/tutorial_path.jpg]]
![[GYM ARC/Screenshots/starter_restore/dumbbell_go_path.jpg]]
![[GYM ARC/Screenshots/starter_restore/top_outside.jpg]]

## Needs the owner
- Walk through the gym once: if you had moved anything by hand after the re-layout (this afternoon), it went back with the old layout. The re-laid-out version is still in `StarterGymBackup.LayoutV2` if you want to copy something out of it.
- The pro gym still needs its own reason to unlock (open question from prompt 16).
