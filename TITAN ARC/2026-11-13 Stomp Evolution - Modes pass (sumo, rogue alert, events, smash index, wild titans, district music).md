# Stomp Evolution - Modes pass (13 Nov 2026, 10:05-10:55)

This pass builds the five items the three kid sims v2 called for (see [[2026-11-13 Stomp Evolution - Three kid simulations v2 (live build)]]).
- Place saved as v120.
- Backups are in ServerStorage, all named `*_preModes_13Nov`.

## 1. Sumo Ring + Rogue Alert (the "no real fighting" objection)
### Sumo Ring
- **How you join:** the SUMO button on screen. You are matched with someone in your size bracket (forms 1-2, 3-4, 5-6, 7-8). If nobody joins within 12 s, you get a SUMO BOT of your size instead.
- **The arena:** a Blender model built from a ChatGPT turnaround sheet, following the roblox-3d-model-from-sheet skill.
  - About 11K tris; asset 73098494052351; kept in ServerStorage as SumoArena.
  - Files are in Art/Sumo: sheet, sumo.py, renders, FBX.
  - It floats high above the town and is scaled per match: ring radius = 12 x the fighter's scale.
- **Fighting:** a stomp near the other titan shoves them; every 4th shove is a SLAM (x1.6). Push them over the rope or off the stage to win. A round lasts 45 s; if time runs out, whoever is nearer the middle wins.
- **Rewards:** a win pays coins (40% less against the bot) and adds 1 to the "Sumo" count in the leaderboard. It never gives power.
- **Code:** SE_Sumo (server) and SE_Modes (client).

### ROGUE ALERT (design doc "Rampage", renamed)
- **When:** every 8 min (the first about 3.5 min after the server starts), lasting 90 s.
- **The titan:**
  - About 2x the size of the biggest player, wearing the armour one form above theirs.
  - It has a red outline and glowing feet.
  - It drops in from the sky and hunts the crown holder (or a random player). Its own stomps knock players back; nobody loses anything.
- **Fighting it:** players hit it by stomping near its feet.
- **Pay:** based on each player's share of the damage, with a floor. If it escapes, players get 25%. During the alert, its own music track plays.
- **Code:** SE_Rogue.
- **Studio test:** set the workspace attribute SE_RogueNow = true.

## 2. City events (every ~90 s)
- Each event gives a 5 s warning, then runs for 20 s, shown in a banner with a draining bar under the NEXT bar.
- The three events:
  - MASS FRENZY: x2 Mass.
  - COIN RAIN: x3 coins, with coins falling around you.
  - GOLD RUSH: golden props appear all over town.
- Each event changes the lighting slightly, always brighter, never darker.
- Events never run during a Rogue Alert.
- **Code:** SE_Events, plus `shared.SE_Event` multipliers in StompServer.

## 3. Smash index + golden props at 1 in 80
- **NEW!:** the first smash of each kind gives a toast and 5x that prop's coins.
- **Stars:** each kind has 3 stars, at 10/100/1000 smashes (landmarks: 1/10/50). Each star gives coins and +1% Mass forever.
- **INDEX window:** opened from the INDEX button. It shows 23 kinds with ChatGPT icons, counts, stars and the next goal. Kinds you haven't smashed show as a silhouette with "???".
- **Golden props:** a keeper keeps about 1 in 80 of the props each player can smash nearby golden. An unclaimed golden prop turns back after 90 s. The old random spawns were removed.
- **Index icons:** 2 sheets plus a tower icon, keyed and cut in the browser and uploaded to group 33151111. Asset ids are in `Config.IndexIcons`.

## 4. Full servers: Wild Titans
- These are NPC giants with real armour sets (Magma in the west, Storm downtown, Crystal on the east bank).
- **How many:** 3 when the server has 1-3 players, 2 at 4-6 players, 1 at 7 or more.
- **Behaviour:**
  - They walk the town and smash props they are big enough for.
  - They turn away from props that are too big and from landmarks.
  - They never smash anything within 70 studs of a player.
  - Their breaks happen locally on each client and rebuild normally.
- Each has an honest "WILD TITAN" tag above it.
- **Code:** SE_Wild and the NPCKit module (ServerStorage).
- **Owner to do (can't be set from a script):** Game Settings > Places > server fill. Fill the fullest servers first and set max players to about 10 (it is 60 now).

## 5. District music
Each district now has its own track, with a 2.5 s crossfade (`Config.DistrictMusic`):

| District | Track |
|---|---|
| Park | Happy Moves |
| Suburbs | Into a Groove |
| Downtown | Scoreline |
| Harbour | Big League |
| Skyline | To The Brink |
| Titan district | Press Start |
| Crown Core | Born to Win |
| Rogue Alert | Heroic Brass And Beats |

These are APM tracks from the Creator Store. The owner can swap any of them by ear.

## Owner feedback fixed during the pass
- **Awaken icon looked like a rewards logo.** It is now a new icon: a violet crystal egg with a golden flame and loop arrows. SUMO got two fists and INDEX got a collection book; all three were made in ChatGPT and replace the duplicated crown/star icons.
- **"Why are my legs in the ground".**
  - Cause: SE_FeetFix measured while the body was stomping, shoved or teleported. The bad reading lowered HipHeight to its 0.5x floor.
  - Fix: it now measures only when calm (1.3 s after the last stomp, no velocity, not in sumo). It retries if the readings disagree, and never goes below the avatar's own hip.
  - Checked: the feet now sit at ground level.
- **Tilted UI should sway.** Every tilted sticker (NEXT UP, HEIGHT, window titles, event banners, big cards) now rocks gently around its tilt via `K.Sway` in UIKit. It is off under Reduced Motion.

## Tested in Play
- Rogue: drop-in, hunt, foot hits, beaten in ~23 s solo, payout, topple.
- Sumo: queue, bot match, out, reward, teleport home; also tested at Storm size.
- Events: Coin Rain and Gold Rush banners.
- Index window.
- Wild titans: walk animation and tags.
- No script errors.

## Open
- The NPCs wear the default dynamic head, with no hair.
- Max players and server fill are game settings the owner has to change.
- Real multiplayer sumo (2 players) is untested here; the checklist is the same as the multiplayer test.
