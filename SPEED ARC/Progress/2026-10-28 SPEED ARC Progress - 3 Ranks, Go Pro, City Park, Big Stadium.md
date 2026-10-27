---
date: 2026-10-28
tags: [speedarc, progress]
prompt: "[[2026-10-28 SPEED ARC Prompt - 3 Ranks, Go Pro, City Park, Big Stadium]]"
---
# Progress 3 - Ranks, Go Pro, City Park, Big Stadium (M3)

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

Done overnight without questions (owner asleep). Imports wait for the morning list at the end of prompt 6.

## Built
- **Ranks** ([[SPEED ARC - Leagues and Go Pro]]): Bronze, Silver, Gold, Platinum, Champion in leagues 1-3. Badge under the coins and a tag over your head ("CHAMPION - L1"). Rank up = popup, rising sound, gold ring on the ground, coins (1/2/3/5 minutes of coins).
- **HUD goal line** always shows the next thing: next station, next rank, or "GO PRO is ready!".
- **Go Pro:** Champion + race wins (1 / 2 / 3) -> big gold GO PRO button + a Coach Benji line. Confirm screen with YOU KEEP / YOU RESET / YOU GET. ~4 s cutscene (SKIP after the first time), then you arrive in the next league with a banner. x8 training per league, a free coach roll, a title (PARK RUNNER, STADIUM STAR). SPEED resets, everything else stays.
- **Portal Plaza** (behind the hub stands): 5 gates on a round platform. Open gates say "WALK IN" and teleport you. Locked gates go dark with "GO PRO FROM LEAGUE X". Mountain Trail + World Games = COMING SOON with NOTIFY ME (Roblox experience notifications).
- **City Park Run** ([[SPEED ARC - City Park]]): blue running loop round a lake, a fountain island (landmark), a stone bridge over the back straight, a city skyline, food carts, a gazebo, picnic blankets, ducks, hedges and railings at the edges. 4 stations: Park Loop, Hill Sprint, Bench Step-Ups, Bike Drafting.
- **Big Stadium** ([[SPEED ARC - Big Stadium]]): 8-lane oval, stands all round with 212 fans, giant scoreboard, 4 floodlight towers (the only 4 lights), a dark players' tunnel into the bright bowl, team tents, press box, camera crane, flags of made-up nations. 4 stations in the infield: Block Starts, Hurdles, Parachute Run, Bungee Sprint.
- **Each area** has its own race every 3 min (offset 0 / 60 / 120 s), music, lighting (park morning, stadium golden hour), leaderboard board and BACK TO HUB gate. Races in a lower league's area pay 25%.
- **Hurdles race** (League 3+): 8 hurdles across every lane, JUMP button with a timing ring (also J / Up key), a miss = x0.7 pace for 0.6 s and "CLIP!", never a stop. Rotates with Sprint and Lap Race. Sounds: jump whoosh, landing tap, knock.

## Tested
- Fresh test save at 1,950 MPH + 1 win -> trained past 2,000 -> Champion popup + GO PRO button -> confirm -> cutscene -> arrived in City Park: League 2, 0 MPH, x8 training, Bronze.
- Park race (Sprint) with NPCs: finished, coins paid, back on the spawn.
- League 3 save: walked through the Big Stadium gate -> teleported into the tunnel with the "BIG STADIUM" banner. Hurdles race: JUMP button and CLIP! on a miss work; coins paid.
- Rejoin on the Studio save: league 2, coins and speed kept. (Shoes and coaches are in the same save; their rejoin test was in prompt 2.)
- No errors in the output during any test.

## Numbers
| Area | Parts | Lights | Draw calls | Triangles |
|---|---|---|---|---|
| Hub (with Portal Plaza) | 739 | 0 | 53 | 145K |
| City Park | 292 | 0 | 47 | 48K |
| Big Stadium | 443 | 4 | 44 | 88K |

Budget is 3,000 parts and 20 lights per area. Each area is its own model with streaming on, far apart (x = 0 / 2000 / 4000), so only one loads around you.

## Pacing (bot sim, `Games/SpeedArc/tools/pacing_sim.py`)
The bot taps 4.5 a second, takes a 6 s break every 50 s, joins every race (30% wins), buys the next shoe when it can, rolls coaches with spare coins, Goes Pro right away. 60 runs averaged.

| League | Target | Before tuning | After tuning |
|---|---|---|---|
| 1 Hometown Track | ~15 min | 9.7 min | 15.5 min |
| 2 City Park Run | ~35 min | 19.1 min | 34.7 min |
| 3 Big Stadium | ~60 min | 31.4 min | 60.9 min |

Before tuning, speed was never the limit: the bot hit Champion in about 2 minutes and then just waited for race wins. So I kept the GDD gains per tap and the x8 per league, and raised the SPEED thresholds instead:
- Ranks L1: 1.5K / 5K / 14K / 28K. L2: 3M / 12M / 30M / 60M. L3: 1.75B / 7B / 17.5B / 35B.
- Station unlocks: Treadmill 550, Stair Run 2K; Hill Sprint 900K, Bench 3M, Bike 9M; Hurdles 520M, Parachute 1.75B, Bungee 5.2B.
- Race pace middles scaled the same way, so race lengths stay ~18 s / ~27 s.

## Changes / calls I made
- **Rank badge** sits under the coins, not next to them: next to them it hid behind the MPH plate.
- **Stadium light** is golden hour (clock 17.3). At 18.0 it was already dusk with the moon up.
- **Stadium spawn** is inside the tunnel, 30 studs from the BACK TO HUB gate, so you don't land in the gate.
- Leagues 4-5 rank numbers are placeholders (scaled like league 3); prompts 7 and 8 tune them.
- New Studio test switches: `TestLeague` (2 or 3), `TestLeagueWins`, `TestRaceNow` = an area id ("Park", "Stadium"), `TestRaceType` = "Hurdles", `TestOpenWindow` = "GoPro".
- Builders: `tools/builder_lib.luau` (shared helpers) + `build_park.luau` and `build_stadium.luau`. They use the existing kit meshes (trees, lamps, benches, arch, bleachers, starting blocks, v1 fans).

## Not done / later
- Phone-size screenshots: the Device Simulator was not on for this test, so these are desktop size. Prompt 6 does the full phone pass.
- The park and stadium "hero" pieces (fountain, gazebo, food carts, bridge, scoreboard, floodlight towers) are still part-built. A Blender kit for them is planned in prompt 6 (Look pass).
- No new .fbx files for this prompt. No images waiting for an OK.

## Screenshots
![[2026-10-28 p3 rank up.jpg]]
![[2026-10-28 p3 gopro confirm.jpg]]
![[2026-10-28 p3 gopro cutscene.jpg]]
![[2026-10-28 p3 portal plaza.jpg]]
![[2026-10-28 p3 park overview.jpg]]
![[2026-10-28 p3 park race.jpg]]
![[2026-10-28 p3 stadium overview.jpg]]
![[2026-10-28 p3 stadium inside.jpg]]
![[2026-10-28 p3 stadium tunnel arrive.jpg]]
![[2026-10-28 p3 hurdles race.jpg]]
