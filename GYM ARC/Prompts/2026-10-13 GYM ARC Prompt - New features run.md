---
date: 2026-10-13
tags: [gymarc, prompt]
status: done
source: GYM_ARC_new_features.md
---
# 2026-10-13 GYM ARC Prompt - New features run

Back to [[00 GYM ARC Home|GYM ARC Home]]. Saved exactly as sent (original file: `GYM_ARC_new_features.md`). Started on 2026-10-13.

BIG FEATURE RUN. Work through the tasks IN ORDER. Don't ask me anything; make sensible choices and write them down.
After EACH task: play-test solo and with 2 players (local server), check phone size, check Output for errors, run the test suites, take screenshots into the screenshots folder, export changed scripts to src/, update PROGRESS.md and commit. If something is blocked, write why in PROGRESS.md and move on to the next task.

Rules (same as always):
- Kids' game, mostly played on mobile. Big buttons, short text, no emojis in the UI, no grunts, no real people, brands or copyrighted art.
- Monetization stays OFF. Everything is earned with coins or by playing.
- Reuse what already exists (machine system, HUD, toasts, titles system, statue, poses, NPCs, Config). Don't duplicate systems.
- Every new number goes in Config (one table per feature, e.g. Config.PosingComp).
- Sounds: leave empty SoundId fields with a comment. I pick the IDs myself.
- All new builds go in a Decor/Feature folder per area so I can find and delete them easily. Keep FPS at 60 on the phone emulator.
- Server is authoritative for rewards, votes, scores and stats. Never trust the client for coins or wins. Add basic rate limits on every new RemoteEvent.

