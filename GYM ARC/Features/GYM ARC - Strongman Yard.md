---
date: 2026-10-27
tags: [gymarc, feature, world, strongman]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Strongman Yard

Prompt: [[2026-10-27 GYM ARC Prompt - 63 Strongman Yard]]. An outdoor yard behind the [[GYM ARC - Powerlifting Gym]], part of it (same unlock: Growth Spurt 5, no new gym in the ladder). Players lift big, awkward objects instead of machines.

## Place
- Behind the warehouse: x -174..-46, z -98..-160. Flat terrain under a `YardGround` part (dirt colour #7A6248, top y 0.05).
- Ways in: the warehouse **back door** (cut in Shell.BackBrick at x -168..-156) and the **street gate** `PowerliftingGym.YardGate` at the end of the side passage (z -98.6). The gate has the same UNLOCKS AT GROWTH SPURT 5 sign as the loading door and opens with it (PowerliftingClient DOORS = LoadingDoor, YardGate).
- Walls: old shipping containers + chain-link fences; the town boundary moved out round the yard (Boundary walls Back / West / East, attribute YardWall; the north wall shortened to x -45..200).
- Look: hand-painted STRONGMAN YARD sign on the back containers, a big scoreboard on the warehouse's back wall, 5 floodlights (NightLight tag, flash in a showdown), tire stacks, pallets, oil drums, chalk buckets, chains, a bench. Rubber mats under every station.
- Backups: 4 moved trees, the old terrain and the old north wall are in `ServerStorage.StrongmanSiteBackup_27Oct`.

## Stations (`Config/Machines.Strongman`, tag Machine, Gym = Powerlifting, the Powerlifting progression tiers with each object's own weights)
| Station | Where | Trains | How a rep looks |
|---|---|---|---|
| AtlasStone1-3 | x -158 / -149 / -140, platforms 3.0 / 3.8 / 4.6 high | back, legs, core | the stone goes floor to platform and back |
| LogPress1-2 | x -128 / -119 | shoulders, arms, chest | the log goes overhead (OverheadPress animation) |
| KegToss | x -104 | shoulders, legs, core | the keg flies over the high bar |
| YokeCarry | (-165, -126) | legs, core, back | carry the yoke down a 20-stud lane and back |
| FarmersWalk | (-136, -126) | forearms, back, core | carry two frames down the lane and back |
| TireFlip | (-106, -126) | legs, back, chest | the tire flips end over end down the lane, then resets |
| TruckPull1-2 | (-163, -139 / -149) | back, arms, legs | hand over hand, the pickup (original model) rolls closer, then resets |

- Carries ping-pong down the lane (LaneLength 20, LaneSteps 8); the tire and the truck go one way and reset every LaneSteps + 1 reps.
- Same tap / REP / EXP / tier rules as machines, with the Powerlifting gym bonus. Entry is locked below the first weight's level (like Powerlifting).
- Code: built by `ServerStorage._Builders.StrongmanStations`; animations in MachineClient (`YARD` helper table, POSE_ANIMS, followCFrame "Anim" reads `bars.animLoad`).

## Strongman Showdown (the yard's own feature)
- Every 15 minutes (`Config/Strongman.ShowdownEvery` 900) for 2 minutes (`ShowdownSeconds` 120), with a 15 s warning. The event rotates: TRUCK PULL (feet, 2.5 ft a rep) / ATLAS STONES (stones).
- Only players inside the yard get it: a toast, an air horn, the floodlights flash, a crowd cheer.
- The scoreboard shows the live top results and the time left; between rounds: the next event, its countdown and the last YARD KING.
- Rewards (`Economy.Rewards.Strongman` 8 / 5 / 3 minutes of coins for places 1-3, `StrongmanEnter` 1 for everyone who scored). First place adds `stats.yardWins`, which gives the **YARD KING** title ([[GYM ARC - Titles]]).
- Code: `ServerScriptService.Server.StrongmanService` (in Main OPTIONAL_SERVICES), `StarterPlayerScripts.StrongmanClient`.

## Hookups
- Guide entry `StrongmanYard` (spurts 5, place Tag:StrongmanYard) for GO TO / Coach Dex; `YardSpot` model tagged StrongmanYard at (-120, 0.15, -104).
- NPCs **Bruno** and **Magnus** (Gym = Strongman, GymGoerService gym "Strongman", yard machines only).
- Sounds: AirHorn 9114075649, StoneThud 9114036511, ChainRattle 9113763589, TruckCreak 9113969124 (+ RecordCheer). See [[GYM ARC - Music and Sounds]].
- PowerliftingService `IsInYard`; `IsInside` includes the yard (area music, lights).

## Studio test hooks
- Workspace `TestShowdown` = true starts a showdown now; `TestMachine` = "<station name>" puts you on a station ([[GYM ARC - Studio Test Hooks]]).

## Tested 27 Oct
- Every station entered and repped (AutoLift 8-16 s each): atlas stone to the platform, yoke and farmer's walk carried 17.5 studs with the body (hands on the load), tire flipped 18 studs, truck rolled 17.5 studs, keg over the bar, log pressed. The keg's arc was raised so it clears the bar.
- Showdown (truck pull): live scoreboard row, 1st place paid 2,600 coins, YARD KING granted, horn + flash.
- Street gate shows the lock sign (fixed: "GROWTH SPURT 5" was cut off), back door walkable.
- Not done yet: a 2-player showdown and a phone lag check with 8 players (needs a team test or a live server).

## Blender models (27 Oct, owner's request)
Atlas stone, yoke and farmer's frames modelled in Blender (with the town shrub, flowers and potted plant): see [[2026-10-27 GYM ARC Strongman Yard and Blender models]]. They replace the part-built props once imported.

## Screenshots
`Screenshots/test_2026-10-27`: sm_01_scoreboard, sm_02_street_gate_locked, sm_03_back_door, sm_04_yard_overview, sm_05_atlas_pr.

## Unlocks at ALTER 2 (27 Oct, prompt 66 part 4, owner: "make Strongman at Alter 2 requirement")
- The yard opens at **Alter 2 (Shredded)**, no longer with the Powerlifting Gym; the gym itself stays at Growth Spurt 5. `Config/Strongman.UnlockAlter` 2, `Strongman.Unlocked(data)`.
- Kept forever: StrongmanService sets `stats.yardUnlocked = 1` (through PlayerData) once a player is open, so a future Hall of Fame reset keeps it.
- Server: MachineService refuses the yard's stations before that (event `YardLocked`, the toast). Client: PowerliftingClient locks the street gate AND the gym's back door (new `YardDoor.Blocker` + a roll-down shutter with the lock sign); both signs read UNLOCKS AT ALTER 2. The toast: "STRONGMAN YARD · UNLOCKS AT ALTER 2" + "NEXT: SHREDDED 96%" (or "Grow to 7'0\", then BODY ALTER to get in").
- At Alter 2: a "STRONGMAN YARD UNLOCKED" reward popup (StrongmanClient, after the alter's title card) and the Coach Dex guide `StrongmanYard` (need `alter = 2`, new Guides condition) with GO TO.
- Players below Alter 2 can still see the yard, the showdown and the scoreboard through the fence / from the gym.
- Studio test hook: Workspace `TestYardLocked` = true locks the yard for everyone. Tested: locked -> back door and gate solid, walked into the shutter, station refused with YardLocked; unlocked -> station works, doors open again; the loading door stayed open throughout.
- Not done from prompt 66 yet: parts 1-3 (codes, Hall of Fame, profiles).

## New look (27 Oct, owner: "the lighting is bad and the quality looks like a cheap roblox game")
Builder `ServerStorage._Builders.StrongmanYardLook` (Run() rebuilds `StrongmanYard.Look`, ~630 parts, no collisions / shadows). Backup of the yard before: `ServerStorage.StrongmanYardBackup_27Oct_look` (plus its terrain).
- Floor: the slab darker (#6E5A44 Ground) with soft round Mud patches, Pebble gravel under every station, a Concrete walk with a yellow edge along the warehouse. Station mats get yellow edges. (Terrain was tried first: its 4-stud voxels buried the mats and stones, undone.)
- Containers keep their colours, with a rusted bottom band, rust streaks and stencils (GAX numbers). Chalk buckets dark, with a little chalk dust.
- Lights (all NightLight: off by day, on at night, no shadows): two steel truss towers with 4 floodlights each by the scoreboard, 7 wall lamps; plus the old floodlights. (The string lights were removed by the owner in Studio on 27 Oct; the builder no longer adds them.)
- Event corner: aluminium bleachers, a red STRONGMAN YARD tent with a table, cooler, towels and bottles, sandbags, a kettlebell row, and two lit wall banners ("STRONGMAN SHOWDOWN · EVERY 15 MINUTES", "LIFT HEAVY").
- Shots: `yard_look_before.jpg`, `yard_look_after_day.jpg`, `yard_look_after_night.jpg`, `yard_look_after_night2.jpg`, `yard_backdoor_alter2.jpg`.
