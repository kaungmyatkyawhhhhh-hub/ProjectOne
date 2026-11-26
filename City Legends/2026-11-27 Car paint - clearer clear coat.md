---
tags: [city-legends, look, cars]
created: 2026-11-27
---
# Car paint: clearer clear coat (27 Nov 2026)

Part of matching the TorqX reference ([[2026-11-27 Sunset light - closer to the TorqX look]]). The reference cars shine with sky and street reflections; ours read matte-ish.

- **What paints cars:** MaterialVariant `CL_PaintGloss` (SmoothPlastic). `client/CarFinish.lua` puts it on the new imported models only (`CarFinish.NEW` / `CARS`, owner 6 Nov: "the new imports only"). Its roughness was a flat 0.2 picture (91277332178340).
- **Change:** a new roughness picture at 0.08 with a faint ±0.015 orange-peel grain (so highlights aren't plastic-perfect).
  - `imports/car_paint/cl_paint_gloss_rough_008.png`, image **127038427072594**.
  - `CL_PaintGloss.RoughnessMap` set to it; the old id is kept in the variant's attribute `OldRoughnessMap`.
  - Satin, matte and metallic are unchanged. Old car models are unchanged (owner's rule).
- **Saved:** version 2272, not published.
- **Trap:** Studio's `ContentProvider:PreloadAsync` can report Failure for images that do load. Check moderation with Open Cloud `GET /assets/v1/assets/<image id>` (`moderationState: Approved`) before switching a material to a new picture.

![[2026-11-27 Car paint - clear coat 0.08 (SVJ at sunset).jpg]]

**Not checked:** the other new-import cars one by one, and a phone.
