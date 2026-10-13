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

## Saved / published
- Not saved to Roblox yet: File > Save to Roblox, then File > Download a Copy to `Documents\GymArc_backups\GymArc_2026-10-13.rbxl`.
