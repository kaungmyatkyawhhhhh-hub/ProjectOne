---
date: 2026-10-28
tags: [speedarc, progress]
prompt: "[[2026-10-28 SPEED ARC Prompt - 1 Project setup and core loop]]"
---
# Progress 1 - Project setup and core loop (M1)

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

## What's done
- **Setup:** [[CLAUDE|SPEED ARC CLAUDE.md]] (rules + performance + folders), code in the vault at `Games/SpeedArc/src` with a sync tool into Studio, all numbers in `Shared/Config`. See [[SPEED ARC - Code and Sync]].
- **Data saving:** session lock, autosave every 60 s, save on leave and on shutdown, migrations, Studio test save. See [[SPEED ARC - Player Data and Saving]].
- **UI kit:** black/carbon panels, electric blue, gold for coins and wins, Montserrat Heavy Italic + Builder Sans, chunky buttons with a press animation, coin/medal/speed icons drawn from shapes. See [[SPEED ARC - UI Kit and HUD]].
- **Hub (Hometown Track):** blue 6-lane oval with lane numbers, gold start/finish arch with countdown screens, bleachers with 115 fans that bob and cheer, school front with clock tower countdown, banners, waving flags, moving clouds, hills, trees, plaza with the SPEED ARC emblem. See [[SPEED ARC - Hub World]].
- **Training:** Sprint Lane (0 MPH, +1/tap), Treadmill (40 MPH, +3), Stair Run (150 MPH, +8). Tap anywhere, combo x1.0 to x1.5. See [[SPEED ARC - Training]].
- **Races:** every 3 min, 10 s gold JOIN window, 3-2-1-GO, Sprint (1 lap) and Lap Race (1.5 laps) taking turns, NPC runners fill to 4, BOOST, slipstream, live position bar, FINAL STRETCH, results card with medal and coins. See [[SPEED ARC - Races]].
- **Sound:** layered and pooled, with pitch variation. See [[SPEED ARC - Sound]].
- **Blender kit:** 13 props as .fbx in `Downloads\speed_arc_models\hub\` (with the script). See [[SPEED ARC - Hub World]].

## Test (as a new player, FreshPlayer)
- Spawn to first tap: about 15 s (with Studio's walk helper). Trained 0 to 48 MPH, Treadmill unlocked.
- Race 1 (Lap Race, 0 MPH): 38.3 s, 3rd of 4, +405 coins (first race of the day +50%), photo finish (38.2 / 38.3 / 38.3 / 38.3).
- Race 2 (Sprint): 25.7 s, 3rd, +270 coins, total 675, two bronze medals. Put back where I was after the race.
- On the phone size: won a Sprint in 14.0 s: 1st, gold medal, confetti, +675.
- Not joining: the race runs without you and you keep training.
- **Rejoin (Studio test save):** left at 131 MPH / 1,036 coins / 2 bronze / 1 silver; rejoined and got exactly the same.

## Performance
| What | Result |
|---|---|
| Hub parts | 878 (budget 3,000): Ground 94, Track 26, Training 119, Stands 38, School 91, Props 133, Life (flags + crowd) 376 |
| Lights | 0 (Neon only: 32 Neon parts) |
| Glass parts | 0 |
| SurfaceGuis | 11, all with MaxDistance |
| Draw calls | 43 total (24 for the world) |
| Triangles on screen | about 97,000 |
| CPU work per frame | about 1 ms |
| Studio FPS | 13-34 on this PC at quality 1, 2, 3 and automatic: **the same looking at the empty sky**, so Studio was the limit (it was waiting 86 ms a frame on the screen with two Studios open), not the game |
| Memory | 685-866 MB in Studio, but that number includes Studio itself. Needs a real phone (F9) |

Still to do: check FPS and memory on a real cheap phone (F9 Developer Console), and a 30-60 min server soak test.

## Changes from the plan (please check)
- **Race pace tuned:** BasePace 22, League 1 middle 80 MPH, low clamp -0.6 (GDD says -1) so brand-new runners aren't painfully slow. Sprint about 18 s and Lap Race about 27 s at 80 MPH; about 26 s / 38 s for a 0 MPH runner.
- **Lap Race = 1.5 laps** that start on the back straight in front of the stands, so the race still ends at the gold arch.
- **JOIN window 10 s** (this prompt) instead of the GDD's 15 s.
- **NPC speed** = the joined players' middle speed x 0.7-1.15, so races stay close.
- **Station names:** the prompt's "treadmill, sprint lane, stair run" with the GDD's numbers: Sprint Lane = GDD's Jog Lane (1/tap, 0 MPH), Treadmill (3, 40), Stair Run (8, 150). Sprint Sled (500 MPH) is not built yet.
- I didn't open the GYM ARC place (rule: never touch it). Data saving was rebuilt from the GYM ARC "Player Data and Saving" note instead.

## What I need from you
1. **Save:** in the SPEED ARC Studio, File > Save to Roblox, then File > Save to File as `SPEED ARC 2026-10-28.rbxl` (backup).
2. **Import the meshes** (when you have time): Studio > 3D Importer > pick a file in `Downloads\speed_arc_models\hub\`, keep "Scale unit: Stud", import as a model, put them in `ServerStorage/Meshes`. Then tell me and I'll swap them into the hub.
3. **Sounds:** the ids are in [[SPEED ARC - Sound]]. Listen in a play test and tell me any you don't like.
4. Test once on your phone and send me the F9 numbers.

## Known issues
- New players don't get an arrow to the Sprint Lane yet (that's the M4 tutorial).
- NPC runners are plain block avatars with name tags.
- The hub still uses smooth parts; the Blender props aren't imported yet.

## Screenshots (phone size: Samsung Galaxy A06)
![[2026-10-28 phone 1 hub.jpg]]
![[2026-10-28 phone 2 training.jpg]]
![[2026-10-28 phone 3 race start.jpg]]
![[2026-10-28 phone 4 race.jpg]]
![[2026-10-28 phone 5 finish.jpg]]

## Screenshots (PC)
![[2026-10-28 hub overview.jpg]]
![[2026-10-28 stands and crowd.jpg]]
![[2026-10-28 lap race start.jpg]]
![[2026-10-28 results card pc.jpg]]
![[2026-10-28 training pc.jpg]]
