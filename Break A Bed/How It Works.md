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
  - **Position (owner, 2026-10-13):** at spawn (off the bed path), To Bed sits alone, **centered** at the top middle. When you walk onto the bed path, SPAWN fades/scales in and To Bed **slides to the side in 0.4 s** (Quad Out), so the two sit side by side, centered as a pair (To Bed left, SPAWN right). Leaving the path reverses it: SPAWN fades out and To Bed slides back to the center in 0.4 s.
  - Both buttons keep the **same size and their full labels**. Never shrink To Bed to an icon with a "1" (that happened in a test).
  - The tutorial's To Bed/SPAWN highlight follows the buttons as they move.
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

## City backdrop (2026-10-11, removed by the owner 2026-10-13: clean map wanted)
- **City** (server module, run once in Edit mode, safe to re-run): removed the trees, bushes, hills and pond outside the play area, flattened and widened the grass, then built a city around the map in `Workspace.City`: roads with sidewalks, lamps and parked cars; houses and shops (with signs) in front, apartments and hotels behind, glass towers further back; and three landmarks: **BED MART** (east of spawn, giant bed on the roof), **MATTRESS FACTORY** (west, halfway down the path, smoking chimneys) and the **GRAND SLEEP HOTEL** (past the end of the path).
- Nothing is built inside the play area (path, plaza, upgrades, training). About 4,450 parts, anchored, no collisions, only the main building blocks cast shadows.

