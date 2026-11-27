---
tags: [city-legends, yangon, realism, buildings]
created: 2026-11-27
---
# Building fronts: real glass and stained walls (27 Nov)

Goal (owner, 27 Nov): next to the TorqX Racing reference ([[2026-11-26 Study - TorqX Racing TikTok (what makes it look real)]]) our buildings read as flat white boxes with window patterns, and white walls blow out in the sun.

Saved as **v2289** in Studio. Not published.

## Census (what is on screen)
| System | Windows | Walls |
|---|---|---|
| Kit detail near the camera (client, 1,000 studs) | Glass was baked into the KGR mesh together with grilles, signs, shutters, AC units: **Metal + YgnSteelPainted**, dark vertex colour. It read as navy-black blocks. | KWX panels: Plaster + YgnRenderPainted in the building's wall code colour |
| Shells (far, and before the kit loads) | Window grid in the YgnShell* variant maps: glass already glossy (roughness 0.12) with recess normals | Plaster + YgnShell*, part Color = wall code |
| Landmarks (Myanmar Plaza, Sedona, City Hall, Myanmar Centre ...) | own meshes | owner-set colours: **not touched** |

**Wall colours in the shells (197,146 parts):** 50,193 were KW6 white (255,252,243) and 24,738 KW4 blue-white (226,248,255). So **38% of all shell walls were near pure white**. Same codes in the kit.

## Changes
1. **Walls:** three wall codes toned down to painted, stained off-whites:
   - KW6 white 255,252,243 -> **222,212,194** (warm off-white)
   - KW4 blue-white 226,248,255 -> **200,208,204** (weathered grey; in the blue shade light it read sky blue)
   - KW0 trim 252,255,250 -> **226,224,216**
   - Done in the kit colours (client), the Edit tool, the shell generator and the 74,931 Studio shells. Landmarks keep their colours (Myanmar Plaza white, City Hall, Sedona).
2. **Glass:** the window glass is now its own kit piece (KGG) next to each panel's KGR:
   - Rebuilt the 453 panels from their saved keys; each old KGR = new KGR + glass (triangle counts match exactly), so nothing moved and no new faces were added.
   - 423 panels have glass: 10 model uploads, 423 KGR templates replaced, 423 KGG templates added.
   - Glass look: **Glass material, slate blue-grey (70,78,84)**, no shadow. Night windows (FacadeNight panes 0.09 studs in front) still light.
3. **Depth on shell windows:** already there (recess normal map + glossy glass in the YgnShell maps), so nothing was added.

## Tried and dropped
- A glossy MaterialVariant (roughness ~0.16, uploaded image 115891737570275) on the whole KGR class: **no visible change**.
- Reflectance on KGR: **ignored** while a MaterialVariant is set. Without the variant it turned signs and shutters blue too.
- SmoothPlastic + Reflectance 0.15-0.3 on the split glass: it read as **flat royal-blue paint** (Roblox reflects only the sky, not the street).

![[2026-11-27 Building fronts - rejected, SmoothPlastic + Reflectance glass reads as blue paint (Play).jpg]]

## Pictures (Play)
| | Before | After |
|---|---|---|
| Township street, noon | `2026-11-27 Building fronts - township street noon (Play) - before.jpg` | `... - after.jpg` |
| Township street, 17:30 | `... 17.30 (Play) - before.jpg` | `... - after.jpg` |
| Township street, night | `... night (Play) - before.jpg` | `... - after.jpg` |
| Downtown street, noon | `2026-11-27 Building fronts - downtown street noon (Play) - before.jpg` | `... - after.jpg` |
| Kabar Aye spawn, noon | `2026-11-27 Building fronts - Kabar Aye spawn noon (Play) - before.jpg` | `... - after.jpg` |

![[2026-11-27 Building fronts - township street noon (Play) - before.jpg]]
![[2026-11-27 Building fronts - township street noon (Play) - after.jpg]]
![[2026-11-27 Building fronts - township street 17.30 (Play) - before.jpg]]
![[2026-11-27 Building fronts - township street 17.30 (Play) - after.jpg]]

## Cost
- FPS at the spawn (PC, capped at 60): **59.5 before, 59.0 after**. Workspace parts: 45,779 before, 45,685 after (streaming differs between runs).
- Near the spawn there are about 430 glass parts. Busy downtown has about 2,800 within the 1,000-stud kit radius. That is roughly one extra part per window-bearing panel.
- Flicker check `kit_flicker_test.py P1`: 0 flickering pairs in the 436 kit pieces. 2 old KWC compound-wall pairs across instances (not from this change).

## Not done / risks
- The spawn view is mostly landmarks (Myanmar Plaza, Myanmar Centre, Sedona), which were left alone on purpose. That is where the biggest white walls on Kabar Aye are, so the spawn shot barely changes.
- The glass does not reflect the street (Roblox has no local reflections). It reads as tinted glass, not mirror glass.
- Extra kit parts on phones: not measured on a real phone.
- New districts need `kit_glass.py` + `KitGlassApply` (or a full `buildings_1to1.py` run, which now writes KGG itself) for any new panel.
