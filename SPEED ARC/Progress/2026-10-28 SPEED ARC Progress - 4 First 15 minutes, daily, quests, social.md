---
date: 2026-10-28
tags: [speedarc, progress]
prompt: "[[2026-10-28 SPEED ARC Prompt - 4 First 15 minutes, daily, quests, social]]"
---
# Progress 4 - First 15 minutes, daily, quests, social (M4)

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

Done overnight without questions (owner asleep).

## Built
- **Loading screen + PLAY** (GDD 0:00): SPEED ARC logo, preload bar (max 10 s), one big PLAY button.
- **Tutorial** ([[SPEED ARC - First 15 Minutes]]): Coach Benji card at the bottom, a gold dotted path on the floor + a GO HERE marker, GO TO buttons that teleport. NEW RUNNER BOOST 2x for 15 min of play (gold badge on the MPH plate). FIRST STEP! = +100 coins +10 MPH. Combo hint. Tutorial race vs 3 slow NPCs with one big TAP BOOST! prompt and a close win. GOLD MEDAL card. GO TO Shoe Shop (coins topped up, Canvas Runners glow in the Locker). Train to Silver. Free coach roll at Silver, GO TO Coach Corner. After the tutorial: a GO TRAIN button.
- **Tutorial rules:** the hint never vanishes while its step is open, comes back every 12 s, hides while a window or race covers it. No other popups while it shows, the area race toast is muted early on. Every step has a safety timeout that only counts while the step is possible: first the game does the GO TO for you, then the step moves on. The race is never skipped, it starts by itself.
- **Daily streak** ([[SPEED ARC - Daily, Quests and Gifts]]): 7 days, one missed day allowed, day 4 = coach roll, day 7 = the new Sunrise trail (first time). Shows what tomorrow gives. Opens by itself once a session (never during the tutorial).
- **Daily quests:** 3 a day from a pool of 9, each pays 3 min of coins, all 3 = 10 min + a coach roll. Finished but unclaimed quests are paid at the reset.
- **Playtime gifts:** 3 / 8 / 15 / 25 / 40 / 60 min of play today. Pay by themselves; the popup names the next one.
- **Popups:** one queue, one at a time, only when you're off a station, not racing, no window open, no tutorial hint.
- **Codes** ([[SPEED ARC - Codes]]): CODES button (left menu) opens Settings with the code field (+ Music and Sounds ON/OFF). SPEEDARC, FIRSTRACE, RELEASE. More can be added live in the DataStore (console commands in the feature note).
- **Leaderboards** ([[SPEED ARC - Leaderboards]]): Leaderboard Wall in the hub (4 boards), each league area's board, and a TOP panel: Top SPEED, Most Wins, Fastest Sprint per area, This Week (wins + fastest Hometown Sprint). Weekly reset Monday 00:00 UTC, top 3 get a title + coins (delivered next time they play). Versioned store names.
- **Titles, medals, profile** ([[SPEED ARC - Social and Profiles]]): titles from the GDD list (FIRST RACE, FIRST WIN, 10/100/1000 WINS, PARK RUNNER, HOMETOWN/PARK/STADIUM CHAMPION, PB HUNTER, weekly titles). Over the head: title + rank + medal count. Tap a runner = VIEW PROFILE / RACE THEM / ADD FRIEND. Tap your own rank badge = your profile (with CHANGE TITLE).
- **RACE THEM:** a private 1v1 sprint on the outside lanes. Coins only for the first 3 a day, no medals or league wins.
- **Social:** Friend Boost +10% per friend (max +30%) with a toast. INVITE button (Roblox invite screen), +10% for 30 min when a friend joins from your invite. Favourite prompt once, after your first Go Pro. Notifications opt-in after the first daily claim.
- **Analytics** ([[SPEED ARC - Analytics]]): the 12 funnel steps from GDD 26, each once per player, always in order. Plus RaceJoined / RaceSkipped events.

## Tested (fresh test save, Studio)
Timed run (my clicks through the tools add a few seconds per step):

| Step | Time |
|---|---|
| PLAY -> Benji card + 2x boost | 0:00 |
| GO TO Sprint Lane shown | 0:04 |
| First tap (FIRST STEP! +100) | 0:57 (tool delay; the button is there from 0:04) |
| Combo hint done | 1:02 |
| Tutorial race won (gold medal, +675 coins) | 2:00 |
| First shoes bought | 2:16 |
| Silver + free roll | admin switch here; the bot sim says 5:00 |
| First coach roll | 2:32 after the Silver switch |
| Go Pro 1 | bot sim: about 13-15 min |

