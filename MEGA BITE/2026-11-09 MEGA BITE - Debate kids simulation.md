---
date: 2026-11-09
tags: [megabite, simulation, debate-kids, design, launch]
status: design stage. A model of friend-group arguments, not real kids.
---
# MEGA BITE: debate-kids simulation (9 Nov)

Owner: "use the debate kids method. simulate multiple group of kids arguing over which roblox game to play. find the objections they have to yours and improve the game until everyone agrees to play ur game."
Method: [[Debate kids simulation]] (new). Code: `MEGA BITE/Calc/debatekids.py`, output `debate_results.txt`. Inputs: [[2026-11-09 MEGA BITE - Full research report]], [[2026-11-09 MEGA BITE - Map plan + kid simulations]], [[2026-11-09 MEGA BITE - EXP curve tuning + slice prompt]].

## How it works
- **3,000 friend groups** of 3-5 kids. Each group chooses between MEGA BITE and 3 random rivals from: Brookhaven RP, Blox Fruits, 99 Nights in the Forest, Murder Mystery 2, Steal a Brainrot, Fish It!, Break and Steal an Egg (top live games Jun / Nov 2026), Be Fish, DEVOUR, SharkBite 2 (our genre).
- **10 kid types**, each with what they argue for and a deal-breaker: Grinder ("nothing to do after a day"), PvP sweat ("no real fighting"), Little sister, 7 ("too scary", "big kids will eat me", "not cute"), Cheap-phone kid ("it lags"), Social kid ("we can't play TOGETHER"), Trend chaser ("nobody plays it, it's dead"), Quality nerd ("looks like AI slop", "a copy"), No-Robux kid ("pay to win"), Shark fan, 8, Bored-fast kid ("boring at the start").
- **Friends only play a game NOBODY vetoes**; among those, the best total score. "Agree" = no kid vetoes MEGA BITE.
- Rival scores are estimates from public info (0-10 on 18 traits). Calibration: the big games get 18-60% of groups agreeing, DEVOUR 2% (it's falling for real).

## Results
| Version | Everyone agrees | MEGA BITE 1st pick | Top objections left |
|---|---|---|---|
| M0 the concept today | **18%** | 27% | "we can't even play TOGETHER", "nobody plays it, it's dead", "it's too scary" |
| M1 + SCHOOLS at launch: join a friend, crews of 4, shared FRENZY, co-op squid | 34% | 35% | dead, too scary, not cute |
| M2 + cartoon look: big eyes, round fins, funny gulp; scary only in the Trench | 60% | 49% | dead |
| M3 + full servers: fill the fullest first, 16 slots, NPC life, creator launch | **100%** | 71% | none |
| M4 + visible weekly updates: countdown, roadmap board, Saturday event | 100% | 74% | none |
| M5 + the twist up front: carry-home + abilities in the 1st minute and the thumbnail | 100% | 80% | none |
| M6 + first-minute fixes from the sims, auto-swim, green/red outlines | 100% | 86% | none |
| M7 + Red Trench for sweats: crown bounty, APEX HOUR, weekly Trench board | 100% | 88% | none |
| **M8 + launch push (marketing): creators + a code + the Saturday event** | **100%** | **90%** | none |
- **Robustness:** every MEGA BITE score moved ±1 at random (60 tries): everyone agrees in 100% (median and worst), 1st pick 89%. Before M7-M8 it was only 64% (worst 32%): PvP thrill and "players online" sat right on a deal-breaker.
- **The one risk design can't remove:** if the launch crowd is small (2-3/10), "nobody plays it, it's dead" comes back: 60% agree, 64-66% 1st pick. So the launch push (creators, code, a full first Saturday) is part of the game plan, not an extra.
- Seeds 5 and 6: 100% agree, 90% 1st pick.

## Example debates (seed 11)
- **Little sister (7), PvP sweat, No-Robux kid, Cheap-phone kid, Shark fan** · MEGA BITE vs Blox Fruits, Be Fish, 99 Nights.
  M0: the sister: "it's too scary" and "it's not cute" → they play **Be Fish**. M8: they play **MEGA BITE** (Be Fish: "no real fighting"; Blox Fruits: "pay to win", "not cute"; 99 Nights: "too scary").
- **Quality nerd, No-Robux kid, Little sister, Social kid, Grinder** · vs SharkBite 2, Be Fish, 99 Nights.
  M0: "too scary", "not cute", "we can't even play TOGETHER" → **Be Fish**. M8: **MEGA BITE** (SharkBite 2: "pay to win", "nothing to do after a day").
- **Shark fan, No-Robux kid, Bored-fast kid, Social kid** · vs Steal a Brainrot, Break & Steal an Egg, Blox Fruits.
  M0: the social kid: "we can't even play TOGETHER" (they still chose MEGA BITE: every option had a veto). M8: MEGA BITE with no objection; the rivals got "pay to win" and "boring at the start".

## What changes in the game plan
1. **Schools (crews of 4) move from week 2 to LAUNCH:** a join-a-friend button, shared FRENZY bites, a shared bank, the squid boss as a co-op fight. The biggest objection.
2. **Cartoon look:** big eyes, round fins, a funny gulp sound, bright Safe Reef; the scary deep only in the opt-in Red Trench. (Fits the Mild rating rule: no blood, no scars.)
3. **Full servers:** 16 slots, matchmaking fills the fullest server first, NPC fish everywhere so no server feels empty.
4. **Visible weekly updates** on a board in the reef: the countdown to Saturday 15:00 UTC, the roadmap, the event.
5. **Show the twist at once:** the first minute and the thumbnail show carrying EXP home and an ability, so it's not "a copy of Be Fish/DEVOUR".
6. **Red Trench for the sweats:** the crown shark has a bounty, APEX HOUR marks the top shark on everyone's map, a weekly Trench board. (Still opt-in; fairness rules stay.)
7. **Launch push:** creators + a code + the first Saturday event, so the first players see full servers.

## Honesty
A model of arguments: the kid types, deal-breakers and rival scores are estimates, and the fixes raise scores by our judgement of each feature. Use it to find the objections and their order, not as a forecast. The real check: a friends test of the slice (ask each kid what they'd play instead and why), then the onboarding funnel.

## Update (owner 9 Nov, 11:39): the launch push is $200 of Roblox ads, NO YouTubers
Owner: "launch push is probably 100 dollars of roblox ads on sunday and another 100 on saturday. but youtubers is not possible."
So M8 (creators + code + event, crowd 5) is replaced. `Calc/launchads.py` works out what $100 of ads buys (12-min sessions, ~18 h of delivery, peak = 1.6x the average) and reruns the debate on versions M0-M7:
| $100 of ads in one day | Players | Avg CCU | Peak CCU | Tile ("playing") | Everyone agrees | 1st pick | The week after |
|---|---|---|---|---|---|---|---|
| Best case: official cost per play ($0.008) | 12,500 | 139 | 222 | 4/10 | **100%** | 88% | 60% |
| Good page: 25% of clickers press Play (~$0.044 per player) | 2,273 | 25 | 40 | 2/10 | 60% | 64% | 60% |
| Galaxy-like page: 6% press Play (~$0.18 per player) | 545 | 6 | 10 | 1/10 | 60% | 63% | 60% |
- At a small "playing" number only ONE kid type still says no: the trend chaser ("nobody plays it, it's dead"). Every group without him agrees. No design feature removes that objection: only a bigger player count does.
- **The game page is the biggest lever on the ad money:** Galaxy's page turned $100 into ~545 players; a fixed page (likes, no [ALPHA], real-gameplay thumbnails, the video) ~2,300; the best case ~12,500. Fix the page before the first dollar.
- **The ad players only help if they stay:** the week after, the count falls back (~12% of the peak at D1 ~10%). Lasting players come from Roblox Home recommending the game (28-day retention, co-play, playtime), not from the ads.

### The launch plan (replaces the "launch push")
1. **Saturday $100 first, on the update day** (after the 15:00 UTC update, kids' Saturday peak ~19:00 UTC). Maximize Plays, daily budget $100; check after 2 hours that it is really spending (Galaxy spent only $29 of its budget).
2. **Read the numbers Sunday/Monday:** D1, 5-minute retention, average playtime, the onboarding funnel. **The second $100 only if D1 ≥ ~10% and playtime ≥ ~15 min** (K02/K05 rule: ads before the game holds players tell Home the game is weak). Then spend it on the NEXT Saturday with the next update (a second peak + a code), not the day after.
3. **Free channels:** a code for the group, Discord, and ONE launch announcement in Myanmar Builders Club (the owner did the same for Galaxy's alpha on 7 Nov; owner's call).
4. **Make every server look alive at a small player count:** 10-slot servers at launch (raise to 16 in config as players grow), fill the fullest server first, NPC life everywhere. This doesn't change the tile number but stops "joined, it's empty, left".
5. **Bring-a-friend:** an invite reward (a cosmetic when an invited friend reaches Piranha) + the Schools bonus, so friend groups bring each other in, the free version of creators.
6. **The ads also buy the Kids/Select gate:** the first wave (13+/16+ players) counts toward the 250 engaged, age-checked 16+ plays needed within 60 days.
