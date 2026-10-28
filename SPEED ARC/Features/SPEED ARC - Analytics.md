---
date: 2026-10-28
tags: [speedarc, feature]
status: done (M4)
---
# SPEED ARC - Analytics

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

GDD 26, built in M4.

- **Onboarding funnel** (Creator Hub > Analytics > Funnels, nothing to set up): 01 loaded, 02 menu_play, 03 first_tap, 04 first_race_joined, 05 first_race_finished, 06 first_shoes, 07 first_coach_roll, 08 silver, 09 gold, 10 go_pro_1, 11 day2_return, 12 go_pro_2.
- Each step fires once per player (saved in their data) and **always in order**: a step reached early waits until the one before it fires.
- **Custom events:** RaceJoined, RaceSkipped (a JOIN window passed while you were in that area). Offers shown / tapped / bought come with the store (M5).

## Where it lives
`Server/Services/Analytics`, step list in `Config/Retention.Funnel`.
