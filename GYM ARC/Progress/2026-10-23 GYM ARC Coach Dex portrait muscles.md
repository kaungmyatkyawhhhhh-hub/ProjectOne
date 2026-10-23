---
date: 2026-10-23
tags: [gymarc, progress, ui, bug]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Coach Dex portrait always muscled

Prompt: [[2026-10-23 GYM ARC Prompt - Coach Dex portrait muscles and dialog wrap|Coach Dex portrait muscles and dialog wrap]] (+ owner: "put clothes on coach dex portrait too"). Features: [[GYM ARC - Tutorial]], [[GYM ARC - Unlock Guides]].

## Why it happened
The dialog portrait copied the live Coach Dex in the world. Further than 60 studs away his muscle meshes are hidden (the NPC low-detail rule in `MuscleClient`), and far away he may not be streamed in at all, so a copy made then had the plain blocky body.

## Fix
- The server keeps a plain copy of Dex in `ReplicatedStorage.CoachPortrait` (made by `GymGoerService` when it builds him: full size, no tags, prompts or labels).
- Each client dresses one copy with his muscle stage meshes on join (`Shared/UI/CoachPortrait`, the same muscle code as the world NPCs), preloads it (ContentProvider:PreloadAsync), and every portrait is a clone of that. Never the live NPC.
- In the portrait he wears his coach tee (off-white, short sleeves, the muscles show through as shape) and his black shorts. Dex in the gym stays shirtless.
- If the dialog opens before the copy is ready (the first ~5 s after joining, while the body meshes download), it waits up to 1 s, then shows an empty frame and fills it in. Never the plain body.
- Dialog words: no "..." cut any more (wrapping on, the box grows to fit), and if a line still doesn't fit on a screen the box grows one more line (`Shared/UI/CoachDialog`).
- Trainer portraits: all 8 trainers use rendered pictures (muscles baked in) that are preloaded on join, so they were fine. The 3D fallback (only used if a trainer has no picture) now also wears the muscle stages (`Shared/UI/TrainerPortrait`).
- The unlock-guide dialogs use the same box, so they get all of this.

## Tested (Studio, PC viewport)
- 10 dialogs from 159 studs away: muscles every time.
- 10 dialogs from the first second after joining: the first 3 (0-4 s) waited 1 s and showed no body, from 5 s on the muscles every time, instantly. In a real join the loading screen and menu cover those seconds.
- Not tested on a real phone.

![[GYM ARC/Screenshots/coach_portrait/dialog_far_away_muscles.jpg]]
![[GYM ARC/Screenshots/coach_portrait/portrait_big_no_shirt.jpg]]
![[GYM ARC/Screenshots/coach_portrait/portrait_coach_tee.jpg]]
