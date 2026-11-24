---
tags: [city-legends, yangon, roads, bugfix]
created: 2026-11-24
---
# 24 Nov: P1-P3 map bug fixes (kerbs, grounds, props)

The queued P1-P3 bugs from [[2026-11-18 Map bug fixes P1-P3 (after the J37 road rebuild)]] are done. Saved as v1885 (props and grounds) and v1899 (roads), then v1901 after the store went back to `CityLegends_v1`. Nothing is published.

## 1. Kerbs lying across each other (the "crossing kerb pairs")
- **Found:** 791 crossing pairs in the P1-P3 cells. Also 600 crumpled kerb pieces: pieces whose 6-stud-deep body leans 15-80 degrees and lies across the road as a slanted plate. Those were the worst ones, at median noses and junction islands.
- **Fixed in the road bake (`tools/yangon/city/roads05_kerb_fix.py`):** every bake now runs this fix, P11 and P12 too. It follows 3 rules:
  - Crumpled pieces are dropped (600).
  - A piece that sticks out across another kerb, or is nearly covered by it, is dropped (406).
  - Two pieces that make one continuous kerb (for example two wedge fans on a gore bend) are both kept, because dropping one cut notches into the kerb. If their tops were level, the smaller one is lifted 0.06 so it can't flicker (105 lifted). 128 such pairs still overlap. That is how the builder lays curved kerbs, and they no longer flicker.
- **Re-baked:** 88 road cells, each one whole and each from the build that is actually in the place. Seven later district rebuilds had re-baked P1-P3 edge cells, so the cells came from 10 different builds. This gave 90 mesh files and 45,814 collision boxes. A check that the road box counts per cell matched the place showed no differences. The 4,773 hole-filler boxes added earlier were kept.
- **Also cleaned up by the re-bake:**
  - The pavement collision is now trimmed to the real pavement in the two Myanmar Centre ramp cells as well.
  - The yellow gore barriers are now in the older P1-P3 cells too (60 boxes).
  - 13 pavement boxes standing 0.3-3 studs over a flyover deck were removed. They were invisible kerbs; two of them were the known Road Flyover #2 ones.
- **Place size:** the first save after the swap failed with "File too large". The fix was to set the new road meshes' collision shape to a simple box (825 meshes). They don't collide anyway, so nothing changes in the game. Each mesh shrank from about 25 KB to 3.5 KB in the file.

