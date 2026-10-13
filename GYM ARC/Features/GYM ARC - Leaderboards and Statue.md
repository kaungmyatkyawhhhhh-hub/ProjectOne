---
date: 2026-10-09
tags: [gymarc, feature]
status: done
---
# GYM ARC - Leaderboards and Statue

Back to [[00 GYM ARC Home|GYM ARC Home]].

A wall leaderboard in the starter gym and a marble statue of the strongest player.

## How it works
- **Wall board:** above the front desk. One column per muscle group, top 5 each, a crown for #1. Updated every 2 minutes, shared by every server.
- **Ranking:** a higher Growth Spurt always ranks above any level from an earlier spurt.
- **Statue:** a marble statue of the strongest player (highest total), as tall as that player, in the entrance hall's back-left corner. It wears the static body stage meshes and can hold a pose.
- **Fresh start:** leaderboards were reset for the 9 Oct release (new stores), so test scores don't show.

## Where it lives
- `Config/ShowOff` (Leaderboard, Statue)
- `Server/ShowOffService`

## Planned change
- **New features prompt, task 4:** wall boards in each gym and the town plaza, top 10 each: Biggest (total look), Strongest (heaviest lift), Tallest (max 7'0"), Most Reps Today (daily), Posing Wins, Arm Wrestling Wins. Name + avatar headshot + value, "Your rank: #123" under each board. Update every 60-120 s; only boards near the player update.
- The [[GYM ARC - Posing Competition]] winner shows on the statue until the next round.

## Related
[[GYM ARC - Crews]], [[GYM ARC - Membership Card]], [[GYM ARC - Poses and Posing Stage]]

## Screenshots
![[GYM ARC/Screenshots/s1_statue_after.png]]
![[GYM ARC/Screenshots/poses_statue.png]]
![[GYM ARC/Screenshots/muscles_v4_statue_back.png]]
