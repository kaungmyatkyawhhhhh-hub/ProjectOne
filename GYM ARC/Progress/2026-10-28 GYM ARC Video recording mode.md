---
date: 2026-10-28
tags: [gymarc, video, progress]
---
# GYM ARC Video recording mode (prompt 89, 28 Oct)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Prompt: [[2026-10-28 GYM ARC Prompt - 89 Video recording mode]]

A Studio-only mode for recording the game page video from real gameplay. It only runs in a Studio play test with the Workspace attribute **RecordingMode** ticked; the live game never runs it (both scripts check `RunService:IsStudio()`).

## What it does
- **Showcase save** (temporary, never saved, the real save is never loaded): 7'0", the Gold alter, the Golden aura, 5M coins, a Hall of Fame star (your statue stands on the Hall's stage), Volta (Legendary, BEAST-MODE) following. Earned auras and unlock guides are marked seen, so no popups.
- The Hall of Fame counts as already open (no launch cutscene, no NEW popup), so shot 6 can be filmed before Saturday.
- The normal HUD stays (it's real gameplay). A small panel top-left lists the keys; it hides itself while a shot runs (H hides it any time).
- Keys: **1-6** go to a shot and set it up; **R** films it.

| Key | Shot | R does |
|---|---|---|
| 1 | Bench press, Pro Gym (Pro Flat Bench) | a smooth 6 s camera move round you (press E first to get on the bench, tap to lift) |
| 2 | Growth Spurt (middle of the Pro Gym, one spurt to go) | the real Growth Spurt transformation (5'8" → 7'0") |
| 3 | Trainer roll at the Trainer Agency | a roll that is a Legendary Volta (the real reveal), then press CLOSE |
| 4 | Body Alter (middle of the Pro Gym, Chrome worn) | the real alter cutscene → ALTER 15: GOLD |
| 5 | Strongman Yard atlas stone | a 6 s camera sweep from the open yard side (press E first, lift) |
| 6 | Hall of Fame | the camera rises from the plaza to the HALL OF FAME sign, your statue inside |

The camera moves: Camera.Focus every frame, no shake, FOV 55, they stop in front of walls. R again gives the normal camera back.

Files: `ServerScriptService.Server.RecordingService`, `StarterPlayerScripts.RecordingClient`, `PlayerData.ShowcaseData / Showcase`.

## Tested (Studio, 1 player)
All 6 shots set up and played; no errors from the game's scripts (two Roblox-side messages: an Avatar Editor core script and a DataStore server blip). First frames:
![[GYM ARC/Screenshots/recording89/1_bench_press.jpg]]
![[GYM ARC/Screenshots/recording89/2_growth_spurt.jpg]]
![[GYM ARC/Screenshots/recording89/3_trainer_roll.jpg]]
![[GYM ARC/Screenshots/recording89/4_body_alter_gold.jpg]]
![[GYM ARC/Screenshots/recording89/5_strongman_yard.jpg]]
![[GYM ARC/Screenshots/recording89/6_hall_of_fame.jpg]]

## How to record (owner)
1. In Studio: Explorer > Workspace > Properties > Attributes: tick **RecordingMode**.
2. File > Studio Settings > Rendering > Editor Quality Level = **Level 21** (highest). In Studio's top-right, maximise the game view (or Test > Device: 1920 x 1080).
3. Press **Play** (not Run). Press PLAY on the menu, close the trainer card.
4. Start recording: **Win + Alt + R** (Windows Game Bar; Studio must be the focused window). Saved in `C:\Users\kaung\Videos\Captures`.
5. Press **1**, wait 3 s, then do the shot (E on a machine for 1 and 5), press **R**, wait for it to end. Then 2, 3, 4, 5, 6 the same way. You can record one long clip or one per shot.
6. Win + Alt + R again to stop. Stop the Studio test. Untick RecordingMode before your normal tests.
7. Send the clips to Claude to cut into one 15-30 s video (best moment first, game sound only, no text or voice).