## 2. Grounds and plots over the new roads
- **The check:** every flat ground part in P1-P3 was tested against the road collision boxes, measuring the area over the road where the part's top is above the road. 300 parts touch a road.
- **Trimmed:** 6 plates whose edge overhung a road by a thin strip (under 10% of the plate). These are the Skyline tower lot, the Customs lot and house lots `y1_low_1`, `y1_low_3`, `y1_low_6` and `y1_mid_7`. Afterwards 0 road area was left under any of them.
- **Not trimmed: here the road runs through the building or venue itself.** Clipping these would mean moving the building, which the brief rules out. Each needs a decision: move the lot, or drop that OSM lane from the road data.
  - **Bogyoke Market:** OSM service lanes run under the halls (127 road boxes; the generated hall layout doesn't match the real lanes).
  - **Holy Trinity Cathedral:** a lane runs through the church.
  - **Strand Hotel:** the front porch and steps stand about 17 studs into Strand Road's carriageway.
  - **Venue lots a road runs through:** Rewards (8,441 studs² of road under it), Legends Service (6,496), the drop-off (1,508), and house lots `y1_high_3`, `y1_high_10`, `y1_mid_3` and `y1_mid_11`.
  - **Also left as they are:** the YCC plate and ramps (on purpose), the Myanmar Centre and Sedona drive collision (the landmark drives sit on the same OSM roads; kept on 19 Nov), the city hall, secretariat and station bodies, the Sule ramps, and one pagoda base.

## 3. Props and trees on the roads
- **Street kit (client data):** the same check used for P4-P10 (KitOnRoad) removed 1,182 records:
  - Data_P1: 354
  - Data_P2: 414
  - P1P: 60
  - P2P: 41
  - P1S: 60 (poles, lamps, drains, name plates, cable spans)
  - P1G and P2G trees: 90
  - P3: 159
  - P3G: 4

  Most of them were invisible wall collision and compound walls. They sit on the edge columns that P4 and P9 re-baked.
- **Parts:** 50 Inya / Kandawgyi lake-edge rail posts and rails standing on carriageways, 2 far trees, and the 24-piece old centre line of `Parks.ThanlwinRoad`, which lay on top of the new Thanlwin Road. The list is in `build/city_1to1/mapbugs/mb24_removed.txt`.

## Play test (store `CityLegends_test`, then back to `CityLegends_v1`, checked on the Server in a fresh Play)
- **Kabar Aye Pagoda Road median nose by Myanmar Centre** (the stray diagonal kerb is gone): 57 studs on road boxes, top vertical speed 0.4.
- **Kaba Aye Pagoda lane** (P2's worst crumpled cluster): 57 studs, no bump after the car settled.
- **Downtown junction island off Strand Road** (P3's worst cluster): 45 studs, height above the road 2.1-2.3 the whole way.
- **Thanlwin Road by the customs lot:** 45 studs, flat.
- No new script errors (only the usual texture-pack and CDN messages).

Pictures:
![[2026-11-24 P1-P3 fixes - Kabar Aye Pagoda Rd median nose by Myanmar Centre (Play) - after.jpg]]
![[2026-11-24 P1-P3 fixes - Kaba Aye Pagoda lane (Play) - after.jpg]]
![[2026-11-24 P1-P3 fixes - downtown junction island off Strand Road (Play) - after.jpg]]
![[2026-11-24 P1-P3 fixes - Thanlwin Road by the customs lot (Play) - after.jpg]]

## Left
- **Six P1-P3 cells were built in the P8 rebuild** (23x21 and the P3 row 23x26-27x26). Their build files are on the laptop, so they still have the old kerbs. Re-bake them there with this fix.
- ~~The venue and landmark conflicts listed in section 2.~~ Done the same day, see "Roads through buildings and lots" below.
- **The Kaba Aye Pagoda lane mouth** still shows one raised kerb end (seen in the shot). It is not a crossing or leaning piece, so it is a builder fault. Not fixed on 24 Nov: the spot could not be found from the shot quickly and a builder change means re-baking cells, so it is not a quick fix.
- **The median nose and crumpled junction from the owner's drive:** the nose fixed above is a likely match. There are still no owner shots to confirm it.
- **The repo copies of the kit tiles** (`imports/sync/ygn1to1_*`) still hold the removed records. Re-run the filter after any regenerate.

## Roads through buildings and lots (24 Nov, OVERLAPS FIX agent)
The owner's decisions for section 2, done and saved (v1906, v1908, v1911 with the store back on `CityLegends_v1`, read on the Server). Nothing is published.

**1. Bogyoke Market: the lanes under the halls are gone.**
- The 8 OSM service lanes inside the market (Lane #19, #3804-#3810) ran under the hall roofs. Every stretch of them outside the halls was 16 studs or less (just their mouths), so they were dropped whole, with their 4 lane crossings.
- **Holy Trinity Cathedral:** the stretch of Lane #4266 that ran through the church (21 samples, its carriageway and pavement inside the nave or the tower) was dropped. The lane is now two pieces that stop at the church: the west piece (166 studs) and `Lane #4266b` (253 studs, along the east side to the tower).
- **How:** `tools/yangon/city/roads05_drop_lanes.py` (self-check `test`) patched the net roads.json, the lane subset `roads05_LP1to10` and a new subset `roads05_RB3o` (RB3 + the drop). Cells 22x27 and 22x28 (the market and the church) were rebuilt whole with the batch 0.5 builder (`stepCell`, 85,349 parts, 0 mouth failures), baked (22 meshes, 1,446 boxes) and swapped. 468 of the 568 old hole-filler boxes were kept; 100 under the halls / church or next to no road were dropped.
- **The old road beds were still in the ground:** a test car fell into a 2-9 stud trench by the church. The terrain along all 492 dropped samples was filled back to the ground beside it (460 fills), and the terrain left over 24 road boxes was cleared.
- **Traffic lanes did not change:** these are `street` roads, and the traffic lanes are only built on main roads, so no lane re-run was needed.

**2. Strand Hotel: the whole hotel moved back.**
- The porch steps stood 22 studs into Strand Road, and the main facade itself was 4 studs into the carriageway. Squashing the porch to half its depth would have spoiled the front, so the whole hotel model moved 30 studs back (north) and 1 up.
- The bottom step now ends at the back of the pavement (z 46795), and no road box touches the hotel.
- The strip between the facade and the pavement is paved (terrain Pavement), like the real paved forecourt in front of the steps (photo `Strand_Hotel_Entrance` in the landmark refs). The lobby floor was cleared of terrain.

**3. Lots moved to the nearest free spot beside a road** (`tools/yangon/LotFinder.luau`: candidates face a pavement box, and nothing but shells is allowed in the pad; then `YangonSites.prepare` on the new spot):

| Lot | Old spot (x, z) | New spot (x, z), facing | Moved |
|---|---|---|---|
| Legends Rewards | 35389, 22839 | 35461.7, 22353.3, (-0.991, -0.135) | 491 |
| Legends Service | 35171, 24404 | 35671.1, 25260.5, (0.259, 0.966) | 990 |
| Drop-off | 35417, 27781 | 35660.1, 27508.2, (-0.758, -0.652) | 365 |
| House y1_high_3 | 31271, 28460 | 31799.3, 28685.5, (-0.271, -0.963) | 574 |
| House y1_high_10 | 29721, 26172 | 29676.7, 26072.3, (-0.902, 0.433) | 109 |
| House y1_mid_3 | 29418, 28144 | 29553.3, 28155.2, (0.079, -0.997) | 136 |
| House y1_mid_11 | 29452, 25750 | 29322.9, 25613.8, (-0.699, 0.715) | 188 |

- **Code:** `Config.YangonVenues.Sites` (rewards, dropoff), `Config.Service.Bay` / `Arrive` (moved with the workshop), `src/shared/YangonWorld.lua` (the 4 house lots; `world_1to1.py` has them in `MOVED`, so a re-run keeps them). Synced into Studio.
- **Legends Service** is a baked model: it moved by the same transform as its lot, and its drive ramps were re-laid from the forecourt to the new pavement edge (the old ones reached 20 studs into the carriageway).
- Prompts, fast travel and the minimap read these positions, so they follow. Checked in Play: Rewards built with its 9 prompts, the service bay and arrive spot land on its floor and forecourt, and the 4 FOR SALE lots stand on the new spots. No road box lies under any new pad.

**Play test** (store `CityLegends_test`, then back to `CityLegends_v1`, checked on the Server in a fresh Play):
- **Bogyoke Aung San Road along the market front:** 176 studs, flat.
- **Lane #4266b by the church:** 120 studs, height 37.16-37.18 the whole way, and the car stops at the lane's end kerb by the tower.
- **Strand Road past the hotel:** 40 studs each way, flat.
- **The venues:** driven past Rewards, Service, the drop-off and lot y1_high_3.
- No new script errors.

Pictures:
![[2026-11-24 overlaps fix - Bogyoke Market front, no lanes under the halls (Play) - after.jpg]]
![[2026-11-24 overlaps fix - Holy Trinity lane now stops at the church (Play) - after.jpg]]
![[2026-11-24 overlaps fix - Strand Hotel porch at the pavement (Play) - after.jpg]]
![[2026-11-24 overlaps fix - Strand Road past the Strand Hotel (Play) - after.jpg]]
![[2026-11-24 overlaps fix - Legends Rewards on its new lot (Play) - after.jpg]]
![[2026-11-24 overlaps fix - Legends Service on its new lot (Play) - after.jpg]]
![[2026-11-24 overlaps fix - drop-off on its new lot (Play) - after.jpg]]
![[2026-11-24 overlaps fix - house lot y1_high_3 on its new spot (Play) - after.jpg]]

**Left:**
- **Old lot spots:** the old pads were deleted, and the shells cleared there earlier stay cleared (flat ground beside the road).
- **Lots driven by:** only y1_high_3 of the 4 house lots was driven past. The other 3 were checked by data (their FOR SALE models are on the new spots, they front a pavement, and no road box is under them).
- **Bogyoke front:** 4 Bogyoke Aung San Road pavement boxes still touch the ends of the market's thin side walls by a few studs at the front facade. This was there before.
- **Kaba Aye Pagoda lane mouth:** the raised kerb end is not fixed (see Left above).
