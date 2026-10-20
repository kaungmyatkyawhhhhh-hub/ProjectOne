---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Studio Test Hooks

Back to [[00 GYM ARC Home|GYM ARC Home]].

Workspace attributes that change how the game behaves in a Studio play test, for testing and screenshots. They do nothing in the live game.

## How it works
- **Player state:**
  - `FreshPlayer` (true): play as a new player on temporary data (never touches the real save)
  - `ReplayTutorial`: replay the tutorial on your own save
  - `TestCoins`, `TestSpurts`: set coins / Growth Spurts
  - `TestMuscleShare` (0..6 x the goal, live; 2 = full look, 5 = mass monster), `TestMuscleIds` (only some muscles, for example "Biceps,Triceps" or "Abs=0.7,Lats=2")
  - `TestMuscleExp` (without FreshPlayer): every muscle at that EXP on your own save, saving off
- **Genetics:** `TestGenetics` / `TestRerollGenetics` ("C,B,A,S,S,D" or with a frame), `TestGeneticsHold` (freeze the reveal at plate n)
- **Machines and feel:** `TestMachine` (puts you on a machine, for example "Beach/BicepCurl"), `TestPoseDepth` (freeze a rep at that depth), `TestPopupSlow`, `TestFlashSlow`, `TestSignCamera` (where the machine sign faces)
- **Screens:** `TestOpenMirror`, `TestPhoneLayout` (phone layout on PC)
- **New features run (13 Oct):** `TestMealRejoin` (act out leaving for n seconds, smoothie boosts pause), `TestRivalBeat` (a rival's id: wins his challenge), `TestClock` (hours: holds the time of day), `TestTrainers` / `TestTrainerSlots` (trainers following you), `TestPhotoMode` (opens photo mode)
- **Other:** `ForceSeason` (for example "Halloween"), `TestSkateMove` (scripted skating), `TestBrokenStage` (fake a failed body stage download), `PoseDebug`, `SoftShutdown` (shows the update note and holding screen)

## Where it lives
- Read by the matching services and client scripts; the list is kept in `PROGRESS.md` ("Studio test hooks").

## Known issues
- Remember to remove test attributes after testing (Studio was left with `TestMuscleShare = 2` for a 2-player test on 9 Oct).

## Related
[[GYM ARC - Player Data and Saving]], [[GYM ARC - Tutorial]], [[GYM ARC - Genetics]]

## TestOpenPanel (14 Oct)
Workspace attribute `TestOpenPanel` = "Physique" (set it during Play) opens the Physique window. Made because in the Device Emulator the test clicks can miss the left menu tiles.

`TestOpenPanel` = "Stats" (during Play, Studio only) turns the stats labels on.

## Phone or PC layout (15 Oct)
Workspace attributes, Studio only: `TestInput` = "Touch", "TouchKeyboard" or "KeyboardAndMouse" acts as that input; `TestNoJump` = true acts as if Roblox's jump button were hidden. With `TestPhoneSize` they test the machine buttons' phone / PC layout. See [[GYM ARC - Bug - Phones got the PC machine layout]].

## TestStatueMe (19 Oct)
Workspace attribute `TestStatueMe` = true: the first player becomes the statue (as the posing champion), to compare the statue with your own body. Studio only.

## TestLowEnd (20 Oct)
Workspace attribute `TestLowEnd` = true: your own body acts as if on a low-end phone. It shows the low-poly stage meshes when the camera is more than 15 studs away, and the live body nearer than 12. Studio only. See [[2026-10-20 GYM ARC Body lag]].
