---
date: 2026-11-01
tags: [gymarc, progress, onboarding, loading, analytics]
---
# GYM ARC - faster loading, new players skip the menu (1 Nov)
Owner: 10 new players sat at spawn at 35.3K for ~2 min without moving, then left.

## Data (Creator Hub, last 7 days, read 1 Nov)
- Onboarding funnel: 30,237 new players; Joined 100% -> Genetics kept 99.9% -> walked to the Flat Bench 72.1% (27.9% gone, ~8,400 players). First rep 99.4%. Stamina ran low 86.4% (13.6% gone).
- FirstMinutes funnel: tutorial done 70.8% -> goal 25% 70.7% -> 50% 67.5% -> 75% 44.0% (-35%) -> goal reached 29.1% (-34%) -> first spurt 29.0%. The second half of the first Growth Spurt loses more than half of the players: next big fix.
- Economy (28 days): Reps 143M, SpurtMilestone 36.8M (a quarter of rep income, cut today), PlaytimeGift 18.2M, TutorialDone 17.5M; sinks TrainerRoll 26M, PumpShop 17.5M.
- Why "didn't move at spawn": while the loading screen or the menu is up the character stands frozen at spawn. They never got past loading / the menu.

## Changes
- New players (tutorial step 1) skip the menu: PLAY presses itself the moment the menu is ready (MenuClient). Returning players keep the menu.
- LoadingScreen: UI image preload capped at 2 s (it had no cap); after the menu is ready World 5 -> 1.5 s, Windows 3 -> 1 s, SKIP after 2 s (was 3), give-up 10 -> 5 s. Everything still loads in the background.
- MenuClient: stream-around timeout 8 -> 3 s.
- New "Loading" funnel (ActionService LoadStep): 1 Joined (server, PlayerData.Loaded) -> 2 Menu / loading done -> 3 Playing, new players only; custom events Load_MenuShown / Load_Playing = seconds since the client started (real device load times).
- Studio: fresh player went straight from loading into the gym with Coach Dex's first line; returning save still gets the menu. (Studio data load ~8 s is Studio's server start-up; live saves load much faster.)
