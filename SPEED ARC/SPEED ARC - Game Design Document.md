---
date: 2026-10-28
tags: [speedarc, design, gdd]
status: living document (v1)
---
# SPEED ARC - Game Design Document (v1)

Back to [[00 SPEED ARC Home|SPEED ARC Home]] · Short version: [[SPEED ARC - Design plan]] · Lessons: [[SPEED ARC - Lessons from GYM ARC]]

> **28 Oct PIVOT (owner): "+1 SPEED every step".** Tap training is gone: every step you run = +SPEED, you smash walls on a wall course for coins, the last wall = Go Pro, treadmills are AFK step machines, races stay as an event every 3 min, bright candy colours. Where this document still talks about tapping, stations per tap or the dark palette, [[SPEED ARC - Wall Course and Steps]] and CLAUDE.md win. Everything else (leagues, shoes, coaches, trails, economy, monetization rules, Legend Laps) still applies.

All numbers here are STARTING values. They live in Config and get tuned with a pacing sim (like GYM ARC's `tests/pacing`). If this document and a prompt disagree, the newest owner decision wins; update this document.

---

## 0. Contents
1. Vision and pillars
2. Audience and devices
3. Art direction
4. The world (areas, layouts)
5. Core loop (minute by minute)
6. Stats and formulas
7. Training
8. Races
9. Leagues, ranks and Go Pro
10. Endless loop: Legend Laps
11. Shoes
12. Coaches
13. Trails
14. Titles, medals and profile
15. Quests, daily and playtime
16. Events
17. Leaderboards
18. Social
19. Economy (coins in and out)
20. Monetization
21. First 15 minutes (tutorial, minute by minute)
22. UI screens
23. Audio
24. Performance budget
25. Tech architecture
26. Analytics
27. Milestones and order of work
28. Open decisions

---

## 1. Vision and pillars
**One line:** start as the slowest kid on the school track, train and race until you win the World Games.
**Tagline:** "Everyone starts slow."

**Pillars (every feature must serve at least one):**
1. **Feel fast.** Speed must be FELT: camera FOV widens, wind lines, footstep rhythm speeds up, trails grow. Getting faster is visible every few minutes.
2. **Race together.** Every few minutes everyone on the server races. Short, loud, fair, fun to lose too.
3. **Always a next goal.** The next rank, the next shoes, the next league, the next coach are always on screen.
4. **Light and polished.** 60 FPS on cheap phones, but looks premium (stylized low-poly, clean UI).

**Not this game:** no combat, no realistic bodies, no stamina walls that stop play, no pay-to-win racing (Robux never wins a race by itself; coaches/shoes are earnable).

## 2. Audience and devices
- Roblox players 8-14, mostly phones (target ~70% mobile), short sessions (10-25 min), come back daily.
- Must work on low-end Android: 60 FPS goal, 30 FPS floor at graphics quality 1.
- Controls: one-thumb play. Training = tap. Races = auto-run + tap to BOOST. Desktop: click / Space.

## 3. Art direction
(Full rules: ART QUALITY RULES in the design plan.)
- **Style:** stylized low-poly cartoon sports. Chunky bevelled shapes, strong silhouettes, flat colours with baked soft shading (vertex colours), no realistic textures.
- **Palette (owner, 28 Oct: BLACK + BLUE + GOLD, "that's what speed looks like"; Config/Palette):**
  - Speed Black #0B0D12 (UI base, night skies), Carbon #171A22 (panels), Graphite #2A2F3A (borders)
  - Electric Blue #1E7BFF (main accent, speed, buttons), Bright Blue #4FC3FF (glows, highlights), Deep Blue #0E3A8A (shadows/gradients)
  - Gold #FFC83D (coins, rewards, winners, premium), Deep Gold #E09A12 (gold gradients)
  - White #F4F6FA (text), Danger Red #FF4A4A (only for warnings/timers)
  - Tracks are BLUE (real modern tracks are), lane lines white, start/finish gold. World greens/skies stay natural but cool-tinted.
  - Each league keeps an accent inside this palette (see 9).
- **Fonts:** one heavy display font (titles, numbers, buttons, italic for speed feel), one clean sans for body text. Minimum text size = the smallest HUD label.
- **Speed language:** slanted shapes, speed lines, motion blur streaks in UI and VFX. Numbers tick up fast.
- **Characters:** normal Roblox avatars (no live meshes). Progress shows through SHOES (on the feet), TRAILS, a speed aura at high speed, titles and medals.
- **World life (cheap):** waving flags (cloth via bones or animated texture), crowds as low-poly billboard groups that bob and cheer, moving clouds, birds (small looping meshes), confetti on wins.
- **Lighting per area:** tuned sky, Atmosphere, ColorCorrection, light Bloom; Neon for glow; 1 sun; max ~20 small lights per area, no shadows from props.

## 4. The world
Small separate areas linked by teleports (no giant open map). Each area streams on its own.

### 4.1 Areas
| Area | What's there | Size target |
|---|---|---|
| **Hub: Hometown Track** | Spawn, School Track League 1 (training + race track), Coach Corner (coach rolls), Shoe Shop, Trail Booth, Daily board, Leaderboard wall, Portal Plaza (teleports to leagues), Legend Wall (top players) | ~250 x 250 studs, < 3,000 parts |
| **League 2: City Park Run** | Park paths, fountain, training spots, a looping park race route | ~300 x 300 |
| **League 3: Big Stadium** | A real stadium oval (8 lanes), stands with crowd, scoreboard, hurdles training | ~300 x 300 |
| **League 4: Mountain Trail** | Dirt trail with switchbacks, wooden bridges, pine trees, uphill training | ~300 x 350 |
| **League 5: World Games** | Night stadium, flags of made-up countries, fireworks, gold podium | ~300 x 300 |
| **Legend Track** (endless) | Floating track in the clouds, unlocked by Legend Laps | ~250 x 250 |

### 4.2 Hub layout (Hometown Track)
- **Spawn** on the school steps, facing the track. The first training spot (Jog Lane) is 15 studs ahead with a glowing arrow.
- **Track** in the middle: 6-lane oval, painted lanes and numbers, start/finish arch with a big countdown screen.
- **Left side:** Shoe Shop (small sports store front), Trail Booth (neon booth), Coach Corner (bench + clipboard board with coach cards).
- **Right side:** bleachers with crowd, Daily Board, Leaderboard Wall, Codes sign.
- **Back:** Portal Plaza with 5 league gates (locked ones show their requirement).
- Every spot reachable in < 10 s of walking; GO TO buttons teleport.

## 5. Core loop
(Rewritten 28 Oct, prompt 11: the "+1 SPEED every step" game. See [[SPEED ARC - Wall Course and Steps]].)
**Every second:** every step you run = +1 SPEED (times your boosts), a "+N" popup and a soft tick.
**Every 1-2 minutes:** smash the next wall on the wall course: coins, and every later step is worth more.
**Every 3 minutes:** a race event (JOIN, ~30 s run, coins and medals).
**Every 5-10 minutes:** a new rank, new shoes, a coach roll at the COACH AGENCY.
**Every 15-60 minutes:** smash your league's last wall = Go Pro to the next world (new course, new music, new races).
**Every day:** daily streak, quests, playtime gifts, the weekly board.
**Forever:** collection (coaches, trails, shoes), weekly events, later leagues.

## 6. Stats and formulas
### 6.1 Stats
- **SPEED** (the main stat). Grows with every step. Resets on Go Pro.
- **Coins.** From walls (main), races, steps (small), quests, gifts.
- **Walls smashed** per league (best ever, saved). **Medals** (lifetime). **League**.

### 6.2 SPEED per step
- **One step** = 3 studs of running on the ground (the server measures it; teleports, races, anchored players and more than 12 steps a second don't count).
- **Per step** = league base (1 / 40 / 900) x 8^(league-1) x shoes x coaches x trail x passes x session boosts (New Runner, gift, friends) x **1.25 per wall smashed in your league**.
- **AFK machines** (treadmills in the hub, the stations in Park / Stadium): 1.6 steps a second x the machine's Mult; the Auto Run pass makes it x2.4, still slower than running (~5 steps a second).
- Wall needs and ranks are tuned by `tools/step_pacing_sim.py` (numbers in Config/Course `Walls`; ranks sit on walls 4 / 6 / 8 / 10).

### 6.3 Walking speed in the hub/areas
- WalkSpeed = 16 + 6 x log10(1 + MPH / 10), capped at 30 (config). You feel faster but stay controllable.
- Camera FOV 70 -> 80 with walk speed; light wind lines past 24.

### 6.4 Race pace
- Every race track has a fixed length L (studs) and a target time of ~30 s.
- Each runner's pace (studs/s) = basePace(league) x (1 + 0.6 x clamp(log2(speed / leagueMid), -1, 1.5)), so a player 2x faster than the league middle is clearly faster, but nobody is 10x faster (still a race).
- **BOOST:** tap during the race = +25% pace for 0.8 s; a boost bar holds 3 charges, refills 1 per 2.5 s. Smart tapping matters, spam doesn't.
- Slipstream: within 6 studs behind someone = +5% pace (keeps races close and exciting).
- Finish: places by time; ties by distance.

## 7. The wall course and AFK machines
- One long straight course per world, 10 stages of 90 studs, each stage its own candy colour; a wall at the end of each. The wall shows WALL k, the SPEED it needs, and for your next wall "214 / 420 - about 40 more steps" with a bar; cracks from 70%, glowing edges and SMASH IT! when you have enough.
- **Smash:** chunky pieces, a camera kick and FOV punch, crack + boom + crowd sound, coins fly to the counter (x3 the first time ever). **Too slow:** a soft bounce.
- Walls go in order; back behind the start (or a respawn) = a new run, every wall stands again. After the last wall: a gold finish stage, then back to the start.
- A strip under the SPEED panel shows walls 1-10 (passed ones filled, the best one gold) while you're on the course.
- **AFK machines** step for you (see 6.2). There's no tapping any more.

## 8. Races
### 8.1 Schedule
- Each league area has its own race every **3 minutes** (config), offset so the server doesn't run all at once.
- **Join window 15 s:** a gold JOIN button pops on the HUD (and a ring on the start line). Players who don't join keep training; no penalty.
- Max 8 runners. If fewer than 4 players join, **NPC runners** fill to 4 (named original characters, speeds set around the league middle so they're beatable but not free).
- Countdown 3-2-1-GO with a starting gun sound; false start = no penalty (just starts on GO).

### 8.2 During the race
- Auto-run along the lane; the player only taps BOOST (big round button bottom right, 3 charge pips).
- Camera: low side-follow, FOV kick on boost, wind lines; other runners visible with their trails.
- Live **position bar** at the top (runner heads on a line), "1ST" place tag next to you.
- Crowd cheers rise when someone overtakes; last 20% = "FINAL STRETCH" text + music swell.

### 8.3 Results
- Podium moment: top 3 on a podium for 3 s (medals, confetti), everyone else gets their place card.
- Rewards (coins = minutes of coins at your league, see 19): 1st 6 min, 2nd 4 min, 3rd 3 min, finish 1.5 min. First race of the day: +50%.
- Medal counts saved (gold/silver/bronze). New personal best time = "NEW PB!" banner (once per race).
- Back where you were before the race (teleport back to your station if you were training).

### 8.4 Race types (unlock over time, rotate)
| Type | League | What's different |
|---|---|---|
| Sprint | 1+ | Straight 100 m-style, ~20 s |
| Lap Race | 1+ | One oval lap, ~30 s |
| Hurdles | 3+ | Tap JUMP on hurdles (timing ring), a miss = small slowdown |
| Trail Run | 4+ | Uphill/downhill sections change pace |
| Relay | Event | Teams of 2-4, baton handoff zones |
| Final | 5 | The big one: longer, fireworks, bigger rewards, every 10 min |

## 9. Leagues, ranks and Go Pro
### 9.1 Leagues
| League | Area | Accent | Speed range (MPH) | Ranks | Go Pro goal |
|---|---|---|---|---|---|
| 1 | School Track | Electric Blue | 0 - 53K | Bronze, Silver, Gold, Platinum, Champion | smash the last wall (since prompt 11, every league) |
| 2 | City Park Run | Bright Blue + green | 0 - 200K | same | Champion + win 2 races |
| 3 | Big Stadium | Deep Blue + white | 0 - 10M | same | Champion + win 3 races |
| 4 | Mountain Trail | Blue + pine | 0 - 500M | same | Champion + win 3 races |
| 5 | World Games | Gold | 0 - 20B | same | Champion = "WORLD CHAMPION" -> Legend Laps unlock |

- **Ranks** are SPEED thresholds inside a league (e.g. League 1: Bronze 0, Silver 100, Gold 400, Platinum 1K, Champion 2K). Rank up = popup, sound, small coin reward, rank badge next to your name.
- Races put you against players in the same league (race in your league's area). A player can visit lower league areas (to hang with friends) but races there give reduced rewards.

### 9.2 Go Pro (rebirth)
- When the Go Pro goal is met: big gold "GO PRO" button + Coach line. Confirm screen shows **YOU KEEP / YOU RESET / YOU GET** (GYM ARC Hall of Fame lesson).
- **Resets:** SPEED to 0, ranks.
- **Keeps:** coins, shoes, coaches, trails, titles, medals, passes, everything bought.
- **Gets:** the next league area (teleport + intro cutscene), its training stations and races, a permanent **League multiplier** (x8 per league, config) on training gains, a free coach roll, the league's title.
- Target times (first run, normal player): League 1 ~15 min, League 2 ~35 min, League 3 ~60 min, League 4 ~90 min, League 5 ~2 h. Total ~5 h to World Champion.

## 10. Endless loop: Legend Laps
- After World Champion: **LEGEND LAP** (like GYM ARC's Hall of Fame). Back to League 1 with SPEED 0, keep everything, get a **Legend star** (★).
- Each star: +50% training gains, start with League 2 already unlocked from ★2, League 3 from ★4; stars shown over your head; Legend Wall top 3 statues (fixed slots, own statue local only).
- Run time targets: ~5 h, then ~2.5 h, ~1.5 h, never under ~1 h.
- **Legend Track** (cloud area) unlocks at ★1: its own races vs other legends, Legend-only trails.
- Gyms-style rule: areas stay unlocked after a Legend Lap; race matchmaking uses your current league.

## 11. Shoes
- Bought with coins at the Shoe Shop, owned forever, one pair worn (shows on the feet as a simple mesh + colour).
- Each pair: a training multiplier + a small race pace bonus (+1-5%).

| # | Shoes | Training x | Race pace | Price | Unlocks |
|---|---|---|---|---|---|
| 1 | Worn Sneakers | x1.0 | +0% | free | start |
| 2 | Canvas Runners | x1.3 | +1% | 250 | L1 |
| 3 | Track Trainers | x1.7 | +1% | 1,500 | L1 Silver |
| 4 | Light Racers | x2.3 | +2% | 8K | L1 Gold |
| 5 | Park Pacers | x3.2 | +2% | 60K | L2 |
| 6 | Spike Shoes | x4.5 | +3% | 400K | L3 |
| 7 | Trail Grippers | x6.5 | +3% | 3M | L4 |
| 8 | Carbon Flyers | x9.5 | +4% | 25M | L5 |
| 9 | Golden Wings | x14 | +5% | 200M | World Champion |
| 10+ | Legend shoes | cosmetic + small x | | stars | Legend Laps |
- Shoe Shop UI: a row of shoes on a rotating pedestal, locked ones as silhouettes with "UNLOCKS AT ..."; try-on preview on your character.

## 12. Coaches (like GYM ARC trainers, lighter)
- Rolled at **Coach Corner** with coins (price = ~1.5 min of coins at your league, min 50). Follow you (1 shown by default; others as portrait chips), give boosts, evolve with 3 duplicates (BASE -> PRO -> ELITE -> LEGEND, 4 stages).
- Slots: 2 free, +1 pass, +1 second pass.
- Pity: guarantees by stage (Rare at 30, Epic 80, Legendary 150...).
- Roll reveal: name roller + small cutscene for Legendary+ (GYM ARC lesson: themed per coach).

Owner, 28 Oct: coaches are INSPIRED BY famous kinds of runners, never copies. Rule: no real names, no real faces/likeness, no signature poses or nicknames that point to one real person (Roblox rules on real people + their rights). Each coach = an original character built from a running archetype.

| Coach | Inspired by (archetype only) | Rarity | Chance | Boost (BASE) |
|---|---|---|---|---|
| **Coach Benji** | the school PE teacher with a whistle | Common | 40% | +5% training |
| **Rae Miles** | the city marathon runner, headband + water bottle | Uncommon | 28% | +8% coins |
| **Ivo Dash** | the old-school sprint coach, stopwatch + clipboard | Rare | 18% | +12% training |
| **Mara Leap** | the hurdles champion, long braid, big stride | Epic | 9.5% | +20% training, +10% coins |
| **Zephyr Reign** | the showman 100 m world-record sprinter: tall, relaxed, fastest ever | Legendary | 3.5% | +35% training, +3% race pace |
| **Kai Highland** | the highland distance legend who ran a marathon barefoot | Mythic | 0.8% | +50% training, +5% race pace |
| **The Flying Ghost** | the 1920s distance legend in vintage kit, pocket watch | Secret | 0.17% | +65% training, +6% pace |
| **Mercury** | the winged-sandals god of speed (myth) | Secret+ | 0.03% | +80% training, +8% pace, golden trail |
- Each coach gets an ORIGINAL signature pose and outfit in the palette (e.g. Zephyr: wind-swoosh arm pose; Kai: hands on knees then sunrise stretch). Themed roll cutscenes for Legendary+ (Zephyr = storm wind tunnel, Kai = sunrise over highlands, Flying Ghost = old film-grain race, Mercury = golden sky temple).

- Total coach boost caps: training +300%, race pace +15% (keeps races fair).

## 13. Trails
- The effect behind you when you run (walk faster than 22 or in races). Cheap: one Trail instance or a short beam strip + a few particles.
- Sources: Trail Booth (coins), quests, events, passes (Trail Pack), Legend Laps.
- Each trail: look + small bonus (+2-10% coins OR training), one equipped.

| Trail | Source | Bonus |
|---|---|---|
| Dust | start | - |
| Chalk Lines | 2K coins | +2% coins |
| Leaf Swirl (L2) | 40K | +3% training |
| Fire Streak | 300K | +5% training |
| Ice Streak | 300K | +5% coins |
| Lightning | Trail Pack | +6% training |
| Rainbow | Trail Pack | +6% coins |
| Comet (L5) | 50M | +8% training |
| Star Dust | ★1 | +10% coins |
| Event trails | events | cosmetic + small |

## 14. Titles, medals and profile
- Titles: First Race, First Win, 10/100/1000 Wins, Rank titles per league ("PARK CHAMPION"), WORLD CHAMPION, LEGEND, event titles, PB titles. Shown over the head in its style.
- Medals shown on the profile and as a small count next to the name.
- Profile (tap a player -> quick menu: VIEW PROFILE / RACE THEM / ADD FRIEND): stars, title, league + rank, top speed, best race times per league, medals, coaches, trails, playtime.

## 15. Quests, daily and playtime
- **Daily quests (3/day):** "Win 1 race", "Train 300 taps", "Get a new PB", "Race 5 times"... reward 3 min of coins each, all 3 = 10 min + 1 coach roll. Unclaimed ones pay before reset.
- **Daily streak (7 days):** coins, a coach roll on day 4, a trail on day 7 (first time). One missed day allowed.
- **Playtime gifts:** 3/8/15/25/40/60 min: coins, boosts, a coach roll last.
- **Codes:** in Settings + a CODES button (DataStore list, admin console commands).

## 16. Events (rotate weekly, run themselves)
- **Relay Weekend:** relay races with friends, team rewards.
- **Hurdle Week:** hurdle races everywhere, Hurdle trail.
- **Double Coins Weekend.**
- **Seasonal:** Halloween Night Run (fog, pumpkin trail), Winter Snow Dash (snow track, sled race), Summer Beach Sprint.
- Event-only titles/trails never come back (collection value).

## 17. Leaderboards
- In the hub (Leaderboard Wall) + a panel: Top SPEED, Most Wins, Fastest Lap per league, Legend Stars. Top 25 scrollable.
- **Weekly boards** reset Monday: Most Wins This Week, Best Time This Week -> top 3 get a title + coins.
- Versioned store prefix so boards can be reset (lesson).

## 18. Social
- Friend Boost: +10% training per friend in server (max +30%).
- Invite: invite button, +10% for 30 min when a friend joins from your invite.
- Race challenges: "RACE THEM" from a profile = a private 1v1 sprint (no rewards farming: coins only first 3 a day).
- Crews (later milestone): crew tag, crew weekly wins board.

## 19. Economy
### 19.1 Coins per minute (base, active play, by league; tune with sim)
| League | Coins/min |
|---|---|
| 1 | 60 |
| 2 | 400 |
| 3 | 3K |
| 4 | 25K |
| 5 | 200K |
- Every reward = "minutes of coins at your league" (lesson), never fixed numbers that become worthless.
- Coin sources split (target): races 55%, training taps 20%, quests/daily/gifts 20%, other 5%.

### 19.2 Coin sinks
- Shoes (main, one-time per pair), coach rolls (repeatable, the main sink), trails, boost upgrades (later), cosmetic name colours (later).
- Coin multipliers capped at x8 total (lesson).

## 20. Monetization (fair, kids' game)
### 20.1 Game passes
| Pass | Price (suggested) | What |
|---|---|---|
| Auto Train | 249 R$ | Trains for you on a station (hero item) |
| 2x Speed | 249 | x2 training gains |
| 2x Coins | 149 | x2 coins |
| VIP | 299 | +10% coins, VIP tag, VIP trail, VIP chat colour |
| Extra Coach Slot | 99 | +1 slot |
| Extra Coach Slot 2 | 149 | +1 more |
| Trail Pack | 199 | Lightning + Rainbow + 2 more trails |
| Faster Rolls | 99 | skip roll animation, x3 roll button |

### 20.2 Developer products
- Coins (scale with league): Small 25 R$ = 20 min, Medium 99 = 2 h, Large 249 = 6 h.
- Boosts: 2x Speed 15 min (25 R$). Never sold: paid luck on rolls, or anything that helps you win a race directly.
- Starter Pack (49-79 R$, once): coins (60 min), 2x Speed 30 min, Canvas Runners skin, STARTER title.
### 20.3 Rules
- Robux never decides a race. No paid random rewards. No fake timers. Offers only at calm moments (after a race, never in one), max one small card per 10 min, none in the tutorial.
- Prices in-game match Roblox's (lesson).

## 21. First 15 minutes (minute by minute)
(Rewritten 28 Oct, prompt 11. Times from the pacing sim and a FreshPlayer test.)
| Time | What happens | Why |
|---|---|---|
| 0:00 | Loading screen, main menu: PLAY. | no freezes later |
| 0:03 | Spawn on the plaza facing the wall course. Coach Benji: "Every step = +1 SPEED. Let's go!" NEW RUNNER BOOST 2x for 15 min. | instant reward |
| 0:05 | "Walk! Every step gives you SPEED." First step: +10 SPEED, +100 coins (test: 4.7 s after PLAY). | first action in < 15 s |
| 0:35 | WALL 1 smashed (test: 34 s): pieces, coins, the strip fills. | the core moment, early |
| 0:40 | "A RACE IS STARTING!" (a small card top right). Tutorial race vs 3 slow NPCs, a close win. | the race event |
| 1:40 | Podium, then "Buy your first shoes!" (GO TO the Shoe Shop). | win + spend |
| 2:00 | Wall 2. | rhythm |
| 4:30 | SILVER rank (wall 4): a free coach roll at the COACH AGENCY. | collection hook |
| 6-8 | Wall 5, Track Trainers, races every 3 min, quests, gifts. | rhythm |
| ~15 | The last wall: GO PRO -> City Park Run. | the "I'll come back" moment |
- The tutorial can't be skipped in the first 60 s; hints never vanish while needed; nothing stacks on a hint; no shop push before minute 5.

## 22. UI screens
- **HUD:** top bar = coins, league + rank badge, MPH big in the middle-top with a speed bar to the next rank; right = race timer pill (JOIN when open); bottom right = TRAIN/BOOST button; left = menu (SHOP, SHOES, COACHES, TRAILS, QUESTS, PROFILE); top centre = one toast lane.
- **Windows:** Shoes, Coaches (inventory + detail + evolve), Coach Corner roll screen, Trails, Quests (Daily / Streak / Weekly), Store (Passes / Coins / Boosts), Settings, Profile, Codes, Go Pro confirm, Legend Lap confirm, Race results.
- Layout rule: nothing in the middle of the screen except race moments; one toast at a time; everything fits 667x375 without overlap.

## 23. Audio
- Music per area (upbeat electronic/sports; owner picks IDs): hub chill-hype, park sunny, stadium big drums, mountain adventurous, World Games epic. Race music separate with a final-stretch swell.
- SFX: taps (pitch rises with combo), footsteps by surface, whoosh on boost, starting gun, crowd cheer layers, rank up, coins, roll reveal, podium fanfare.
- Mix: music ducks during races' countdown; nothing ear-piercing; settings sliders.

## 24. Performance budget
| Thing | Budget |
|---|---|
| FPS | 60 target, 30 floor at quality 1 |
| Parts per area | < 3,000 (meshes merged) |
| Lights per area | < 20, only your area on |
| Particles on screen | < 300 total, own trail full, others' simplified |
| Runners drawn | all 8 in a race; outside races others beyond 120 studs hidden |
| SurfaceGuis | MaxDistance always set |
| Client memory | < 600 MB on phones |
| Server memory | flat in a 60 min soak test |
| Per-frame scripts | only active things; no per-tap Instance creation without pooling |

## 25. Tech architecture
- Folders: `Shared/Config/*` (all numbers), `Shared/UIKit`, `Server/*Service`, `Client/*Controller`.
- Services: PlayerData (session lock, autosave, migrations), TrainingService, RaceService (one per area, server authoritative timing and positions; clients only send BOOST taps, rate limited), LeagueService (ranks, Go Pro, Legend), ShopService (shoes, trails), CoachService (rolls, pity, evolve), RewardService (minutes-of-coins), QuestService, DailyService, PlaytimeService, CodesService, MonetizationService (receipts), LeaderboardService, AnalyticsService, AdminConsole.
- Anti-cheat: server checks tap rate (max ~12/s counted), race positions computed on the server, coins only granted by the server.
- Reuse from GYM ARC by copying + adapting (never editing GYM ARC).

## 26. Analytics (funnel steps)
01 loaded, 02 menu PLAY, 03 first tap, 04 first race joined, 05 first race finished, 06 first shoes, 07 first coach roll, 08 Silver, 09 Gold, 10 Go Pro 1, 11 day-2 return, 12 Go Pro 2. Plus offers shown/tapped/bought, race joins vs skips, average races per session.

## 27. Milestones and order of work
1. **M1 Core:** setup, data, UI kit, hub look, Jog Lane + Treadmill, SPEED, coins, races (Sprint + Lap) with NPCs, results. Quality + FPS check.
2. **M2 Collect:** shoes shop, coaches (rolls, reveal, follow, evolve), trails.
3. **M3 Leagues:** ranks, Go Pro, League 2 + 3 areas, Hurdles race.
4. **M4 Retention:** tutorial (section 21), daily, quests, playtime, codes, leaderboards, profile, friend/invite boosts.
5. **M5 Money:** passes, products, Starter Pack, store, offers.
6. **M6 Polish + soft launch:** pacing sim, phone tests, funnel, fix the first 15 min.
7. **M7 Leagues 4-5, Legend Laps, events.**

## 28. Decisions (owner, 28 Oct)
- Name: **SPEED ARC** (final).
- Colours: **black + blue + gold** (section 3).
- Coaches: inspired by real runner archetypes, original characters (section 12).
- Races: every **3 minutes**.
- Tap combo: **yes**, as in 6.2 (x1.0 -> x1.5 over 10 s of steady tapping; Auto Train gets a fixed x1.2) - Claude's call, keep unless playtests say otherwise.
- Prices: as in section 20 - Claude's call, tune after launch data.
- M1 tuning (prompt 1, 28 Oct): JOIN window **10 s**; race pace BasePace 22, League 1 middle 80 MPH, low clamp -0.6 (not -1) so new runners aren't too slow; **Lap Race = 1.5 laps** starting on the back straight (~27 s at 80 MPH), Sprint = 1 lap (~18 s); races stop at 45 s and the rest are placed by distance; NPC speed = joined players' middle x 0.7-1.15. Station 1 is called **Sprint Lane** (the GDD's Jog Lane numbers). See [[SPEED ARC - Races]].

## 29. Detail plans
- [[SPEED ARC - World, Map and Buildings]]
- [[SPEED ARC - Lighting]]
- [[SPEED ARC - Audio (SFX and Music)]]
- [[SPEED ARC - VFX]]
- [[SPEED ARC - Customization]]
- [[SPEED ARC - Update Roadmap]]
