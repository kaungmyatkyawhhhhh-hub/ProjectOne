---
date: 2026-10-13
tags: [gymarc, feature]
status: planned
---
# GYM ARC - Posing Competition

Back to [[00 GYM ARC Home|GYM ARC Home]].

Planned (new features prompt, task 1): a server-wide posing contest every few minutes, with judges, an audience vote and a podium. Not built yet.

## How it works (as the prompt asks)
- **Stage:** a raised stage in the town plaza (or by the statue) with 3 marked spots, spotlights and a simple scoreboard sign. No logos.
- **Timing:** a round every `Config.PosingComp.Interval` (default 12 min). Server-wide note and countdown: "Posing Competition starts in 60s! Go to the stage!" with a waypoint arrow.
- **Joining:** walk onto the stage before the countdown ends. Max 6 players. Fewer than 2 = NPC bodybuilders fill in so solo players can play.
- **Round:** 3 existing poses (for example Front Double Biceps, Lat Spread, Most Muscular). Tap the pose button on screen within a short window; good timing gives a small bonus.
- **Score:** muscle size (total look) + balance between groups + timing bonus (weights in Config). NPC judges show a 1-10 score card above each player after each pose.
- **Audience vote:** players not on stage tap a contestant's name during the last pose for a small bonus. No voting for yourself.
- **Results:** 1st / 2nd / 3rd on podium spots, coins, and the winner gets the title "Posing Champion" and is shown on the town statue until the next round.
- **Leaving mid-round:** out, no reward, no errors.
- Server decides scores, votes and rewards; rate limits on every new remote.
- Also planned: a "Posing Wins" leaderboard, an "Enter a posing competition" daily quest, and a scream on a win (monetization prompt).

## Where it lives
- Not built. Would reuse `Server/ShowOffService` (poses, judges, statue) and a new `Config.PosingComp`.

## Related
[[GYM ARC - Poses and Posing Stage]], [[GYM ARC - Leaderboards and Statue]], [[GYM ARC - Titles]], [[GYM ARC - Daily Quests]]

## Screenshots
![[GYM ARC/Screenshots/s3_posing-stage_after.png]]
