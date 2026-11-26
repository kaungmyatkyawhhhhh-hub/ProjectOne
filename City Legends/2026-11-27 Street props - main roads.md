---
tags: [city-legends, yangon, realism, streets]
created: 2026-11-27
---
# Street props on the main roads: YBS shelters with lit ads, ad panels, bins, pole stops, manholes (27 Nov)

Goal (owner, 27 Nov): street level felt empty next to the TorqX Racing reference ([[2026-11-26 Study - TorqX Racing TikTok (what makes it look real)]]): bus shelters with glowing ad screens, manholes, arrows, hedges. Only real-Yangon things, checked against [[2026-11-16 Research - Yangon street furniture and traffic life]] and [[2026-11-16 Research - Real Yangon street detail survey]].

Saved as **v2280** in Studio. Not published.

## Census first (what was already there)
| Item | Before |
|---|---|
| YBS shelters / pole stops, orange bins | **P1 only** (street layer `Data_P1S`). Shelter ad box was a plain light panel, no ad. Every other district: **none**. |
| Power poles, cables, lamps, pole billboards, gantries, booths, hoarding, toddy palms | Yes (P1 street layer + `YangonRoadside` everywhere else) |
| Signals with the blue lane-arrow panel | Yes |
| Painted turn arrows, stop lines, zebras | Yes (`roads05_paint`: arrows at every signalled stop line) |
| Drains, median railings, tea shops, stalls | P1 street layer |
| Manholes | **None anywhere** |
| Hydrants, hedges, mailboxes | Not added: not part of Yangon street research (TorqX is a US city) |

## Added (all client-built near the camera, in `src/client/YangonRoadside.lua`; 0 saved map parts)
1. **YBS stops at the 1,063 real OSM bus stops** off P1 (P1 keeps its own). `tools/yangon/city/roadside_data.py` now writes `Stops` into `YangonRoadsideData` ("x,z,K"):
   - S = FMI-style shelter when OSM says `shelter=yes`, or 2 of 3 untagged stops on primary / trunk / secondary roads (research: shelters every 300-500 m per direction on main roads): **635 S**, 428 P.
   - A shelter uses the same kit pieces as P1 (`busd`), plus the orange YCDC bin past its open end and a **free-standing double-sided ad panel** (1.2 x 1.8 m on two legs) past its ad end.
   - Stops snap to the nearest outer lane they stand right of. The whole strip must fit on one level of pavement (5 rays, 0.3 max height spread, pavement or grass), clear of the kit, buildings, poles, palms, gantries. Else a **pole stop** (`busp`) near the kerb.
   - Poles now keep off stops (`stopReg`).
2. **Lit ads on every shelter**, P1's too: new invisible kit piece `SAD_busd` (`YangonStreetKit.shelterAd()`, tag `ShelterAd`), its two faces 0.08 in front of the ad box plates. Each copy gets portrait SurfaceGui ads when it enters the Workspace. They light up at night within 320 studs with the billboards' `RoadsideAd` switch (no lights, so free on phones).
   - Made-up ads, Burmese in Myanmar Unicode, no kinzi: NAGA X9 phone (ဖုန်းအသစ်), SHWE LA tea mix (လက်ဖက်ရည်), THAZIN NET telco-style SIM (အင်တာနက် အမြန်), MINGALAR noodle (ခေါက်ဆွဲ), MYA PEARL soda (အအေး).
3. **Manhole covers** on every main-road lane, P1 included: one every 230 studs per lane (offset per lane, in a wheel track 2.6 off the lane middle). Never within 60 studs of a lane end or 70 of a signalled junction (arrows, stop lines, zebras), never on decks.
   - Only where 5 rays to the road boxes agree on one flat plane (no seams or crowns under it).
   - One Cylinder part, 0.14 thick, bottom 0.04 over the road, top 0.18: cast iron (DiamondPlate, 58,56,52) or every 3rd a smaller rusty one (CorrodedMetal).
   - No collision, no queries, no shadows.

No uploads were needed (ads are SurfaceGuis like the pole billboards).

## Counts and cost (Studio Play)
- Kabar Aye spawn: 26-27 manholes within the 480-stud build radius.
- Waizayandar Road: 3 shelters and 35 manholes in range.
- Sule Pagoda Road downtown: 0 shelters, 2 pole stops (narrow arcaded pavements, which is what real downtown has).
- FPS at the spawn: before **59.1** (40,854 workspace parts); after **55-56** with 52,928 parts streamed (the session had driven round). A/B in the same spot with the new parts taken out: 55.9 with / 55.8 without / 56.1 with. The new props cost nothing measurable; the drop is the extra streamed map.
- Overlap check (every new visible part vs kit, map, medians, signals, roadside within 64 studs, point-in-box): **0 hits** at Waizayandar (116 parts tested). The only flags were whole-cell night meshes whose boxes cover the street (false positives).
- Flicker: ad faces 0.08 in front of the plates; manhole top 0.18 over the road box (road paint sits at 0.08).

## Pictures
| | Before | After |
|---|---|---|
| Kabar Aye spawn, day | `2026-11-27 Street props - Kabar Aye spawn day (Play) - before.jpg` | `... - after.jpg` |
| Kabar Aye spawn, night | `2026-11-27 Street props - Kabar Aye spawn night (Play) - before.jpg` | `... - after.jpg` |
| Sule Pagoda Road, day | `2026-11-27 Street props - Sule Pagoda Road day (Play) - before.jpg` | |
| Manholes on Kabar Aye | | `2026-11-27 Street props - manhole covers on Kabar Aye (Play) - after.jpg` |
| P1 shelter with its new ad | | `2026-11-27 Street props - P1 shelter with lit ad (Play) - after.jpg` |
| Waizayandar shelter, ad panel, bin (day / night) | | `2026-11-27 Street props - YBS shelter, ad panel, bin on Waizayandar Road day (Play) - after.jpg`, `... ads lit at night, Waizayandar (Play) - after.jpg` |

![[2026-11-27 Street props - YBS shelter, ad panel, bin on Waizayandar Road day (Play) - after.jpg]]
![[2026-11-27 Street props - YBS shelter ads lit at night, Waizayandar (Play) - after.jpg]]
![[2026-11-27 Street props - manhole covers on Kabar Aye (Play) - after.jpg]]

## Not done / risks
- Yellow kerb paint along the bus bays (research item): it is road-surface paint, left for the road builder.
- Concrete bollards / planters / vendor umbrellas outside P1: the research gives no main-road rule for them; skipped.
- Our shelters have no stop-name plate (P1's come from the atlas); the YBS box on top is plain white.
- Walkers' paths are not told about the new shelters: a walker can pass through one.
- Manholes sit on the road collision boxes; the visible road mesh is within about ±0.05 of them on flat stretches (measured with EditableMesh vertices at the spawn), worse at kerb edges, which are avoided.
- Not checked on a real phone.
