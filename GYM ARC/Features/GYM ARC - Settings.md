---
date: 2026-10-09
tags: [gymarc, feature]
status: done
---
# GYM ARC - Settings

Back to [[00 GYM ARC Home|GYM ARC Home]].

The Settings panel (top bar pill or the menu). All choices are saved per player.

## How it works
- **Music volume** and **Effects volume** sliders.
- **Gain numbers:** On (rep + set popups) / Minimal (set popups only) / Off.
- **Show EXP popups:** On / Off (Off = the old single "+N").
- **Rep flash:** On / Off (the red pulse on each rep; the training tint stays).
- **Spot requests:** On / Off.
- Fits on phones (one line per setting).

## Where it lives
- `SettingsClient`, saved in `settings` in the player's data (`Server/DataTemplate`), changed through `Server/ActionService`

## Planned change
- Monetization prompt: a **music on / off** toggle (if missing) for the new playlist, and a **Screams** toggle (on by default) that mutes other players' screams for you only.

## Related
[[GYM ARC - Game Feel]], [[GYM ARC - Spotting]], [[GYM ARC - Music and Sounds]], [[GYM ARC - UI System]]

## Screenshots
![[GYM ARC/Screenshots/fonts_after_settings_pc.png]]
![[GYM ARC/Screenshots/fonts_after_settings_phone.png]]
