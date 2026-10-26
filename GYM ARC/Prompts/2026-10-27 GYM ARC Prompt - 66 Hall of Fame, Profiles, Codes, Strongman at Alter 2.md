---
date: 2026-10-27
tags: [gymarc, prompt]
status: in progress
---
# 66 Hall of Fame, Profiles, Codes, Strongman at Alter 2

Back to [[00 GYM ARC Home|GYM ARC Home]]

Part 4 (Strongman at Alter 2) done 27 Oct: [[GYM ARC - Strongman Yard]]. Parts 1-3 not started.

```text
Big endgame + retention update (owner, 27 Oct). The game is live: change carefully, never delete player data (migrate), never undo the owner's manual Studio changes. Follow CLAUDE.md Speed rules. Mobile first. All numbers in Config. Owner rule: Studio is the only copy, so do File > Save to Roblox after each part and remind me to download a backup copy. Work in this order, test each part before the next.

PART 1: CODES (small, do first)
- A "CODES" button in Settings and a small CODES chip next to the Store button. Opens a small panel: text box, REDEEM button, result line.
- Each code: reward (coins as minutes of coins at the player's stage via Economy.Minutes, shakes/boosts, free trainer rolls, a title), optional expiry date, optional "group members only" (existing group perks check), once per player (saved in the player's data, case-insensitive).
- Codes live in a DataStore ("Codes") so I can add/disable them WITHOUT republishing, using the existing admin console (new commands: code add / code disable / code list). Servers refresh the list every 5 min. A small default list in Config as fallback.
- Messages: "+5,000 COINS!" with the reward popup; "That code doesn't exist", "Already used", "This code expired", "Group members only: join the group, then tap CHECK AGAIN".
- Rate limit: 5 tries a minute per player (server).
- Starting codes: RELEASE (10 min of coins + 2 shakes), GYMARC (1 free trainer roll), HALLOFFAME (15 min of coins, add when Part 2 ships), STRONGMAN (1 free roll + 1 Mass Gainer).
- Analytics: Code_Redeemed_<CODE>.

PART 2: HALL OF FAME (rebirth after the last alter)
A) WHEN: after ALTER 15 (end of Tier 3). This requirement NEVER moves in future updates. A gold "HALL OF FAME" button appears (HUD card where the NEXT alter card was) + a Coach Dex line: "You made it to the top. Ready to be a legend?"
B) CONFIRM SCREEN (shows exactly what happens before you agree):
- "YOU KEEP": trainers (levels/evolutions), coins, alter skins (as cosmetics), titles, auras, styles, gear, passes and everything bought with Robux, LVL (keeps counting).
- "YOU START OVER": height, Growth Spurts, muscle levels, Body Alters 1-15 (their gains).
- "YOU GET": the next star and its perks (table below), your statue in the Hall, a free trainer roll + the star-only aura on the first star.
- Big gold ENTER THE HALL OF FAME button + "Not yet". Never forced; players can stay at the end forever.
C) STARS (permanent, saved; Config table):
- ★1: +25% EXP, start at Growth Spurt 2
- ★2: +50% EXP, gear always kept on
- ★3: +75% EXP, +10% coins, start at Growth Spurt 3, unlocks ALTER TIER 4 (when it exists)
- ★5: +125% EXP, +20% coins, Growth Spurts 1-4 instant, unlocks ALTER TIER 5
- ★10: +200% EXP, gold name + "LEGEND" title
- after ★10: +10% EXP per star, no cap on stars.
- Target run times (tune with tests/pacing, bot play with trainers): 1st run as now (~5 h), 2nd ~2.5 h, 3rd ~1.5 h, never under ~1 h. Stars' EXP counts in its own boost source "HallOfFame" (shown in the boost row + Stats).
- Future alter tiers (4, 5, ...) come AFTER the Hall of Fame point and are unlocked by stars (★3 Tier 4, ★5 Tier 5, ★5+ Tier 6); they never lengthen the run to the Hall of Fame. Their skins stay unlocked forever.
D) THE CEREMONY (~6 s, skippable after the first time): the player is placed on the ceremony stage in the Hall, spotlight, crowd cheer, confetti, a gold flash, "★1 HALL OF FAME" slams in, the player's PEAK body is saved as their statue, then a fade and they wake up small in the Starter Gym with a toast "★1: +25% EXP · Start at Growth Spurt 2". Nearby players see the ceremony on the stage.
E) THE HALL (in the TOWN PLAZA, the open side facing the street; move the existing leaderboards + champion statue next to it so it's one "fame" spot):
- An open hall with white marble columns, a gold roof edge, warm spotlights, gold glow at night. Open at the front.
- FIXED size, never grows: exactly 3 statues on pedestals (the top 3 players of all time by stars, global OrderedDataStore, refreshed every few minutes), one gold board (TOP 10 ALL TIME by stars + "LEGENDS IN THIS SERVER", max 10, scrolls), one empty middle pedestal, the ceremony stage.
- "VIEW MY STATUE": on the board / your profile: your own peak-body statue appears on the middle pedestal ON YOUR SCREEN ONLY (client-side), with your name and stars.
- Statues = the saved peak body (muscle sizes, height, alter skin, title), built with the existing stage meshes (light, no live meshes).
F) SHOWING OFF: stars next to the name over the head (★★★, gold for 10+), the HALL OF FAME leaderboard (most stars), a "HALL OF FAMER" title on ★1.
G) EXISTING PLAYERS already at Alter 15: they get the button right away + a one-time popup "NEW: HALL OF FAME".

PART 3: PROFILES
- Tap any player (or their name over the head) -> PROFILE card. Your own from the menu card and a PROFILE button in Settings/Stats.
- Card (premium style like the Alters/Auras panels):
  - Top: avatar headshot, name, Hall of Fame stars, equipped title (in its style), membership tier (Bronze..Diamond, Config/ShowOff).
  - VIEW STATUE button (their peak-body statue, same as Part 2, shown in a ViewportFrame or on the Hall pedestal for you only).
  - Stats rows: LVL, height, current alter, lifetime reps, best lift (PR + machine), posing show wins, Strongman Showdown wins, playtime.
  - Their 3 best trainers as mini tiles.
  - Collection: titles x/y, auras x/y, alter skins x/y (Trainer Index later).
  - Badges row: event titles (e.g. "BETA TESTER", future "HALLOWEEN 2026").
  - Buttons: ADD FRIEND (Roblox prompt), INVITE TO CREW (if you lead/own a crew), CHALLENGE (arm wrestle) when nearby.
- Data comes from the server (only public info), cached per server; opening a profile never lags.

PART 4: STRONGMAN YARD AT ALTER 2
- The Strongman Yard unlocks at ALTER 2 (Shredded) instead of Growth Spurt 5. The Powerlifting Gym stays at Spurt 5.
- Gate + the gym's back door: sign "UNLOCKS AT ALTER 2"; tapping shows the locked toast + progress ("NEXT: SHREDDED 42%"). Players below Alter 2 can watch the showdown and scoreboard from outside the fence.
- Unlock guide + Coach Dex line at Alter 2 ("You unlocked the STRONGMAN YARD!") with GO TO; the Alter 2 popup lists it. Remove it from Spurt 5's unlock line.
- Once unlocked it stays unlocked forever, also after the Hall of Fame reset.

ANALYTICS: HallOfFame_ButtonShown / Confirm_Opened / Entered (with star number), HallOfFame_SecondRun_Done, Profile_Opened, Code_Redeemed_<CODE>.

TEST (phone first): redeem each code (valid, used, expired, group-only, wrong); add a code from the admin console; a save at Alter 14 -> 15 (button + popup), the confirm screen, the ceremony, waking up small at Spurt 2 with everything kept (check trainers, coins, skins, passes), a second run's speed in the pacing sim, the Hall with 3 statues + VIEW MY STATUE; a profile of another player and your own; the Strongman gate at Spurt 5 without alters and after reaching Alter 2. Screenshots of each. Progress note + new feature notes "GYM ARC - Hall of Fame", "GYM ARC - Profiles", "GYM ARC - Codes" in the vault, and update the gameplay plan.
```
