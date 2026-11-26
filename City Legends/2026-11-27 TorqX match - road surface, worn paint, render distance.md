---
tags: [city-legends, look, roads, settings]
created: 2026-11-27
---
# Getting close to the TorqX reference: road surface, worn paint (+ render distance fix) (27 Nov 2026)

**Owner:** "now we need to get close to that game reference" (the TorqX Racing TikTok, [[2026-11-26 Study - TorqX Racing TikTok (what makes it look real)]]). Then, mid-task: "why is the render distance so low rn even though its max? i can only see a few chunks".

## Gap check (same kind of shot: chase camera on Kabar Aye Pagoda Road, about 17:00)
- **Road:** ours was near-black and perfectly flat (Asphalt 46, 47, 50 under the RivAsphalt override); the reference has visible grain, bumps and sun shine. **Biggest gap.**
- **Paint:** ours is new and spotless (SmoothPlastic lines); the reference has chipped, worn yellow lines and textured zebras.
- **Light:** at 17:30 our day cycle already goes warm with sunset clouds. Left alone: the owner chose this light (16 Nov).
- **Already done 26 Nov, not redone:** lasting tyre marks, tail-light glow on the road, backfire light.

![[2026-11-27 TorqX match - road before (flat dark asphalt).jpg]]

## Done
1. **Road surface:**
   - All 420 road meshes (`Roads.Meshes` `RMeshR*`) now use MaterialVariant `YgnAsphaltWorn` (normal + roughness maps, 9 studs a tile) instead of the plain override.
   - Colour (80, 80, 84), still dark like Yangon's asphalt but grainy, with cracks.
   - Old values are kept in each part's attributes `OldColor` / `OldVariant`.
2. **Worn paint:**
   - `tools/road_paint/worn_paint.py` (tileable 512 px colour + roughness maps: about 10% chips showing dark grey, a lighter worn rim, fine grit).
   - Uploaded as images 131454717480631 (colour) and 140376370796258 (roughness); MaterialVariant `CL_RoadPaintWorn` (SmoothPlastic base, 8 studs a tile).
   - Applied to all 844 line meshes (`RMeshL`, `RMeshLY`, `RMeshLZ`; old variant in attribute `OldVariant`).
   - The pictures were still in Roblox's review when saved, so the lines show plain until they clear. Check again later.
3. **Render distance** (`client/MainMenu.lua` `renderDistanceOf`):
   - The cause: Performance AUTO drops into low-end mode under 28 fps, and low-end mode forced Render distance to LOW while the row still said MAX.
   - In Studio it never comes back: the memory check (under 1,800 MB) reads the whole Studio process.
   - Now the player's own choice wins; low-end mode only sets the default.
   - **Still true:** roads, terrain and landmarks stream in from the server only to `StreamingTargetRadius` 640 studs (Roblox's default is 1024). MAX only stretches the client-built building detail.

![[2026-11-27 TorqX match - road after (worn asphalt).jpg]]
![[2026-11-27 TorqX match - worn paint map.png]]

Saved as version 2249, not published.

## Not done / next
- The lines' worn look, once Roblox clears the pictures (check: `ContentProvider:PreloadAsync` returns Success).
- Raising `StreamingTargetRadius` 640 -> 1024 so MAX shows roads and landmarks further. It costs every player memory, and most are on phones: owner's call.
- The rest of the reference list: more street props (bus shelters with lit ads), manholes / painted arrows, a golden-hour menu shot with sun haze.

## Streaming radius (owner: "how about 4096"), measured 27 Nov
Studio Play on this PC, spawn on Kabar Aye, settled values (what streams in from the server; MAX's building detail is separate):

| `StreamingTargetRadius` | parts streamed | farthest road | fps (settled) | fps while loading |
|---|---|---|---|---|
| 640 (before) | 14,400 | 1,320 studs | 59 | 55 |
| 1024 | 15,300 | 1,805 | 59 | 59 |
| **2048 (set)** | **22,800** | **2,931** | **57-59** | **52** |
| 4096 | 43,600 | 5,835 | 46-48 | 25-34, for about 20 s |

- **Picked 2048 (version 2252, `default.project.json` matches).**
  - About 2.2x the road reach of 640 for no frame-rate cost on this PC.
- **4096 isn't worth it for most players:**
  - 3x the parts and about 12 fps less on a gaming PC once loaded;
  - 25 fps while it loads, again on every fast travel;
  - most players are on cheap phones, so expect worse there, and memory is the risk.
- Not measured on a real phone. Studio's memory tags count all of Studio, so only part counts and fps compare.
