---
tags: [city-legends, yangon, landmark, sedona]
created: 2026-11-28
---
# Sedona Yangon: the current sign, and what else differs (28 Nov 2026, night)

Owner (28 Nov, paused list): "Myanmar Plaza, Melia and Sedona interiors are inaccurate; also the Sedona exterior and its SEDONA sign." Rule: current dated photos only (2023-2026, newest wins).

## Done tonight: the road sign (in Studio, saved v2467, not published)
- The roadside sign on Kabar Aye Pagoda Road was the **old blue board with white letters**.
- It now wears the hotel's **current logo**: slate and taupe serif SEDONA with an orchid in the O, YANGON under it, on a white board with a taupe cap and plinth.
- Source: sedonamyanmar.com, the site logo (files uploaded 2023-12 and 2026-06). Real brand signs are allowed for Sedona (owner's rule in `Games/CityLegends/CLAUDE.md`).
- How: `tools/yangon/SedonaSign.luau` builds `Landmarks.IrlSigns28Nov.Sedona_RoadSign` round the old board (the old mesh is untouched inside it). Face picture `imports/signs/sedona_sign_face.png` = Image **131324883898621** (group 33151111). Undo: `SedonaSign.undo()`.
- **Not certain:** the real board's shape. I found no dated photo of the roadside sign itself, only the logo.

![[2026-11-28 Sedona - road sign with the current logo (Studio).jpg]]
![[2026-11-28 Sedona - front before (old blue sign, Studio).jpg]]

## Dated sources found (the hotel's own, newest first)
| What | File on sedonamyanmar.com | Date |
|---|---|---|
| Logo | `2026/06/SedonaLogotransparent.png`, `2023/12/SEDONA-Yangon-RGB.png` | Jun 2026, Dec 2023 |
| Garden Wing lobby and Lobby Lounge | `2025/09/Lobby-Lounger-Banner.jpg` | Sep 2025 |
| Linkway between the wings | `2024/01/Linkway.jpg` | Jan 2024 |
| Inya Wing lobby | `2023/12/IW_Lobby_011-scaled.jpg` | Dec 2023 |
| Garden Wing from the pool | `2023/12/Pool-edited-copy.jpeg` | Dec 2023 |

Copies are only on this PC: `Games/CityLegends/build/landmarks/sedona/refs/` (not in git: the hotel's pictures).

## What the photos show against the game (for the rebuild)
**Outside (Garden Wing, Dec 2023 photo):**
- Real: the roofs are in **many tiers**: each wing ends in its own small gabled roof pavilion, the roofs step down toward the ends, brown-red tiles. Game: one long flat hip roof per wing.
- Real: **green-tinted ribbon windows** in long horizontal bands with white sills. Game: separate blue square windows in a white grid.
- Real: the wings wrap the pool in a shallow U with the tall spire pavilion in the middle. Game: has the spire pavilion; the U needs checking in Play.
- Real: a thatched pool bar pavilion in the middle of a curvy lagoon pool, dark-shingled Burmese pavilions round it, red umbrellas, toddy palms.
- The floor count needs a count on a straight-on photo (the game has about 12 rows of windows; the pool photo shows about 8 to 9).

**Garden Wing lobby (Sep 2025 photo):** wide dark marble steps up to the Lobby Lounge; two huge dark teak round columns; a **gold elephant statue on each side**; white carved relief walls; a coffered gold ceiling with a crystal chandelier; patterned brown carpet; the "Lobby Lounge" stand; a pastry case.

**Inya Wing lobby (Dec 2023 photo):** beige stone walls and square piers, a wide dark timber staircase with carved posts, cream marble floor, a coffered ceiling.

**Linkway (Jan 2024 photo):** sculpted layered timber benches, tall green glass fins, cream marble floor, dark timber wall panels.

## Not done, and why
- **The outside and the interiors are not rebuilt.** The Sedona model is made by `tools/yangon/city/sedona3d.py` from `build/landmarks/refs/sedona/sedona_model.json`, and that input is not on this PC (only `site_1to1.json` is). The rebuild has to run on the PC that has it.
- On this PC, Play runs out of memory (16 GB), so nothing could be walked through.
- To do there: roof tiers, ribbon windows, the three interiors above from these photos, side-by-side sheets.
