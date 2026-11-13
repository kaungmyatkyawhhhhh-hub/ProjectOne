---
date: 2026-11-14
tags: [mega-bite, ui, phone, audit, plan]
---
# MEGA BITE: roblox-ui-pro pass, the windows on phones (audit + plan)

Run of `/roblox-ui-pro on mega bite` after the HUD fix ([[2026-11-14 MEGA BITE - HUD tap floor (phone audit fixes)]]). I opened every window the way its button does and audited it on 5 devices. Screenshots: `MEGA BITE/UI/phone_audit_14Nov/`.

## Result: the windows work everywhere except phones, and phones are where the kids are

| Window | Galaxy A06 (705×338) | iPhone 17 Pro (750×381) | iPad 10th gen | Xbox | PC 976×584 |
|---|---|---|---|---|---|
| Shop | ×0.72, 22 errors | ×0.83, 18 | ×1.35, 2 | ×1.88, 0 | ×1.16, ok* |
| Fish Index | ×0.67, 42 | ×0.75, 41 | ×1.30, 3 | ×1.57, 1 | ×1.00, ok* |
| Settings | ×0.58, 45 | ×0.67, 45 | ×1.30, ok* | ×1.57, 1 | ×1.00, ok* |
| World Map | ×0.63, 28 | ×0.73, 24 | ×1.30, ok* | ×2.04, 1 | ×1.18, ok* |

\* Those device "errors" were mouse-sized targets on PC or touch targets on big screens. The audit now uses 24 px for mouse input.

**Why:** every window is a fixed-size box (e.g. Settings ≈ 560×380) that `K.AttachScale` shrinks until it fits the usable height. A phone has ~280–320 px of usable height, so the windows drop to ×0.58–0.83:
- Text drops to 8–12 px.
- Tabs, toggles and map pins drop to 17–24 px.
- The windows use only half the screen width (Settings: 324 px of 705).

The HUD tap floor doesn't help windows: a window has to fit.

![[A06 Settings.jpg]]
![[A06 World Map.jpg]]
![[A06 Fish Index.jpg]]
![[A06 Shop.jpg]]

## Slop check (the phone screenshots)
- **Tells:**
  - The windows are small islands in a big empty screen, with tiny words (Settings, World Map).
  - The World Map ring labels overlap ("GLOW GARD… KINGDOM").
  - The selected fish card to the right of the Fish Index grid is **blurred** on the phone. Is it a 3D card behind the window blur? Check it on PC too.
  - Store mini-cards: "EQUIP" price buttons are 24 px tall with 11 px words; the banner's ‹ › arrows are 18×21 and dark on dark.
- **Wows (keep these):** the depth titles, the consistent v6 kit (navy ink, lime/red/blue 3D buttons, white paper slab), the Shop's featured banner, the Index cards.

## Plan: phone layouts for the windows (not done yet; waiting for the owner's go)
A phone layout for each window, used when the screen's short side is ≤ 500 and the input is touch. The PC, tablet and console layouts stay as they are. The goal is that each window fills the phone's width at ≥ ×0.82, with all words ≥ 14 px and every tap ≥ 44 px.
1. **Settings:** two columns of rows (3 + 4) and a wide, short window. That's about ×0.85 on the A06 instead of ×0.58. Toggles 44 px tall.
2. **World Map:** the map disc on the left, filling the height; the landmark list on the right; ring labels outside the ring or on tap; pins 44 px tap areas.
3. **Fish Index:** a 5–6 column grid filling the width, the detail card as a slide-up sheet on tap (not a blurred side card), tabs 44 px.
4. **Shop:** the tabs and mini-card price buttons at 44 px; banner arrows 44 px and light; side cards in a horizontal scroll row.
5. Not yet audited: **Fossilize, the x2 EXP offer, the 3D reveal** (event-driven; they need a test trigger).

## Done in this pass
- **Studio-only test hook** in `ReplicatedStorage.MegaBite.ClientBus`: in Studio play, the bus events are parented under the module, so tests can open windows (`ClientBus.StoreOpen:Fire()`). It doesn't run on live servers. Backup: `ServerStorage.ClientBus_preTestHook_14Nov`.
- **roblox-ui-pro skill updated** and copied to `Brain/Skills/roblox-ui-pro`:
  - smarter audit: mouse targets, CanvasGroup clipping, full-screen dims, plates that are siblings
  - the test-hook method
  - the mid-Play device sweep
  - "phone windows are wide and short"
- Studio is back to the default viewport. **The place is not saved.**
