---
date: 2026-11-14
tags: [mega-bite, ui, world-map, phone, change-log]
---
# MEGA BITE: World Map gets a phone layout

Step 2 of the plan in [[2026-11-14 MEGA BITE - UI pro pass (windows on phones, audit + plan)]], after [[2026-11-14 MEGA BITE - Settings phone layout]].

## Before → after (phones)
The 13 Nov phone pass had already made the window wide (676×344). But its own scale code also capped it at the HUD's BaseScale, so a Galaxy A06 still got ×0.63. That meant 8 px ring names, 11 px landmark names, 20 px rows, 21 px map icons, and the ring names piled up in the middle.

**Now, a phone held sideways gets its own layout:**
- A 780×262 window that **fills** the screen: ×0.79 on the A06, ×0.84 on an iPhone 17 Pro.
- The map disc is as tall as the window, so it stays about the same size in pixels (164 px on the A06, 174 px on the iPhone).
- The six landmarks are **two-line cards in a 2×3 grid**: the name, then "Chest FULL" / the refill time / the hint under it. Each card is 52 units tall.
- The zoom buttons are 1.5× bigger.
- REMOVE PIN sits at the end of the zone chip's row (it used to sit under the list, where a phone has no room).
- The **ring names** (KELP HILLS…) show only once you zoom in to 1.6× or more.
- "6/6 FOUND" is 18 (was 16).

**All devices:**
- Every landmark icon on the map has an invisible 60-unit tap area. The icon looks the same.
- The red X has an invisible 64-unit tap area.

PC, tablet and console keep the 676×344 window and the one-line rows.

![[iPhone 17 Pro World Map - phone layout.jpg]]
![[A06 World Map - phone layout.jpg]]

## Checked (14 Nov, Play in Studio, opened through the bus like the minimap tap)

| Device | Layout | Scale | Smallest text | Smallest tap | Audit |
|---|---|---|---|---|---|
| Galaxy A06 705×338 | phone | ×0.79 (was ×0.63) | 14.2 px (was 8) | 40 px (was 21) | 0 errors; cards and zoom at 40–41 px warned |
| iPhone 17 Pro 750×381 | phone | ×0.84 (was ×0.73) | 15.1 px | 42 px | 0 errors |
| iPad 10th gen | PC layout | ×1.30 | 14 px | 40 px | 0 errors |
| Xbox | PC layout | ×2.04 | 14 px | 64 px | 0 errors |
| PC 976×584 | PC layout | ×1.18 | 14.4 px | (mouse) | 0 / 0 |

- No script errors.
- The console shows two failed asset loads, but they are not from this change. They are the new **Piranha skin textures** in `GameConfig` (Lantern 75990353384769, Ember 135651012473635), probably still in moderation.
- Landmark tap areas overlap each other where landmarks sit close together on a small map. The top one wins; zoom in to separate them.

**Not checked:**
- Dropping a pin, REMOVE PIN in its new place on phones, and zoom/pan by finger. A test can't press the buttons.
- A real phone.
- Portrait.

**The place is not saved.**

## What changed in code (`MB_WorldMap`)
- `mode` + `applyLayout(mode)`: sizes and places the window, disc (`DISC` and `k2` are now variables), zone chip, cards, zoom buttons and ring-name size for desk or phone. It runs at start, when the viewport changes, and when the window opens.
- The window's scale fills the screen in phone mode.
- `rowLayout(r, found)`: one line (PC) or a two-line card (phone).
- `setPinButtons()`: the desk REMOVE PIN under the list, or the phone one next to the zone chip.
- Backup: `ServerStorage.MB_WorldMap_prePhoneLayout_14Nov`.

## Next
Fish Index, then Shop.
