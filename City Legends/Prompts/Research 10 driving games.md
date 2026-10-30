# Prompt: research the top driving games, remember it, and improve City Legends

_For Claude Code on the PC. Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`)._

## Before you start
- Read:
  - `CLAUDE.md`;
  - `Roblox Playbook/Roblox Playbook - Rules for every game.md` (and search the Playbook guides when you need detail);
  - `Games/CityLegends/CLAUDE.md`;
  - `City Legends/City Legends.md`.
- **Never type, ask for, or handle the owner's Roblox password, cookies or 2-step codes.** If a game needs a login, stop and ask the owner to log in themselves.
- **Never buy anything** with Robux or real money. Don't chat with other players. Don't join groups or accept friend requests.

## The owner's favourite: Midnight Racing: Tokyo (2026-10-30)
The owner respects **Midnight Racing: Tokyo** the most of all driving games. So:
- Study it **first and deepest**: wiki pages (https://robloxmidnightracing.fandom.com), at least 5 videos, update logs, and what players love about it.
- Cover:
  - driving physics and camera;
  - car sounds;
  - the dealership and trims;
  - tuning and customisation;
  - the highway / Tokyo maps;
  - traffic;
  - police;
  - races and meets;
  - levels;
  - the UI;
  - night lighting.
- In the research note, give it its own long section and a **"What makes Midnight Racing great"** list.
- **When lessons from different games disagree, Midnight Racing's way wins**, unless it breaks our rules or the Playbook.
- Still never copy its names, UI art, logos or assets exactly: make our own version.

### Exception: interiors, clusters and the in-car view come from Driving Empire (owner, 2026-10-30)
- Midnight Racing doesn't have a proper interior view for most cars. **The best interiors and gauge clusters are in Driving Empire**, so for these, **Driving Empire's way wins**:
  - the in-car / first-person camera;
  - detailed cabins;
  - live clusters (needles, screens, lights);
  - the steering wheel.
  - Study it closely: videos in the driver's seat, how the camera sits, the FOV, how the cluster reads at night, mirrors.
- **But not the hands:** the owner finds Driving Empire's driver hands **too big**. Ours stay **real-size**:
  - real proportions against the wheel (a normal adult hand, about the width of the steering wheel's rim grip);
  - sitting at 9 and 3 o'clock;
  - turning with the wheel;
  - never covering the cluster.
  - Check them in a first-person screenshot next to a real car photo.

## The games (play or study these 10)
1. **Highway Legends** (our target look)
2. **Driving Empire**
3. **Midnight Racing: Tokyo** (the owner's favourite: study first, see above)
4. **Car Dealership Tycoon**
5. **Greenville**
6. **Southwest Florida**
7. **Vehicle Legends**
8. **Driving Simulator**
9. **Jailbreak** (driving, police and robbery side)
10. **Car Crushers 2**

Also look at the big console games for feel and camera only (videos are enough): **Forza Horizon 5**, **Need for Speed Heat / Unbound**, **GTA V** (driving, police, houses).

## How to study each game (in this order, best first)
1. **Read:** the game's wiki (fandom), its Roblox page (description, update notes, passes and prices, player count), and a few reviews / Reddit threads ("what makes X fun", "X is boring because").
2. **Watch:** 2–3 YouTube videos per game: a beginner's first 10 minutes, an "every feature" tour, and an update showcase. If the `watch` skill is installed, use it. Otherwise read the transcripts and take screenshots.
3. **Play (only if computer use is available and the owner says OK):**
   - **Computer use** is the ability to see the screen and move the mouse / keyboard. It works through the Claude desktop app, if the owner turns it on in its settings. If you don't have it, skip playing and say so. Don't fake it.
   - The owner opens Roblox and logs in themselves first.
   - Play each game for **at most 15 minutes**:
     - the first 3 minutes as a new player (what you see, how fast you get a car, what the tutorial says);
     - then drive, open every menu (dealer, garage, customise, houses, shop), and try one money activity.
   - Take screenshots of every important screen.
   - **Roblox may see automated play as a bot and could warn or ban the account.** Tell the owner this before starting, and only play if they say yes. Keep the sessions short, and never farm money or AFK.
   - Leave each game normally.

## What to write down for every game
Make one section per game with:
- **First 3 minutes:**
  - the loading screen;
  - the tutorial;
  - the first car;
  - the first money;
  - the first goal.
  - How long until you drive?
- **Driving feel:**
  - camera (views, FOV, shake);
  - physics (grip, drift, weight);
  - speed feel;
  - sounds;
  - phone controls.
- **Cars:**
  - how many;
  - prices;
  - trims and levels;
  - dealer UI;
  - customisation (paint, wraps, rims, body kits, tuning);
  - garage limits.
- **Money and progress:**
  - ways to earn and how much per hour;
  - levels / XP;
  - daily rewards;
  - quests;
  - the first big goal and the long goal.
- **World:**
  - map size and areas;
  - traffic;
  - police;
  - day / night;
  - weather;
  - houses;
  - activities (races, jobs, heists, events).
- **Social:**
  - crews;
  - races with others;
  - trading;
  - roommates;
  - showing off.
- **Shop and passes:** what they sell, prices in Robux, and what feels fair or greedy.
- **UI style:**
  - colours and fonts;
  - how menus look on a phone;
  - the HUD.
  - Screenshots go in `Games/CityLegends/imports/refs/games/<game>/`, small (720p or less).
- **Best 3 things** we should learn from it, and **worst 3 things** we should avoid.
- **Numbers:** players online, likes %, visits, from the Roblox page, with the date.

## Never forget it
- Save everything in **`City Legends/Research - Driving games.md`**, with screenshots linked from `imports/refs/games/`.
- Add a short **"What the top driving games do"** summary at the top: the 15 most important lessons, ranked.
- Add this line to `Games/CityLegends/CLAUDE.md` under the notes, so every future session reads it:
  > Before planning any City Legends feature, read `City Legends/Research - Driving games.md` (the lessons from the top driving games).
- Also add a one-line link to it in `City Legends/City Legends.md`.
- Commit and push after each game, so nothing is lost if the session stops.

## Then improve City Legends
1. Compare: make a table of **what top games have vs. what City Legends has** (have / missing / ours is worse / ours is better).
2. Make a **ranked improvement list** (biggest win for players first). Use the Playbook rules: first 3 minutes, day-2 / day-7 reasons to return, phone performance.
3. **Show the owner the top 10 before building.** Ask first about big changes: prices, removing features, the money balance, paid items.
4. Then build the approved ones **one at a time**. Each one:
   - play-test in Studio (2 players);
   - phone-size screenshot;
   - Lune tests and `luau-lsp analyze`;
   - commit and push;
   - save the place.
5. Respect the earlier rules:
   - fictional names, no logos;
   - no alcohol, no clubs (DJ / party only in penthouses);
   - the casino is scenery only;
   - don't copy any game's UI, names or assets exactly: make our own versions.

## When done, tell the owner (short)
- the 3 best ideas from each game;
- the top 10 improvements and which are done;
- where the notes are;
- anything you couldn't do (for example, playing, if computer use wasn't available).
