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
| Waizayandar junction (signal) | `2026-11-25 Street realism - Waizayandar junction signal (Play) - before.jpg` | `... - after.jpg` (retaken in pass 2 with the ↑→ arrow) |
| Pyay Road | `2026-11-25 Street realism - Pyay Road (Play) - before.jpg` | `... - after.jpg` |
| Anawrahta Road | `2026-11-25 Street realism - Anawrahta Road (Play) - before.jpg` | `... - after.jpg` |
| Pole billboard | | `2026-11-25 Street realism - pole billboard by Waizayandar Road (Play) - after.jpg` |
| Kabar Aye Pagoda Road (P1, unchanged) | `2026-11-25 Street realism - Kabar Aye Pagoda Road P1 (Play) - before.jpg` | |

## Test
- Test save `CityLegends_test` for the shots.
- Then the store went back to `CityLegends_v1`, saved (v2023), and was checked on the Server in Play (store = CityLegends_v1, YangonRoadside started, no errors).

## Pass 2 (25 Nov, later): no overlaps, side streets, toddy palms, lamps
Saved as **v2036**, then the store was switched back to v1 and saved again: that save timed out, but Studio then reported no unsaved changes, so it went through. Not published.

**1. Nothing touches anything (owner's no-overlap rule):**
- Every pole, lamp arm, top arm, billboard, palm and wire is tested before it is built, against:
  - the kit near the camera: balconies, walls, AC boxes and **tree crowns** in `YgnKitNear`. Their CanQuery is off, so they are tested point by point against each part's box;
  - building shells and roofs, parks, landmarks, edge greenery, the planted medians and the signal poles.
- A pole that would touch something moves up to 12 studs along the kerb or 4.5 studs across it, or is skipped. A wire that would touch something (a balcony on a narrow pavement, a crown, a roof) is left out.
- A chunk now waits until the kit tiles round it are built: `YangonKitStream` sets attribute `Built` on each finished tile folder.
- Check in Play near Waizayandar: 516 new parts and 178 wires, **0 overlaps** with any other visible part. The first pass had 4 (tree crowns, a kit part, shell roofs).

**2. Side streets:**
- Every road collision box (`RoadBox` R) with no traffic lane in it is a side street.
- One pole per 96-stud cell goes on one side of the street, with one wire and two bundles to the next pole along it, and an **amber** lamp on every second pole (owner, 21 Nov: side-street power-pole lamps are amber).
- P1 is still skipped (it has its own street layer).

**3. Toddy palm rows (clip 0930):**
- A palm every 30 studs (10 m) down the middle of any median at least 15 studs (5 m) wide, measured as the gap between the two ways' inner lanes.
- Never on a flyover, and never where the crown would touch a tree, a building or the planted-median shrubs (so Pyay Road mostly keeps its shrubs).
- The kit piece is `ReplicatedStorage.RoadsideKit.ToddyPalm`: a 15 m dark trunk and a generated palmyra crown (round fan-leaf head with dry leaves under it, 6.7 m wide). 2 parts.
- About 610 spots are planned over the map (before the junction and clearance checks), most on U Wisara, Bayint Naung, Waizayandar, No.1 Industrial and Pyay roads. Spots that fail the checks get no palm.

**4. Street lamps on main roads:**
- Every second main-road pole carries a galvanised arm with a white LED head over the road.
- Pyay Road and Kabar Aye Pagoda Road are left out (their planted medians already have lamps).
- The lights are on only at night, at normal quality, and within 220 studs of the camera: about 5 of 32 lit in the test, to keep phones fast.

Pictures (Play):
- `2026-11-25 Street realism - toddy palm median on Waizayandar Road (Play) - after.jpg`
- `2026-11-25 Street realism - pole lamps and palms at night, Waizayandar (Play) - after.jpg`
- `2026-11-25 Street realism - side-street pole with amber lamp (Play) - after.jpg`
- `2026-11-25 Street realism - Waizayandar junction signal (Play) - after.jpg` (retaken with ↑→)

Cost:
- About 450-520 parts and about 170 wires near the camera. No saved map parts, except the 2-part palm kit and about 42 KB of script.

## Pass 3 (25 Nov, afternoon): islands, lit billboards, gantries, guard booths, hoarding
Saved as **v2066**, on `CityLegends_v1`. Checked on the Server in Play: the store reads `CityLegends_v1` and the roadside pieces start. Not published. The PC lost power three times during this pass. Each time I checked the scripts in Studio and git against checksums before going on, and nothing was lost.

**1. No poles on corner islands or small traffic islands:**
- A pole spot now needs land behind it, away from the street: 6, 12 and 18 studs out must not be road, median or deck.
- The corner-island pole from pass 2 is gone.

**2. Billboards light up at night:**
- Within about 107 m of the camera, the ad faces glow at night (no light influence, a little brighter).
- No extra lights, so it costs phones nothing.

**3. Camera gantries and guard booths:**
- **Camera gantries:** at the 51 big signalled junctions (4+ approaches, widest approach 4+ lanes), a white pole and arm 10 m before the stop line with 3 or 4 white cameras (clips 0929: 4, 0930: 3).
  - Wires and poles keep out of the gantry's space. It is known from the plan, before anything is built.
- **Guard booths:** at real OSM gates (`barrier=gate`, 561 in the map).
  - A cream booth with windows on three sides, a door at the back and a red-white striped roof.
  - It stands 3-6 m from the gate, off the road on all four corners, and clear of walls and trees.
  - Many gates have no free spot, so they get no booth (2 near Thingangyun's gate cluster in the test).

**4. Blue sheet hoarding:**
- Only round real construction sites: OSM `landuse=construction` or `building=construction`, 23 sites in the map.
- Panels are 2.5 m tall, butted end to end, with a gap at each corner so two edges never meet.
- A panel is left out where it would cross a road, a tree, a building or the kerb.
- Example: the big site south-east of Kabar Aye (83 panels).

**Also fixed while testing:**
- **Wire ends:** wires now leave each pole at a shallow angle. Before, their ends dropped straight down beside the pole and ran through its top.
- **Top wires:** they tie to the arm end nearer the other pole.
- **My own pieces:** poles and wires keep out of each other. A pole is known from the moment its spot is chosen, and wires are logged a stud apart.

**Overlap check in Play, after the fixes:** 0 hits at the Thingangyun gate cluster (306 parts, 42 wires) and 0 at the Waizayandar junction (484 parts, 137 wires).

Data:
- `src/shared/YangonRoadsideData.lua`, from `tools/yangon/city/roadside_data.py` (OSM extract, ODbL), about 12 KB.

Pictures (Play):
- `2026-11-25 Street realism - camera gantry at Waizayandar junction (Play) - after.jpg`
- `2026-11-25 Street realism - guard booth at a compound gate (Play) - after.jpg`
- `2026-11-25 Street realism - blue hoarding at a real construction site (Play) - after.jpg`
- `2026-11-25 Street realism - blue hoarding close (Play) - after.jpg`
- `2026-11-25 Street realism - lit billboard and camera gantry at night (Play) - after.jpg`

Not touched:
- road meshes, kerbs, paint and lanes (the road-bug agent's work)
- the sky
- the zebra crossings

## Checks and known limits
- The overlap check samples points against each part's box. A round crown's box is a little bigger than the crown, so a few poles stand further from trees than they need to.
- Some pole spots and wires near the edge of the loaded area appear only once the camera comes closer (they wait for the kit there).
- Kit tree trunks are only as good as their boxes (no trunk parts were found in the kit).
- The Hledan deck fix was removed by the deck agent while this was being built, so the ray filter uses only the road boxes and terrain (git and Studio match).

## Left (ranked)
1. Phone check on a real device (FPS with poles, palms and lamps at night).
2. Blue hoarding round building sites, guard booths with striped roofs, camera gantries.
3. Lit billboards at night (night note item 4).
4. Not ours: the hazy day sky (owner: the old haze was too foggy) and the yellow zebra crossings (road builder).
