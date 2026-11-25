---
tags: [city-legends, yangon, realism, streets]
created: 2026-11-25
---
# Street realism (day Yangon): wires, pole billboards, lane-arrow signs (25 Nov)

The owner asked for "realism stuff": streets that look and feel like real daytime Yangon. Checked against [[2026-11-23 Real Yangon by day - clip study (what the game must match)]] and [[2026-11-24 Clip re-watch - what the earlier studies missed (0927-0931)]].

Saved as **v2023** in Studio. Not published.

## Audit first (Play, test save, 11:00)
Spots: Waizayandar Road (clip 0929's road), its junction, Pyay Road, Anawrahta Road, and Kabar Aye Pagoda Road (P1).

| Clip list item | In the game before? |
|---|---|
| 1. Overhead wires and poles | **P1 only** (its street layer). Every other district: none. Biggest gap. |
| 2. Toddy palms / rain trees | Rain trees and coconut-type palms yes. No toddy (fan) palm avenues on roads. |
| 3. Traffic mix (white Japanese cars, YBS buses, red taxi plates) | Yes |
| 4. Signal heads with countdown in the lamp colour | Yes |
| 4. Blue lane-arrow panel on the mast arm | **No** |
| 5. Red-white median kerbs | Yes |
| 5. Black-white banded poles | **No** (outside P1) |
| 3-line plates "YGN-n" | Plates yes (black / red). Not checked for the 3rd line. |
| Yellow zebra + white stop line | Not seen at the audit spots |
| 6. Hazy day sky, flat-bottom clouds | Clouds yes. The sky is cleaner and bluer than the clips (see "Left"). |
| 7. Barred balconies, laundry, AC boxes | Yes (kit buildings) |
| Blue hoarding on building sites | No |
| 8. Pole billboards | **No** |
| Guard booths | Not seen on the roads |
| Blue metal awnings | Yes |
| Street lamps outside P1 | Only on the planted medians of Pyay / Kabar Aye |

## What was added (cheapest, biggest look first)
All of it is built on each player's phone near the camera from the traffic lane data. So it covers every district's main roads by rule, and adds **0 parts and about 19 KB of script to the saved place**.

1. **Power poles and overhead wires** (`src/client/YangonRoadside.lua`, new):
   - A concrete pole every 105 studs (35 m) on the kerb side of every road that has traffic lanes, both sides.
   - Each pole is 9 m tall with a black-white banded foot and a top arm.
   - From pole to pole: 2 thin top wires and 3 thick sagging cable bundles (Beams, so no parts).
   - Every 3rd pole has 2 wires across the road.
   - Junction boxes and coils of spare cable alternate along the poles, and every 7th pole has a transformer.
   - Poles go only on the pavement or the grass verge, never on a road, median, deck or building, and never inside a signalled junction.
   - P1 is skipped where its own street layer already has poles and cables (checked: 0 new poles at Kabar Aye).
2. **Pole billboards** (same script):
   - Every 9th pole gets a big board on one green steel column, set back behind the pavement and facing the traffic, with an ad on both sides.
   - The 6 ads are fictional brands with Burmese in Myanmar Unicode (no kinzi): SHWE PYAY cement, YADANAR 5G, GOLDEN TEAK RESIDENCE, HILLTOP MILK TEA, LUCKY STAR noodle, ZAYAR PAINT.
   - A board is skipped if it would hit a building, landmark, park, site or tree box.
3. **Blue lane-arrow panel** under every signal mast arm (`src/client/YangonSignals.lua`):
   - One arrow per approach lane: left on the inner lane, straight in the middle, straight + right on the outer lane.
   - It is only added where the arm is long enough.
   - "↱" has no glyph in Roblox fonts, so the outer lane shows "↑→".

Started from `Main.client.lua` (`startStep("YangonRoadside", ...)`, after the medians).

## Cost
- Saved place: 0 map parts, about 19 KB of script.
- In Play near the camera: about 170 parts and 110 beams (radius 480 studs).
- Phones in low-end mode: radius 336 and 3 cable bundles a span instead of 5.
- Start-up cost: 0.00 s after the plan was split over frames (the first try was a 0.4 s hitch).
- Studio Play: 60 FPS at Anawrahta Road.
- No script errors.

## Pictures (Play, 11:00)
| Spot | Before | After |
|---|---|---|
| Waizayandar Road | `2026-11-25 Street realism - Waizayandar Road (Play) - before.jpg` | `... - after.jpg` |
| Waizayandar junction (signal) | `2026-11-25 Street realism - Waizayandar junction signal (Play) - before.jpg` | `... - after.jpg` (lane panel; the shot is from before the ↑→ fix) |
| Pyay Road | `2026-11-25 Street realism - Pyay Road (Play) - before.jpg` | `... - after.jpg` |
| Anawrahta Road | `2026-11-25 Street realism - Anawrahta Road (Play) - before.jpg` | `... - after.jpg` |
| Pole billboard | | `2026-11-25 Street realism - pole billboard by Waizayandar Road (Play) - after.jpg` |
| Kabar Aye Pagoda Road (P1, unchanged) | `2026-11-25 Street realism - Kabar Aye Pagoda Road P1 (Play) - before.jpg` | |

## Test
- Test save `CityLegends_test` for the shots.
- Then the store went back to `CityLegends_v1`, saved (v2023), and was checked on the Server in Play (store = CityLegends_v1, YangonRoadside started, no errors).

## Checks and known limits
- Overlap: a box test of every new part against everything near it found no building or road hits. Only tree crowns (kit trees `OK*_ot1`) overlap some poles and one board column, which is a pole through foliage. Kit trees can't be ray-tested (CanQuery off), so the code cannot avoid them yet.
- Wires on narrow pavements run close to old-block facades and may brush balconies (visual only).
- Side streets without traffic lanes get no poles yet (P1's street layer has them, other districts don't).
- The Hledan deck fix was removed by the deck agent while this was being built, so the ray filter now uses only the road boxes and terrain (git and Studio match).

## Left (ranked)
1. Poles and wires on side streets (needs street data outside the lane set, like P1's `Data_P1S`).
2. Toddy (fan) palm rows along avenues (clip 0930).
3. Street lamps on undivided main roads (twin-arm lamps on the median or kerb poles).
4. Hazy, paler day sky. Careful: the owner called the old Yangon haze "too foggy" (16 Nov), so it needs his OK and a side-by-side.
5. Yellow zebra crossings with a white stop line (road paint: owned by the road builder, not touched here).
6. Blue hoarding round building sites, guard booths with striped roofs, camera gantries.
7. A phone check on a real device (FPS with the poles).
