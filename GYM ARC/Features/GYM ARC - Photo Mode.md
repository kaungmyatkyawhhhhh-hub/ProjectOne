---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Photo Mode

Back to [[00 GYM ARC Home|GYM ARC Home]].

Take a nice picture of your character. Built 13 Oct (new features run, task 7D).

## How it works
- **Where:** a **PHOTO** button (camera icon) shows at the top right when you stand near the gym mirror walls, the clothing store mirror, the progress mirror or the posing stage.
- **In photo mode:** the whole HUD hides (also Roblox's own buttons, prompts and machine signs) and your character stands still. Drag to turn the camera around you, scroll or pinch to zoom; the camera never goes inside a wall. A row of poses at the bottom (all the poses, including the new Victory wave).
- **HIDE UI** clears the screen so you can take a screenshot with your device; then a tap anywhere ends photo mode. The X button or Esc ends it too.

## Where it lives
- `Config/PhotoMode` (spots, camera distance and speed), `PhotoModeClient` (all on your own screen; poses go through the normal pose system).
- Studio test switch: `TestPhotoMode`.

## Related
[[GYM ARC - Poses and Posing Stage]], [[GYM ARC - Progress Mirror]], [[GYM ARC - Bug - Photo mode missed the mirror wall]], [[GYM ARC - Bug - Photo mode froze without the player module]]

## Screenshots
![[GYM ARC/Screenshots/photo_mode_mirror.jpg]]
![[GYM ARC/Screenshots/photo_mode_hidden_ui.jpg]]
