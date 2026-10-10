# Break A Bed: How It Works

#break-a-bed

Back to [[Break A Bed/Project Overview|Project Overview]].

## The map
- When the server starts, `WorldBuilder` builds everything from `GameConfig` into `Workspace.BreakABedWorld`:
  - `Path`: white fences down both sides and across the far end, lamps where tiles meet, and the "BED PATH" arch
  - `Beds`: `Bed1`…`Bed25`. Each has its own colored floor tile with the bed in the middle, a floating name tag (name, health, 💪 needed) and a "Break" prompt
  - `Training`: the training area, its sign, and the 12 training items on stands (4 × 3)
- Spawn is at the middle. The path runs away from spawn and the training area is off to the side.
- You stand on the right-hand side of a bed to chop it. The COMPLETED sign goes on its left.

## Strength, Level and Cash
- **Strength** goes up by the training item's amount on every chop.
- **Level** is worked out from Strength. Each level needs about 35% more Strength than the last (Level 2 at 4, Level 10 at 139, Level 20 at 3K, Level 50 at 24M), so levels keep coming all the way into the trillions. A "LEVEL UP!" banner shows when it goes up.
- **Damage per chop** on a bed = 1 + Strength ÷ 10 (rounded down).
- **Cash** comes from breaking beds and buys better training items.
- **Strength requirement:** each bed needs a minimum Strength before you can break it. Until then the prompt says "Need 💪 X" and the server refuses. At the requirement it takes about 30 chops (4 seconds).
- **How the numbers grow:** each bed has about 3.3× the health of the one before, needs health ÷ 3 Strength, and pays about 3× more Cash. Each training item is affordable around a certain bed and takes 1 to 3 minutes of training to reach the next couple of beds.

## Breaking a bed (or training)
1. Walk up and press **E** (or tap the button on mobile). The server locks you in place in front of the bed.
2. The camera zooms in from the side, the name tag hides, and the health panel, "Click to chop!" and **EXIT** appear.
3. Each click or tap is a karate chop: the arm swings up and slams down. At most about 8 chops a second (`GameConfig.ChopCooldown` = 0.12s; the server checks).
4. The server lowers the bed's health by your damage and sends back the new health.
5. At 0: you get the Cash, the bed is marked completed (saved), it splinters (only on your screen), cash pops out, and the COMPLETED ✅ sign appears. The bed respawns instantly at full health.
   - **First time you break that bed:** chopping stops, and after 1.4 seconds you're sent back to normal view (`GameConfig.FirstBreakExitDelay`).
   - **Bed already completed:** you stay in the break screen and keep breaking it for cash. The panel counts "Broken xN", and the hint says "Keep chopping for cash!".
6. **EXIT** stops at any time. The **SPAWN** button (top of the screen) also ends it and teleports you back to spawn.

**Per player / client-side:** bed health is kept separately for each player on the server. All break effects (flying pieces, wood chips, cash bills, the respawn blink, COMPLETED signs) are made by that player's own client in `Workspace.LocalFx`, which never reaches the server or other players. The real bed is never changed, so others always see a whole bed. Others only see your arm chopping. (Tested: right after a break the client had 31 pieces, the server had 0.)

Training works the same way, except the item never breaks and every chop adds Strength.

## Buying training items
- Items you don't own show **Buy $X** instead of **Train**.
- Press E with enough Cash to buy it. Without enough Cash you get "Need $X more Cash".

## Saving
- DataStore `BreakABed_v2` stores Cash, Strength, completed beds and owned items.
- Saves when you leave, every 2 minutes, and when the server shuts down.
- If loading fails, that player isn't saved for the session, so a failed load can't wipe real progress.

## Testing tips
- Turn on **Game Settings → Security → Enable Studio Access to API Services** to test saving in Studio.
- Give yourself Strength or Cash during a playtest: Studio command bar in **Server** mode → `game.Players.YOURNAME.leaderstats.Strength.Value = 1000` (Level updates by itself).
