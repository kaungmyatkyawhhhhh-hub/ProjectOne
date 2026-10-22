---
date: 2026-10-23
tags: [gymarc, progress, menu]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Menu camera flyover (prompt 60)

Prompt: [[2026-10-23 GYM ARC Prompt - 60 Menu camera flyover]]

Game commit fcd19a6.
- The flyover: `Shared/UI/MenuFlyover`, started by `MenuClient`.
- The shot points: `Workspace.MenuCameraPath`, built in Studio. Recipe: `tools/builders/MenuCameraPath`.

## What changed
- **Behind the title screen** (the prompt 41 layout stays on top) the camera now glides slowly round the map in a loop of 6 shots.
- **The shots** (9-10 s each, sine-eased, no shake, a soft dip through dark between shots):
  1. high over the town
  2. past the PUMP SHOP sign
  3. through a Starter Gym street window into the gym (the x 40 window; the x 30 one has Coach Dex's desk right behind it)
  4. over the Beach Gym
  5. the Pro Gym front
  6. rising back up over the town
- **Moving a shot:** the points are in `Workspace.MenuCameraPath`, one folder per shot ("Shot1_Town" .. "Shot6_TownRise", played in name order). Each folder has an invisible `Start` and `End` part. The camera glides from Start to End, looking out of each part's **front face**: move or turn them in Studio. A shot's `Seconds` attribute sets its length. The model streams to every player at join (Persistent).
- **Streaming:** the first shot is streamed in while the loading screen is up. Each next shot is streamed in (`RequestStreamAroundAsync`, Start and End) while the current one plays.
- **Readability:**
  - a light depth of field: only the far distance softens, lighter than the old still image;
  - a soft dark vignette on the top, bottom and right edges;
  - the left gradient stays.
- **Hidden in the menu:** your character (and its name tag) and your trainers. The HUD stays hidden as before.
- **PLAY:** the camera swoops from wherever it is to behind your character in 1 s (eased), then hands control back. The HUD fades in during the swoop. The loading screen still comes first.
- **Phones / slow devices:**
  - no depth of field on low graphics quality (1-3);
  - if the frame rate stays under 40 for two 3-second windows in a row, the depth of field goes too (the first window is skipped: loading);
  - the vignette always stays.
- **Reduced Motion:** the camera holds still on each shot (the dips still change shots).
- Without a `MenuCameraPath` the old prompt 41 framing (the doorway and your character) is used.

## Tested (Studio)
- **Desktop 972x584:**
  - PUMP SHOP shot with the menu on top;
  - the window shot (the old x 30 window; Coach Dex in the way, so moved);
  - the PLAY swoop mid-way, ending at 12.8 studs behind the character with the Custom camera and the character visible again.
- **Phone layout 844x390:** the window shot at x 40 (clear), the Beach Gym shot with the depth of field on, the PLAY swoop mid-way.
- **Depth of field:** created at load and kept for 20 s at 57-60 fps. The test captures themselves stall Studio's frames and made it switch off in earlier runs, so the frame-rate check needs two slow windows in a row now.
- **Loading:** 0.8-1 s to the menu in Studio.
- No script errors; the logic tests pass.

## Not tested
- A video clip: Studio's capture tool only takes stills.
- A real phone's frame rate.
- How long streaming takes on a slow connection (each shot gets up to 6 s ahead).
- **Store after PLAY:** on this Studio test account the Store opens right after PLAY. It did that before this change too (a separate thing, not looked at).

![[GYM ARC/Screenshots/prompt60/01_desktop_pump_shop.jpg]]
![[GYM ARC/Screenshots/prompt60/02_desktop_window_old_x30.jpg]]
![[GYM ARC/Screenshots/prompt60/03_desktop_play_swoop.jpg]]
![[GYM ARC/Screenshots/prompt60/04_phone_window_x40.jpg]]
![[GYM ARC/Screenshots/prompt60/05_phone_beach_gym.jpg]]
![[GYM ARC/Screenshots/prompt60/06_phone_play_swoop.jpg]]
