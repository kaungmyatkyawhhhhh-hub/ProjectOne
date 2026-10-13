# Break A Bed: How It Works

#break-a-bed

Back to [[Break A Bed/Project Overview|Project Overview]].

## The map
- Since 2026-10-10 the whole map is **saved in the place as real models**, so it shows (and can be edited) in Studio without pressing Play. Workspace folders:
  - `Path`: `PathBase`, `Fences` (FenceLeft, FenceRight, FenceEnd), `Lamps`, `EntranceArch`
  - `Beds`: `Bed1`…`Bed25`. Each has its colored floor tile, cinder blocks (`Base`), the bed (`Bed`), a floating name sign (name, health, 💪 needed), a "Break" prompt, and two invisible markers: `StandPoint` (where you stand to chop) and `TargetPoint` (where hits land)
  - `TrainingArea`: floor, edges and `Posts` (17 posts on glowing pads, rows of five, cheapest nearest spawn)
  - `Upgrades`: the two upgrade boards with their green pads
  - `Signs`: `PathSign` ("BED PATH"), `TrainingSign`, `Leaderboard`, `CompletedSigns` (one COMPLETED ✅ sign per bed)
  - `Scenery`: trees, bushes, the spawn plaza and its lamps. Terrain and lighting are saved too.
- `ServerStorage.BedTemplates` has a copy of every bed. If a bed (or the bed part of it) goes missing, the game clones it back from there. Breaking itself happens only on each player's screen, so the real bed never actually disappears.
- At game start the scripts **load** these models instead of building them. Names, health, Strength needed and prices on signs are filled in from `GameConfig`, so they're always right. COMPLETED signs are handed to each player, who sees only their own.
- **Editing in Studio:** move or restyle anything. Move a bed as its whole `Bed<N>` model (the markers move with it), and move its `Completed<N>` sign along. Rebuilding the map from code (`WorldBuilder.build()`) would wipe hand edits, so Claude only does that if the owner asks.
- Spawn is at the middle. The path runs away from spawn and the training area is off to the side.
- You stand on the right-hand side of a bed to chop it. The COMPLETED sign goes on its left.

## Look and feel
- `Environment` sets up the lighting (afternoon sun, haze, bloom, sun rays, a slightly warm color grade, clouds), a grass field with trees and bushes, and the brick spawn plaza. The spawn pad is made invisible and flush with the plaza, with no force-field bubble.
- Plain dirt (not grass) goes under the path, plaza and training floor, because Roblox's 3D grass blades poke through thin floors.
- Sounds: real chop, wood-break, cash, level-up and click sounds from the Creator Store, plus background music. The 🔊 button next to SPAWN mutes the music. Sound ids are in `GameConfig.Sounds`.
- Every hit: the bed jolts and wobbles, dust puffs, the camera kicks. Every break: big splinters, dust cloud, white screen flash, flying cash and gold coins.

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
3. Each click or tap is the next punch of the combo: **left hook → right hook → uppercut**, then repeat. Hooks swing in from the side with the body twisting; the uppercut dips low and drives up with a little hop, hits harder and throws debris upward. The bed's shake and the damage number appear the moment the fist lands. At most about 8 punches a second (`GameConfig.ChopCooldown` = 0.12s; the server checks).
4. The server lowers the bed's health by your damage and sends back the new health.
5. At 0: you get the Cash, the bed is marked completed (saved), it splinters (only on your screen), cash pops out, and the COMPLETED ✅ sign appears. The bed respawns instantly at full health.
   - **First time you break that bed:** chopping stops, and after 1.4 seconds you're sent back to normal view (`GameConfig.FirstBreakExitDelay`).
   - **Bed already completed:** you stay in the break screen and keep breaking it for cash. The panel counts "Broken xN", and the hint says "Keep chopping for cash!".
6. **EXIT** stops at any time. The **SPAWN** button (top of the screen) also ends it and teleports you back to spawn.

**Per player / client-side:** bed health is kept separately for each player on the server. All break effects (flying pieces, wood chips, cash bills, the respawn blink, COMPLETED signs) are made by that player's own client in `Workspace.LocalFx`, which never reaches the server or other players. The real bed is never changed, so others always see a whole bed. Others only see your arm chopping. (Tested: right after a break the client had 31 pieces, the server had 0.)

