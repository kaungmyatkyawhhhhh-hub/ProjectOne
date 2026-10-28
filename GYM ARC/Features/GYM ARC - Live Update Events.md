---
date: 2026-10-28
tags: [gymarc, liveops, feature]
---
# GYM ARC - Live Update Events

Back to [[00 GYM ARC Home|GYM ARC Home]] · Built in [[2026-10-28 GYM ARC Update countdown and live launch event]] (prompt 90)

A reusable system for every big update: publish EARLY with the new content hidden, a countdown runs by itself, and at a UTC time every server launches at the same second (live cutscene, unlock, reward). Nothing is republished or restarted at launch time.

## Where things are
- **Config:** `ReplicatedStorage.Shared.Config.LiveEvents`: one entry per update (name, time UTC, countdown hours, gather minutes, cutscene, unlocks, GO TO target, window lines, launch reward, popup days).
- **Cutscene:** `Shared.VFX.LaunchCutscenes` (each update's camera shots and timed effects) played by `Shared.VFX.LaunchCinematic`.
- **Server:** `ServerScriptService.Server.LiveEventService`. **Client:** `StarterPlayerScripts.LiveEventClient`.
- **Covered building:** `Workspace.Town.HallOfFame.LaunchCover` (3 curtains + the countdown banner). After launch it moves to `ReplicatedStorage.LaunchCovers` (the WATCH replay drops a copy of it).

## What players see
- From 24 h before: a gold countdown card in the right column ("HALL OF FAME · Opens in 3:12:05"); tap = a window with 3 lines + GO TO THE HALL. Not shown during the tutorial.
- The banner on the covered Hall: HALL OF FAME / OPENS IN / clock.
- Last 10 min: the card grows and glows, the window opens once by itself ("gather at the Hall").
- Last 10 s: big 10..1 in the middle with a tick, a drum roll, the music lowers.
- Launch (~24 s, everyone online at once): letterbox, lights dim, the camera flies to the Hall, the curtains drop, warm light inside, 4 shafts of gold light, fireworks, confetti, cheer, "NOW OPEN · HALL OF FAME". Then back to the player and "HALL OF FAME IS OPEN". Players on a machine are taken off first. Players in the tutorial or the main menu skip it.
- Reward (online at launch, once, saved): **Launch Day** title + 30 min of 1.5x EXP and coins (a tile in the boost row; put back on rejoin while it lasts).
- Joined after (7 days): "NEW: HALL OF FAME" once, with WATCH (replay) and GO TO THE HALL.
- The NEWS update log gets the Hall of Fame entry only once it has launched, and the red NEWS dot comes back. Entries in Config/UI.Updates can have `event = "<id>"`.
- Reduced Motion: still shots changed through fades, no punch on the numbers.

## Controls
- Creator Hub > Configs: `Launch_HallOfFame_Time` (string, UTC, `2026-10-31 15:00`) and `Launch_HallOfFame_Enabled` (boolean; false = never launches, Hall stays locked). Config default: Sat 31 Oct 15:00 UTC (9:30 PM Myanmar).
- Admin console (THIS server only): `game.ServerStorage.Admin:Invoke("launch", "status" | "now" | "in", 5 | "cancel" | "reset")`.
- Studio only: Workspace attributes `TestLaunchIn` = seconds (a test launch), `TestLaunchHoldAt` = seconds (freezes the cutscene there, for screenshots), `TestLaunchPopup` = true (shows the NEW popup).

## Analytics
`LaunchEvent_Seen` (each player online at launch), `LaunchEvent_Online_HallOfFame` (value = players online on that server), `LaunchEvent_Replay`.

## A new update next time
1. Add an entry to `Config/LiveEvents` (id, name, time, unlocks, lines, reward).
2. Add its cutscene to `Shared/VFX/LaunchCutscenes` (shots + events).
3. Gate the new feature with `LiveEvents.Unlocked("<feature>")`, add a covered look if it has a building, and an `event =` entry in `Config/UI.Updates`.
