---
tags: [city-legends, look, cars]
created: 2026-11-27
---
# Glossy car paint (27 Nov 2026)

Owner: "im sure the car paint need to be more glossy and same for traffic cars too." Follows [[2026-11-27 Car paint - clearer clear coat]] (roughness 0.08 was not enough).

**What changed**
- **Player cars:** the shared gloss MaterialVariant `CL_PaintGloss` (MaterialService), which `client/CarFinish.lua` and Customs' gloss finish already use.
  - Roughness 0.08 → **0.03** with a faint grain: `imports/car_paint/cl_paint_gloss_rough_003.png`, image 130690930391046.
  - Metalness 0 → **0.7**: `imports/car_paint/cl_paint_gloss_metal_070.png`, image 102974304712187.
  - Old ids are kept on the variant as attributes `OldRoughnessMap_008` and `OldMetalnessMap`.
- **Traffic cars:** `client/TrafficBodies.lua` `prepare()` now puts their paint parts (`TrafficPaint`) on the same `CL_PaintGloss`, with Reflectance 0 instead of plain SmoothPlastic at 0.08. This runs once per template, so there are no per-car scripts. Checked in Play: 123 of 123 paint parts on 46 cars.
- Satin, matte and metallic are unchanged. Old car models are unchanged (they never had the variant; owner's rule).

**Why metalness.** Roblox reflects only the sky, not the city. A plain clear coat (metalness 0) only shines at the edges, so it still read as plastic. Metalness 0.7 cuts the flat colour and lets the sky reflection and the sun highlight show across the whole panel, so the paint looks deep. Tested side by side in Play at noon and night:
- metalness 0, 0.2, 0.5 and 0.7;
- Reflectance 0.25 (rejected: it washes the paint with a pale blue);
- white and black cars at 0.7 (white stays white, black keeps its reflections).

**Trade-off:** at night, dark traffic colours read a bit darker than before (the black night sky gives nothing to reflect), but they still pick up streetlight highlights.

**FPS:** about 14.9 before and 15.2 after (Studio Play with the window in the background, 46 traffic cars). The change made no FPS difference.

![[2026-11-27 Glossy car paint - Player car, noon (before and after).jpg]]
![[2026-11-27 Glossy car paint - Traffic car, noon (before and after).jpg]]
![[2026-11-27 Glossy car paint - Player car, night (before and after).jpg]]
![[2026-11-27 Glossy car paint - Traffic car, night (before and after).jpg]]

**Saved** in Studio (not published). **Not checked:** each car one by one, a phone, and the M4 stand-in is a parked copy, not a car being driven.
