---
tags: [city-legends, cars, traffic, flicker]
created: 2026-11-27
---
# Windshield flicker (27 Nov 2026)

The owner said: "also some car windshields are flickering / overlapping". Later the same day: "after the glossy paint update, the cars have flickering/overlapping things."

## Cause
- **Probox, Hiace, Carry and YBS bus (our own traffic cars from `tools/yangon_traffic_cars.py`).** The window pillars were made by cutting a piece out of the glass shape and extruding it across the whole car.
  - Because of that, each pillar's front and back faces sat in the same plane as the windscreen and the rear glass. Painted pieces fought the black glass and showed as white wedges on the windscreen.
  - On the Probox the rear window was covered completely.
  - These four make up most of the city's traffic: in the test, 36 of 46 live traffic cars were one of them, 22 of those Probox.
  - Today's glossy, metallic paint on traffic bodies makes the painted wedge shine through, so it shows much more now.
- **Camry traffic copy.** It has a black under-layer with exactly the same shape and position as the painted hood. Since all car meshes were made DoubleSided today, that layer's back face shows through the hood as black triangles.

## What changed
- `tools/yangon_traffic_cars.py`:
  - New `Car.pillar`: a pillar is now a slab on each side, between the glass and 0.02 m outside it, never across the car.
  - The Carry's cab back wall stays solid but now sits 0.02 m behind the glass and reaches the roof top.
  - The YBS bumpers sit 0.02 m outside the body sides.
  - A coplanar check on the exported triangles finds no same-facing overlaps of different colours now. Before the fix there were 42 on the Probox, 49 on the Hiace, 59 on the Carry and 144 on the YBS. The pairs left are faces touching inside the car, which can't be seen.
- **New mesh in Studio:** Model 84402848780660 (group upload).
  - The Body meshes of the four templates in `ReplicatedStorage.TrafficModels` were swapped with `ApplyMesh`, plus the YBS Detail mesh. Size, attributes, TrafficPaint and DoubleSided were kept.
  - The old parts are in `ServerStorage.TrafficBodyOld_20261127`.
- **Camry:** the under-layer has `DoubleSided = false` and attribute `UnderPaint`. The rule: in TrafficModels, a non-paint MeshPart with the same box as a TrafficPaint part gets DoubleSided off. It was the only one.
- Gloss is kept: CL_PaintGloss is unchanged.

## Checked (Play, test store, then back to v1)
- Every player car model (55) and every traffic template was checked from the front three-quarter view in three ways:
  - real colours;
  - all glass turned opaque white;
  - every part a different flat colour, to find overlaps.
- Windshield wedges showed only on Probox and Hiace. Both are clean after the fix (pictures below).
- Player-car glass was clean in every check.
- The Camry's black hood triangles are gone.

![[2026-11-27 Windshield flicker - Probox (before and after).jpg]]
![[2026-11-27 Windshield flicker - Hiace (before and after).jpg]]
![[2026-11-27 Windshield flicker - Camry hood (before and after).jpg]]

**Saved** in Studio, version 2395 (not published).

**Not checked:**
- Rear and side views of every player car.
- A phone.
- Night.

The colour-coded view also shows ragged seams between paint pieces of the same colour, for example on the Chaser bumper. These can't be seen in the real paint, so they were left alone.
