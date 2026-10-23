# Prompt: play-test City Legends, then put the map into the Studio file

_For Claude Code. Read all of this first, then do it in order. Owner: talk short and simple (caveman mode, see `Preferences.md`)._

## Before you start
- The vault is `C:\Users\USER\ProjectOne`. The game is in `Games/CityLegends` (Rojo + Luau). Read `Games/CityLegends/CLAUDE.md` and `City Legends/City Legends.md` first: they explain every system, the tools and the rules.
- Tools: rojo (7.6.1 or newer), luau-lsp, lune. The Lune tests live in `Games/CityLegends/tools/*_test.luau` (`lune run tools/<name>.luau .` from `Games/CityLegends`).
- Build: `rojo build default.project.json -o CityLegends.rbxl`, then `python tools/fix_rbxl.py CityLegends.rbxl`.
- Commit and push to `master` when a part is done. Never save over `CityLegendsCars.rbxl` (the owner's car place).
- If Roblox Studio can be driven from here (computer use, or a Studio MCP), use it: open `CityLegends.rbxl`, press Play and look. If not, play-test by reading the code as a player would hit it and by running the Lune tests; say which you did.

## Part 1: play-test
Go through the game twice: as a brand-new player, then as someone who has played for hours. Cover:
- First join: menu, intro, starter car, first drive, HUD on PC, phone (touch) and gamepad.
- Driving: all three cameras, physics and drifting, crashes, traffic, traffic lights, speed cameras.
- Police: wanted stars, chase timer, busted (10%), escaped bounty.
- Money and cars: garage (CARS), Legends Motors dealership, level and market locks, the car market, Legends Customs.
- Heists: bank, casino vault, gem smash-and-grab, the drop-off.
- Places: towers and penthouses, the hotel with valets and suites, island houses with garages, the chauffeur, on foot and walking.
- Free roam: challenges (drift, speed traps, jumps, leaderboard), races, jobs, chips, mini map, day and night, rain.
- Saving and loading, and the console commands (SetCash, UnlockAllCars, UnlockEverything).

Make one list of every:
- bug or script error (look for nil access, missing WaitForChild, remotes trusting the client);
- exploit (money, speed or teleport cheats through remotes);
- place a player can get stuck (fall through, no car, camera stuck, UI won't close);
- annoyance: overlapping or confusing UI, unclear next step, too slow, too grindy or too expensive, too many pop-ups, things too hard on a phone;
- heavy or laggy part (part counts, loops every frame, memory).

Rank the list from worst to least. Show the owner the top of it (short), then fix everything that's clearly a bug or an annoyance. Ask first only for big design changes (prices, removing features). After fixing, run every Lune test, type check (`luau-lsp analyze`), build, push, and tell the owner what to check in Studio.

## Part 2: put the map into the Studio file ("bake")
Right now the scripts build the whole map when the game starts (`src/server/CityBuilder.lua` and the modules it calls: CityPremium, Mainland, West, Bank, Towers, Hotel, Casino, GemShowcase, Houses, Dealership, Customs, Challenges). The owner wants the map **inside `CityLegends.rbxl`** so they can see and edit it in Studio without pressing Play.

Do it like this (scenery first, the safe part):
1. Build the map once with Lune, the way `tools/world_test.luau` does. It already runs `CityBuilder.build` with real instances. Use its fixed `CFrame.lookAt` (Lune's is wrong for slopes).
   - Keep the tags: call the real `Instance:AddTag` in the CollectionService stand-in. The game uses tags like `LOD`, `LODLight`, `DayOff`, `TrafficLamp` and `Blink`.
2. Save the scenery (roads, sidewalks, buildings, trees, palms, lamps, signals, skyline, mainland, the west, the bridge and the islands) as `assets/Map.rbxm`, and have Rojo put it in `Workspace.City` (`default.project.json`).
3. Change `CityBuilder.build` so that when `Workspace.City` is already there it keeps it (don't destroy it). Only do what can't be baked:
   - lighting (`setupLighting`);
   - terrain water (`Terrain:FillBlock`: Lune can't);
   - clouds;
   - the parts with live behaviour.
4. The interactive venues create their prompts and buttons while they build: Bank, Towers, Hotel, Casino, GemShowcase, Houses, Dealership, Customs, Challenges, the police speed cameras, the chauffeur stands. Keep building those by script at start (simplest, safest), or split each into "build" and "wire up" and bake the build half. Pick the first unless it's easy.
5. Check:
   - every Lune test still passes;
   - a new `bake_test` loads `assets/Map.rbxm` and finds roads under every lane;
   - the built `CityLegends.rbxl` opens in Studio with the map visible in Workspace;
   - the part count is about the same as before (about 150,000);
   - say how big the place file gets.
6. Agree with the owner who owns the map after baking. Suggested: after baking, map changes made in Studio are the owner's, and Claude changes the map only when asked, by editing the baked file (not by rebuilding over it).
7. Write the new way of working into `Games/CityLegends/CLAUDE.md` and the `City Legends` note, then commit and push.

## When done
Tell the owner, short:
- what you found and fixed;
- what's baked;
- how to open it in Studio;
- what is still untested.