## AFK training (owner, 2026-10-13)
**Built 2026-10-13** (client `AfkTraining`, GameServer `afkRejoin`), see [[Break A Bed/2026-10-13|2026-10-13]]. Live test still to do.
- **The message:** when a player starts training, a green text "**AFK-friendly!**" with "**While training, you won't be kicked.**" under it shows in the lower middle of the screen. It's bold, with a thick dark outline (like the owner's screenshot). It fades in, stays **3 seconds** and fades out. It shows again at most once every **10 minutes** for that player (the cooldown resets when they rejoin).
- **No AFK kick while training:** Roblox kicks players who are idle for 20 minutes. If a player has been idle for **15 minutes while training** (`LocalPlayer.Idled` gives the idle time), the game moves them before the kick:
  1. The server saves a Resume entry (the same idea as [[Break A Bed/Soft Shutdown|Soft Shutdown]]): "training at post X", plus their position.
  2. It teleports them back into **the same server** (`TeleportToPlaceInstance` with this server's JobId), or into any server of the game if that one is full.
  3. On arrival they're put straight back at the same post with **training running again** automatically, so the AFK earnings keep going. A small toast says "Still training! 💪".
- This happens only while training. Players who are idle anywhere else get Roblox's normal kick.
- A short fade to black hides the teleport. Saving happens before the teleport, so nothing is lost.


## Camera fix for breaking and training (owner, 2026-10-14)
**Built 2026-10-14** (client `SessionCamera`), see [[Break A Bed/2026-10-14|2026-10-14]].
**Problem:** on phones the break camera sits too close, behind the player's back, and the big beds (Diamond Bed) fill half the screen. You can't see the character's punch or the bed properly. Training has the same issue.
**New camera (same for breaking and training):**
- A fixed **3/4 side view**: the camera is about **45° to the side** of the player, **slightly above** (looks down about 15–20°), and far enough back that the **whole character and the whole bed/post** fit on screen, with the bed a bit right of center. The distance is worked out from the bed's size, so big beds pull the camera further back.
- The camera never goes inside or behind the bed. Place it on the open side (path side), never clipping through the bed, fences or other beds. If something blocks the view, move to the other side.
- It smoothly glides into place in **0.4 s** (Quad Out) on Break/Train, and back to the normal camera in 0.4 s on EXIT, SPAWN or To Bed.
- It stays still while punching. Only the existing small hit shake/kick plays.
- It must look right on **phone landscape and PC**, and the health panel, "Next" bar and EXIT must not cover the character or the bed.

## Training and breaking feel, like the reference game (owner, 2026-10-14)
**Built 2026-10-15**, see [[Break A Bed/2026-10-15|2026-10-15]] (also the two sections below).
The owner sent screenshots of a reference game and wants ours to feel like it. Art and sound are in `Models/juice/` (made by Claude): `bicep.png`, `cube_x2/x3/x5.png`, `cash_bill.png`, `cash_stack_hex.png`, `pieces_break.ogg`. Preview: ![[Models/juice/sheet.png]]

### Training
- **Auto train is the fastest possible.** Auto punches at the maximum punch rate (the same as the fastest allowed clicking, about 8 a second), so clicking is never faster. Remove the "Click to punch 2x faster!" hint.
- **Strength popups:** every punch pops a yellow **bicep icon with "+4"** (the real gain, short numbers like +1.2K) from the post. It floats up and to the side with a little bounce and fades out after ~0.8 s. It's a BillboardGui with `bicep.png` and white bold text with a thick black outline, and a few can be on screen at once.
- **Multiplier cubes:** while training, glowing cubes pop up on the floor of your training pad, within reach, every ~4–6 s, and stay 6 s, bobbing and spinning slowly:

  | Cube | Chance | Effect |
  |---|---|---|
  | **X2** (green) | common, 70% | 10 s of x2 training Strength |
  | **X3** (blue) | uncommon, 25% | 10 s of x3 |
  | **X5** (purple, sparkles + glow) | rare, 5% | 10 s of x5, with a "RARE!" pop |

  - Collect one by **clicking/tapping it** (you're locked in place while training). It pops with a burst in its color and a sound.
  - Only the highest active one counts. A collected cube restarts its 10 s timer. A small "X3 10s" chip shows the timer.
  - The cube is a Part with the cube image on all 6 faces (Decals) plus a soft glow. Only you see your own cubes.
  - The strength popups show the multiplied number while a cube is active.
- **Change (owner, 2026-10-14): the X2 / X3 / X5 pickups are on the SCREEN, not 3D cubes in the world.** Remove the 3D cube parts. While training:
  - Every ~4–6 s, a square **X2 / X3 / X5 button** (the same `cube_x2/x3/x5.png` images, ~11% of screen height) **pops onto the screen** at a random spot in the middle area. It never covers the HUD, the side buttons, the top bar or the training panel.
  - It pops in with a bounce (scale 0 → 1.15 → 1, 0.25 s), wobbles gently, and has a soft glow behind it (X5 also sparkles and shows a small "RARE!" tag). It stays 4 s, then shrinks away.
  - **Tap/click it** to collect: it bursts into small stars of its color, flies into a timer chip near the Strength stat ("X3 10s"), and gives the 10 s boost. Same chances (X2 70%, X3 25%, X5 5%), and the highest active one counts.
  - At most 1 on screen at a time. Only during training.
  - **Timer chip design (owner: "make this UI better", 2026-10-14).** Mockup: ![[Models/juice/boost_chip_mockup.png]]
    - The **cube icon is big** (as tall as the chip plus a bit more), tilted ~12°, with a drop shadow, and overlaps the chip's left end.
    - The chip is a dark rounded panel (UI Kit studs) with a **2-layer border**: black outside, the boost's color inside (green X2, blue X3, purple X5), plus a soft outer glow in that color.
    - The top line reads "**x2 STRENGTH**" on the left and the seconds "**7s**" on the right, in white bold text with a black outline.
    - Underneath is a **countdown bar** in the boost color that shrinks smoothly (not in steps).
    - When collected, the chip slides in from the left with a bounce. In the **last 3 s** it pulses and the bar blinks. When it ends, it shrinks away. If a new pickup restarts the timer, the bar refills with a quick flash.
    - Size: about 9% of screen height. It sits just above the Strength stat, never over buttons.

- **Camera:** training uses the **normal free camera**. The player can rotate and zoom around while locked in place, instead of the fixed side view. It starts behind the player looking at the post.

### Breaking beds
- **Camera:** like the reference: from the **front**, slightly above, on the other side of the bed, looking at the player's face with the bed between. Close enough that the player and bed fill the middle of the screen.
- **Prompt style:** every ProximityPrompt looks like the reference: a big **white square key with a thick black border** and the letter in bold black, then the action word ("Break", "Train", "Buy") in **big bold white text with a thick black outline**. No panel or background.
- **When a bed breaks:**
  - The bed **shatters into many pieces** (planks, frame, mattress chunks, pillow), cut from its parts. They fly out, fall, bounce and scatter on the ground. They fade after ~3 s, client side.
  - **`pieces_break.ogg`** plays: a crack, then many pieces knocking on the ground.
  - **Screen money:** 15–25 cartoon **cash bills** (`cash_bill.png`) burst across the whole screen, spinning, flying out from the center and falling with gravity. They're big near the camera and fade out in ~1.2 s, as a ScreenGui overlay.
  - **"+5" money badges:** 3–4 green **cash-stack hexagons** (`cash_stack_hex.png`) with the Cash earned ("+5", "+1.2K") in white bold outlined text pop up around the top of the screen, bounce and fly to the Cash counter.
- **Every hit, like the owner's second reference screenshot (2026-10-14):**
  - **Chips fly off on every hit**, not only when it breaks: 4–6 small flat pieces in the bed's own colors (sampled from its parts: frame, blanket, mattress) burst out from the hit point. They tumble, fall, bounce once and fade after ~1.5 s, client side. They pile up a little around the bed while you chop.
  - **Hit marker:** a white ring with short radial lines (`Models/juice/hit_marker.png`) flashes at the exact hit point on the bed on every punch. It pops from 60% to 110% size in 0.1 s and fades in 0.15 s.
  - **Damage number** on each hit: big white bold text with a thick black outline, tilted ~25°, popping out near the hit and drifting up. The same style is used for CRITICAL in orange.
  - **Health bar** under the bed: wide, **pink fill on a dark red track**, white bold "418K / 612K" text with a dark outline, and a red **plus icon** (`health_plus.png`) on its left. The fill eases down on each hit, with a white "damage chunk" that shrinks after 0.2 s.
  - The bed jolts and squashes slightly on every hit (already in the game, keep it).
- **The money must never cover the buttons and HUD (owner, 2026-10-14 screenshot):** the cash bills and "+9.9K" badges covered the side buttons, the stats, the health bar and EXIT, and there were far too many.
  - Put the money effects in their own ScreenGui with a **lower DisplayOrder than every HUD ScreenGui** (e.g. money -10, HUD 0 and up), so all buttons, stats, the health bar and EXIT are always drawn **on top** of the money.
  - Keep the bills inside the **middle area** of the screen: not over the left buttons/stats column, the right button column, the top buttons or the bottom health bar/EXIT. Start them from the center and fade them out before they reach those areas.
  - **Fewer and smaller:** at most **10 bills** per break (smaller, ~8% of screen height), gone within 1 s. Only **one "+cash" badge per break** (the total, e.g. "+9.9K"), not one per bill. If breaks come fast (auto), merge them into the same badge and count it up, and never more than 2 badges on screen.
  - Low Graphics: 4 bills.
- **CRITICAL hits:** "**CRITICAL!**" in an orange-to-red gradient with a thick dark outline pops at the hit spot. The damage number ("326K") is big white text with a black outline, **tilted ~15°**, punching in with a scale bounce.

## Break any bed, slower when you're weak (owner, 2026-10-14)
The owner wants players to be able to break beds far ahead on the path, but very slowly when their Strength is low.
- **No Strength lock anymore:** the Break prompt works on every bed. "Need 💪 X" is gone from the prompt. The bed sign still shows the recommended Strength.
- **Damage per chop is the same as now (from Strength).** A bed far ahead just has far more health compared with your hits, so it takes much longer. Roughly: time ≈ 4 s × (bed's Strength need ÷ your Strength). For example, 10x too weak is about 40 s, 100x too weak about 7 min, and 1,000x too weak about an hour.
- **The health panel shows an estimate** under the bar: "⏱ ~7m 20s" (live, from your current damage per second, auto or clicking). Green under 1 min, yellow under 10 min, red above. "Too long" isn't shown; just the time.
- **Progress resets** if you EXIT or walk away for more than 10 s (the health refills), so you can't chip at it a bit each day. AFK breaking with Auto/AFK rejoin is fine, though.
- **BREAK IT (Robux):** if the estimate is over 60 s, a gold "⚡ BREAK IT" button with the live price (gap tiers in [[Break A Bed/Shop Plan|Shop Plan]]) shows next to the health bar. It replaces the old "you can't break this" moment.
- Undiscovered (black) beds can be broken too. The "NEW BED DISCOVERED!" reveal plays when it breaks.
- Balance check: cash per minute from a bed far ahead stays a little below the best bed you can break normally (cash grows ~3x per bed, health ~3.3x), so breaking far ahead is a fun "big goal", not a shortcut.

## Unique zone for every bed (owner, 2026-10-14)
Each bed's tile area gets decorated in that bed's theme. Keep it **compact**: only on that bed's tile and the fence posts beside it, nothing on the walkway, and nothing taller than the bed sign. Each zone has: a themed **floor** (texture/material on the tile), **2–4 small props** at the tile edges, and **one ambient effect** (particles or light). Undiscovered beds: the zone is dark/greyed until the bed is first broken, then it "comes alive" (colors fade in).

| # | Bed | Floor | Props | Ambient |
|---|---|---|---|---|
| 1 | Cardboard | brown cardboard texture | stacked cardboard boxes, tape roll | – |
| 2 | Air Mattress | pool tiles, light blue | inflatable ring, beach ball, air pump | soft bubbles |
| 3 | Sleeping Bag | forest grass + dirt | small tent, campfire (custom flame flipbook), log seat | campfire embers |
| 4 | Wooden | wooden planks | log pile, axe in a stump | sawdust motes |
| 5 | Bunk Bed | kid's room carpet | toy blocks, teddy bear, small ladder | – |
| 6 | Water Bed | shallow water (glass + ripples) | lily pads, rubber duck | water ripple rings |
| 7 | Hospital Bed | white clean tiles | IV stand, heart monitor (beeping green line), curtain | – |
| 8 | Royal Bed | red carpet with gold trim | 2 gold pillars, red rope barriers | gold sparkles |
| 9 | Gold Bed | gold tiles | coin piles, gold bars | coin glints |
| 10 | Diamond Bed | white marble | diamond crystals on stands | white sparkles |
| 11 | Emerald Bed | green marble | emerald crystal clusters, vines | green glints |
| 12 | Ruby Bed | dark red stone | ruby clusters, red velvet cushions | red glow |
| 13 | Ice Bed | snow + ice | ice spikes, snowman | falling snow |
| 14 | Lava Bed | cracked black rock with glowing lava lines | lava rocks, small lava pool | embers + heat glow |
| 15 | Crystal Bed | purple crystal floor | big floating crystals (slow spin) | purple shimmer |
| 16 | Neon Bed | dark floor with neon grid lines | neon signs, glowing tubes | neon flicker |
| 17 | Robot Bed | metal plates with bolts | gears, a small robot, warning stripes | sparks |
| 18 | Alien Bed | green alien goo floor | alien plants, a small UFO hovering | green beam |
| 19 | Lunar Bed | grey moon dust with craters | flag, moon rocks | low floating dust |
| 20 | Solar Bed | orange-hot floor | small sun orb, solar flares | heat shimmer, orange glow |
| 21 | Galaxy Bed | starry space floor (galaxy texture) | tiny planets orbiting | stars |
| 22 | Nebula Bed | pink-blue cloudy floor | nebula clouds (soft parts) | drifting cloud particles |
| 23 | Black Hole Bed | pitch black with a swirl | a small black hole vortex (rune/swirl sprites) | particles being sucked in |
| 24 | Cosmic Bed | deep purple with constellations | comets, star shards | twinkling lines |
| 25 | Infinity Bed | rainbow shifting floor with an ∞ symbol | floating ∞ rings | rainbow sparkles |

- Reuse the sprites in `Models/vfx/sprites` for the effects. Never use Roblox's default Fire/Smoke/Sparkles.
- Low Graphics turns off the ambient effects and keeps the floor and props.
- Belt-test beds (3, 6, 9, ...) have no gate (the owner removed the dojo gates). They keep the floating belt and the "BELT TEST" tag.

## Hidden zones in the clouds (owner, 2026-10-14, corrected)
**Built 2026-10-15** (client `CloudZones`, saved `FurthestZone`), see [[Break A Bed/2026-10-15|2026-10-15]].
To make the game more exciting, players can't see far ahead.
- **Rule:** you can see every zone you meet the Strength for, **plus the next 3 zones** after it (normal, visible, and you can break them slowly). **From the 4th zone onward, a cloud wall covers everything**, and you **can't walk past it**: it's solid like a wall.
  - Example: your Strength meets the Gold Bed (bed 9). You see beds 1–9 plus 10, 11 and 12. The cloud wall starts at bed 13 and blocks the path there.
- **The cloud wall:** a big, fluffy white-grey cloud bank across the whole path (fence to fence and high up), made from our `cloud`/`smoke` sprites (ParticleEmitters with big slow particles + cloud billboards for the shape), never plain grey parts. It drifts slowly. Everything behind it is invisible (client side). A sign in front of it says "🔒 Reach 💪 1.2M to clear the clouds" (the Strength need of the zone 3 before the wall, i.e. clearing the next one moves the wall).
- **The 🔒 sign is part of the clouds, not a billboard (owner, 2026-10-14):** the first build used a big BillboardGui that faced the camera, showed through everything and could be seen from spawn. It was ugly. Instead:
  - Put a **SurfaceGui on a flat invisible part pressed flat against the front of the cloud wall**, facing down the path, about 1/3 of the path width and centered, at chest-to-head height. It's fixed in the world: it doesn't turn to face the camera, and it's hidden behind things like any wall (AlwaysOnTop off).
  - **Look:** like it's written on the cloud. There's no dark pill panel, just a soft white cloud-shaped backing (rounded, slightly see-through) with the lock icon and text in dark blue-grey ("🔒 Reach 💪 1.2M"), plus a light white outline. It gently bobs with the clouds.
  - **Only readable up close:** it fades in from 45 to 30 studs away and is invisible farther away, so from spawn you see only the clouds.
  - Don't put bed name tags (like the "Cardboard Bed" label) in front of it. Labels of zones behind the wall are hidden.
- **Solid:** an invisible wall part with CanCollide on, made on the client only (each player has their own wall at their own spot). Walking into it just stops you, with a soft "poof" of cloud particles where you touch it.
- **Cover the whole map width, not just the path (owner, 2026-10-14):** players could walk around the wall over the grass and get into the hidden area. The cloud wall and its solid part must go **across the entire map**, from one edge of the island (grass, terrain, everything) to the other, and from below the ground up to well above jump height (about 60 studs tall), so there's no way around, over or under it. Check it: walk along the grass on both sides and try jumping on the fence and props near the wall. If the island edge is open, the wall continues to the edge of the map, and a matching invisible solid "side wall" runs along the map edge back to spawn if needed so nobody can drop off and walk around below.
  - The clouds also cover the grass on both sides behind the wall (big cloud billboards and particles spread across the whole width), so the hidden area looks fully covered from any angle.
  - If a player is somehow already behind the wall (an old position, lag), teleport them back to spawn.
- **Fix after the second build (owner screenshot, 2026-10-14):** the clouds now stretch endlessly across the sky as a flat glowing white strip, visible from far away. That's wrong. The map floats in the sky, so the island's own edge is the limit:
  - **Clouds only over the island:** the cloud mass covers just the hidden part of the island (its exact width plus ~6 studs past each edge), sitting on it like a **3D cloud blanket** that fills the hidden zones (lumpy and uneven on top, about 25–40 studs tall, thickest near the wall), not a thin wall and not an endless strip.
  - **No glow:** LightEmission 0 and LightInfluence 1 on the cloud particles/billboards, so they're shaded by the sun like real clouds. Soft white with light grey undersides. They must not shine or look like a neon band.
  - **Solid part:** an invisible wall the island's width plus 10 studs on each side, from below the floor to 60 studs high. That's enough, because walking off the island edge already means falling.
  - **Use real 3D clouds, not flat pictures (owner: "it looks off", 2026-10-14):** the build used flat cloud images (the swirly outlined `cloud` sprite and big flat white billboards). They look pasted on. Replace ALL of them with the **custom 3D cloud meshes** in `Models/clouds/` (`Cloud_1`…`Cloud_4.glb`): puffy cumulus clouds made of round puffs, white on top fading to a soft blue-grey underneath (texture included).
    - Build the cloud bank from many copies of these 4 clouds, randomly rotated (Y only) and scaled 0.8–1.6x, overlapping, so it looks like one big lumpy cloud. Bigger and taller near the wall front, a bit lower toward the island's back edge, and also covering the top.
    - Material **SmoothPlastic**, Transparency 0, CastShadow off, CanCollide/CanQuery/CanTouch off. Colors come from the texture. No outline, no glow.
    - Optional softness: a few slow `smoke` particles (white, LightEmission 0, Transparency ~0.6) only along the bottom edge where the clouds meet the ground, to blend them in. **Don't use the swirly `cloud` sprite here at all.**
    - Gentle motion: each cloud drifts/bobs 0.5 stud slowly (client tween).
  - **Fixes after the 3D-cloud build (owner screenshots, 2026-10-14):**
    - **The player could walk INTO the clouds, and the 🔒 sign was inside them** (you could only read it from inside). Fix: the **solid wall stands exactly at the front face of the cloud bank** (the closest puff to the player), so nobody can enter the clouds. The sign sits **in front of the clouds**, about 1–2 studs before that front face, centered over the path, facing the player and readable while walking up (fades in from 45 to 30 studs). It's never hidden inside a puff.
    - **The clouds float with a visible gap underneath.** Fix: every cloud's bottom must touch the ground, sunk about 1–2 studs into the floor/grass. Add a bottom row of wide, flattened clouds (scale Y ~0.5) along the ground across the whole width to fill any gaps. Check at ground level from the front and both sides that no sky shows under the clouds.
  - **The clouds overlapped the last visible bed (owner screenshot, 2026-10-14).** The cloud bank must start **after** the last visible zone, never on it: keep a clear gap of at least **6 studs** between the back of the last visible bed (its tile edge) and the closest point of any cloud. Puffs must not bulge forward over the visible tile. Test with the bed's whole frame and headboard visible from the front and the sides.
  - **New smoother cloud meshes (v2, 2026-10-14):** `Models/clouds/` now has smooth merged clouds (no faceted ball look): `Cloud_1`…`Cloud_4` plus **`Cloud_GroundRow`**, a long flat cloud for the bottom row along the ground (no gap underneath). Re-import them and replace the old ones.
  - **The clouds must never block the 🔒 sign (owner, 2026-10-14 screenshot: only half the text showed through the puffs).** Keep the sign flat and fixed in the world (a SurfaceGui on a flat part in front of the clouds, facing the path, not camera-facing), but set **`AlwaysOnTop = true`** on that SurfaceGui so cloud puffs can never cover it. Because AlwaysOnTop would show it from far away, keep the **distance fade** (fully visible within 30 studs, fades out by 45, hidden beyond) and only show it when the player is on the near side of the wall. Size it so the whole line "🔒 Reach 💪 58K" fits on one row and reads clearly.
  - **STILL BROKEN (owner screenshots, 2026-10-14, third time): clouds touch the last visible bed, the player can walk into the clouds, and up close the sign vanishes.** Hard rules, with checks:
    1. **One boundary plane.** Compute `boundary` = the far edge of the last visible zone's floor tile + **8 studs**. Every cloud's bounding box (`Model:GetBoundingBox()`, including its size) must be **entirely behind** `boundary`. If a cloud's front pokes past it, push the cloud back. No exceptions for "small bulges".
    2. **The solid wall sits exactly ON `boundary`** (a thin invisible part, CanCollide on, across the whole island width, 60 studs tall). So the player stops at least 8 studs from the bed and can never touch or enter a cloud.
    3. **The camera can't go into the clouds:** set the cloud parts to `CanQuery = true` (still CanCollide false) so Roblox's camera stops at the cloud surface instead of clipping inside. Also, if the camera's position is behind `boundary`, move it back in front.
    4. **The sign** sits 1 stud in front of `boundary`, AlwaysOnTop, and stays **fully visible at every distance under 30 studs** (it fades only between 30 and 45). Up close it must not disappear.
    5. **Self-check before saying it's done:** run a script that, for each possible wall position (every zone), asserts that (a) no cloud part's box overlaps the last visible bed's tile (`workspace:GetPartBoundsInBox`), (b) the wall is at the boundary, and (c) a test character walking straight at the wall stops in front of the clouds. Print PASS/FAIL per zone. Then take screenshots from the front, the left, the right and very close to the sign.
  - **VFX on the clouds (owner: "it's just white balls", 2026-10-14):** the clouds themselves stay solid white (no glow), but they get a layer of soft magic around them:
    1. **Mist wisps:** slow, see-through `smoke` particles (white, Transparency ~0.7, LightEmission 0) drifting sideways across the cloud surface and spilling over the front edge like dry ice. Big (8–15 studs), long life (6–8 s).
    2. **Twinkles:** tiny `spark`/`star` particles that blink on and off all over the cloud surface (white with a hint of gold, LightEmission 1, size 0.4–0.8, rate low). Magical, not busy.
    3. **Mystery glow inside:** 2–3 big soft `glow` sprites hidden just inside the front clouds, in the **theme color of the next hidden zone** (red for Lava, icy blue for Ice, purple for Crystal...). They pulse slowly (4 s), as if something is waiting inside.
    4. **Inner flashes:** every 8–15 s, a soft flash deep in the clouds (a PointLight flickering 2–3 times in the zone color) with a very quiet distant rumble. On later zones (16+), it's light purple lightning `lightning` sprites inside.
    5. **Light rays from above:** 1–2 soft `rays` billboards high above the cloud top, very faint (Transparency ~0.85), slowly turning, like sunbeams on the clouds.
    6. **Touching the wall:** a puff of cloud particles plus a soft whoosh where the player walks into it.
    - Low Graphics: keep only the mist (fewer) and the mystery glow.
  - **Remove the floating grey blocks** visible in the sky above the map (debris/props left floating), unless they're meant to be there.
  - **The hidden zones must be truly invisible, from every angle (owner: "I can see the front too"):** clouds alone don't hide them when the camera looks from above, the side or past the wall. So on the client, everything in a hidden zone (bed, cinder blocks, tile, props, signs, name tags, lights, particles, sounds) is **removed locally**: moved into a client-side folder outside Workspace, and brought back when revealed. Not just made see-through.
  - The cloud blanket also covers the **top** of the hidden area, so looking down from above you see only clouds.
  - **Camera:** limit zoom-out (CameraMaxZoomDistance ~45) so the camera can't fly high over the wall, and don't let the camera pass through the cloud wall (if it would, pull it back to the near side).
  - Check from far away (zoomed out and from the plaza): it should look like a fluffy cloud bank sitting on the back of the island, with nothing across the sky.
- **Moving the wall:** when your Strength reaches the next zone's need, the wall **moves forward by one zone**: the front clouds blow apart (~1.5 s, wind whoosh), that zone fades in, and "NEW ZONE REVEALED!" shows with the bed's name (black silhouette until first broken).
- **The reveal waits until you walk up to it (owner, 2026-10-14).** Reaching the Strength (for example while training) does NOT reveal the zone right away. It only makes it **ready**:
  - When a zone becomes ready, a small toast says "☁️ The clouds are thinning... go see!", and the 🔒 sign on the wall changes to "✨ Walk closer!" with a soft pulsing glow. The next-bed bar shows "New zone ready!".
  - The clouds only blow apart (the reveal moment with "NEW ZONE REVEALED!") when the player **walks within ~20 studs of the wall** while the zone is ready.
  - If several zones became ready at once (big Strength jump), they reveal **one by one** as the player walks forward: each time you approach the new wall position, the next zone opens.
  - While the zone is ready but not revealed yet, the wall stays solid.
  - **Bug fix (owner, 2026-10-15): walking fast through several ready zones left the player stuck** (the clouds had moved far ahead, but the invisible wall and the "✨ Walk closer!" sign stayed in the old spot). New rules:
    - **No cooldown and no waiting.** When a ready zone opens, the **solid wall and the sign move instantly** to the next spot (same frame). The cloud blow-apart and "NEW ZONE REVEALED!" are only visuals that play on top and never block movement.
    - **Chain reveal:** if the player keeps walking and the next zone is also ready, it opens as soon as they reach the new wall, right away, even while the previous animation is still playing. Combine the toasts so only one "NEW ZONE REVEALED!" shows at a time (or "3 NEW ZONES!").
    - **Always recompute from the truth:** the wall position = based on the player's Strength / FurthestZone and which zones were revealed, computed in one function. Every time anything changes (Strength, a reveal, respawn, teleport, To Bed), call it and place the wall, sign and clouds from scratch. Never move them step by step from the old state.
    - **Safety net:** if the player is ever standing behind the wall's current position (desync), don't push them back. Recompute; if the zones they're in are ready, reveal them instantly.
    - Test: train far past 3–4 zones, then sprint (and use To Bed) straight through. Every wall should open with no stopping, and the player should never get stuck.

- To Bed, the guide beam and the next-bed bar never point past the wall.
- **Rebirth (decided 2026-10-14): the wall does NOT come back.** Revealed zones stay revealed forever, saved as `FurthestZone` (like DiscoveredBeds, not reset by Rebirth). The wall stays at the furthest spot you ever reached and only moves further when your Strength goes past your old best. After a rebirth the world doesn't shrink: you see where you've been, beds you broke before have the ⚡ 5x-faster mark, and the clouds ahead are the next real mystery. This keeps rebirth feeling like progress, not losing the map.
- Low Graphics: fewer particles; it uses mostly billboards.