Also tested:
- GO HERE marker + gold path, TAP BOOST! goes away on the first boost, Canvas Runners glow in the Locker.
- Daily: claimed day 1, fake clock +1 day = day 2, +3 more days = streak restarted (one missed day is OK, two isn't).
- Codes: SPEEDARC works once, then "already used", a wrong code says so.
- Gift 1 popup at 3 min ("GIFT 1 OF 6: +60 coins. Next gift at 8 min").
- Leaderboard panel reads the global board. Weekly reset in Studio (`TestWeekOffset`): the old week was paid once.
- Profile window, quests window, titles over the head (FIRST WIN, 1 MEDAL).
- No script errors in the output.

**Not tested:** a real 2-player test (Friend Boost, profile of another player, RACE THEM). The Studio tools here only run one player. Please try it with a friend or Studio's 2-player test (Test tab > Clients: 2).
**Phone size:** screenshots are desktop size (the Device Simulator isn't on). Prompt 6 does the phone pass.

## Pacing re-tuned (bot sim with the 2x boost, gifts, daily, quests)
| League | Target | After prompt 3 numbers | After re-tune |
|---|---|---|---|
| 1 | ~15 min | 9.8 min | 14.7 min |
| 2 | ~35 min | 28.2 min | 34.4 min |
| 3 | ~60 min | 59.0 min | 61.1 min |

League 1 milestones from the sim: first shoes 2.2 min (GDD 2:30), Silver 5.0 min (GDD 5:00), Gold 8.0, Champion 13.7.
New numbers: ranks L1 3.8K / 20K / 36K / 70K, L2 4M / 16M / 40M / 80M, L3 1.8B / 7.5B / 18B / 36B. Stations: Treadmill 1.4K, Stair Run 5K; Hill Sprint 1.25M, Bench 4M, Bike 12M; Hurdles 550M, Parachute 1.8B, Bungee 5.5B.

## Changes / calls I made
- The tutorial race win counts as a gold medal and a win, but **not** for Go Pro (Go Pro still needs "Champion + win a race").
- Old saves that already played skip the tutorial (save version 4).
- Layout: DAILY / QUESTS / TOP under the race timer (JOIN moved under them, GO PRO below that). CODES / INVITE under the left menu. Rank-up and gift popups sit below the toast lane.
- The GO HERE marker is not "always on top" (in Studio's capture it didn't draw that way).
- Day 7 trail = new **Sunrise** trail (gold/orange), only from the streak.
- New Studio test switches: `TestAutoPlay`, `TestTutStep`, `TestAddSpeed`, `TestDayOffset`, `TestWeekOffset`, `TestOpenWindow` = "Daily" / "Quests" / "Settings" / "Top" / "Profile".

## For you: Creator Hub setup
1. **Funnel:** nothing to set up. Creator Hub > Analytics > Funnels shows the onboarding funnel by itself. Step names: 01 loaded, 02 menu_play, 03 first_tap, 04 first_race_joined, 05 first_race_finished, 06 first_shoes, 07 first_coach_roll, 08 silver, 09 gold, 10 go_pro_1, 11 day2_return, 12 go_pro_2. Custom events: RaceJoined, RaceSkipped.
2. **Notification strings** (Creator Hub > Engagement > Notifications). Please make these 3:
   - `daily_ready`: "Your day {streak} streak reward is waiting in SPEED ARC!"
   - `new_league`: "A new league just opened in SPEED ARC. Come race!" (for the NOTIFY ME gates)
   - `weekly_top`: "You finished top 3 this week! Your title is waiting."
   Sending them needs an Open Cloud API key (Creator Hub > Secrets). Tell me when they exist and I'll wire the sender.
3. **Codes:** to add a code without publishing, in a live server's console: `_G.SpeedArcCodes.add("SUMMER", { Minutes = 5, Rolls = 1 })`. Remove: `_G.SpeedArcCodes.remove("SUMMER")`.

## Screenshots
![[2026-10-28 p4 0 loading.jpg]]
![[2026-10-28 p4 1 go to sprint lane.jpg]]
![[2026-10-28 p4 2 first step combo.jpg]]
![[2026-10-28 p4 3 race offer.jpg]]
![[2026-10-28 p4 4 tutorial race boost.jpg]]
![[2026-10-28 p4 5 first shoes title.jpg]]
![[2026-10-28 p4 6 locker highlight.jpg]]
![[2026-10-28 p4 7 silver free roll.jpg]]
![[2026-10-28 p4 8 after tutorial go train.jpg]]
![[2026-10-28 p4 daily.jpg]]
![[2026-10-28 p4 quests.jpg]]
![[2026-10-28 p4 leaderboards.jpg]]
![[2026-10-28 p4 profile.jpg]]
