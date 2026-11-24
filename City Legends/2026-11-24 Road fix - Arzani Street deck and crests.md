---
tags: [city-legends, roads, roads05, traffic]
created: 2026-11-24
---
# Road fix: Arzani Street deck end and the crests (24 Nov 2026)

Follows [[2026-11-24 Traffic fix - racer bumps and rear doors]] ("What's left"). Saved in Studio as **v1934** (store `CityLegends_v1`, read on the Server). Not published.

## 1. Arzani Street "flyover" in the air: fixed

### What OSM says
- None of the Arzani Street ways has a bridge or layer tag (ways 489235410, 23380102, 482651149, 617583031, checked on the live OSM API on 24 Nov).
- The only bridges near it are Shwedagon's covered stairways and footways.
- So the real Arzani Street has **no flyover**. It is a ground road climbing the hill north of Shwedagon (past the Martyrs' Mausoleum).
- The deck came from a "raised" stretch in the old P7 height profile. The same profile put the hill's roads on two flat shelves (76.97 and 129.56) with 50-stud jumps between them.
- The 19 Nov build re-graded those roads into something drivable. That is why the deck ended 39 studs over the road.

### The fix (in the road data, cells rebuilt whole)
- `tools/yangon/city/roads05_arzani_fix.py`:
  - The deck is gone. Arzani Street is one ground road.
  - From the old deck foot it climbs in one even grade (76.7 to 91), then follows the built hill road up to 121.
  - Every other road in the two cells takes the built road's height (smoothed), not the broken shelves.
  - Side roads that end on Arzani take its height at the mouth.
- Applied to the whole network, the lanes data (`roads05_LP1to10`) and a new Studio subset `roads05_RB7a`. Backups: `roads_before_arzanifix.json`.
- Cells **20x23 and 21x23** were rebuilt whole with the batch 0.5 builder (Roads.luau + YangonRoads.luau): 68,337 parts, 0 mouths failed. Then baked (21 meshes, 1,156 collision boxes) and swapped.
- Lanes:
  - The old heights in the two cells were dropped and measured again with LaneHeights: 0 points off the road.
  - `roads05_lanes.py LP1to10 --install`: 1,322 lanes, 0 dead ends. Modules _13, _14 and _24 changed. All 26 load in Studio.
- Traffic: Arzani's lane no longer has a cliff, so the traffic agent's cut does not apply to it any more. NPC cars drive the old deck stretch again (24 cars on it during the test). The general cliff guard in `RivieraTraffic` stays as a safety net; it removes nothing now.
- DeckFeetCheck: no deck feet left in these cells. The nearby decks (Kabar Aye, May Ni Gone, Shwedagon, Ahlone): 8 ok, 0 bad.

### Play test (test store, then back to `CityLegends_v1`)
- Drove up from the old deck foot to Shwedagon: no deck, no drop, no floating medians, no terrain arches over the road. Traffic drives in both lanes.
- Drove down from (33300, 36330) to the old deck foot: no cliff.
- Before: ![[2026-11-24 road fix - Arzani Street deck end, canyon and floating medians (Play) - before.jpg]]
- After:
  - ![[2026-11-24 road fix - Arzani Street ground road where the fake deck was (Play) - after.jpg]]
  - ![[2026-11-24 road fix - Arzani Street past the old deck end, traffic on it (Play) - after.jpg]]
  - ![[2026-11-24 road fix - Arzani Street at the old deck end, driving down with traffic (Play) - after.jpg]]

### Left on Arzani
- Three small bumps that are **in the collision only** (the road you see is smooth):
  - About 1.2 studs at Lane #1957's slanted mouth (32836, 36243). A racer feels it as one small hop.
  - Two 1.6-stud cracks between boxes at (32969, 36326) and (33603, 36458).
  - They come from how the bake fits collision boxes. A fix belongs in `roads05_bake.collision`.
- Past the old deck end the road runs in a deep cutting. The 19 Nov build dug it, and the walls stay; nothing hangs over the road any more.

## 2. Crests and steps from the spot list
Measured on the built road in Studio:

| Spot | Built step now | Cause | State |
|---|---|---|---|
| Ahlone Road #3 deck foot (27503, 39765) | 4.6 down at the foot | the data's foot sample is 56.58 next to 61.82 | tried, reverted (below) |
| Maha Bandula Road #2 (~35713, 45107) | 4.2 down | a stretch built 3.3 over its data that drops back (looks like a junction pin) | not fixed |
| Ziwaka Road (33775, 39434) / (33905, 39367) | 1.2 and 0.9 | zigzag in the data (±8% every other sample) | not fixed |
| Merchant Road (34014, 45886) | 0.8 | small | not fixed |
| Shwe Gone Dine, Old Yay Ta Shay #2, May Ni Gone | 0.3-0.6 | data zigzag | not fixed |
| Zoological Garden Road #4 | none | - | ok |
| Hledan Road #3 deck foot (25082, 28895) | 1.6 | deck foot | not fixed |

- **Ahlone #3, tried:**
  - `roads05_ahlone_fix.py` gave the road's samples under the deck the deck's heights.
  - Cell 17x25 was rebuilt, baked and swapped.
  - The builder then lifted the ground road's start to 64.9, 3 studs **over** the deck foot, and the deck's last collision box tilted up to it. That is worse.
  - The cell was swapped back, and the data change was undone in the network and the lanes data. `roads05_RB6a` is kept for the next try.
  - Next: find what lifts the road start (deck-foot easing in Roads.luau) before rebuilding 17x25.
- The other spots are each in another district's cells (P3, P5, P6, P8). Each needs its own subset, rebuild, bake and swap. Not done today.
