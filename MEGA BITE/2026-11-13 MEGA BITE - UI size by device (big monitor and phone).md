# 2026-11-13 MEGA BITE - UI size by device (big monitor and phone)

Owner, 13 Nov 02:46: "in my big monitor pc, the buttons become small and on phone the buttons become big".

## What was wrong (read from the live scripts)
- `UIKit.AttachScale` scaled every HUD corner and window by `min(width / 844, height / 390)`, capped at **1.0 on PC** (11 Nov rule, tuned on a 1440 x 810 window) and 1.0 on phones.
- So the HUD had a fixed pixel size on PC. On a 2560 x 1440 monitor the DART button (112 px) was 8% of the screen height; in the 1440 x 810 window it was 14%; on a phone 24-27%.
- The Gold Rush meter, COMBO pop-up, FRENZY chip (`MB_GrindFx`) and the first-minute hints (`MB_FirstMinute`) had no device scale at all.

## The new rule (one function, `UIKit.BaseScale(v)`, v = the safe area in px)
| Device | Scale |
|---|---|
| PC / console (mouse, keyboard, gamepad) | the UI keeps the SAME share of the screen it has at 1440 x 810: `min(w / 1440, h / 810)`, up to 2.6. Never under 1.0 unless the window is smaller than 844 x 390 |
| Phone (touch, short side 500 px or less) | the old phone scale x 0.9 |
| Tablet (touch) | unchanged, up to 1.3 |
- Device = `UserInputService.PreferredInput` (falls back to `TouchEnabled`); the UI re-fits when it changes.
- The Settings "UI size" option still multiplies on top.
- Results: 976 x 526 -> 1.00, 1440 x 810 -> 1.00, 1920 x 1022 -> 1.26, 2560 x 1382 -> 1.71, 3840 x 2102 -> 2.60.
- Shop (`MB_StoreUI`): on PC it now also keeps its 1440 x 810 share (1.35 there, up to 3.2). Phone shop unchanged (it is a full-screen window).
- `MB_GrindFx`: meter, COMBO and FRENZY chip use `BaseScale`. `MB_FirstMinute`: the swim hints and the EAT! marker use it.

## Scripts changed (Studio, not published) and backups in ServerStorage
`UIKit` (`UIKit_preDeviceScale_13Nov`), `MB_StoreUI` (`MB_StoreUI_preDeviceScale_13Nov`), `MB_GrindFx` (`MB_GrindFx_preDeviceScale_13Nov`), `MB_FirstMinute` (`MB_FirstMinute_preDeviceScale_13Nov`).

## Checked
- Play in Studio (976 x 584, mouse): no errors, HUD and meter at 1.00 as before; `BaseScale` returns the table above.
- Big-monitor look shown by setting the HUD scales by hand in the Studio window (old rule 0.38 of the window, new rule 0.65): picture `Art\MEGA BITE - UI size on a big monitor (before and after).jpg`.
- NOT checked: a real phone and the real big monitor. The phone factor 0.9 is a judgement (the smallest button, Settings, is about 34 x 40 px on a phone; going lower makes it hard to tap). If the phone still feels big, the next step is 0.85 or shrinking only the DART button.
