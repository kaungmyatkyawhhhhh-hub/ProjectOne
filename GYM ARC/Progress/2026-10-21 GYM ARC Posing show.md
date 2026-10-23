---
date: 2026-10-21
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-21 GYM ARC Posing show

Prompt: [[2026-10-20 GYM ARC Prompt - 18 Posing show every 5 minutes]]. Feature note: [[GYM ARC - Posing Competition]].

## What changed
The posing competition (every 12 min, timing taps, audience vote) is now a **posing show every 5 minutes** with height divisions, 4 judge-called poses, judging out of 100 with the breakdown shown, the show ladder (Local to Universe Championship), trophies, stats, 4 titles, a HUD timer with JOIN and analytics. The daily "posing" quest only goes to players with a Growth Spurt.

## Tested in Studio (667x375 phone layout, 1 player + NPCs)
- Growth Spurt 1 player (Bantam, Local Show): timer, JOIN put me on the stage, 3 NPCs filled in, 4 poses, podium with confetti, "Good effort!" 4th place +25 coins, Stage Debut title, all 4 analytics events.
- Growth Spurt 3 player with muscles (Middle, Regional Show): judges' panel "Size 41 / Balance 25 / Presence 12 = 78", 3rd place.
- **Not tested:** 2 real players in different divisions (Studio's test tools here only run one player). The code runs each division in turn; please try it with a friend.

![[GYM ARC/Screenshots/posing_show/pose_called.jpg]]
![[GYM ARC/Screenshots/posing_show/podium_good_effort.jpg]]

## Needs the owner
- The stage has 6 marks; up to 8 per division stand spread along them.
- A player right after a Growth Spurt has 0 muscle and comes last against the NPCs (still gets coins and "Good effort!"). Fine, or should NPCs be smaller?
- No backdrop change per show level yet (only the label and prizes).
- Sounds: existing PosingStart / PosingScore / PosingWin / CrowdOoh.
