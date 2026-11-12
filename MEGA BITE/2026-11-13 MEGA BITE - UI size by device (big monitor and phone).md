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

## Round 2 (13 Nov 03:23, owner on the big-monitor preview: "i think this is so small and also people wont even bother reading any of those texts. and move the one in 2nd to the 3rd place")
- **PC scale +25%:** the reference is 1150 x 650 now (was 1440 x 810), cap 3.2. Results: 976 x 526 -> 1.00, 1440 x 810 -> 1.25, 1920 x 1022 -> 1.57, 2560 x 1382 -> 2.13. Shop on PC: `min(w / 1150, h / 650) x 1.2`, cap 3.6.
- **SIZE + EXP readout moved to the bottom-left corner** on PC / console (the spot the owner marked). The NEXT bar, the FOSSILIZE button and the carry chip stack above it. `tlLayout()` in `MB_HUD`.
  - On phones it stays top-left: the floating swim thumbstick owns the bottom-left (`MB_Swim`: left 42%, lower 65% of the screen), so a thumb would cover it.
- **Bigger small texts:** the unlock column on the right (tiles 46 -> 56, labels 11 -> 14 px), FOSSIL chip 14 -> 17, NEXT label and % 15 -> 17, quest count 13 -> 14.
- **Corner offsets now scale with the UI** (`corner()` in `MB_HUD`, attribute `BasePos`): at scale 2+ the unlock column would otherwise have sat under the scaled-up minimap.
- Backups: `UIKit_preBigger_13Nov`, `MB_StoreUI_preBigger_13Nov`, `MB_HUD_preBottomLeft_13Nov`.
- Checked in Play (976 x 584): no errors, layout as intended; big-monitor look simulated at 0.81 of the window. Picture: `Art\MEGA BITE - UI on a big monitor v2.jpg`. Still not checked on the real monitor or a phone.
- Owner approved the clownfish at 03:23.

