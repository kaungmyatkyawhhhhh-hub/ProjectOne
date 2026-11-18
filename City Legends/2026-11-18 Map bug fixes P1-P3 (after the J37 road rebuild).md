---
tags: [city-legends, yangon, roads, bugfix]
created: 2026-11-19
---
# Map bug fixes P1-P3 (after the J37 road rebuild)

The owner drove P1-P3 after the J37 rebuild and found 5 kinds of bugs (shots were not saved). Each kind was scanned over the whole of P1-P3 and fixed at its root, not spot by spot.

## What was wrong and what was done
| Class | Scan found | Fix (root) |
|---|---|---|
| **Invisible bumps** (cars hit things you can't see) | 4,203 of 11,905 pavement collision boxes stood over bare asphalt or ground: the road bake laid a pavement box (0.5 over the road) along each road's whole length from the road data, but the builder had cut the pavement at junction mouths, driveways, side lanes beside the flyovers and gores. Also 79 invisible wall-collision records (WCOL) on the new carriageways. Nothing else: Roads.Collide had no boxes from old builds, and the other invisible boxes over roads are landmark collision under the landmarks' own grounds (visible) | The bake now keeps a pavement box only where a pavement, kerb or median piece was really built (`roads05_pbox_clip.py`, in every new bake). In the place: 5,625 pavement boxes replaced by 8,770 clipped pieces (each cut to the covered thirds of its width). WCOL removed with the props below |
| **Street-name signs in the road** (University Ave x Kabar Aye) | Props placed from the old road layout, tested by footprint against the new carriageway: 396 records in 194 tiles: 13 name plates + 26 name labels, 76 drains, 79 WCOL, compound-wall runs, stalls / litter, 3 trees | Removed from the client kit data (place + repo copies). The old filter only tested each record's centre point (missed plates, which sit at plate height, and walls that only partly cross the road) |
| **Terrain ridges and grass arches by the flyovers; roads under grass** | 39 road boxes with terrain over them (Shwedagon side, MC); 3,791 stray terrain voxels near the decks (over the local road level + 4, or floating) in 1,748 columns: Kabar Aye flyover park, the P3 river bridge approach | Cleared only those (terrain over each box; near-deck columns above road level + 3). Real ground kept |
| **Crumpled island kerbs, kerbs crossing** | `roads05_kerb_cross.py`: P3 297 crossing kerb pairs in 96 clusters, P1-P2 516 pairs in 183 clusters | Not fixed in the builder yet (see "Left") |

## Shots
Kabar Aye flyover, terrain ridge: before ![[2026-11-18 Map bug fixes - Kabar Aye flyover terrain ridge - before.jpg]] after ![[2026-11-18 Map bug fixes - Kabar Aye flyover terrain ridge - after.jpg]]

Invisible pavement boxes (magenta) on the P3 river bridge approach: before ![[2026-11-18 Map bug fixes - invisible pavement boxes on P3 river bridge approach (magenta) - before.jpg]] first pass ![[2026-11-18 Map bug fixes - invisible pavement boxes on P3 river bridge approach (magenta) - round 1.jpg]] final (boxes only on pavements) ![[2026-11-18 Map bug fixes - invisible pavement boxes on P3 river bridge approach (magenta) - after.jpg]]

Play (test save): University Ave x Kabar Aye under the flyover, no signs in the road ![[2026-11-18 Map bug fixes - University Ave x Kabar Aye no signs in the road (Play) - after.jpg]] P3 bridge ramp driven, no bumps ![[2026-11-18 Map bug fixes - P3 river bridge ramp driven, no bumps (Play) - after.jpg]]

Grass over the pavement on the P3 bridge approach (before): ![[2026-11-18 Map bug fixes - P3 bridge approach grass over pavement - before.jpg]]

## Play test (19 Nov, store CityLegends_test, then back to CityLegends_v1 and read on the Server)
Driven: University Ave x Kabar Aye under the flyover (115 studs, height change 0.7, top vertical speed 1.3), Sule ring west mouth (114 studs, 2.1), the P3 river bridge ramp deck where the boxes stood on the lanes (122 studs, 2.0, smooth descent). No plates or wall collision left near the University x Kabar Aye spot. No new script errors. Place saved (version 1471).

## Left
- The median nose (bug 1) and the small junction (bug 5: crumpled island, kerb notch / step, yellow line cut mid-curve, white bar, light-blue bar, 4-way arrow) were not found by location (no shots). They are builder look faults in the road meshes; the kerb-crossing clusters list the candidates. Fixing them needs a YangonRoads change and a rebuild of those cells.
- Buildings (shells) and some landmark grounds (Bogyoke market, Holy Trinity, Strand) stand over J37 road boxes: roads through compounds in the OSM data.

Tools: `tools/yangon/city/roads05_pbox_check.py`, `roads05_pbox_clip.py` (+ `_test.py`), `roads05_kerb_cross.py`, `kit_tile_patch.py`, `tools/yangon/MapBugScan.luau`. Detail and counts: `build/city_1to1/roads05_HANDOVER.md` "MAP BUG FIXES".
