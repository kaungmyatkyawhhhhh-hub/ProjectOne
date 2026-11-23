---
date: 2026-11-23
tags: [gymarc, retention, tutorial, progress]
---
# GYM ARC: come back tomorrow + auto chapter 1 (23 Nov, v1894, NOT published)

## Why (stats checked 23 Nov)
- **Tutorial fix (v1890) worked:** first Growth Spurt reach 62% → **69%**; 75% → ready loss 17-21% → 12%; out-of-memory exits -68%.
- **Roblox cut exposure:** home recommendation new players 2,406 (14 Nov) → 855 (16 Nov) → 306 (19 Nov) → 189 (22 Nov); thumbnail impressions -81% in a week (113k vs 595k).
- **7-day averages:**
  - D1 retention 6.19% (-14%);
  - playtime 11.7 min (-17%);
  - DAU 3,372 (-39%);
  - revenue 2,058 Robux/day (-40%);
  - like ratio 68% (225 up / 105 down);
  - play-through rate 3.70% (84th percentile).
- No ad players since 8 Nov.
- **Owner:** "do 1 and 2" (1 = a reason to come back tomorrow, 2 = the path from Growth Spurt 1 to 2); "go on autopilot".

## What changed
1. **ComeBackClient (new):** a small bottom card "COME BACK TOMORROW!" with tomorrow's login-calendar reward (e.g. "DAY 2 reward: BEAST FORMULA + 1,150 coins") and the streak.
   - Shown 10 s after the first Growth Spurt, and once a day ~10 min into a session.
   - A NOTIFY ME button opens Roblox's notification opt-in (only when CanPromptOptInAsync allows; 13+). Otherwise the button reads "Got it!".
   - Studio test: Workspace TestComeBack.
2. **Chapter 1 moves you itself:** `autoGo` on BeatBenny (to Benny), GoBeach, BeachChest, BeachCore, BeachLegs, BeachBack and FillSpurt2.
   - TutorialClient auto-go now works once per step+target, also from another machine (a 2 s beat to see the set end).
   - Lines changed from "Tap STOP, then..." to "Next: LEGS...".
3. **Growth Spurt 2 grows by itself** 5 s after ready while the tutorial runs, like Growth Spurt 1 (ProgressClient).
- **Test** (new player at phone size, REP taps + arm-wrestle taps only):
  - Growth Spurt 1 at 44 s;
  - Benny → Beach Gym → Coral → chest/core/legs/back;
  - **Growth Spurt 2 at ~2:55**;
  - 0 errors.

## Notifications: what's left (owner, optional)
- Sending needs a notification string (Creator Hub → Engagement → Notifications) + an Open Cloud API key.
- Messages must be personal (not ads); 13+ only.
- The opt-in prompt is in.

## Check after publishing (7 days)
- D1 retention (6.2% now), Growth Spurt 2 reach (~half of GS1 before), playtime (11.7 min).
- Home recommendation plays/day (189 on 22 Nov).