## Training posts
- Stand on a post's glowing pad. A hint at the bottom says "Click to punch! +70 💪" (or the price, if it's locked).
- Each click is a straight punch: you turn to face the post, the post jolts, and "+70 💪" pops out. About 8 punches a second at most. The server checks that you own the post and are really standing on its pad.
- Locked posts: a 🔒 and the cash price float above them, and their pad glow is gray. Press **E** at the post, or click while standing on its pad, to buy it. Without enough Cash you see "Not enough money" in red above the post.
- Strength per punch: 1, 4, 17, 70, 290, 1.2K, 4.9K, 20K, 84K, 350K, then about ×4 each post up to 7.9B. Each post costs roughly what you earn from a handful of breaks of the bed you've just reached, so each one takes about 1–2 minutes to pay off.

## Change to build (owner 2026-10-12): training works like beds, auto training is free, Auto Punch is for beds only
**Built and tested 2026-10-12** (see [[Break A Bed/2026-10-12|2026-10-12]]). Auto training punches every 0.25 s (`GameConfig.AutoTrainInterval`), so clicking (up to 8/s) is faster. Walking/jumping now ends bed breaking too.

**Training posts use a ProximityPrompt, like beds:**
- Each training post gets a `ProximityPrompt` like the beds (same style, `HoldDuration` 0, `MaxActivationDistance` the same as the beds, key **E**, and a tap button on mobile).
  - Owned post: ActionText **"Train"**, ObjectText the post name and "+70 💪" (the real amount with passes and boosts).
  - Locked post: ActionText **"Buy"**, ObjectText the price ("$1.2K"). Pressing it buys the post (same "Not enough money" message), and the prompt turns into "Train".
- Pressing **Train** works like pressing E at a bed: the server locks you in place facing the post, the camera moves to the side view, the name tag hides, and a small panel shows the post name, "+70 💪 per punch" and an **EXIT** button. SPAWN also ends it.
- Remove the old "stand on the pad and click" training and its bottom hint. The pads stay only as decoration (keep their glow and lock color).

**Auto training is free for everyone:**
- Once you press Train, your character **punches by itself** (the left hook → right hook → uppercut combo) at the normal Auto Punch speed. Nobody needs a pass to train hands-free.
- Clicking or tapping still punches, so active players can go faster (up to the normal limit, `ChopCooldown` 0.12 s; the server checks). Break Spam still makes it faster.
- Training continues until the player presses EXIT or SPAWN, moves away (jump or walk input ends it, the same as beds) or leaves.
- The server gives the Strength per punch (owned-post check stays), so it can't be cheated.

**Auto Punch pass (R$149, id 2027108793) = beds only:**
- The pass now only auto-punches **beds**. It no longer does anything at training posts, because training auto-punches for everyone.
- The Auto Punch ON/OFF switch on the main screen only shows for owners and only matters at beds.
- Update the pass text everywhere (shop card and the Roblox pass description): **"AUTO PUNCH: breaks beds for you!"**
- Non-owners at a bed see a small hint in the break panel: "Auto break beds with **AUTO PUNCH**" with a buy button (once per session, never during the tutorial).

**Tutorial:** step 1 ("Punch to get stronger!") now says **"Press E to train!"** at the Straw Post. Step 2 finishes after 10 punches (auto punches count).

