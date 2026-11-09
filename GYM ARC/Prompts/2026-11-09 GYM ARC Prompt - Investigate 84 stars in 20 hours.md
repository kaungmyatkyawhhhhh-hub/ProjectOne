---
date: 2026-11-09
tags: [gymarc, prompt, claude-code, hall-of-fame, exploit]
---
# GYM ARC: investigate a player with ★84 Hall of Fame in 19h 34m playtime (owner, 9 Nov)

Owner (profile screenshot): "theGoated one", OLYMPIAN, ★84 HALL OF FAME, 3.2B Muscle EXP, best lift 1413 lb Crystal Deadlift, 3 posing wins, playtime 19h 34m, trainers Solaris + Heracles (BASE LV 20) + The Bronze Titan (IRON-BORN LV 1). "how this guy got 84 stars in 20 hours".

## Why it's impossible by design
From [[2026-11-03 GYM ARC Pace by star - realistic trainers]] and [[GYM ARC - Hall of Fame]]:
- Max 2 stars per entry (Alter 20 = 2 stars), so 84 stars = **at least 42 full runs**.
- 19.5 h / 42 runs = **~28 min per run**. The fastest real run on the sim is ~42 min (★10, 2 Heracles, skip to 20), and ★0-★3 runs take 2-9 hours. The owner's own maxed account (+800% trainer cap) needed ~27 min, and runs under 30 min are refused by the Fastest Run timer.
- Legit 84 stars would take well over 100 hours.

## Likely causes (most likely first)
1. **Double-enter race:** the Enter Hall of Fame remote fired many times at once, and the server awarded a star on each call before the reset was saved (CanEnter checked before the data changed).
2. **Test / admin leak:** a Studio test switch (`TestStars`, `TestHallOfFame`, test stats) or the Admin `stars` command reachable on live servers.
3. **Playtime undercounted:** if playtime only started counting when Profiles shipped (~28 Oct), older hours are missing. That shrinks the gap but can't explain 42 runs.

```text
GYM ARC – INVESTIGATE A HALL OF FAME STAR EXPLOIT. GYM ARC is in maintenance mode: fix only this, add no features. Do NOT publish (the owner publishes). Do NOT change any player's data yet: report first.

A live player "theGoated one" has ★84 HALL OF FAME with 19h 34m playtime. Max 2 stars per entry means 42+ runs at ~28 min each, which the design doesn't allow (fastest real run ~42 min; Fastest Run refuses < 30 min).

1. READ-ONLY INVESTIGATION:
   - Read this player's save (DataStore, by UserId): fame.stars, fame.firstAt, fame.lastEnteredAt, fame.lastRun / bestRun / weekBest, playtime, alter history if logged. Is the player in HallOfFame.Plausible's suspicious list (console: `fame suspicious`)?
   - How fast were stars gained (firstAt -> lastEnteredAt, stars per day)? Any jumps of more than 2 stars in one entry?
   - Code review of the enter path (HallOfFameService, PlayerData:EnterHallOfFame, the RemoteEvent/Function): can several calls in a row (or at the same moment) each award stars before the reset is applied? Is there a per-player lock/debounce?
   - Search the LIVE place for test switches and admin paths: Workspace TestStars / TestHallOfFame / TestCutscene, test stats, the Admin "stars" command. Can any of them be reached by a normal player on a live server?
   - When did playtime start being counted?
   - Check the top 10 of the Hall of Fame board for the same pattern (stars vs playtime).

2. IF A HOLE IS FOUND, FIX IT (code only):
   - one server-side lock per player around EnterHallOfFame: check CanEnter, apply the reset AND add stars in one step, save, then release; extra calls during that are dropped and logged;
   - test switches and admin commands only work in Studio (RunService:IsStudio()) or for the owner's UserId;
   - the plausibility check also flags stars that grow faster than 2 per 30 min of playtime.

3. REPORT (short): what the save shows, the cause, the fix, other players with the same pattern, and a recommendation on what to do with the exploited stars (the owner decides; don't touch saves).
```
