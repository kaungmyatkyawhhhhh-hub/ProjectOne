---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Posing Competition

Back to [[00 GYM ARC Home|GYM ARC Home]].

A posing contest on the beach stage every 12 minutes: three poses, judges' cards, an audience vote, a podium, coins, a title and the statue for the winner. Built 13 Oct (new features run, task 1).

## How it works
- **Countdown:** every 12 minutes the whole server gets a 60 s countdown: a small banner at the top of the right column, a marker over the stage (with the distance) and an arrow on the screen while the stage is out of view.
- **Joining:** stand on the stage when the countdown ends. Up to 6 contestants (closest to the middle first). Nobody lifting or skating joins.
- **NPC bodybuilders:** with fewer than 2 contestants, NPCs fill up to 3 (Marco Vance, Jade Rivers, Theo Banks, Kai Summers, Nina Cruz), so a solo player can still compete.
- **The round:** contestants stand on the taped marks and get the crowd's view of the stage. Three poses: Front double biceps, Lat spread, Most muscular. A ring closes on a big POSE button: tap when it closes (Space or gamepad A work too). The server times every tap (Perfect, Good, Late, Early, Missed). A missed tap still poses, with no timing bonus.
- **Judges:** after each pose a card from 1 to 10 goes up above every contestant. Score = 55% muscle size + 25% balance between the groups + 20% timing.
- **Audience vote:** players within 150 studs who are not on the stage get a vote panel during the last pose. Each vote adds 0.5 points (max 2). Nobody can vote for themselves.
- **Results:** the top 3 stand on the podium for 10 s. Coins: 150 / 90 / 50, and 10 for everyone else who finished. A winning player gets the title "Posing Champion" and becomes the marble statue in the entrance hall (with their own muscles, plaque "Posing champion: name") until the next round. If an NPC wins, the statue goes back to the strongest lifter.
- **Dropping out:** leaving the stage, resetting or leaving the game = out of the round, no reward.
- **Scoreboard:** a screen beside the stage shows the countdown, the pose and the running totals, then the last results.

## Where it lives
- `Config/PosingComp` (every number), `Server/PosingCompService`, `PosingCompClient`
- Stage pieces: `Workspace.Town.PosingStage.Feature_PosingComp` (marks, podium, scoreboard), built by `tools/builders/PosingComp`
- Stats `posingWins` and `posingEntries`; the title in `Config/Titles`
- Studio test switches: `TestPosingComp` (start now), `TestPosingCountdown` (seconds), `TestPosingWatch` (NPCs only, so you can vote)
- Numbers: [[GYM ARC - Config values]]; sounds: [[GYM ARC - Music and Sounds]]

## Not tested yet
- Two real players (spotting each other's votes, two contestants), and the phone emulator.

## Related
[[GYM ARC - Poses and Posing Stage]], [[GYM ARC - Leaderboards and Statue]], [[GYM ARC - Titles]], [[2026-10-13 GYM ARC New features run]]

## Screenshots
![[GYM ARC/Screenshots/posing_countdown_banner_arrow.jpg]]
![[GYM ARC/Screenshots/posing_3_contestants_score_cards.jpg]]
![[GYM ARC/Screenshots/posing_vote_panel.jpg]]
![[GYM ARC/Screenshots/posing_podium.jpg]]
![[GYM ARC/Screenshots/posing_statue_champion.jpg]]

## Avatar headshots (14 Oct)
Player pictures here are the real Roblox avatar headshot in a plain dark circle (the same look everywhere, see [[GYM ARC - Loading Screen and Menu]]).

## Posing show every 5 minutes (21 Oct, prompt 18) - replaces "How it works" above
- **Schedule:** a show every 5 min (`PosingComp.Interval = 300`). Players with a Growth Spurt see a small pill in the right column: "POSING SHOW 2:30". In the last 30 s it glows gold with a **JOIN** button (from far away or another gym it puts you on the stage; close by it draws a glowing path) and the stage top glows. On the stage the pill says "ON STAGE". Tap the pill for your show stats. Nobody is pulled out of training.
- **Divisions** by height, run one after another, smallest first: Bantam (under 5'0"), Middle (5'0"-6'0"), Heavy (over 6'0"), Open (7'0"; by alter tier later). Up to 8 per division; NPC competitors (sized for the division) fill a small one so it never feels empty.
- **The show** (under 60 s per division): line up, the judges call Side chest, Front double biceps, Back double biceps, Abs and thigh (5 s each), everyone hits each pose together; crowd sound and camera flashes. Contestants get the stage camera. (The old timing tap and the audience vote are gone.)
- **Judging** (out of 100, all numbers in `Config/PosingComp`): size 60 (compared to the best size in the division), balance 25, stage presence 15 (height; alter tier later). Nothing bought changes a score. Everyone sees "Size 52 / Balance 21 / Presence 11 = 84".
- **Results:** top 3 on the podium with confetti and the fanfare; the winner is told to the whole server; 1st gets a trophy. Prizes by the player's show: Local (Spurt 1) 150/90/60, Regional (2) 300/180/120, National (4) 700/420/280, Pro Card Qualifier (5) 1200/720/480, Universe Championship (7'0") 2000/1200/800; everyone else 25-250 and "Good effort!".
- **Stats:** posingEntries, posingWins, posingTrophies, posingBest. **Titles:** Stage Debut (first show), Posing Champion (first win), Stage Veteran (10 wins), Stage Legend (50 wins).
- **Analytics** (custom events): PosingTimerSeen, PosingJoinTapped, PosingCompeted, PosingPlaced (1/2/3, 4 = other).
- Studio: `TestPosingComp` + `TestPosingCountdown` (seconds), `TestPosingWatch` (NPC-only show).

![[GYM ARC/Screenshots/posing_show/timer_join_phone.jpg]]
![[GYM ARC/Screenshots/posing_show/judges_panel.jpg]]
