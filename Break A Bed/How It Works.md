# Break A Bed: How It Works

#break-a-bed

Back to [[Break A Bed/Project Overview|Project Overview]].

## The map
- When the server starts, `WorldBuilder` builds everything from `GameConfig` into `Workspace.BreakABedWorld`:
  - `Path`: the path, borders, lamp posts and the "BED PATH" arch
  - `Beds`: `Bed1`…`Bed15`, each on cinder blocks with a rug, a floating name tag and a "Break" prompt
  - `Training`: the training area, its sign, and the six training items on stands
- Spawn is at the middle. The path runs away from spawn and the training area is off to the side.
- Beds alternate left and right of the path.

## Strength, Level and Cash
- **Strength** goes up by the training item's amount on every chop.
- **Level** is worked out from Strength: Level L needs 5 × (L − 1)² Strength (Level 2 at 5, Level 5 at 80, Level 10 at 405). A "LEVEL UP!" banner shows when it goes up.
- **Damage per chop** on a bed = 1 + Strength ÷ 10 (rounded down).
- **Cash** comes from breaking beds and buys better training items.

## Breaking a bed (or training)
1. Walk up and press **E** (or tap the button on mobile). The server locks you in place in front of the bed.
2. The camera zooms in from the side, the name tag hides, and the health panel, "Click to chop!" and **EXIT** appear.
3. Each click or tap is a karate chop: the arm swings up and slams down. At most 4 chops a second (the server checks).
4. The server lowers the bed's health by your damage and sends back the new health.
5. At 0: you get the Cash, the bed is marked completed, it splinters (only on your screen), cash pops out, and the COMPLETED ✅ sign appears. After 1.4 seconds you're released. The bed is back for you after 5 seconds.
6. **EXIT** stops at any time.

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
