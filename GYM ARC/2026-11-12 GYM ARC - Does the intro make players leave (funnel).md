---
date: 2026-11-12
tags: [gymarc, funnel, intro, retention]
---
# GYM ARC: does the intro make players leave? (12 Nov)

Owner: "does the intro also matter? is it why players leave"

## Data (vault: [[2026-11-10 GYM ARC - Why the like ratio fell (74 to 69) + fix prompt]], Creator Hub funnel, 7 days, 26,902 new players)
| Step | Reached | Lost at this step |
|---|---|---|
| 01 Joined → 02 Genetics kept | 100% | 0% |
| **03 Walked to the Flat Bench** | 84.3% | **15.7% (the biggest single drop)** |
| 05 Bench reps | 73.0% | 13.3% |
| 09 Crunch step | 61.6% | 14.5% |

**Where the intro sits:** step 02 fires at join, before the intro (checked in today's Studio console). So the 15.7% lost before step 03 is three things together:
1. the intro cutscene;
2. the first walk / GO TO (it failed silently when the bench was taken; fixed 10 Nov);
3. plain bouncing.

The funnel has no step between them, so the intro's own share can't be separated yet. The Creator Hub funnel page failed to load today ("Request failed"); read it again after publishing.

## The intro (today's playtests)
- About **35-45 s** before the player can move: Benny scene, the membership sign, a flyover of the whole town.
- SKIP is there, but small, and kids don't read it as "start playing".
- **Rule of thumb for Roblox kids:** the first 30-60 s decide it. A 40 s cutscene at the very start is a real risk. It is part of the step-03 drop, but probably not the whole of it (the GO TO bug was the confirmed one).

## Recommended (not built yet)
1. **Measure it:** add funnel step "02b Intro finished" (with skipped yes/no and its seconds), so the next 7 days show the intro's own drop.
2. **Shorten it to ~15 s:** keep Benny shoving you, the "One day YOU'LL be the big one" line and the gym door. Drop the town flyover (the Progression Road and the gym signs teach the map later). Show SKIP as a bigger "PLAY" pill after 3 s.
3. **Target:** the step-03 drop from 15.7% to under 8%.
