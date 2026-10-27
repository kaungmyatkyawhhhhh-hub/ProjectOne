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
- **Full court** (27 Oct, owner: "the basketball match should be full court not a half court"): one game at a time on the whole court (the next pair waits in the queue). Player 1 attacks the north basket, player 2 the south (`Court.AttackHalf`). After a basket or a turnover, play restarts at centre court: the one with the ball just on their side of the centre circle, the defender between them and the basket (`Court.CenterSpots`). Out = past the court's lines (`Court.InCourt`). The replicated folder is `Matches.Full`.
- **Score:** first to 5 (2 inside the arc, 3 beyond it), or the most points when the 2:30 clock ends; a tie: the next basket wins.
- **Controls, no button:** press anywhere that isn't a button (a click, a tap; key F too). With the ball: hold, let go when the gold marker is in the teal green (stronger arms + shoulders = a wider green). Near the rim and 6'0" or taller: a DUNK at once (shorter players take a close shot). Defending: a tap steals (a block while they wind up). On a phone a sliding finger turns the camera and never shoots.
- **Shots:** the server decides every shot: distance (close / mid / three), the timing (perfect / good / off), a defender close in front (contested). A miss bounces off the rim: the first one close to the ball has the rebound.
- **Rules:** the ball handler out of the court = a turnover; after every basket play restarts at centre court (the scorer defends).
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

## COURT KING title (27 Oct, owner: "add a COURT KING title for wins")
- `Config/Titles` CourtKing: Epic, Social, "Win 5 games of 1v1 basketball on the town court" (stat `courtWins` >= 5; wins against the rival count too). CourtService checks titles after every win.

## Prompt 71: block, new moves, effects, sounds, music ([[2026-10-27 GYM ARC Basketball block, VFX, SFX, music resume, mirror fix]])
- **Block:** a tap while the shooter winds up, or in the first 0.32 s after the ball leaves their hand, within 5 studs: a jump with both arms up. 45% on the windup / 30% in flight, +12% when taller, half on a dunk; a blocked ball pops loose by the shooter. The rival blocks too. Hint: "TAP TO BLOCK!". `Config/Court.Block`.
- **Moves reworked:** a crossover dribble (the ball changes hands every 2 bounces, guard arm out, low when standing), the gather, the jump shot with a held goose-neck follow-through, the dunk (gather, knee drive, slam, hang on the rim, landing), the block jump, the steal lunge + sweep (also on a miss), defence, a fist pump after scoring.
- **Effects reworked** (textures from `Downloads/gym_arc_models/vfx`, `Config/Court.VFX`; Roblox built-ins until imported): dust + floor ring per bounce, release streaks + flash (gold stars on a perfect release), ball trail, net star burst (bigger on a three), rim sparks, dunk impact + floor shockwave + rim ring + shake, block impact + swoosh + stars, steal swoosh, winner confetti + gold glow.
- **Sounds:** CourtShot (release), CourtSwish, CourtRim, CourtDunk + CourtRattle, CourtBlock, CourtSteal, CourtCheer (dunks, blocks, threes), CourtOoh (misses), CourtBeep (3-2-1), CourtWhistle (out), plus the tip-off whistle and the final horn ([[GYM ARC - Music and Sounds]]).
- **Fixed from the owner's playtest:** a click near the sign right after a game started a new one (6 s lockout, the prompt hides in and after a match); the start toast covered the countdown; the daily reward window opened over a match; the camera after a basket faced the other player (now behind you, facing the rim, at every check); the idle scoreboard said "opens at Growth Spurt 4" to everyone (now the last result).
- Studio: Workspace `CourtLog` = true prints every play in the Output.
- (27 Oct) The 8 VFX textures are in (the owner imported them to the Myanmar Builders Club group) and set in `Config/Court.VFX`: CourtGlow 133239390087541, CourtSpark 120114519049039, CourtRing 135405721436283, CourtPuff 105919056943791, CourtStar 81083299144841, CourtImpact 126616960430184, CourtSwoosh 96262080134290, CourtConfetti 108985583024524. All 8 load in play; the floor shockwaves are real rings now.
- (27 Oct) Full court tested vs the rival: one "Full" game, each side scoring on its own basket (my close shot and dunk at the north basket, the rival's baskets at the south), the camera facing your own basket at every restart. The sign reads "FULL COURT · FIRST TO 5".

## Smoother moves (27 Oct, owner: "the basketball animations feel very laggy")
- Every joint now eases toward each move's pose and back into the walk / idle animation (no more snapping between dribble, gather, shot, block...). Your own moves start the instant you tap (the server only confirms): the gather on press, the jump shot on release, the dunk, the block jump and the steal swipe. The standing crouch has hysteresis (it no longer flickers on and off as you slow down). The server checks the game 20 times a second (was 7).
- The "Internal server error." lines seen once in Output: no script prints that text, and cloning the rival on the server didn't produce it; it didn't come back in later runs. Most likely a Roblox web request hiccup in Studio. The "ContentId 203785492 ... asset type" warning isn't from any script, model or avatar in the place (likely the TopbarPlus library).
