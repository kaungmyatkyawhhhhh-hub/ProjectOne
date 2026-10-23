---
date: 2026-10-15
tags: [gymarc, feature, analytics]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Analytics

The onboarding funnel in the Creator Dashboard shows where new players stop.

## Funnel steps (15 Oct)
The old funnel was numbered from the tutorial's list, so adding the Skate tip on 14 Oct shifted the numbers and the dashboard showed "First Growth Spurt" twice (step 13 was really "Tutorial done"). The steps now have fixed numbered names, each is sent once per player ever and in order, and a new step 14 shows players who reached the Growth Spurt goal but haven't pressed the button yet.

| # | Step name | What triggers it |
|---|---|---|
| 1 | 01. Joined (new player) | data loaded for a player with no Growth Spurt yet |
| 2 | 02. Genetics kept | KEEP on the genetics screen (GeneticsSeen) |
| 3 | 03. Tutorial: walked to the Flat Bench | tutorial step 1 (GoBench) completed |
| 4 | 04. Tutorial: first rep | step 2 (FirstLift) completed |
| 5 | 05. Tutorial: stamina ran low | step 3 (Stamina) completed |
| 6 | 06. Tutorial: drank the free shake | step 4 (Shake) completed |
| 7 | 07. Tutorial: got on the Squat Rack | step 5 (GoSquat) completed |
| 8 | 08. Tutorial: 3 squats | step 6 (SquatLift) completed |
| 9 | 09. Tutorial: opened Stats | step 7 (OpenStats) completed |
| 10 | 10. Tutorial: talked to Coach Dex | step 8 (Coach) completed |
| 11 | 11. Tutorial: saw the Growth Spurt goal | step 9 (Goal) completed |
| 12 | 12. Tutorial: skate tip | step 10 (Skate) completed |
| 13 | 13. Tutorial finished or skipped | tutorial done, or SKIP TUTORIAL |
| 14 | 14. Growth Spurt goal reached | every muscle group at its goal (checked every 5 s) |
| 15 | 15. First Growth Spurt done | the first Growth Spurt (+ custom event FirstGrowthSpurt = minutes since first join) |
