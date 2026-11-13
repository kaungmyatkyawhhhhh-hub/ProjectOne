---
date: 2026-11-14
tags: [mega-bite, ui, settings, phone, change-log]
---
# MEGA BITE: Settings gets a phone layout

Step 1 of the plan in [[2026-11-14 MEGA BITE - UI pro pass (windows on phones, audit + plan)]].

## Before → after (phones)
On a phone, the 560×390 Settings window was shrunk to fit ~280 px of height: ×0.58 on a Galaxy A06, ×0.67 on an iPhone 17 Pro. That gave 8.7 px words, 17 px tall toggles, and half the screen empty.

**Now, a phone held sideways gets its own layout:**
- Two columns: Colour-blind / UI size / Shake / Vibration on the left, Music / Sounds / Codes on the right.
- A 780×266 window that **fills** the screen instead of shrinking to the HUD's scale.
- Taller rows (48), bigger words (18) and short phone labels ("Colour-blind", "Shake").
- The UI size pills read SMALL / MID / BIG on phones ("NORMAL" split in two there).

PC, tablet, console and portrait keep the one-column window, unchanged. Tablets get finger-sized tap areas on the pills. The window switches layouts live if the screen changes, e.g. touch → mouse.

![[iPhone 17 Pro Settings - phone layout.jpg]]
![[PC Settings - desk layout (unchanged).jpg]]
(`A06 Settings - phone layout.jpg` was taken one fix earlier, before the MID label and the wider pills.)

## Checked (14 Nov, Play in Studio; window opened through the bus like the gear button)

| Device | Layout | Scale | Smallest text | Smallest tap | Audit |
|---|---|---|---|---|---|
| Galaxy A06 705×338 | phone | ×0.78 (was ×0.58) | 14 px (was 8.7) | 39–40 px (was 17) | 0 errors; taps < 44 warned |
| iPhone 17 Pro 750×381 | phone | ×0.84 | 14 px | 41–42 px | 0 errors |
| iPhone 13 | phone | ×0.84 | 14 px | 41–43 px | 0 errors |
| iPad 10th gen | one column | ×1.30 | 19 px | 50 px | ok |
| Xbox | one column | ×1.57 | 24 px | 45 px | 0 / 0 |
| PC 976×584 | one column | ×1.00 | 15 px | (mouse) | 0 / 0 |

On phones every word fits on one line, and there are no script errors.

**Not checked:**
- A real phone.
- The Codes box with the phone keyboard open.
- Portrait (the game allows Sensor orientation; portrait gets the one-column window and will be small).

**The place is not saved.**

## What changed in code
- **`MB_Settings`:**
  - The rows are built by `build(mode)` from a `GEOM` table (`desk` / `phone`) and a `LAYOUT` list.
  - A row's icon wiggle now uses its own icon (with two columns, the old search found the other column's icon).
  - There's a 64-unit invisible tap area around the red X.
  - Backup: `ServerStorage.MB_Settings_prePhoneLayout_14Nov`.
- **`UIKit.AttachScale`:**
  - A window with the attribute `FitFill` fills the screen (up to ×1) instead of also shrinking to BaseScale.
  - Windows re-fit when their Size changes.
  - Backup: `ServerStorage.UIKit_prePhoneLayout_14Nov`.

## Next in the plan
World Map (map left, list right, pins 44 px), then Fish Index, then Shop. The same pattern: a `phone` geometry plus `FitFill`.
