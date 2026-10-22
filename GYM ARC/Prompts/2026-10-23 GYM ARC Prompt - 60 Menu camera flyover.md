---
date: 2026-10-23
tags: [gymarc, prompt]
status: done
---
# 60 Menu camera flyover

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Main menu (title screen) background: replace the still picture with a LIVE camera flyover of the map.
- While the menu is open, the camera is scriptable and slowly glides over the world: a smooth loop of 4-6 shots (e.g. high over the town -> past the PUMP SHOP sign -> through the Starter Gym windows -> over the Beach Gym -> the Pro Gym front -> back up over the town). Slow and steady (no shake), ~8-10 s per shot, eased curves, a soft crossfade or smooth move between shots. Shot points as parts in a "MenuCameraPath" folder so I can move them in Studio.
- Keep the prompt 41 title layout on top (logo, buttons). Keep the background slightly blurred (DepthOfField or a light BlurEffect) and a soft dark vignette so the buttons stay readable; lighter blur than the still image had.
- Streaming: call RequestStreamAroundAsync for each shot point before the camera gets there so nothing pops in. Hide the player's character and the HUD while in the menu.
- Pressing PLAY: the camera flies down smoothly (~1 s) to the player's character and hands control back. Loading screen still shows first, as now.
- Phones: lower the effects if FPS drops (no DepthOfField on low quality, just the vignette).
TEST: phone + desktop clip/screenshots of 3 shots and the PLAY transition. Short note in the vault.
```
