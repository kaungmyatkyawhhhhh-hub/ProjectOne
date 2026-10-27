---
date: 2026-10-27
tags: [gymarc, feature]
status: planned
---
# GYM ARC - Court Competitions

Back to [[00 GYM ARC Home|GYM ARC Home]].

Owner (27 Oct, prompt 70): "later in the game, the court needs to be playable like competitions". The basketball court in town (`Town.SportsCourt`, rebuilt in prompt 69) becomes a competition venue for later-game players, like the Strongman Showdown and the Posing Competition.

## Proposed (not built yet, waiting for the owner's choices)
- **Format:** a HOOP SHOOTOUT, a three-point-contest style round. Each player takes shots from 5 spots around the arc, about 60 s per round. Tap when a moving meter is in the green; arm and shoulder strength widen the green, so training still matters. Works well on phones and with any number of players. (Other options: 1v1 to 11 points, or 3v3; both are much bigger to build and need matchmaking.)
- **Schedule:** every 15 minutes, like the Showdown, with a warning toast and a GO TO button. Live scoreboard on the court's existing Scoreboard.
- **Rewards:** top 3 paid from `Config/Economy.Rewards` (minutes of coins at the player's stage, like the Showdown), everyone who joins gets a little. A COURT KING title for 1st (only titles the owner approves).
- **Unlock "later in the game":** a gate like the Strongman Yard (Alter 2) or a Growth Spurt. Until then the court is a locked decoration with a sign.
- **Built like the others:** server-run rounds and scores (validated remotes, all coins through PlayerData), a Config file for the numbers, Studio test hook `TestShootout`.

## Open questions for the owner
1. Build it now, or later?
2. Format: Hoop Shootout, 1v1, or 3v3?
3. Unlock: which Growth Spurt or Alter?

## Related
[[GYM ARC - Town and Gyms]], [[GYM ARC - Strongman Yard]], [[GYM ARC - Posing Competition]]
