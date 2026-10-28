---
date: 2026-10-28
tags: [gymarc, liveops, progress]
---
# GYM ARC Update countdown and live launch event (prompt 90, 28 Oct)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Prompt: [[2026-10-28 GYM ARC Prompt - 90 Update countdown and live launch event]] · How it works: [[GYM ARC - Live Update Events]]

## Built
- The reusable live event system (config, server timer, client countdown, cutscene player, per-update cutscene module).
- First event: HALL OF FAME, Sat 31 Oct 15:00 UTC. **The Hall of Fame is now locked until then** (`HallOfFame.IsOpen` also needs the launch). The Hall is covered: navy curtains with gold rods, a gold star, light leaking under them, and the countdown banner across the middle columns.
- GO TO target "Hall" (the plaza in front of the steps, facing the Hall).
- Launch Day title (Social, Epic) for players online at the opening + 30 min 1.5x EXP and coins.
- Owner's extra request: the NEWS update log gets a "Hall of Fame · 31 Oct" entry (Hall of Fame, keep list, statue + Launch Day, profiles, CODES / HALLOFFAME) that only appears once the Hall has opened; the red NEWS dot comes back then.

## Tested in Studio (1 player, test save)
- Countdown card, gather window, GO TO, banner clock, 10..1, the live cutscene, curtains drop, cover put away, Hall of Fame unlocks, title + boost saved once, boost tile, the late-join popup + WATCH replay, the NEWS entry after launch, a launch while on the title screen (skipped, as planned). No script errors.
- FPS in Studio: cutscene avg 23 / worst frame 65 ms vs normal play 19 / 77 ms on the same PC (no extra cost).
- Not done: a real 2-3 player test (the Studio tools here start only 1 player) and true phone-size captures (these are the Studio window, 1089 x 730).

![[GYM ARC/Screenshots/launch90/1_hud_card.jpg]]
![[GYM ARC/Screenshots/launch90/2_gather_window.jpg]]
![[GYM ARC/Screenshots/launch90/3_covered_hall_board.jpg]]
![[GYM ARC/Screenshots/launch90/4_ten_to_one.jpg]]
![[GYM ARC/Screenshots/launch90/5_cutscene_reveal.jpg]]
![[GYM ARC/Screenshots/launch90/6_cutscene_light_shafts.jpg]]
![[GYM ARC/Screenshots/launch90/7_cutscene_title.jpg]]
![[GYM ARC/Screenshots/launch90/8_new_popup_late_join.jpg]]

## Update day runbook (Sat 31 Oct)
1. Fri / Sat morning: publish. The Hall stays covered and locked by itself.
2. Hours before (by ~12:00 UTC / 6:30 PM Myanmar): Restart Servers > "Restart only outdated servers", delay 10 min. Never at launch time.
3. 15:00 UTC (9:30 PM Myanmar): it launches by itself on every server.
4. Right after: send the Update Announcement; watch Error Report and players for 1-2 hours.
