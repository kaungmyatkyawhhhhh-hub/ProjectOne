# MEGA BITE - first minute pass 1 (12 Nov 2026, 23:40)
Owner: "yes do it rn" (the first-60-seconds tutorial). Built on the vault research [[Playbook notes - Onboarding, retention and live ops]]: teach through the world with pictures, contextual hints, timed hints only for stuck players, the first action in seconds, kids may not read well; log an onboarding funnel.

## Test as a brand-new player (before)
New Studio switch: `workspace` attribute **MB_FreshPlayer = true** -> `MB_Data` starts you from the defaults and never saves (the real save is not read or touched; Studio only). **Set it back to false to play your own save** (it is false now).
- t=0: the Minnow spawns standing still (no auto-swim). Nothing shows how to swim.
- The welcome school sat 23 studs ahead, held 8 s, then swam off (t=16 s); the next edible fish was then ~100 studs away.
- The ground chevrons (MB_GuideArrows) only show when food is 20+ studs away, so they barely showed in that moment.

## What was built
1. **MB_FirstMinute** (new LocalScript; only while you are a Minnow that has never eaten):
   - **How to swim**, after 3 s standing still, for your device: phone = a glowing finger-dot that drags a swim stroke over the stick area + "DRAG TO SWIM"; PC = 3D W A S D keycaps, W presses in gold + "PRESS W TO SWIM"; controller = the left stick pushing up. Pops in with Back easing, gone the moment you swim, never returns.
   - **EAT!** a bouncing gold "EAT!" + arrow over the nearest fish you can eat that is ON SCREEN (off-screen fish get a penalty), from your first swim until your first bite. Drawn on the screen by projection (a BillboardGui in this setup did not draw in the Studio test).
   - Hidden while a window or cutscene is open; the whole thing deletes itself after the first bite.
2. **Welcome school** (`GameConfig.Fish`): WelcomeAhead 25 -> **16** studs; new **WelcomeMax 40**: the school now waits in front of the new player until their first bite (up to 40 s), not just 8 s (`MB_FishServer`).
3. **MB_Funnel** (new server Script): `AnalyticsService:LogOnboardingFunnelStepEvent` steps 1 Joined, 2 FirstSwim (moved 12+ studs), 3 FirstBite, 4 Quest1Done (5 fish), 5 Piranha, 6 OpenSea, 7 TenMinutes (the Creator Rewards threshold). Shows in Creator Dashboard > Analytics > Funnels after launch. Step numbers must never change.

## Checked in Play (MB_FreshPlayer)
- 3 s still: the PC hint shows (W A S D + "PRESS W TO SWIM"), welcome shrimp 16 studs ahead.
- Press W 0.7 s: first bite at about 4 s from spawn ("NEW FISH! CORAL SHRIMP", stars, 1/5, NEXT: PIRANHA 32%), hint gone.
- Swim backwards instead: "EAT!" sits over the welcome school on screen.
- Not checked: the phone and controller hints on a real device (only the PC one was seen), the funnel in the dashboard (needs a published game).

## Same night: first-person right-click fix
Owner: "in first person, when i press right click, my screen tilts up". In first person the mouse is locked to the centre; right-click switched it to LockCurrentPosition, the cursor jumped and that jump was read as one huge look move (pitch up). Now right-click does nothing in first person, and any single mouse jump over 220 px is ignored as a look. Checked: in first person, right-click + a 280 px cursor jump left the pitch at -12.0 deg. Backup `ServerStorage.MB_Swim_preFpRmb_12Nov`.

## Backups
`ServerStorage`: MB_Data_preFreshTest_12Nov, GameConfig_preFirstMinute_12Nov, MB_FishServer_preFirstMinute_12Nov, MB_Swim_preFpRmb_12Nov.

## Next for the first minute
- Run the impatient-kid sim on the live numbers (not done tonight): time to Piranha is 25 EXP; check the dead time between quest 1 and the first evolve.
- After launch: read the funnel; the biggest drop is the next fix.
