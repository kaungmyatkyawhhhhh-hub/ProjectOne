---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Leaderboards and Statue

Back to [[00 GYM ARC Home|GYM ARC Home]].

A wall leaderboard in the starter gym and a marble statue of the strongest player.

## Leaderboard walls (built 13 Oct, new features run task 4)
- **Six boards, top 10 each:** Biggest (most muscle, "Size 142"), Strongest (heaviest weight ever lifted), Tallest (height, up to 7'0"), Most reps today (resets every UTC day), Posing wins, Arm wrestling wins.
- **Where:** a board wall in the starter gym (front wall, left of the hall door, above the windows), one in the pro gym (above the front glass) and a freestanding stand at the north edge of the town plaza. Each wall has six framed screens under a "LEADERBOARDS" header with a light strip.
- **Each row:** rank (#1 in gold), the player's Roblox headshot, name and value. Your own name shows in light blue.
- **Your rank:** under each board, "You're #3!" when you're on it, "Your rank: #23" when you're in the top 100, "Your rank: 100+" below that.
- **How it updates:** every 90 seconds the server saves each player's values (only when they changed; never for Studio test players), reads every board's top 100 and sends it to all players. Only the boards near you are drawn.
- **Where it lives:** `Config/Leaderboards`, `Server/LeaderboardService`, `LeaderboardClient`; walls built by `tools/builders/Leaderboards` (`Feature_Leaderboards` folders). Studio test switch: `TestLeaderboards`.
- The older per-muscle-group board above the front desk and the statue (below) are unchanged.

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
![[GYM ARC/Screenshots/leaderboards_starter_gym.jpg]]
![[GYM ARC/Screenshots/leaderboards_pro_gym.jpg]]
![[GYM ARC/Screenshots/leaderboards_town_plaza.jpg]]

## Avatar headshots (14 Oct)
Player pictures here are the real Roblox avatar headshot in a plain dark circle (the same look everywhere, see [[GYM ARC - Loading Screen and Menu]]).

## The statue is the real player's body (19 Oct)
The statue reads the strongest player's save (read-only) and is built with their own widths and muscles, like their real character (before: a generic fully grown body). The posing champion's values are kept from when they won. It rebuilds when the player's widths or muscles change. Studio: Workspace attribute `TestStatueMe` = true makes you the statue. See [[GYM ARC - Bug - Mirror and statue bodies too narrow]].

## Alters and Level boards (24 Oct, owner)
- Two new boards: **ALTERS** (highest Body Alter, "Alter 5") and **LEVEL** (the best top bar LVL ever = average muscle level, "LVL 305"; sub "Best ever"). `Config/Leaderboards` + `Server/LeaderboardService`; stores `LB1_Alters`, `LB1_Level`.
- On the **Pro Gym wall** and the **town stand** (both now 8 panels, frames / header / trims / posts stretched). The **starter gym wall keeps its 6**: no room (the side wall on one end, the Personal Trainers desk under the other).
- Best ever (owner, 24 Oct): `stats.bestLevel`, noted by `PlayerData.NoteBestLevel` before a Growth Spurt / alter resets the muscles and on every board write. Old saves start from their current LVL.

## Reset and top 25 (28 Oct, prompt 79; [[2026-10-28 GYM ARC Leaderboard reset, trainer slots, pity stages]])
- All boards reset: stores are now `LB2_<board>` (fresh). Players reappear as they play.
- Every board shows the **top 25**, scrollable (10 rows visible; the extra rows are added on the client by `LeaderboardClient.scrollRows`).
- (28 Oct) **LEVEL board removed** (it duplicated STRONGEST LIFTER). Boards now: Biggest, Strongest lifter (best LVL ever), Tallest, Most reps today, Posing wins, Arm wrestling, Alters. The Town / Pro Gym rows have 7 panels, evenly spaced; the old LEVEL panels are in `ServerStorage._Removed_LevelBoards_28Oct`.
