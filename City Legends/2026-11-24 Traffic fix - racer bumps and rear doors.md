---
tags: [city-legends, traffic, racers]
created: 2026-11-24
---
# Traffic fix: racer bumps and hops, missing rear doors (24 Nov 2026)

Two open NPC-traffic bugs, both fixed in Studio (saved, not published) and in the repo.

## 1. Racers bumping and hopping

### What caused it
The 1:1 lanes are chains of straight pieces about 24 studs long. Traffic cars sit exactly on them (no ground ray), so:
- **Curve speed never applied.** The racer speed rule (3% slower per degree of turn, owner 21 Nov) measured the bend *inside* each piece. A straight piece has none, so a racer took every bend, crest and dip at top speed.
- **The nose snapped at every lane point.** The car's heading was the piece's direction, so it jumped by the joint's angle in one frame (up to 10-17 degrees on Kabar Aye's bend). On a crest or dip, the up/down speed flipped in one frame: a hop.
- **Bad lane heights in 3 places:**
  - **Arzani Street:** 4 lane points were left at the deck's height (128-131) over the ground road built 12-25 studs lower. Those were the worst hops: at 220 mph that is a 579 studs/s vertical jolt in one frame.
  - **Arzani Street deck end:** the built deck stops in the air at (32720, 36170), 39 studs over the road (129.6 down to 90.4 in 24 studs), with no ramp. The traffic lane ran straight off it.
  - **Hledan deck (Pyay Road #6, `YangonDeckFix`):**
    - The lift onto the new deck also lifted 12 points of **Pyay Road #12**, the ground road under the deck, 16 studs up.
    - It missed Pyay Road #6's outer lane 3 where that lane ran more than 21 studs from the middle. This left a 15-stud step at each deck end.

### The spots (16 places, by kind)
| # | Where | Kind | Before (at 220 mph) |
|---|---|---|---|
| 1-2 | Arzani Street (32969-33064, 36330) and (33209, 36354) | 4 deck-height spikes | 25-studs jumps |
| 3-4 | Arzani Street deck end (32724, 36175), both ways | cliff, 39 studs | car drove off the deck |
| 5-6 | Pyay Road #12 under the Hledan deck (27234-27308, 28494-28772) | lifted 16 studs by mistake | up / down steps |
| 7-8 | Pyay Road #6 lane 3, both deck ends (~27293-27338, 28869-28882) | 15-stud step | step |
| 9 | Maha Bandula Road #2 (35649, 45105) | built crest, 18% grade change | 51 studs/s jolt |
| 10 | Ahlone Road #3 deck foot (27527, 39763) | built step, 19% | 53 studs/s |
| 11 | Shwe Gone Dine Road (36460, 33309) | crest, 18% | 51 studs/s |
| 12 | Old Yay Ta Shay Street #2 (34500, 37754) | dip, 18% | 51 studs/s |
| 13 | Hledan Road #3 deck foot (25082, 28895) | step, 11% | 31 studs/s |
| 14 | Ziwaka Road (33775, 39434) and (33905, 39367) | kinks, 12-13% | 35 studs/s |
| 15 | Merchant Road (34014, 45886) | kink, 12% | 35 studs/s |
| 16 | May Ni Gone Overpass (29047, 35048) / Zoological Garden Road #4 (35271, 38242) | kinks, 10-12% | 30 studs/s |

### The fix (cause, not speed caps)
- **`src/shared/YangonDeckFix.lua`**
  - `unspike`: a lane point off BOTH neighbours by more than 1.5 studs the same way goes back onto the line between them, in order along the lane. This changes only the 4 Arzani points. Their new heights match the built road exactly (104.2 / 106.7 / 109.3 / 116.8, checked by raycast).
  - `cliff(a, b)`: true for a piece that climbs or drops more than 6 studs at over 1 in 2.
  - The Hledan lift now applies only to `D.ROAD` = Pyay Road #6, across 26 studs.
- **`src/shared/RivieraTraffic.lua`:** a cliff piece is never joined to the piece before it and is not a spawn piece. The deck pieces before the Arzani deck end are pruned back to the last junction, so no traffic drives off it. After the fix there are 2 cliff pieces (both on Arzani) and **0 live lane pieces steeper than 25%** in the whole 1:1 graph.
- **`src/client/Traffic.lua` (racers only, everyday cars unchanged):**
  - `bendSpeed` now counts the corner where two pieces meet, up and down included (a crest is a bend). The first 1 degree is free (chord noise), so straights keep full speed: 83% of all lane joints are under 1 degree.
  - `racerSample`: near a joint the racer drives a short curve round the corner instead of snapping its heading. The window is 0.05 s of travel, at most 12 studs each side. Its height stays the lane's own (on the built road); only the nose eases up or down.
  - The previous piece is tracked as `prevSeg` and restored when a blocked step is undone.
  - The cost is a few vector operations per racer per frame. The grid spot-finding and frame spreading are untouched.

### Check (Play, store `CityLegends_test`, `TestRareChance` 1, `TestLowEnd` false; 90 s, 7 racers, about 3,900 samples over 100 mph)
- Vertical jolts: **worst 8 studs/s, 0 over 40** (before: 31-579 at the spots).
- Turning: at most 1.14 degrees per stud travelled (a smooth 50-stud curve) at over 100 mph. Before, the heading jumped by the whole joint angle in one frame.
- A racer slowed to 117 mph through the 17-degree joint on Kabar Aye's bend. Top speed seen: 274 mph (a Bugatti in a chase, x1.15). Average on straight frames: 133 mph for all racer kinds together (GT-R 150 and R34 130 tops included).
- Low-end mode still works: in the first run Studio's slow frame rate switched it on, and traffic dropped to 14 cars as before.
- No Traffic errors in the Output.
- Shot: ![[2026-11-24 traffic fix - racer on Kabar Aye bend (Play) - after.jpg]]

## 2. Rear doors missing on traffic copies

### What caused it (in `tools/yangon/TrafficLOD.luau`, which makes the light traffic copies)
- **Belta and Alfard: a filter stripped the doors.** `DROP_GROUPS` dropped every group named `misc`, and these A-Chassis cars keep all their doors in `Misc/FL..RR/Door`. The Belta copy had no doors at all, so its white seats showed through. The Alfard copy lost its sliding doors.
- **Camry and Crown: the 45-part cap trimmed by size only.** It cut rear door skins and side windows. Where two parts tied at the cut, one door of a pair was kept and the other dropped.
- **Belta wheels:** the copy's "wheels" were 3 see-through suspension arms. The real wheel is the corner Part itself (a cylinder).
- The 19 Nov old-model move put the roster's old bodies in `ServerStorage.OldModelCars`, so `TrafficLOD` could no longer rebuild those cars.

### The fix
- `misc` is out of `DROP_GROUPS`. The steering wheel in Misc is still dropped by its own `SW` group, and interior parts still go by the cabin-box and name tests.
- A door part in the paint parts' colour and material is paint, so the Belta's door skins (named "H") take the livery. This applies to doors only: on a black car every black trim would otherwise take the livery.
- The cap never trims the shell (paint, glass, door parts, badge covers). Only other parts are trimmed, by size, with a stable tie-break.
- Suspension parts are never wheels. An A-Chassis corner part is used as the wheel, in a dark tyre colour.
- Source cars are looked up in `CarModels`, then in `ServerStorage.OldModelCars`.
- **Rebuilt and swapped: only the 4 broken copies**: Belta (body 33 -> 45 parts), Camry, Crown (same 45, now the whole shell), Alfard (20 -> 40). The other 13 were left as they are. A rebuild would have replaced the R34 copy with the new R34 body, which is a separate change. The old 4 are in `ServerStorage.TrafficModels_preDoors`.
- Performance: the Belta and Alfard copies have about 20 more parts each. Low-end mode keeps its 14-car cap.
- Shots:
  - ![[2026-11-24 traffic fix - rear doors Belta Camry Crown (Play) - after.jpg]]
  - ![[2026-11-24 traffic fix - Camry Crown Alfard copies (Play) - after.jpg]]
  - These are the traffic templates as TrafficBodies scales them, placed by the road in Play. In that run no Belta, Camry or Alfard had spawned near the camera.

## Left / not done
- **The Arzani Street deck itself ends 39 studs in the air** (builder or data fault, also a drop for players). Traffic no longer drives there, but the road needs a ramp, or the deck needs cutting, in the roads05 builder, then `LaneHeights` and the lanes re-run.
- The lane modules are unchanged. The fixes run when the lanes load (`YangonDeckFix`). After the next `roads05_lanes.py` run, the spike rule still applies, but fix the deck data at the source too.
- The built crests (Maha Bandula #2, Ahlone #3 deck foot, and others) are real steps in the road for players. Racers now ease over them, but the roads are unchanged.
- `ServerStorage.TrafficModels_preDoors` can be deleted after the owner's phone test, along with `TrafficModels_old` and `TrafficModels_preBadges`.
