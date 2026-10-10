# Break A Bed: How It Works

#break-a-bed

Back to [[Break A Bed/Project Overview|Project Overview]].

## The game loop
1. When the server starts, `BedServer` reads the layout in `BedConfig` and builds a floor pad and a bed for each spot (in folders `Workspace.Beds` and `Workspace.BedPads`).
2. Each bed has a ClickDetector (range 14 studs). A click goes to the server, which checks: cooldown, player alive, enough rebirths.
3. The server lowers the bed's health, updates its health bar, and tells every player's screen to show the hit effects.
4. At 0 health the server pays coins, moves the bed to `Workspace.BedDebris`, unanchors its parts so they fly apart, fades them out after 3s, and builds a new bed after 5s.

## Coins
- Each player who hit the bed gets `reward × (their damage ÷ bed health) × their rebirth bonus`, rounded, minimum 1.
- Coins and rebirths are in `leaderstats` (shown on the player list).

## Rebirths
- **Cost:** 500 coins, then each one costs 2.5× the last (500, 1,250, 3,125, 7,812…).
- **What you lose:** all your coins.
- **What you get:** +1 damage per hit and +50% coins, forever, plus access to the next locked beds.
- The server does the check (`RequestRebirth` remote). The rebirth panel and confirm dialog are only the screen side.

## Locked beds
- Each bed type can have `RequiredRebirths` in `BedConfig`.
- **Server:** refuses hits from players with fewer rebirths and sends them a "Needs N Rebirths" message.
- **Each player's screen:** shows or hides the 🔒 on the health bar based on that player's rebirths.

## Saving
- DataStore `BreakABed_Coins_v1`, key `u<UserId>`, value `{ Coins, Rebirths }`. Older saves that are just a number still load as coins.
- Saves when you leave, every 2 minutes, and when the server shuts down.
- If loading fails, that player's progress isn't saved for the session, so a failed load can't wipe real progress.

## Testing tips
- Turn on **Game Settings → Security → Enable Studio Access to API Services** to test saving in Studio.
- Give yourself coins during a playtest: Studio command bar in **Server** mode → `game.Players.YOURNAME.leaderstats.Coins.Value = 1000`
