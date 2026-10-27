---
date: 2026-10-28
tags: [speedarc, prompt]
status: todo
---
# 4 First 15 minutes, daily, quests, social (M4)

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

```text
SPEED ARC milestone M4: the reasons to stay and come back. This is the most important prompt for players (GYM ARC lost most players in the first minutes). Follow CLAUDE.md (Quick Rules). Never touch GYM ARC.
READ (only these): GDD sections 14, 15, 17, 18, 21 and 26; "SPEED ARC - Lessons from GYM ARC.md" sections 3, 4, 7 and 10. You may READ GYM ARC's daily rewards / playtime gifts / codes / notifications code to copy and adapt.

1) TUTORIAL = GDD 21 minute by minute
- 0:05 spawn on the school steps, Coach Benji: "Everyone starts slow. Let's fix that!", NEW RUNNER BOOST 2x for 15 min of play.
- First tap within 15 s: gold arrow + a floor path + GO TO button to the Sprint Lane. First tap = +100 coins and "FIRST STEP!".
- ~1:00 tutorial race vs 3 slow NPCs, BOOST taught with one big prompt, a close WIN. ~1:40 podium, gold medal.
- ~2:30 buy Canvas Runners (enough coins given). ~5:00 Silver rank + a free coach roll.
- Rules: steps never skip themselves while the player can't do them; the hint stays (comes back every 12 s) until the step is done; no toast or popup on top of a hint; no shop offers in the tutorial; it can't get stuck (every step has a safety timeout that only counts while the step is possible). Test it on a phone-size screen as a fresh player, step by step, with a screenshot per step.

2) DAILY + QUESTS + PLAYTIME (GDD 15)
- Daily streak 7 days (one missed day allowed), shown with what tomorrow gives.
- 3 daily quests; unclaimed ones pay before the reset; all 3 = bonus + a coach roll.
- Playtime gifts at 3/8/15/25/40/60 min of play today, paying by themselves with a popup naming the next one.
- Popups only when off a station and not in a race, one at a time.

3) CODES
- CODES button + Settings field. Codes in a DataStore (add new ones without publishing), admin console command to add/remove. Launch codes: SPEEDARC, FIRSTRACE, RELEASE (rewards in Config).

4) LEADERBOARDS (GDD 17)
- Leaderboard Wall in the hub + a board in each league area + a panel: Top SPEED, Most Wins, Fastest Sprint per league. Weekly boards (Most Wins This Week, Best Time This Week) reset Monday; top 3 get a title + coins. Versioned store names so boards can be reset.

5) TITLES, MEDALS, PROFILE (GDD 14)
- Titles from the GDD list, shown over the head; the medal count next to the name.
- Tapping a player opens a quick menu: VIEW PROFILE / RACE THEM / ADD FRIEND. Profile shows league + rank, top speed, best times, medals, coaches, trail, title.
- RACE THEM = a private 1v1 sprint (coins only for the first 3 a day).

6) SOCIAL (GDD 18)
- Friend Boost +10% training per friend in the server (max +30%), with a toast "Maya is here! Friend Boost +10%".
- INVITE button: Roblox invite screen; +10% for 30 min when a friend joins from your invite.
- Favourite prompt once, after the first Go Pro. Notifications opt-in after the first daily claim (I'll make the notification strings in Creator Hub; tell me what to make).

7) ANALYTICS
- Onboarding funnel steps exactly as GDD 26 (each fires once per player, saved flag, in order) + race joins vs skips.

TEST
- Fresh player on phone size: the whole first 15 minutes with screenshots and the time of each step (first tap, first race, first win, first shoes, first roll, Silver, Go Pro 1).
- Daily / quests / gifts with a fake clock; a code; weekly board reset in Studio; 2-player test for friend boost, profile and RACE THEM.
- Progress note + feature notes. Tell me the funnel step names and what I need to set up in Creator Hub.
```
