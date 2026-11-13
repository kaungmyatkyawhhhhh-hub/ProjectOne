---
date: 2026-11-14
tags: [mega-bite, ui, shop, phone, change-log]
---
# MEGA BITE: the Shop gets a phone layout

Step 4 of [[2026-11-14 MEGA BITE - UI pro pass (windows on phones, audit + plan)]], after [[2026-11-14 MEGA BITE - Fish Index phone layout, full-screen map, right column removed]]. This was the last window in the plan.

## Before → after (phones)
**Before:** a phone fitted the whole shop to its short height, so a Galaxy A06 got ×0.72. That gave:
- 9–12 px words (the side cards' stat lines, the banner text, "FEATURED PASS", Collection)
- tabs 24 px tall
- side-card price buttons 24 px
- banner ‹ › arrows 18×21 px
- the X 35×39 px

**Now, a phone held sideways (touch, short side ≤ 500) gets:**
- **Fitted by width, not height.** The list already scrolls, so the height doesn't have to hold everything: ×0.86 on the A06 (was ×0.72), ×0.91 on an iPhone 17 Pro.
- **Tabs 1.55×** (45 px tall) in a taller top bar. The X is 1.15× with an invisible 64-unit tap area (on every device).
- **Card price buttons 1.25×** (44 px tall). The cards are taller (230) so the button stays under the stat line.
- **Words ≥ 17 units** (14.6 px on the A06), with short phone wording so they fit:
  - stat lines: "Pearl bubbles", "Glows bright", "Warm embers", "x2 every fish", "Fish on map"…
  - section hints: "No loot boxes", "Looks only", "No fight boosts"
- **The featured banner and the two side cards are each one big button.** Their price pills did the same thing as the card, so on phones the pill is only a picture and the whole card takes the tap (side cards 83 px tall).
- **Banner arrows 54 units** (46 px) on a bigger pill, and the art moved up to clear them. This applies on **every touch screen**: the iPad had 34 px arrows.

PC and console keep the old layout. One fix for every device: a section hint that doesn't fit its half of the header ("Looks only · on every shark you become" on a 976-wide PC) switches to its short form.

![[A06 Shop - before phone layout.jpg]]
![[A06 Shop - phone layout.jpg]]
![[A06 Shop - phone layout, skins.jpg]]
![[A06 Shop - phone layout, side cards.jpg]]
![[iPhone 17 Pro Shop - phone layout.jpg]]
![[iPad Shop - touch arrows.jpg]]
![[PC Shop - desk layout (unchanged).jpg]]

## Checked (14 Nov, Play in Studio, opened through the bus like the Shop button)

| Device | Layout | Scale | Smallest text | Smallest tap | Result |
|---|---|---|---|---|---|
| Galaxy A06 705×338 | phone | ×0.86 (was ×0.72) | 14.6 px (was 9.3) | 44 px (was 18) | 0 small, 0 off screen |
| iPhone 17 Pro 750×381 | phone | ×0.91 (was ×0.83) | 15.5 px | 46 px | 0 / 0 |
| iPad 10th gen | wide + touch arrows | ×1.35 | 17.6 px | 45 px (was 34) | 0 / 0 |
| Xbox | wide | ×1.88 | 24.5 px | 47 px | 0 / 0 |
| PC 976×584 | wide (unchanged) | ×1.16 | 15 px | (mouse) | 0 / 0 after the hint fix |

- No script errors.
- The console showed one failed asset load (`rbxassetid://108714310651768`), not from the Shop.
- After closing, the window blur is 0 and `MB_HeroOpen` is 0, so the hero card cleaned up.

**Not checked:**
- Buying, equipping and swiping the carousel by finger (a test can't press buttons).
- Scrolling by finger.
- Portrait.
- A real phone.

**The place is not saved.**

## What changed in code (`MB_StoreUI`)
- `fit()`: decides `PHONE` and fits by width on phones (`min(v.X/820, v.Y/300)`).
- `onFit()`: the top bar height (76 on phones), the list under it, the tab scale, the X size and position, the side cards 96 tall.
- `applyMode("phone" | "touch" | "desk")`, run when the mode changes (e.g. touch ↔ mouse):
  - card stat and price sizes, and the short phone wording
  - the side-card and banner buttons
  - the hint and chip words
  - the banner arrows and art
  - the grid's card height
- `CloseHit`: the 64-unit tap area on the X.
- Hint fallback: a hint that doesn't fit uses its short form.
- Backup: `ServerStorage.MB_StoreUI_prePhoneLayout_14Nov`.

## The phone pass is done
Settings, World Map, Fish Index and Shop all have a phone layout now. What's left from the plan:
- **Fossilize, the x2 EXP offer and the 3D reveal** are not audited yet. They're event-driven and need a test trigger.