## Upgrades
- Two boards on the left of the spawn plaza, each with a green pad in front.
- **⚡ Training Speed:** multiplies the Strength from every punch. x1.00 to start, +0.15 per level (… x4.00 → x4.15 …), up to x10.00.
- **👟 Walk Speed:** 16 to start (Roblox's normal speed), +2 per level (… 34 → 36 …), up to 60.
- Each board shows *your* current → next value and the price; the price is red when you can't afford it.
- Step on the green pad to buy one level. Click while standing on it to buy more. Not enough Cash shows "Not enough money" in red above the board.
- Prices grow each level (Training Speed ×1.45, Walk Speed ×2), so x4.00 → x4.15 costs about $340K and 34 → 36 about $51K.

## Critical hits
- Each chop has a 1 in 10 chance to be a **CRITICAL!** hit (the server decides). It does 3× damage and pays bonus Cash right away: 10% of that bed's break reward (at least $1).
- On screen: big orange "CRITICAL!", the damage in orange, "+$X" in green, a harder jolt, an orange flash and a bigger camera shake.
- Settings: `GameConfig.CritChance`, `CritMultiplier`, `CritCashFraction`.

## Leaderboard sign
- The 🏆 **TOP Total Damage Dealt** sign stands on the right of the spawn plaza, next to the path arch, facing spawn.
- Every chop's damage adds to your **total damage** (saved). The sign shows the top 10 players across all servers: rank (gold/silver/bronze for the top 3), avatar, name and total.
- It refreshes every 3 minutes (`GameConfig.LeaderboardRefresh`). The bottom shows *your* total and "Refreshes in m:ss".
- Players in the same server always count with their live totals, so the board works in Studio even when saving is off.
- Behind the scenes the scores are stored on a log scale, because Roblox's leaderboard storage can't hold numbers past ~9 quintillion.

## Group Reward
- A pink 🎁 button on the right of the screen (under the stats), with a red "!" until claimed. It opens a panel with **JOIN GROUP** (Roblox's own join pop-up) and **CLAIM**.
- Claiming checks you're in the group, then gives **+10% Strength from every punch, forever** (saved). Not in the group: "Join the group first, then claim!".
- The group is set by `GameConfig.GroupId` (the number in the group's web link). While it's 0 the panel says "Coming soon".

## Robux shop and free rewards (2026-10-11)
- **All ids are in `GameConfig`** (the "Robux shop" section). 0 = the button says "Coming soon". Buttons show Roblox's real price once the item exists.
- **Strength tier button:** one gold button always offers the next multiplier pass: x2 (R$19) → x3 (39) → x5 (79) → x7 (149) → x10 (249) → x15 (399) (real prices on Roblox, 2026-10-12). Each is its own game pass. Only your highest one counts (they don't add up). When you own all of them it says "MAX x15". The old x2 pass is tier 1.
- **Passes:** Auto Punch (punches for you at beds, with an AUTO ON/OFF button; from 2026-10-12 training auto-punches for free, see "Change to build" above), x2 Cash, VIP (+20% Strength and Cash, gold [VIP] chat tag, the VIP lounge), Fast Walk (+12 speed), Break Spam (punch almost twice as fast).
- **Developer products:** +1/+3/+9 Levels, x2 Strength and x2 Cash boosts (15 minutes, timer under the top bar, buying again adds time, saved and only counting down while playing), +3/+10 spins, and three Cash packs that grow with your progress (30/120/400 breaks of the best bed you've completed).
- **Safety:** products are only given after Roblox confirms the purchase, only once your save has loaded, and each purchase only once (saved). Passes are checked when you join and right after buying.
- **Free rewards:** daily reward (7-day streak, missing a day starts again at day 1, pops up when you join), a playtime gift every 5 minutes (every 3rd one adds a spin), and a spin wheel (a free spin every 4 hours, plus spins from rewards and the shop; the server picks the prize).
- **Screen:** PC has SHOP, the tier button, SPIN, GIFT and AUTO on the left. Phones only have SHOP and the tier button (top-left); a red "!" on SHOP means something free is ready. The SHOP panel has tabs: PASSES, BOOSTS, CASH, FREE.
- **VIP lounge:** a glass room with a gold door behind-left of spawn. Only VIPs can walk through the door (anyone else who gets in is put back outside). Inside: the VIP post (2x your best training post), sofas, lamps.

## Look, numbers and phones
- **Text:** the bold, rounded FredokaOne font everywhere, with a thick dark outline that grows with the text size (big numbers get big outlines).
- **Short numbers:** 1.14M, 1.9T, 392Qa (K, M, B, T, Qa, Qi, Sx, Sp, Oc, No, Dc). Roblox's own player list shows them short too: the real numbers live in a hidden `Stats` folder, and `leaderstats` only shows the short text.
- **Punching:** the left hook → right hook → uppercut combo, on beds and training posts alike.
- **UI style:** chunky buttons (coloured top on a darker bottom edge, bounce on hover, squish when pressed), navy panels, one bold font with thick outlines, and drawn icons for cash (green note), strength (yellow dumbbell), lock and gift. No emoji anywhere, in the HUD or on world signs. Green = cash, yellow = strength, red = exit/errors.
- **SPAWN button:** only shows on the bed path. An invisible part, `Workspace.Path.BedPathZone`, covers the path (move or resize it in Studio to change the area). The button fades in when you walk onto the path, fades out when you leave, and hides in the break screen.
- **To Bed button (owner, 2026-10-13):** teleports you to the best bed you can break right now. The owner added it and asked Claude Code to build it.
- **No lag when breaking fast:** all effects are only on your screen. Debris chunks, bills and coins are reused from capped pools (36 / 24 / 12), never collide with each other and vanish in about a second. When beds break several times in 2 seconds, effects automatically get smaller (fewer pieces and bills, no sparkles/flash). At most 10 floating numbers show at once.
- **Bed breaks:** 18 flying cash bills in three shades of green, spinning gold coins, gold sparkles, party confetti, dust, a white flash and the "+$X" pop-up.
- **Phones:** tap to chop or punch, and prompts show a tap button. The HUD (stats, SPAWN, shop, gift button, break-mode panel) shrinks on short screens, down to 65%, so it stays clear of the thumbstick and jump button.

## Saving
- DataStore `BreakABed_v2` stores Cash, Strength, completed beds, owned training posts, upgrade levels, total damage, whether the group reward was claimed and recent Robux purchases. The leaderboard uses its own store, `BreakABed_TotalDamage_v1`.
- Saves every minute, about 6 seconds after big moments (first break of a bed, buying a post or upgrade, claiming the group reward), right away after a Robux purchase, when you leave, and when a server closes (it waits for every save to finish).
- Each save and load is tried up to 3 times, so a short Roblox hiccup doesn't lose progress.
- If loading still fails, that player isn't saved for the session, so a failed load can't wipe real progress.

## Testing tips
- Turn on **Game Settings → Security → Enable Studio Access to API Services** to test saving in Studio.
- Give yourself Strength or Cash during a playtest: Studio command bar in **Server** mode → `game.Players.YOURNAME.Stats.Strength.Value = 1000` (Level updates by itself). Use `Stats`, not `leaderstats`, which only holds the short text.

## HUD layout and prompts (2026-10-11)
- The HUD goes right up to the top edge (10 px gap) but stays inside phone notches and rounded corners (`DeviceSafeInsets`). Only the top-left corner is kept for Roblox's menu/chat/mic buttons (the phone SHOP button sits below them). It shrinks on short screens.
- All "Break" / "Buy" prompts are Roblox's default style again (E key, "Break", bed name). The custom one was removed.

## Map zones, screen effects, sounds (2026-10-11)
- **Decor** (server module, run once in Edit mode, safe to re-run): lighting, the 5 zones (colours, gates, props, particles), the hub title and signpost, hills, pond, flowers. It only recolours the path/beds, never rebuilds them, so hand edits stay.
- **Ambient** (on each player's screen): makes floating things bob and spin, and flies butterflies around the flowers.
- **ScreenFx** (on each player's screen): edge glow, speed lines, break pulse, flying cash/strength icons, combo text.
- **Sounds** play on your own screen; nearby players hear a quieter version.

## City backdrop (2026-10-11)
- **City** (server module, run once in Edit mode, safe to re-run): removed the trees, bushes, hills and pond outside the play area, flattened and widened the grass, then built a city around the map in `Workspace.City`: roads with sidewalks, lamps and parked cars; houses and shops (with signs) in front, apartments and hotels behind, glass towers further back; and three landmarks: **BED MART** (east of spawn, giant bed on the roof), **MATTRESS FACTORY** (west, halfway down the path, smoking chimneys) and the **GRAND SLEEP HOTEL** (past the end of the path).
- Nothing is built inside the play area (path, plaza, upgrades, training). About 4,450 parts, anchored, no collisions, only the main building blocks cast shadows.