====================================================================
TASK 1. POSING COMPETITION
- Build a posing stage in the town plaza (or next to the statue): raised stage, 3 spots marked on the floor, spotlights, a simple scoreboard sign above it. No logos.
- Every Config.PosingComp.Interval (default 12 min) a round starts. Server-wide announcement + countdown: "Posing Competition starts in 60s! Go to the stage!" with a waypoint arrow.
- Join by walking onto the stage before the countdown ends (max Config.PosingComp.MaxPlayers, default 6). If fewer than 2 players join, fill with NPC bodybuilders so solo players can still play.
- Round: 3 poses (use the existing poses, e.g. Front Double Biceps, Lat Spread, Most Muscular). Each pose, the player taps the pose button shown on screen within a short time window; holding the pose with good timing = small bonus.
- Score = muscle size (total look) + balance between groups + timing bonus. Weights in Config. NPC judges show a score card (1-10) above each player after each pose.
- Audience vote: players NOT on stage get a simple vote UI (tap a contestant's name) during the last pose. Votes add a small bonus in Config. You can't vote for yourself.
- Results: 1st/2nd/3rd on podium spots, coins (Config), and the winner gets the title "Posing Champion" (existing titles system) and is shown on the town statue until the next round (statue uses the static stage meshes, same as other players).
- Leaving or resetting mid-round = out, no reward, no errors.
Screenshots: countdown UI, 3 players posing with score cards, the vote UI, the podium, the statue showing the winner.

====================================================================
TASK 2. DAILY QUESTS + LOGIN STREAK
- 3 daily quests per player, picked from a pool in Config, reset at 00:00 UTC. Examples:
  - Do 50 reps on any chest machine / 50 leg reps / 100 reps total
  - Spot another player 2 times
  - Run 1 km on the treadmill
  - Enter a posing competition
  - Win an arm wrestle (after task 3 exists)
  - Train 3 different muscle groups
- Quests track automatically using the existing EXP/rep events. Show them in a small Quests panel (reuse the existing menu style; one button on the HUD side bar). Progress bars, a Claim button when done, coins as the reward.
- Bonus: completing all 3 gives an extra reward.
- Login streak: 7-day calendar with rising coin rewards (day 7 = big reward + a title "Dedicated"). Missing a day resets the streak to day 1. Show a popup on join with the Claim button. Saved per player.
- Make sure quests that need another player (spotting) can also be done another way if the server is empty (e.g. swap button once per day).
Screenshots: quest panel with progress, the streak popup on day 1 and day 7.

====================================================================
TASK 3. ARM WRESTLING
- Add 2 arm wrestling tables (starter gym and pro gym). Use the existing machine system to sit down (same Occupy flow and prompt style).
- Two players sit = match. One player sits alone = they can choose to play against an NPC.
- Gameplay: 3-2-1 countdown, then both players tap a big button as fast as they can for up to Config.ArmWrestle.MaxTime (default 8 s). A bar in the middle shows who is winning. Strength bonus: each tap counts a bit more for stronger arms (biceps + forearms + grip look), capped so tapping skill still matters (formula and cap in Config).
- Animate the two arms pushing over the table based on the bar. The winner's arm slams the loser's arm down.
- NPC opponents: 3 difficulty levels from weak to strong (Config). Beating the strongest NPC gives a title "Arm Wrestling King".
- Rewards: coins for winning, small Forearms/Biceps EXP for both players (less than a real machine so it never replaces lifting).
- Anti-autoclicker: cap taps per second on the server (Config, default 15).
Screenshots: two players mid-match with the bar, the win screen, playing vs NPC on mobile size.

====================================================================
TASK 4. LEADERBOARDS
- Wall boards in each gym + one in the town plaza (SurfaceGui), top 10 each:
  - Biggest (total muscle look)
  - Strongest (heaviest lift ever)
  - Tallest (height, max 7'0")
  - Most Reps Today (resets daily)
  - Posing Wins
  - Arm Wrestling Wins
- Use OrderedDataStores for all-time boards and a daily key for "today" boards. Update at most every 60-120 s (Config) to stay within DataStore limits. Show player name + Roblox avatar headshot + value.
- Show "Your rank: #123" under each board for the viewing player if they are not in the top 10.
- Only the boards near the player need to update (respect StreamingEnabled).
Screenshots: each board with test data.

====================================================================
TASK 5. SHAKES & MEALS (SMOOTHIE BAR)
- Build a smoothie bar counter in the pro gym (and a small cart in the starter gym). Walk up and use the existing prompt style to open a small shop panel.
- Items, bought with coins (prices, strength and durations in Config):
  - Protein Shake: +20% EXP for 5 min
  - Energy Shake: stamina refills 50% faster for 5 min
  - Chicken & Rice: +10% EXP and +10% stamina refill for 10 min
  - Coconut Water (beach gym only): faster cardio distance for 5 min
- Only one boost of each type at a time; buying again extends the time (with a max in Config). Small boost icons with timers on the HUD.
- Boosts pause when the player leaves and resume when they rejoin (saved), or expire; pick one, write it down.
- Drinking animation: the character holds a shaker for 1-2 s. No real brand names on anything.
Screenshots: the shop panel, the HUD timers, the drinking animation.

====================================================================
TASK 6. NPC RIVALS (one per gym)
- Each gym gets a named rival NPC (reuse Dante if he fits; make 2 more with simple original looks and names). They train on machines in their gym like the current NPCs.
- Talk to a rival (prompt) to see a short challenge card. Challenge = beat his record on a specific lift (or beat him in arm wrestling for one of them). Their numbers in Config, rising per gym (starter < pro < beach or whatever order the gyms unlock).
- Beating a rival: coins, a title ("Beat Dante", etc.), and it unlocks/points the player toward the next gym. If gyms are already unlocked another way, keep that and make the rival an extra goal instead; write down what you chose.
- Rivals react: a short line of text when you beat them or lose ("Not bad, rookie." / "Come back stronger."). Kid-friendly, no insults.
- IMPORTANT: rivals must use the fixed NPC size rules (one source of truth for their size; no shrinking/growing when you get close or while they train).
Screenshots: each rival's challenge card and the win message.

====================================================================
TASK 7. SMALLER ADDITIONS (do these last)
A) Flex emotes: an Emotes button (or reuse the existing poses) so players can hit a pose anywhere: Front Double Biceps, Lat Spread, Most Muscular, Side Chest, and one fun one (e.g. a victory wave). Works on mobile with one tap. Other players see it.
B) Gym buddy pets: build on the existing pet (Plates the cat). 3-4 more simple pets bought with coins that follow you and play a cheer animation when you finish a set. Cosmetic only, or a tiny bonus in Config (default 0). No copyrighted characters.
C) Day/night cycle in town: a full day takes Config.DayNight.Length (default 20 min). Street lamps, shop windows and gym signs turn on at night. Gym interiors keep their own lighting. Check FPS at night (lights!): keep within the 1-shadow-light-per-room rule.
D) Photo mode: a camera button at the mirrors (and in the posing area) that hides the HUD, lets the player orbit/zoom the camera around themselves, pick a pose, and press a button to hide the UI so they can take a screenshot with their device. Tap anywhere to exit.
Screenshots: each emote, the pets, the town at day and night, photo mode.

====================================================================
WHEN DONE: write a short report at the top of PROGRESS.md:
- what got done per task, and anything you couldn't do and why
- every new Config value I might want to tune (list them)
- every new SoundId field I need to fill
- FPS on the phone emulator before vs after all tasks
- "TRY FIRST": the 5 things I should test first
- the list of screenshot file names
