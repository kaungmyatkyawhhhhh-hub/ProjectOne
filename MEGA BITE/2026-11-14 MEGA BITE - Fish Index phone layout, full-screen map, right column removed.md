---
date: 2026-11-14
tags: [mega-bite, ui, phone, index, world-map, hud, change-log]
---
# MEGA BITE: Fish Index phone layout, a full-screen World Map, the right column removed

Steps 3+ of [[2026-11-14 MEGA BITE - UI pro pass (windows on phones, audit + plan)]], with two owner requests made during the work.

## 1. World Map → a full-screen sea chart (owner: "make map like fits screen like deepwoken map cuz rn the map is so small")
This replaces [[2026-11-14 MEGA BITE - World Map phone layout]], which left the map small on every device.
- **One layout for every device:** a thin navy-framed chart over the whole safe area.
  - The world circle is as tall as the screen allows, capped at 760 px.
  - The title, the red X, the zone chip and the six landmark cards are on the right (two columns of cards when there's room, one on PC and iPad).
  - The zoom buttons sit in the circle's bottom corners.
  - REMOVE PIN sits at the end of the zone row.
- **Region names** show on big maps (≥ 380 px) and when zoomed in. A landmark icon sitting on a name pushes the name above or below it.
- Zoom, pan, pins and chests: the same code as before.

| Device | Circle before | Circle now |
|---|---|---|
| Galaxy A06 | 164 px | 254 px |
| iPhone 17 Pro | 174 px | 295 px |
| PC 976×584 | 321 px | 490 px |
| iPad 10th gen | 353 px | 723 px |
| Xbox 1080p | 555 px | 760 px |

Audit: 0 errors on every device. Text ≥ 14 px, taps ≥ 49 px on phones (zoom buttons 55×49).

![[PC World Map - full screen chart.jpg]]
![[A06 World Map - full screen chart.jpg]]

Backup: `ServerStorage.MB_WorldMap_preFullScreen_14Nov` (and `_prePhoneLayout_14Nov` before that).

## 2. The right column is gone (owner: "on mobile, these are gonna be pretty annoying so just remove those 3 buttons in both pc and mobile")
- The COMING NEXT tiles (next ability / FOSSILIZE / PVP) are off on every device.
- To bring them back: `SHOW_COMING_NEXT = true` in `MB_HUD`.
- The "tile flies into its button" unlock show only runs while they're on. Ability unlocks still get the HUD's other celebration.
- The PVP tile was only a toast ("RED TRENCH: swim past the reef edge"), so nothing else was lost.
- Backup: `ServerStorage.MB_HUD_preNoRightCol_14Nov`.

![[A06 HUD - right column removed.jpg]]

## 3. Fish Index on phones
- **Before:** the panel is anchored left, so it was never fitted. On a Galaxy A06 it stayed ×0.67 and ran off the bottom (10–13 px words, tabs 18 px tall).
- **Now, a phone in landscape gets:**
  - a 530×300 panel that fills the height (×0.79 on the A06, ×0.88 on an iPhone 17 Pro)
  - the 16 fish in rows of 6 that **scroll** (the grid is a ScrollingFrame; on PC its canvas is the frame, so nothing changes)
  - FISH/SHARKS tabs 1.4× (37–41 px tall), with the found bar moved to the right edge so they don't overlap
  - bigger counter and hint text
  - a 64-unit tap area around the X
- **Tablets** keep the PC panel with finger-sized tabs.
- The layout re-checks when the input type changes. Once, during a device switch, the input briefly read as mouse and the panel stayed in PC mode. The World Map got the same fix.

![[iPhone 17 Pro Fish Index - phone layout.jpg]]

| Device | Scale | Tabs | Fish tile tap | Audit |
|---|---|---|---|---|
| Galaxy A06 | ×0.79 | 37 px | 58×63 | text ≥ 14 except the hint line (~12 px) |
| iPhone 17 Pro | ×0.88 | 41 px | 64×70 | 0 errors after the fixes |
| iPad | ×1.30 | 44 px | — | 0 / 0 |
| PC | ×1.00 | — | — | 0 / 0 |

Backup: `ServerStorage.MB_Index_prePhoneLayout_14Nov`.

## 4. A bug fixed: the 3D hero card got blurred
**The bug:** the Shop and Index hero card is a real 3D card in front of the camera, and it turns the window blur off. But when ANOTHER window closed (Map → Index, or pressing M with the Index open), `K.Backdrop` turned the blur back on over the card.

**The fix:** `HeroCard` counts itself open with the `Lighting` attribute `MB_HeroOpen`, and `K.Backdrop` keeps the blur off while it's open. Checked: after Map → Index, the blur stays at 0.

Backups: `ServerStorage.HeroCard_preBlurFix_14Nov`, `UIKit_preBlurFix_14Nov`.

## Not checked
- Dropping a pin, REMOVE PIN, and pinch/drag on the new map (a test can't press buttons).
- Scrolling the Index grid by finger.
- Portrait.
- A real phone.

**The place is not saved.**

## Next in the plan
The Shop on phones (×0.72 on the A06: 9 px text, 24 px tabs and price buttons).
