---
date: 2026-10-27
tags: [gymarc, feature]
status: done
---
# GYM ARC - Court Competitions

Back to [[00 GYM ARC Home|GYM ARC Home]].

1v1 basketball on the town court (`Town.SportsCourt`). Owner, 27 Oct (prompt 70): "the court needs to be playable like competitions", then "1v1", "growth spurt 4", "make it a 5 point game", "dont put a button. make it so that u can press anywhere and it steals/shoots", "put soundeffects and vfx", "dunk when ur near the rim and over 6'0", "remove the skate button and itembar while playing basketball", "the scoreboard gui is annoying", "put dribbling, dunking, shooting, stealing animations with vfx".

## How it plays
- **Join:** the PLAY 1V1 prompt on the sign by the court gate (from Growth Spurt 4; earlier: "opens at Growth Spurt 4"). Two players in the queue get a match; alone for 12 s, a rival NPC (a gym regular's look, a name like Rico / Dash) steps in.
- **Two games at once:** each half of the court is its own match (South / North).
- **Score:** first to 5 (2 inside the arc, 3 beyond it), or the most points when the 2:30 clock ends; a tie: the next basket wins.
- **Controls, no button:** press anywhere that isn't a button (a click, a tap; key F too). With the ball: hold, let go when the gold marker is in the teal green (stronger arms + shoulders = a wider green). Near the rim and 6'0" or taller: a DUNK at once (shorter players take a close shot). Defending: a tap steals (a block while they wind up). On a phone a sliding finger turns the camera and never shoots.
- **Shots:** the server decides every shot: distance (close / mid / three), the timing (perfect / good / off), a defender close in front (contested). A miss bounces off the rim: the first one close to the ball has the rebound.
- **Rules:** the ball handler out of their half = a turnover; after every basket both go back to a check (the scorer defends).
- **Rewards:** win 4 min of coins at your stage (at least 200), lose 1 min (at least 50); vs the rival 60%; a win under 2 points (a quick forfeit) pays like a loss; leaving = nothing. `stats.courtWins` counts wins. A one-time "1V1 COURT OPEN!" toast at Growth Spurt 4 (`stats.courtUnlocked`).

## What players see
- The ball (`CourtBall` in ReplicatedStorage once the court model is in; a leather sphere until then): dribbled by the ball handler, over the head while winding up, an arc to the rim with a trail (gold after your perfect release), through the net or off the rim, resting on the floor as a rebound.
- **Moves (code-made joint poses, for everyone near):** dribbling (right arm pumps with the ball, left arm guards), defence (low, arms wide, hands moving), the shooting crouch with the ball overhead, the jump shot with a wrist flick, the dunk (a big hop, knees tucked, a one-arm slam), the steal (a lunge and swipe).
- **Effects:** a dust puff on each bounce, a spark on release, gold sparks through the net, a gold burst + shockwave ring + camera shake on a dunk, white sparks off the rim, a blue flash on a steal / block, confetti over the winner.
- **Sounds** (licensed library, [[GYM ARC - Music and Sounds]]): dribble bounces, net swish, rim clank, dunk slam, steal whoosh, the referee whistle at tip-off, the air horn + applause at the end.
- **HUD:** a slim pill at the top (YOU 2 · 1:20 · 2 RICO, your score in gold), a small line under it (what to do, or the last play), the shot meter while holding, LEAVE bottom left. Toasts sit under the pill. The skate button and the item bar hide during a match, and your trainer is hidden. The court's own scoreboard shows the live score for everyone.

## Where it lives
- `Config/Court` (all numbers), `CourtService` (server), `CourtClient` (ball, moves, effects, HUD), `Town.SportsCourt.CourtSign` (the sign + prompt), `Town.SportsCourt.Matches` (the replicated state), `Town.SportsCourt.Scoreboard` (the score board).
- Also touched: `SkateService` (no skating in a match), `SkateClient` / `HotbarClient` (hidden in a match), `TrainerFollowClient` (trainer hidden), `Config/Sounds` (Court* sounds), `Main` (starts CourtService).
- Studio test: Workspace `TestCourt` = true makes the rival step in after 1 s.

## Related
[[GYM ARC - Town and Gyms]], [[GYM ARC - Strongman Yard]], [[GYM ARC - Posing Competition]], [[2026-10-27 GYM ARC 1v1 court and court model]]
